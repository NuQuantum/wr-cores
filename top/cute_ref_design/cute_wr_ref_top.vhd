library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.gencores_pkg.all;
use work.wishbone_pkg.all;
use work.wr_board_pkg.all;
use work.wr_cute_pkg.all;
use work.wrcore_pkg.all;
use work.wr_xilinx_pkg.all;
use work.endpoint_pkg.all;
use work.etherbone_pkg.all;
use work.wr_fabric_pkg.all;

library unisim;
use unisim.vcomponents.all;

entity cute_wr_ref_top is
generic (
  g_dpram_initf : string := "../../bin/wrpc/wrc_phy8.bram";
  g_sfp0_enable : boolean:= true;
  g_sfp1_enable : boolean:= false;
  g_aux_sdb            : t_sdb_device  := c_xwb_xil_multiboot_sdb;
  g_multiboot_enable   : boolean:= true
);
port
(
-- clock
  clk20              : in std_logic;    -- 20mhz vcxo clock
  fpga_clk_p         : in std_logic;  -- 125 mhz pll reference
  fpga_clk_n         : in std_logic;
  sfp0_ref_clk_p     : in std_logic;  -- dedicated clock for xilinx gtp transceiver
  sfp0_ref_clk_n     : in std_logic;
  sfp1_ref_clk_p     : in std_logic;  -- dedicated clock for xilinx gtp transceiver
  sfp1_ref_clk_n     : in std_logic;
  
-- pll
  plldac_sclk        : out std_logic;
  plldac_din         : out std_logic;
  plldac_clr_n       : out std_logic;
  plldac_load_n      : out std_logic;
  plldac_sync_n      : out std_logic;
  
-- eeprom
  eeprom_scl         : inout std_logic;
  eeprom_sda         : inout std_logic;
  
-- 1-wire
  one_wire           : inout std_logic;      -- 1-wire interface to ds18b20
  
  -- flash
  flash_sclk_o       : out std_logic;
  flash_ncs_o        : out std_logic;
  flash_mosi_o       : out std_logic;
  flash_miso_i       : in  std_logic:='1';
  
  -- sfp0 pins
  sfp0_tx_p          : out   std_logic;
  sfp0_tx_n          : out   std_logic;
  sfp0_rx_p          : in    std_logic;
  sfp0_rx_n          : in    std_logic;
  sfp0_det           : in    std_logic;  -- sfp detect
  sfp0_scl           : inout std_logic;  -- scl
  sfp0_sda           : inout std_logic;  -- sda
  sfp0_tx_fault      : in    std_logic;
  sfp0_tx_disable    : out   std_logic;
  sfp0_los           : in    std_logic;  
  --sfp1_tx_p          : out   std_logic;
  --sfp1_tx_n          : out   std_logic;
  --sfp1_rx_p          : in    std_logic;
  --sfp1_rx_n          : in    std_logic;
  --sfp1_det           : in    std_logic;  -- sfp detect
  --sfp1_scl           : inout std_logic;  -- scl
  --sfp1_sda           : inout std_logic;  -- sda
  --sfp1_tx_fault      : in    std_logic;
  --sfp1_tx_disable    : out   std_logic;
  --sfp1_tx_los        : in    std_logic;

  --uart
  uart_rx            : in  std_logic;
  uart_tx            : out std_logic;
  
  -- user interface
  sfp0_led           : out std_logic;
  sfp1_led           : out std_logic;
  --ext_clk            : out std_logic;
  usr_button         : in  std_logic;
  usr_led1           : out std_logic;
  usr_led2           : out std_logic;
  pps_out            : out std_logic
);
end cute_wr_ref_top;

architecture rtl of cute_wr_ref_top is

------------------------------------------------------------------------------
-- components declaration
------------------------------------------------------------------------------
component cute_reset_gen is
  port (
    clk_sys_i : in std_logic;
    rst_button_n_a_i : in std_logic;
    rst_n_o : out std_logic
  );
end component;

component cute_serial_dac_arb is
  generic(
    g_invert_sclk    : boolean;
    g_num_extra_bits : integer);
  port(
    clk_i   : in std_logic;
    rst_n_i : in std_logic;

    val1_i  : in std_logic_vector(15 downto 0);
    load1_i : in std_logic;
    val2_i  : in std_logic_vector(15 downto 0);
    load2_i : in std_logic;

    dac_ldac_n_o : out std_logic;
    dac_clr_n_o  : out std_logic;
    dac_sync_n_o : out std_logic;
    dac_sclk_o   : out std_logic;
    dac_din_o    : out std_logic);

