library ieee;
use ieee.std_logic_1164.all;

library unisim;
use unisim.vcomponents.all;

entity kasli_soc is
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
    g_dpram_initf               : string  := "../wrc_phy16.bram";
    -- identification (id and ver) of the layout of words in the generic diag interface
    g_diag_id                   : integer := 0;
    g_diag_ver                  : integer := 0;
    -- size the generic diag interface
    g_diag_ro_vector_width      : integer := 0;
    g_diag_rw_vector_width      : integer := 0
    );
  port (
    DDR_addr : inout STD_LOGIC_VECTOR ( 14 downto 0 );
    DDR_ba : inout STD_LOGIC_VECTOR ( 2 downto 0 );
    DDR_cas_n : inout STD_LOGIC;
    DDR_ck_n : inout STD_LOGIC;
    DDR_ck_p : inout STD_LOGIC;
    DDR_cke : inout STD_LOGIC;
    DDR_cs_n : inout STD_LOGIC;
    DDR_dm : inout STD_LOGIC_VECTOR ( 3 downto 0 );
    DDR_dq : inout STD_LOGIC_VECTOR ( 31 downto 0 );
    DDR_dqs_n : inout STD_LOGIC_VECTOR ( 3 downto 0 );
    DDR_dqs_p : inout STD_LOGIC_VECTOR ( 3 downto 0 );
    DDR_odt : inout STD_LOGIC;
    DDR_ras_n : inout STD_LOGIC;
    DDR_reset_n : inout STD_LOGIC;
    DDR_we_n : inout STD_LOGIC;
    dio_oe_n : out std_logic_vector(2 downto 0);
    dio_term : out std_logic_vector(2 downto 0);
    FIXED_IO_ddr_vrn : inout STD_LOGIC;
    FIXED_IO_ddr_vrp : inout STD_LOGIC;
    FIXED_IO_mio : inout STD_LOGIC_VECTOR ( 53 downto 0 );
    FIXED_IO_ps_clk : inout STD_LOGIC;
    FIXED_IO_ps_porb : inout STD_LOGIC;
    FIXED_IO_ps_srstb : inout STD_LOGIC;

    SFP_rxn : in std_logic;
    SFP_rxp : in std_logic;
    SFP_txn : out std_logic;
    SFP_txp : out std_logic;

    clk_125m_gtp_n_i : in std_logic;
    clk_125m_gtp_p_i : in std_logic;
    clk_125m_pllref_n_i : in std_logic;
    clk_125m_pllref_p_i : in std_logic;

    clk_ref_125m_n : out std_logic_vector(0 downto 0);
    clk_ref_125m_p : out std_logic_vector(0 downto 0);
    ddmtd_helper_clk_n : out std_logic;
    ddmtd_helper_clk_p : out std_logic;
    eeprom_i2c_scl_io : inout std_logic;
    eeprom_i2c_sda_io : inout std_logic;


    UART_rxd     : in  STD_LOGIC := '0';
    UART_txd     : out STD_LOGIC := '0';

    -- rtio core
      dio0_p             : inout std_logic;
  dio0_n             : inout std_logic;
  dio0_p_1           : inout std_logic;
  dio0_n_1           : inout std_logic;
  dio0_p_2           : inout std_logic;
  dio0_n_2           : inout std_logic;
  dio0_p_3           : inout std_logic;
  dio0_n_3           : inout std_logic;
  dio0_p_4           : inout std_logic;
  dio0_n_4           : inout std_logic;
  dio0_p_5           : inout std_logic;
  dio0_n_5           : inout std_logic;
  dio0_p_6           : inout std_logic;
  dio0_n_6           : inout std_logic;
  dio0_p_7           : inout std_logic;
  dio0_n_7           : inout std_logic;
  pulsar5_spi_p_clk  : out std_logic;
  pulsar5_spi_p_mosi : inout std_logic;
  pulsar5_spi_p_miso : inout std_logic;
  pulsar5_spi_p_cs_n : out std_logic_vector(3 downto 0);
  pulsar5_spi_n_clk  : out std_logic;
  pulsar5_spi_n_mosi : inout std_logic;
  pulsar5_spi_n_miso : inout std_logic;
  pulsar5_spi_n_cs_n : out std_logic_vector(3 downto 0)
  );
end entity;

architecture rtl of kasli_soc is

--------------------------------------------------------------------
-- These signals have been removed from the entity and tied off
-- I am not yet sure where they should go
--------------------------------------------------------------------
signal sfp_i2c_scl_io :  std_logic;
signal sfp_i2c_sda_io :  std_logic;

-- These signals are only accessable via 12c
signal SFP_mod_abs       : std_logic := '0';
signal SFP_rx_los        : std_logic := '0';
signal SFP_tx_disable    : std_logic := '0';
signal SFP_tx_fault      : std_logic := '0';
signal sfp_rate_select_o : std_logic;

signal pps_n            : std_logic_vector(0 downto 0);
signal pps_p            : std_logic_vector(0 downto 0);
signal thermo_id_tri_io : std_logic;

signal clk_20m_vcxo_i   : std_logic := '0';

signal areset_n_i      : std_logic := '1';

signal pll20dac_cs_n_o : std_logic;
signal pll25dac_cs_n_o : std_logic;
signal plldac_din_o    : std_logic;
signal plldac_sclk_o   : std_logic;
--------------------------------------------------------------------

component rtio_core is
port(
	m_axi_gp0_awid     : in std_logic_vector(11 downto 0);
	m_axi_gp0_awaddr   : in std_logic_vector(31 downto 0);
	m_axi_gp0_awlen    : in std_logic_vector(7 downto 0);
	m_axi_gp0_awsize   : in std_logic_vector(2 downto 0);
	m_axi_gp0_awburst  : in std_logic_vector(1 downto 0);
	m_axi_gp0_awlock   : in std_logic_vector(1 downto 0) := (others=>'0');
	m_axi_gp0_awcache  : in std_logic_vector(3 downto 0);
	m_axi_gp0_awprot   : in std_logic_vector(2 downto 0);
	m_axi_gp0_awqos    : in std_logic_vector(3 downto 0);
	m_axi_gp0_awvalid  : in std_logic;
	m_axi_gp0_awready  : out std_logic;
	m_axi_gp0_wid      : in std_logic_vector(11 downto 0);
	m_axi_gp0_wdata    : in std_logic_vector(31 downto 0);
	m_axi_gp0_wstrb    : in std_logic_vector(3 downto 0);
	m_axi_gp0_wlast    : in std_logic;
	m_axi_gp0_wvalid   : in std_logic;
	m_axi_gp0_wready   : out std_logic;
	m_axi_gp0_bid      : out std_logic_vector(11 downto 0);
	m_axi_gp0_bresp    : out std_logic_vector(1 downto 0);
	m_axi_gp0_bvalid   : out std_logic;
	m_axi_gp0_bready   : in std_logic;
	m_axi_gp0_arid     : in std_logic_vector(11 downto 0);
	m_axi_gp0_araddr   : in std_logic_vector(31 downto 0);
	m_axi_gp0_arlen    : in std_logic_vector(7 downto 0);
	m_axi_gp0_arsize   : in std_logic_vector(2 downto 0);
	m_axi_gp0_arburst  : in std_logic_vector(1 downto 0);
	m_axi_gp0_arlock   : in std_logic_vector(1 downto 0) := (others=>'0');
	m_axi_gp0_arcache  : in std_logic_vector(3 downto 0);
	m_axi_gp0_arprot   : in std_logic_vector(2 downto 0);
	m_axi_gp0_arqos    : in std_logic_vector(3 downto 0);
	m_axi_gp0_arvalid  : in std_logic;
	m_axi_gp0_arready  : out std_logic;
	m_axi_gp0_rid      : out std_logic_vector(11 downto 0);
	m_axi_gp0_rdata    : out std_logic_vector(31 downto 0);
	m_axi_gp0_rresp    : out std_logic_vector(1 downto 0);
	m_axi_gp0_rlast    : out std_logic;
	m_axi_gp0_rvalid   : out std_logic;
	m_axi_gp0_rready   : in std_logic;
	m_axi_gp1_awid     : in std_logic_vector(11 downto 0);
	m_axi_gp1_awaddr   : in std_logic_vector(31 downto 0);
	m_axi_gp1_awlen    : in std_logic_vector(7 downto 0);
	m_axi_gp1_awsize   : in std_logic_vector(2 downto 0);
	m_axi_gp1_awburst  : in std_logic_vector(1 downto 0);
	m_axi_gp1_awlock   : in std_logic_vector(1 downto 0) := (others=>'0');
	m_axi_gp1_awcache  : in std_logic_vector(3 downto 0);
	m_axi_gp1_awprot   : in std_logic_vector(2 downto 0);
	m_axi_gp1_awqos    : in std_logic_vector(3 downto 0);
	m_axi_gp1_awvalid  : in std_logic;
	m_axi_gp1_awready  : out std_logic;
	m_axi_gp1_wid      : in std_logic_vector(11 downto 0);
	m_axi_gp1_wdata    : in std_logic_vector(31 downto 0);
	m_axi_gp1_wstrb    : in std_logic_vector(3 downto 0);
	m_axi_gp1_wlast    : in std_logic;
	m_axi_gp1_wvalid   : in std_logic;
	m_axi_gp1_wready   : out std_logic;
	m_axi_gp1_bid      : out std_logic_vector(11 downto 0);
	m_axi_gp1_bresp    : out std_logic_vector(1 downto 0);
	m_axi_gp1_bvalid   : out std_logic;
	m_axi_gp1_bready   : in std_logic;
	m_axi_gp1_arid     : in std_logic_vector(11 downto 0);
	m_axi_gp1_araddr   : in std_logic_vector(31 downto 0);
	m_axi_gp1_arlen    : in std_logic_vector(7 downto 0);
	m_axi_gp1_arsize   : in std_logic_vector(2 downto 0);
	m_axi_gp1_arburst  : in std_logic_vector(1 downto 0);
	m_axi_gp1_arlock   : in std_logic_vector(1 downto 0) := (others=>'0');
	m_axi_gp1_arcache  : in std_logic_vector(3 downto 0);
	m_axi_gp1_arprot   : in std_logic_vector(2 downto 0);
	m_axi_gp1_arqos    : in std_logic_vector(3 downto 0);
	m_axi_gp1_arvalid  : in std_logic;
	m_axi_gp1_arready  : out std_logic;
	m_axi_gp1_rid      : out std_logic_vector(11 downto 0);
	m_axi_gp1_rdata    : out std_logic_vector(31 downto 0);
	m_axi_gp1_rresp    : out std_logic_vector(1 downto 0);
	m_axi_gp1_rlast    : out std_logic;
	m_axi_gp1_rvalid   : out std_logic;
	m_axi_gp1_rready   : in std_logic;
	dio0_p             : inout std_logic;
	dio0_n             : inout std_logic;
	dio0_p_1           : inout std_logic;
	dio0_n_1           : inout std_logic;
	dio0_p_2           : inout std_logic;
	dio0_n_2           : inout std_logic;
	dio0_p_3           : inout std_logic;
	dio0_n_3           : inout std_logic;
	dio0_p_4           : inout std_logic;
	dio0_n_4           : inout std_logic;
	dio0_p_5           : inout std_logic;
	dio0_n_5           : inout std_logic;
	dio0_p_6           : inout std_logic;
	dio0_n_6           : inout std_logic;
	dio0_p_7           : inout std_logic;
	dio0_n_7           : inout std_logic;
	pulsar5_spi_p_clk  : out std_logic;
	pulsar5_spi_p_mosi : inout std_logic;
	pulsar5_spi_p_miso : inout std_logic;
	pulsar5_spi_p_cs_n : out std_logic_vector(3 downto 0);
	pulsar5_spi_n_clk  : out std_logic;
	pulsar5_spi_n_mosi : inout std_logic;
	pulsar5_spi_n_miso : inout std_logic;
	pulsar5_spi_n_cs_n : out std_logic_vector(3 downto 0);
	rtio_clk           : in std_logic;
	rtio_rst           : in std_logic;
	rtiox4_clk         : in std_logic;
	rtiox4_rst         : in std_logic;
	sys_clk            : in std_logic;
	sys_rst            : in std_logic
);
end component;

