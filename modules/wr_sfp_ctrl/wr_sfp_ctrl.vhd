library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.wishbone_pkg.all;
use work.sfp_ctrl_if_wb_pkg.all;

entity wr_sfp_ctrl is 
generic 
(
	g_num_sfp 	: integer := 1   --number of sfp interfaces, max 24
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
end entity wr_sfp_ctrl;

architecture rtl of wr_sfp_ctrl is 

	function f_get_used_regs(num_sfp : integer) return integer is
	begin
		if(num_sfp <= 8 ) then 
			return 1;
		elsif(num_sfp <= 16) then 
			return 2;
		else
			return 3;
		end if;
	end function;

	constant c_MAX_PORTS 		: integer := 24;
	constant c_NUM_REGS    	: integer := f_get_used_regs(g_num_sfp);

	component sfp_ctrl_if_wb is
		port 
		(
		  rst_n_i              : in    std_logic;
	    clk_i                : in    std_logic;
	    wb_cyc_i             : in    std_logic;
	    wb_stb_i             : in    std_logic;
	    wb_adr_i             : in    std_logic_vector(5 downto 2);
	    wb_sel_i             : in    std_logic_vector(3 downto 0);
	    wb_we_i              : in    std_logic;
	    wb_dat_i             : in    std_logic_vector(31 downto 0);
	    wb_ack_o             : out   std_logic;
	    wb_err_o             : out   std_logic;
	    wb_rty_o             : out   std_logic;
	    wb_stall_o           : out   std_logic;
	    wb_dat_o             : out   std_logic_vector(31 downto 0);
	    -- Wires and registers
	    sfp_if_regs_i        : in    t_sfp_if_regs_master_in;
	    sfp_if_regs_o        : out   t_sfp_if_regs_master_out
		);
	end component sfp_ctrl_if_wb;

	signal wb_regs_in   			: t_sfp_if_regs_master_in;
	signal wb_regs_out  			: t_sfp_if_regs_master_out;

	signal i2c_wb_dat_o 			: std_logic_vector(31 downto 0);
	signal i2c_wb_ack_o				: std_logic;
	signal i2c_wb_stall_o			: std_logic;
	signal i2c_wb_cyc_i  			: std_logic;

	signal sfp_wb_ack_o 			: std_logic;
	signal sfp_wb_err_o  			: std_logic;
	signal sfp_wb_rty_o  			: std_logic;
	signal sfp_wb_stall_o 		: std_logic;
	signal sfp_wb_dat_o  			: std_logic_vector(31 downto 0);	
	signal sfp_wb_cyc_i  			: std_logic;

begin


  U_i2c_master: wb_i2c_master
    generic map
    (
      g_interface_mode      => CLASSIC,
      g_address_granularity => BYTE,
      g_num_interfaces      => g_num_sfp
    )
    port map
    (
      clk_sys_i    		=> clk_i,
      rst_n_i      		=> rst_n_i,
      wb_adr_i     		=> wb_adr_i(4 downto 0),
      wb_dat_i     		=> wb_dat_i,
      wb_dat_o     		=> i2c_wb_dat_o,
      wb_sel_i     		=> wb_sel_i,
      wb_stb_i     		=> wb_stb_i,
      wb_cyc_i     		=> i2c_wb_cyc_i,
      wb_we_i      		=> wb_we_i,
      wb_ack_o     		=> i2c_wb_ack_o,
      wb_stall_o   		=> i2c_wb_stall_o,
      int_o        		=> open,
      scl_pad_i    		=> scl_pad_i,
      scl_pad_o    		=> scl_pad_o,
      scl_padoen_o 		=> scl_padoen_o,
      sda_pad_i    		=> sda_pad_i,
      sda_pad_o    		=> sda_pad_o,
      sda_padoen_o 		=> sda_padoen_o
     );

	--wb modules ack all addresses 
	--mask cycles to each slave
  i2c_wb_cyc_i 		<= wb_cyc_i and not(wb_adr_i(5));
  sfp_wb_cyc_i 		<= wb_cyc_i and (wb_adr_i(5));

	U_wb_if: sfp_ctrl_if_wb
		port map 
		(
		  rst_n_i              => rst_n_i,
	    clk_i                => clk_i,
	    wb_cyc_i             => wb_cyc_i,
	    wb_stb_i             => sfp_wb_cyc_i,
	    wb_adr_i             => wb_adr_i(5 downto 2),
	    wb_sel_i             => wb_sel_i(3 downto 0),
	    wb_we_i              => wb_we_i,
	    wb_dat_i             => wb_dat_i,
	    wb_ack_o             => sfp_wb_ack_o,
	    wb_err_o             => sfp_wb_err_o,
	    wb_rty_o             => sfp_wb_rty_o,
	    wb_stall_o           => sfp_wb_stall_o,	
	    wb_dat_o             => sfp_wb_dat_o,
	    -- Wires and registers
	    sfp_if_regs_i        => wb_regs_in,
	    sfp_if_regs_o        => wb_regs_out
	   );

	--wb muxing
	wb_dat_o 	<= i2c_wb_dat_o when i2c_wb_ack_o = '1' else sfp_wb_dat_o;		
	wb_ack_o  <= i2c_wb_ack_o or sfp_wb_ack_o;
	wb_err_o  <= sfp_wb_ack_o when sfp_wb_ack_o = '1' else '0';
	wb_rty_o 	<= sfp_wb_rty_o when sfp_wb_ack_o = '1' else '0';
	wb_stall_o <= sfp_wb_stall_o when sfp_wb_ack_o = '1' else '0';

	--register to port mapping
	gen_regs1: if c_NUM_REGS = 1 generate 
		gen_regmap_0: for i in 0 to g_num_sfp-1 generate
			wb_regs_in.gpi0_gpi0_word((i*4)+3 downto (i*4)) 	<= '0' & los_i(i) & detect_i(i) & tx_fault_i(i);
			tx_diable_o(i) 		<= wb_regs_out.gpo0_gpo0_word((i*4));
			led_mode_o(i) 		<= wb_regs_out.gpo0_gpo0_word((i*4)+1);
			led_synced_o(i) 	<= wb_regs_out.gpo0_gpo0_word((i*4)+2);
		end generate;
	end generate;

	gen_regs2: if c_NUM_REGS = 2 generate 
		gen_regmap_0: for i in 0 to 7 generate
			wb_regs_in.gpi0_gpi0_word((i*4)+3 downto (i*4)) 	<= '0' & los_i(i) & detect_i(i) & tx_fault_i(i);
			tx_diable_o(i) 		<= wb_regs_out.gpo0_gpo0_word((i*4));
			led_mode_o(i) 		<= wb_regs_out.gpo0_gpo0_word((i*4)+1);
			led_synced_o(i) 	<= wb_regs_out.gpo0_gpo0_word((i*4)+2);
		end generate;

		gen_regmap1: for i in 0 to g_num_sfp-8-1 generate
			wb_regs_in.gpi1_gpi1_word((i*4)+3 downto (i*4)) 	<= '0' & los_i(i+8) & detect_i(i+8) & tx_fault_i(i+8);
			tx_diable_o(i+8) 		<= wb_regs_out.gpo1_gpo1_word((i*4));
			led_mode_o(i+8) 		<= wb_regs_out.gpo1_gpo1_word((i*4)+1);
			led_synced_o(i+8) 	<= wb_regs_out.gpo1_gpo1_word((i*4)+2);
		end generate;
	end generate;		

	gen_regs3: if c_NUM_REGS = 3 generate 
		gen_regmap0: for i in 0 to 7 generate
			wb_regs_in.gpi0_gpi0_word((i*4)+3 downto (i*4)) 	<= '0' & los_i(i) & detect_i(i) & tx_fault_i(i);
			tx_diable_o(i) 		<= wb_regs_out.gpo0_gpo0_word((i*4));
			led_mode_o(i) 		<= wb_regs_out.gpo0_gpo0_word((i*4)+1);
			led_synced_o(i) 	<= wb_regs_out.gpo0_gpo0_word((i*4)+2);						
		end generate;

		gen_regmap1: for i in 0 to 7 generate
			wb_regs_in.gpi1_gpi1_word((i*4)+3 downto (i*4)) 	<= '0' & los_i(i+8) & detect_i(i+8) & tx_fault_i(i+8);
			tx_diable_o(i+8) 		<= wb_regs_out.gpo1_gpo1_word((i*4));
			led_mode_o(i+8) 		<= wb_regs_out.gpo1_gpo1_word((i*4)+1);
			led_synced_o(i+8) 	<= wb_regs_out.gpo1_gpo1_word((i*4)+2);	
		end generate;

		gen_regmap2: for i in 0 to g_num_sfp-16-1 generate
			wb_regs_in.gpi2_gpi2_word((i*4)+3 downto (i*4)) 	<= '0' & los_i(i+16) & detect_i(i+16) & tx_fault_i(i+16);
			tx_diable_o(i+16) 		<= wb_regs_out.gpo2_gpo2_word((i*4));
			led_mode_o(i+16) 			<= wb_regs_out.gpo2_gpo2_word((i*4)+1);
			led_synced_o(i+16) 		<= wb_regs_out.gpo2_gpo2_word((i*4)+2);						
		end generate;			
	end generate;		

end architecture;
