-------------------------------------------------------------------------------
-- Title      : WRPC Wrapper for Kasli
-- Project    : WR PTP Core
-- URL        : http://www.ohwr.org/projects/wr-cores/wiki/Wrpc_core
-------------------------------------------------------------------------------
-- File       : wrc_board_kaslivhd
-- Author(s)  : Richard North
-- Company    : Nu-Quantum
-- Created    : 2024-07-15
-- Last update: 2024-07-15
-- Standard   : VHDL'93
-------------------------------------------------------------------------------
-- Description: Top-level wrapper for WR PTP core including all the modules
-- needed to operate the core on the Kasli board.
-- Version with no VHDL records on the top-level (mainly for Verilog
-- instantiation).
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
use work.etherbone_pkg.all;
use work.wr_fabric_pkg.all;
use work.endpoint_pkg.all;
use work.streamers_pkg.all;
use work.wr_xilinx_pkg.all;
use work.wr_board_pkg.all;
use work.wr_kasli_pkg.all;

entity wrc_board_kasli is
  generic(
    -- set to 1 to speed up some initialization processes during simulation
    g_simulation                : integer := 0;
    -- Select whether to include external ref clock input
    g_with_external_clock_input : integer := 0;
    -- Number of aux clocks syntonized by WRPC to WR timebase
    g_aux_clks                  : integer := 0;
    -- "gmii" = expose gmii interface
    -- "plainfbrc" = expose WRC fabric interface
    -- "streamers" = attach WRC streamers to fabric interface
    -- "etherbone" = attach Etherbone slave to fabric interface
    g_fabric_iface              : string  := "PLAINFBRC";
    -- parameters configuration when g_fabric_iface = "streamers" (otherwise ignored)
    --g_streamers_op_mode        : t_streamers_op_mode  := TX_AND_RX;
    --g_tx_streamer_params       : t_tx_streamer_params := c_tx_streamer_params_defaut;
    --g_rx_streamer_params       : t_rx_streamer_params := c_rx_streamer_params_defaut;
    -- memory initialisation file for embedded CPU
    g_dpram_initf               : string  := "wrc_phy16.bram";
    -- identification (id and ver) of the layout of words in the generic diag interface
    g_diag_id                   : integer := 0;
    g_diag_ver                  : integer := 0;
    -- size the generic diag interface
    g_diag_ro_vector_width      : integer := 0;
    g_diag_rw_vector_width      : integer := 0
    );
  port (
    ---------------------------------------------------------------------------
    -- Clocks/resets
    ---------------------------------------------------------------------------
    -- Reset from system fpga
    areset_n_i          : in  std_logic;
    -- Optional reset input active low with rising edge detection. Does not
    -- reset PLLs.
    --areset_edge_n_i     : in  std_logic := '1';
    -- Clock inputs from the board
    clk_20m_vcxo_i      : in  std_logic;
    clk_125m_pllref_p_i : in  std_logic;
    clk_125m_pllref_n_i : in  std_logic;
    clk_125m_gtp_n_i    : in  std_logic;
    clk_125m_gtp_p_i    : in  std_logic;
    -- 10MHz ext ref clock input (g_with_external_clock_input = TRUE)
    clk_10m_ext_i       : in  std_logic := '0';
    -- External PPS input (g_with_external_clock_input = TRUE)
    pps_ext_i           : in  std_logic := '0';
    -- 62.5MHz sys clock output
    clk_sys_62m5_o      : out std_logic;
    -- 125MHz ref clock output
    clk_ref_125m_o      : out std_logic;
    -- active low reset outputs, synchronous to 62m5 and 125m clocks
    rst_sys_62m5_n_o    : out std_logic;
    rst_ref_125m_n_o    : out std_logic;

    ---------------------------------------------------------------------------
    -- Shared SPI interface to DACs
    ---------------------------------------------------------------------------
    plldac_sclk_o   : out std_logic;
    plldac_din_o    : out std_logic;
    pll25dac_cs_n_o : out std_logic;
    pll20dac_cs_n_o : out std_logic;

    ---------------------------------------------------------------------------
    -- SFP I/O for transceiver and SFP management info
    ---------------------------------------------------------------------------
    sfp_tx_p_o         : out std_logic;
    sfp_tx_n_o         : out std_logic;
    sfp_rx_p_i         : in  std_logic;
    sfp_rx_n_i         : in  std_logic;
    sfp_det_i         : in  std_logic := '1';
    sfp_sda_i         : in  std_logic;
    sfp_sda_o         : out std_logic;
    sfp_sda_t         : out std_logic;
    sfp_scl_i         : in  std_logic;
    sfp_scl_o         : out std_logic;
    sfp_scl_t         : out std_logic;
    sfp_rate_select_o : out std_logic;
    sfp_tx_fault_i    : in  std_logic := '0';
    sfp_tx_disable_o  : out std_logic;
    sfp_los_i         : in  std_logic := '0';

    ---------------------------------------------------------------------------
    -- I2C EEPROM
    ---------------------------------------------------------------------------
    eeprom_sda_i : in  std_logic;
    eeprom_sda_o : out std_logic;
    eeprom_sda_t : out std_logic;
    eeprom_scl_i : in  std_logic;
    eeprom_scl_o : out std_logic;
    eeprom_scl_t : out std_logic;

    ---------------------------------------------------------------------------
    -- Onewire interface
    ---------------------------------------------------------------------------
    thermo_id_i : in  std_logic;
    thermo_id_o : out std_logic;
    thermo_id_t : out std_logic;

    ---------------------------------------------------------------------------
    -- UART
    ---------------------------------------------------------------------------
    uart_rxd_i : in  std_logic;
    uart_txd_o : out std_logic;

    ------------------------------------------
    -- Axi Slave Bus Interface S00_AXI
    ------------------------------------------
    s00_axi_aclk_o  : out std_logic;
    s00_axi_aresetn : in  std_logic := '1';
    s00_axi_awaddr  : in  std_logic_vector(31 downto 0) := (others=>'0');
    s00_axi_awprot  : in  std_logic_vector(2 downto 0);
    s00_axi_awvalid : in  std_logic := '0';
    s00_axi_awready : out std_logic;
    s00_axi_wdata   : in  std_logic_vector(31 downto 0) := (others=>'0');
    s00_axi_wstrb   : in  std_logic_vector(3 downto 0)  := (others=>'0');
    s00_axi_wvalid  : in  std_logic := '0';
    s00_axi_wready  : out std_logic;
    s00_axi_bresp   : out std_logic_vector(1 downto 0);
    s00_axi_bvalid  : out std_logic;
    s00_axi_bready  : in  std_logic := '0';
    s00_axi_araddr  : in  std_logic_vector(31 downto 0) := (others=>'0');
    s00_axi_arprot  : in std_logic_vector(2 downto 0);
    s00_axi_arvalid : in  std_logic := '0';
    s00_axi_arready : out std_logic;
    s00_axi_rdata   : out std_logic_vector(31 downto 0);
    s00_axi_rresp   : out std_logic_vector(1 downto 0);
    s00_axi_rvalid  : out std_logic;
    s00_axi_rready  : in  std_logic := '0';
    s00_axi_rlast   : out std_logic;
    axi_int_o       : out std_logic;

    ---------------------------------------------------------------------------
    -- WR fabric interface (when g_fabric_iface = "plainfbrc")
    ---------------------------------------------------------------------------
    wrf_src_o_adr : out std_logic_vector(1 downto 0);
    wrf_src_o_dat : out std_logic_vector(15 downto 0);
    wrf_src_o_cyc : out std_logic;
    wrf_src_o_stb : out std_logic;
    wrf_src_o_we  : out std_logic;
    wrf_src_o_sel : out std_logic_vector(1 downto 0);

    wrf_src_i_ack   : in std_logic := '0';
    wrf_src_i_stall : in std_logic := '0';
    wrf_src_i_err   : in std_logic := '0';
    wrf_src_i_rty   : in std_logic := '0';

    wrf_snk_o_ack   : out std_logic := '0';
    wrf_snk_o_stall : out std_logic := '0';
    wrf_snk_o_err   : out std_logic := '0';
    wrf_snk_o_rty   : out std_logic := '0';

    wrf_snk_i_adr : in  std_logic_vector(1 downto 0) := (others=>'0');
    wrf_snk_i_dat : in  std_logic_vector(15 downto 0) := (others=>'0');
    wrf_snk_i_cyc : in  std_logic := '0';
    wrf_snk_i_stb : in  std_logic := '0';
    wrf_snk_i_we  : in  std_logic := '0';
    wrf_snk_i_sel : in  std_logic_vector(1 downto 0) := (others=>'0');

    ---------------------------------------------------------------------------
    -- GMII interface (when g_fabric_iface = gmii)
    ---------------------------------------------------------------------------
    wrg_rx_clk       : in  std_logic := '0';
    wrg_rx_valid     : in  std_logic := '0';
    wrg_rx_err       : in  std_logic := '0';
    wrg_rx_data      : in  std_logic_vector(7 downto 0) := (others=>'0');

    wrg_tx_clk       : in  std_logic := '0';
    wrg_tx_valid     : out std_logic := '0';
    wrg_tx_err       : out std_logic := '0';
    wrg_tx_data      : out std_logic_vector(7 downto 0) := (others=>'0');

    ---------------------------------------------------------------------------
    -- External Tx Timestamping I/F
    ---------------------------------------------------------------------------
    tstamps_stb_o       : out std_logic;
    tstamps_tsval_o     : out std_logic_vector(31 downto 0);
    tstamps_port_id_o   : out std_logic_vector(5 downto 0);
    tstamps_frame_id_o  : out std_logic_vector(15 downto 0);
    tstamps_incorrect_o : out std_logic;
    tstamps_ack_i       : in  std_logic := '1';

    ---------------------------------------------------------------------------
    -- Timecode I/F
    ---------------------------------------------------------------------------
    --tm_link_up_o    : out std_logic;
    --tm_time_valid_o : out std_logic;
    --tm_tai_o        : out std_logic_vector(39 downto 0);
    --tm_cycles_o     : out std_logic_vector(27 downto 0);

    ---------------------------------------------------------------------------
    -- Buttons, LEDs and PPS output
    ---------------------------------------------------------------------------
    led_act_o  : out std_logic;
    led_link_o : out std_logic;
    --btn1_i     : in  std_logic := '1';
    --btn2_i     : in  std_logic := '1';
    -- 1PPS output
    pps_p_o    : out std_logic;
    pps_led_o  : out std_logic;
    -- Link ok indication
    link_ok_o  : out std_logic
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

  signal aux_master_out : t_wishbone_master_out;
  signal aux_master_in  : t_wishbone_master_in;

  -- Etherbone interface
  signal wb_eth_master_out : t_wishbone_master_out;
  signal wb_eth_master_in  : t_wishbone_master_in;

  -- Aux diagnostics
  constant c_diag_ro_size : integer := g_diag_ro_vector_width/32;
  constant c_diag_rw_size : integer := g_diag_rw_vector_width/32;

  signal aux_diag_in  : t_generic_word_array(c_diag_ro_size-1 downto 0);
  signal aux_diag_out : t_generic_word_array(c_diag_rw_size-1 downto 0);

  -- External Tx Timestamping I/F
  signal timestamps_out : t_txtsu_timestamp;

  -- streamers config
  signal wrs_tx_cfg_in  : t_tx_streamer_cfg;
  signal wrs_rx_cfg_in  : t_rx_streamer_cfg;

  -- axi signals
  signal s_axi_araddr : std_logic_vector(31 downto 0);
  signal s_axi_awaddr : std_logic_vector(31 downto 0);

begin  -- architecture struct


  -- axi supports word-addressing only, i.e. per 4 bytes; not shift needed though
  s_axi_araddr <= s00_axi_araddr(31 downto 0);
  s_axi_awaddr <= s00_axi_awaddr(31 downto 0);
  -- Instantiate the records-based module
  cmp_xwrc_board_fasec : entity work.xwrc_board_kasli
    generic map (
      g_simulation                => g_simulation,
      g_with_external_clock_input => f_int2bool(g_with_external_clock_input),
      g_aux_clks                  => g_aux_clks,
      g_fabric_iface              => f_str2iface_type(g_fabric_iface),
      g_streamers_op_mode         => TX_AND_RX,
      g_tx_streamer_params        => c_tx_streamer_params_defaut,
      g_rx_streamer_params        => c_rx_streamer_params_defaut,
      g_dpram_initf               => g_dpram_initf,
      g_diag_id                   => g_diag_id,
      g_diag_ver                  => g_diag_ver,
      g_diag_ro_size              => c_diag_ro_size,
      g_diag_rw_size              => c_diag_rw_size)
    port map (
      areset_n_i           => areset_n_i,
      --areset_edge_n_i      => areset_edge_n_i,
      clk_20m_vcxo_i       => clk_20m_vcxo_i,
      clk_125m_pllref_p_i  => clk_125m_pllref_p_i,
      clk_125m_pllref_n_i  => clk_125m_pllref_n_i,
      clk_125m_gtp_n_i     => clk_125m_gtp_n_i,
      clk_125m_gtp_p_i     => clk_125m_gtp_p_i,
      clk_10m_ext_i        => clk_10m_ext_i,
      pps_ext_i            => pps_ext_i,
      clk_sys_62m5_o       => clk_sys_62m5_o,
      clk_ref_125m_o       => clk_ref_125m_o,
      rst_sys_62m5_n_o     => rst_sys_62m5_n_o,
      rst_ref_125m_n_o     => rst_ref_125m_n_o,
      --
      plldac_sclk_o        => plldac_sclk_o,
      plldac_din_o         => plldac_din_o,
      pll25dac_cs_n_o      => pll25dac_cs_n_o,
      pll20dac_cs_n_o      => pll20dac_cs_n_o,
      --
      sfp_txp_o            => sfp_tx_p_o,
      sfp_txn_o            => sfp_tx_n_o,
      sfp_rxp_i            => sfp_rx_p_i,
      sfp_rxn_i            => sfp_rx_n_i,
      sfp_det_i            => sfp_det_i,
      sfp_sda_i            => sfp_sda_i,
      sfp_sda_o            => sfp_sda_o,
      sfp_sda_t            => sfp_sda_t,
      sfp_scl_i            => sfp_scl_i,
      sfp_scl_o            => sfp_scl_o,
      sfp_scl_t            => sfp_scl_t,
      sfp_rate_select_o    => sfp_rate_select_o,
      sfp_tx_fault_i       => sfp_tx_fault_i,
      sfp_tx_disable_o     => sfp_tx_disable_o,
      sfp_los_i            => sfp_los_i,
      --
      eeprom_sda_i => eeprom_sda_i,
      eeprom_sda_o => eeprom_sda_o,
      eeprom_sda_t => eeprom_sda_t,
      eeprom_scl_i => eeprom_scl_i,
      eeprom_scl_o => eeprom_scl_o,
      eeprom_scl_t => eeprom_scl_t,
      --
      thermo_id_i  => thermo_id_i,
      thermo_id_o  => thermo_id_o,
      thermo_id_t  => thermo_id_t,
      --
      uart_rxd_i           => uart_rxd_i,
      uart_txd_o           => uart_txd_o,
      --
      s00_axi_aclk_o       => s00_axi_aclk_o,
      s00_axi_aresetn      => s00_axi_aresetn,
      s00_axi_awaddr       => s_axi_awaddr,
      s00_axi_awprot       => s00_axi_awprot,
      s00_axi_awvalid      => s00_axi_awvalid,
      s00_axi_awready      => s00_axi_awready,
      s00_axi_wdata        => s00_axi_wdata,
      s00_axi_wstrb        => s00_axi_wstrb,
      s00_axi_wvalid       => s00_axi_wvalid,
      s00_axi_wready       => s00_axi_wready,
      s00_axi_bresp        => s00_axi_bresp,
      s00_axi_bvalid       => s00_axi_bvalid,
      s00_axi_bready       => s00_axi_bready,
      s00_axi_araddr       => s_axi_araddr,
      s00_axi_arprot       => s00_axi_arprot,
      s00_axi_arvalid      => s00_axi_arvalid,
      s00_axi_arready      => s00_axi_arready,
      s00_axi_rdata        => s00_axi_rdata,
      s00_axi_rresp        => s00_axi_rresp,
      s00_axi_rvalid       => s00_axi_rvalid,
      s00_axi_rready       => s00_axi_rready,
      s00_axi_rlast        => s00_axi_rlast,
      axi_int_o            => axi_int_o,

    wrf_src_o_adr       => wrf_src_o_adr,
    wrf_src_o_dat       => wrf_src_o_dat,
    wrf_src_o_cyc       => wrf_src_o_cyc,
    wrf_src_o_stb       => wrf_src_o_stb,
    wrf_src_o_we        => wrf_src_o_we ,
    wrf_src_o_sel       => wrf_src_o_sel,

    wrf_src_i_ack       => wrf_src_i_ack  ,
    wrf_src_i_stall     => wrf_src_i_stall,
    wrf_src_i_err       => wrf_src_i_err  ,
    wrf_src_i_rty       => wrf_src_i_rty  ,

    wrf_snk_o_ack       => wrf_snk_o_ack  ,
    wrf_snk_o_stall     => wrf_snk_o_stall,
    wrf_snk_o_err       => wrf_snk_o_err  ,
    wrf_snk_o_rty       => wrf_snk_o_rty  ,

    wrf_snk_i_adr       => wrf_snk_i_adr,
    wrf_snk_i_dat       => wrf_snk_i_dat,
    wrf_snk_i_cyc       => wrf_snk_i_cyc,
    wrf_snk_i_stb       => wrf_snk_i_stb,
    wrf_snk_i_we        => wrf_snk_i_we ,
    wrf_snk_i_sel       => wrf_snk_i_sel,


      --
      wrg_rx_clk           => wrg_rx_clk   ,
      wrg_rx_valid         => wrg_rx_valid ,
      wrg_rx_err           => wrg_rx_err   ,
      wrg_rx_data          => wrg_rx_data  ,

      wrg_tx_clk           => wrg_tx_clk  ,
      wrg_tx_valid         => wrg_tx_valid,
      wrg_tx_err           => wrg_tx_err  ,
      wrg_tx_data          => wrg_tx_data ,
      --
      led_act_o            => led_act_o,
      led_link_o           => led_link_o,
      --btn1_i               => btn1_i,
      --btn2_i               => btn2_i,
      --
      pps_p_o              => pps_p_o,
      pps_led_o            => pps_led_o,
      --
      link_ok_o            => link_ok_o);

end architecture std_wrapper;
