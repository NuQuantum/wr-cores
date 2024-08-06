
library ieee;
use ieee.std_logic_1164.all;

library work;

library vunit_lib;
context vunit_lib.vunit_context;
context vunit_lib.vc_context;

entity kasli_testbench is
--port (
--
--);
end entity;

architecture sim of kasli_testbench is

    ---------------------------------------------------------------------------
    -- Clocks/resets
    ---------------------------------------------------------------------------
    -- Reset from system fpga
    signal areset_n_i          : std_logic := '0';
    -- Optional reset input active low with rising edge detection. Does not
    -- reset PLLs.
    --areset_edge_n_i     : in  std_logic := '1';
    -- Clock inputs from the board
    signal clk_20m_vcxo_i      : std_logic := '1';
    signal clk_125m_pllref_p_i : std_logic := '1';
    signal clk_125m_pllref_n_i : std_logic := '0';
    signal clk_125m_gtp_n_i    : std_logic := '0';
    signal clk_125m_gtp_p_i    : std_logic := '1';
    -- 10MHz ext ref clock input (g_with_external_clock_input = TRUE)
    signal clk_10m_ext_i       : std_logic := '0';
    -- External PPS input (g_with_external_clock_input = TRUE)
    signal pps_ext_i           : std_logic := '0';
    -- 62.5MHz sys clock output
    signal clk_sys_62m5_o      : std_logic;
    -- 125MHz ref clock output
    signal clk_ref_125m_o      :  std_logic;
    -- active low reset outputs, synchronous to 62m5 and 125m clocks
    signal rst_sys_62m5_n_o    :  std_logic;
    signal rst_ref_125m_n_o    :  std_logic;

    ---------------------------------------------------------------------------
    -- Shared SPI interface to DACs
    ---------------------------------------------------------------------------
    signal plldac_sclk_o   :  std_logic;
    signal plldac_din_o    :  std_logic;
    signal pll25dac_cs_n_o :  std_logic;
    signal pll20dac_cs_n_o :  std_logic;

    ---------------------------------------------------------------------------
    -- SFP I/O for transceiver and SFP management info
    ---------------------------------------------------------------------------
    signal sfp_tx_p_o         :  std_logic;
    signal sfp_tx_n_o         :  std_logic;
    signal sfp_rx_p_i         : std_logic := '0';
    signal sfp_rx_n_i         : std_logic := '1';
    signal sfp_det_i         : std_logic := '1';
    signal sfp_sda_i         :  std_logic := '0';
    signal sfp_sda_o         :  std_logic;
    signal sfp_sda_t         :  std_logic;
    signal sfp_scl_i         :  std_logic := '0';
    signal sfp_scl_o         :  std_logic;
    signal sfp_scl_t         :  std_logic;
    signal sfp_rate_select_o :  std_logic;
    signal sfp_tx_fault_i    :  std_logic := '0';
    signal sfp_tx_disable_o  :  std_logic;
    signal sfp_los_i         :  std_logic := '0';

    ---------------------------------------------------------------------------
    -- I2C EEPROM
    ---------------------------------------------------------------------------
    signal eeprom_sda_i :  std_logic := '0';
    signal eeprom_sda_o :  std_logic;
    signal eeprom_sda_t :  std_logic;
    signal eeprom_scl_i :  std_logic := '0';
    signal eeprom_scl_o :  std_logic;
    signal eeprom_scl_t :  std_logic;

    ---------------------------------------------------------------------------
    -- Onewire interface
    ---------------------------------------------------------------------------
    signal thermo_id_i :  std_logic := '0';
    signal thermo_id_o :  std_logic;
    signal thermo_id_t :  std_logic;

    ---------------------------------------------------------------------------
    -- UART
    ---------------------------------------------------------------------------
    signal uart_rxd_i :  std_logic := '0';
    signal uart_txd_o :  std_logic;

    ------------------------------------------
    -- Axi Slave Bus Interface S00_AXI
    ------------------------------------------
    signal s00_axi_aclk_o  :  std_logic := '0';
    signal s00_axi_aresetn :  std_logic := '1';
    signal s00_axi_awaddr  :  std_logic_vector(31 downto 0) := (others=>'0');
    signal s00_axi_awprot  : std_logic_vector(2 downto 0);
    signal s00_axi_awvalid :  std_logic := '0';
    signal s00_axi_awready :  std_logic := '0';
    signal s00_axi_wdata   :  std_logic_vector(31 downto 0) := (others=>'0');
    signal s00_axi_wstrb   :  std_logic_vector(3 downto 0)  := (others=>'0');
    signal s00_axi_wvalid  :  std_logic := '0';
    signal s00_axi_wready  :  std_logic := '0';
    signal s00_axi_bresp   :  std_logic_vector(1 downto 0);
    signal s00_axi_bvalid  :  std_logic := '0';
    signal s00_axi_bready  :  std_logic := '0';
    signal s00_axi_araddr  :  std_logic_vector(31 downto 0) := (others=>'0');
    signal s00_axi_arprot  : std_logic_vector(2 downto 0);
    signal s00_axi_arvalid :  std_logic := '0';
    signal s00_axi_arready :  std_logic := '0';
    signal s00_axi_rdata   :  std_logic_vector(31 downto 0);
    signal s00_axi_rresp   :  std_logic_vector(1 downto 0);
    signal s00_axi_rvalid  :  std_logic := '0';
    signal s00_axi_rready  :  std_logic := '0';
    signal s00_axi_rlast   :  std_logic := '0';
    signal axi_int_o       :  std_logic := '0';

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

    ---------------------------------------------------------------------------
    -- GMII interface (when g_fabric_iface = gmii)
    ---------------------------------------------------------------------------
    signal wrg_rx_clk       :  std_logic := '0';
    signal wrg_rx_valid     :  std_logic := '0';
    signal wrg_rx_err       :  std_logic := '0';
    signal wrg_rx_data      :  std_logic_vector(7 downto 0) := (others=>'0');

    signal wrg_tx_clk       :  std_logic := '0';
    signal wrg_tx_valid     :  std_logic := '0';
    signal wrg_tx_err       :  std_logic := '0';
    signal wrg_tx_data      :  std_logic_vector(7 downto 0) := (others=>'0');

    ---------------------------------------------------------------------------
    -- External Tx Timestamping I/F
    ---------------------------------------------------------------------------
    signal tstamps_stb_o       :  std_logic;
    signal tstamps_tsval_o     :  std_logic_vector(31 downto 0);
    signal tstamps_port_id_o   :  std_logic_vector(5 downto 0);
    signal tstamps_frame_id_o  :  std_logic_vector(15 downto 0);
    signal tstamps_incorrect_o :  std_logic;
    signal tstamps_ack_i       :  std_logic := '1';

    ---------------------------------------------------------------------------
    -- Buttons, LEDs and PPS output
    ---------------------------------------------------------------------------
    signal led_act_o  :  std_logic;
    signal led_link_o :  std_logic;
    --btn1_i     : in  std_logic := '1';
    --btn2_i     : in  std_logic := '1';
    -- 1PPS output
    signal pps_p_o    :  std_logic;
    signal pps_led_o  :  std_logic;
    -- Link ok indication
    signal link_ok_o  :  std_logic;

  constant axi_bus      : bus_master_t := new_bus(data_length => s00_axi_wdata'length, address_length => s00_axi_awaddr'length, logger => get_logger("axi_bus"));
  constant master_uart : uart_master_t := new_uart_master;
  constant master_stream : stream_master_t := as_stream(master_uart);

  constant slave_uart : uart_slave_t := new_uart_slave(data_length => 8);
  constant slave_stream : stream_slave_t := as_stream(slave_uart);

  constant wb_ethernet_rx : wishbone_slave_t := new_wishbone_slave;
  constant wb_ethernet_tx : bus_master_t := new_bus(data_length => wrf_src_o_dat'length, address_length => wrf_src_o_adr'length, logger => get_logger("wb_bus"));

  constant sgmii_rx : sgmii_slave_t := new_sgmii_slave;
  constant sgmii_tx : sgmii_master_t := new_sgmii_master;

