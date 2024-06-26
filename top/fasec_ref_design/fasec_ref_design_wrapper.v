//Copyright 1986-2022 Xilinx, Inc. All Rights Reserved.
//--------------------------------------------------------------------------------
//Tool Version: Vivado v.2022.2 (lin64) Build 3671981 Fri Oct 14 04:59:54 MDT 2022
//Date        : Tue Jun 18 17:25:48 2024
//Host        : NU-QUANTUM-LAP30 running 64-bit Ubuntu 22.04.4 LTS
//Command     : generate_target fasec_ref_design_wrapper.bd
//Design      : fasec_ref_design_wrapper
//Purpose     : IP block netlist
//--------------------------------------------------------------------------------
`timescale 1 ps / 1 ps

module fasec_ref_design_wrapper
   (DDR_addr,
    DDR_ba,
    DDR_cas_n,
    DDR_ck_n,
    DDR_ck_p,
    DDR_cke,
    DDR_cs_n,
    DDR_dm,
    DDR_dq,
    DDR_dqs_n,
    DDR_dqs_p,
    DDR_odt,
    DDR_ras_n,
    DDR_reset_n,
    DDR_we_n,
    FIXED_IO_ddr_vrn,
    FIXED_IO_ddr_vrp,
    FIXED_IO_mio,
    FIXED_IO_ps_clk,
    FIXED_IO_ps_porb,
    FIXED_IO_ps_srstb,
    SFP_mod_abs,
    SFP_rx_los,
    SFP_rxn,
    SFP_rxp,
    SFP_tx_disable,
    SFP_tx_fault,
    SFP_txn,
    SFP_txp,
    areset_n_i,
    clk_125m_gtp_n_i,
    clk_125m_gtp_p_i,
    clk_125m_pllref_n_i,
    clk_125m_pllref_p_i,
    clk_20m_vcxo_i,
    clk_ref_125m_n,
    clk_ref_125m_p,
    clk_sys_62m5_n,
    clk_sys_62m5_p,
    dio_oe_n,
    dio_term,
    eeprom_i2c_scl_io,
    eeprom_i2c_sda_io,
    pll20dac_cs_n_o,
    pll25dac_cs_n_o,
    plldac_din_o,
    plldac_sclk_o,
    pps_n,
    pps_p,
    sfp_i2c_scl_io,
    sfp_i2c_sda_io,
    sfp_rate_select_o,
    thermo_id_tri_io);
  inout [14:0]DDR_addr;
  inout [2:0]DDR_ba;
  inout DDR_cas_n;
  inout DDR_ck_n;
  inout DDR_ck_p;
  inout DDR_cke;
  inout DDR_cs_n;
  inout [3:0]DDR_dm;
  inout [31:0]DDR_dq;
  inout [3:0]DDR_dqs_n;
  inout [3:0]DDR_dqs_p;
  inout DDR_odt;
  inout DDR_ras_n;
  inout DDR_reset_n;
  inout DDR_we_n;
  inout FIXED_IO_ddr_vrn;
  inout FIXED_IO_ddr_vrp;
  inout [53:0]FIXED_IO_mio;
  inout FIXED_IO_ps_clk;
  inout FIXED_IO_ps_porb;
  inout FIXED_IO_ps_srstb;
  input SFP_mod_abs;
  input SFP_rx_los;
  input SFP_rxn;
  input SFP_rxp;
  output SFP_tx_disable;
  input SFP_tx_fault;
  output SFP_txn;
  output SFP_txp;
  input areset_n_i;
  input clk_125m_gtp_n_i;
  input clk_125m_gtp_p_i;
  input clk_125m_pllref_n_i;
  input clk_125m_pllref_p_i;
  input clk_20m_vcxo_i;
  output [0:0]clk_ref_125m_n;
  output [0:0]clk_ref_125m_p;
  output [0:0]clk_sys_62m5_n;
  output [0:0]clk_sys_62m5_p;
  output [2:0]dio_oe_n;
  output [2:0]dio_term;
  inout eeprom_i2c_scl_io;
  inout eeprom_i2c_sda_io;
  output pll20dac_cs_n_o;
  output pll25dac_cs_n_o;
  output plldac_din_o;
  output plldac_sclk_o;
  output [0:0]pps_n;
  output [0:0]pps_p;
  inout sfp_i2c_scl_io;
  inout sfp_i2c_sda_io;
  output sfp_rate_select_o;
  inout thermo_id_tri_io;

  wire [14:0]DDR_addr;
  wire [2:0]DDR_ba;
  wire DDR_cas_n;
  wire DDR_ck_n;
  wire DDR_ck_p;
  wire DDR_cke;
  wire DDR_cs_n;
  wire [3:0]DDR_dm;
  wire [31:0]DDR_dq;
  wire [3:0]DDR_dqs_n;
  wire [3:0]DDR_dqs_p;
  wire DDR_odt;
  wire DDR_ras_n;
  wire DDR_reset_n;
  wire DDR_we_n;
  wire FIXED_IO_ddr_vrn;
  wire FIXED_IO_ddr_vrp;
  wire [53:0]FIXED_IO_mio;
  wire FIXED_IO_ps_clk;
  wire FIXED_IO_ps_porb;
  wire FIXED_IO_ps_srstb;
  wire SFP_mod_abs;
  wire SFP_rx_los;
  wire SFP_rxn;
  wire SFP_rxp;
  wire SFP_tx_disable;
  wire SFP_tx_fault;
  wire SFP_txn;
  wire SFP_txp;
  wire areset_n_i;
  wire clk_125m_gtp_n_i;
  wire clk_125m_gtp_p_i;
  wire clk_125m_pllref_n_i;
  wire clk_125m_pllref_p_i;
  wire clk_20m_vcxo_i;
  wire [0:0]clk_ref_125m_o;
  wire [0:0]clk_ref_125m_n;
  wire [0:0]clk_ref_125m_p;
  wire [0:0]clk_sys_62m5_o
  wire [0:0]clk_sys_62m5_n;
  wire [0:0]clk_sys_62m5_p;
  wire [2:0]dio_oe_n;
  wire [2:0]dio_term;
  wire eeprom_i2c_scl_i;
  wire eeprom_i2c_scl_io;
  wire eeprom_i2c_scl_o;
  wire eeprom_i2c_scl_t;
  wire eeprom_i2c_sda_i;
  wire eeprom_i2c_sda_io;
  wire eeprom_i2c_sda_o;
  wire eeprom_i2c_sda_t;
  wire pll20dac_cs_n_o;
  wire pll25dac_cs_n_o;
  wire plldac_din_o;
  wire plldac_sclk_o;
  wire [0:0]pps_0;
  wire [0:0]pps_n;
  wire [0:0]pps_p;
  wire sfp_i2c_scl_i;
  wire sfp_i2c_scl_io;
  wire sfp_i2c_scl_o;
  wire sfp_i2c_scl_t;
  wire sfp_i2c_sda_i;
  wire sfp_i2c_sda_io;
  wire sfp_i2c_sda_o;
  wire sfp_i2c_sda_t;
  wire sfp_rate_select_o;
  wire thermo_id_tri_i;
  wire thermo_id_tri_io;
  wire thermo_id_tri_o;
  wire thermo_id_tri_t;

  IOBUF eeprom_i2c_scl_iobuf
       (.I(eeprom_i2c_scl_o),
        .IO(eeprom_i2c_scl_io),
        .O(eeprom_i2c_scl_i),
        .T(eeprom_i2c_scl_t));
  IOBUF eeprom_i2c_sda_iobuf
       (.I(eeprom_i2c_sda_o),
        .IO(eeprom_i2c_sda_io),
        .O(eeprom_i2c_sda_i),
        .T(eeprom_i2c_sda_t));

fasec_ref_design fasec_ref_design_i
        (.DDR_addr(DDR_addr),
         .DDR_ba(DDR_ba),
         .DDR_cas_n(DDR_cas_n),
         .DDR_ck_n(DDR_ck_n),
         .DDR_ck_p(DDR_ck_p),
         .DDR_cke(DDR_cke),
         .DDR_cs_n(DDR_cs_n),
         .DDR_dm(DDR_dm),
         .DDR_dq(DDR_dq),
         .DDR_dqs_n(DDR_dqs_n),
         .DDR_dqs_p(DDR_dqs_p),
         .DDR_odt(DDR_odt),
         .DDR_ras_n(DDR_ras_n),
         .DDR_reset_n(DDR_reset_n),
         .DDR_we_n(DDR_we_n),
         .FIXED_IO_ddr_vrn(FIXED_IO_ddr_vrn),
         .FIXED_IO_ddr_vrp(FIXED_IO_ddr_vrp),
         .FIXED_IO_mio(FIXED_IO_mio),
         .FIXED_IO_ps_clk(FIXED_IO_ps_clk),
         .FIXED_IO_ps_porb(FIXED_IO_ps_porb),
         .FIXED_IO_ps_srstb(FIXED_IO_ps_srstb),
         .UART_0_rxd(UART_0_rxd),
         .UART_0_txd(UART_0_txd),
         .wr_axi_araddr(wr_axi_araddr),
         .wr_axi_arprot(wr_axi_arprot),
         .wr_axi_arready(wr_axi_arready),
         .wr_axi_arvalid(wr_axi_arvalid),
         .wr_axi_awaddr(wr_axi_awaddr),
         .wr_axi_awprot(wr_axi_awprot),
         .wr_axi_awready(wr_axi_awready),
         .wr_axi_awvalid(wr_axi_awvalid),
         .wr_axi_bready(wr_axi_bready),
         .wr_axi_bresp(wr_axi_bresp),
         .wr_axi_bvalid(wr_axi_bvalid),
         .wr_axi_clk(wr_axi_clk),
         .wr_axi_rdata(wr_axi_rdata),
         .wr_axi_rready(wr_axi_rready),
         .wr_axi_rresp(wr_axi_rresp),
         .wr_axi_rstn(wr_axi_rstn),
         .wr_axi_rvalid(wr_axi_rvalid),
         .wr_axi_wdata(wr_axi_wdata),
         .wr_axi_wready(wr_axi_wready),
         .wr_axi_wstrb(wr_axi_wstrb),
         .wr_axi_wvalid(wr_axi_wvalid));
         

wrc_board_fasec wr_core_1
       .areset_n_i(areset_n_i),
       .clk_125m_gtp_n_i(clk_125m_gtp_n_i),
       .clk_125m_gtp_p_i(clk_125m_gtp_p_i),
       .clk_125m_pllref_n_i(clk_125m_pllref_n_i),
       .clk_125m_pllref_p_i(clk_125m_pllref_p_i),
       .clk_20m_vcxo_i(clk_20m_vcxo_i),
       .clk_10m_ext_i(),
       .pps_ext_i(),
       .clk_sys_62m5_o(clk_sys_62m5_o),
       .clk_ref_125m_o(clk_ref_125m_o),
       .rst_sys_62m5_n_o(),
       .rst_ref_125m_n_o(),
   
       .pll20dac_cs_n_o(pll20dac_cs_n_o),
       .pll25dac_cs_n_o(pll25dac_cs_n_o),
       .plldac_din_o(plldac_din_o),
       .plldac_sclk_o(plldac_sclk_o),
   
       .SFP_mod_abs(SFP_mod_abs),
       .SFP_rx_los(SFP_rx_los),
       .SFP_rxn(SFP_rxn),
       .SFP_rxp(SFP_rxp),
       .SFP_tx_disable(SFP_tx_disable),
       .SFP_tx_fault(SFP_tx_fault),
       .SFP_txn(SFP_txn),
       .SFP_txp(SFP_txp),

       .sfp_tx_p_o(SFP_txp),
       .sfp_tx_n_o(SFP_txn),
       .sfp_rx_p_i(SFP_rxp),
       .sfp_rx_n_i(SFP_rxn),
//       .sfp_det_i         : in  std_logic := '1';
       .sfp_sda_i(sfp_i2c_sda_i),
       .sfp_sda_o(sfp_i2c_sda_o),
       .sfp_sda_t(sfp_i2c_sda_t),
       .sfp_scl_i(sfp_i2c_scl_i),
       .sfp_scl_o(sfp_i2c_scl_o),
       .sfp_scl_t(sfp_i2c_scl_t),
       .sfp_rate_select_o(sfp_rate_select_o),
       .sfp_tx_fault_i(SFP_tx_fault),
       .sfp_tx_disable_o(SFP_tx_disable),
       .sfp_los_i(SFP_rx_los),
   

       .eeprom_sda_i(eeprom_i2c_sda_i),
       .eeprom_sda_o(eeprom_i2c_sda_o),
       .eeprom_sda_t(eeprom_i2c_sda_t),
       .eeprom_scl_i(eeprom_i2c_scl_i),
       .eeprom_scl_o(eeprom_i2c_scl_o),
       .eeprom_scl_t(eeprom_i2c_scl_t),
   
       .thermo_id_i(thermo_id_tri_i),
       .thermo_id_o(thermo_id_tri_o),
       .thermo_id_t(thermo_id_tri_t),
   
       .uart_rxd_i(UART_0_txd),
       .uart_txd_o(UART_0_rxd),
   
       .s00_axi_aclk_o(wr_axi_clk),
       .s00_axi_aresetn(wr_axi_rstn),
       .s00_axi_awaddr(wr_axi_awaddr),
       //s00_axi_awprot(wr_axi_awprot),
       .s00_axi_awvalid(wr_axi_awvalid),
       .s00_axi_awready(wr_axi_awready),
       .s00_axi_wdata(wr_axi_wdata),
       .s00_axi_wstrb(wr_axi_wstrb),
       .s00_axi_wvalid(wr_axi_wvalid),
       .s00_axi_wready(wr_axi_wready),
       .s00_axi_bresp(wr_axi_bresp),
       .s00_axi_bvalid(wr_axi_bvalid),
       .s00_axi_bready(wr_axi_bready),
       .s00_axi_araddr(wr_axi_araddr),
       //s00_axi_arprot(wr_axi_arprot),
       .s00_axi_arvalid(wr_axi_arvalid),
       .s00_axi_arready(wr_axi_arready),
       .s00_axi_rdata(wr_axi_rdata),
       .s00_axi_rresp(wr_axi_rresp),
       .s00_axi_rvalid(wr_axi_rvalid),
       .s00_axi_rready(wr_axi_rready),
       .s00_axi_rlast(),

       .axi_int_o(),
       .led_act_o(),
       .led_link_o(),
       .pps_p_o(pps_o),
       .pps_led_o(),
       .link_ok_o()
       );
           
  IOBUF sfp_i2c_scl_iobuf
       (.I(sfp_i2c_scl_o),
        .IO(sfp_i2c_scl_io),
        .O(sfp_i2c_scl_i),
        .T(sfp_i2c_scl_t));
  IOBUF sfp_i2c_sda_iobuf
       (.I(sfp_i2c_sda_o),
        .IO(sfp_i2c_sda_io),
        .O(sfp_i2c_sda_i),
        .T(sfp_i2c_sda_t));
  IOBUF thermo_id_tri_iobuf
       (.I(thermo_id_tri_o),
        .IO(thermo_id_tri_io),
        .O(thermo_id_tri_i),
        .T(thermo_id_tri_t));

  OBUFDS clk_out_62_5
        (.I(clk_sys_62m5_o),
         .O(clk_sys_62m5_p),
         .OB(clk_sys_62m5_n));

  OBUFDS clk_out_125
        (.I(clk_ref_125m_o),
         .O(clk_ref_125m_p),
         .OB(clk_ref_125m_n));

  OBUFDS pps_out
         (.I(pps_o),
          .O(pps_p),
          .OB(pps_n));
          
  assign dio_oe_n = 0;
  assign dio_term = 0;

endmodule