end component;

component cute_core_ref_top is
  generic
    (
      g_simulation                : integer              := 0;
      g_dpram_initf : string := "../../bin/wrpc/wrc_phy8.bram";
      g_sfp0_enable               : boolean:= true;
      g_sfp1_enable               : boolean:= false;
      g_aux_sdb                   : t_sdb_device  := c_xwb_xil_multiboot_sdb;
      g_multiboot_enable          : boolean:= false);
  port
    (
      rst_n_i              : in  std_logic;
      clk_20m_i            : in  std_logic;
      clk_dmtd_i           : in  std_logic;
      clk_sys_i            : in  std_logic;    
      clk_ref_i            : in  std_logic;
      clk_sfp0_i           : in  std_logic :='0';
      clk_sfp1_i           : in  std_logic :='0';
      dac_hpll_load_p1_o   : out std_logic;
      dac_hpll_data_o      : out std_logic_vector(15 downto 0);
      dac_dpll_load_p1_o   : out std_logic;
      dac_dpll_data_o      : out std_logic_vector(15 downto 0);
      eeprom_scl_i         : in  std_logic;
      eeprom_scl_o         : out std_logic;
      eeprom_sda_i         : in  std_logic;
      eeprom_sda_o         : out std_logic;
      flash_sclk_o         : out std_logic;
      flash_ncs_o          : out std_logic;
      flash_mosi_o         : out std_logic;
      flash_miso_i         : in  std_logic:='1';
      onewire_i            : in  std_logic;
      onewire_oen_o        : out std_logic;
      uart_rxd_i           : in  std_logic:='0';
      uart_txd_o           : out std_logic;
      sfp0_txp_o           : out std_logic;
      sfp0_txn_o           : out std_logic;
      sfp0_rxp_i           : in  std_logic:='0';
      sfp0_rxn_i           : in  std_logic:='0';
      sfp0_det_i           : in  std_logic:='0';  -- sfp detect
      sfp0_scl_i           : in  std_logic:='0';  -- scl
      sfp0_scl_o           : out std_logic;  -- scl
      sfp0_sda_i           : in  std_logic:='0';  -- sda
      sfp0_sda_o           : out std_logic;  -- sda
      sfp0_rate_select_o   : out std_logic;
      sfp0_tx_fault_i      : in  std_logic:='0';
      sfp0_tx_disable_o    : out std_logic;
      sfp0_los_i           : in  std_logic:='0';
      sfp0_refclk_sel_i    : in  std_logic_vector(2 downto 0):="000";
      sfp0_rx_rbclk_o      : out std_logic;
      sfp1_txp_o           : out std_logic;
      sfp1_txn_o           : out std_logic;
      sfp1_rxp_i           : in  std_logic:='0';
      sfp1_rxn_i           : in  std_logic:='0';
      sfp1_det_i           : in  std_logic:='0';
      sfp1_scl_i           : in  std_logic:='0';
      sfp1_scl_o           : out std_logic:='0';
      sfp1_sda_i           : in  std_logic:='0';
      sfp1_sda_o           : out std_logic:='0';
      sfp1_rate_select_o   : out std_logic;
      sfp1_tx_fault_i      : in  std_logic:='0';
      sfp1_tx_disable_o    : out std_logic;
      sfp1_los_i           : in  std_logic:='0';
      sfp1_refclk_sel_i    : in  std_logic_vector(2 downto 0):="000";
      sfp1_rx_rbclk_o      : out std_logic;
      wb_slave_o           : out t_wishbone_slave_out;
      wb_slave_i           : in  t_wishbone_slave_in := cc_dummy_slave_in;
      aux_master_o         : out t_wishbone_master_out;
      aux_master_i         : in  t_wishbone_master_in := cc_dummy_master_in;
      wrf_src_o            : out t_wrf_source_out;
      wrf_src_i            : in  t_wrf_source_in := c_dummy_src_in;
      wrf_snk_o            : out t_wrf_sink_out;
      wrf_snk_i            : in  t_wrf_sink_in   := c_dummy_snk_in;
      wb_eth_master_o      : out t_wishbone_master_out;
      wb_eth_master_i      : in  t_wishbone_master_in := cc_dummy_master_in;
      tm_link_up_o         : out std_logic;
      tm_time_valid_o      : out std_logic;
      tm_tai_o             : out std_logic_vector(39 downto 0);
      tm_cycles_o          : out std_logic_vector(27 downto 0);
      led_act_o            : out std_logic;
      led_link_o           : out std_logic;
      btn1_i               : in  std_logic := '1';
      btn2_i               : in  std_logic := '1';
      pps_p_o              : out std_logic;
      pps_led_o            : out std_logic;
      pps_csync_o          : out std_logic;
      link_ok_o            : out std_logic
      );
