-------------------------------------------------------------------------------
-- Title      : WRPC Wrapper for kasli package
-- Project    : WR PTP Core
-- URL        : http://www.ohwr.org/projects/wr-cores/wiki/Wrpc_core
-------------------------------------------------------------------------------
-- File       : wr_kasli_pkg.vhd
-- Author(s)  : Jonah Foley <jonah.foley@nu-quantum.com>
-- Company    : CERN (BE-CO-HT)
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

package wr_kasli_pkg is

  component xwrc_board_kasli
    generic(
      -- set to 1 to speed up some initialization processes during simulation
      g_simulation                 : integer               := 0;
      -- Select whether to include external ref clock input
      g_aux_clks                   : integer               := 4;
      -- plain     = expose WRC fabric interface
      -- streamers = attach WRC streamers to fabric interface
      -- etherbone = attach Etherbone slave to fabric interface
      g_fabric_iface               : t_board_fabric_iface  := plain;
      -- parameters configuration when g_fabric_iface = "streamers" (otherwise ignored)
      g_streamers_op_mode          : t_streamers_op_mode   := TX_AND_RX;
      g_tx_streamer_params         : t_tx_streamer_params  := c_tx_streamer_params_defaut;
      g_rx_streamer_params         : t_rx_streamer_params  := c_rx_streamer_params_defaut;
      -- memory initialisation file for embedded CPU
      g_dpram_initf                : string                := "../wrpc/wrc_phy16.bram";
      -- identification (id and ver) of the layout of words in the generic diag interface
      g_diag_id                    : integer               := 0;
      g_diag_ver                   : integer               := 0;
      -- size the generic diag interface
      g_diag_ro_size               : integer               := 0;
      g_diag_rw_size               : integer               := 0;
      -- User-defined PLL_BASE outputs config
      g_aux_pll_cfg                : t_auxpll_cfg_array    := c_AUXPLL_CFG_ARRAY_DEFAULT
    );
    port (
      ---------------------------------------------------------------------------
      -- Clocks/resets
      ---------------------------------------------------------------------------
      -- Clock inputs from the board
      clk_20m_vcxo_i         : in  std_logic;
      clk_125m_pllref_p_i    : in  std_logic;
      clk_125m_pllref_n_i    : in  std_logic;
      clk_125m_gtp_p_i       : in  std_logic;
      clk_125m_gtp_n_i       : in  std_logic;
      clk_125m_bootstrap_p_i : in  std_logic;            
      clk_125m_bootstrap_n_i : in  std_logic;
      -- Configurable (with g_aux_pll_cfg) clock outputs from the main PLL_BASE
      clk_pll_aux_o          : out std_logic_vector(3 downto 0);

      ---------------------------------------------------------------------------
      -- I2C SI549s (Main = 0, Helper = 1)
      ---------------------------------------------------------------------------
      si549_sda_i : in  std_logic_vector(1 downto 0);
      si549_sda_o : in  std_logic_vector(1 downto 0);
      si549_sda_t : out std_logic_vector(1 downto 0);

      si549_scl_i : in  std_logic_vector(1 downto 0);
      si549_scl_o : in  std_logic_vector(1 downto 0);
      si549_scl_t : out std_logic_vector(1 downto 0);

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

      ---------------------------------------------------------------------------
      -- Flash memory SPI interface
      ---------------------------------------------------------------------------
      flash_sclk_o : out std_logic;
      flash_ncs_o  : out std_logic;
      flash_mosi_o : out std_logic;
      flash_miso_i : in  std_logic;

      ------------------------------------------
      -- Axi Slave Bus Interface S01_AXI
      ------------------------------------------
      s01_axi_i : in  t_axi4_lite_slave_in_32;
      s01_axi_o : out t_axi4_lite_slave_out_32;

      -- clock and reset
      s01_axi_aclk_o : out std_logic;

      ------------------------------------------
      -- Axi Master Bus Interface M01_AXI
      ------------------------------------------
      m01_axi_o : out t_axi4_lite_master_out_32;
      m01_axi_i : in  t_axi4_lite_master_in_32;

      -- clock and reset
      m01_axi_aclk_o : out std_logic;

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
      tm_dac_value_o       : out std_logic_vector(31 downto 0);
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
      pps_p_o    : out std_logic;
      pps_led_o  : out std_logic;
      link_ok_o  : out std_logic
    );
  end component xwrc_board_kasli;

end wr_kasli_pkg;
