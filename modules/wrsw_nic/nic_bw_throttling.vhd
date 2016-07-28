library IEEE;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.wr_fabric_pkg.all;
--use work.gencores_pkg.all;

entity nic_bw_throttling is
  generic (
    g_true_random : boolean := false);
  port (
    clk_sys_i   : in  std_logic;
    rst_n_i     : in  std_logic;

    pps_p_i     : in std_logic;
    pps_valid_i : in std_logic;

    snk_i   : in  t_wrf_sink_in;
    snk_o   : out t_wrf_sink_out;
    src_o   : out t_wrf_source_out;
    src_i   : in  t_wrf_source_in;

    bw_o    : out std_logic_vector(31 downto 0);
    rnd_o   : out std_logic_vector(31 downto 0));
end nic_bw_throttling;

architecture behav of nic_bw_throttling is

  signal bw_cnt : unsigned(31 downto 0);
  signal bw_reg : unsigned(31 downto 0);
  signal is_data : std_logic;

  signal drop_frame : std_logic;
  type t_fwd_fsm is (WAIT_FRAME, FLUSH, PASS, DROP);
  signal state_fwd : t_fwd_fsm;
  signal wrf_reg : t_wrf_sink_in;

  signal ring_out : std_logic_vector(31 downto 0);
  signal rnd_reg  : std_logic_vector(31 downto 0);
  --attribute keep : string;
  --attribute keep of ring_out : signal is "true";
  --attribute keep_hierarchy : string;
  --attribute keep_hierarchy of behav : architecture is "true";
  attribute S : string;
  attribute S of ring_out : signal is "true";

  constant c_LFSR_START : std_logic_vector := x"A5A5";
begin

  -------------------------------------------------
  --          Random number generation           --
  -------------------------------------------------
  GEN_RND: if g_true_random generate
    -- based on Generalized Ring Oscillator
    ring_out(0) <= ring_out(31) xnor ring_out(0) xnor ring_out(1);
    GEN_RND: for I in 1 to 30 generate
      ring_out(I) <= ring_out(I-1) xor ring_out(I) xor ring_out(I+1);
    end generate;
    ring_out(31) <= ring_out(30) xor ring_out(31) xor ring_out(0);

    --GEN_ANTI_META: for J in 0 to 31 generate
    --  SYNC_FFS: gc_sync_ffs
    --    port map (
    --      clk_i    => clk_sys_i,
    --      rst_n_i  => rst_n_i,
    --      data_i   => ring_out(J),
    --      synced_o => rnd_reg(J));
    --end generate;
    process(clk_sys_i)
    begin
      if rising_edge(clk_sys_i) then
        if rst_n_i = '0' then
          rnd_reg <= (others=>'0');
        else
          rnd_reg <= ring_out;
        end if;
      end if;
    end process;
  end generate;

  GEN_PSEUDO_RND: if not g_true_random generate
    -- based on LSFR x^16 + x^15 + x^13 + x^4 + 1
    process(clk_sys_i)
    begin
      if rising_edge(clk_sys_i) then
        if rst_n_i = '0' then
          rnd_reg(31 downto 0) <= (others=>'0');
          rnd_reg(15 downto 0) <= c_LFSR_START;
        else
          rnd_reg(0) <= rnd_reg(15) xor rnd_reg(14) xor rnd_reg(12) xor rnd_reg(3);
          rnd_reg(15 downto 1) <= rnd_reg(14 downto 0);
        end if;
      end if;
    end process;

  end generate;

  rnd_o <= rnd_reg;

  -------------------------------------------------
  --        Forwarding or dropping frames        --
  -------------------------------------------------
  drop_frame <= '0';

  process(clk_sys_i)
  begin
    if rising_edge(clk_sys_i) then
      if rst_n_i = '0' then
        state_fwd <= WAIT_FRAME;
        wrf_reg <= c_dummy_snk_in;

        snk_o <= c_dummy_src_in;
        src_o <= c_dummy_snk_in;
      else
        case state_fwd is
          when WAIT_FRAME =>
            snk_o.ack   <= '0';
            snk_o.err   <= '0';
            snk_o.rty   <= '0';
            src_o       <= c_dummy_snk_in;
            if (snk_i.cyc='1' and snk_i.stb='1') then
              -- new frame is transmitted
              snk_o.stall <= '1';
              wrf_reg <= snk_i;

              if (drop_frame = '0') then
                state_fwd <= FLUSH;
              elsif (drop_frame = '1') then
                state_fwd <= DROP;
              end if;
            else
              snk_o.stall <= '0';
            end if;

          when FLUSH =>
            -- flush wrf_reg stored on stall or in WAIT_FRAME
            snk_o <= src_i;
            if (src_i.stall = '0') then
              src_o     <= wrf_reg;
              state_fwd <= PASS;
            end if;

          when PASS =>
            snk_o <= src_i;
            if (src_i.stall = '0') then
              src_o <= snk_i;
            else
              wrf_reg   <= snk_i;
              state_fwd <= FLUSH;
            end if;

          when DROP =>
            -- ack everything from SNK, pass nothing to SRC
            snk_o.stall <= '0';
            snk_o.err   <= '0';
            snk_o.rty   <= '0';
            src_o       <= c_dummy_snk_in;
            if (snk_i.stb='1') then
              snk_o.ack <= '1';
            else
              snk_o.ack <= '0';
            end if;

            if (snk_i.cyc='0' and snk_i.stb='0') then
              state_fwd <= WAIT_FRAME;
            end if;
        end case;
      end if;
    end if;
  end process;


  -------------------------------------------------
  -- Calculating bandwidth actually going to ARM --
  -------------------------------------------------

  is_data <= '1' when (snk_i.adr=c_WRF_DATA and snk_i.cyc='1' and snk_i.stb='1') else
             '0';

  process(clk_sys_i)
  begin
    if rising_edge(clk_sys_i) then
      if rst_n_i = '0' or pps_valid_i = '0' then
        bw_cnt <= (others=>'0');
        bw_reg <= (others=>'0');
      elsif pps_p_i = '1' then
        bw_reg <= bw_cnt;
        bw_cnt <= (others=>'0');
      elsif is_data = '1' then
        -- we count incoming bytes here
        if snk_i.sel(0) = '1' then
          -- 16bits carry valid data
          bw_cnt <= bw_cnt + 2;
        elsif snk_i.sel(0) = '0' then
          -- only 8bits carry valid data
          bw_cnt <= bw_cnt + 1;
        end if;
      end if;
    end if;
  end process;
  
  bw_o <= std_logic_vector(bw_reg);

end behav;