end component;

------------------------------------------------------------------------------
-- signals declaration
------------------------------------------------------------------------------
-- reset
  signal local_reset_n : std_logic;
-- clock
  signal fpga_clk_i    : std_logic;
  signal clk_ref_i     : std_logic;
  signal clk_sys_i     : std_logic;
  signal clk_dmtd_i    : std_logic;
  signal clk_sfp0_i    : std_logic;
  signal clk_sfp1_i    : std_logic;
  signal clk_20m_buf   : std_logic;
  signal pllout_clk_62_5   : std_logic;
  signal pllout_clk_125    : std_logic;
  signal pllout_clk_fb_ref : std_logic;
  signal pllout_clk_fb_dmtd: std_logic;
  signal pllout_clk_dmtd   : std_logic;
  signal eeprom_scl_o      : std_logic;
  signal eeprom_scl_i      : std_logic;
  signal eeprom_sda_o      : std_logic;
  signal eeprom_sda_i      : std_logic;
  signal onewire_i         : std_logic;
  signal onewire_oen_o     : std_logic;
  signal sfp0_scl_i        : std_logic;
  signal sfp0_scl_o        : std_logic;
  signal sfp0_sda_i        : std_logic;
  signal sfp0_sda_o        : std_logic;
  signal sfp1_scl_i        : std_logic;
  signal sfp1_scl_o        : std_logic;
  signal sfp1_sda_i        : std_logic;
  signal sfp1_sda_o        : std_logic;
  signal dac_hpll_load_p1  : std_logic;
  signal dac_dpll_load_p1  : std_logic;
  signal dac_hpll_data     : std_logic_vector(15 downto 0);
  signal dac_dpll_data     : std_logic_vector(15 downto 0);
  
  signal pps               : std_logic;
  signal pps_p1            : std_logic;
  signal tm_tai            : std_logic_vector(39 downto 0);
  signal tm_tai_valid      : std_logic;
  -- Wishbone buse(s) from masters attached to crossbar
  signal cnx_master_out : t_wishbone_master_out_array(0 downto 0);
  signal cnx_master_in  : t_wishbone_master_in_array(0 downto 0);
  -- Wishbone buse(s) to slaves attached to crossbar
  signal cnx_slave_out : t_wishbone_slave_out_array(0 downto 0);
  signal cnx_slave_in  : t_wishbone_slave_in_array(0 downto 0);

begin

u_reset_gen : cute_reset_gen
  port map (
    clk_sys_i        => clk_sys_i,
    rst_button_n_a_i => usr_button,
    rst_n_o          => local_reset_n);

cmp_refclk_buf : ibufgds
  generic map (
    diff_term    => true,             -- differential termination
    ibuf_low_pwr => true,  -- low power (true) vs. performance (false) setting for referenced i/o standards
    iostandard   => "default")
  port map (
    o  => fpga_clk_i,            -- buffer output
    i  => fpga_clk_p,  -- diff_p buffer input (connect directly to top-level port)
    ib => fpga_clk_n); -- diff_n buffer input (connect directly to top-level port)

cmp_clk_vcxo_buf : bufg
  port map (
    o => clk_20m_buf,
    i => clk20);
    
cmp_sfp0_dedicated_clk_buf : ibufds
 generic map(
   diff_term    => true,
   ibuf_low_pwr => true,
   iostandard   => "default")
 port map (
   o  => clk_sfp0_i,
   i  => sfp0_ref_clk_p,
   ib => sfp0_ref_clk_n);

