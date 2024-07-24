//////////////////////////////////////////////////////////////////////////////-
// Title      : WhiteRabbit PTP Core
// Project    : WhiteRabbit
//////////////////////////////////////////////////////////////////////////////-
// File       : xwr_core.v
// Author     : Richard North <richard.north@nu-quantum.com>
// Company    : Nu-Quantum
// Created    : 2024-07-04
// Platform   : FPGA-generics
// Standard   : Verilog
//////////////////////////////////////////////////////////////////////////////-
// Description:
// WR PTP Core is a HDL module implementing a complete gigabit Ethernet
// interface (MAC + PCS + PHY) with integrated PTP slave ordinary clock
// compatible with White Rabbit protocol. It performs subnanosecond clock
// synchronization via WR protocol and also acts as an Ethernet "gateway",
// providing access to TX/RX interfaces of the built-in WR MAC.
//
// Starting from version 2.0 all modules are interconnected with pipelined
// wishbone interface (using wb crossbar and bus fanout). Separate pipelined
// wishbone bus is used for passing packets between Endpoint, Mini-NIC
// and External MAC interface.
//////////////////////////////////////////////////////////////////////////////-
//
//////////////////////////////////////////////////////////////////////////////-
// Memory map:
//  0x00000000: I/D Memory
//  0x00020000: Peripheral interconnect
//      +0x000: Minic
//      +0x100: Endpoint
//      +0x200: Softpll
//      +0x300: PPS gen
//      +0x400: Syscon
//      +0x500: UART
//      +0x600: OneWire
//      +0x700: Auxillary space (Etherbone config, etc)
//      +0x800: WRPC diagnostics registers

