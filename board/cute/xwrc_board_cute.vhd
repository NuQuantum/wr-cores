-------------------------------------------------------------------------------
-- Title      : WRPC Wrapper for CUTE
-- Project    : WR PTP Core
-- URL        : http://www.ohwr.org/projects/wr-cores/wiki/Wrpc_core
-------------------------------------------------------------------------------
-- File       : xwrc_board_cute.vhd
-- Author(s)  : Hongming Li <lihm.thu@foxmail.com>
-- Company    : Tsinghua Univ. (DEP)
-- Created    : 2018-07-14
-- Last update: 2018-07-14
-- Standard   : VHDL'93
-------------------------------------------------------------------------------
-- Description: Top-level wrapper for WR PTP core including all the modules
-- needed to operate the core on the CUTE board.
-------------------------------------------------------------------------------
-- Copyright (c) 2017 CERN
-------------------------------------------------------------------------------
-- GNU LESSER GENERAL PUBLIC LICENSE
--
-- This source file is free software; you can redistribute it   
-- and/or modify it under the terms of the GNU Lesser General   
-- Public License as published by the Free Software Foundation; 
-- either version 2.1 of the License, or (at your option) any   
-- later version.                                               
--
-- This source is distributed in the hope that it will be       
-- useful, but WITHOUT ANY WARRANTY; without even the implied   
-- warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR      
-- PURPOSE.  See the GNU Lesser General Public License for more 
-- details.                                                     
--
-- You should have received a copy of the GNU Lesser General    
-- Public License along with this source; if not, download it   
-- from http://www.gnu.org/licenses/lgpl-2.1.html
-- 
-------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;

library work;
use work.gencores_pkg.all;
use work.wrcore_pkg.all;
use work.wishbone_pkg.all;
use work.wr_fabric_pkg.all;
use work.endpoint_pkg.all;
use work.streamers_pkg.all;
use work.wr_xilinx_pkg.all;
use work.wr_board_pkg.all;
use work.wr_cute_pkg.all;

library unisim;
use unisim.vcomponents.all;

