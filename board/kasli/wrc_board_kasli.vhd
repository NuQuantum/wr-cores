-------------------------------------------------------------------------------
-- Title      : WRPC Wrapper for Kasli
-- Project    : WR PTP Core
-- URL        : http://www.ohwr.org/projects/wr-cores/wiki/Wrpc_core
-------------------------------------------------------------------------------
-- File       : wrc_board_kasli.vhd
-- Author(s)  : Jonah Foley <jonah.foley@nu-quantum.com>
-- Company    : Nu Quantum Ltd.
-- Created    : 2017-08-02
-- Last update: 2017-09-07
-- Standard   : VHDL'93
-------------------------------------------------------------------------------
-- Description: Top-level wrapper for WR PTP core including all the modules
-- needed to operate the core on the Kasli SoC board.
-- Version with no VHDL records on the top-level (mainly for Verilog
-- instantiation).
-------------------------------------------------------------------------------
-- Copyright (c) 2024 Nu Quantum Ltd.
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
-- vsg_off port_012
-------------------------------------------------------------------------------

library ieee;
  use ieee.std_logic_1164.all;

library work;
  use work.gencores_pkg.all;
  use work.wrcore_pkg.all;
  use work.wishbone_pkg.all;
  use work.etherbone_pkg.all;
  use work.wr_fabric_pkg.all;
  use work.endpoint_pkg.all;
  use work.streamers_pkg.all;
  use work.wr_xilinx_pkg.all;
  use work.wr_board_pkg.all;
  use work.wr_kasli_pkg.all;
  use work.axi4_pkg.all;

entity wrc_board_kasli is
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
    link_ok_o : out   std_logic
  );
end entity wrc_board_kasli;

architecture std_wrapper of wrc_board_kasli is

  -----------------------------------------------------------------------------
  -- Signals
  -----------------------------------------------------------------------------

  -- WR fabric interface
  signal wrf_src_out : t_wrf_source_out;
  signal wrf_src_in  : t_wrf_source_in;
  signal wrf_snk_out : t_wrf_sink_out;
  signal wrf_snk_in  : t_wrf_sink_in;

  -- Etherbone interface
  signal wb_eth_master_out : t_wishbone_master_out;
  signal wb_eth_master_in  : t_wishbone_master_in;

  -- Aux diagnostics
  constant c_diag_ro_size : integer := g_diag_ro_vector_width / 32;
  constant c_diag_rw_size : integer := g_diag_rw_vector_width / 32;

  signal aux_diag_in  : t_generic_word_array(c_diag_ro_size - 1 downto 0);
  signal aux_diag_out : t_generic_word_array(c_diag_rw_size - 1 downto 0);

  -- External Tx Timestamping I/F
  signal timestamps_out : t_txtsu_timestamp;

  -- axi signals
  signal s01_axi_in  : t_axi4_lite_slave_in_32;
  signal s01_axi_out : t_axi4_lite_slave_out_32;
  signal m01_axi_out : t_axi4_lite_master_out_32;
  signal m01_axi_in  : t_axi4_lite_master_in_32;

  -- sys PLL aux clock config
  constant c_auxpll_cfg_rtio_125m : t_auxpll_cfg       := (TRUE, TRUE, 8);
  constant c_auxpll_cfg_rtio_500m : t_auxpll_cfg       := (TRUE, TRUE, 2);
  constant c_auxpll_cfg_rtio_200m : t_auxpll_cfg       := (TRUE, TRUE, 5);
  constant c_auxpll_cfg           : t_auxpll_cfg_array :=
  (
    c_auxpll_cfg_rtio_200m,
    c_auxpll_cfg_rtio_500m,
    c_auxpll_cfg_rtio_125m,
    c_AUXPLL_CFG_DEFAULT
  );

  -- wb crossbar address / mask
  -- convert from a flat vector to an array of t_wishbone_address
  -- vsg_off
  constant c_wb_crossbar_address_cfg : t_wishbone_address_array(c_num_wb_crossbar_slaves - 1 downto 0) := t_wishbone_address_array(f_de_vectorize_diag(g_wb_crossbar_address_cfg_vector, c_wb_crossbar_address_vector_width));

  constant c_wb_crossbar_mask_cfg : t_wishbone_address_array(c_num_wb_crossbar_slaves - 1 downto 0) := t_wishbone_address_array(f_de_vectorize_diag(g_wb_crossbar_mask_cfg_vector, c_wb_crossbar_address_vector_width));
  -- vsg_on

