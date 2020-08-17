-------------------------------------------------------------------------------
-- Title      : WRPC Wrapper for SPEC package
-- Project    : WR PTP Core
-- URL        : http://www.ohwr.org/projects/wr-cores/wiki/Wrpc_core
-------------------------------------------------------------------------------
-- File       : wr_pxie_fmc_pkg.vhd
-- Author(s)  : Greg Daniluk <grzegorz.daniluk@cern.ch>
-- Company    : CERN (BE-CO-HT)
-- Standard   : VHDL'93
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
use work.wishbone_pkg.all;
use work.wrcore_pkg.all;
use work.wr_fabric_pkg.all;
use work.endpoint_pkg.all;
use work.wr_board_pkg.all;
use work.wr_xilinx_pkg.all;
use work.streamers_pkg.all;

package wr_pxie_fmc_pkg is

  component xwrc_board_pxie_fmc is
    generic(
      g_simulation                : integer              := 0;
      g_aux_clks                  : integer              := 0;
      g_dpram_initf               : string               := "default_xilinx";
      g_aux_sdb                   : t_sdb_device         := c_wrc_periph3_sdb
      );
    port (
      areset_n_i             : in  std_logic;
      areset_edge_n_i        : in  std_logic := '1';
      wr_clk_helper_125m_p_i : in  std_logic;
      wr_clk_helper_125m_n_i : in  std_logic;
      wr_clk_main_125m_p_i   : in  std_logic;
      wr_clk_main_125m_n_i   : in  std_logic;
      wr_clk_sfp_125m_p_i    : in  std_logic;
      wr_clk_sfp_125m_n_i    : in  std_logic;
  
      clk_sys_62m5_o      : out std_logic;
      clk_ref_125m_o      : out std_logic;
      rst_sys_62m5_n_o    : out std_logic;
      rst_ref_125m_n_o    : out std_logic;
  
      plldac_sclk_o   : out std_logic;
      plldac_din_o    : out std_logic;
      pll25dac_cs_n_o : out std_logic;
      pll20dac_cs_n_o : out std_logic;
  
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
  
      eeprom_sda_i : in  std_logic;
      eeprom_sda_o : out std_logic;
      eeprom_scl_i : in  std_logic;
      eeprom_scl_o : out std_logic;
      uart_rxd_i : in  std_logic;
      uart_txd_o : out std_logic;
  
      wb_slave_o   : out t_wishbone_slave_out;
      wb_slave_i   : in  t_wishbone_slave_in := cc_dummy_slave_in;
      aux_master_o : out t_wishbone_master_out;
      aux_master_i : in  t_wishbone_master_in := cc_dummy_master_in;
  
      wrf_src_o    : out t_wrf_source_out;
      wrf_src_i    : in  t_wrf_source_in := c_dummy_src_in;
      wrf_snk_o    : out t_wrf_sink_out;
      wrf_snk_i    : in  t_wrf_sink_in   := c_dummy_snk_in;
  
      tm_link_up_o    : out std_logic;
      tm_time_valid_o : out std_logic;
      tm_tai_o        : out std_logic_vector(39 downto 0);
      tm_cycles_o     : out std_logic_vector(27 downto 0);
  
      led_act_o  : out std_logic;
      led_link_o : out std_logic;
      pps_p_o    : out std_logic;
      pps_led_o  : out std_logic;
      link_ok_o  : out std_logic);
  
  end component xwrc_board_pxie_fmc;

end wr_pxie_fmc_pkg;