cmp_sfp1_dedicated_clk_buf : ibufds
  generic map(
    diff_term    => true,
    ibuf_low_pwr => true,
    iostandard   => "default")
  port map (
    o  => clk_sfp1_i,
    i  => sfp1_ref_clk_p,
    ib => sfp1_ref_clk_n);

cmp_sys_clk_pll : pll_base
  generic map (
    bandwidth          => "optimized",
    clk_feedback       => "clkfbout",
    compensation       => "internal",
    divclk_divide      => 1,
    clkfbout_mult      => 8,
    clkfbout_phase     => 0.000,
    clkout0_divide     => 16,        -- 62.5 mhz
    clkout0_phase      => 0.000,
    clkout0_duty_cycle => 0.500,
    clkout1_divide     => 8,         -- 125 mhz
    clkout1_phase      => 0.000,
    clkout1_duty_cycle => 0.500,
    clkout2_divide     => 4,         -- 250 mhz
    clkout2_phase      => 0.000,
    clkout2_duty_cycle => 0.500,
    clkin_period       => 8.0,
    ref_jitter         => 0.016)
  port map (
    clkfbout => pllout_clk_fb_ref,
    clkout0  => pllout_clk_62_5,
    clkout1  => pllout_clk_125,
    clkout2  => open,
    clkout3  => open,
    clkout4  => open,
    clkout5  => open,
    locked   => open,
    rst      => '0',
    clkfbin  => pllout_clk_fb_ref,
    clkin    => fpga_clk_i);

cmp_dmtd_clk_pll : pll_base
  generic map (
    bandwidth          => "optimized",
    clk_feedback       => "clkfbout",
    compensation       => "internal",
    divclk_divide      => 1,
    clkfbout_mult      => 50,
    clkfbout_phase     => 0.000,
    clkout0_divide     => 16,         -- 62.5 mhz
    clkout0_phase      => 0.000,
    clkout0_duty_cycle => 0.500,
    clkout1_divide     => 16,         -- 62.5 mhz
    clkout1_phase      => 0.000,
    clkout1_duty_cycle => 0.500,
    clkout2_divide     => 16,         -- 62.5 mhz
    clkout2_phase      => 0.000,
    clkout2_duty_cycle => 0.500,
    clkin_period       => 50.0,
    ref_jitter         => 0.016)
  port map (
    clkfbout => pllout_clk_fb_dmtd,
    clkout0  => pllout_clk_dmtd,
    clkout1  => open,
    clkout2  => open,
    clkout3  => open,
    clkout4  => open,
    clkout5  => open,
    locked   => open,
    rst      => '0',
    clkfbin  => pllout_clk_fb_dmtd,
    clkin    => clk_20m_buf);

cmp_clk_sys_buf : bufg
  port map (
    o => clk_sys_i,
    i => pllout_clk_62_5);

cmd_clk_ref_buf: bufg
  port map(
    o => clk_ref_i,
    i => pllout_clk_125);

cmp_clk_dmtd_buf : bufg
  port map (
    o => clk_dmtd_i,
    i => pllout_clk_dmtd);