begin

U_DUT : entity work.wrc_board_kasli
  generic map(
    g_simulation                => 1,
    g_with_external_clock_input => 0,
    g_aux_clks                  => 0,
    g_fabric_iface              => "PLAINFBRC",
    g_dpram_initf               => "../../../bin/wrpc/wrc_phy16.bram",
    g_diag_id                   => 0,
    g_diag_ver                  => 0,
    g_diag_ro_vector_width      => 0,
    g_diag_rw_vector_width      => 0
    )
  port map(
    areset_n_i          => areset_n_i,

    clk_20m_vcxo_i      => clk_20m_vcxo_i     ,
    clk_125m_pllref_p_i => clk_125m_pllref_p_i,
    clk_125m_pllref_n_i => clk_125m_pllref_n_i,
    clk_125m_gtp_n_i    => clk_125m_gtp_n_i   ,
    clk_125m_gtp_p_i    => clk_125m_gtp_p_i   ,
    clk_10m_ext_i       => clk_10m_ext_i      ,
    pps_ext_i           => pps_ext_i          ,
    clk_sys_62m5_o      => clk_sys_62m5_o     ,
    clk_ref_125m_o      => clk_ref_125m_o     ,
    rst_sys_62m5_n_o    => rst_sys_62m5_n_o   ,
    rst_ref_125m_n_o    => rst_ref_125m_n_o   ,

    plldac_sclk_o       => plldac_sclk_o  ,
    plldac_din_o        => plldac_din_o   ,
    pll25dac_cs_n_o     => pll25dac_cs_n_o,
    pll20dac_cs_n_o     => pll20dac_cs_n_o,

    sfp_tx_p_o          => sfp_tx_p_o       ,
    sfp_tx_n_o          => sfp_tx_n_o       ,
    sfp_rx_p_i          => sfp_rx_p_i       ,
    sfp_rx_n_i          => sfp_rx_n_i       ,
    sfp_det_i           => sfp_det_i        ,
    sfp_rate_select_o   => sfp_rate_select_o,
    sfp_tx_fault_i      => sfp_tx_fault_i   ,
    sfp_tx_disable_o    => sfp_tx_disable_o ,
    sfp_los_i           => sfp_los_i        ,

    sfp_sda_i           => sfp_sda_i        ,
    sfp_sda_o           => sfp_sda_o        ,
    sfp_sda_t           => sfp_sda_t        ,
    sfp_scl_i           => sfp_scl_i        ,
    sfp_scl_o           => sfp_scl_o        ,
    sfp_scl_t           => sfp_scl_t        ,

    eeprom_sda_i        => eeprom_sda_i,
    eeprom_sda_o        => eeprom_sda_o,
    eeprom_sda_t        => eeprom_sda_t,
    eeprom_scl_i        => eeprom_scl_i,
    eeprom_scl_o        => eeprom_scl_o,
    eeprom_scl_t        => eeprom_scl_t,

    thermo_id_i         => thermo_id_i,
    thermo_id_o         => thermo_id_o,
    thermo_id_t         => thermo_id_t,

    uart_rxd_i          => uart_rxd_i,
    uart_txd_o          => uart_txd_o,

    s00_axi_aclk_o      => s00_axi_aclk_o ,
    s00_axi_aresetn     => s00_axi_aresetn,
    s00_axi_awaddr      => s00_axi_awaddr ,
    s00_axi_awprot      => s00_axi_awprot ,
    s00_axi_awvalid     => s00_axi_awvalid,
    s00_axi_awready     => s00_axi_awready,
    s00_axi_wdata       => s00_axi_wdata  ,
    s00_axi_wstrb       => s00_axi_wstrb  ,
    s00_axi_wvalid      => s00_axi_wvalid ,
    s00_axi_wready      => s00_axi_wready ,
    s00_axi_bresp       => s00_axi_bresp  ,
    s00_axi_bvalid      => s00_axi_bvalid ,
    s00_axi_bready      => s00_axi_bready ,
    s00_axi_araddr      => s00_axi_araddr ,
    s00_axi_arprot      => s00_axi_arprot ,
    s00_axi_arvalid     => s00_axi_arvalid,
    s00_axi_arready     => s00_axi_arready,
    s00_axi_rdata       => s00_axi_rdata  ,
    s00_axi_rresp       => s00_axi_rresp  ,
    s00_axi_rvalid      => s00_axi_rvalid ,
    s00_axi_rready      => s00_axi_rready ,
    s00_axi_rlast       => s00_axi_rlast  ,
    axi_int_o           => axi_int_o      ,

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

    wrg_rx_clk          => wrg_rx_clk  ,
    wrg_rx_valid        => wrg_rx_valid,
    wrg_rx_err          => wrg_rx_err  ,
    wrg_rx_data         => wrg_rx_data ,

    wrg_tx_clk          => wrg_tx_clk  ,
    wrg_tx_valid        => wrg_tx_valid,
    wrg_tx_err          => wrg_tx_err  ,
    wrg_tx_data         => wrg_tx_data ,

    tstamps_stb_o       => tstamps_stb_o      ,
    tstamps_tsval_o     => tstamps_tsval_o    ,
    tstamps_port_id_o   => tstamps_port_id_o  ,
    tstamps_frame_id_o  => tstamps_frame_id_o ,
    tstamps_incorrect_o => tstamps_incorrect_o,
    tstamps_ack_i       => tstamps_ack_i      ,

    --tm_link_up_o    : out std_logic;
    --tm_time_valid_o : out std_logic;
    --tm_tai_o        : out std_logic_vector(39 downto 0);
    --tm_cycles_o     : out std_logic_vector(27 downto 0);

    led_act_o           => led_act_o ,
    led_link_o          => led_link_o,

    pps_p_o             => pps_p_o  ,
    pps_led_o           => pps_led_o,

    link_ok_o           => link_ok_o
    );