component kasli_ref_design is
  port (
    DDR_addr           : inout STD_LOGIC_VECTOR ( 14 downto 0 );
    DDR_ba             : inout STD_LOGIC_VECTOR ( 2 downto 0 );
    DDR_cas_n          : inout STD_LOGIC;
    DDR_ck_n           : inout STD_LOGIC;
    DDR_ck_p           : inout STD_LOGIC;
    DDR_cke            : inout STD_LOGIC;
    DDR_cs_n           : inout STD_LOGIC;
    DDR_dm             : inout STD_LOGIC_VECTOR ( 3 downto 0 );
    DDR_dq             : inout STD_LOGIC_VECTOR ( 31 downto 0 );
    DDR_dqs_n          : inout STD_LOGIC_VECTOR ( 3 downto 0 );
    DDR_dqs_p          : inout STD_LOGIC_VECTOR ( 3 downto 0 );
    DDR_odt            : inout STD_LOGIC;
    DDR_ras_n          : inout STD_LOGIC;
    DDR_reset_n        : inout STD_LOGIC;
    DDR_we_n           : inout STD_LOGIC;
    FIXED_IO_ddr_vrn   : inout STD_LOGIC;
    FIXED_IO_ddr_vrp   : inout STD_LOGIC;
    FIXED_IO_mio       : inout STD_LOGIC_VECTOR ( 53 downto 0 );
    FIXED_IO_ps_clk    : inout STD_LOGIC;
    FIXED_IO_ps_porb   : inout STD_LOGIC;
    FIXED_IO_ps_srstb  : inout STD_LOGIC;
    RTIO_AXI_aclk      : out STD_LOGIC;
    RTIO_AXI_araddr    : out STD_LOGIC_VECTOR ( 31 downto 0 );
    RTIO_AXI_arburst   : out STD_LOGIC_VECTOR ( 1 downto 0 );
    RTIO_AXI_arcache   : out STD_LOGIC_VECTOR ( 3 downto 0 );
    RTIO_AXI_arid      : out STD_LOGIC_VECTOR ( 11 downto 0 );
    RTIO_AXI_arlen     : out STD_LOGIC_VECTOR ( 7 downto 0 );
    RTIO_AXI_arlock    : out STD_LOGIC_VECTOR ( 0 to 0 );
    RTIO_AXI_arprot    : out STD_LOGIC_VECTOR ( 2 downto 0 );
    RTIO_AXI_arqos     : out STD_LOGIC_VECTOR ( 3 downto 0 );
    RTIO_AXI_arready   : in STD_LOGIC_VECTOR ( 0 to 0 );
    RTIO_AXI_arregion  : out STD_LOGIC_VECTOR ( 3 downto 0 );
    RTIO_AXI_arsize    : out STD_LOGIC_VECTOR ( 2 downto 0 );
    RTIO_AXI_arvalid   : out STD_LOGIC_VECTOR ( 0 to 0 );
    RTIO_AXI_awaddr    : out STD_LOGIC_VECTOR ( 31 downto 0 );
    RTIO_AXI_awburst   : out STD_LOGIC_VECTOR ( 1 downto 0 );
    RTIO_AXI_awcache   : out STD_LOGIC_VECTOR ( 3 downto 0 );
    RTIO_AXI_awid      : out STD_LOGIC_VECTOR ( 11 downto 0 );
    RTIO_AXI_awlen     : out STD_LOGIC_VECTOR ( 7 downto 0 );
    RTIO_AXI_awlock    : out STD_LOGIC_VECTOR ( 0 to 0 );
    RTIO_AXI_awprot    : out STD_LOGIC_VECTOR ( 2 downto 0 );
    RTIO_AXI_awqos     : out STD_LOGIC_VECTOR ( 3 downto 0 );
    RTIO_AXI_awready   : in STD_LOGIC_VECTOR ( 0 to 0 );
    RTIO_AXI_awregion  : out STD_LOGIC_VECTOR ( 3 downto 0 );
    RTIO_AXI_awsize    : out STD_LOGIC_VECTOR ( 2 downto 0 );
    RTIO_AXI_awvalid   : out STD_LOGIC_VECTOR ( 0 to 0 );
    RTIO_AXI_bid       : in STD_LOGIC_VECTOR ( 11 downto 0 );
    RTIO_AXI_bready    : out STD_LOGIC_VECTOR ( 0 to 0 );
    RTIO_AXI_bresp     : in STD_LOGIC_VECTOR ( 1 downto 0 );
    RTIO_AXI_bvalid    : in STD_LOGIC_VECTOR ( 0 to 0 );
    RTIO_AXI_rdata     : in STD_LOGIC_VECTOR ( 31 downto 0 );
    RTIO_AXI_resetn    : out STD_LOGIC_VECTOR ( 0 to 0 );
    RTIO_AXI_rid       : in STD_LOGIC_VECTOR ( 11 downto 0 );
    RTIO_AXI_rlast     : in STD_LOGIC_VECTOR ( 0 to 0 );
    RTIO_AXI_rready    : out STD_LOGIC_VECTOR ( 0 to 0 );
    RTIO_AXI_rresp     : in STD_LOGIC_VECTOR ( 1 downto 0 );
    RTIO_AXI_rvalid    : in STD_LOGIC_VECTOR ( 0 to 0 );
    RTIO_AXI_wdata     : out STD_LOGIC_VECTOR ( 31 downto 0 );
    RTIO_AXI_wlast     : out STD_LOGIC_VECTOR ( 0 to 0 );
    RTIO_AXI_wready    : in STD_LOGIC_VECTOR ( 0 to 0 );
    RTIO_AXI_wstrb     : out STD_LOGIC_VECTOR ( 3 downto 0 );
    RTIO_AXI_wvalid    : out STD_LOGIC_VECTOR ( 0 to 0 );
    S_AXI_HP0_ACLK     : in STD_LOGIC;
    S_AXI_HP0_araddr   : in STD_LOGIC_VECTOR ( 31 downto 0 );
    S_AXI_HP0_arburst  : in STD_LOGIC_VECTOR ( 1 downto 0 );
    S_AXI_HP0_arcache  : in STD_LOGIC_VECTOR ( 3 downto 0 );
    S_AXI_HP0_arid     : in STD_LOGIC_VECTOR ( 5 downto 0 );
    S_AXI_HP0_arlen    : in STD_LOGIC_VECTOR ( 3 downto 0 );
    S_AXI_HP0_arlock   : in STD_LOGIC_VECTOR ( 1 downto 0 );
    S_AXI_HP0_arprot   : in STD_LOGIC_VECTOR ( 2 downto 0 );
    S_AXI_HP0_arqos    : in STD_LOGIC_VECTOR ( 3 downto 0 );
    S_AXI_HP0_arready  : out STD_LOGIC;
    S_AXI_HP0_arsize   : in STD_LOGIC_VECTOR ( 2 downto 0 );
    S_AXI_HP0_arvalid  : in STD_LOGIC;
    S_AXI_HP0_awaddr   : in STD_LOGIC_VECTOR ( 31 downto 0 );
    S_AXI_HP0_awburst  : in STD_LOGIC_VECTOR ( 1 downto 0 );
    S_AXI_HP0_awcache  : in STD_LOGIC_VECTOR ( 3 downto 0 );
    S_AXI_HP0_awid     : in STD_LOGIC_VECTOR ( 5 downto 0 );
    S_AXI_HP0_awlen    : in STD_LOGIC_VECTOR ( 3 downto 0 );
    S_AXI_HP0_awlock   : in STD_LOGIC_VECTOR ( 1 downto 0 );
    S_AXI_HP0_awprot   : in STD_LOGIC_VECTOR ( 2 downto 0 );
    S_AXI_HP0_awqos    : in STD_LOGIC_VECTOR ( 3 downto 0 );
    S_AXI_HP0_awready  : out STD_LOGIC;
    S_AXI_HP0_awsize   : in STD_LOGIC_VECTOR ( 2 downto 0 );
    S_AXI_HP0_awvalid  : in STD_LOGIC;
    S_AXI_HP0_bid      : out STD_LOGIC_VECTOR ( 5 downto 0 );
    S_AXI_HP0_bready   : in STD_LOGIC;
    S_AXI_HP0_bresp    : out STD_LOGIC_VECTOR ( 1 downto 0 );
    S_AXI_HP0_bvalid   : out STD_LOGIC;
    S_AXI_HP0_rdata    : out STD_LOGIC_VECTOR ( 63 downto 0 );
    S_AXI_HP0_rid      : out STD_LOGIC_VECTOR ( 5 downto 0 );
    S_AXI_HP0_rlast    : out STD_LOGIC;
    S_AXI_HP0_rready   : in STD_LOGIC;
    S_AXI_HP0_rresp    : out STD_LOGIC_VECTOR ( 1 downto 0 );
    S_AXI_HP0_rvalid   : out STD_LOGIC;
    S_AXI_HP0_wdata    : in STD_LOGIC_VECTOR ( 63 downto 0 );
    S_AXI_HP0_wid      : in STD_LOGIC_VECTOR ( 5 downto 0 );
    S_AXI_HP0_wlast    : in STD_LOGIC;
    S_AXI_HP0_wready   : out STD_LOGIC;
    S_AXI_HP0_wstrb    : in STD_LOGIC_VECTOR ( 7 downto 0 );
    S_AXI_HP0_wvalid   : in STD_LOGIC;
    S_AXI_HP1_ACLK     : in STD_LOGIC;
    S_AXI_HP1_araddr   : in STD_LOGIC_VECTOR ( 31 downto 0 );
    S_AXI_HP1_arburst  : in STD_LOGIC_VECTOR ( 1 downto 0 );
    S_AXI_HP1_arcache  : in STD_LOGIC_VECTOR ( 3 downto 0 );
    S_AXI_HP1_arid     : in STD_LOGIC_VECTOR ( 5 downto 0 );
    S_AXI_HP1_arlen    : in STD_LOGIC_VECTOR ( 3 downto 0 );
    S_AXI_HP1_arlock   : in STD_LOGIC_VECTOR ( 1 downto 0 );
    S_AXI_HP1_arprot   : in STD_LOGIC_VECTOR ( 2 downto 0 );
    S_AXI_HP1_arqos    : in STD_LOGIC_VECTOR ( 3 downto 0 );
    S_AXI_HP1_arready  : out STD_LOGIC;
    S_AXI_HP1_arsize   : in STD_LOGIC_VECTOR ( 2 downto 0 );
    S_AXI_HP1_arvalid  : in STD_LOGIC;
    S_AXI_HP1_awaddr   : in STD_LOGIC_VECTOR ( 31 downto 0 );
    S_AXI_HP1_awburst  : in STD_LOGIC_VECTOR ( 1 downto 0 );
    S_AXI_HP1_awcache  : in STD_LOGIC_VECTOR ( 3 downto 0 );
    S_AXI_HP1_awid     : in STD_LOGIC_VECTOR ( 5 downto 0 );
    S_AXI_HP1_awlen    : in STD_LOGIC_VECTOR ( 3 downto 0 );
    S_AXI_HP1_awlock   : in STD_LOGIC_VECTOR ( 1 downto 0 );
    S_AXI_HP1_awprot   : in STD_LOGIC_VECTOR ( 2 downto 0 );
    S_AXI_HP1_awqos    : in STD_LOGIC_VECTOR ( 3 downto 0 );
    S_AXI_HP1_awready  : out STD_LOGIC;
    S_AXI_HP1_awsize   : in STD_LOGIC_VECTOR ( 2 downto 0 );
    S_AXI_HP1_awvalid  : in STD_LOGIC;
    S_AXI_HP1_bid      : out STD_LOGIC_VECTOR ( 5 downto 0 );
    S_AXI_HP1_bready   : in STD_LOGIC;
    S_AXI_HP1_bresp    : out STD_LOGIC_VECTOR ( 1 downto 0 );
    S_AXI_HP1_bvalid   : out STD_LOGIC;
    S_AXI_HP1_rdata    : out STD_LOGIC_VECTOR ( 63 downto 0 );
    S_AXI_HP1_rid      : out STD_LOGIC_VECTOR ( 5 downto 0 );
    S_AXI_HP1_rlast    : out STD_LOGIC;
    S_AXI_HP1_rready   : in STD_LOGIC;
    S_AXI_HP1_rresp    : out STD_LOGIC_VECTOR ( 1 downto 0 );
    S_AXI_HP1_rvalid   : out STD_LOGIC;
    S_AXI_HP1_wdata    : in STD_LOGIC_VECTOR ( 63 downto 0 );
    S_AXI_HP1_wid      : in STD_LOGIC_VECTOR ( 5 downto 0 );
    S_AXI_HP1_wlast    : in STD_LOGIC;
    S_AXI_HP1_wready   : out STD_LOGIC;
    S_AXI_HP1_wstrb    : in STD_LOGIC_VECTOR ( 7 downto 0 );
    S_AXI_HP1_wvalid   : in STD_LOGIC;
    UART_0_rxd         : in STD_LOGIC;
    UART_0_txd         : out STD_LOGIC;
    ZYNQ7_GMII_col     : in STD_LOGIC;
    ZYNQ7_GMII_crs     : in STD_LOGIC;
    ZYNQ7_GMII_rx_clk  : in STD_LOGIC;
    ZYNQ7_GMII_rx_dv   : in STD_LOGIC;
    ZYNQ7_GMII_rx_er   : in STD_LOGIC;
    ZYNQ7_GMII_rxd     : in STD_LOGIC_VECTOR ( 7 downto 0 );
    ZYNQ7_GMII_tx_clk  : in STD_LOGIC;
    ZYNQ7_GMII_tx_en   : out STD_LOGIC_VECTOR ( 0 to 0 );
    ZYNQ7_GMII_tx_er   : out STD_LOGIC_VECTOR ( 0 to 0 );
    ZYNQ7_GMII_txd     : out STD_LOGIC_VECTOR ( 7 downto 0 );
    wr_axi_araddr      : out STD_LOGIC_VECTOR ( 31 downto 0 );
    wr_axi_arburst     : out STD_LOGIC_VECTOR ( 1 downto 0 );
    wr_axi_arcache     : out STD_LOGIC_VECTOR ( 3 downto 0 );
    wr_axi_arid        : out STD_LOGIC_VECTOR ( 11 downto 0 );
    wr_axi_arlen       : out STD_LOGIC_VECTOR ( 3 downto 0 );
    wr_axi_arlock      : out STD_LOGIC_VECTOR ( 1 downto 0 );
    wr_axi_arprot      : out STD_LOGIC_VECTOR ( 2 downto 0 );
    wr_axi_arqos       : out STD_LOGIC_VECTOR ( 3 downto 0 );
    wr_axi_arready     : in STD_LOGIC;
    wr_axi_arsize      : out STD_LOGIC_VECTOR ( 2 downto 0 );
    wr_axi_arvalid     : out STD_LOGIC;
    wr_axi_awaddr      : out STD_LOGIC_VECTOR ( 31 downto 0 );
    wr_axi_awburst     : out STD_LOGIC_VECTOR ( 1 downto 0 );
    wr_axi_awcache     : out STD_LOGIC_VECTOR ( 3 downto 0 );
    wr_axi_awid        : out STD_LOGIC_VECTOR ( 11 downto 0 );
    wr_axi_awlen       : out STD_LOGIC_VECTOR ( 3 downto 0 );
    wr_axi_awlock      : out STD_LOGIC_VECTOR ( 1 downto 0 );
    wr_axi_awprot      : out STD_LOGIC_VECTOR ( 2 downto 0 );
    wr_axi_awqos       : out STD_LOGIC_VECTOR ( 3 downto 0 );
    wr_axi_awready     : in STD_LOGIC;
    wr_axi_awsize      : out STD_LOGIC_VECTOR ( 2 downto 0 );
    wr_axi_awvalid     : out STD_LOGIC;
    wr_axi_bid         : in STD_LOGIC_VECTOR ( 11 downto 0 );
    wr_axi_bready      : out STD_LOGIC;
    wr_axi_bresp       : in STD_LOGIC_VECTOR ( 1 downto 0 );
    wr_axi_bvalid      : in STD_LOGIC;
    wr_axi_clk         : in STD_LOGIC;
    wr_axi_rdata       : in STD_LOGIC_VECTOR ( 31 downto 0 );
    wr_axi_resetn      : out STD_LOGIC_VECTOR ( 0 to 0 );
    wr_axi_rid         : in STD_LOGIC_VECTOR ( 11 downto 0 );
    wr_axi_rlast       : in STD_LOGIC;
    wr_axi_rready      : out STD_LOGIC;
    wr_axi_rresp       : in STD_LOGIC_VECTOR ( 1 downto 0 );
    wr_axi_rvalid      : in STD_LOGIC;
    wr_axi_wdata       : out STD_LOGIC_VECTOR ( 31 downto 0 );
    wr_axi_wid         : out STD_LOGIC_VECTOR ( 11 downto 0 );
    wr_axi_wlast       : out STD_LOGIC;
    wr_axi_wready      : in STD_LOGIC;
    wr_axi_wstrb       : out STD_LOGIC_VECTOR ( 3 downto 0 );
    wr_axi_wvalid      : out STD_LOGIC
  );
