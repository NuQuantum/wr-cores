library ieee;
use ieee.std_logic_1164.all;

library unisim;
use unisim.vcomponents.all;

entity fasec is
 generic(
    -- set to 1 to speed up some initialization processes during simulation
    g_simulation                : integer := 0;
    -- Select whether to include external ref clock input
    g_with_external_clock_input : integer := 0;
    -- Number of aux clocks syntonized by WRPC to WR timebase
    g_aux_clks                  : integer := 0;
    -- "plainfbrc" = expose WRC fabric interface
    -- "streamers" = attach WRC streamers to fabric interface
    -- "etherbone" = attach Etherbone slave to fabric interface
    g_fabric_iface              : string  := "plainfbrc";
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
    FIXED_IO_ddr_vrn : inout STD_LOGIC;
    FIXED_IO_ddr_vrp : inout STD_LOGIC;
    FIXED_IO_mio : inout STD_LOGIC_VECTOR ( 53 downto 0 );
    FIXED_IO_ps_clk : inout STD_LOGIC;
    FIXED_IO_ps_porb : inout STD_LOGIC;
    FIXED_IO_ps_srstb : inout STD_LOGIC;

    SFP_mod_abs : in std_logic;
    SFP_rx_los : in std_logic;
    SFP_rxn : in std_logic;
    SFP_rxp : in std_logic;
    SFP_tx_disable : out std_logic;
    SFP_tx_fault : in std_logic;
    SFP_txn : out std_logic;
    SFP_txp : out std_logic;
    areset_n_i : in std_logic;
    clk_125m_gtp_n_i : in std_logic;
    clk_125m_gtp_p_i : in std_logic;
    clk_125m_pllref_n_i : in std_logic;
    clk_125m_pllref_p_i : in std_logic;
    clk_20m_vcxo_i : in std_logic;
    clk_ref_125m_n : out std_logic_vector(0 downto 0);
    clk_ref_125m_p : out std_logic_vector(0 downto 0);
    clk_sys_62m5_n : out std_logic_vector(0 downto 0);
    clk_sys_62m5_p : out std_logic_vector(0 downto 0);
    dio_oe_n : out std_logic_vector(2 downto 0);
    dio_term : out std_logic_vector(2 downto 0);
    eeprom_i2c_scl_io : inout std_logic;
    eeprom_i2c_sda_io : inout std_logic;
    pll20dac_cs_n_o : out std_logic;
    pll25dac_cs_n_o : out std_logic;
    plldac_din_o : out std_logic;
    plldac_sclk_o : out std_logic;
    pps_n : out std_logic_vector(0 downto 0);
    pps_p : out std_logic_vector(0 downto 0);
    sfp_i2c_scl_io : inout std_logic;
    sfp_i2c_sda_io : inout std_logic;
    sfp_rate_select_o : out std_logic;
    thermo_id_tri_io : inout std_logic

  );
end entity;

architecture rtl of fasec is

signal UART_0_rxd     : STD_LOGIC;
signal UART_0_txd     : STD_LOGIC;

