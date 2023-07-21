library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity serial_dac856x is
  generic (
    --  SCLK is CLK / (g_sclk_div + 1)
    g_sclk_div : positive := 1
  );
  port (
    clk_i     :     std_logic;
    rst_n_i   :     std_logic;

    --  Value to be sent for output A.
    value_a_i :     std_logic_vector (15 downto 0);
    wr_a_i    :     std_logic;

    value_b_i :     std_logic_vector (15 downto 0);
    wr_b_i    :     std_logic;

    --  If true, values for a and b will be sent.
    en_a_i    :     std_logic;
    en_b_i    :     std_logic;

    --  Extra config.  When BUSY is set, the data are not yet sent.
    data_i    :     std_logic_vector(23 downto 0);
    wr_i      :     std_logic;
    busy_o    : out std_logic;

    --  SPI interface
    sclk_o    : out std_logic;
    d_o       : out std_logic;
    sync_n_o  : out std_logic
  );
end serial_dac856x;

architecture behav of serial_dac856x is
  signal sclk_p : std_logic;
  signal sclk_cnt : natural range g_sclk_div - 1 downto 0;

  signal set_a, set_b, set_d : std_logic;
  signal val_a, val_b : std_logic_vector(15 downto 0);
  signal val_d : std_logic_vector(23 downto 0);

  subtype t_clk_count is natural range (24 + 4) - 1 downto 0;
  signal edge : std_logic;
  signal clk_count : t_clk_count;
  signal buf : std_logic_vector(23 downto 0);
  signal busy : std_logic;
begin

  --  Clock divider.
  process (clk_i)
  begin
    if rising_edge(clk_i) then
      sclk_p <= '0';

      if rst_n_i = '0' or busy = '0' then
        sclk_cnt <= g_sclk_div - 1;
      else
        if sclk_cnt = 0 then
          sclk_p <= '1';
          sclk_cnt <= g_sclk_div - 1;
        else
          sclk_cnt <= sclk_cnt - 1;
        end if;
      end if;
    end if;
  end process;

  --  General state machine
  process (clk_i)
  begin
    if rising_edge(clk_i) then
      if rst_n_i = '0' then
        busy <= '0';
        sclk_o <= '1';
        sync_n_o <= '1';
        d_o <= '0';
        set_a <= '0';
        set_b <= '0';
        set_d <= '0';
      else
        --  Accept values.  Will overwrite but not corrupt current values.
        if wr_a_i = '1' then
          val_a <= value_a_i;
          set_a <= '1';
        end if;
        if wr_b_i = '1' then
          val_b <= value_b_i;
          set_b <= '1';
        end if;
        if wr_i = '1' then
          val_d <= data_i;
          set_d <= '1';
        end if;

        if busy = '1' then
          --  Transmit, but only on clock divider pulses.
          if sclk_p = '1' then
            if clk_count > 3 then
              sclk_o <= edge;
            else
              sclk_o <= '1';
            end if;
            if edge = '1' then
              if clk_count > 3 then
                sync_n_o <= '0';
                d_o <= buf(buf'high);
                buf <= buf(buf'high - 1 downto buf'low) & '0';
              else
                sync_n_o <= '1';
                d_o <= '0';
              end if;
            else
              if clk_count = 0 then
                busy <= '0';
              else
                clk_count <= clk_count - 1;
              end if;
            end if;
            edge <= not edge;
          end if;
        else
          --  Choose (with implicit priority the new data to be transmitted).
          if set_d = '1' then
            buf <= val_d;
            busy <= '1';
            set_d <= '0';
          elsif set_a = '1' and en_a_i = '1' then
            buf <= b"00_011_000" & val_a;
            busy <= '1';
            set_a <= '0';
          elsif set_b = '1' and en_b_i = '1' then
            buf <= b"00_011_001" & val_b;
            busy <= '1';
            set_b <= '0';
          end if;
          clk_count <= t_clk_count'high;
          edge <= '1';
        end if;
      end if;
    end if;
  end process;

  busy_o <= set_d;
end behav;
