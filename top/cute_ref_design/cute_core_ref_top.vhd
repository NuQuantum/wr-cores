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

entity cute_core_ref_top is
  generic
    (
      -- set to 1 to speed up some initialization processes during simulation
      g_simulation                : integer              := 0;
      g_dpram_initf               : string :=   "../../bin/wrpc/wrc_phy8.bram";
      g_sfp0_enable               : boolean:= true;
      g_sfp1_enable               : boolean:= false;
      g_aux_sdb                   : t_sdb_device  := c_xwb_tcpip_sdb;
      g_multiboot_enable          : boolean:= false
     );
  port
    (
      ---------------------------------------------------------------------------
      -- Clocks/resets
      ---------------------------------------------------------------------------
      -- Reset input (active low, can be async)
      rst_n_i       : in  std_logic;
      -- Clock input, used to derive the DDMTD clock
      clk_20m_i     : in std_logic;
      -- 62.5m dmtd clock, from pll drived by clk_20m_vcxo
      clk_dmtd_i    : in std_logic;
      -- 62.5m system clock, from pll drived by clk_125m_pllref
      clk_sys_i     : in std_logic;    
      -- 125m reference clock, from pll drived by clk_125m_pllref
      clk_ref_i     : in std_logic;
      -- Dedicated clock for the Xilinx GTP transceiver.
      clk_sfp0_i    : in std_logic :='0';
      clk_sfp1_i    : in std_logic :='0';
      ---------------------------------------------------------------------------
      -- Shared SPI interface to DACs
      ---------------------------------------------------------------------------
      dac_hpll_load_p1_o : out std_logic;
      dac_hpll_data_o    : out std_logic_vector(15 downto 0);
      dac_dpll_load_p1_o : out std_logic;
      dac_dpll_data_o    : out std_logic_vector(15 downto 0);

      ---------------------------------------------------------------------------
      -- I2C EEPROM
      ---------------------------------------------------------------------------
      eeprom_scl_i : in  std_logic;
      eeprom_scl_o : out std_logic;
      eeprom_sda_i : in  std_logic;
      eeprom_sda_o : out std_logic;

      ---------------------------------------------------------------------------
      -- Flash memory SPI interface
      ---------------------------------------------------------------------------
      flash_sclk_o : out std_logic;
      flash_ncs_o  : out std_logic;
      flash_mosi_o : out std_logic;
      flash_miso_i : in  std_logic:='1';

      ---------------------------------------------------------------------------
      -- Onewire interface, Temp Sensor DS18B20
      ---------------------------------------------------------------------------
      onewire_i     : in  std_logic;
      onewire_oen_o : out std_logic;

      ---------------------------------------------------------------------------
      -- UART
      ---------------------------------------------------------------------------
      uart_rxd_i : in  std_logic:='0';
      uart_txd_o : out std_logic;

      ---------------------------------------------------------------------------
      -- SFP I/O for transceiver and SFP management info
      ---------------------------------------------------------------------------
      sfp0_txp_o        : out std_logic;
      sfp0_txn_o        : out std_logic;
      sfp0_rxp_i        : in  std_logic:='0';
      sfp0_rxn_i        : in  std_logic:='0';
      sfp0_det_i        : in  std_logic:='0';  -- sfp detect
      sfp0_scl_i        : in  std_logic:='0';  -- scl
      sfp0_scl_o        : out std_logic;  -- scl
      sfp0_sda_i        : in  std_logic:='0';  -- sda
      sfp0_sda_o        : out std_logic;  -- sda
      sfp0_rate_select_o: out std_logic;
      sfp0_tx_fault_i   : in  std_logic:='0';
      sfp0_tx_disable_o : out std_logic;
      sfp0_los_i        : in  std_logic:='0';
      sfp0_rx_rbclk_o   : out std_logic;
      sfp1_txp_o        : out std_logic;
      sfp1_txn_o        : out std_logic;
      sfp1_rxp_i        : in  std_logic:='0';
      sfp1_rxn_i        : in  std_logic:='0';
      sfp1_det_i        : in  std_logic:='0';
      sfp1_scl_i        : in  std_logic:='0';
      sfp1_scl_o        : out std_logic:='0';
      sfp1_sda_i        : in  std_logic:='0';
      sfp1_sda_o        : out std_logic:='0';
      sfp1_rate_select_o: out std_logic;
      sfp1_tx_fault_i   : in  std_logic:='0';
      sfp1_tx_disable_o : out std_logic;
      sfp1_los_i        : in  std_logic:='0';
      sfp1_rx_rbclk_o   : out std_logic;
      
      ---------------------------------------------------------------------------
      -- External WB interface
      ---------------------------------------------------------------------------
      wb_slave_o   : out t_wishbone_slave_out;
      wb_slave_i   : in  t_wishbone_slave_in := cc_dummy_slave_in;

      aux_master_o : out t_wishbone_master_out;
      aux_master_i : in  t_wishbone_master_in := cc_dummy_master_in;
      
      ---------------------------------------------------------------------------
      -- WR fabric interface (when g_fabric_iface = "plainfbrc")
      ---------------------------------------------------------------------------
      wrf_src_o : out t_wrf_source_out;
      wrf_src_i : in  t_wrf_source_in := c_dummy_src_in;
      wrf_snk_o : out t_wrf_sink_out;
      wrf_snk_i : in  t_wrf_sink_in   := c_dummy_snk_in;

      ---------------------------------------------------------------------------
      -- Etherbone WB master interface (when g_fabric_iface = "etherbone")
      ---------------------------------------------------------------------------
      wb_eth_master_o : out t_wishbone_master_out;
      wb_eth_master_i : in  t_wishbone_master_in := cc_dummy_master_in;

      ---------------------------------------------------------------------------
      -- Timecode I/F
      ---------------------------------------------------------------------------
      tm_link_up_o    : out std_logic;
      tm_time_valid_o : out std_logic;
      tm_tai_o        : out std_logic_vector(39 downto 0);
      tm_cycles_o     : out std_logic_vector(27 downto 0);

      ---------------------------------------------------------------------------
      -- Buttons, LEDs and PPS output
      ---------------------------------------------------------------------------
      led_act_o      : out std_logic;
      led_link_o     : out std_logic;
      btn1_i         : in  std_logic := '1';
      btn2_i         : in  std_logic := '1';
      -- 1PPS output
      pps_valid_o    : out std_logic;
      pps_p_o        : out std_logic;
      pps_led_o      : out std_logic;
      pps_csync_o    : out std_logic;
      -- Link ok indication
      link_ok_o      : out std_logic
      );
