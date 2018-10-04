library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity fixed_latency_ts_match is
  generic
    (g_clk_ref_rate : integer);
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

  constant c_unwrap_threshold : integer := 62500000;

  signal ts_adjusted   : unsigned(28 downto 0);
  signal target_cycles : unsigned(28 downto 0);
  signal delta : signed(28 downto 0);
  signal arm_d         : std_logic_vector(2 downto 0);
  signal armed         : std_logic;

  signal tm_cycles_scaled : unsigned(28 downto 0);
  
begin

  process(tm_cycles_i)
  begin
    if g_clk_ref_rate = 62500000 then
      tm_cycles_scaled <= unsigned(tm_cycles_i & '0');
    elsif g_clk_ref_rate = 125000000 then
      tm_cycles_scaled <= unsigned('0' & tm_cycles_i);
    else
      report "Unsupported g_clk_ref_rate (62.5 / 125 MHz)" severity failure;
    end if;
  end process;
  
    
  
  process(clk_i)
  begin
    if rising_edge(clk_i) then
      if rst_n_i = '0' then
        arm_d  <= (others => '0');
        miss_o <= '0';
      else
        arm_d <= arm_d(1 downto 0) & arm_i;

        if arm_i = '1' then
          match_o     <= '0';
          miss_o      <= '0';
          ts_adjusted <= resize(unsigned(ts_origin_i) + unsigned(ts_latency_i), 29);
          delta       <= signed('0'&ts_origin_i) + signed('0'&ts_latency_i) - signed('0'&tm_cycles_i);
        end if;

        if delta < -c_unwrap_threshold or delta > c_unwrap_threshold then
          ts_adjusted   <= ts_adjusted + 125000000;
          target_cycles <= tm_cycles_scaled + 125000000;
            
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

        if armed = '1' and ts_adjusted = target_cycles then
          match_o <= '1';
          armed <= '0';
        else
          match_o <= '0';
        end if;
      end if;
    end if;
  end process;

end rtl;