entity xwrc_board_cute is
  generic(
    -- set to 1 to speed up some initialization processes during simulation
    g_simulation                : integer              := 0;
    -- Select whether to include external ref clock input
    g_with_external_clock_input : boolean              := false;
    -- Number of aux clocks syntonized by WRPC to WR timebase
    g_aux_clks                  : integer              := 0;
    -- plain     = expose WRC fabric interface
    -- streamers = attach WRC streamers to fabric interface
    -- etherbone = attach Etherbone slave to fabric interface
    g_fabric_iface              : t_board_fabric_iface := plain;
    -- parameters configuration when g_fabric_iface = "streamers" (otherwise ignored)
    g_streamers_op_mode        : t_streamers_op_mode  := TX_AND_RX;
    g_tx_streamer_params       : t_tx_streamer_params := c_tx_streamer_params_defaut;
    g_rx_streamer_params       : t_rx_streamer_params := c_rx_streamer_params_defaut;
    g_aux_sdb                   : t_sdb_device         := c_wrc_periph3_sdb;
    -- memory initialisation file for embedded CPU
    g_dpram_initf               : string               := "default_xilinx";
    -- identification (id and ver) of the layout of words in the generic diag interface
    g_diag_id                   : integer              := 0;
    g_diag_ver                  : integer              := 0;
    -- size the generic diag interface
    g_diag_ro_size              : integer              := 0;
    g_diag_rw_size              : integer              := 0;
    -- cute special
    g_sfp0_enable               : boolean:= true;
    g_sfp1_enable               : boolean:= false;
    g_multiboot_enable          : boolean:= false
    );
  port (
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
    -- Aux clocks, which can be disciplined by the WR Core
    clk_aux_i     : in  std_logic_vector(g_aux_clks-1 downto 0) := (others => '0');
    -- 10MHz ext ref clock input (g_with_external_clock_input = TRUE)
    clk_10m_ext_i : in  std_logic := '0';
    -- External PPS input (g_with_external_clock_input = TRUE)
    pps_ext_i     : in  std_logic := '0';

    ---------------------------------------------------------------------------
    -- Shared SPI interface to DACs
    ---------------------------------------------------------------------------
    dac_hpll_load_p1_o : out std_logic;
    dac_hpll_data_o    : out std_logic_vector(15 downto 0);
    dac_dpll_load_p1_o : out std_logic;
    dac_dpll_data_o    : out std_logic_vector(15 downto 0);

    ---------------------------------------------------------------------------
    -- SFP I/O for transceiver and SFP management info
    ---------------------------------------------------------------------------
    sfp0_txp_o         : out std_logic;
    sfp0_txn_o         : out std_logic;
    sfp0_rxp_i         : in  std_logic;
    sfp0_rxn_i         : in  std_logic;
    sfp0_det_i         : in  std_logic := '1';
    sfp0_sda_i         : in  std_logic;
    sfp0_sda_o         : out std_logic;
    sfp0_scl_i         : in  std_logic;
    sfp0_scl_o         : out std_logic;
    sfp0_rate_select_o : out std_logic;
    sfp0_tx_fault_i    : in  std_logic := '0';
    sfp0_tx_disable_o  : out std_logic;
    sfp0_los_i         : in  std_logic := '0';
    sfp0_refclk_sel_i  : in  std_logic_vector(2 downto 0);
    sfp0_rx_rbclk_o    : out std_logic;

    sfp1_txp_o         : out std_logic;
    sfp1_txn_o         : out std_logic;
    sfp1_rxp_i         : in  std_logic;
    sfp1_rxn_i         : in  std_logic;
    sfp1_det_i         : in  std_logic := '1';
    sfp1_sda_i         : in  std_logic;
    sfp1_sda_o         : out std_logic;
    sfp1_scl_i         : in  std_logic;
    sfp1_scl_o         : out std_logic;
    sfp1_rate_select_o : out std_logic;
    sfp1_tx_fault_i    : in  std_logic := '0';
    sfp1_tx_disable_o  : out std_logic;
    sfp1_los_i         : in  std_logic := '0';
    sfp1_refclk_sel_i  : in  std_logic_vector(2 downto 0);
    sfp1_rx_rbclk_o    : out std_logic;

    ---------------------------------------------------------------------------
    -- I2C EEPROM
    ---------------------------------------------------------------------------
    eeprom_sda_i : in  std_logic;
    eeprom_sda_o : out std_logic;
    eeprom_scl_i : in  std_logic;
    eeprom_scl_o : out std_logic;

    ---------------------------------------------------------------------------
    -- Onewire interface
    ---------------------------------------------------------------------------
    onewire_i     : in  std_logic;
    onewire_oen_o : out std_logic;

    ---------------------------------------------------------------------------
    -- UART
    ---------------------------------------------------------------------------
    uart_rxd_i : in  std_logic;
    uart_txd_o : out std_logic;

    ---------------------------------------------------------------------------
    -- Flash memory SPI interface
    ---------------------------------------------------------------------------
    flash_sclk_o : out std_logic;
    flash_ncs_o  : out std_logic;
    flash_mosi_o : out std_logic;
    flash_miso_i : in  std_logic;

    ---------------------------------------------------------------------------
    -- External WB interface
    ---------------------------------------------------------------------------
    wb_slave_o : out t_wishbone_slave_out;
    wb_slave_i : in  t_wishbone_slave_in := cc_dummy_slave_in;

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
    -- Generic diagnostics interface (access from WRPC via SNMP or uart console
    ---------------------------------------------------------------------------
    aux_diag_i : in  t_generic_word_array(g_diag_ro_size-1 downto 0) := (others => (others => '0'));
    aux_diag_o : out t_generic_word_array(g_diag_rw_size-1 downto 0);

    ---------------------------------------------------------------------------
    -- Aux clocks control
    ---------------------------------------------------------------------------
    tm_dac_value_o       : out std_logic_vector(23 downto 0);
    tm_dac_wr_o          : out std_logic_vector(g_aux_clks-1 downto 0);
    tm_clk_aux_lock_en_i : in  std_logic_vector(g_aux_clks-1 downto 0) := (others => '0');
    tm_clk_aux_locked_o  : out std_logic_vector(g_aux_clks-1 downto 0);

    ---------------------------------------------------------------------------
    -- External Tx Timestamping I/F
    ---------------------------------------------------------------------------
    timestamps_o     : out t_txtsu_timestamp;
    timestamps_ack_i : in  std_logic := '1';

    -----------------------------------------
    -- Timestamp helper signals, used for Absolute Calibration
    -----------------------------------------
    abscal_txts_o       : out std_logic;
    abscal_rxts_o       : out std_logic;

    ---------------------------------------------------------------------------
    -- Pause Frame Control
    ---------------------------------------------------------------------------
    fc_tx_pause_req_i   : in  std_logic                     := '0';
    fc_tx_pause_delay_i : in  std_logic_vector(15 downto 0) := x"0000";
    fc_tx_pause_ready_o : out std_logic;

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
    led_act_o  : out std_logic;
    led_link_o : out std_logic;
    btn1_i     : in  std_logic := '1';
    btn2_i     : in  std_logic := '1';
    -- 1PPS output
    pps_valid_o: out std_logic;
    pps_p_o    : out std_logic;
    pps_led_o  : out std_logic;
    pps_csync_o: out std_logic;
    -- Link ok indication
    link_ok_o  : out std_logic
    );

end entity xwrc_board_cute;


architecture struct of xwrc_board_cute is

  -----------------------------------------------------------------------------
  -- Signals
  -----------------------------------------------------------------------------
  -- OneWire
  signal onewire_in : std_logic_vector(1 downto 0);
  signal onewire_en : std_logic_vector(1 downto 0);

  -- PHY
  signal phy8_to_wrc   : t_phy_8bits_to_wrc;
  signal phy8_from_wrc : t_phy_8bits_from_wrc;

  -- External reference
  signal ext_ref_mul         : std_logic;
  signal ext_ref_mul_locked  : std_logic;
  signal ext_ref_mul_stopped : std_logic;
  signal ext_ref_rst         : std_logic;

  signal sfp_det_i   : std_logic;
  signal sfp_scl_i   : std_logic;
  signal sfp_scl_o   : std_logic;
  signal sfp_sda_i   : std_logic;
  signal sfp_sda_o   : std_logic;
 
  signal aux_master_out  :  t_wishbone_master_out;
  signal aux_master_in   :  t_wishbone_master_in := cc_dummy_master_in;

  signal multiboot_wb_out  : t_wishbone_master_out;
  signal multiboot_wb_in   : t_wishbone_master_in;
  signal multiboot_slave_out : t_wishbone_slave_out;
  signal multiboot_slave_in  : t_wishbone_slave_in := cc_dummy_slave_in;

begin  -- architecture struct

  -----------------------------------------------------------------------------
  -- The WR PTP core with optional fabric interface attached
  -----------------------------------------------------------------------------

  cmp_board_common : xwrc_board_common
    generic map (
      g_simulation                => g_simulation,
      g_with_external_clock_input => g_with_external_clock_input,
      g_board_name                => "CUTE",
      g_flash_secsz_kb            => 64,         -- sector size for M25P32
      g_flash_sdbfs_baddr         => 16#2e0000#, -- sdbfs after multiboot bitstream
      g_phys_uart                 => TRUE,
      g_virtual_uart              => TRUE,
      g_aux_clks                  => g_aux_clks,
      g_ep_rxbuf_size             => 1024,
      g_tx_runt_padding           => TRUE,
      g_dpram_initf               => g_dpram_initf,
      g_dpram_size                => 131072/4,
      g_interface_mode            => PIPELINED,
      g_address_granularity       => BYTE,
      g_aux_sdb                   => g_aux_sdb,
      g_softpll_enable_debugger   => FALSE,
      g_vuart_fifo_size           => 1024,
      g_pcs_16bit                 => FALSE,
      g_diag_id                   => g_diag_id,
      g_diag_ver                  => g_diag_ver,
      g_diag_ro_size              => g_diag_ro_size,
      g_diag_rw_size              => g_diag_rw_size,
      g_streamers_op_mode         => g_streamers_op_mode,
      g_tx_streamer_params        => g_tx_streamer_params,
      g_rx_streamer_params        => g_rx_streamer_params,
      g_fabric_iface              => g_fabric_iface
      )
    port map (
      clk_sys_i            => clk_sys_i,
      clk_dmtd_i           => clk_dmtd_i,
      clk_ref_i            => clk_ref_i,
      clk_aux_i            => clk_aux_i,
      clk_10m_ext_i        => clk_10m_ext_i,
      clk_ext_mul_i        => ext_ref_mul,
      clk_ext_mul_locked_i => ext_ref_mul_locked,
      clk_ext_stopped_i    => ext_ref_mul_stopped,
      clk_ext_rst_o        => ext_ref_rst,
      pps_ext_i            => pps_ext_i,
      rst_n_i              => rst_n_i,
      dac_hpll_load_p1_o   => dac_hpll_load_p1_o,
      dac_hpll_data_o      => dac_hpll_data_o,
      dac_dpll_load_p1_o   => dac_dpll_load_p1_o,
      dac_dpll_data_o      => dac_dpll_data_o,
      phy8_o               => phy8_from_wrc,
      phy8_i               => phy8_to_wrc,
      scl_o                => eeprom_scl_o,
      scl_i                => eeprom_scl_i,
      sda_o                => eeprom_sda_o,
      sda_i                => eeprom_sda_i,
      sfp_scl_o            => sfp_scl_o,
      sfp_scl_i            => sfp_scl_i,
      sfp_sda_o            => sfp_sda_o,
      sfp_sda_i            => sfp_sda_i,
      sfp_det_i            => sfp_det_i,
      spi_sclk_o           => flash_sclk_o,
      spi_ncs_o            => flash_ncs_o,
      spi_mosi_o           => flash_mosi_o,
      spi_miso_i           => flash_miso_i,
      uart_rxd_i           => uart_rxd_i,
      uart_txd_o           => uart_txd_o,
      owr_pwren_o          => open,
      owr_en_o             => onewire_en,
      owr_i                => onewire_in,
      wb_slave_i           => wb_slave_i,
      wb_slave_o           => wb_slave_o,
      aux_master_o         => aux_master_out,
      aux_master_i         => aux_master_in,
      wrf_src_o            => wrf_src_o,
      wrf_src_i            => wrf_src_i,
      wrf_snk_o            => wrf_snk_o,
      wrf_snk_i            => wrf_snk_i,
      wb_eth_master_o      => wb_eth_master_o,
      wb_eth_master_i      => wb_eth_master_i,
      aux_diag_i           => aux_diag_i,
      aux_diag_o           => aux_diag_o,
      tm_dac_value_o       => tm_dac_value_o,
      tm_dac_wr_o          => tm_dac_wr_o,
      tm_clk_aux_lock_en_i => tm_clk_aux_lock_en_i,
      tm_clk_aux_locked_o  => tm_clk_aux_locked_o,
      timestamps_o         => timestamps_o,
      timestamps_ack_i     => timestamps_ack_i,
      abscal_txts_o        => abscal_txts_o,
      abscal_rxts_o        => abscal_rxts_o,
      fc_tx_pause_req_i    => fc_tx_pause_req_i,
      fc_tx_pause_delay_i  => fc_tx_pause_delay_i,
      fc_tx_pause_ready_o  => fc_tx_pause_ready_o,
      tm_link_up_o         => tm_link_up_o,
      tm_time_valid_o      => tm_time_valid_o,
      tm_tai_o             => tm_tai_o,
      tm_cycles_o          => tm_cycles_o,
      led_act_o            => led_act_o,
      led_link_o           => led_link_o,
      btn1_i               => btn1_i,
      btn2_i               => btn2_i,
      pps_valid_o          => pps_valid_o,
      pps_p_o              => pps_p_o,
      pps_csync_o          => pps_csync_o,
      pps_led_o            => pps_led_o,
      link_ok_o            => link_ok_o);

  sfp0_rate_select_o <= '1';
  sfp1_rate_select_o <= '1';

  onewire_oen_o <= onewire_en(0);
  onewire_in(0) <= onewire_i;
  onewire_in(1) <= '1';

U_WRPC_SFP0: if (g_sfp0_enable = true) generate

  phy8_to_wrc.ref_clk        <= clk_ref_i;
  phy8_to_wrc.sfp_tx_fault   <= sfp0_tx_fault_i;
  phy8_to_wrc.sfp_los        <= sfp0_los_i;
  sfp0_tx_disable_o          <= phy8_from_wrc.sfp_tx_disable;
  sfp_det_i                  <= sfp0_det_i;
  sfp_scl_i                  <= sfp0_scl_i;
  sfp0_scl_o                 <= sfp_scl_o;
  sfp_sda_i                  <= sfp0_sda_i;
  sfp0_sda_o                 <= sfp_sda_o;
  sfp0_rx_rbclk_o            <= phy8_to_wrc.rx_clk;

  u_gtp0 : wr_gtp_phy_spartan6
  generic map (
    g_enable_ch0 => 0,
    g_enable_ch1 => 1,
    g_simulation => g_simulation)
  port map (
    gtp1_clk_i         => clk_sfp0_i,
    ch1_ref_clk_i      => clk_ref_i,
    ch1_tx_data_i      => phy8_from_wrc.tx_data,
    ch1_tx_k_i         => phy8_from_wrc.tx_k(0),
    ch1_tx_disparity_o => phy8_to_wrc.tx_disparity,
    ch1_tx_enc_err_o   => phy8_to_wrc.tx_enc_err,
    ch1_rx_rbclk_o     => phy8_to_wrc.rx_clk,
    ch1_rx_data_o      => phy8_to_wrc.rx_data,
    ch1_rx_k_o         => phy8_to_wrc.rx_k(0),
    ch1_rx_enc_err_o   => phy8_to_wrc.rx_enc_err,
    ch1_rx_bitslide_o  => phy8_to_wrc.rx_bitslide,
    ch1_rst_i          => phy8_from_wrc.rst,
    ch1_loopen_i       => phy8_from_wrc.loopen,
    ch1_loopen_vec_i   => phy8_from_wrc.loopen_vec,
    ch1_tx_prbs_sel_i  => phy8_from_wrc.tx_prbs_sel,
    ch1_rdy_o          => phy8_to_wrc.rdy,
    pad_txn1_o         => sfp0_txn_o,
    pad_txp1_o         => sfp0_txp_o,
    pad_rxn1_i         => sfp0_rxn_i,
    pad_rxp1_i         => sfp0_rxp_i,

    gtp0_clk_i         => '0',
    ch0_ref_clk_i      => clk_ref_i,
    ch0_tx_data_i      => x"00",
    ch0_tx_k_i         => '0',
    ch0_tx_disparity_o => open,
    ch0_tx_enc_err_o   => open,
    ch0_rx_data_o      => open,
    ch0_rx_rbclk_o     => open,
    ch0_rx_k_o         => open,
    ch0_rx_enc_err_o   => open,
    ch0_rx_bitslide_o  => open,
    ch0_rst_i          => '1',
    ch0_loopen_i       => '0',
    ch0_loopen_vec_i   => (others=>'0'),
    ch0_tx_prbs_sel_i  => (others=>'0'),
    ch0_rdy_o          => open,

    ch0_ref_sel_pll    => "100",
    ch1_ref_sel_pll    => sfp0_refclk_sel_i,

    pad_txn0_o         => open,
    pad_txp0_o         => open,
    pad_rxn0_i         => '0',
    pad_rxp0_i         => '0'
);

end generate;

U_WRPC_SFP1: if (g_sfp1_enable = true) generate
  
  phy8_to_wrc.ref_clk        <= clk_ref_i;
  phy8_to_wrc.sfp_tx_fault   <= sfp1_tx_fault_i;
  phy8_to_wrc.sfp_los        <= sfp1_los_i;
  sfp0_tx_disable_o          <= phy8_from_wrc.sfp_tx_disable;

  sfp_det_i                  <= sfp1_det_i;
  sfp_scl_i                  <= sfp1_scl_i;
  sfp1_scl_o                 <= sfp_scl_o;
  sfp_sda_i                  <= sfp1_sda_i;
  sfp1_sda_o                 <= sfp_sda_o;
  sfp1_rx_rbclk_o            <= phy8_to_wrc.rx_clk;

  u_gtp1 : wr_gtp_phy_spartan6
  generic map (
    g_enable_ch0 => 0,
    g_enable_ch1 => 1,
    g_simulation => g_simulation)
  port map (
    gtp1_clk_i         => clk_sfp1_i,
    ch1_ref_clk_i      => clk_ref_i,
    ch1_tx_data_i      => phy8_from_wrc.tx_data,
    ch1_tx_k_i         => phy8_from_wrc.tx_k(0),
    ch1_tx_disparity_o => phy8_to_wrc.tx_disparity,
    ch1_tx_enc_err_o   => phy8_to_wrc.tx_enc_err,
    ch1_rx_rbclk_o     => phy8_to_wrc.rx_clk,
    ch1_rx_data_o      => phy8_to_wrc.rx_data,
    ch1_rx_k_o         => phy8_to_wrc.rx_k(0),
    ch1_rx_enc_err_o   => phy8_to_wrc.rx_enc_err,
    ch1_rx_bitslide_o  => phy8_to_wrc.rx_bitslide,
    ch1_rst_i          => phy8_from_wrc.rst,
    ch1_loopen_i       => phy8_from_wrc.loopen,
    ch1_loopen_vec_i   => phy8_from_wrc.loopen_vec,
    ch1_tx_prbs_sel_i  => phy8_from_wrc.tx_prbs_sel,
    ch1_rdy_o          => phy8_to_wrc.rdy,
    pad_txn1_o         => sfp1_txn_o,
    pad_txp1_o         => sfp1_txp_o,
    pad_rxn1_i         => sfp1_rxn_i,
    pad_rxp1_i         => sfp1_rxp_i,
    gtp0_clk_i         => '0',
    ch0_ref_clk_i      => clk_ref_i,
    ch0_tx_data_i      => x"00",
    ch0_tx_k_i         => '0',
    ch0_tx_disparity_o => open,
    ch0_tx_enc_err_o   => open,
    ch0_rx_data_o      => open,
    ch0_rx_rbclk_o     => open,
    ch0_rx_k_o         => open,
    ch0_rx_enc_err_o   => open,
    ch0_rx_bitslide_o  => open,
    ch0_rst_i          => '1',
    ch0_loopen_i       => '0',
    ch0_loopen_vec_i   => (others=>'0'),
    ch0_tx_prbs_sel_i  => (others=>'0'),
    ch0_rdy_o          => open,

    ch0_ref_sel_pll    => "100",
    ch1_ref_sel_pll    => sfp1_refclk_sel_i,

    pad_txn0_o         => open,
    pad_txp0_o         => open,
    pad_rxn0_i         => '0',
    pad_rxp0_i         => '0'
  );

end generate;
  

U_WRPC_MULTIBOOT: if (g_multiboot_enable = true) generate

  multiboot_slave_in   <= aux_master_out;
  aux_master_in        <= multiboot_slave_out;
  aux_master_o         <= cc_dummy_master_out;

  cmp_clock_crossing: xwb_clock_crossing
    port map (
      slave_clk_i     => clk_sys_i,
      slave_rst_n_i   => rst_n_i,
      slave_i         => multiboot_slave_in,
      slave_o         => multiboot_slave_out,
      master_clk_i    => clk_20m_i,
      master_rst_n_i  => rst_n_i,
      master_i        => multiboot_wb_in,
      master_o        => multiboot_wb_out);

  u_multiboot: xwb_xil_multiboot
    port map (
      clk_i   => clk_20m_i,
      rst_n_i => rst_n_i,
      wbs_i   => multiboot_wb_out,
      wbs_o   => multiboot_wb_in,
      spi_cs_n_o => open,
      spi_sclk_o => open,
      spi_mosi_o => open,
      spi_miso_i => '0');

end generate;

U_WRPC_NO_MULTIBOOT: if (g_multiboot_enable = false) generate
  aux_master_o   <= aux_master_out;
  aux_master_in  <= aux_master_i;
end generate;

end architecture struct;