end cute_core_ref_top;

architecture rtl of cute_core_ref_top is

begin
  
  cmp_xwrc_board_cute : xwrc_board_cute
  generic map (
    g_simulation                => g_simulation,
    g_with_external_clock_input => false,
    g_dpram_initf               => g_dpram_initf,
    g_fabric_iface              => PLAIN,
    g_aux_sdb                   => g_aux_sdb,
    g_sfp0_enable               => g_sfp0_enable,
    g_sfp1_enable               => g_sfp1_enable,
    g_multiboot_enable          => g_multiboot_enable)
  port map (
    rst_n_i                => rst_n_i,          
    clk_20m_i              => clk_20m_i,            
    clk_dmtd_i             => clk_dmtd_i,             
    clk_sys_i              => clk_sys_i,            
    clk_ref_i              => clk_ref_i,            
    clk_sfp0_i             => clk_sfp0_i,             
    clk_sfp1_i             => clk_sfp1_i,             
    dac_hpll_load_p1_o     => dac_hpll_load_p1_o,
    dac_hpll_data_o        => dac_hpll_data_o,
    dac_dpll_load_p1_o     => dac_dpll_load_p1_o,
    dac_dpll_data_o        => dac_dpll_data_o,
    sfp0_txp_o             => sfp0_txp_o,
    sfp0_txn_o             => sfp0_txn_o,
    sfp0_rxp_i             => sfp0_rxp_i,
    sfp0_rxn_i             => sfp0_rxn_i,
    sfp0_det_i             => sfp0_det_i,
    sfp0_scl_i             => sfp0_scl_i,
    sfp0_scl_o             => sfp0_scl_o,
    sfp0_sda_i             => sfp0_sda_i,
    sfp0_sda_o             => sfp0_sda_o,
    sfp0_rate_select_o     => sfp0_rate_select_o,
    sfp0_tx_fault_i        => sfp0_tx_fault_i,
    sfp0_tx_disable_o      => sfp0_tx_disable_o,
    sfp0_los_i             => sfp0_los_i,
    sfp0_rx_rbclk_o        => sfp0_rx_rbclk_o,
    sfp1_txp_o             => sfp1_txp_o,
    sfp1_txn_o             => sfp1_txn_o,
    sfp1_rxp_i             => sfp1_rxp_i,
    sfp1_rxn_i             => sfp1_rxn_i,
    sfp1_det_i             => sfp1_det_i,
    sfp1_scl_i             => sfp1_scl_i,
    sfp1_scl_o             => sfp1_scl_o,
    sfp1_sda_i             => sfp1_sda_i,
    sfp1_sda_o             => sfp1_sda_o,
    sfp1_rate_select_o     => sfp1_rate_select_o,
    sfp1_tx_fault_i        => sfp1_tx_fault_i,
    sfp1_tx_disable_o      => sfp1_tx_disable_o,
    sfp1_los_i             => sfp1_los_i,
    sfp1_rx_rbclk_o        => sfp1_rx_rbclk_o,
    eeprom_scl_i           => eeprom_scl_i,
    eeprom_scl_o           => eeprom_scl_o,
    eeprom_sda_i           => eeprom_sda_i,
    eeprom_sda_o           => eeprom_sda_o,
    onewire_i              => onewire_i,
    onewire_oen_o          => onewire_oen_o,
    uart_rxd_i             => uart_rxd_i,
    uart_txd_o             => uart_txd_o,
    flash_sclk_o           => flash_sclk_o,
    flash_ncs_o            => flash_ncs_o,
    flash_mosi_o           => flash_mosi_o,
    flash_miso_i           => flash_miso_i,
    wb_slave_o             => wb_slave_o,
    wb_slave_i             => wb_slave_i,
    aux_master_o           => aux_master_o,
    aux_master_i           => aux_master_i,
    wrf_src_o              => wrf_src_o,
    wrf_src_i              => wrf_src_i,
    wrf_snk_o              => wrf_snk_o,
    wrf_snk_i              => wrf_snk_i,
    wb_eth_master_o        => wb_eth_master_o,
    wb_eth_master_i        => wb_eth_master_i,
    tm_link_up_o           => tm_link_up_o,
    tm_time_valid_o        => tm_time_valid_o,
    tm_tai_o               => tm_tai_o,
    tm_cycles_o            => tm_cycles_o,
    led_act_o              => led_act_o,
    led_link_o             => led_link_o,
    pps_led_o              => pps_led_o,
    btn1_i                 => btn1_i,
    btn2_i                 => btn2_i,
    pps_valid_o            => pps_valid_o,
    pps_p_o                => pps_p_o,
    pps_csync_o            => pps_csync_o,
    link_ok_o              => link_ok_o);

end rtl;
