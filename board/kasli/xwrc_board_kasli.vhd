-------------------------------------------------------------------------------
-- Title      : WRPC Wrapper for Kasli SoC
-- Project    : WR PTP Core
-- URL        : http://www.ohwr.org/projects/wr-cores/wiki/Wrpc_core
-------------------------------------------------------------------------------
-- File       : xwrc_board_kasli.vhd
-- Author(s)  : Jonah Foley <jonah.foley@nu-quantum.com>
-- Company    : Nu Quantum Ltd.
-- Created    : 2024-08-28
-- Last update: 2024-08-28
-- Standard   : VHDL'93
-------------------------------------------------------------------------------
-- Description: Top-level wrapper for WR PTP core including all the modules
-- needed to operate the core on the Kasli SoC board.
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
  use work.wr_fabric_pkg.all;
  use work.endpoint_pkg.all;
  use work.streamers_pkg.all;
  use work.wr_xilinx_pkg.all;
  use work.wr_board_pkg.all;
  use work.wr_kasli_pkg.all;
  use work.axi4_pkg.all;
  use work.xwrc_board_kasli_regs_pkg.all;

library unisim;
  use unisim.vcomponents.all;

entity xwrc_board_kasli is
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
    -- dmtd PLL reference clock (from helper Si549)
    clk_20m_vcxo_i         : in    std_logic;
    
    -- sys PLL reference clock (from main Si549)
    clk_125m_pllref_p_i    : in    std_logic;
    clk_125m_pllref_n_i    : in    std_logic;
    
    -- transciever reference clock
    clk_125m_gtp_p_i       : in    std_logic;
    clk_125m_gtp_n_i       : in    std_logic;

    -- sys PLL reference clock (from bootstrap oscillator)
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
    link_ok_o : out   std_logic
  );
end entity xwrc_board_kasli;

architecture struct of xwrc_board_kasli is

  -- For some reason the general core axi_pkg.vhd doesnt provide this component def
  component xaxi4lite_wb_bridge is
    port (
      clk_i   : in    std_logic;
      rst_n_i : in    std_logic;

      wb_slave_i : in    t_wishbone_slave_in;
      wb_slave_o : out   t_wishbone_slave_out;

      axi4_master_o : out   t_axi4_lite_master_out_32;
      axi4_master_i : in    t_axi4_lite_master_in_32
    );
  end component xaxi4lite_wb_bridge;

  -----------------------------------------------------------------------------
  -- Signals
  -----------------------------------------------------------------------------

  -- IBUFDS
  signal clk_125m_pllref_buf    : std_logic;
  signal clk_125m_bootstrap_buf : std_logic;
  signal clk_125m_bootstrap     : std_logic;

  -- PLLs, clocks
  signal clk_pll_62m5   : std_logic;
  signal clk_pll_125m   : std_logic;
  signal clk_pll_dmtd   : std_logic;
  signal clk_pll_aux    : std_logic_vector(3 downto 0);
  signal pll_locked     : std_logic;
  signal pll_sys_locked : std_logic;
  signal clk_10m_ext    : std_logic;

  -- Reset logic
  signal sys_rstlogic_clk_in  : std_logic_vector(3 downto 0);
  signal sys_rstlogic_arst_n  : std_logic;
  signal sys_rstlogic_rst_out : std_logic_vector(3 downto 0);

  signal bootstrap_rstlogic_clk_in  : std_logic_vector(0 downto 0);
  signal bootstrap_rstlogic_arst_n  : std_logic;
  signal bootstrap_rstlogic_rst_out : std_logic_vector(0 downto 0);

  signal rst_sys_62m5_n       : std_logic;
  signal rst_bootstrap_62m5_n : std_logic;

  -- Registers
  signal reg2hw : t_wrpc_kasli_regs_master_out;

  -- PLL DAC ARB

  type pll_data_array_t is array (0 to 1) of std_logic_vector(23 downto 0);

  signal dac_pll_load_p1 : std_logic_vector(1 downto 0);
  signal dac_pll_data    : pll_data_array_t;

  -- OneWire
  signal onewire_in : std_logic_vector(1 downto 0);
  signal onewire_en : std_logic_vector(1 downto 0);

  -- PHY
  signal phy16_to_wrc   : t_phy_16bits_to_wrc;
  signal phy16_from_wrc : t_phy_16bits_from_wrc;

  -- External reference
  signal ext_ref_mul         : std_logic;
  signal ext_ref_mul_locked  : std_logic;
  signal ext_ref_mul_stopped : std_logic;
  signal ext_ref_rst         : std_logic;

  -- GP1 master port wishbone slave connection
  signal wb_m01_slave_in  : t_wishbone_slave_in;
  signal wb_m01_slave_out : t_wishbone_slave_out;

  -- WB interface (to core)
  signal wb_aux_master_out : t_wishbone_master_out;
  signal wb_aux_master_in  : t_wishbone_master_in;

  -- Kasli wishbone master -> slave interconnect
  signal secbar_master_in  : t_wishbone_master_in_array(c_num_wb_crossbar_slaves - 1 downto 0);
  signal secbar_master_out : t_wishbone_master_out_array(c_num_wb_crossbar_slaves - 1 downto 0);

  -- Kasli -> GP1 WB Slave interface (from Kasli interconnect)
  signal wb_master_out : t_wishbone_master_out;
  signal wb_master_in  : t_wishbone_master_in;

  -- WRC WB Slave interface (from WRC interconnect)
  signal wb_wrc_master_out : t_wishbone_master_out;
  signal wb_wrc_master_in  : t_wishbone_master_in;

  -- Register map interface
  signal wb_kasli_regs_out : t_wishbone_slave_out;
  signal wb_kasli_regs_in  : t_wishbone_slave_in;

  -- SI549 main interface
  signal wb_si549_master_out : t_wishbone_master_out_array(1 downto 0);
  signal wb_si549_master_in  : t_wishbone_master_in_array(1 downto 0);

