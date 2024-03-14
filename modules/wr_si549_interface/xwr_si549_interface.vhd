library ieee;
use ieee.std_logic_1164.all;
use work.wishbone_pkg.all;
use work.axi4_pkg.all;

entity xwr_si549_interface is 
	generic
	(
    g_simulation 			: integer := 0;
    g_sys_clock_freq 	: integer := 62500000;
    g_i2c_freq 				: integer := 400000
	);
	port
	(
		clk_sys_i 				: in std_logic;
		rst_n_i 					: in std_logic;

    tm_dac_value_i    : in  std_logic_vector(23 downto 0);
    tm_dac_value_wr_i : in  std_logic;
    
    scl_pad_oen_o     : out std_logic;
    sda_pad_oen_o     : out std_logic;
    scl_pad_i         : in  std_logic;
    sda_pad_i         : in  std_logic;

    slave_wb_i 				: in  t_wishbone_slave_in;
    slave_wb_o 				: out t_wishbone_slave_out
	);
end entity xwr_si549_interface;

architecture wrapper of xwr_si549_interface is 

	component wr_si549_interface is 
	  generic 
	  (
	    g_simulation 			: integer := 0;
	    g_sys_clock_freq 	: integer := 62500000;
	    g_i2c_freq 				: integer := 400000
	  );
	  port 
	  (
	    clk_sys_i : in std_logic;
	    rst_n_i   : in std_logic;

	    -- WR Core timing interface: aux clock tune port
	    tm_dac_value_i    : in std_logic_vector(23 downto 0) := x"000000";
	    tm_dac_value_wr_i : in std_logic := '0';

	    -- I2C bus: output enable (active low)
	    scl_pad_oen_o : out std_logic;
	    sda_pad_oen_o : out std_logic;

	    -- I2C bus: input pads
	    scl_pad_i : in std_logic;
	    sda_pad_i : in std_logic;

	    -- Wishbone
	    wb_adr_i   : in  std_logic_vector(c_wishbone_address_width-1 downto 0);
	    wb_dat_i   : in  std_logic_vector(c_wishbone_data_width-1 downto 0);
	    wb_dat_o   : out std_logic_vector(c_wishbone_data_width-1 downto 0);
	    wb_sel_i   : in  std_logic_vector(c_wishbone_address_width/8-1 downto 0);
	    wb_we_i    : in  std_logic;
	    wb_cyc_i   : in  std_logic;
	    wb_stb_i   : in  std_logic;
	    wb_ack_o   : out std_logic;
	    wb_err_o   : out std_logic;
	    wb_rty_o   : out std_logic;
	    wb_stall_o : out std_logic
	  );
	 end component;

begin 

	U_wrapped_si549: wr_si549_interface 
	  generic map 
	  (
	    g_simulation 			=> g_simulation,
	    g_sys_clock_freq  => g_sys_clock_freq,
	    g_i2c_freq 				=> g_i2c_freq
	  )
	  port map
	  (
	    clk_sys_i 					=> clk_sys_i,
	    rst_n_i   					=> rst_n_i,

	    tm_dac_value_i    	=> tm_dac_value_i,
	    tm_dac_value_wr_i 	=> tm_dac_value_wr_i,

	    scl_pad_oen_o 			=> scl_pad_oen_o,
	    sda_pad_oen_o 			=> sda_pad_oen_o,

	    scl_pad_i 					=> scl_pad_i,
	    sda_pad_i 					=> sda_pad_i,
	    -- Wishbone
	    wb_adr_i   					=> slave_wb_i.adr,
	    wb_dat_i   					=> slave_wb_i.dat,
	    wb_dat_o   					=> slave_wb_o.dat,
	    wb_sel_i   					=> slave_wb_i.sel,
	    wb_we_i    					=> slave_wb_i.we,
	    wb_cyc_i   					=> slave_wb_i.cyc,
	    wb_stb_i   					=> slave_wb_i.stb,
	    wb_ack_o   					=> slave_wb_o.ack,
	    wb_err_o   					=> slave_wb_o.err,
	    wb_rty_o 						=> slave_wb_o.rty,
	    wb_stall_o 					=> slave_wb_o.stall
	  );	

end architecture;