---------------------------------------------
-- clocks and reset
---------------------------------------------
    areset_n_i          <= '1' after 100 ns;

    clk_20m_vcxo_i      <= not clk_20m_vcxo_i after 25 ns;
    clk_125m_pllref_p_i <= not clk_125m_pllref_p_i after 4 ns;
    clk_125m_pllref_n_i <= not clk_125m_pllref_n_i after 4 ns;
    clk_125m_gtp_n_i    <= not clk_125m_gtp_n_i after 4 ns;
    clk_125m_gtp_p_i    <= not clk_125m_gtp_p_i after 4 ns;
    clk_10m_ext_i       <= not clk_10m_ext_i after 50 ns;
    pps_ext_i           <= not pps_ext_i after 0.5 sec;

--    clk_sys_62m5_o      => clk_sys_62m5_o     ,
--    clk_ref_125m_o      => clk_ref_125m_o     ,
--    rst_sys_62m5_n_o    => rst_sys_62m5_n_o   ,
--    rst_ref_125m_n_o    => rst_ref_125m_n_o   ,

--    plldac_sclk_o       => plldac_sclk_o  ,
--    plldac_din_o        => plldac_din_o   ,
--    pll25dac_cs_n_o     => pll25dac_cs_n_o,
--    pll20dac_cs_n_o     => pll20dac_cs_n_o,

