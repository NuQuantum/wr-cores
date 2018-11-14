library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity fixed_latency_ts_match is
  generic
    (g_clk_ref_rate : integer;
     g_simulation : integer := 0;
     g_sim_cycle_counter_range : integer := 125000000

     );
  port
    (
      clk_i   : in std_logic;
      rst_n_i : in std_logic;

      arm_i        : in std_logic;

      ts_tai_i    : in std_logic_vector(39 downto 0);
      ts_cycles_i : in std_logic_vector(27 downto 0);
      ts_latency_i : in std_logic_vector(27 downto 0);

      -- Time valid flag
      tm_time_valid_i : in std_logic := '0';

      -- TAI seconds
      tm_tai_i : in std_logic_vector(39 downto 0) := x"0000000000";

      -- Fractional part of the second (in clk_ref_i cycles)
      tm_cycles_i : in std_logic_vector(27 downto 0) := x"0000000";


      match_o : out std_logic;
      late_o  : out std_logic


      );

end entity;

architecture rtl of fixed_latency_ts_match is

  type t_state is (IDLE, WRAP_ADJ_TS, CHECK_LATE, WAIT_TRIG);

  impure function f_cycles_counter_range return integer is
  begin
    if g_simulation = 1 then
      if g_clk_ref_rate = 62500000 then
        return 2*g_sim_cycle_counter_range;
      else
        return g_sim_cycle_counter_range;
      end if;
      
    else
      return 125000000;
    end if;
  end function;

  signal ts_adjusted_cycles : unsigned(28 downto 0);
  signal ts_adjusted_tai    : unsigned(39 downto 0);

  signal tm_cycles_scaled : unsigned(28 downto 0);
  signal ts_latency_scaled : unsigned(28 downto 0);

  signal tm_cycles_scaled_d  : unsigned(28 downto 0);
  signal ts_latency_scaled_d : unsigned(28 downto 0);
  signal ts_adjusted_d       : unsigned(28 downto 0);

  signal match, late : std_logic;
  signal state : t_state;

  signal ts_adj_next_cycle, roll_lo, roll_hi : std_logic;

  attribute mark_debug : string;

  attribute mark_debug of ts_adjusted_d       : signal is "TRUE";
  attribute mark_debug of tm_cycles_scaled_d  : signal is "TRUE";
  attribute mark_debug of ts_latency_scaled_d : signal is "TRUE";
  attribute mark_debug of state               : signal is "TRUE";
  attribute mark_debug of match               : signal is "TRUE";
  attribute mark_debug of late                : signal is "TRUE";


begin

  process(clk_i)
  begin
    if rising_edge(clk_i) then
      ts_adjusted_d       <= ts_adjusted_cycles;
      tm_cycles_scaled_d  <= tm_cycles_scaled;
      ts_latency_scaled_d <= ts_latency_scaled;
    end if;
  end process;


  process(tm_cycles_i, ts_latency_i)
  begin
    if g_clk_ref_rate = 62500000 then
      tm_cycles_scaled <= unsigned(tm_cycles_i & '0');
      ts_latency_scaled <= unsigned(ts_latency_i & '0');
    elsif g_clk_ref_rate = 125000000 then
      tm_cycles_scaled <= unsigned('0' & tm_cycles_i);
      ts_latency_scaled <= unsigned('0' & ts_latency_i);
    else
      report "Unsupported g_clk_ref_rate (62.5 / 125 MHz)" severity failure;
    end if;
  end process;



  process(clk_i)
  begin
    if rising_edge(clk_i) then
      if rst_n_i = '0' then
        late <= '0';
        match  <= '0';
        State  <= IDLE;

      else

        case State is
          when IDLE =>
            match  <= '0';
            late  <= '0';

            if arm_i = '1' then
              ts_adjusted_cycles <= resize(unsigned(ts_cycles_i) + unsigned(ts_latency_i), 29);
              ts_adjusted_tai    <= resize(unsigned(ts_tai_i), 40);
              State              <= WRAP_ADJ_TS;
            end if;

          when WRAP_ADJ_TS =>


            if ts_adjusted_cycles >= f_cycles_counter_range then
              ts_adjusted_cycles <= ts_adjusted_cycles - f_cycles_counter_range;
              ts_adjusted_tai    <= ts_adjusted_tai + 1;
            end if;

            State <= CHECK_LATE;

          when CHECK_LATE =>

            if tm_time_valid_i = '0' then
              late  <= '1';
              state <= IDLE;
            end if;


            if ts_adjusted_tai < unsigned(tm_tai_i) then
              late  <= '1';
              State <= IDLE;
            elsif ts_adjusted_tai = unsigned(tm_tai_i) and ts_adjusted_cycles <= tm_cycles_scaled then
              late  <= '1';
              State <= IDLE;
            else
              State <= WAIT_TRIG;
            end if;

          when WAIT_TRIG =>
            if ts_adjusted_cycles = tm_cycles_scaled and ts_adjusted_tai = unsigned(tm_tai_i) then
              match <= '1';
              State <= IDLE;
            end if;

        end case;
      end if;
    end if;
  end process;

  match_o <= match;
  late_o  <= late;

end rtl;
