-------------------------------------------------------------------------------
-- Title      : recordless wrapper around xwrf_gmii
-- Project    :
-------------------------------------------------------------------------------
-- File       : wrf_gmii.vhd
-- Author     : Jonah Foley
-- Company    : Nu Quantum Ltd.
-- Created    : 03-09-2024
-- Last update: 03-09-2024
-- Platform   : Xilinx Artix 7
-- Standard   : VHDL'93
-------------------------------------------------------------------------------
-- Description: Wraps xwrf_gmii expanding the WRF interface to plain signals
-------------------------------------------------------------------------------
--
-- Copyright (c) 2011 CERN
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
-- Revisions  :
-- Date        Version  Author          Description
-- 2015-01-26  1.0      lihm            Created
-------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.endpoint_pkg.all;
use work.wishbone_pkg.all;
use work.wr_fabric_pkg.all;
use work.gencores_pkg.all;

library unisim;
use unisim.vcomponents.all;

entity wrf_gmii is
port (
    clk_sys_i           : in std_logic;
    rst_sys_n_i         : in std_logic;

    wrf_src_adr_o       : out std_logic_vector(1 downto 0);
    wrf_src_dat_o       : out std_logic_vector(15 downto 0);
    wrf_src_cyc_o       : out std_logic;
    wrf_src_stb_o       : out std_logic;
    wrf_src_we_o        : out std_logic;
    wrf_src_sel_o       : out std_logic_vector(1 downto 0);

    wrf_src_ack_i       : in  std_logic;
    wrf_src_stall_i     : in  std_logic;
    wrf_src_err_i       : in  std_logic;
    wrf_src_rty_i       : in  std_logic;

    wrf_snk_adr_i       : in  std_logic_vector(1 downto 0);
    wrf_snk_dat_i       : in  std_logic_vector(15 downto 0);
    wrf_snk_cyc_i       : in  std_logic;
    wrf_snk_stb_i       : in  std_logic;
    wrf_snk_we_i        : in  std_logic;
    wrf_snk_sel_i       : in  std_logic_vector(1 downto 0);

    wrf_snk_ack_o       : out std_logic;
    wrf_snk_stall_o     : out std_logic;
    wrf_snk_err_o       : out std_logic;
    wrf_snk_rty_o       : out std_logic;
    
    gmii_rx_rst_n_i     : in  std_logic;
    gmii_rx_125m_i      : in  std_logic;
    gmii_rxd_i          : in  std_logic_vector(7 downto 0);
    gmii_rxdv_i         : in  std_logic;
    gmii_rx_er          : in  std_logic;

    gmii_tx_125m_i      : in  std_logic;
    gmii_tx_rst_n_i     : in  std_logic;
    gmii_txdata_o       : out std_logic_vector(7 downto 0);
    gmii_txen_o         : out std_logic;
    gmii_tx_er_o        : out std_logic
);
end entity;

architecture rtl of wrf_gmii is

  -- WR fabric interface
  signal wrf_src_out : t_wrf_source_out;
  signal wrf_src_in  : t_wrf_source_in;
  signal wrf_snk_out : t_wrf_sink_out;
  signal wrf_snk_in  : t_wrf_sink_in;

begin  -- rtl

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
  
  u_wrf_gmii_warpped : xwrf_gmii 
    port map (
        clk_sys_i           => clk_sys_i,
        rst_sys_n_i         => rst_sys_n_i,

        wrf_snk_i           => wrf_snk_in,
        wrf_snk_o           => wrf_snk_out,
        wrf_src_i           => wrf_src_in,
        wrf_src_o           => wrf_src_out,

        gmii_rx_rst_n_i     => gmii_rx_rst_n_i,
        gmii_rx_125m_i      => gmii_rx_125m_i,
        gmii_rxd_i          => gmii_rxd_i,
        gmii_rxdv_i         => gmii_rxdv_i,
        gmii_rx_er          => gmii_rx_er,

        gmii_tx_125m_i      => gmii_tx_125m_i,
        gmii_tx_rst_n_i     => gmii_tx_rst_n_i,
        gmii_txdata_o       => gmii_txdata_o,
        gmii_txen_o         => gmii_txen_o,
        gmii_tx_er_o        => gmii_tx_er_o
    );

end rtl;