--  inst_dut: entity work.serial_dac856x
--    generic map (
--      g_sclk_div => 1
--      )
--    port map (
--      clk_i => clk,
--      rst_n_i => rst_n,
--      value_a_i => value_a,
--      wr_a_i => wr_a,
--      value_b_i => value_b,
--      wr_b_i => wr_b,
--
--      sclk_o => sclk,
--      d_o => din,
--      sync_n_o => sync_n
--      );
--
--  inst_dut: entity work.serial_dac856x
--    generic map (
--      g_sclk_div => 1
--      )
--    port map (
--      clk_i => clk,
--      rst_n_i => rst_n,
--      value_a_i => value_a,
--      wr_a_i => wr_a,
--      value_b_i => value_b,
--      wr_b_i => wr_b,
--
--      sclk_o => sclk,
--      d_o => din,
--      sync_n_o => sync_n
--      );

------------------------------------------
--  axi interface
------------------------------------------
axi_master : entity vunit_lib.axi_lite_master
    generic map (
      bus_handle => axi_bus)
    port map (
      aclk    => s00_axi_aclk_o,

      arready => s00_axi_arready,
      arvalid => s00_axi_arvalid,
      araddr  => s00_axi_araddr,

      rready  => s00_axi_rready,
      rvalid  => s00_axi_rvalid,
      rdata   => s00_axi_rdata,
      rresp   => s00_axi_rresp,

      awready => s00_axi_awready,
      awvalid => s00_axi_awvalid,
      awaddr  => s00_axi_awaddr,

      wready  => s00_axi_wready,
      wvalid  => s00_axi_wvalid,
      wdata   => s00_axi_wdata,
      wstrb   => s00_axi_wstrb,

      bvalid  => s00_axi_bvalid,
      bready  => s00_axi_bready,
      bresp   => s00_axi_bresp);