module xwr_core
  #(
    //if set to 1, then blocks in PCS use smaller calibration counter to speed
    //up simulation
    parameter g_simulation                = 0,
    // set to false to reduce the number of information printed during simulation
    parameter g_verbose                   = 1,
    parameter g_with_external_clock_input = 1,
    parameter g_ram_address_space_size_kb = 128,

    //
    parameter g_board_name                = "NA  ",
    parameter g_flash_secsz_kb            = 256,        // default for SVEC (M25P128)
    parameter g_flash_sdbfs_baddr         = 'h600000, // default for SVEC (M25P128)
    parameter g_phys_uart                 = 1,
    parameter g_with_phys_uart_fifo       = 0,
    parameter g_phys_uart_tx_fifo_size    = 1024,
    parameter g_phys_uart_rx_fifo_size    = 1024,
    parameter g_virtual_uart              = 1,
    parameter g_aux_clks                  = 0,
    parameter g_ep_rxbuf_size             = 1024,
    parameter g_tx_runt_padding           = 1,
    parameter g_dpram_initf               = "",
    parameter g_dpram_size                = 131072/4,  //in 32-bit words
    parameter g_use_platform_specific_dpram = 0,
    parameter g_interface_mode            = "PIPELINED",
    parameter g_address_granularity       = "BYTE",
    parameter g_aux_sdb                   = "c_wrc_periph3_sdb",
    parameter g_softpll_enable_debugger   = 0,
    parameter g_softpll_use_sampled_ref_clocks = 0,
    parameter g_softpll_reverse_dmtds     = 0,
    parameter g_vuart_fifo_size           = 1024,
    parameter g_pcs_16bit                 = 0,
    parameter g_records_for_phy           = 0,
    parameter g_diag_id                   = 0,
    parameter g_diag_ver                  = 0,
    parameter g_diag_ro_size              = 0,
    parameter g_diag_rw_size              = 0,
    parameter g_dac_bits                  = 16,
    parameter g_softpll_aux_channel_config = "c_softpll_default_channels_config",
    parameter g_with_clock_freq_monitor   = 1,
    parameter g_hwbld_date                = 0,
    parameter c_wishbone_address_width    = 32,
    parameter c_wishbone_data_width       = 32
    )
   (
    //////////////////////////////////////////////////////////////////////////-
    // Clocks/resets
    //////////////////////////////////////////////////////////////////////////-

    // system reference clock (any frequency <= f(clk_ref_i))
    input wire clk_sys_i,

    // DDMTD offset clock (125.x MHz)
    input wire clk_dmtd_i,
    input wire clk_dmtd_over_i, // := '0',

    // Timing reference (125 MHz)
    input wire clk_ref_i ,

    // Aux clocks (i.e. the FMC clock), which can be disciplined by the WR Core
    input wire [g_aux_clks-1 : 0] clk_aux_i , //:= (others ('0'),

    input wire clk_ext_mul_i,  //:= '0',
    input wire clk_ext_mul_locked_i,  // := '1',
    input wire clk_ext_stopped_i,  // := '0',
    input wire clk_ext_rst_o,

    // External 10 MHz reference (cesium, GPSDO, etc.), used in Grandmaster mode
    input wire clk_ext_i,  //:= '0',

    // External PPS input (cesium, GPSDO, etc.), used in Grandmaster mode
    input wire pps_ext_i,  // := '0',

    input wire rst_n_i,

    ////////////////////////////////////////-
    //Timing system
    ////////////////////////////////////////-
    output wire dac_hpll_load_p1_o,
    output wire [g_dac_bits-1 : 0] dac_hpll_data_o    ,

    output wire dac_dpll_load_p1_o,
    output wire [g_dac_bits-1 : 0] dac_dpll_data_o    ,

    // PHY I/f
    input wire phy_ref_clk_i,

    output wire [(g_pcs_16bit*8)+ 7 : 0] phy_tx_data_o      ,
    output wire [g_pcs_16bit : 0] phy_tx_k_o         ,
    input wire phy_tx_disparity_i,
    input wire phy_tx_enc_err_i,

    input wire [(g_pcs_16bit*8)+ 7 : 0] phy_rx_data_i     ,
    input wire phy_rx_rbclk_i,
    input wire [g_pcs_16bit : 0] phy_rx_k_i        ,
    input wire phy_rx_enc_err_i,
    input wire [g_pcs_16bit+3 : 0] phy_rx_bitslide_i ,

    output wire phy_rst_o,
    input wire phy_rdy_i,  //:= '1',
    output wire phy_loopen_o,
    output wire [2 : 0] phy_loopen_vec_o     ,
    output wire [2 : 0] phy_tx_prbs_sel_o    ,
    input wire phy_sfp_tx_fault_i,  //:= '0',
    input wire phy_sfp_los_i,  // := '0',
    output wire phy_sfp_tx_disable_o,

    input wire phy_rx_rbclk_sampled_i ,

    // clk_sys_i domain!
    output wire phy_mdio_master_cyc_o,
    output wire phy_mdio_master_stb_o,
    output wire phy_mdio_master_we_o,
    output wire [31 : 0] phy_mdio_master_dat_o ,
    output wire [3 : 0] phy_mdio_master_sel_o , // := "0000",
    output wire [31 : 0] phy_mdio_master_adr_o ,
    input wire phy_mdio_master_ack_i,  // := '0',
    input wire phy_mdio_master_stall_i,  // := '0',
    input wire [31 : 0] phy_mdio_master_dat_i , // := x"00000000",

    ////////////////////////////////////////-
    //GPIO
    ////////////////////////////////////////-
    output wire led_act_o,
    output wire led_link_o,
    output wire scl_o,
    input wire scl_i,  // := '1',
    output wire sda_o,
    input wire sda_i,  // := '1',
    output wire sfp_scl_o,
    input wire sfp_scl_i,  // := '1',
    output wire sfp_sda_o,
    input wire sfp_sda_i,  // := '1',
    input wire sfp_det_i,  // := '1',
    input wire btn1_i,  // := '1',
    input wire btn2_i,  // := '1',
    output wire spi_sclk_o,
    output wire spi_ncs_o,
    output wire spi_mosi_o,
    input wire spi_miso_i,  //:= '0',

    ////////////////////////////////////////-
    //UART
    ////////////////////////////////////////-
    input wire uart_rxd_i,  //:= '1',
    output wire uart_txd_o,

    ////////////////////////////////////////-
    // 1-wire
    ////////////////////////////////////////-
    output wire [1:0] owr_pwren_o ,
    output wire [1:0] owr_en_o    ,
    input wire [1:0] owr_i       , // := (others ('1'),

    ////////////////////////////////////////-
    //External WB interface
    ////////////////////////////////////////-
    input wire [c_wishbone_address_width-1 : 0] wb_adr_i   , //   := (others ('0'),
    input wire [c_wishbone_data_width-1 : 0] wb_dat_i   , //      := (others ('0'),
    output wire [c_wishbone_data_width-1 : 0] wb_dat_o   ,
    input wire [c_wishbone_address_width/8-1 : 0] wb_sel_i   , // := (others ('0'),
    input wire wb_we_i,  //:= '0',
    input wire wb_cyc_i,  //:= '0',
    input wire wb_stb_i,  //:= '0',
    output wire wb_ack_o,
    output wire wb_err_o,
    output wire wb_rty_o,
    output wire wb_stall_o,

    ////////////////////////////////////////-
    // Auxillary WB master
    ////////////////////////////////////////-
    output wire [c_wishbone_address_width-1 : 0] aux_adr_o   ,
    output wire [c_wishbone_data_width-1 : 0] aux_dat_o   ,
    input wire [c_wishbone_data_width-1 : 0] aux_dat_i   ,
    output wire [c_wishbone_address_width/8-1 : 0] aux_sel_o   ,
    output wire aux_we_o,
    output wire aux_cyc_o,
    output wire aux_stb_o,
    input wire aux_ack_i,  // := '1',
    input wire aux_stall_i,  // := '0',

    ////////////////////////////////////////-
    // External Fabric I/F
    ////////////////////////////////////////-
    input wire [1 : 0] ext_snk_adr_i   , //  := "00",
    input wire [15 : 0] ext_snk_dat_i   , // := x"0000",
    input wire [1 : 0] ext_snk_sel_i   , //  := "00",
    input wire ext_snk_cyc_i,  //:= '0',
    input wire ext_snk_we_i,  //:= '0',
    input wire ext_snk_stb_i,  //:= '0',
    output wire ext_snk_ack_o,
    output wire ext_snk_err_o,
    output wire ext_snk_stall_o,

    output wire  [1 : 0] ext_src_adr_o  ,
    output wire [15 : 0] ext_src_dat_o   ,
    output wire [1 : 0] ext_src_sel_o   ,
    output wire ext_src_cyc_o,
    output wire ext_src_stb_o,
    output wire ext_src_we_o,
    input wire ext_src_ack_i,  //:= '1',
    input wire ext_src_err_i,  //:= '0',
    input wire ext_src_stall_i,  //:= '0',

    //////////////////////////////////////////
    // External TX Timestamp I/F
    //////////////////////////////////////////
    output wire [4 : 0] txtsu_port_id_o      ,
    output wire [15 : 0] txtsu_frame_id_o     ,
    output wire [31 : 0] txtsu_ts_value_o     ,
    output wire txtsu_ts_incorrect_o,
    output wire txtsu_stb_o,
    input wire txtsu_ack_i,  // := '1',

    ////////////////////////////////////////-
    // Timestamp helper signals, used for Absolute Calibration
    ////////////////////////////////////////-
    output wire abscal_txts_o,
    output wire abscal_rxts_o,

    ////////////////////////////////////////-
    // Pause Frame Control
    ////////////////////////////////////////-
    input wire fc_tx_pause_req_i,  // := '0',
    input wire [15 : 0] fc_tx_pause_delay_i , // := x"0000",
    output wire fc_tx_pause_ready_o,

    ////////////////////////////////////////-
    // Timecode/Servo Control
    ////////////////////////////////////////-

    output wire tm_link_up_o,
    // DAC Control
    output wire [31 : 0] tm_dac_value_o       ,
    output wire [g_aux_clks-1 : 0] tm_dac_wr_o          ,
    // Aux clock lock enable
    input wire [g_aux_clks-1 : 0] tm_clk_aux_lock_en_i , // := (others ('0'),
    // Aux clock locked flag
    output wire [g_aux_clks-1 : 0] tm_clk_aux_locked_o  ,
    // Timecode output
    output wire tm_time_valid_o,
    output wire [39 : 0] tm_tai_o             ,
    output wire [27 : 0] tm_cycles_o          ,
    // 1PPS output
    output wire pps_csync_o,
    output wire pps_valid_o,
    output wire pps_p_o,
    output wire pps_led_o,

    output wire rst_aux_n_o,

    output wire link_ok_o
    );

  WRPC
    #(
      .g_simulation                (g_simulation),
      .g_verbose                   (g_verbose),
      .g_ram_address_space_size_kb (g_ram_address_space_size_kb),
      .g_board_name                (g_board_name),
      .g_flash_secsz_kb            (g_flash_secsz_kb),
      .g_flash_sdbfs_baddr         (g_flash_sdbfs_baddr),
      .g_phys_uart                 (g_phys_uart),
      .g_with_phys_uart_fifo       (g_with_phys_uart_fifo),
      .g_phys_uart_tx_fifo_size    (g_phys_uart_tx_fifo_size),
      .g_phys_uart_rx_fifo_size    (g_phys_uart_rx_fifo_size),
      .g_virtual_uart              (g_virtual_uart),
      .g_rx_buffer_size            (g_ep_rxbuf_size),
      .g_tx_runt_padding           (g_tx_runt_padding),
      .g_with_external_clock_input (g_with_external_clock_input),
      .g_aux_clks                  (g_aux_clks),
      .g_dpram_initf               (g_dpram_initf),
      .g_dpram_size                (g_dpram_size),
      .g_interface_mode            (g_interface_mode),
      .g_address_granularity       (g_address_granularity),
      .g_aux_sdb                   (g_aux_sdb),
      .g_softpll_enable_debugger   (g_softpll_enable_debugger),
      .g_softpll_use_sampled_ref_clocks (g_softpll_use_sampled_ref_clocks),
      .g_softpll_reverse_dmtds (g_softpll_reverse_dmtds),
      .g_vuart_fifo_size           (g_vuart_fifo_size),
      .g_pcs_16bit                 (g_pcs_16bit),
      .g_records_for_phy           (g_records_for_phy),
      .g_diag_id                   (g_diag_id),
      .g_diag_ver                  (g_diag_ver),
      .g_diag_ro_size              (g_diag_ro_size),
      .g_diag_rw_size              (g_diag_rw_size),
      .g_dac_bits                  (g_dac_bits),
      .g_use_platform_specific_dpram (g_use_platform_specific_dpram),
      .g_softpll_aux_channel_config (g_softpll_aux_channel_config),
      .g_with_clock_freq_monitor   (g_with_clock_freq_monitor),
      .g_hwbld_date                (g_hwbld_date)
      )
    wr_core (
      .clk_sys_i     (clk_sys_i),
      .clk_dmtd_i    (clk_dmtd_i),
      .clk_dmtd_over_i (clk_dmtd_over_i),
      .clk_ref_i     (clk_ref_i),
      .clk_aux_i     (clk_aux_i),
      .clk_ext_i     (clk_ext_i),
      .clk_ext_mul_i (clk_ext_mul_i),
      .clk_ext_mul_locked_i  (clk_ext_mul_locked_i),
      .clk_ext_stopped_i (clk_ext_stopped_i),
      .clk_ext_rst_o     (clk_ext_rst_o),
      .pps_ext_i     (pps_ext_i),
      .rst_n_i       (rst_n_i),

      .dac_hpll_load_p1_o   (dac_hpll_load_p1_o),
      .dac_hpll_data_o      (dac_hpll_data_o),
      .dac_dpll_load_p1_o   (dac_dpll_load_p1_o),
      .dac_dpll_data_o      (dac_dpll_data_o),

      .phy_ref_clk_i        (phy_ref_clk_i),
      .phy_tx_data_o        (phy_tx_data_o),
      .phy_tx_k_o           (phy_tx_k_o),
      .phy_tx_disparity_i   (phy_tx_disparity_i),
      .phy_tx_enc_err_i     (phy_tx_enc_err_i),
      .phy_rx_data_i        (phy_rx_data_i),
      .phy_rx_rbclk_i       (phy_rx_rbclk_i),
      .phy_rx_rbclk_sampled_i (phy_rx_rbclk_sampled_i),
      .phy_rx_k_i           (phy_rx_k_i),
      .phy_rx_enc_err_i     (phy_rx_enc_err_i),
      .phy_rx_bitslide_i    (phy_rx_bitslide_i),
      .phy_rst_o            (phy_rst_o),
      .phy_rdy_i            (phy_rdy_i),
      .phy_loopen_o         (phy_loopen_o),
      .phy_loopen_vec_o     (phy_loopen_vec_o),
      .phy_tx_prbs_sel_o    (phy_tx_prbs_sel_o),
      .phy_sfp_tx_fault_i   (phy_sfp_tx_fault_i),
      .phy_sfp_los_i        (phy_sfp_los_i),
      .phy_sfp_tx_disable_o (phy_sfp_tx_disable_o),

      .phy_mdio_master_cyc_o  (phy_mdio_master_cyc_o),
      .phy_mdio_master_stb_o  (phy_mdio_master_stb_o),
      .phy_mdio_master_we_o   (phy_mdio_master_we_o),
      .phy_mdio_master_sel_o  (phy_mdio_master_sel_o),
      .phy_mdio_master_adr_o  (phy_mdio_master_adr_o),
      .phy_mdio_master_dat_o    (phy_mdio_master_dat_o),
      .phy_mdio_master_dat_i    (phy_mdio_master_dat_i),
      .phy_mdio_master_stall_i  (phy_mdio_master_stall_i),
      .phy_mdio_master_ack_i    (phy_mdio_master_ack_i),

      .led_act_o  (led_act_o),
      .led_link_o (led_link_o),
      .scl_o      (scl_o),
      .scl_i      (scl_i),
      .sda_o      (sda_o),
      .sda_i      (sda_i),
      .sfp_scl_o  (sfp_scl_o),
      .sfp_scl_i  (sfp_scl_i),
      .sfp_sda_o  (sfp_sda_o),
      .sfp_sda_i  (sfp_sda_i),
      .sfp_det_i  (sfp_det_i),
      .btn1_i     (btn1_i),
      .btn2_i     (btn2_i),
      .spi_sclk_o (spi_sclk_o),
      .spi_ncs_o  (spi_ncs_o),
      .spi_mosi_o (spi_mosi_o),
      .spi_miso_i (spi_miso_i),
      .uart_rxd_i (uart_rxd_i),
      .uart_txd_o (uart_txd_o),

      .owr_pwren_o (owr_pwren_o),
      .owr_en_o    (owr_en_o),
      .owr_i       (owr_i),

      .wb_adr_i   (wb_adr_i),
      .wb_dat_i   (wb_dat_i),
      .wb_dat_o   (wb_dat_o),
      .wb_sel_i   (wb_sel_i),
      .wb_we_i    (wb_we_i),
      .wb_cyc_i   (wb_cyc_i),
      .wb_stb_i   (wb_stb_i),
      .wb_ack_o   (wb_ack_o),
      .wb_err_o   (wb_err_o),
      .wb_rty_o   (wb_rty_o),
      .wb_stall_o (wb_stall_o),

      .aux_adr_o   (aux_adr_o),
      .aux_dat_o   (aux_dat_o),
      .aux_sel_o   (aux_sel_o),
      .aux_cyc_o   (aux_cyc_o),
      .aux_stb_o   (aux_stb_o),
      .aux_we_o    (aux_we_o),
      .aux_stall_i (aux_stall_i),
      .aux_ack_i   (aux_ack_i),
      .aux_dat_i   (aux_dat_i),

      .ext_snk_adr_i   (ext_snk_adr_i),
      .ext_snk_dat_i   (ext_snk_dat_i),
      .ext_snk_sel_i   (ext_snk_sel_i),
      .ext_snk_cyc_i   (ext_snk_cyc_i),
      .ext_snk_we_i    (ext_snk_we_i),
      .ext_snk_stb_i   (ext_snk_stb_i),
      .ext_snk_ack_o   (ext_snk_ack_o),
      .ext_snk_err_o   (ext_snk_err_o),
      .ext_snk_stall_o (ext_snk_stall_o),

      .ext_src_adr_o   (ext_src_adr_o),
      .ext_src_dat_o   (ext_src_dat_o),
      .ext_src_sel_o   (ext_src_sel_o),
      .ext_src_cyc_o   (ext_src_cyc_o),
      .ext_src_stb_o   (ext_src_stb_o),
      .ext_src_we_o    (ext_src_we_o),
      .ext_src_ack_i   (ext_src_ack_i),
      .ext_src_err_i   (ext_src_err_i),
      .ext_src_stall_i (ext_src_stall_i),

      .txtsu_port_id_o      (txtsu_port_id_o[4 : 0]),
      .txtsu_frame_id_o     (txtsu_frame_id_o),
      .txtsu_ts_value_o     (txtsu_ts_value_o),
      .txtsu_ts_incorrect_o (txtsu_ts_incorrect_o),
      .txtsu_stb_o          (txtsu_stb_o),
      .txtsu_ack_i          (txtsu_ack_i),

      .abscal_txts_o        (abscal_txts_o),
      .abscal_rxts_o        (abscal_rxts_o),

      .fc_tx_pause_req_i    (fc_tx_pause_req_i),
      .fc_tx_pause_delay_i  (fc_tx_pause_delay_i),
      .fc_tx_pause_ready_o  (fc_tx_pause_ready_o),

      .tm_link_up_o         (tm_link_up_o),
      .tm_dac_value_o       (tm_dac_value_o),
      .tm_dac_wr_o          (tm_dac_wr_o),
      .tm_clk_aux_lock_en_i (tm_clk_aux_lock_en_i),
      .tm_clk_aux_locked_o  (tm_clk_aux_locked_o),
      .tm_time_valid_o      (tm_time_valid_o),
      .tm_tai_o             (tm_tai_o),
      .tm_cycles_o          (tm_cycles_o),
      .pps_csync_o          (pps_csync_o),
      .pps_valid_o          (pps_valid_o),
      .pps_p_o              (pps_p_o),
      .pps_led_o            (pps_led_o),

      .rst_aux_n_o (rst_aux_n_o),

      .link_ok_o (link_ok_o)
      );

// assign txtsu_port_id_o[5] = 0;

endmodule