signal wr_axi_araddr  : STD_LOGIC_VECTOR ( 31 downto 0 );
signal wr_axi_arburst : STD_LOGIC_VECTOR ( 1 downto 0 );
signal wr_axi_arcache : STD_LOGIC_VECTOR ( 3 downto 0 );
signal wr_axi_arid    : STD_LOGIC_VECTOR ( 11 downto 0 );
signal wr_axi_arlen   : STD_LOGIC_VECTOR ( 3 downto 0 );
signal wr_axi_arlock  : STD_LOGIC_VECTOR ( 1 downto 0 );
signal wr_axi_arprot  : STD_LOGIC_VECTOR ( 2 downto 0 );
signal wr_axi_arqos   : STD_LOGIC_VECTOR ( 3 downto 0 );
signal wr_axi_arready : STD_LOGIC;
signal wr_axi_arsize  :  STD_LOGIC_VECTOR ( 2 downto 0 );
signal wr_axi_arvalid :  STD_LOGIC;
signal wr_axi_awaddr  :  STD_LOGIC_VECTOR ( 31 downto 0 );
signal wr_axi_awburst :  STD_LOGIC_VECTOR ( 1 downto 0 );
signal wr_axi_awcache :  STD_LOGIC_VECTOR ( 3 downto 0 );
signal wr_axi_awid    :  STD_LOGIC_VECTOR ( 11 downto 0 );
signal wr_axi_awlen   :  STD_LOGIC_VECTOR ( 3 downto 0 );
signal wr_axi_awlock  :  STD_LOGIC_VECTOR ( 1 downto 0 );
signal wr_axi_awprot  :  STD_LOGIC_VECTOR ( 2 downto 0 );
signal wr_axi_awqos   :  STD_LOGIC_VECTOR ( 3 downto 0 );
signal wr_axi_awready : STD_LOGIC;
signal wr_axi_awsize  :  STD_LOGIC_VECTOR ( 2 downto 0 );
signal wr_axi_awvalid :  STD_LOGIC;
signal wr_axi_bid     : STD_LOGIC_VECTOR ( 11 downto 0 );
signal wr_axi_bready  :  STD_LOGIC;
signal wr_axi_bresp   : STD_LOGIC_VECTOR ( 1 downto 0 );
signal wr_axi_bvalid  : STD_LOGIC;
signal wr_axi_clk     : STD_LOGIC;
signal wr_axi_rdata   : STD_LOGIC_VECTOR ( 31 downto 0 );
signal wr_axi_resetn  :  STD_LOGIC_VECTOR ( 0 to 0 );
signal wr_axi_rid     : STD_LOGIC_VECTOR ( 11 downto 0 );
signal wr_axi_rlast   : STD_LOGIC;
signal wr_axi_rready  :  STD_LOGIC;
signal wr_axi_rresp   : STD_LOGIC_VECTOR ( 1 downto 0 );
signal wr_axi_rvalid  : STD_LOGIC;
signal wr_axi_wdata   :  STD_LOGIC_VECTOR ( 31 downto 0 );
signal wr_axi_wid     :  STD_LOGIC_VECTOR ( 11 downto 0 );
signal wr_axi_wlast   :  STD_LOGIC;
signal wr_axi_wready  : STD_LOGIC;
signal wr_axi_wstrb   :  STD_LOGIC_VECTOR ( 3 downto 0 );
signal wr_axi_wvalid  :  STD_LOGIC;



  signal clk_ref_125m_o  :  STD_LOGIC_VECTOR(0 downto 0);
  signal clk_sys_62m5_o :  STD_LOGIC_VECTOR(0 downto 0);

  signal eeprom_i2c_scl_i  :  STD_LOGIC;
  signal eeprom_i2c_scl_o  :  STD_LOGIC;
  signal eeprom_i2c_scl_t  :  STD_LOGIC;
  signal eeprom_i2c_sda_i  :  STD_LOGIC;
  signal eeprom_i2c_sda_o  :  STD_LOGIC;
  signal eeprom_i2c_sda_t  :  STD_LOGIC;

  signal pps_o :  STD_LOGIC_VECTOR(0 downto 0);
  signal sfp_i2c_scl_i  :  STD_LOGIC;
  signal sfp_i2c_scl_o  :  STD_LOGIC;
  signal sfp_i2c_scl_t  :  STD_LOGIC;
  signal sfp_i2c_sda_i  :  STD_LOGIC;
  signal sfp_i2c_sda_o  :  STD_LOGIC;
  signal sfp_i2c_sda_t  :  STD_LOGIC;
   signal thermo_id_tri_i  :  STD_LOGIC;
  signal thermo_id_tri_o  :  STD_LOGIC;
  signal thermo_id_tri_t  :  STD_LOGIC;

begin

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

fasec_ref_design_i : entity work.fasec_ref_design
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
      UART_0_rxd => UART_0_rxd,
      UART_0_txd => UART_0_txd,
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

wr_core_1 : entity work.wrc_board_fasec
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


       eeprom_sda_i => eeprom_i2c_sda_i,
       eeprom_sda_o => eeprom_i2c_sda_o,
       eeprom_sda_t => eeprom_i2c_sda_t,
       eeprom_scl_i => eeprom_i2c_scl_i,
       eeprom_scl_o => eeprom_i2c_scl_o,
       eeprom_scl_t => eeprom_i2c_scl_t,

       thermo_id_i => thermo_id_tri_i,
       thermo_id_o => thermo_id_tri_o,
       thermo_id_t => thermo_id_tri_t,

       uart_rxd_i => UART_0_txd,
       uart_txd_o => UART_0_rxd,

       s00_axi_aclk_o => wr_axi_clk,
       s00_axi_aresetn => wr_axi_resetn(0),
       s00_axi_awaddr => wr_axi_awaddr,
       --s00_axi_awprot => wr_axi_awprot,
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
       --s00_axi_arprot => wr_axi_arprot,
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
         O => clk_sys_62m5_p(0),
         OB => clk_sys_62m5_n(0));

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

end architecture;