----------------------------------------
-- uart                               --
----------------------------------------
  uart_master_inst: entity vunit_lib.uart_master
    generic map (uart => master_uart)
    port map (tx => uart_rxd_i);

  uart_slave_inst: entity vunit_lib.uart_slave
    generic map (uart => slave_uart)
    port map (rx => uart_txd_o);


----------------------------------------
-- wishbone ethernet interface        --
----------------------------------------
U_wb_rx : entity vunit_lib.wishbone_slave
  generic map(
    wishbone_slave : wishbone_slave_t
  );
  port map(
    clk   => ,
    adr   => wrf_src_o_adr,
    dat_i => wrf_src_o_dat,
    dat_o => open,
    sel   => wrf_src_o_sel,
    cyc   => wrf_src_o_cyc,
    stb   => wrf_src_o_stb,
    we    => wrf_src_o_we,
    stall => wrf_src_i_stall,
    ack   => wrf_src_i_ack
    );
--    wrf_src_i_err       => wrf_src_i_err  ,
--    wrf_src_i_rty       => wrf_src_i_rty  ,


U_wb_tx : entity vunit_lib.wishbone_master
  generic map(
    bus_handle : bus_master_t;
    strobe_high_probability : real range 0.0 to 1.0 := 1.0
    );
  port map(
    clk   => ,
    adr   => wrf_snk_i_adr,
    dat_i => (others=>'0'),
    dat_o => wrf_snk_i_dat,
    sel   => wrf_snk_i_sel,
    cyc   => wrf_snk_i_cyc,
    stb   => wrf_snk_i_stb,
    we    => wrf_snk_i_we,
    stall => wrf_snk_o_stall,
    ack   => wrf_snk_o_ack
    );

--    wrf_snk_o_err       => wrf_snk_o_err  ,
--    wrf_snk_o_rty       => wrf_snk_o_rty  ,
----------------------------------------
-- WR SFP                              --
----------------------------------------

u_sgmii_master entity work.sgmii_master
  generic map(sgmii => sgmii_tx);
  port map(tx_p => sfp_rx_p_i,
           tx_n => sfp_rx_n_i);

u_sgmii_slave entity work.sgmii_slave
  generic map(sgmii => sgmii_rx);
  port map(rx_p => sfp_tx_p_o,
           rx_n => sfp_tx_n_o);

--    sfp_det_i           => sfp_det_i        ,
--    sfp_rate_select_o   => sfp_rate_select_o,
--    sfp_tx_fault_i      => sfp_tx_fault_i   ,
--    sfp_tx_disable_o    => sfp_tx_disable_o ,
--    sfp_los_i           <=  sfp_los_i        ,

-----------------------------------------
-- SFP EEPROM model
-----------------------------------------
    sfp_sda_i           <= sfp_sda_o when sfp_sda_t='1' else 'H';
    sfp_scl_i           <= sfp_scl_o when sfp_scl_t='1' else 'H';

--    sfp_sda_i           => sfp_sda_i        ,
--    sfp_sda_o           => sfp_sda_o        ,
--    sfp_sda_t           => sfp_sda_t        ,
--    sfp_scl_i           => sfp_scl_i        ,
--    sfp_scl_o           => sfp_scl_o        ,
--    sfp_scl_t           => sfp_scl_t        ,

----------------------------------------
-- eeprom model                       --
----------------------------------------
    eeprom_sda_i           <= eeprom_sda_o when eeprom_sda_t='1' else 'H';
    eeprom_scl_i           <= eeprom_scl_o when eeprom_scl_t='1' else 'H';

--    eeprom_sda_i        => eeprom_sda_i,
--    eeprom_sda_o        => eeprom_sda_o,
--    eeprom_sda_t        => eeprom_sda_t,
--    eeprom_scl_i        => eeprom_scl_i,
--    eeprom_scl_o        => eeprom_scl_o,
--    eeprom_scl_t        => eeprom_scl_t,

----------------------------------------
-- temperature chip                   --
----------------------------------------
    thermo_id_i         <= thermo_id_o when thermo_id_t='1' else 'H';
--    thermo_id_i         => thermo_id_i,
--    thermo_id_o         => thermo_id_o,
--    thermo_id_t         => thermo_id_t,

    end architecture;