u_wr_core : cute_core_ref_top
  generic map(
    g_dpram_initf => g_dpram_initf,
    g_sfp0_enable => g_sfp0_enable,
    g_sfp1_enable => g_sfp1_enable,
    g_aux_sdb     => g_aux_sdb,
    g_multiboot_enable => g_multiboot_enable)
  port map (
    rst_n_i             => local_reset_n,
    clk_20m_i           => clk_20m_buf,
    clk_sys_i           => clk_sys_i,
    clk_dmtd_i          => clk_dmtd_i,
    clk_ref_i           => clk_ref_i,
    clk_sfp0_i          => clk_sfp0_i,
    clk_sfp1_i          => clk_sfp1_i,
    dac_hpll_load_p1_o  => dac_hpll_load_p1,
    dac_hpll_data_o     => dac_hpll_data,
    dac_dpll_load_p1_o  => dac_dpll_load_p1,
    dac_dpll_data_o     => dac_dpll_data,
    eeprom_scl_i        => eeprom_scl_i,
    eeprom_scl_o        => eeprom_scl_o,
    eeprom_sda_i        => eeprom_sda_i,
    eeprom_sda_o        => eeprom_sda_o,
    onewire_i           => onewire_i,
    onewire_oen_o       => onewire_oen_o,
    flash_sclk_o        => flash_sclk_o,
    flash_ncs_o         => flash_ncs_o,
    flash_mosi_o        => flash_mosi_o,
    flash_miso_i        => flash_miso_i,
    uart_rxd_i          => uart_rx,
    uart_txd_o          => uart_tx,
    sfp0_txp_o          => sfp0_tx_p,
    sfp0_txn_o          => sfp0_tx_n,
    sfp0_rxp_i          => sfp0_rx_p,
    sfp0_rxn_i          => sfp0_rx_n,
    sfp0_det_i          => sfp0_det,
    sfp0_scl_i          => sfp0_scl_i,
    sfp0_scl_o          => sfp0_scl_o,
    sfp0_sda_i          => sfp0_sda_i,
    sfp0_sda_o          => sfp0_sda_o,
    sfp0_rate_select_o  => open,
    sfp0_tx_fault_i     => sfp0_tx_fault,
    sfp0_tx_disable_o   => sfp0_tx_disable,
    sfp0_los_i          => sfp0_los,
    sfp0_refclk_sel_i   => "100",
    sfp0_rx_rbclk_o     => open,
    --sfp1_txp_o          => sfp1_tx_p,
    --sfp1_txn_o          => sfp1_tx_n,
    --sfp1_rxp_i          => sfp1_rx_p,
    --sfp1_rxn_i          => sfp1_rx_n,
    --sfp1_det_i          => sfp1_det,
    --sfp1_scl_i          => sfp1_scl_i,
    --sfp1_scl_o          => sfp1_scl_o,
    --sfp1_sda_i          => sfp1_sda_i,
    --sfp1_sda_o          => sfp1_sda_o,
    --sfp1_rate_select_o  => open,
    --sfp1_tx_fault_i     => sfp1_tx_fault,
    --sfp1_tx_disable_o   => sfp1_tx_disable,
    --sfp1_los_i          => sfp1_tx_los,
    --sfp1_refclk_sel_i   => "100",
    --sfp1_rx_rbclk_o     => open,
    wb_slave_o          => cnx_slave_out(0),
    wb_slave_i          => cnx_slave_in(0),
    wb_eth_master_o     => cnx_master_out(0),
    wb_eth_master_i     => cnx_master_in(0),
    tm_link_up_o        => open,
    tm_time_valid_o     => tm_tai_valid,
    tm_tai_o            => tm_tai,
    tm_cycles_o         => open,
    led_act_o           => sfp0_led,
    led_link_o          => sfp1_led,
    pps_p_o             => pps_out,
    pps_led_o           => usr_led1,
    pps_csync_o         => pps_p1,
    link_ok_o           => usr_led2);
  
  cnx_slave_in <= cnx_master_out;
  cnx_master_in <= cnx_slave_out;

  u_dac_arb: cute_serial_dac_arb
  generic map (
    g_invert_sclk => false,
    g_num_extra_bits => 8)
  port map (
    clk_i         => clk_sys_i,
    rst_n_i       => local_reset_n,
    val1_i        => dac_dpll_data,
    load1_i       => dac_dpll_load_p1,
    val2_i        => dac_hpll_data,
    load2_i       => dac_hpll_load_p1,
    dac_sync_n_o  => plldac_sync_n,
    dac_ldac_n_o  => plldac_load_n,
    dac_clr_n_o   => plldac_clr_n,
    dac_sclk_o    => plldac_sclk,
    dac_din_o     => plldac_din);

  eeprom_scl  <= '0' when eeprom_scl_o = '0' else 'Z';
  eeprom_sda  <= '0' when eeprom_sda_o = '0' else 'Z';
  eeprom_scl_i  <= eeprom_scl;
  eeprom_sda_i  <= eeprom_sda;

  sfp0_scl <= '0' when sfp0_scl_o = '0' else 'Z';
  sfp0_sda <= '0' when sfp0_sda_o = '0' else 'Z';
  sfp0_scl_i <= sfp0_scl;
  sfp0_sda_i <= sfp0_sda;
  --sfp1_scl <= '0' when sfp1_scl_o = '0' else 'Z';
  --sfp1_sda <= '0' when sfp1_sda_o = '0' else 'Z';
  --sfp1_scl_i <= sfp1_scl;
  --sfp1_sda_i <= sfp1_sda;
  
  one_wire <= '0' when onewire_oen_o = '1' else 'Z';
  onewire_i  <= one_wire;
  
end rtl;
