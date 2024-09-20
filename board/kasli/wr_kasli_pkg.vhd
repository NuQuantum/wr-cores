-------------------------------------------------------------------------------
-- Title      : WRPC Wrapper for kasli package
-- Project    : WR PTP Core
-- URL        : http://www.ohwr.org/projects/wr-cores/wiki/Wrpc_core
-------------------------------------------------------------------------------
-- File       : wr_kasli_pkg.vhd
-- Author(s)  : Jonah Foley <jonah.foley@nu-quantum.com>
-- Company    : Nu Quantum Ltd.
-- Created    : 2017-08-02
-- Last update: 2017-09-07
-- Standard   : VHDL'93
-------------------------------------------------------------------------------
--
-- Copyright (c) 2017 CERN
--
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
-- vsg_off port_012
-------------------------------------------------------------------------------

library ieee;
  use ieee.std_logic_1164.all;

library work;
  use work.wishbone_pkg.all;
  use work.wrcore_pkg.all;
  use work.wr_fabric_pkg.all;
  use work.endpoint_pkg.all;
  use work.wr_board_pkg.all;
  use work.axi4_pkg.all;
  use work.streamers_pkg.all;
  use work.wr_xilinx_pkg.all;
  use work.xwrc_board_kasli_regs_pkg.all;

