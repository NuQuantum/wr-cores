
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.wr_fabric_pkg.all;
use work.endpoint_pkg.all;

package wrf_gmii_pkg is

  -- This component definition is not provided by endpoint_pkg
  component ep_rx_wb_master is
    generic(
      g_ignore_ack   : boolean := true;
      g_cyc_on_stall : boolean := false);
    port (
      clk_sys_i : in std_logic;
      rst_n_i   : in std_logic;

      stop_traffic_i : in std_logic := '0';
      -- physical coding sublayer (PCS) interface
      snk_fab_i  : in  t_ep_internal_fabric;
      snk_dreq_o : out std_logic;

      -- Wishbone I/O (master)
      src_wb_i : in  t_wrf_source_in;
      src_wb_o : out t_wrf_source_out
    );

  end component ep_rx_wb_master;

  component wrf_gmii is
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
  end component wrf_gmii;

  component xwrf_gmii is
    port (
        clk_sys_i           : in std_logic;
        rst_sys_n_i         : in std_logic;

        wrf_snk_i           : in  t_wrf_sink_in;
        wrf_snk_o           : out t_wrf_sink_out;
        wrf_src_i           : in  t_wrf_source_in;
        wrf_src_o           : out t_wrf_source_out;

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
    end component;

end package;