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
      ts_origin_i  : in std_logic_vector(27 downto 0);
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
  
  constant c_rollover_threshold_lo : integer := f_cycles_counter_range / 4;
  constant c_rollover_threshold_hi : integer := f_cycles_counter_range * 3 / 4;

  signal ts_adjusted   : unsigned(28 downto 0);
  signal armed         : std_logic;

  signal tm_cycles_scaled : unsigned(28 downto 0);
  signal ts_latency_scaled : unsigned(28 downto 0);

  signal match : std_logic;
  signal state : t_state;

  signal ts_adj_next_cycle, roll_lo, roll_hi : std_logic;

begin

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
        armed <= '0';
        late_o <= '0';
        match  <= '0';
        State  <= IDLE;

      else

        case State is
          when IDLE =>
            match  <= '0';
            late_o <= '0';
            armed  <= '0';

            if arm_i = '1' then
              ts_adjusted <= resize(unsigned(ts_origin_i) + unsigned(ts_latency_i), 29);
              State       <= WRAP_ADJ_TS;
              armed       <= '1';
            end if;

          when WRAP_ADJ_TS =>

            ts_adj_next_cycle <= '0';
            roll_lo           <= '0';
            roll_hi           <= '0';


            if ts_adjusted >= f_cycles_counter_range then
              ts_adj_next_cycle <= '1';
              ts_adjusted       <= ts_adjusted - f_cycles_counter_range;
            end if;

            if ts_adjusted < c_rollover_threshold_lo then
              roll_lo <= '1';
            end if;

            if tm_cycles_scaled > c_rollover_threshold_hi then
              roll_hi <= '1';
            end if;

          State <= CHECK_LATE;

          when CHECK_LATE =>

            if roll_lo = '1' and roll_hi = '1' then
              if ts_adj_next_cycle = '0' then
                late_o <= '1';
                State  <= IDLE;
              else
                State <= WAIT_TRIG;
              end if;
            else
              State <= WAIT_TRIG;
            end if;



          when WAIT_TRIG =>
            if ts_adjusted = tm_cycles_scaled then
              match <= '1';
              State <= IDLE;
            end if;

        end case;
      end if;
    end if;
  end process;

  match_o <= match;

end rtl;
