library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.wishbone_pkg.all;
use work.wr_fabric_pkg.all;

package endpoint_pkg is

  component wr_endpoint
    generic (
      g_interface_mode      : t_wishbone_interface_mode      := CLASSIC;
        g_address_granularity : t_wishbone_address_granularity := WORD;
      g_simulation          : boolean := false;
      g_tx_force_gap_length : integer := 0;
      g_pcs_16bit           : boolean := false;
      g_rx_buffer_size      : integer := 1024;
      g_with_rx_buffer      : boolean := true;
      g_with_flow_control   : boolean := true;
      g_with_timestamper    : boolean := true;
      g_with_dpi_classifier : boolean := false;
      g_with_vlans          : boolean := false;
      g_with_rtu            : boolean := false;
      g_with_leds           : boolean := false);
    port (
      clk_ref_i          : in  std_logic;
      clk_sys_i          : in  std_logic;
      clk_dmtd_i : in std_logic := '0';
      rst_n_i            : in  std_logic;
      pps_csync_p1_i     : in  std_logic                     := '0';
      phy_rst_o          : out std_logic;
      phy_loopen_o       : out std_logic;
      phy_enable_o       : out std_logic;
      phy_syncen_o       : out std_logic;
      phy_ref_clk_i      : in  std_logic                     := '0';
      phy_tx_data_o      : out std_logic_vector(15 downto 0);
      phy_tx_k_o         : out std_logic_vector(1 downto 0);
      phy_tx_disparity_i : in  std_logic                     := '0';
      phy_tx_enc_err_i   : in  std_logic                     := '0';
      phy_rx_data_i      : in  std_logic_vector(15 downto 0) := x"0000";
      phy_rx_clk_i       : in  std_logic                     := '0';
      phy_rx_k_i         : in  std_logic_vector(1 downto 0)  := "00";
      phy_rx_enc_err_i   : in  std_logic                     := '0';
      phy_rx_bitslide_i  : in  std_logic_vector(4 downto 0)  := "00000";
      gmii_tx_clk_i      : in  std_logic                     := '0';
      gmii_txd_o         : out std_logic_vector(7 downto 0);
      gmii_tx_en_o       : out std_logic;
      gmii_tx_er_o       : out std_logic;
      gmii_rx_clk_i      : in  std_logic                     := '0';
      gmii_rxd_i         : in  std_logic_vector(7 downto 0)  := x"00";
      gmii_rx_er_i       : in  std_logic                     := '0';
      gmii_rx_dv_i       : in  std_logic := '0';
      src_dat_o          : out std_logic_vector(15 downto 0);
      src_adr_o          : out std_logic_vector(1 downto 0);
      src_sel_o          : out std_logic_vector(1 downto 0);
      src_cyc_o          : out std_logic;
      src_stb_o          : out std_logic;
      src_we_o           : out std_logic;
      src_stall_i        : in  std_logic;
      src_ack_i          : in  std_logic;
      src_err_i          : in  std_logic;
      snk_dat_i          : in  std_logic_vector(15 downto 0);
      snk_adr_i          : in  std_logic_vector(1 downto 0);
      snk_sel_i          : in  std_logic_vector(1 downto 0);
      snk_cyc_i          : in  std_logic;
      snk_stb_i          : in  std_logic;
      snk_we_i           : in  std_logic;
      snk_stall_o        : out std_logic;
      snk_ack_o          : out std_logic;
      snk_err_o          : out std_logic;
      snk_rty_o          : out std_logic;
      txtsu_port_id_o    : out std_logic_vector(4 downto 0);
      txtsu_frame_id_o   : out std_logic_vector(16 - 1 downto 0);
      txtsu_tsval_o      : out std_logic_vector(28 + 4 - 1 downto 0);
      txtsu_valid_o      : out std_logic;
      txtsu_ack_i        : in  std_logic                     := '1';
      rtu_full_i         : in  std_logic                     := '0';
      rtu_almost_full_i  : in  std_logic                     := '0';
      rtu_rq_strobe_p1_o : out std_logic;
      rtu_rq_smac_o      : out std_logic_vector(48 - 1 downto 0);
      rtu_rq_dmac_o      : out std_logic_vector(48 - 1 downto 0);
      rtu_rq_vid_o       : out std_logic_vector(12 - 1 downto 0);
      rtu_rq_has_vid_o   : out std_logic;
      rtu_rq_prio_o      : out std_logic_vector(3 - 1 downto 0);
      rtu_rq_has_prio_o  : out std_logic;
      wb_cyc_i           : in  std_logic;
      wb_stb_i           : in  std_logic;
      wb_we_i            : in  std_logic;
      wb_sel_i           : in  std_logic_vector(3 downto 0);
      wb_adr_i           : in  std_logic_vector(7 downto 0);
      wb_dat_i           : in  std_logic_vector(31 downto 0);
      wb_dat_o           : out std_logic_vector(31 downto 0);
      wb_ack_o           : out std_logic;
      wb_stall_o: out std_logic;
      led_link_o         : out std_logic;
      led_act_o          : out std_logic);
  end component;

  constant c_xwr_endpoint_sdwb : t_sdwb_device := (
    wbd_begin     => x"0000000000000000",
    wbd_end       => x"00000000000000ff",
    sdwb_child    => x"0000000000000000",
    wbd_flags     => x"01", -- big-endian, no-child, present
    wbd_width     => x"07", -- 8/16/32-bit port granularity
    abi_ver_major => x"01",
    abi_ver_minor => x"01",
    abi_class     => x"00000000", -- undocumented device
    dev_vendor    => x"0000CE42", -- CERN
    dev_device    => x"650c2d4f",
    dev_version   => x"00000001",
    dev_date      => x"20120305",
    description   => "WR-Endpoint     ");
  component xwr_endpoint
    generic (
      g_interface_mode      : t_wishbone_interface_mode      := CLASSIC;
      g_address_granularity : t_wishbone_address_granularity := WORD;
      g_simulation          : boolean := false;
      g_pcs_16bit           : boolean := false;
      g_tx_force_gap_length : integer := 0;
      g_rx_buffer_size      : integer := 1024;
      g_with_rx_buffer      : boolean := true;
      g_with_flow_control   : boolean := true;
      g_with_timestamper    : boolean := true;
      g_with_dpi_classifier : boolean := false;
      g_with_vlans          : boolean := false;
      g_with_rtu            : boolean := false;
      g_with_leds           : boolean := false);
    port (
      clk_ref_i          : in  std_logic;
      clk_sys_i          : in  std_logic;
      clk_dmtd_i: in std_logic := '0';
      rst_n_i            : in  std_logic;
      pps_csync_p1_i     : in  std_logic                    := '0';
      phy_rst_o          : out std_logic;
      phy_loopen_o       : out std_logic;
      phy_enable_o       : out std_logic;
      phy_syncen_o       : out std_logic;
      phy_ref_clk_i      : in  std_logic;
      phy_tx_data_o      : out std_logic_vector(15 downto 0);
      phy_tx_k_o         : out std_logic_vector(1 downto 0);
      phy_tx_disparity_i : in  std_logic;
      phy_tx_enc_err_i   : in  std_logic;
      phy_rx_data_i      : in  std_logic_vector(15 downto 0);
      phy_rx_clk_i       : in  std_logic;
      phy_rx_k_i         : in  std_logic_vector(1 downto 0);
      phy_rx_enc_err_i   : in  std_logic;
      phy_rx_bitslide_i  : in  std_logic_vector(4 downto 0);
      gmii_tx_clk_i      : in  std_logic                    := '0';
      gmii_txd_o         : out std_logic_vector(7 downto 0);
      gmii_tx_en_o       : out std_logic;
      gmii_tx_er_o       : out std_logic;
      gmii_rx_clk_i      : in  std_logic                    := '0';
      gmii_rxd_i         : in  std_logic_vector(7 downto 0) := x"00";
      gmii_rx_er_i       : in  std_logic                    := '0';
      gmii_rx_dv_i       : in  std_logic                    := '0';
      src_o              : out t_wrf_source_out;
      src_i              : in  t_wrf_source_in;
      snk_o              : out t_wrf_sink_out;
      snk_i              : in  t_wrf_sink_in;
      txtsu_port_id_o    : out std_logic_vector(4 downto 0);
      txtsu_frame_id_o   : out std_logic_vector(16 - 1 downto 0);
      txtsu_tsval_o      : out std_logic_vector(28 + 4 - 1 downto 0);
      txtsu_valid_o      : out std_logic;
      txtsu_ack_i        : in  std_logic                    := '1';
      rtu_full_i         : in  std_logic                    := '0';
      rtu_almost_full_i  : in  std_logic                    := '0';
      rtu_rq_strobe_p1_o : out std_logic;
      rtu_rq_smac_o      : out std_logic_vector(48 - 1 downto 0);
      rtu_rq_dmac_o      : out std_logic_vector(48 - 1 downto 0);
      rtu_rq_vid_o       : out std_logic_vector(12 - 1 downto 0);
      rtu_rq_has_vid_o   : out std_logic;
      rtu_rq_prio_o      : out std_logic_vector(3 - 1 downto 0);
      rtu_rq_has_prio_o  : out std_logic;
      wb_i               : in    t_wishbone_slave_in;
      wb_o               : out    t_wishbone_slave_out;
      led_link_o         : out std_logic;
      led_act_o          : out std_logic);
  end component;
end endpoint_pkg;

-------------------------------------------------------------------------------
