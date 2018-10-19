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
      miss_o  : out std_logic
      );

end entity;

architecture rtl of fixed_latency_ts_match is

  impure function f_cycles_counter_range return integer is
  begin
    if g_simulation = 1 then
      return g_sim_cycle_counter_range;
    else
      return 125000000;
    end if;
  end function;
  
  constant c_rollover_threshold_lo : integer := f_cycles_counter_range / 4;
  constant c_rollover_threshold_hi : integer := f_cycles_counter_range * 3 / 4;
  

  signal ts_adjusted   : unsigned(28 downto 0);
  signal target_cycles : unsigned(28 downto 0);
  signal arm_d         : std_logic_vector(2 downto 0);
  signal armed         : std_logic;

  signal tm_cycles_scaled : unsigned(28 downto 0);
  signal ts_latency_scaled : unsigned(28 downto 0);
  
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
        arm_d  <= (others => '0');
        miss_o <= '0';
      else
        arm_d <= arm_d(1 downto 0) & arm_i;

        if arm_i = '1' then
          match_o     <= '0';
          miss_o      <= '0';
          ts_adjusted <= resize(unsigned(ts_origin_i) + unsigned(ts_latency_i), 29);
        end if;

        if ts_adjusted < c_rollover_threshold_lo and tm_cycles_scaled > c_rollover_threshold_hi then
          target_cycles <= tm_cycles_scaled + f_cycles_counter_range;
          if arm_d(0) = '1' then
            ts_adjusted <= ts_adjusted + f_cycles_counter_range;
          end if;
          
        else
          target_cycles <= tm_cycles_scaled;
        end if;
        
          
        if (arm_d(1) = '1') then
          if ts_adjusted < target_cycles then
            miss_o <= '1';
          else
            armed <= '1';
          end if;
        end if;

        if armed = '1' and ts_adjusted = tm_cycles_scaled then
          match_o <= '1';
          armed <= '0';
        else
          match_o <= '0';
        end if;
      end if;
    end if;
  end process;

end rtl;
