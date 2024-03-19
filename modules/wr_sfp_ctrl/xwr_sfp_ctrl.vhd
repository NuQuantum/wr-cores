library ieee;
use ieee.std_logic_1164.all;

library work;
use work.wishbone_pkg.all;

entity xwr_sfp_ctrl is 
generic 
(
	g_num_sfp 	: integer := 1
);
port 
(

	clk_i				: in std_logic;
  rst_n_i     : in std_logic;

  --sfp i2c
  scl_pad_i 		: in std_logic_vector(g_num_sfp-1 downto 0);
  scl_pad_o 		: out std_logic_vector(g_num_sfp-1 downto 0);
  scl_padoen_o 	: out std_logic_vector(g_num_sfp-1 downto 0);
  sda_pad_i 		: in std_logic_vector(g_num_sfp-1 downto 0);
  sda_pad_o 		: out std_logic_vector(g_num_sfp-1 downto 0);
  sda_padoen_o 	: out std_logic_vector(g_num_sfp-1 downto 0);

  --sfp gpio
  detect_i   		: in std_logic_vector(g_num_sfp-1 downto 0);
  tx_fault_i  	: in std_logic_vector(g_num_sfp-1 downto 0);
  los_i 				: in std_logic_vector(g_num_sfp-1 downto 0);
  tx_diable_o   : out std_logic_vector(g_num_sfp-1 downto 0);
  led_mode_o  	: out std_logic_vector(g_num_sfp-1 downto 0);
  led_synced_o	: out std_logic_vector(g_num_sfp-1 downto 0);

  --wb
  slave_i : in  t_wishbone_slave_in;
  slave_o : out t_wishbone_slave_out
);
end entity xwr_sfp_ctrl;

architecture wrapper of xwr_sfp_ctrl is


	component wr_sfp_ctrl is 
	generic 
	(
			g_num_sfp : integer := 1
	);
	port 
	(
	  clk_i					: in std_logic;
	  rst_n_i     	: in std_logic;

	  --sfp i2c
	  scl_pad_i 		: in std_logic_vector(g_num_sfp-1 downto 0);
	  scl_pad_o 		: out std_logic_vector(g_num_sfp-1 downto 0);
	  scl_padoen_o 	: out std_logic_vector(g_num_sfp-1 downto 0);
	  sda_pad_i 		: in std_logic_vector(g_num_sfp-1 downto 0);
	  sda_pad_o 		: out std_logic_vector(g_num_sfp-1 downto 0);
	  sda_padoen_o 	: out std_logic_vector(g_num_sfp-1 downto 0);

	  --sfp gpio
	  detect_i   		: in std_logic_vector(g_num_sfp-1 downto 0);
	  tx_fault_i  	: in std_logic_vector(g_num_sfp-1 downto 0);
	  los_i 				: in std_logic_vector(g_num_sfp-1 downto 0);
	  tx_diable_o   : out std_logic_vector(g_num_sfp-1 downto 0);
	  led_mode_o  	: out std_logic_vector(g_num_sfp-1 downto 0);
	  led_synced_o	: out std_logic_vector(g_num_sfp-1 downto 0);

	  --wb 
	  wb_cyc_i     	: in std_logic;
	  wb_stb_i     	: in std_logic;
	  wb_adr_i     	: in std_logic_vector(31 downto 0);
	  wb_sel_i     	: in std_logic_vector(3 downto 0);
	  wb_we_i      	: in std_logic;
	  wb_dat_i     	: in std_logic_vector(31 downto 0);
	  wb_ack_o     	: out std_logic;
	  wb_err_o     	: out std_logic;
	  wb_rty_o     	: out std_logic;
	  wb_stall_o   	: out std_logic;
	  wb_dat_o     	: out std_logic_vector(31 downto 0)			
	);
	end component wr_sfp_ctrl;

begin
	
	U_wrapped_wr_sfp_ctrl: wr_sfp_ctrl
	generic map 
	(
		g_num_sfp 		=> g_num_sfp
	)
	port map 
	(
	  clk_i					=> clk_i,
	  rst_n_i     	=> rst_n_i,

	  scl_pad_i 		=> scl_pad_i,
	  scl_pad_o 		=> scl_pad_o,
	  scl_padoen_o 	=> scl_padoen_o,
	  sda_pad_i 		=> sda_pad_i,
	  sda_pad_o 		=> sda_pad_o,
	  sda_padoen_o 	=> sda_padoen_o,

	  detect_i   		=> detect_i,
	  tx_fault_i  	=> tx_fault_i,
	  los_i 				=> los_i,
	  tx_diable_o   => tx_diable_o,
	  led_mode_o  	=> led_mode_o,
	  led_synced_o	=> led_synced_o,

		wb_adr_i      => slave_i.adr,
    wb_dat_i      => slave_i.dat,
    wb_dat_o      => slave_o.dat,
    wb_sel_i      => slave_i.sel,
    wb_we_i       => slave_i.we,
    wb_cyc_i      => slave_i.cyc,
    wb_stb_i      => slave_i.stb,
    wb_ack_o      => slave_o.ack,
    wb_err_o      => slave_o.err,
    wb_stall_o    => slave_o.stall
	);

end architecture;
