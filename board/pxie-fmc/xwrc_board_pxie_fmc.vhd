-------------------------------------------------------------------------------
-- Title      : WRPC Wrapper for PXIe-FMC Carrier
-- Project    : WR PTP Core
-- URL        : http://www.ohwr.org/projects/wr-cores/wiki/Wrpc_core
-------------------------------------------------------------------------------
-- File       : xwrc_board_pxie_fmc.vhd
-- Author(s)  : Greg Daniluk <grzegorz.daniluk@cern.ch>
-- Company    : CERN (BE-CO-HT)
-- Standard   : VHDL'93
-------------------------------------------------------------------------------
-- Description: Top-level wrapper for WR PTP core including all the modules
-- needed to operate the core on the EN-SMM PXIe-FMC board.
-- https://ohwr.org/project/pxie-fmc
-------------------------------------------------------------------------------
-- Copyright (c) 2020 CERN
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
use work.wr_pxie_fmc_pkg.all;

library unisim;
use unisim.vcomponents.all;

entity xwrc_board_pxie_fmc is
  generic(
    -- set to 1 to speed up some initialization processes during simulation
    g_simulation                : integer              := 0;
    -- Number of aux clocks syntonized by WRPC to WR timebase
    g_aux_clks                  : integer              := 0;
    -- memory initialisation file for embedded CPU
    g_dpram_initf               : string               := "default_xilinx";
    g_aux_sdb                   : t_sdb_device         := c_wrc_periph3_sdb
    );
  port (
    ---------------------------------------------------------------------------
    -- Clocks/resets
    ---------------------------------------------------------------------------
    -- Reset input (active low, can be async)
    areset_n_i          : in  std_logic;
    -- Optional reset input active low with rising edge detection. Does not
    -- reset PLLs.
    areset_edge_n_i        : in  std_logic := '1';
    -- Clock inputs from the board
    wr_clk_helper_125m_p_i : in  std_logic;
    wr_clk_helper_125m_n_i : in  std_logic;
    wr_clk_main_125m_p_i   : in  std_logic;
    wr_clk_main_125m_n_i   : in  std_logic;
    wr_clk_sfp_125m_p_i    : in  std_logic;
    wr_clk_sfp_125m_n_i    : in  std_logic;

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
    sfp_txp_o         : out std_logic;
    sfp_txn_o         : out std_logic;
    sfp_rxp_i         : in  std_logic;
    sfp_rxn_i         : in  std_logic;
    sfp_det_i         : in  std_logic := '1';
    sfp_sda_i         : in  std_logic;
    sfp_sda_o         : out std_logic;
    sfp_scl_i         : in  std_logic;
    sfp_scl_o         : out std_logic;
    sfp_rate_select_o : out std_logic;
    sfp_tx_fault_i    : in  std_logic := '0';
    sfp_tx_disable_o  : out std_logic;
    sfp_los_i         : in  std_logic := '0';

    ---------------------------------------------------------------------------
    -- I2C EEPROM
    ---------------------------------------------------------------------------
    eeprom_sda_i : in  std_logic;
    eeprom_sda_o : out std_logic;
    eeprom_scl_i : in  std_logic;
    eeprom_scl_o : out std_logic;

    ---------------------------------------------------------------------------
    -- UART
    ---------------------------------------------------------------------------
    uart_rxd_i : in  std_logic;
    uart_txd_o : out std_logic;

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
    -- 1PPS output
    pps_p_o    : out std_logic;
    pps_led_o  : out std_logic;
    -- Link ok indication
    link_ok_o  : out std_logic
    );

end entity xwrc_board_pxie_fmc;