package wr_kasli_pkg is

  -----------------------------------------------------------------------------
  -- Constants
  -----------------------------------------------------------------------------

  constant c_num_wb_crossbar_slaves           : integer := 5;
  constant c_wb_crossbar_address_vector_width : integer := c_wishbone_address_width * c_num_wb_crossbar_slaves;

  constant c_num_aux_clocks : integer := 3;

  -- Address Map for the componenets connected to the WB_Crossbar outside the WRPC core - secondary crossbar.
  -- Addresses in the range 0x00020000 to 0x00020800 belong to HDL modules connected to the primary crossar.
  -- Also 0x0008000 is reserved as Auxillary space (Etherbone config, etc).
  -- At the primary crossbar:
  --   0x00020000: Peripheral interconnect
  constant c_wb_crossbar_addr_kasli_periph : std_logic_vector((c_wishbone_address_width * c_num_wb_crossbar_slaves)-1 downto 0) :=
                                     x"000A_0000" & -- secbar_master_in(0): SI549 (0)
                                     x"0008_0000" & -- secbar_master_in(2): SI549 (1)
                                     x"0006_0000" & -- secbar_master_in(3): GP1 slave interface
                                     x"0004_0000" & -- secbar_master_in(4): Kasli register map slave interface
                                     x"0002_0000";  -- secbar_master_in(5): Core wishone slave interface

  constant c_mask_kasli_periph: std_logic_vector((c_wishbone_address_width)-1 downto 0) := x"000F_0000";

  constant c_wb_crossbar_mask_kasli_periph : std_logic_vector((c_wishbone_address_width * c_num_wb_crossbar_slaves)-1 downto 0) :=
                                     c_mask_kasli_periph & -- secbar_master_in(0): SI549 (0)
                                     c_mask_kasli_periph & -- secbar_master_in(2): SI549 (1)
                                     c_mask_kasli_periph & -- secbar_master_in(3): GP1 slave interface
                                     c_mask_kasli_periph & -- secbar_master_in(4): Kasli register map slave interface
                                     c_mask_kasli_periph;  -- secbar_master_in(5): Core wishone slave interface

  -----------------------------------------------------------------------------
  -- External Component declarations
  -----------------------------------------------------------------------------

  component xwr_si549_interface is
    generic (

      g_simulation     : integer := 0;
      g_sys_clock_freq : integer := 62500000;
      g_i2c_freq       : integer := 400000
    );
    port (
      clk_sys_i : in    std_logic;
      rst_n_i   : in    std_logic;

      tm_dac_value_i    : in    std_logic_vector(23 downto 0);
      tm_dac_value_wr_i : in    std_logic;

      scl_pad_oen_o : out   std_logic;
      sda_pad_oen_o : out   std_logic;
      scl_pad_i     : in    std_logic;
      sda_pad_i     : in    std_logic;

      slave_wb_i : in    t_wishbone_slave_in;
      slave_wb_o : out   t_wishbone_slave_out
    );
  end component xwr_si549_interface;

  -----------------------------------------------------------------------------
  -- Internal Component declarations
  -----------------------------------------------------------------------------

  component xwrc_board_kasli_regs is
    port (
      rst_n_i    : in    std_logic;
      clk_i      : in    std_logic;
      wb_cyc_i   : in    std_logic;
      wb_stb_i   : in    std_logic;
      wb_adr_i   : in    std_logic_vector(2 downto 2);
      wb_sel_i   : in    std_logic_vector(3 downto 0);
      wb_we_i    : in    std_logic;
      wb_dat_i   : in    std_logic_vector(31 downto 0);
      wb_ack_o   : out   std_logic;
      wb_err_o   : out   std_logic;
      wb_rty_o   : out   std_logic;
      wb_stall_o : out   std_logic;
      wb_dat_o   : out   std_logic_vector(31 downto 0);
      -- Wires and registers
      wrpc_kasli_regs_o : out   t_wrpc_kasli_regs_master_out
    );
  end component xwrc_board_kasli_regs;

  component wrc_board_kasli is
    generic (
      -- set to 1 to speed up some initialization processes during simulation
      g_simulation : integer := 0;
      -- "plainfbrc" = expose WRC fabric interface
      -- "streamers" = attach WRC streamers to fabric interface
      -- "etherbone" = attach Etherbone slave to fabric interface
      g_fabric_iface : string := "plainfbrc";
      -- parameters configuration when g_fabric_iface = "streamers" (otherwise ignored)
      -- g_streamers_op_mode        : t_streamers_op_mode  := TX_AND_RX;
      -- g_tx_streamer_params       : t_tx_streamer_params := c_tx_streamer_params_defaut;
      -- g_rx_streamer_params       : t_rx_streamer_params := c_rx_streamer_params_defaut;
      -- memory initialisation file for embedded CPU
      g_dpram_initf : string := "../../../../bin/wrpc/wrc_phy16.bram";
      -- identification (id and ver) of the layout of words in the generic diag interface
      g_diag_id  : integer := 0;
      g_diag_ver : integer := 0;
      -- size the generic diag interface (must be num diag i/f's * vector width (32))
      g_diag_ro_vector_width : integer := 0;
      g_diag_rw_vector_width : integer := 0;
      -- vectorised wishbone crossbar address array
      g_wb_crossbar_address_cfg_vector : std_logic_vector(c_wb_crossbar_address_vector_width - 1 downto 0) := (others => '0');
      g_wb_crossbar_mask_cfg_vector    : std_logic_vector(c_wb_crossbar_address_vector_width - 1 downto 0) := (others => '0')
    );
    port (
      ---------------------------------------------------------------------------
      -- Clocks/resets
      ---------------------------------------------------------------------------
      -- Clock inputs from the board
      clk_20m_vcxo_i         : in    std_logic;
      clk_125m_pllref_p_i    : in    std_logic;
      clk_125m_pllref_n_i    : in    std_logic;
      clk_125m_gtp_n_i       : in    std_logic;
      clk_125m_gtp_p_i       : in    std_logic;
      clk_125m_bootstrap_p_i : in    std_logic;
      clk_125m_bootstrap_n_i : in    std_logic;

      -- Generated sys clock and reset
      clk_sys_62m5_o   : out   std_logic;
      rst_sys_62m5_n_o : out   std_logic;

      -- Generated bootstrap reset
      rst_bootstrap_62m5_n_o : out   std_logic;

      -- Configurable (with g_aux_pll_cfg) clock outputs from the main PLL_BASE
      clk_aux_o   : out   std_logic_vector(c_num_aux_clocks - 1 downto 0);
      rst_aux_n_o : out   std_logic_vector(c_num_aux_clocks - 1 downto 0);

      ---------------------------------------------------------------------------
      -- I2C SI549s (Main = 0, Helper = 1)
      ---------------------------------------------------------------------------
      si549_sda_i : in    std_logic_vector(1 downto 0);
      si549_sda_o : out   std_logic_vector(1 downto 0);
      si549_sda_t : out   std_logic_vector(1 downto 0);

      si549_scl_i : in    std_logic_vector(1 downto 0);
      si549_scl_o : out   std_logic_vector(1 downto 0);
      si549_scl_t : out   std_logic_vector(1 downto 0);

      ---------------------------------------------------------------------------
      -- SFP I/O for transceiver and SFP management info
      ---------------------------------------------------------------------------
      sfp_tx_p_o        : out   std_logic;
      sfp_tx_n_o        : out   std_logic;
      sfp_rx_p_i        : in    std_logic;
      sfp_rx_n_i        : in    std_logic;
      sfp_det_i         : in    std_logic := '1';
      sfp_rate_select_o : out   std_logic;
      sfp_tx_fault_i    : in    std_logic := '0';
      sfp_tx_disable_o  : out   std_logic;
      sfp_los_i         : in    std_logic := '0';

      ---------------------------------------------------------------------------
      -- I2C EEPROM
      ---------------------------------------------------------------------------
      eeprom_sda_i : in    std_logic;
      eeprom_sda_o : out   std_logic;
      eeprom_sda_t : out   std_logic;
      eeprom_scl_i : in    std_logic;
      eeprom_scl_o : out   std_logic;
      eeprom_scl_t : out   std_logic;

      ---------------------------------------------------------------------------
      -- Onewire interface
      ---------------------------------------------------------------------------
      thermo_id_i : in    std_logic;
      thermo_id_o : out   std_logic;
      thermo_id_t : out   std_logic;

      ---------------------------------------------------------------------------
      -- UART
      ---------------------------------------------------------------------------
      uart_rxd_i : in    std_logic;
      uart_txd_o : out   std_logic;

      -------------------------------------------------------------------------
      -- Flash memory SPI interface
      -------------------------------------------------------------------------
      flash_sclk_o : out   std_logic;
      flash_ncs_o  : out   std_logic;
      flash_mosi_o : out   std_logic;
      flash_miso_i : in    std_logic;

      ------------------------------------------
      -- Axi Slave Bus Interface S01_AXI (driven by GP0 master)
      ------------------------------------------
      s01_axi_aclk_o  : out   std_logic;
      s01_axi_awaddr  : in    std_logic_vector(31 downto 0) := (others => '0');
      s01_axi_awvalid : in    std_logic                     := '0';
      s01_axi_awready : out   std_logic;
      s01_axi_wdata   : in    std_logic_vector(31 downto 0) := (others => '0');
      s01_axi_wstrb   : in    std_logic_vector(3 downto 0)  := (others => '0');
      s01_axi_wvalid  : in    std_logic                     := '0';
      s01_axi_wready  : out   std_logic;
      s01_axi_bresp   : out   std_logic_vector(1 downto 0);
      s01_axi_bvalid  : out   std_logic;
      s01_axi_bready  : in    std_logic                     := '0';
      s01_axi_araddr  : in    std_logic_vector(31 downto 0) := (others => '0');
      s01_axi_arvalid : in    std_logic                     := '0';
      s01_axi_arready : out   std_logic;
      s01_axi_rdata   : out   std_logic_vector(31 downto 0);
      s01_axi_rresp   : out   std_logic_vector(1 downto 0);
      s01_axi_rvalid  : out   std_logic;
      s01_axi_rready  : in    std_logic                     := '0';
      s01_axi_rlast   : out   std_logic;

      ------------------------------------------
      -- Axi Master Bus Interface M01_AXI
      ------------------------------------------
      m01_axi_aclk_o  : out   std_logic;
      m01_axi_awaddr  : out   std_logic_vector(31 downto 0) := (others => '0');
      m01_axi_awvalid : out   std_logic                     := '0';
      m01_axi_awready : in    std_logic;
      m01_axi_wdata   : out   std_logic_vector(31 downto 0) := (others => '0');
      m01_axi_wstrb   : out   std_logic_vector(3 downto 0)  := (others => '0');
      m01_axi_wvalid  : out   std_logic                     := '0';
      m01_axi_wready  : in    std_logic;
      m01_axi_bresp   : in    std_logic_vector(1 downto 0);
      m01_axi_bvalid  : in    std_logic;
      m01_axi_bready  : out   std_logic                     := '0';
      m01_axi_araddr  : out   std_logic_vector(31 downto 0) := (others => '0');
      m01_axi_arvalid : out   std_logic                     := '0';
      m01_axi_arready : in    std_logic;
      m01_axi_rdata   : in    std_logic_vector(31 downto 0);
      m01_axi_rresp   : in    std_logic_vector(1 downto 0);
      m01_axi_rvalid  : in    std_logic;
      m01_axi_rready  : out   std_logic                     := '0';
      m01_axi_rlast   : in    std_logic;

      ---------------------------------------------------------------------------
      -- WR fabric interface (when g_fabric_iface = "plain")
      ---------------------------------------------------------------------------
      wrf_src_adr_o   : out   std_logic_vector(1 downto 0);
      wrf_src_dat_o   : out   std_logic_vector(15 downto 0);
      wrf_src_cyc_o   : out   std_logic;
      wrf_src_stb_o   : out   std_logic;
      wrf_src_we_o    : out   std_logic;
      wrf_src_sel_o   : out   std_logic_vector(1 downto 0);
      wrf_src_ack_i   : in    std_logic;
      wrf_src_stall_i : in    std_logic;
      wrf_src_err_i   : in    std_logic;
      wrf_src_rty_i   : in    std_logic;
      wrf_snk_adr_i   : in    std_logic_vector(1 downto 0);
      wrf_snk_dat_i   : in    std_logic_vector(15 downto 0);
      wrf_snk_cyc_i   : in    std_logic;
      wrf_snk_stb_i   : in    std_logic;
      wrf_snk_we_i    : in    std_logic;
      wrf_snk_sel_i   : in    std_logic_vector(1 downto 0);
      wrf_snk_ack_o   : out   std_logic;
      wrf_snk_stall_o : out   std_logic;
      wrf_snk_err_o   : out   std_logic;
      wrf_snk_rty_o   : out   std_logic;

      ---------------------------------------------------------------------------
      -- Etherbone WB master interface (when g_fabric_iface = "etherbone")
      ---------------------------------------------------------------------------
      wb_eth_adr_o   : out   std_logic_vector(c_wishbone_address_width - 1 downto 0);
      wb_eth_dat_o   : out   std_logic_vector(c_wishbone_data_width - 1 downto 0);
      wb_eth_dat_i   : in    std_logic_vector(c_wishbone_data_width - 1 downto 0) := (others => '0');
      wb_eth_sel_o   : out   std_logic_vector(c_wishbone_address_width / 8 - 1 downto 0);
      wb_eth_we_o    : out   std_logic;
      wb_eth_cyc_o   : out   std_logic;
      wb_eth_stb_o   : out   std_logic;
      wb_eth_ack_i   : in    std_logic                                            := '0';
      wb_eth_int_i   : in    std_logic                                            := '0';
      wb_eth_err_i   : in    std_logic                                            := '0';
      wb_eth_rty_i   : in    std_logic                                            := '0';
      wb_eth_stall_i : in    std_logic                                            := '0';

      ---------------------------------------------------------------------------
      -- Generic diagnostics interface (access from WRPC via SNMP or uart console
      ---------------------------------------------------------------------------
      aux_diag_i : in    std_logic_vector(g_diag_ro_vector_width - 1 downto 0) := (others => '0');
      aux_diag_o : out   std_logic_vector(g_diag_rw_vector_width - 1 downto 0) := (others => '0');

      ---------------------------------------------------------------------------
      -- Aux clocks control
      ---------------------------------------------------------------------------
      tm_dac_value_o       : out   std_logic_vector(31 downto 0);
      tm_dac_wr_o          : out   std_logic_vector(c_num_aux_clocks - 1 downto 0);
      tm_clk_aux_lock_en_i : in    std_logic_vector(c_num_aux_clocks - 1 downto 0) := (others => '0');
      tm_clk_aux_locked_o  : out   std_logic_vector(c_num_aux_clocks - 1 downto 0);

      ---------------------------------------------------------------------------
      -- External Tx Timestamping I/F
      ---------------------------------------------------------------------------
      tstamps_stb_o       : out   std_logic;
      tstamps_tsval_o     : out   std_logic_vector(31 downto 0);
      tstamps_port_id_o   : out   std_logic_vector(5 downto 0);
      tstamps_frame_id_o  : out   std_logic_vector(15 downto 0);
      tstamps_incorrect_o : out   std_logic;
      tstamps_ack_i       : in    std_logic := '1';

      -----------------------------------------
      -- Timestamp helper signals, used for Absolute Calibration
      -----------------------------------------
      abscal_txts_o : out   std_logic;
      abscal_rxts_o : out   std_logic;

      ---------------------------------------------------------------------------
      -- Pause Frame Control
      ---------------------------------------------------------------------------
      fc_tx_pause_req_i   : in    std_logic                     := '0';
      fc_tx_pause_delay_i : in    std_logic_vector(15 downto 0) := x"0000";
      fc_tx_pause_ready_o : out   std_logic;

      ---------------------------------------------------------------------------
      -- Timecode I/F
      ---------------------------------------------------------------------------
      tm_link_up_o    : out   std_logic;
      tm_time_valid_o : out   std_logic;
      tm_tai_o        : out   std_logic_vector(39 downto 0);
      tm_cycles_o     : out   std_logic_vector(27 downto 0);

      ---------------------------------------------------------------------------
      -- Buttons, LEDs and PPS output
      ---------------------------------------------------------------------------
      -- LEDs
      led_act_o  : out   std_logic;
      led_link_o : out   std_logic;

      -- 1PPS output
      pps_p_o   : out   std_logic;
      pps_led_o : out   std_logic;

      -- Link ok indication
      link_ok_o : out   std_logic;

      ---------------------------------------------------------------------------
      -- Debug interface for clock_select, reset and clock
      ---------------------------------------------------------------------------
      d_wrpc_reset_core     : out   std_logic := '0';
      d_system_clock_select : out   std_logic := '0';
      d_clock_62m5_signal   : out   std_logic := '0'
    );
  end component wrc_board_kasli;

  component xwrc_board_kasli is
    generic (
      -- set to 1 to speed up some initialization processes during simulation
      g_simulation : integer := 0;
      -- Select whether to include external ref clock input
      g_aux_clks : integer := 4;
      -- plain     = expose WRC fabric interface
      -- streamers = attach WRC streamers to fabric interface
      -- etherbone = attach Etherbone slave to fabric interface
      g_fabric_iface : t_board_fabric_iface := plain;
      -- parameters configuration when g_fabric_iface = "streamers" (otherwise ignored)
      g_streamers_op_mode  : t_streamers_op_mode  := TX_AND_RX;
      g_tx_streamer_params : t_tx_streamer_params := c_tx_streamer_params_defaut;
      g_rx_streamer_params : t_rx_streamer_params := c_rx_streamer_params_defaut;
      -- memory initialisation file for embedded CPU
      g_dpram_initf : string := "../wrpc/wrc_phy16.bram";
      -- identification (id and ver) of the layout of words in the generic diag interface
      g_diag_id  : integer := 0;
      g_diag_ver : integer := 0;
      -- size the generic diag interface
      g_diag_ro_size : integer := 0;
      g_diag_rw_size : integer := 0;
      -- User-defined PLL_BASE outputs config
      g_aux_pll_cfg : t_auxpll_cfg_array := c_AUXPLL_CFG_ARRAY_DEFAULT;
      -- Wishbone cross bar addressing
      g_wb_crossbar_address_cfg : t_wishbone_address_array := c_DUMMY_WB_ADDR_ARRAY;
      g_wb_crossbar_mask_cfg    : t_wishbone_address_array := c_DUMMY_WB_ADDR_ARRAY
    );
    port (
      ---------------------------------------------------------------------------
      -- Clocks/resets
      ---------------------------------------------------------------------------
      -- Clock inputs from the board
      clk_20m_vcxo_i         : in    std_logic;
      clk_125m_pllref_p_i    : in    std_logic;
      clk_125m_pllref_n_i    : in    std_logic;
      clk_125m_gtp_p_i       : in    std_logic;
      clk_125m_gtp_n_i       : in    std_logic;
      clk_125m_bootstrap_p_i : in    std_logic;
      clk_125m_bootstrap_n_i : in    std_logic;

      -- Generate sys clock and rest
      clk_sys_62m5_o   : out   std_logic;
      rst_sys_62m5_n_o : out   std_logic;

      -- Generated bootstrap reset
      rst_bootstrap_62m5_n_o : out   std_logic;

      -- Configurable (with g_aux_pll_cfg) clock outputs from the main PLL_BASE
      clk_aux_o   : out   std_logic_vector(g_aux_clks - 1 downto 0);
      rst_aux_n_o : out   std_logic_vector(g_aux_clks - 1 downto 0);

      ---------------------------------------------------------------------------
      -- I2C SI549s (Main = 0, Helper = 1)
      ---------------------------------------------------------------------------
      si549_sda_i : in    std_logic_vector(1 downto 0);
      si549_sda_o : out   std_logic_vector(1 downto 0);
      si549_sda_t : out   std_logic_vector(1 downto 0);

      si549_scl_i : in    std_logic_vector(1 downto 0);
      si549_scl_o : out   std_logic_vector(1 downto 0);
      si549_scl_t : out   std_logic_vector(1 downto 0);

      ---------------------------------------------------------------------------
      -- SFP I/O for transceiver and SFP management info
      ---------------------------------------------------------------------------
      sfp_txp_o         : out   std_logic;
      sfp_txn_o         : out   std_logic;
      sfp_rxp_i         : in    std_logic;
      sfp_rxn_i         : in    std_logic;
      sfp_det_i         : in    std_logic := '1';
      sfp_rate_select_o : out   std_logic;
      sfp_tx_fault_i    : in    std_logic := '0';
      sfp_tx_disable_o  : out   std_logic;
      sfp_los_i         : in    std_logic := '0';

      ---------------------------------------------------------------------------
      -- I2C EEPROM
      ---------------------------------------------------------------------------
      eeprom_sda_i : in    std_logic;
      eeprom_sda_o : out   std_logic;
      eeprom_sda_t : out   std_logic;
      eeprom_scl_i : in    std_logic;
      eeprom_scl_o : out   std_logic;
      eeprom_scl_t : out   std_logic;

      ---------------------------------------------------------------------------
      -- Onewire interface
      ---------------------------------------------------------------------------
      thermo_id_i : in    std_logic;
      thermo_id_o : out   std_logic;
      thermo_id_t : out   std_logic;

      ---------------------------------------------------------------------------
      -- UART
      ---------------------------------------------------------------------------
      uart_rxd_i : in    std_logic;
      uart_txd_o : out   std_logic;

      ---------------------------------------------------------------------------
      -- Flash memory SPI interface
      ---------------------------------------------------------------------------
      flash_sclk_o : out   std_logic;
      flash_ncs_o  : out   std_logic;
      flash_mosi_o : out   std_logic;
      flash_miso_i : in    std_logic;

      ---------------------------------------------------------------------------
      -- Axi Master Port (To drive GP1 slave port)
      ---------------------------------------------------------------------------
      m01_axi_i : in    t_axi4_lite_master_in_32;
      m01_axi_o : out   t_axi4_lite_master_out_32;

      -- clock and reset
      m01_axi_aclk_o : out   std_logic;

      ---------------------------------------------------------------------------
      -- Axi Slave Port (To be driven by GP1 master port)
      ---------------------------------------------------------------------------
      s01_axi_o : out   t_axi4_lite_slave_out_32;
      s01_axi_i : in    t_axi4_lite_slave_in_32;

      -- clock and reset
      s01_axi_aclk_o : out   std_logic;

      ---------------------------------------------------------------------------
      -- WR fabric interface (when g_fabric_iface = "plainfbrc")
      ---------------------------------------------------------------------------
      wrf_src_o : out   t_wrf_source_out;
      wrf_src_i : in    t_wrf_source_in := c_dummy_src_in;
      wrf_snk_o : out   t_wrf_sink_out;
      wrf_snk_i : in    t_wrf_sink_in   := c_dummy_snk_in;

      ---------------------------------------------------------------------------
      -- Etherbone WB master interface (when g_fabric_iface = "etherbone")
      ---------------------------------------------------------------------------
      wb_eth_master_o : out   t_wishbone_master_out;
      wb_eth_master_i : in    t_wishbone_master_in := cc_dummy_master_in;

      ---------------------------------------------------------------------------
      -- Generic diagnostics interface (access from WRPC via SNMP or uart console
      ---------------------------------------------------------------------------
      aux_diag_i : in    t_generic_word_array(g_diag_ro_size - 1 downto 0) := (others => (others => '0'));
      aux_diag_o : out   t_generic_word_array(g_diag_rw_size - 1 downto 0);

      ---------------------------------------------------------------------------
      -- Aux clocks control
      ---------------------------------------------------------------------------
      tm_dac_value_o       : out   std_logic_vector(31 downto 0);
      tm_dac_wr_o          : out   std_logic_vector(g_aux_clks - 1 downto 0);
      tm_clk_aux_lock_en_i : in    std_logic_vector(g_aux_clks - 1 downto 0) := (others => '0');
      tm_clk_aux_locked_o  : out   std_logic_vector(g_aux_clks - 1 downto 0);

      ---------------------------------------------------------------------------
      -- External Tx Timestamping I/F
      ---------------------------------------------------------------------------
      timestamps_o     : out   t_txtsu_timestamp;
      timestamps_ack_i : in    std_logic := '1';

      -----------------------------------------
      -- Timestamp helper signals, used for Absolute Calibration
      -----------------------------------------
      abscal_txts_o : out   std_logic;
      abscal_rxts_o : out   std_logic;

      ---------------------------------------------------------------------------
      -- Pause Frame Control
      ---------------------------------------------------------------------------
      fc_tx_pause_req_i   : in    std_logic                     := '0';
      fc_tx_pause_delay_i : in    std_logic_vector(15 downto 0) := x"0000";
      fc_tx_pause_ready_o : out   std_logic;

      ---------------------------------------------------------------------------
      -- Timecode I/F
      ---------------------------------------------------------------------------
      tm_link_up_o    : out   std_logic;
      tm_time_valid_o : out   std_logic;
      tm_tai_o        : out   std_logic_vector(39 downto 0);
      tm_cycles_o     : out   std_logic_vector(27 downto 0);

      ---------------------------------------------------------------------------
      -- Buttons, LEDs and PPS output
      ---------------------------------------------------------------------------
      led_act_o  : out   std_logic;
      led_link_o : out   std_logic;
      -- 1PPS output
      pps_p_o   : out   std_logic;
      pps_led_o : out   std_logic;
      -- Link ok indication
      link_ok_o : out   std_logic;

      ---------------------------------------------------------------------------
      -- Debug interface for clock_select, reset and clock
      ---------------------------------------------------------------------------
      d_wrpc_reset_core     : out   std_logic := '0';
      d_system_clock_select : out   std_logic := '0';
      d_clock_62m5_signal   : out   std_logic := '0'
    );
  end component xwrc_board_kasli;

end package wr_kasli_pkg;