end component;

component wrc_board_kasli is
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
end component;

component wb_gmii is
port (
    clk_sys_i           : in std_logic;
    rst_sys_n_i         : in std_logic;

    wrf_snk_adr_i       : in  std_logic_vector(1 downto 0)  := "00";
    wrf_snk_dat_i       : in  std_logic_vector(15 downto 0) := x"0000";
    wrf_snk_sel_i       : in  std_logic_vector(1 downto 0)  := "00";
    wrf_snk_cyc_i       : in  std_logic                     := '0';
    wrf_snk_we_i        : in  std_logic                     := '0';
    wrf_snk_stb_i       : in  std_logic                     := '0';
    wrf_snk_ack_o       : out std_logic;
    wrf_snk_err_o       : out std_logic;
    wrf_snk_rty_o       : out std_logic;
    wrf_snk_stall_o     : out std_logic;

    wrf_src_adr_o       : out std_logic_vector(1 downto 0);
    wrf_src_dat_o       : out std_logic_vector(15 downto 0);
    wrf_src_sel_o       : out std_logic_vector(1 downto 0);
    wrf_src_cyc_o       : out std_logic;
    wrf_src_stb_o       : out std_logic;
    wrf_src_we_o        : out std_logic;
    wrf_src_ack_i       : in  std_logic := '1';
    wrf_src_err_i       : in  std_logic := '0';
    wrf_src_rty_i       : in  std_logic := '0';
    wrf_src_stall_i     : in  std_logic := '0';

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


signal PS_UART_0_rxd     : STD_LOGIC := '0';
signal PS_UART_0_txd     : STD_LOGIC := '0';

signal wr_axi_araddr  : STD_LOGIC_VECTOR (31 downto 0 ) := (others=>'0');
signal wr_axi_arburst : STD_LOGIC_VECTOR ( 1 downto 0 ) := (others=>'0');
signal wr_axi_arcache : STD_LOGIC_VECTOR ( 3 downto 0 ) := (others=>'0');
signal wr_axi_arid    : STD_LOGIC_VECTOR (11 downto 0 ) := (others=>'0');
signal wr_axi_arlen   : STD_LOGIC_VECTOR ( 3 downto 0 ) := (others=>'0');
signal wr_axi_arlock  : STD_LOGIC_VECTOR ( 1 downto 0 ) := (others=>'0');
signal wr_axi_arprot  : STD_LOGIC_VECTOR ( 2 downto 0 ) := (others=>'0');
signal wr_axi_arqos   : STD_LOGIC_VECTOR ( 3 downto 0 ) := (others=>'0');
signal wr_axi_arready : STD_LOGIC := '1';
signal wr_axi_arsize  :  STD_LOGIC_VECTOR ( 2 downto 0 ) := (others=>'0');
signal wr_axi_arvalid :  STD_LOGIC := '0';
signal wr_axi_awaddr  :  STD_LOGIC_VECTOR ( 31 downto 0 ) := (others=>'0');
signal wr_axi_awburst :  STD_LOGIC_VECTOR ( 1 downto 0 ) := (others=>'0');
signal wr_axi_awcache :  STD_LOGIC_VECTOR ( 3 downto 0 ) := (others=>'0');
signal wr_axi_awid    :  STD_LOGIC_VECTOR ( 11 downto 0 ) := (others=>'0');
signal wr_axi_awlen   :  STD_LOGIC_VECTOR ( 3 downto 0 ) := (others=>'0');
signal wr_axi_awlock  :  STD_LOGIC_VECTOR ( 1 downto 0 ) := (others=>'0');
signal wr_axi_awprot  :  STD_LOGIC_VECTOR ( 2 downto 0 ) := (others=>'0');
signal wr_axi_awqos   :  STD_LOGIC_VECTOR ( 3 downto 0 ) := (others=>'0');
signal wr_axi_awready : STD_LOGIC := '1';
signal wr_axi_awsize  :  STD_LOGIC_VECTOR ( 2 downto 0 ) := (others=>'0');
signal wr_axi_awvalid :  STD_LOGIC := '0';
signal wr_axi_bid     : STD_LOGIC_VECTOR ( 11 downto 0 ) := (others=>'0');
signal wr_axi_bready  :  STD_LOGIC := '1';
signal wr_axi_bresp   : STD_LOGIC_VECTOR ( 1 downto 0 ) := (others=>'0');
signal wr_axi_bvalid  : STD_LOGIC := '0';
signal wr_axi_clk     : STD_LOGIC := '0';
signal wr_axi_rdata   : STD_LOGIC_VECTOR ( 31 downto 0 ) := (others=>'0');
signal wr_axi_resetn  :  STD_LOGIC_VECTOR ( 0 to 0 ) := (others=>'0');
signal wr_axi_rid     : STD_LOGIC_VECTOR ( 11 downto 0 ) := (others=>'0');
signal wr_axi_rlast   : STD_LOGIC := '0';
signal wr_axi_rready  :  STD_LOGIC := '1';
signal wr_axi_rresp   : STD_LOGIC_VECTOR ( 1 downto 0 ) := (others=>'0');
signal wr_axi_rvalid  : STD_LOGIC := '0';
signal wr_axi_wdata   :  STD_LOGIC_VECTOR ( 31 downto 0 ) := (others=>'0');
signal wr_axi_wid     :  STD_LOGIC_VECTOR ( 11 downto 0 ) := (others=>'0');
signal wr_axi_wlast   :  STD_LOGIC := '0';
signal wr_axi_wready  : STD_LOGIC := '1';
signal wr_axi_wstrb   :  STD_LOGIC_VECTOR ( 3 downto 0 ) := (others=>'0');
signal wr_axi_wvalid  :  STD_LOGIC := '0';

signal RTIO_AXI_aclk      : STD_LOGIC := '0';
signal RTIO_AXI_araddr    : STD_LOGIC_VECTOR ( 31 downto 0 ) := (others=>'0');
signal RTIO_AXI_arburst   : STD_LOGIC_VECTOR ( 1 downto 0 ) := (others=>'0');
signal RTIO_AXI_arcache   : STD_LOGIC_VECTOR ( 3 downto 0 ) := (others=>'0');
signal RTIO_AXI_arid      : STD_LOGIC_VECTOR ( 11 downto 0 ) := (others=>'0');
signal RTIO_AXI_arlen     : STD_LOGIC_VECTOR ( 7 downto 0 ) := (others=>'0');
signal RTIO_AXI_arlock    : STD_LOGIC_VECTOR ( 1 to 0 ) := (others=>'0');
signal RTIO_AXI_arprot    : STD_LOGIC_VECTOR ( 2 downto 0 ) := (others=>'0');
signal RTIO_AXI_arqos     : STD_LOGIC_VECTOR ( 3 downto 0 ) := (others=>'0');
signal RTIO_AXI_arready   : STD_LOGIC_VECTOR ( 0 to 0 ) := (others=>'1');
signal RTIO_AXI_arregion  : STD_LOGIC_VECTOR ( 3 downto 0 ) := (others=>'0');
signal RTIO_AXI_arsize    : STD_LOGIC_VECTOR ( 2 downto 0 ) := (others=>'0');
signal RTIO_AXI_arvalid   : STD_LOGIC_VECTOR ( 0 to 0 ) := (others=>'0');
signal RTIO_AXI_awaddr    : STD_LOGIC_VECTOR ( 31 downto 0 ) := (others=>'0');
signal RTIO_AXI_awburst   : STD_LOGIC_VECTOR ( 1 downto 0 ) := (others=>'0');
signal RTIO_AXI_awcache   : STD_LOGIC_VECTOR ( 3 downto 0 ) := (others=>'0');
signal RTIO_AXI_awid      : STD_LOGIC_VECTOR ( 11 downto 0 ) := (others=>'0');
signal RTIO_AXI_awlen     : STD_LOGIC_VECTOR ( 7 downto 0 ) := (others=>'0');
signal RTIO_AXI_awlock    : STD_LOGIC_VECTOR ( 1 to 0 ) := (others=>'0');
signal RTIO_AXI_awprot    : STD_LOGIC_VECTOR ( 2 downto 0 ) := (others=>'0');
signal RTIO_AXI_awqos     : STD_LOGIC_VECTOR ( 3 downto 0 ) := (others=>'0');
signal RTIO_AXI_awready   : STD_LOGIC_VECTOR ( 0 to 0 ) := (others=>'1');
signal RTIO_AXI_awregion  : STD_LOGIC_VECTOR ( 3 downto 0 ) := (others=>'0');
signal RTIO_AXI_awsize    : STD_LOGIC_VECTOR ( 2 downto 0 ) := (others=>'0');
signal RTIO_AXI_awvalid   : STD_LOGIC_VECTOR ( 0 to 0 ) := (others=>'0');
signal RTIO_AXI_bid       : STD_LOGIC_VECTOR ( 11 downto 0 ) := (others=>'0');
signal RTIO_AXI_bready    : STD_LOGIC_VECTOR ( 0 to 0 ) := (others=>'1');
signal RTIO_AXI_bresp     : STD_LOGIC_VECTOR ( 1 downto 0 ) := (others=>'0');
signal RTIO_AXI_bvalid    : STD_LOGIC_VECTOR ( 0 to 0 ) := (others=>'0');
signal RTIO_AXI_rdata     : STD_LOGIC_VECTOR ( 31 downto 0 ) := (others=>'0');
signal RTIO_AXI_resetn    : STD_LOGIC_VECTOR ( 0 to 0 ) := (others=>'0');
signal RTIO_AXI_rid       : STD_LOGIC_VECTOR ( 11 downto 0 ) := (others=>'0');
signal RTIO_AXI_rlast     : STD_LOGIC_VECTOR ( 0 to 0 ) := (others=>'0');
signal RTIO_AXI_rready    : STD_LOGIC_VECTOR ( 0 to 0 ) := (others=>'1');
signal RTIO_AXI_rresp     : STD_LOGIC_VECTOR ( 1 downto 0 ) := (others=>'0');
signal RTIO_AXI_rvalid    : STD_LOGIC_VECTOR ( 0 to 0 ) := (others=>'0');
signal RTIO_AXI_wid       : STD_LOGIC_VECTOR (11 downto 0 ) := (others=>'0');
signal RTIO_AXI_wdata     : STD_LOGIC_VECTOR ( 31 downto 0 ) := (others=>'0');
signal RTIO_AXI_wlast     : STD_LOGIC_VECTOR ( 0 to 0 ) := (others=>'0');
signal RTIO_AXI_wready    : STD_LOGIC_VECTOR ( 0 to 0 ) := (others=>'1');
signal RTIO_AXI_wstrb     : STD_LOGIC_VECTOR ( 3 downto 0 ) := (others=>'0');
signal RTIO_AXI_wvalid    : STD_LOGIC_VECTOR ( 0 to 0 ) := (others=>'0');

signal RTIO_AXI1_araddr    : STD_LOGIC_VECTOR ( 31 downto 0 ) := (others=>'0');
signal RTIO_AXI1_arburst   : STD_LOGIC_VECTOR ( 1 downto 0 ) := (others=>'0');
signal RTIO_AXI1_arcache   : STD_LOGIC_VECTOR ( 3 downto 0 ) := (others=>'0');
signal RTIO_AXI1_arid      : STD_LOGIC_VECTOR ( 11 downto 0 ) := (others=>'0');
signal RTIO_AXI1_arlen     : STD_LOGIC_VECTOR ( 7 downto 0 ) := (others=>'0');
signal RTIO_AXI1_arlock    : STD_LOGIC_VECTOR ( 1 to 0 ) := (others=>'0');
signal RTIO_AXI1_arprot    : STD_LOGIC_VECTOR ( 2 downto 0 ) := (others=>'0');
signal RTIO_AXI1_arqos     : STD_LOGIC_VECTOR ( 3 downto 0 ) := (others=>'0');
signal RTIO_AXI1_arready   : STD_LOGIC_VECTOR ( 0 to 0 ) := (others=>'1');
signal RTIO_AXI1_arregion  : STD_LOGIC_VECTOR ( 3 downto 0 ) := (others=>'0');
signal RTIO_AXI1_arsize    : STD_LOGIC_VECTOR ( 2 downto 0 ) := (others=>'0');
signal RTIO_AXI1_arvalid   : STD_LOGIC_VECTOR ( 0 to 0 ) := (others=>'0');
signal RTIO_AXI1_awaddr    : STD_LOGIC_VECTOR ( 31 downto 0 ) := (others=>'0');
signal RTIO_AXI1_awburst   : STD_LOGIC_VECTOR ( 1 downto 0 ) := (others=>'0');
signal RTIO_AXI1_awcache   : STD_LOGIC_VECTOR ( 3 downto 0 ) := (others=>'0');
signal RTIO_AXI1_awid      : STD_LOGIC_VECTOR ( 11 downto 0 ) := (others=>'0');
signal RTIO_AXI1_awlen     : STD_LOGIC_VECTOR ( 7 downto 0 ) := (others=>'0');
signal RTIO_AXI1_awlock    : STD_LOGIC_VECTOR ( 1 to 0 ) := (others=>'0');
signal RTIO_AXI1_awprot    : STD_LOGIC_VECTOR ( 2 downto 0 ) := (others=>'0');
signal RTIO_AXI1_awqos     : STD_LOGIC_VECTOR ( 3 downto 0 ) := (others=>'0');
signal RTIO_AXI1_awready   : STD_LOGIC_VECTOR ( 0 to 0 ) := (others=>'1');
signal RTIO_AXI1_awregion  : STD_LOGIC_VECTOR ( 3 downto 0 ) := (others=>'0');
signal RTIO_AXI1_awsize    : STD_LOGIC_VECTOR ( 2 downto 0 ) := (others=>'0');
signal RTIO_AXI1_awvalid   : STD_LOGIC_VECTOR ( 0 to 0 ) := (others=>'0');
signal RTIO_AXI1_bid       : STD_LOGIC_VECTOR ( 11 downto 0 ) := (others=>'0');
signal RTIO_AXI1_bready    : STD_LOGIC_VECTOR ( 0 to 0 ) := (others=>'1');
signal RTIO_AXI1_bresp     : STD_LOGIC_VECTOR ( 1 downto 0 ) := (others=>'0');
signal RTIO_AXI1_bvalid    : STD_LOGIC_VECTOR ( 0 to 0 ) := (others=>'0');
signal RTIO_AXI1_rdata     : STD_LOGIC_VECTOR ( 31 downto 0 ) := (others=>'0');
signal RTIO_AXI1_resetn    : STD_LOGIC_VECTOR ( 0 to 0 ) := (others=>'0');
signal RTIO_AXI1_rid       : STD_LOGIC_VECTOR ( 11 downto 0 ) := (others=>'0');
signal RTIO_AXI1_rlast     : STD_LOGIC_VECTOR ( 0 to 0 ) := (others=>'0');
signal RTIO_AXI1_rready    : STD_LOGIC_VECTOR ( 0 to 0 ) := (others=>'1');
signal RTIO_AXI1_rresp     : STD_LOGIC_VECTOR ( 1 downto 0 ) := (others=>'0');
signal RTIO_AXI1_rvalid    : STD_LOGIC_VECTOR ( 0 to 0 ) := (others=>'0');
signal RTIO_AXI1_wid       : STD_LOGIC_VECTOR (11 downto 0 ) := (others=>'0');
signal RTIO_AXI1_wdata     : STD_LOGIC_VECTOR ( 31 downto 0 ) := (others=>'0');
signal RTIO_AXI1_wlast     : STD_LOGIC_VECTOR ( 0 to 0 ) := (others=>'0');
signal RTIO_AXI1_wready    : STD_LOGIC_VECTOR ( 0 to 0 ) := (others=>'1');
signal RTIO_AXI1_wstrb     : STD_LOGIC_VECTOR ( 3 downto 0 ) := (others=>'0');
signal RTIO_AXI1_wvalid    : STD_LOGIC_VECTOR ( 0 to 0 ) := (others=>'0');

signal S_AXI_HP0_ACLK     : STD_LOGIC := '0';
signal S_AXI_HP0_araddr   : STD_LOGIC_VECTOR ( 31 downto 0 ) := (others=>'0');
signal S_AXI_HP0_arburst  : STD_LOGIC_VECTOR ( 1 downto 0 ) := (others=>'0');
signal S_AXI_HP0_arcache  : STD_LOGIC_VECTOR ( 3 downto 0 ) := (others=>'0');
signal S_AXI_HP0_arid     : STD_LOGIC_VECTOR ( 5 downto 0 ) := (others=>'0');
signal S_AXI_HP0_arlen    : STD_LOGIC_VECTOR ( 3 downto 0 ) := (others=>'0');
signal S_AXI_HP0_arlock   : STD_LOGIC_VECTOR ( 1 downto 0 ) := (others=>'0');
signal S_AXI_HP0_arprot   : STD_LOGIC_VECTOR ( 2 downto 0 ) := (others=>'0');
signal S_AXI_HP0_arqos    : STD_LOGIC_VECTOR ( 3 downto 0 ) := (others=>'0');
signal S_AXI_HP0_arready  : STD_LOGIC := '1';
signal S_AXI_HP0_arsize   : STD_LOGIC_VECTOR ( 2 downto 0 ) := (others=>'0');
signal S_AXI_HP0_arvalid  : STD_LOGIC := '0';
signal S_AXI_HP0_awaddr   : STD_LOGIC_VECTOR ( 31 downto 0 ) := (others=>'0');
signal S_AXI_HP0_awburst  : STD_LOGIC_VECTOR ( 1 downto 0 ) := (others=>'0');
signal S_AXI_HP0_awcache  : STD_LOGIC_VECTOR ( 3 downto 0 ) := (others=>'0');
signal S_AXI_HP0_awid     : STD_LOGIC_VECTOR ( 5 downto 0 ) := (others=>'0');
signal S_AXI_HP0_awlen    : STD_LOGIC_VECTOR ( 3 downto 0 ) := (others=>'0');
signal S_AXI_HP0_awlock   : STD_LOGIC_VECTOR ( 1 downto 0 ) := (others=>'0');
signal S_AXI_HP0_awprot   : STD_LOGIC_VECTOR ( 2 downto 0 ) := (others=>'0');
signal S_AXI_HP0_awqos    : STD_LOGIC_VECTOR ( 3 downto 0 ) := (others=>'0');
signal S_AXI_HP0_awready  : STD_LOGIC := '1';
signal S_AXI_HP0_awsize   : STD_LOGIC_VECTOR ( 2 downto 0 ) := (others=>'0');
signal S_AXI_HP0_awvalid  : STD_LOGIC := '0';
signal S_AXI_HP0_bid      : STD_LOGIC_VECTOR ( 5 downto 0 ) := (others=>'0');
signal S_AXI_HP0_bready   : STD_LOGIC := '1';
signal S_AXI_HP0_bresp    : STD_LOGIC_VECTOR ( 1 downto 0 ) := (others=>'0');
signal S_AXI_HP0_bvalid   : STD_LOGIC := '0';
signal S_AXI_HP0_rdata    : STD_LOGIC_VECTOR ( 63 downto 0 ) := (others=>'0');
signal S_AXI_HP0_rid      : STD_LOGIC_VECTOR ( 5 downto 0 ) := (others=>'0');
signal S_AXI_HP0_rlast    : STD_LOGIC := '0';
signal S_AXI_HP0_rready   : STD_LOGIC := '1';
signal S_AXI_HP0_rresp    : STD_LOGIC_VECTOR ( 1 downto 0 ) := (others=>'0');
signal S_AXI_HP0_rvalid   : STD_LOGIC := '0';
signal S_AXI_HP0_wdata    : STD_LOGIC_VECTOR ( 63 downto 0 ) := (others=>'0');
signal S_AXI_HP0_wid      : STD_LOGIC_VECTOR ( 5 downto 0 ) := (others=>'0');
signal S_AXI_HP0_wlast    : STD_LOGIC := '0';
signal S_AXI_HP0_wready   : STD_LOGIC := '1';
signal S_AXI_HP0_wstrb    : STD_LOGIC_VECTOR ( 7 downto 0 ) := (others=>'0');
signal S_AXI_HP0_wvalid   : STD_LOGIC := '0';
signal S_AXI_HP1_ACLK     : STD_LOGIC := '0';
signal S_AXI_HP1_araddr   : STD_LOGIC_VECTOR ( 31 downto 0 ) := (others=>'0');
signal S_AXI_HP1_arburst  : STD_LOGIC_VECTOR ( 1 downto 0 ) := (others=>'0');
signal S_AXI_HP1_arcache  : STD_LOGIC_VECTOR ( 3 downto 0 ) := (others=>'0');
signal S_AXI_HP1_arid     : STD_LOGIC_VECTOR ( 5 downto 0 ) := (others=>'0');
signal S_AXI_HP1_arlen    : STD_LOGIC_VECTOR ( 3 downto 0 ) := (others=>'0');
signal S_AXI_HP1_arlock   : STD_LOGIC_VECTOR ( 1 downto 0 ) := (others=>'0');
signal S_AXI_HP1_arprot   : STD_LOGIC_VECTOR ( 2 downto 0 ) := (others=>'0');
signal S_AXI_HP1_arqos    : STD_LOGIC_VECTOR ( 3 downto 0 ) := (others=>'0');
signal S_AXI_HP1_arready  : STD_LOGIC := '1';
signal S_AXI_HP1_arsize   : STD_LOGIC_VECTOR ( 2 downto 0 ) := (others=>'0');
signal S_AXI_HP1_arvalid  : STD_LOGIC := '0';
signal S_AXI_HP1_awaddr   : STD_LOGIC_VECTOR ( 31 downto 0 ) := (others=>'0');
signal S_AXI_HP1_awburst  : STD_LOGIC_VECTOR ( 1 downto 0 ) := (others=>'0');
signal S_AXI_HP1_awcache  : STD_LOGIC_VECTOR ( 3 downto 0 ) := (others=>'0');
signal S_AXI_HP1_awid     : STD_LOGIC_VECTOR ( 5 downto 0 ) := (others=>'0');
signal S_AXI_HP1_awlen    : STD_LOGIC_VECTOR ( 3 downto 0 ) := (others=>'0');
signal S_AXI_HP1_awlock   : STD_LOGIC_VECTOR ( 1 downto 0 ) := (others=>'0');
signal S_AXI_HP1_awprot   : STD_LOGIC_VECTOR ( 2 downto 0 ) := (others=>'0');
signal S_AXI_HP1_awqos    : STD_LOGIC_VECTOR ( 3 downto 0 ) := (others=>'0');
signal S_AXI_HP1_awready  : STD_LOGIC := '1';
signal S_AXI_HP1_awsize   : STD_LOGIC_VECTOR ( 2 downto 0 ) := (others=>'0');
signal S_AXI_HP1_awvalid  : STD_LOGIC := '0';
signal S_AXI_HP1_bid      : STD_LOGIC_VECTOR ( 5 downto 0 ) := (others=>'0');
signal S_AXI_HP1_bready   : STD_LOGIC := '1';
signal S_AXI_HP1_bresp    : STD_LOGIC_VECTOR ( 1 downto 0 ) := (others=>'0');
signal S_AXI_HP1_bvalid   : STD_LOGIC := '0';
signal S_AXI_HP1_rdata    : STD_LOGIC_VECTOR ( 63 downto 0 ) := (others=>'0');
signal S_AXI_HP1_rid      : STD_LOGIC_VECTOR ( 5 downto 0 ) := (others=>'0');
signal S_AXI_HP1_rlast    : STD_LOGIC := '0';
signal S_AXI_HP1_rready   : STD_LOGIC := '1';
signal S_AXI_HP1_rresp    : STD_LOGIC_VECTOR ( 1 downto 0 ) := (others=>'0');
signal S_AXI_HP1_rvalid   : STD_LOGIC := '0';
signal S_AXI_HP1_wdata    : STD_LOGIC_VECTOR ( 63 downto 0 ) := (others=>'0');
signal S_AXI_HP1_wid      : STD_LOGIC_VECTOR ( 5 downto 0 ) := (others=>'0');
signal S_AXI_HP1_wlast    : STD_LOGIC := '0';
signal S_AXI_HP1_wready   : STD_LOGIC := '1';
signal S_AXI_HP1_wstrb    : STD_LOGIC_VECTOR ( 7 downto 0 ) := (others=>'0');
signal S_AXI_HP1_wvalid   : STD_LOGIC := '0';

signal ZYNQ7_GMII_col    : STD_LOGIC;
signal ZYNQ7_GMII_crs    : STD_LOGIC;
signal ZYNQ7_GMII_rx_clk : STD_LOGIC;
signal ZYNQ7_GMII_rx_dv  : STD_LOGIC;
signal ZYNQ7_GMII_rx_er  : STD_LOGIC;
signal ZYNQ7_GMII_rxd    : STD_LOGIC_VECTOR ( 7 downto 0 );
signal ZYNQ7_GMII_tx_clk : STD_LOGIC;
signal ZYNQ7_GMII_tx_en  : STD_LOGIC_VECTOR ( 0 to 0 );
signal ZYNQ7_GMII_tx_er  : STD_LOGIC_VECTOR ( 0 to 0 );
signal ZYNQ7_GMII_txd    : STD_LOGIC_VECTOR ( 7 downto 0 );


signal clk_ref_125m_o   :  STD_LOGIC_VECTOR(0 downto 0) := (others=>'0');
signal clk_sys_62m5_o   :  STD_LOGIC_VECTOR(0 downto 0) := (others=>'0');

signal eeprom_i2c_scl_i  :  STD_LOGIC := '0';
signal eeprom_i2c_scl_o  :  STD_LOGIC := '0';
signal eeprom_i2c_scl_t  :  STD_LOGIC := '0';
signal eeprom_i2c_sda_i  :  STD_LOGIC := '0';
signal eeprom_i2c_sda_o  :  STD_LOGIC := '0';
signal eeprom_i2c_sda_t  :  STD_LOGIC := '0';

signal pps_o             :  STD_LOGIC_VECTOR(0 downto 0) := (others=>'0');
signal sfp_i2c_scl_i     :  STD_LOGIC := '0';
signal sfp_i2c_scl_o     :  STD_LOGIC := '0';
signal sfp_i2c_scl_t     :  STD_LOGIC := '0';
signal sfp_i2c_sda_i     :  STD_LOGIC := '0';
signal sfp_i2c_sda_o     :  STD_LOGIC := '0';
signal sfp_i2c_sda_t     :  STD_LOGIC := '0';
signal thermo_id_tri_i   :  STD_LOGIC := '0';
signal thermo_id_tri_o   :  STD_LOGIC := '0';
signal thermo_id_tri_t   :  STD_LOGIC := '0';

    ---------------------------------------------------------------------------
    -- WR fabric interface (when g_fabric_iface = "plainfbrc")
    ---------------------------------------------------------------------------
signal wrf_src_o_adr : std_logic_vector(1 downto 0);
signal wrf_src_o_dat : std_logic_vector(15 downto 0);
signal wrf_src_o_cyc : std_logic;
signal wrf_src_o_stb : std_logic;
signal wrf_src_o_we  : std_logic;
signal wrf_src_o_sel : std_logic_vector(1 downto 0);

signal wrf_src_i_ack   : std_logic := '0';
signal wrf_src_i_stall : std_logic := '0';
signal wrf_src_i_err   : std_logic := '0';
signal wrf_src_i_rty   : std_logic := '0';

signal wrf_snk_o_ack   : std_logic := '0';
signal wrf_snk_o_stall : std_logic := '0';
signal wrf_snk_o_err   : std_logic := '0';
signal wrf_snk_o_rty   : std_logic := '0';

signal wrf_snk_i_adr : std_logic_vector(1 downto 0) := (others=>'0');
signal wrf_snk_i_dat : std_logic_vector(15 downto 0) := (others=>'0');
signal wrf_snk_i_cyc : std_logic := '0';
signal wrf_snk_i_stb : std_logic := '0';
signal wrf_snk_i_we  : std_logic := '0';
signal wrf_snk_i_sel : std_logic_vector(1 downto 0) := (others=>'0');

-- rtio core
signal rtio_clk           : std_logic := '0';
signal rtio_rst           : std_logic := '0';
signal rtiox4_clk         : std_logic := '0';
signal rtiox4_rst         : std_logic := '0';
signal sys_clk            : std_logic := '0';
signal sys_rst            : std_logic := '0';

begin

kasli_ref_design_i : kasli_ref_design
     port map (
      DDR_addr(14 downto 0) => DDR_addr(14 downto 0),
      DDR_ba(2 downto 0) => DDR_ba(2 downto 0),
      DDR_cas_n => DDR_cas_n,
      DDR_ck_n => DDR_ck_n,
      DDR_ck_p => DDR_ck_p,
      DDR_cke => DDR_cke,
      DDR_cs_n => DDR_cs_n,
      DDR_dm(3 downto 0) => DDR_dm(3 downto 0),
      DDR_dq(31 downto 0) => DDR_dq(31 downto 0),
      DDR_dqs_n(3 downto 0) => DDR_dqs_n(3 downto 0),
      DDR_dqs_p(3 downto 0) => DDR_dqs_p(3 downto 0),
      DDR_odt => DDR_odt,
      DDR_ras_n => DDR_ras_n,
      DDR_reset_n => DDR_reset_n,
      DDR_we_n => DDR_we_n,
      FIXED_IO_ddr_vrn => FIXED_IO_ddr_vrn,
      FIXED_IO_ddr_vrp => FIXED_IO_ddr_vrp,
      FIXED_IO_mio(53 downto 0) => FIXED_IO_mio(53 downto 0),
      FIXED_IO_ps_clk => FIXED_IO_ps_clk,
      FIXED_IO_ps_porb => FIXED_IO_ps_porb,
      FIXED_IO_ps_srstb => FIXED_IO_ps_srstb,
      RTIO_AXI_aclk => RTIO_AXI_aclk,
      RTIO_AXI_araddr(31 downto 0) => RTIO_AXI_araddr(31 downto 0),
      RTIO_AXI_arburst(1 downto 0) => RTIO_AXI_arburst(1 downto 0),
      RTIO_AXI_arcache(3 downto 0) => RTIO_AXI_arcache(3 downto 0),
      RTIO_AXI_arid(11 downto 0) => RTIO_AXI_arid(11 downto 0),
      RTIO_AXI_arlen(7 downto 0) => RTIO_AXI_arlen(7 downto 0),
      RTIO_AXI_arlock(0 downto 0) => RTIO_AXI_arlock(0 downto 0),
      RTIO_AXI_arprot(2 downto 0) => RTIO_AXI_arprot(2 downto 0),
      RTIO_AXI_arqos(3 downto 0) => RTIO_AXI_arqos(3 downto 0),
      RTIO_AXI_arready(0) => RTIO_AXI_arready(0),
      RTIO_AXI_arregion(3 downto 0) => RTIO_AXI_arregion(3 downto 0),
      RTIO_AXI_arsize(2 downto 0) => RTIO_AXI_arsize(2 downto 0),
      RTIO_AXI_arvalid(0) => RTIO_AXI_arvalid(0),
      RTIO_AXI_awaddr(31 downto 0) => RTIO_AXI_awaddr(31 downto 0),
      RTIO_AXI_awburst(1 downto 0) => RTIO_AXI_awburst(1 downto 0),
      RTIO_AXI_awcache(3 downto 0) => RTIO_AXI_awcache(3 downto 0),
      RTIO_AXI_awid(11 downto 0) => RTIO_AXI_awid(11 downto 0),
      RTIO_AXI_awlen(7 downto 0) => RTIO_AXI_awlen(7 downto 0),
      RTIO_AXI_awlock(0 downto 0) => RTIO_AXI_awlock(0 downto 0),
      RTIO_AXI_awprot(2 downto 0) => RTIO_AXI_awprot(2 downto 0),
      RTIO_AXI_awqos(3 downto 0) => RTIO_AXI_awqos(3 downto 0),
      RTIO_AXI_awready(0) => RTIO_AXI_awready(0),
      RTIO_AXI_awregion(3 downto 0) => RTIO_AXI_awregion(3 downto 0),
      RTIO_AXI_awsize(2 downto 0) => RTIO_AXI_awsize(2 downto 0),
      RTIO_AXI_awvalid(0) => RTIO_AXI_awvalid(0),
      RTIO_AXI_bid(11 downto 0) => RTIO_AXI_bid(11 downto 0),
      RTIO_AXI_bready(0) => RTIO_AXI_bready(0),
      RTIO_AXI_bresp(1 downto 0) => RTIO_AXI_bresp(1 downto 0),
      RTIO_AXI_bvalid(0) => RTIO_AXI_bvalid(0),
      RTIO_AXI_rdata(31 downto 0) => RTIO_AXI_rdata(31 downto 0),
      RTIO_AXI_resetn(0) => RTIO_AXI_resetn(0),
      RTIO_AXI_rid(11 downto 0) => RTIO_AXI_rid(11 downto 0),
      RTIO_AXI_rlast(0) => RTIO_AXI_rlast(0),
      RTIO_AXI_rready(0) => RTIO_AXI_rready(0),
      RTIO_AXI_rresp(1 downto 0) => RTIO_AXI_rresp(1 downto 0),
      RTIO_AXI_rvalid(0) => RTIO_AXI_rvalid(0),
      RTIO_AXI_wdata(31 downto 0) => RTIO_AXI_wdata(31 downto 0),
      RTIO_AXI_wlast(0) => RTIO_AXI_wlast(0),
      RTIO_AXI_wready(0) => RTIO_AXI_wready(0),
      RTIO_AXI_wstrb(3 downto 0) => RTIO_AXI_wstrb(3 downto 0),
      RTIO_AXI_wvalid(0) => RTIO_AXI_wvalid(0),
      S_AXI_HP0_ACLK => S_AXI_HP0_ACLK,
      S_AXI_HP0_araddr(31 downto 0) => S_AXI_HP0_araddr(31 downto 0),
      S_AXI_HP0_arburst(1 downto 0) => S_AXI_HP0_arburst(1 downto 0),
      S_AXI_HP0_arcache(3 downto 0) => S_AXI_HP0_arcache(3 downto 0),
      S_AXI_HP0_arid(5 downto 0) => S_AXI_HP0_arid(5 downto 0),
      S_AXI_HP0_arlen(3 downto 0) => S_AXI_HP0_arlen(3 downto 0),
      S_AXI_HP0_arlock(1 downto 0) => S_AXI_HP0_arlock(1 downto 0),
      S_AXI_HP0_arprot(2 downto 0) => S_AXI_HP0_arprot(2 downto 0),
      S_AXI_HP0_arqos(3 downto 0) => S_AXI_HP0_arqos(3 downto 0),
      S_AXI_HP0_arready => S_AXI_HP0_arready,
      S_AXI_HP0_arsize(2 downto 0) => S_AXI_HP0_arsize(2 downto 0),
      S_AXI_HP0_arvalid => S_AXI_HP0_arvalid,
      S_AXI_HP0_awaddr(31 downto 0) => S_AXI_HP0_awaddr(31 downto 0),
      S_AXI_HP0_awburst(1 downto 0) => S_AXI_HP0_awburst(1 downto 0),
      S_AXI_HP0_awcache(3 downto 0) => S_AXI_HP0_awcache(3 downto 0),
      S_AXI_HP0_awid(5 downto 0) => S_AXI_HP0_awid(5 downto 0),
      S_AXI_HP0_awlen(3 downto 0) => S_AXI_HP0_awlen(3 downto 0),
      S_AXI_HP0_awlock(1 downto 0) => S_AXI_HP0_awlock(1 downto 0),
      S_AXI_HP0_awprot(2 downto 0) => S_AXI_HP0_awprot(2 downto 0),
      S_AXI_HP0_awqos(3 downto 0) => S_AXI_HP0_awqos(3 downto 0),
      S_AXI_HP0_awready => S_AXI_HP0_awready,
      S_AXI_HP0_awsize(2 downto 0) => S_AXI_HP0_awsize(2 downto 0),
      S_AXI_HP0_awvalid => S_AXI_HP0_awvalid,
      S_AXI_HP0_bid(5 downto 0) => S_AXI_HP0_bid(5 downto 0),
      S_AXI_HP0_bready => S_AXI_HP0_bready,
      S_AXI_HP0_bresp(1 downto 0) => S_AXI_HP0_bresp(1 downto 0),
      S_AXI_HP0_bvalid => S_AXI_HP0_bvalid,
      S_AXI_HP0_rdata(63 downto 0) => S_AXI_HP0_rdata(63 downto 0),
      S_AXI_HP0_rid(5 downto 0) => S_AXI_HP0_rid(5 downto 0),
      S_AXI_HP0_rlast => S_AXI_HP0_rlast,
      S_AXI_HP0_rready => S_AXI_HP0_rready,
      S_AXI_HP0_rresp(1 downto 0) => S_AXI_HP0_rresp(1 downto 0),
      S_AXI_HP0_rvalid => S_AXI_HP0_rvalid,
      S_AXI_HP0_wdata(63 downto 0) => S_AXI_HP0_wdata(63 downto 0),
      S_AXI_HP0_wid(5 downto 0) => S_AXI_HP0_wid(5 downto 0),
      S_AXI_HP0_wlast => S_AXI_HP0_wlast,
      S_AXI_HP0_wready => S_AXI_HP0_wready,
      S_AXI_HP0_wstrb(7 downto 0) => S_AXI_HP0_wstrb(7 downto 0),
      S_AXI_HP0_wvalid => S_AXI_HP0_wvalid,
      S_AXI_HP1_ACLK => S_AXI_HP1_ACLK,
      S_AXI_HP1_araddr(31 downto 0) => S_AXI_HP1_araddr(31 downto 0),
      S_AXI_HP1_arburst(1 downto 0) => S_AXI_HP1_arburst(1 downto 0),
      S_AXI_HP1_arcache(3 downto 0) => S_AXI_HP1_arcache(3 downto 0),
      S_AXI_HP1_arid(5 downto 0) => S_AXI_HP1_arid(5 downto 0),
      S_AXI_HP1_arlen(3 downto 0) => S_AXI_HP1_arlen(3 downto 0),
      S_AXI_HP1_arlock(1 downto 0) => S_AXI_HP1_arlock(1 downto 0),
      S_AXI_HP1_arprot(2 downto 0) => S_AXI_HP1_arprot(2 downto 0),
      S_AXI_HP1_arqos(3 downto 0) => S_AXI_HP1_arqos(3 downto 0),
      S_AXI_HP1_arready => S_AXI_HP1_arready,
      S_AXI_HP1_arsize(2 downto 0) => S_AXI_HP1_arsize(2 downto 0),
      S_AXI_HP1_arvalid => S_AXI_HP1_arvalid,
      S_AXI_HP1_awaddr(31 downto 0) => S_AXI_HP1_awaddr(31 downto 0),
      S_AXI_HP1_awburst(1 downto 0) => S_AXI_HP1_awburst(1 downto 0),
      S_AXI_HP1_awcache(3 downto 0) => S_AXI_HP1_awcache(3 downto 0),
      S_AXI_HP1_awid(5 downto 0) => S_AXI_HP1_awid(5 downto 0),
      S_AXI_HP1_awlen(3 downto 0) => S_AXI_HP1_awlen(3 downto 0),
      S_AXI_HP1_awlock(1 downto 0) => S_AXI_HP1_awlock(1 downto 0),
      S_AXI_HP1_awprot(2 downto 0) => S_AXI_HP1_awprot(2 downto 0),
      S_AXI_HP1_awqos(3 downto 0) => S_AXI_HP1_awqos(3 downto 0),
      S_AXI_HP1_awready => S_AXI_HP1_awready,
      S_AXI_HP1_awsize(2 downto 0) => S_AXI_HP1_awsize(2 downto 0),
      S_AXI_HP1_awvalid => S_AXI_HP1_awvalid,
      S_AXI_HP1_bid(5 downto 0) => S_AXI_HP1_bid(5 downto 0),
      S_AXI_HP1_bready => S_AXI_HP1_bready,
      S_AXI_HP1_bresp(1 downto 0) => S_AXI_HP1_bresp(1 downto 0),
      S_AXI_HP1_bvalid => S_AXI_HP1_bvalid,
      S_AXI_HP1_rdata(63 downto 0) => S_AXI_HP1_rdata(63 downto 0),
      S_AXI_HP1_rid(5 downto 0) => S_AXI_HP1_rid(5 downto 0),
      S_AXI_HP1_rlast => S_AXI_HP1_rlast,
      S_AXI_HP1_rready => S_AXI_HP1_rready,
      S_AXI_HP1_rresp(1 downto 0) => S_AXI_HP1_rresp(1 downto 0),
      S_AXI_HP1_rvalid => S_AXI_HP1_rvalid,
      S_AXI_HP1_wdata(63 downto 0) => S_AXI_HP1_wdata(63 downto 0),
      S_AXI_HP1_wid(5 downto 0) => S_AXI_HP1_wid(5 downto 0),
      S_AXI_HP1_wlast => S_AXI_HP1_wlast,
      S_AXI_HP1_wready => S_AXI_HP1_wready,
      S_AXI_HP1_wstrb(7 downto 0) => S_AXI_HP1_wstrb(7 downto 0),
      S_AXI_HP1_wvalid => S_AXI_HP1_wvalid,
      UART_0_rxd => PS_UART_0_rxd,
      UART_0_txd => PS_UART_0_txd,
      ZYNQ7_GMII_col    => ZYNQ7_GMII_col   ,
      ZYNQ7_GMII_crs    => ZYNQ7_GMII_crs   ,
      ZYNQ7_GMII_rx_clk => ZYNQ7_GMII_rx_clk,
      ZYNQ7_GMII_rx_dv  => ZYNQ7_GMII_rx_dv ,
      ZYNQ7_GMII_rx_er  => ZYNQ7_GMII_rx_er ,
      ZYNQ7_GMII_rxd    => ZYNQ7_GMII_rxd   ,
      ZYNQ7_GMII_tx_clk => ZYNQ7_GMII_tx_clk,
      ZYNQ7_GMII_tx_en  => ZYNQ7_GMII_tx_en ,
      ZYNQ7_GMII_tx_er  => ZYNQ7_GMII_tx_er ,
      ZYNQ7_GMII_txd     => ZYNQ7_GMII_txd ,
      wr_axi_araddr(31 downto 0) => wr_axi_araddr(31 downto 0),
      wr_axi_arburst(1 downto 0) => wr_axi_arburst(1 downto 0),
      wr_axi_arcache(3 downto 0) => wr_axi_arcache(3 downto 0),
      wr_axi_arid(11 downto 0) => wr_axi_arid(11 downto 0),
      wr_axi_arlen(3 downto 0) => wr_axi_arlen(3 downto 0),
      wr_axi_arlock(1 downto 0) => wr_axi_arlock(1 downto 0),
      wr_axi_arprot(2 downto 0) => wr_axi_arprot(2 downto 0),
      wr_axi_arqos(3 downto 0) => wr_axi_arqos(3 downto 0),
      wr_axi_arready => wr_axi_arready,
      wr_axi_arsize(2 downto 0) => wr_axi_arsize(2 downto 0),
      wr_axi_arvalid => wr_axi_arvalid,
      wr_axi_awaddr(31 downto 0) => wr_axi_awaddr(31 downto 0),
      wr_axi_awburst(1 downto 0) => wr_axi_awburst(1 downto 0),
      wr_axi_awcache(3 downto 0) => wr_axi_awcache(3 downto 0),
      wr_axi_awid(11 downto 0) => wr_axi_awid(11 downto 0),
      wr_axi_awlen(3 downto 0) => wr_axi_awlen(3 downto 0),
      wr_axi_awlock(1 downto 0) => wr_axi_awlock(1 downto 0),
      wr_axi_awprot(2 downto 0) => wr_axi_awprot(2 downto 0),
      wr_axi_awqos(3 downto 0) => wr_axi_awqos(3 downto 0),
      wr_axi_awready => wr_axi_awready,
      wr_axi_awsize(2 downto 0) => wr_axi_awsize(2 downto 0),
      wr_axi_awvalid => wr_axi_awvalid,
      wr_axi_bid(11 downto 0) => wr_axi_bid(11 downto 0),
      wr_axi_bready => wr_axi_bready,
      wr_axi_bresp(1 downto 0) => wr_axi_bresp(1 downto 0),
      wr_axi_bvalid => wr_axi_bvalid,
      wr_axi_clk => wr_axi_clk,
      wr_axi_rdata(31 downto 0) => wr_axi_rdata(31 downto 0),
      wr_axi_resetn(0) => wr_axi_resetn(0),
      wr_axi_rid(11 downto 0) => wr_axi_rid(11 downto 0),
      wr_axi_rlast => wr_axi_rlast,
      wr_axi_rready => wr_axi_rready,
      wr_axi_rresp(1 downto 0) => wr_axi_rresp(1 downto 0),
      wr_axi_rvalid => wr_axi_rvalid,
      wr_axi_wdata(31 downto 0) => wr_axi_wdata(31 downto 0),
      wr_axi_wid(11 downto 0) => wr_axi_wid(11 downto 0),
      wr_axi_wlast => wr_axi_wlast,
      wr_axi_wready => wr_axi_wready,
      wr_axi_wstrb(3 downto 0) => wr_axi_wstrb(3 downto 0),
      wr_axi_wvalid => wr_axi_wvalid
    );

U_rtio_core : rtio_core
port map(
	m_axi_gp0_awid     => RTIO_AXI_awid   ,
	m_axi_gp0_awaddr   => RTIO_AXI_awaddr ,
	m_axi_gp0_awlen    => RTIO_AXI_awlen  ,
	m_axi_gp0_awsize   => RTIO_AXI_awsize ,
	m_axi_gp0_awburst  => RTIO_AXI_awburst,
--	m_axi_gp0_awlock   => RTIO_AXI_awlock ,
	m_axi_gp0_awcache  => RTIO_AXI_awcache,
	m_axi_gp0_awprot   => RTIO_AXI_awprot ,
	m_axi_gp0_awqos    => RTIO_AXI_awqos  ,
	m_axi_gp0_awvalid  => RTIO_AXI_awvalid(0),
	m_axi_gp0_awready  => RTIO_AXI_awready(0),
	m_axi_gp0_wid      => RTIO_AXI_wid    ,
	m_axi_gp0_wdata    => RTIO_AXI_wdata  ,
	m_axi_gp0_wstrb    => RTIO_AXI_wstrb  ,
	m_axi_gp0_wlast    => RTIO_AXI_wlast(0)  ,
	m_axi_gp0_wvalid   => RTIO_AXI_wvalid(0) ,
	m_axi_gp0_wready   => RTIO_AXI_wready(0) ,
	m_axi_gp0_bid      => RTIO_AXI_bid    ,
	m_axi_gp0_bresp    => RTIO_AXI_bresp  ,
	m_axi_gp0_bvalid   => RTIO_AXI_bvalid(0) ,
	m_axi_gp0_bready   => RTIO_AXI_bready(0) ,
	m_axi_gp0_arid     => RTIO_AXI_arid   ,
	m_axi_gp0_araddr   => RTIO_AXI_araddr ,
	m_axi_gp0_arlen    => RTIO_AXI_arlen  ,
	m_axi_gp0_arsize   => RTIO_AXI_arsize ,
	m_axi_gp0_arburst  => RTIO_AXI_arburst,
--	m_axi_gp0_arlock   => RTIO_AXI_arlock ,
	m_axi_gp0_arcache  => RTIO_AXI_arcache,
	m_axi_gp0_arprot   => RTIO_AXI_arprot ,
	m_axi_gp0_arqos    => RTIO_AXI_arqos  ,
	m_axi_gp0_arvalid  => RTIO_AXI_arvalid(0),
	m_axi_gp0_arready  => RTIO_AXI_arready(0),
	m_axi_gp0_rid      => RTIO_AXI_rid    ,
	m_axi_gp0_rdata    => RTIO_AXI_rdata  ,
	m_axi_gp0_rresp    => RTIO_AXI_rresp  ,
	m_axi_gp0_rlast    => RTIO_AXI_rlast(0)  ,
	m_axi_gp0_rvalid   => RTIO_AXI_rvalid(0) ,
	m_axi_gp0_rready   => RTIO_AXI_rready(0) ,
	m_axi_gp1_awid     => RTIO_AXI1_awid   ,
	m_axi_gp1_awaddr   => RTIO_AXI1_awaddr ,
	m_axi_gp1_awlen    => RTIO_AXI1_awlen  ,
	m_axi_gp1_awsize   => RTIO_AXI1_awsize ,
	m_axi_gp1_awburst  => RTIO_AXI1_awburst,
--	m_axi_gp1_awlock   => RTIO_AXI1_awlock ,
	m_axi_gp1_awcache  => RTIO_AXI1_awcache,
	m_axi_gp1_awprot   => RTIO_AXI1_awprot ,
	m_axi_gp1_awqos    => RTIO_AXI1_awqos  ,
	m_axi_gp1_awvalid  => RTIO_AXI1_awvalid(0),
	m_axi_gp1_awready  => RTIO_AXI1_awready(0),
	m_axi_gp1_wid      => RTIO_AXI1_wid    ,
	m_axi_gp1_wdata    => RTIO_AXI1_wdata  ,
	m_axi_gp1_wstrb    => RTIO_AXI1_wstrb  ,
	m_axi_gp1_wlast    => RTIO_AXI1_wlast(0)  ,
	m_axi_gp1_wvalid   => RTIO_AXI1_wvalid(0) ,
	m_axi_gp1_wready   => RTIO_AXI1_wready(0) ,
	m_axi_gp1_bid      => RTIO_AXI1_bid    ,
	m_axi_gp1_bresp    => RTIO_AXI1_bresp  ,
	m_axi_gp1_bvalid   => RTIO_AXI1_bvalid(0) ,
	m_axi_gp1_bready   => RTIO_AXI1_bready(0) ,
	m_axi_gp1_arid     => RTIO_AXI1_arid   ,
	m_axi_gp1_araddr   => RTIO_AXI1_araddr ,
	m_axi_gp1_arlen    => RTIO_AXI1_arlen  ,
	m_axi_gp1_arsize   => RTIO_AXI1_arsize ,
	m_axi_gp1_arburst  => RTIO_AXI1_arburst,
--	m_axi_gp1_arlock   => RTIO_AXI1_arlock ,
	m_axi_gp1_arcache  => RTIO_AXI1_arcache,
	m_axi_gp1_arprot   => RTIO_AXI1_arprot ,
	m_axi_gp1_arqos    => RTIO_AXI1_arqos  ,
	m_axi_gp1_arvalid  => RTIO_AXI1_arvalid(0),
	m_axi_gp1_arready  => RTIO_AXI1_arready(0),
	m_axi_gp1_rid      => RTIO_AXI1_rid    ,
	m_axi_gp1_rdata    => RTIO_AXI1_rdata  ,
	m_axi_gp1_rresp    => RTIO_AXI1_rresp  ,
	m_axi_gp1_rlast    => RTIO_AXI1_rlast(0)  ,
	m_axi_gp1_rvalid   => RTIO_AXI1_rvalid(0) ,
	m_axi_gp1_rready   => RTIO_AXI1_rready(0) ,
	dio0_p             => dio0_p            ,
	dio0_n             => dio0_n            ,
	dio0_p_1           => dio0_p_1          ,
	dio0_n_1           => dio0_n_1          ,
	dio0_p_2           => dio0_p_2          ,
	dio0_n_2           => dio0_n_2          ,
	dio0_p_3           => dio0_p_3          ,
	dio0_n_3           => dio0_n_3          ,
	dio0_p_4           => dio0_p_4          ,
	dio0_n_4           => dio0_n_4          ,
	dio0_p_5           => dio0_p_5          ,
	dio0_n_5           => dio0_n_5          ,
	dio0_p_6           => dio0_p_6          ,
	dio0_n_6           => dio0_n_6          ,
	dio0_p_7           => dio0_p_7          ,
	dio0_n_7           => dio0_n_7          ,
	pulsar5_spi_p_clk  => pulsar5_spi_p_clk ,
	pulsar5_spi_p_mosi => pulsar5_spi_p_mosi,
	pulsar5_spi_p_miso => pulsar5_spi_p_miso,
	pulsar5_spi_p_cs_n => pulsar5_spi_p_cs_n,
	pulsar5_spi_n_clk  => pulsar5_spi_n_clk ,
	pulsar5_spi_n_mosi => pulsar5_spi_n_mosi,
	pulsar5_spi_n_miso => pulsar5_spi_n_miso,
	pulsar5_spi_n_cs_n => pulsar5_spi_n_cs_n,
	rtio_clk           => rtio_clk          ,
	rtio_rst           => rtio_rst          ,
	rtiox4_clk         => rtiox4_clk        ,
	rtiox4_rst         => rtiox4_rst        ,
	sys_clk            => sys_clk           ,
	sys_rst            => sys_rst
);

wr_core_1 : wrc_board_kasli
generic map (
    g_simulation                => g_simulation,
    g_with_external_clock_input => g_with_external_clock_input,
    g_aux_clks                  => g_aux_clks,
    g_fabric_iface              => g_fabric_iface,
    g_dpram_initf               => "../wrc_phy16.bram",
    g_diag_id                   => g_diag_id,
    g_diag_ver                  => g_diag_ver,
    g_diag_ro_vector_width      => g_diag_ro_vector_width,
    g_diag_rw_vector_width      => g_diag_rw_vector_width)
port map (areset_n_i => areset_n_i,
       clk_125m_gtp_n_i => clk_125m_gtp_n_i,
       clk_125m_gtp_p_i => clk_125m_gtp_p_i,
       clk_125m_pllref_n_i => clk_125m_pllref_n_i,
       clk_125m_pllref_p_i => clk_125m_pllref_p_i,
       clk_20m_vcxo_i => clk_20m_vcxo_i,
--       clk_10m_ext_i => ,
--       pps_ext_i => ,
       clk_sys_62m5_o => clk_sys_62m5_o(0),
       clk_ref_125m_o => clk_ref_125m_o(0),
--       rst_sys_62m5_n_o => ,
--       rst_ref_125m_n_o => ,

       pll20dac_cs_n_o => pll20dac_cs_n_o,
       pll25dac_cs_n_o => pll25dac_cs_n_o,
       plldac_din_o => plldac_din_o,
       plldac_sclk_o => plldac_sclk_o,

--       SFP_mod_abs => SFP_mod_abs,
--       SFP_rx_los => SFP_rx_los,
--       SFP_rxn => SFP_rxn,
--       SFP_rxp => SFP_rxp,
--       SFP_tx_disable => SFP_tx_disable,
--       SFP_tx_fault => SFP_tx_fault,
--       SFP_txn => SFP_txn,
--       SFP_txp => SFP_txp,

       sfp_tx_p_o => SFP_txp,
       sfp_tx_n_o => SFP_txn,
       sfp_rx_p_i => SFP_rxp,
       sfp_rx_n_i => SFP_rxn,
--       sfp_det_i         : in  std_logic := '1';
       sfp_sda_i => sfp_i2c_sda_i,
       sfp_sda_o => sfp_i2c_sda_o,
       sfp_sda_t => sfp_i2c_sda_t,
       sfp_scl_i => sfp_i2c_scl_i,
       sfp_scl_o => sfp_i2c_scl_o,
       sfp_scl_t => sfp_i2c_scl_t,
       sfp_rate_select_o => sfp_rate_select_o,
       sfp_tx_fault_i => SFP_tx_fault,
       sfp_tx_disable_o => SFP_tx_disable,
       sfp_los_i => SFP_rx_los,

    wrf_src_o_adr => wrf_src_o_adr,
    wrf_src_o_dat => wrf_src_o_dat,
    wrf_src_o_cyc => wrf_src_o_cyc,
    wrf_src_o_stb => wrf_src_o_stb,
    wrf_src_o_we => wrf_src_o_we,
    wrf_src_o_sel => wrf_src_o_sel,

    wrf_src_i_ack    => wrf_src_i_ack,
    wrf_src_i_stall  => wrf_src_i_stall,
    wrf_src_i_err    => wrf_src_i_err,
    wrf_src_i_rty    => wrf_src_i_rty,

    wrf_snk_o_ack    => wrf_snk_o_ack,
    wrf_snk_o_stall  => wrf_snk_o_stall,
    wrf_snk_o_err    => wrf_snk_o_err,
    wrf_snk_o_rty    => wrf_snk_o_rty,

    wrf_snk_i_adr  => wrf_snk_i_adr,
    wrf_snk_i_dat  => wrf_snk_i_dat,
    wrf_snk_i_cyc  => wrf_snk_i_cyc,
    wrf_snk_i_stb  => wrf_snk_i_stb,
    wrf_snk_i_we   => wrf_snk_i_we,
    wrf_snk_i_sel  => wrf_snk_i_sel,


       eeprom_sda_i => eeprom_i2c_sda_i,
       eeprom_sda_o => eeprom_i2c_sda_o,
       eeprom_sda_t => eeprom_i2c_sda_t,
       eeprom_scl_i => eeprom_i2c_scl_i,
       eeprom_scl_o => eeprom_i2c_scl_o,
       eeprom_scl_t => eeprom_i2c_scl_t,

       thermo_id_i => thermo_id_tri_i,
       thermo_id_o => thermo_id_tri_o,
       thermo_id_t => thermo_id_tri_t,

       uart_rxd_i => UART_rxd,
       uart_txd_o => UART_txd,

       s00_axi_aclk_o => wr_axi_clk,
       s00_axi_aresetn => wr_axi_resetn(0),
       s00_axi_awaddr => wr_axi_awaddr,
       s00_axi_awprot => wr_axi_awprot,
       s00_axi_awvalid => wr_axi_awvalid,
       s00_axi_awready => wr_axi_awready,
       s00_axi_wdata => wr_axi_wdata,
       s00_axi_wstrb => wr_axi_wstrb,
       s00_axi_wvalid => wr_axi_wvalid,
       s00_axi_wready => wr_axi_wready,
       s00_axi_bresp => wr_axi_bresp,
       s00_axi_bvalid => wr_axi_bvalid,
       s00_axi_bready => wr_axi_bready,
       s00_axi_araddr => wr_axi_araddr,
       s00_axi_arprot => wr_axi_arprot,
       s00_axi_arvalid => wr_axi_arvalid,
       s00_axi_arready => wr_axi_arready,
       s00_axi_rdata => wr_axi_rdata,
       s00_axi_rresp => wr_axi_rresp,
       s00_axi_rvalid => wr_axi_rvalid,
       s00_axi_rready => wr_axi_rready,
--       s00_axi_rlast => ,

--       axi_int_o => ,
--       led_act_o => ,
--       led_link_o => ,
       pps_p_o => pps_o(0)
--       pps_led_o => ,
--       link_ok_o =>
       );

u_zynq_gmii : wb_gmii
port map (
    clk_sys_i           => sys_clk,
    rst_sys_n_i         => wr_axi_resetn(0),

    wrf_snk_adr_i       => wrf_src_o_adr,
    wrf_snk_dat_i       => wrf_src_o_dat,
    wrf_snk_sel_i       => wrf_src_o_sel,
    wrf_snk_cyc_i       => wrf_src_o_cyc,
    wrf_snk_we_i        => wrf_src_o_we ,
    wrf_snk_stb_i       => wrf_src_o_stb,
    wrf_snk_ack_o       => wrf_src_i_ack,
    wrf_snk_err_o       => wrf_src_i_err,
    wrf_snk_stall_o     => wrf_src_i_stall,

    wrf_src_adr_o       => wrf_snk_i_adr,
    wrf_src_dat_o       => wrf_snk_i_dat,
    wrf_src_sel_o       => wrf_snk_i_sel,
    wrf_src_cyc_o       => wrf_snk_i_cyc,
    wrf_src_stb_o       => wrf_snk_i_stb,
    wrf_src_we_o        => wrf_snk_i_we,
    wrf_src_ack_i       => wrf_snk_o_ack,
    wrf_src_err_i       => wrf_snk_o_err,
    wrf_src_stall_i     => wrf_snk_o_stall,

    gmii_rx_rst_n_i     => wr_axi_resetn(0),
    gmii_rx_125m_i      => sys_clk,
    gmii_rxd_i          => ZYNQ7_GMII_txd,
    gmii_rxdv_i         => ZYNQ7_GMII_tx_en(0),
    gmii_rx_er          => ZYNQ7_GMII_tx_er(0),

    gmii_tx_125m_i      => sys_clk,
    gmii_tx_rst_n_i     => wr_axi_resetn(0),
    gmii_txdata_o       => ZYNQ7_GMII_rxd,
    gmii_txen_o         => ZYNQ7_GMII_rx_dv,
    gmii_tx_er_o        => ZYNQ7_GMII_rx_er
);


  sfp_i2c_scl_iobuf : IOBUF
  port map(I => sfp_i2c_scl_o,
        IO => sfp_i2c_scl_io,
        O => sfp_i2c_scl_i,
        T => sfp_i2c_scl_t);

  sfp_i2c_sda_iobuf : IOBUF
  port map(I => sfp_i2c_sda_o,
        IO => sfp_i2c_sda_io,
        O => sfp_i2c_sda_i,
        T => sfp_i2c_sda_t);

  thermo_id_tri_iobuf : IOBUF
  port map(I => thermo_id_tri_o,
        IO => thermo_id_tri_io,
        O => thermo_id_tri_i,
        T => thermo_id_tri_t);

  clk_out_62_5 : OBUFDS
  port map(I => clk_sys_62m5_o(0),
         O => ddmtd_helper_clk_p,
         OB => ddmtd_helper_clk_n);

  clk_out_125 : OBUFDS
  port map(I => clk_ref_125m_o(0),
         O => clk_ref_125m_p(0),
         OB => clk_ref_125m_n(0));

  pps_out : OBUFDS
  port map(I => pps_o(0),
          O => pps_p(0),
          OB => pps_n(0));

   dio_oe_n <= (others=>'0');
   dio_term <= (others=>'0');

  eeprom_i2c_scl_iobuf : IOBUF
  port map(I  => eeprom_i2c_scl_o,
           IO => eeprom_i2c_scl_io,
           O  => eeprom_i2c_scl_i,
           T  => eeprom_i2c_scl_t);

  eeprom_i2c_sda_iobuf : IOBUF
  port map(I  => eeprom_i2c_sda_o,
           IO => eeprom_i2c_sda_io,
           O  => eeprom_i2c_sda_i,
           T  => eeprom_i2c_sda_t);

end architecture;