architecture struct of xwrc_board_pxie_fmc is

  -- PLLs, clocks
  signal clk_125m_pllref_buf : std_logic;
  signal clk_125m_dmtd_buf   : std_logic;
  signal clk_pll_62m5        : std_logic;
  signal clk_pll_125m        : std_logic;
  signal clk_pll_dmtd        : std_logic;
  signal pll_locked          : std_logic;

  -- Reset logic
  signal areset_edge_ppulse : std_logic;
  signal rst_62m5_n         : std_logic;
  signal rstlogic_arst      : std_logic;
  signal rstlogic_clk_in    : std_logic_vector(1 downto 0);
  signal rstlogic_rst_out   : std_logic_vector(1 downto 0);

  -- PLL DAC ARB
  signal dac_hpll_load_p1 : std_logic;
  signal dac_hpll_data    : std_logic_vector(15 downto 0);
  signal dac_dpll_load_p1 : std_logic;
  signal dac_dpll_data    : std_logic_vector(15 downto 0);

  -- PHY
  signal phy16_to_wrc   : t_phy_16bits_to_wrc;
  signal phy16_from_wrc : t_phy_16bits_from_wrc;

begin  -- architecture struct

  -----------------------------------------------------------------------------
  -- Platform-dependent part (PHY, PLLs, buffers, etc)
  -----------------------------------------------------------------------------

  cmp_ibufgds_pllmain : IBUFDS
    generic map (
      DQS_BIAS     => "FALSE")
    port map (
      O  => clk_125m_pllref_buf,
      I  => wr_clk_main_125m_p_i,
      IB => wr_clk_main_125m_n_i);

  cmp_ibufgds_dmtd : IBUFDS
    generic map (
      DQS_BIAS     => "FALSE")
    port map (
      O  => clk_125m_dmtd_buf,
      I  => wr_clk_helper_125m_p_i,
      IB => wr_clk_helper_125m_n_i);

  cmp_xwrc_platform : xwrc_platform_xilinx
    generic map (
      g_fpga_family               => "zynqus",
      g_with_external_clock_input => FALSE,
      g_use_default_plls          => TRUE,
      g_simulation                => g_simulation)
    port map (
      areset_n_i            => areset_n_i,
      clk_125m_pllref_i     => clk_125m_pllref_buf,
      clk_125m_gtp_p_i      => wr_clk_sfp_125m_p_i,
      clk_125m_gtp_n_i      => wr_clk_sfp_125m_n_i,
      clk_125m_dmtd_i       => clk_125m_dmtd_buf,
      sfp_txn_o             => sfp_txn_o,
      sfp_txp_o             => sfp_txp_o,
      sfp_rxn_i             => sfp_rxn_i,
      sfp_rxp_i             => sfp_rxp_i,
      sfp_tx_fault_i        => sfp_tx_fault_i,
      sfp_los_i             => sfp_los_i,
      sfp_tx_disable_o      => sfp_tx_disable_o,
      clk_62m5_sys_o        => clk_pll_62m5,
      clk_125m_ref_o        => clk_pll_125m,
      clk_62m5_dmtd_o       => clk_pll_dmtd,
      pll_locked_o          => pll_locked,
      phy16_o               => phy16_to_wrc,
      phy16_i               => phy16_from_wrc);

  clk_ref_125m_o <= clk_pll_125m;
  clk_sys_62m5_o <= clk_pll_62m5;

  -----------------------------------------------------------------------------
  -- Reset logic
  -----------------------------------------------------------------------------
  -- Detect when areset_edge_n_i goes high (end of reset) and use this edge to
  -- generate rstlogic_arst. This is needed to connect optional reset like PCIe
  -- reset. When baord runs standalone, we need to ignore PCIe reset being
  -- constantly low.
  cmp_arst_edge: gc_sync_ffs
    generic map (
      g_sync_edge => "positive")
    port map (
      clk_i    => clk_pll_62m5,
      rst_n_i  => '1',
      data_i   => areset_edge_n_i,
      ppulse_o => areset_edge_ppulse);

  -- logic AND of all async reset sources (active high)
  rstlogic_arst <= (not pll_locked) and (not areset_n_i) and areset_edge_ppulse;

  -- concatenation of all clocks required to have synced resets
  rstlogic_clk_in(0)          <= clk_pll_62m5;
  rstlogic_clk_in(1)          <= clk_pll_125m;

  cmp_rstlogic_reset : gc_reset_multi_aasd
    generic map (
      g_CLOCKS  => 2,   -- 62.5MHz, 125MHz
      g_RST_LEN => 16)  -- 16 clock cycles
    port map (
      arst_i  => rstlogic_arst,
      clks_i  => rstlogic_clk_in,
      rst_n_o => rstlogic_rst_out);

  -- distribution of resets (already synchronized to their clock domains)
  rst_62m5_n <= rstlogic_rst_out(0);

  rst_sys_62m5_n_o <= rst_62m5_n;
  rst_ref_125m_n_o <= rstlogic_rst_out(1);

  -----------------------------------------------------------------------------
  -- 2x SPI DAC
  -----------------------------------------------------------------------------

  cmp_dac_arb : spec_serial_dac_arb
    generic map (
      g_invert_sclk    => FALSE,
      g_num_extra_bits => 8)
    port map (
      clk_i         => clk_pll_62m5,
      rst_n_i       => rst_62m5_n,
      val1_i        => dac_dpll_data,
      load1_i       => dac_dpll_load_p1,
      val2_i        => dac_hpll_data,
      load2_i       => dac_hpll_load_p1,
      dac_cs_n_o(0) => pll25dac_cs_n_o,
      dac_cs_n_o(1) => pll20dac_cs_n_o,
      dac_sclk_o    => plldac_sclk_o,
      dac_din_o     => plldac_din_o);

  -----------------------------------------------------------------------------
  -- The WR PTP Core
  -----------------------------------------------------------------------------

  cmp_board_common : xwrc_board_common
    generic map (
      g_simulation                => g_simulation,
      g_verbose                   => TRUE,
      g_with_external_clock_input => FALSE,
      g_board_name                => "PXIE",
      g_phys_uart                 => TRUE,
      g_virtual_uart              => TRUE,
      g_ep_rxbuf_size             => 1024,
      g_tx_runt_padding           => TRUE,
      g_dpram_initf               => g_dpram_initf,
      g_dpram_size                => 131072/4,
      g_interface_mode            => PIPELINED,
      g_address_granularity       => BYTE,
      g_aux_sdb                   => g_aux_sdb,
      g_softpll_enable_debugger   => FALSE,
      g_vuart_fifo_size           => 1024,
      g_pcs_16bit                 => TRUE,
      g_fabric_iface              => PLAIN)
    port map (
      clk_sys_i            => clk_pll_62m5,
      clk_dmtd_i           => clk_pll_dmtd,
      clk_ref_i            => clk_pll_125m,
      rst_n_i              => rst_62m5_n,
      dac_hpll_load_p1_o   => dac_hpll_load_p1,
      dac_hpll_data_o      => dac_hpll_data,
      dac_dpll_load_p1_o   => dac_dpll_load_p1,
      dac_dpll_data_o      => dac_dpll_data,
      phy16_o              => phy16_from_wrc,
      phy16_i              => phy16_to_wrc,
      scl_o                => eeprom_scl_o,
      scl_i                => eeprom_scl_i,
      sda_o                => eeprom_sda_o,
      sda_i                => eeprom_sda_i,
      sfp_scl_o            => sfp_scl_o,
      sfp_scl_i            => sfp_scl_i,
      sfp_sda_o            => sfp_sda_o,
      sfp_sda_i            => sfp_sda_i,
      sfp_det_i            => sfp_det_i,
      uart_rxd_i           => uart_rxd_i,
      uart_txd_o           => uart_txd_o,
      wb_slave_i           => wb_slave_i,
      wb_slave_o           => wb_slave_o,
      aux_master_o         => aux_master_o,
      aux_master_i         => aux_master_i,
      wrf_src_o            => wrf_src_o,
      wrf_src_i            => wrf_src_i,
      wrf_snk_o            => wrf_snk_o,
      wrf_snk_i            => wrf_snk_i,
      tm_link_up_o         => tm_link_up_o,
      tm_time_valid_o      => tm_time_valid_o,
      tm_tai_o             => tm_tai_o,
      tm_cycles_o          => tm_cycles_o,
      led_act_o            => led_act_o,
      led_link_o           => led_link_o,
      pps_p_o              => pps_p_o,
      pps_led_o            => pps_led_o,
      link_ok_o            => link_ok_o);

  sfp_rate_select_o <= '1';

end architecture struct;