begin  -- architecture struct

  -----------------------------------------------------------------------------
  -- Clock buffering / single ended conversion
  -----------------------------------------------------------------------------

  cmp_ibufgds_pllref : component IBUFGDS
    generic map (
      diff_term    => TRUE,
      ibuf_low_pwr => TRUE,
      iostandard   => "DEFAULT"
    )
    port map (
      O  => clk_125m_pllref_buf,
      I  => clk_125m_pllref_p_i,
      IB => clk_125m_pllref_n_i
    );


  -- The bootstrap clock is fed in on MGTREFCLK0 so needs an IBUFDS_GTE2.
  -- This is a free running 125MHz xtal oscillator.

  cmp_gtp_dedicated_clk : component IBUFDS_GTE2
    generic map(
      CLKCM_CFG    => true,
      CLKRCV_TRST  => true,
      CLKSWING_CFG => "11")
    port map (
      O     => clk_125m_bootstrap_buf,
      ODIV2 => open,
      CEB   => '0',
      I     => clk_125m_bootstrap_p_i,
      IB    => clk_125m_bootstrap_n_i
    );

  cmp_bufg_bootstrap : component BUFG
    port map (
      I => clk_125m_bootstrap_buf,
      O => clk_125m_bootstrap
    );


  -----------------------------------------------------------------------------
  -- AXI4-Lite Slave to WB  Master bridge.
  -----------------------------------------------------------------------------

  s01_axi_aclk_o <= clk_pll_62m5;

  cmp_wbm_axi4lite : component xwb_axi4lite_bridge
    port map (
      clk_sys_i => clk_pll_62m5,
      rst_n_i   => rst_bootstrap_62m5_n,
      -- from AXI lite slave
      axi4_slave_i => s01_axi_i,
      axi4_slave_o => s01_axi_o,
      -- to WB master
      wb_master_o => wb_m01_slave_in,
      wb_master_i => wb_m01_slave_out
    );

  -----------------------------------------------------------------------------
  -- WB Slave Classic to AXI4-Lite Master bridge
  -----------------------------------------------------------------------------

  m01_axi_aclk_o <= clk_pll_62m5;

  cmp_axi4litem_wb : component xaxi4lite_wb_bridge
    port map (
      clk_i   => clk_pll_62m5,
      rst_n_i => rst_bootstrap_62m5_n,
      -- from WB Slave
      wb_slave_i => wb_master_out,
      wb_slave_o => wb_master_in,
      -- to AXI4-Lite
      axi4_master_o => m01_axi_o,
      axi4_master_i => m01_axi_i
    );

  -----------------------------------------------------------------------------
  -- Wishbone interconnect
  -----------------------------------------------------------------------------

  cmp_kasli_interconnect : component xwb_crossbar
    generic map (
      g_num_masters => 2,
      g_num_slaves  => c_num_wb_crossbar_slaves,
      g_registered  => TRUE,
      g_address     => g_wb_crossbar_address_cfg,
      g_mask        => g_wb_crossbar_mask_cfg,
      g_verbose     => TRUE
    )
    port map (
      clk_sys_i => clk_pll_62m5,
      rst_n_i   => rst_bootstrap_62m5_n,
      -- Master connections (INTERCON is a slave)
      slave_i(0) => wb_aux_master_out,
      slave_i(1) => wb_m01_slave_in,
      slave_o(0) => wb_aux_master_in,
      slave_o(1) => wb_m01_slave_out,
      -- Slave connections (INTERCON is a master)
      master_i => secbar_master_in,
      master_o => secbar_master_out
    );

  -- SI549 (0) slave interface
  secbar_master_in(0)    <= wb_si549_master_in(0);
  wb_si549_master_out(0) <= secbar_master_out(0);

  -- SI549 (1) slave interface
  secbar_master_in(1)    <= wb_si549_master_in(1);
  wb_si549_master_out(1) <= secbar_master_out(1);

  -- GP1 slave interface
  secbar_master_in(2) <= wb_master_in;
  wb_master_out       <= secbar_master_out(2);

  -- Kasli register map slave interface
  secbar_master_in(3) <= wb_kasli_regs_out;
  wb_kasli_regs_in    <= secbar_master_out(3);

  -- Core wishone slave interface
  secbar_master_in(4) <= wb_wrc_master_in;
  wb_wrc_master_out   <= secbar_master_out(4);

  -----------------------------------------------------------------------------
  -- Register Map
  -----------------------------------------------------------------------------
  -- Cannot be reset by the system PLL since it drives the clk sel input
  -----------------------------------------------------------------------------

  cmp_xwrc_kasli_regs : component xwrc_board_kasli_regs
    port map (
      -- clock / reset
      clk_i   => clk_pll_62m5,
      rst_n_i => rst_bootstrap_62m5_n,
      -- wishbone interface
      wb_cyc_i => wb_kasli_regs_in.cyc,
      wb_stb_i => wb_kasli_regs_in.stb,
      -- Only two registers, so only 1 bit is used for addressing
      wb_adr_i   => wb_kasli_regs_in.adr(0 downto 0),
      wb_sel_i   => wb_kasli_regs_in.sel,
      wb_we_i    => wb_kasli_regs_in.we,
      wb_dat_i   => wb_kasli_regs_in.dat,
      wb_ack_o   => wb_kasli_regs_out.ack,
      wb_err_o   => wb_kasli_regs_out.err,
      wb_rty_o   => wb_kasli_regs_out.rty,
      wb_stall_o => wb_kasli_regs_out.stall,
      wb_dat_o   => wb_kasli_regs_out.dat,
      -- Wires and registers
      wrpc_kasli_regs_o => reg2hw
    );

  -----------------------------------------------------------------------------
  -- Platform-dependent part (PHY, PLLs, buffers, etc)
  -----------------------------------------------------------------------------

  cmp_xwrc_platform : component xwrc_platform_xilinx
    generic map (
      g_fpga_family                => "kintex7",
      g_with_external_clock_input  => FALSE,
      g_with_bootstrap_clock_input => TRUE,
      g_use_default_plls           => TRUE,
      g_aux_pll_cfg                => g_aux_pll_cfg,
      g_simulation                 => g_simulation
    )
    port map (
      -- clock / reset
      areset_n_i             => '1', -- REVISIT: do we need to reset on clock switch? See UG472 p.91
      clk_20m_vcxo_i         => clk_20m_vcxo_i,
      clk_125m_pllref_i      => clk_125m_pllref_buf,
      clk_125m_gtp_p_i       => clk_125m_gtp_p_i,
      clk_125m_gtp_n_i       => clk_125m_gtp_n_i,
      clk_125m_bootstrap_i   => clk_125m_bootstrap,
      clk_sys_sel_i          => reg2hw.SYSTEM_CLOCK_SELECT,
      sfp_txn_o              => sfp_txn_o,
      sfp_txp_o              => sfp_txp_o,
      sfp_rxn_i              => sfp_rxn_i,
      sfp_rxp_i              => sfp_rxp_i,
      sfp_tx_fault_i         => sfp_tx_fault_i,
      sfp_los_i              => sfp_los_i,
      sfp_tx_disable_o       => sfp_tx_disable_o,
      clk_62m5_sys_o         => clk_pll_62m5,
      clk_125m_ref_o         => clk_pll_125m,
      clk_62m5_dmtd_o        => clk_pll_dmtd,
      clk_pll_aux_o          => clk_pll_aux,
      pll_locked_o           => pll_locked,
      pll_aux_locked_o       => pll_sys_locked,
      clk_10m_ext_o          => clk_10m_ext,
      phy16_o                => phy16_to_wrc,
      phy16_i                => phy16_from_wrc,
      ext_ref_mul_o          => ext_ref_mul,
      ext_ref_mul_locked_o   => ext_ref_mul_locked,
      ext_ref_mul_stopped_o  => ext_ref_mul_stopped,
      ext_ref_rst_i          => ext_ref_rst
    );

  clk_sys_62m5_o <= clk_pll_62m5;
  clk_aux_o      <= clk_pll_aux(c_num_aux_clocks - 1 downto 0);

  -----------------------------------------------------------------------------
  -- Reset logic
  -----------------------------------------------------------------------------

  -- logic AND of all async reset sources (active low)
  sys_rstlogic_arst_n <= pll_locked and (not reg2hw.RESET_WRPC_CORE);

  -- Hold the bootstrap logic in reset until the sys PLL locks. However when the SI549
  -- is selected as input lock will be lost ... in this case we want to avoid reset
  -- since that will cause a reset loop. In this case SYSTEM_CLOCK_SELECT is 1 so use
  -- that to mask the reset
  bootstrap_rstlogic_arst_n <= pll_sys_locked or reg2hw.SYSTEM_CLOCK_SELECT;

  -- concatenation of all clocks required to have synced resets
  sys_rstlogic_clk_in(0)          <= clk_pll_62m5;
  sys_rstlogic_clk_in(3 downto 1) <= clk_pll_aux(c_num_aux_clocks - 1 downto 0);

  -- TODO: free_clock_i -> locked_i false path
  cmp_sys_rstlogic_reset : component gc_reset
    generic map (
      g_clocks    => c_num_aux_clocks + 1,
      g_logdelay  => 4,
      g_syncdepth => 3
    )
    port map (
      free_clk_i => clk_125m_bootstrap,
      locked_i   => sys_rstlogic_arst_n,
      clks_i     => sys_rstlogic_clk_in,
      rstn_o     => sys_rstlogic_rst_out
    );

  bootstrap_rstlogic_clk_in(0) <= clk_pll_62m5;

  -- TODO: free_clock_i -> locked_i false path
  cmp_bootstrap_rstlogic_reset : component gc_reset
    generic map (
      g_clocks    => 1,
      g_logdelay  => 4,
      g_syncdepth => 3
    )
    port map (
      free_clk_i => clk_125m_bootstrap,
      locked_i   => bootstrap_rstlogic_arst_n,
      clks_i     => bootstrap_rstlogic_clk_in,
      rstn_o     => bootstrap_rstlogic_rst_out
    );

  -- distribution of resets (already synchronized to their clock domains)
  rst_sys_62m5_n       <= sys_rstlogic_rst_out(0);
  rst_bootstrap_62m5_n <= bootstrap_rstlogic_rst_out(0);

  -- Export the resets for use in higher level startup
  rst_sys_62m5_n_o       <= rst_sys_62m5_n;
  rst_aux_n_o            <= sys_rstlogic_rst_out(3 downto 1);
  rst_bootstrap_62m5_n_o <= rst_bootstrap_62m5_n;

  -----------------------------------------------------------------------------
  -- SI549 Main I2C masters
  -----------------------------------------------------------------------------

  gen_si549 : for i in 0 to 1 generate

    cmp_si549_main_i2c_master : component xwr_si549_interface
      generic map (
        g_simulation     => g_simulation,
        g_sys_clock_freq => 62500000, -- 1Mbps
        g_i2c_freq       => 40000
      )
      port map (
        clk_sys_i => clk_pll_62m5,
        rst_n_i   => rst_bootstrap_62m5_n,
        -- WR Core timing interface: aux clock tune port
        tm_dac_value_i    => dac_pll_data(i),
        tm_dac_value_wr_i => dac_pll_load_p1(i),
        -- I2C bus: output enable (active low)
        scl_pad_oen_o => si549_scl_t(i),
        sda_pad_oen_o => si549_sda_t(i),
        -- I2C bus: input pads
        scl_pad_i => si549_scl_i(i),
        sda_pad_i => si549_sda_i(i),
        -- Wishbone interface (from Kasli interconnect)
        slave_wb_i => wb_si549_master_out(i),
        slave_wb_o => wb_si549_master_in(i)
      );

    -- Drive to zero such that when oen is high the SCL/SDA lines go low
    si549_scl_o(i) <= '0';
    si549_sda_o(i) <= '0';

  end generate gen_si549;

  -----------------------------------------------------------------------------
  -- The WR PTP core with optional fabric interface attached
  -----------------------------------------------------------------------------

  cmp_board_common : component xwrc_board_common
    generic map (
      g_simulation                => g_simulation,
      g_with_external_clock_input => FALSE,
      g_board_name                => "KSLI",
      g_phys_uart                 => TRUE,
      g_virtual_uart              => TRUE,
      g_aux_clks                  => g_aux_clks,
      g_ep_rxbuf_size             => 1024,
      g_tx_runt_padding           => TRUE,
      g_dpram_initf               => g_dpram_initf,
      g_dpram_size                => 131072 / 4,
      g_interface_mode            => PIPELINED,
      g_address_granularity       => BYTE,
      g_aux_sdb                   => c_wrc_periph3_sdb,
      g_softpll_enable_debugger   => FALSE,
      g_vuart_fifo_size           => 1024,
      g_pcs_16bit                 => TRUE,
      g_diag_id                   => g_diag_id,
      g_diag_ver                  => g_diag_ver,
      g_diag_ro_size              => g_diag_ro_size,
      g_diag_rw_size              => g_diag_rw_size,
      g_streamers_op_mode         => g_streamers_op_mode,
      g_tx_streamer_params        => g_tx_streamer_params,
      g_rx_streamer_params        => g_rx_streamer_params,
      g_fabric_iface              => g_fabric_iface,
      g_dac_bits                  => 24
    )
    port map (
      clk_sys_i            => clk_pll_62m5,
      clk_dmtd_i           => clk_pll_dmtd,
      clk_ref_i            => clk_pll_125m,
      clk_ext_mul_i        => ext_ref_mul,
      clk_ext_mul_locked_i => ext_ref_mul_locked,
      clk_ext_stopped_i    => ext_ref_mul_stopped,
      clk_ext_rst_o        => ext_ref_rst,
      rst_n_i              => rst_sys_62m5_n,
      -- Helper PLL updates
      dac_hpll_load_p1_o => dac_pll_load_p1(1),
      dac_hpll_data_o    => dac_pll_data(1),
      -- Main PLL updates
      dac_dpll_load_p1_o => dac_pll_load_p1(0),
      dac_dpll_data_o    => dac_pll_data(0),
      -- Transceiver data i/f
      phy16_o => phy16_from_wrc,
      phy16_i => phy16_to_wrc,
      -- EEPROM I2C
      scl_o => eeprom_scl_t,
      scl_i => eeprom_scl_i,
      sda_o => eeprom_sda_t,
      sda_i => eeprom_sda_i,
      -- No SFP I2C as it comes via the wishbone interface to the RISC-V
      sfp_det_i => sfp_det_i,
      -- flash SPI
      spi_sclk_o => flash_sclk_o,
      spi_ncs_o  => flash_ncs_o,
      spi_mosi_o => flash_mosi_o,
      spi_miso_i => flash_miso_i,
      -- UART
      uart_rxd_i => uart_rxd_i,
      uart_txd_o => uart_txd_o,
      -- one wire
      owr_pwren_o => open,
      owr_en_o    => onewire_en,
      owr_i       => onewire_in,
      -- WB Slave port (From PS -> WRC)
      wb_slave_i => wb_wrc_master_out,
      wb_slave_o => wb_wrc_master_in,
      -- Aux mater port (From WRC -> PS .. for I2C)
      aux_master_o => wb_aux_master_out,
      aux_master_i => wb_aux_master_in,
      -- wr fabric interface (g_fabric_interface = plain)
      wrf_src_o => wrf_src_o,
      wrf_src_i => wrf_src_i,
      wrf_snk_o => wrf_snk_o,
      wrf_snk_i => wrf_snk_i,
      -- etherbone interface (g_fabric_interface = etherbone)
      wb_eth_master_o => wb_eth_master_o,
      wb_eth_master_i => wb_eth_master_i,
      -- Auxillary diagnostics interface
      aux_diag_i => aux_diag_i,
      aux_diag_o => aux_diag_o,
      --
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
      pps_p_o              => pps_p_o,
      pps_led_o            => pps_led_o,
      link_ok_o            => link_ok_o
    );

  sfp_rate_select_o <= '1';

  thermo_id_t <= '0' when onewire_en(0) = '1' else '1';
  thermo_id_o <= '0';

  onewire_in(0) <= thermo_id_i;
  onewire_in(1) <= '1';

  eeprom_sda_o <= '0';
  eeprom_scl_o <= '0';

end architecture struct;