begin  -- architecture struct

  -- AXI master port (drives by GP1 slave)
  m01_axi_awvalid <= m01_axi_out.awvalid;
  m01_axi_wdata   <= m01_axi_out.wdata;
  m01_axi_wstrb   <= m01_axi_out.wstrb;
  m01_axi_wvalid  <= m01_axi_out.wvalid;
  m01_axi_bready  <= m01_axi_out.bready;
  m01_axi_arvalid <= m01_axi_out.arvalid;
  m01_axi_rready  <= m01_axi_out.rready;
  -- axi supports word-addressing only, i.e. per 4 bytes; shift for wb-bridge
  m01_axi_awaddr <= m01_axi_out.awaddr(29 downto 0) & "00";
  m01_axi_araddr <= m01_axi_out.araddr(29 downto 0) & "00";

  m01_axi_in.awready <= m01_axi_awready;
  m01_axi_in.wready  <= m01_axi_wready;
  m01_axi_in.bresp   <= m01_axi_bresp;
  m01_axi_in.bvalid  <= m01_axi_bvalid;
  m01_axi_in.arready <= m01_axi_arready;
  m01_axi_in.rdata   <= m01_axi_rdata;
  m01_axi_in.rresp   <= m01_axi_rresp;
  m01_axi_in.rvalid  <= m01_axi_rvalid;
  m01_axi_in.rlast   <= m01_axi_rlast;

  -- AXI slave port (driven by GP1 master)
  s01_axi_in.awvalid <= s01_axi_awvalid;
  s01_axi_in.wdata   <= s01_axi_wdata;
  s01_axi_in.wstrb   <= s01_axi_wstrb;
  s01_axi_in.wvalid  <= s01_axi_wvalid;
  s01_axi_in.bready  <= s01_axi_bready;
  s01_axi_in.arvalid <= s01_axi_arvalid;
  s01_axi_in.rready  <= s01_axi_rready;
  -- axi supports word-addressing only, i.e. per 4 bytes; shift for wb-bridge
  s01_axi_in.awaddr <= "00" & s01_axi_awaddr(31 downto 2);
  s01_axi_in.araddr <= "00" & s01_axi_araddr(31 downto 2);

  s01_axi_awready <= s01_axi_out.awready;
  s01_axi_wready  <= s01_axi_out.wready;
  s01_axi_bresp   <= s01_axi_out.bresp;
  s01_axi_bvalid  <= s01_axi_out.bvalid;
  s01_axi_arready <= s01_axi_out.arready;
  s01_axi_rdata   <= s01_axi_out.rdata;
  s01_axi_rresp   <= s01_axi_out.rresp;
  s01_axi_rvalid  <= s01_axi_out.rvalid;
  s01_axi_rlast   <= s01_axi_out.rlast;

  -- WR fabric
  wrf_src_adr_o    <= wrf_src_out.adr;
  wrf_src_dat_o    <= wrf_src_out.dat;
  wrf_src_cyc_o    <= wrf_src_out.cyc;
  wrf_src_stb_o    <= wrf_src_out.stb;
  wrf_src_we_o     <= wrf_src_out.we;
  wrf_src_sel_o    <= wrf_src_out.sel;
  wrf_src_in.ack   <= wrf_src_ack_i;
  wrf_src_in.stall <= wrf_src_stall_i;
  wrf_src_in.err   <= wrf_src_err_i;
  wrf_src_in.rty   <= wrf_src_rty_i;

  wrf_snk_in.adr  <= wrf_snk_adr_i;
  wrf_snk_in.dat  <= wrf_snk_dat_i;
  wrf_snk_in.cyc  <= wrf_snk_cyc_i;
  wrf_snk_in.stb  <= wrf_snk_stb_i;
  wrf_snk_in.we   <= wrf_snk_we_i;
  wrf_snk_in.sel  <= wrf_snk_sel_i;
  wrf_snk_ack_o   <= wrf_snk_out.ack;
  wrf_snk_stall_o <= wrf_snk_out.stall;
  wrf_snk_err_o   <= wrf_snk_out.err;
  wrf_snk_rty_o   <= wrf_snk_out.rty;

  -- Etherbone
  wb_eth_adr_o <= wb_eth_master_out.adr;
  wb_eth_dat_o <= wb_eth_master_out.dat;
  wb_eth_cyc_o <= wb_eth_master_out.cyc;
  wb_eth_stb_o <= wb_eth_master_out.stb;
  wb_eth_sel_o <= wb_eth_master_out.sel;
  wb_eth_we_o  <= wb_eth_master_out.we;

  wb_eth_master_in.dat   <= wb_eth_dat_i;
  wb_eth_master_in.ack   <= wb_eth_ack_i;
  wb_eth_master_in.err   <= wb_eth_err_i;
  wb_eth_master_in.rty   <= wb_eth_rty_i;
  wb_eth_master_in.stall <= wb_eth_stall_i;

  aux_diag_in <= f_de_vectorize_diag(aux_diag_i, g_diag_ro_vector_width);
  aux_diag_o  <= f_vectorize_diag(aux_diag_out, g_diag_rw_vector_width);

  tstamps_stb_o      <= timestamps_out.stb;
  tstamps_tsval_o    <= timestamps_out.tsval;
  tstamps_port_id_o  <= timestamps_out.port_id;
  tstamps_frame_id_o <= timestamps_out.frame_id;

  -- Instantiate the records-based module
  cmp_xwrc_board_kasli : component xwrc_board_kasli
    generic map (
      g_simulation              => g_simulation,
      g_aux_clks                => c_num_aux_clocks,
      g_fabric_iface            => f_str2iface_type(g_fabric_iface),
      g_streamers_op_mode       => TX_AND_RX,
      g_tx_streamer_params      => c_tx_streamer_params_defaut,
      g_rx_streamer_params      => c_rx_streamer_params_defaut,
      g_dpram_initf             => g_dpram_initf,
      g_diag_id                 => g_diag_id,
      g_diag_ver                => g_diag_ver,
      g_diag_ro_size            => c_diag_ro_size,
      g_diag_rw_size            => c_diag_rw_size,
      g_aux_pll_cfg             => c_auxpll_cfg,
      g_wb_crossbar_address_cfg => c_wb_crossbar_address_cfg,
      g_wb_crossbar_mask_cfg    => c_wb_crossbar_mask_cfg
    )
    port map (
      clk_20m_vcxo_i         => clk_20m_vcxo_i,
      clk_125m_pllref_p_i    => clk_125m_pllref_p_i,
      clk_125m_pllref_n_i    => clk_125m_pllref_n_i,
      clk_125m_gtp_n_i       => clk_125m_gtp_n_i,
      clk_125m_gtp_p_i       => clk_125m_gtp_p_i,
      clk_125m_bootstrap_p_i => clk_125m_bootstrap_p_i,
      clk_125m_bootstrap_n_i => clk_125m_bootstrap_n_i,
      --
      rst_sys_62m5_n_o       => rst_sys_62m5_n_o,
      rst_bootstrap_62m5_n_o => rst_bootstrap_62m5_n_o,
      -- Auxillary clocks / reset
      clk_aux_o   => clk_aux_o,
      rst_aux_n_o => rst_aux_n_o,
      --
      si549_sda_i => si549_sda_i,
      si549_sda_o => si549_sda_o,
      si549_sda_t => si549_sda_t,
      si549_scl_i => si549_scl_i,
      si549_scl_o => si549_scl_o,
      si549_scl_t => si549_scl_t,
      --
      sfp_txp_o         => sfp_tx_p_o,
      sfp_txn_o         => sfp_tx_n_o,
      sfp_rxp_i         => sfp_rx_p_i,
      sfp_rxn_i         => sfp_rx_n_i,
      sfp_det_i         => sfp_det_i,
      sfp_rate_select_o => sfp_rate_select_o,
      sfp_tx_fault_i    => sfp_tx_fault_i,
      sfp_tx_disable_o  => sfp_tx_disable_o,
      sfp_los_i         => sfp_los_i,
      --
      eeprom_sda_i => eeprom_sda_i,
      eeprom_sda_o => eeprom_sda_o,
      eeprom_sda_t => eeprom_sda_t,
      eeprom_scl_i => eeprom_scl_i,
      eeprom_scl_o => eeprom_scl_o,
      eeprom_scl_t => eeprom_scl_t,
      --
      thermo_id_i => thermo_id_i,
      thermo_id_o => thermo_id_o,
      thermo_id_t => thermo_id_t,
      --
      uart_rxd_i => uart_rxd_i,
      uart_txd_o => uart_txd_o,
      --
      flash_sclk_o => flash_sclk_o,
      flash_ncs_o  => flash_ncs_o,
      flash_mosi_o => flash_mosi_o,
      flash_miso_i => flash_miso_i,
      --
      s01_axi_i      => s01_axi_in,
      s01_axi_o      => s01_axi_out,
      s01_axi_aclk_o => s01_axi_aclk_o,
      --
      m01_axi_o      => m01_axi_out,
      m01_axi_i      => m01_axi_in,
      m01_axi_aclk_o => m01_axi_aclk_o,
      --
      wrf_src_o => wrf_src_out,
      wrf_src_i => wrf_src_in,
      wrf_snk_o => wrf_snk_out,
      wrf_snk_i => wrf_snk_in,
      --
      wb_eth_master_o => wb_eth_master_out,
      wb_eth_master_i => wb_eth_master_in,
      --
      aux_diag_i => aux_diag_in,
      aux_diag_o => aux_diag_out,
      --
      tm_dac_value_o       => tm_dac_value_o,
      tm_dac_wr_o          => tm_dac_wr_o,
      tm_clk_aux_lock_en_i => tm_clk_aux_lock_en_i,
      tm_clk_aux_locked_o  => tm_clk_aux_locked_o,
      --
      timestamps_o     => timestamps_out,
      timestamps_ack_i => tstamps_ack_i,
      --
      abscal_txts_o => abscal_txts_o,
      abscal_rxts_o => abscal_rxts_o,
      --
      fc_tx_pause_req_i   => fc_tx_pause_req_i,
      fc_tx_pause_delay_i => fc_tx_pause_delay_i,
      fc_tx_pause_ready_o => fc_tx_pause_ready_o,
      --
      tm_link_up_o    => tm_link_up_o,
      tm_time_valid_o => tm_time_valid_o,
      tm_tai_o        => tm_tai_o,
      tm_cycles_o     => tm_cycles_o,
      --
      led_act_o  => led_act_o,
      led_link_o => led_link_o,
      --
      pps_p_o   => pps_p_o,
      pps_led_o => pps_led_o,
      --
      link_ok_o => link_ok_o
    );

end architecture std_wrapper;
