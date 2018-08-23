
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity cute_reset_gen is
port (
  clk_sys_i : in std_logic;
  rst_button_n_a_i : in std_logic;
  rst_n_o : out std_logic);
end cute_reset_gen;

architecture behavioral of cute_reset_gen is

  signal powerup_cnt     : unsigned(7 downto 0) := x"00";
  signal powerup_n       : std_logic            := '0';
  signal button_synced_n : std_logic;
  
  component gc_sync_ffs is
    generic(
      g_sync_edge : string := "positive"
      );
    port(
      clk_i    : in  std_logic;  -- clock from the destination clock domain
      rst_n_i  : in  std_logic;           -- reset
      data_i   : in  std_logic;           -- async input
      synced_o : out std_logic;           -- synchronized output
      npulse_o : out std_logic;  -- negative edge detect output (single-clock
      -- pulse)
      ppulse_o : out std_logic   -- positive edge detect output (single-clock
     -- pulse)
      );
  end component;

begin  -- behavioral
  
  U_Sync_Button : gc_sync_ffs port map (
    clk_i    => clk_sys_i,
    rst_n_i  => '1',
    data_i   => rst_button_n_a_i,
    synced_o => button_synced_n);

  p_powerup_reset : process(clk_sys_i)
  begin
    if rising_edge(clk_sys_i) then
      if(powerup_cnt /= x"ff") then
        powerup_cnt <= powerup_cnt + 1;
        powerup_n   <= '0';
      else
        powerup_n <= '1';
      end if;
    end if;
  end process;

  rst_n_o <= powerup_n and button_synced_n;

end behavioral;
