##################
# Clocks
##################
create_clock -period 8.000 -name wr_clk_helper_125m -waveform {0.000  4.000} [get_ports {wr_clk_helper_125m_p_i}]
create_clock -period 8.000 -name wr_clk_main_125m   -waveform {0.000  4.000} [get_ports {wr_clk_main_125m_p_i}]
create_clock -period 8.000 -name wr_clk_sfp_125m    -waveform {0.000  4.000} [get_ports {wr_clk_sfp_125m_p_i}]
create_clock -period 16.000 -name gth_txclk         -waveform {0.000 8.000} [get_nets cmp_xwrc_board_pxie_fmc/cmp_xwrc_platform/gen_phy_zynqus.cmp_gth/tx_out_clk_o]
create_clock -period 16.000 -name gth_rxclk         -waveform {0.000 8.000} [get_nets cmp_xwrc_board_pxie_fmc/cmp_xwrc_platform/gen_phy_zynqus.cmp_gth/rx_rbclk_o]

create_generated_clock -name clk_dmtd -source [get_ports {wr_clk_helper_125m_p_i}] -divide_by 2 [get_pins cmp_xwrc_board_pxie_fmc/cmp_xwrc_platform/gen_default_plls.gen_zynqus_default_plls.cmp_clk_dmtd_buf_o/O]

set_clock_groups -asynchronous -group {wr_clk_main_125m wr_clk_sfp_125m} -group {wr_clk_helper_125m clk_dmtd} -group {gth_txclk} -group {gth_rxclk}


##################
# I/O constraints
##################

set_property PACKAGE_PIN AU9 [get_ports {user_led_o[0]}]
set_property PACKAGE_PIN AW9 [get_ports {user_led_o[1]}]
set_property PACKAGE_PIN AV9 [get_ports {user_led_o[2]}]
set_property PACKAGE_PIN AW10 [get_ports eeprom_scl_b]
set_property PACKAGE_PIN AW11 [get_ports eeprom_sda_b]
set_property PACKAGE_PIN K14 [get_ports pll25dac_cs_n_o]
set_property PACKAGE_PIN L12 [get_ports pll20dac_cs_n_o]
set_property PACKAGE_PIN K13 [get_ports plldac_din_o]
set_property PACKAGE_PIN J14 [get_ports plldac_sclk_o]
set_property PACKAGE_PIN A11 [get_ports pps_p_o]
set_property PACKAGE_PIN K12 [get_ports ps_por_i]
set_property PACKAGE_PIN G10 [get_ports sfp_det_i]
set_property PACKAGE_PIN K10 [get_ports sfp_los_i]
set_property PACKAGE_PIN AM2 [get_ports sfp_rxp_i]
set_property PACKAGE_PIN AH10 [get_ports wr_clk_sfp_125m_p_i]
set_property PACKAGE_PIN AU21 [get_ports sfp_scl_b]
set_property PACKAGE_PIN AT21 [get_ports sfp_sda_b]
set_property PACKAGE_PIN D12 [get_ports sfp_tx_disable_o]
set_property PACKAGE_PIN C12 [get_ports uart_txd_o]
set_property PACKAGE_PIN C14 [get_ports uart_rxd_i]
set_property PACKAGE_PIN AP20 [get_ports wr_clk_helper_125m_p_i]
set_property PACKAGE_PIN AN19 [get_ports wr_clk_main_125m_p_i]

set_property IOSTANDARD LVCMOS33 [get_ports pll20dac_cs_n_o]
set_property IOSTANDARD LVCMOS33 [get_ports pll25dac_cs_n_o]
set_property IOSTANDARD LVCMOS18 [get_ports eeprom_sda_b]
set_property IOSTANDARD LVCMOS18 [get_ports eeprom_scl_b]
set_property IOSTANDARD LVCMOS18 [get_ports {user_led_o[0]}]
set_property IOSTANDARD LVCMOS18 [get_ports {user_led_o[1]}]
set_property IOSTANDARD LVCMOS18 [get_ports {user_led_o[2]}]
set_property IOSTANDARD LVCMOS33 [get_ports plldac_din_o]
set_property IOSTANDARD LVCMOS33 [get_ports plldac_sclk_o]
set_property IOSTANDARD LVCMOS33 [get_ports pps_p_o]
set_property IOSTANDARD LVCMOS33 [get_ports ps_por_i]
set_property IOSTANDARD LVCMOS33 [get_ports sfp_det_i]
set_property IOSTANDARD LVCMOS18 [get_ports sfp_scl_b]
set_property IOSTANDARD LVCMOS33 [get_ports sfp_los_i]
set_property IOSTANDARD LVCMOS18 [get_ports sfp_sda_b]
set_property IOSTANDARD LVCMOS33 [get_ports sfp_tx_disable_o]
set_property IOSTANDARD LVCMOS33 [get_ports uart_txd_o]
set_property IOSTANDARD LVCMOS33 [get_ports uart_rxd_i]
set_property IOSTANDARD LVDS [get_ports wr_clk_helper_125m_p_i]
set_property IOSTANDARD LVDS [get_ports wr_clk_main_125m_p_i]

set_property OFFCHIP_TERM NONE [get_ports eeprom_scl_b]
set_property OFFCHIP_TERM NONE [get_ports eeprom_sda_b]
set_property OFFCHIP_TERM NONE [get_ports pll20dac_cs_n_o]
set_property OFFCHIP_TERM NONE [get_ports pll25dac_cs_n_o]
set_property OFFCHIP_TERM NONE [get_ports plldac_din_o]
set_property OFFCHIP_TERM NONE [get_ports plldac_sclk_o]
set_property OFFCHIP_TERM NONE [get_ports pps_p_o]
set_property OFFCHIP_TERM NONE [get_ports sfp_scl_b]
set_property OFFCHIP_TERM NONE [get_ports sfp_sda_b]
set_property OFFCHIP_TERM NONE [get_ports sfp_tx_disable_o]
set_property OFFCHIP_TERM NONE [get_ports uart_txd_o]
set_property OFFCHIP_TERM NONE [get_ports user_led_o[2]]
set_property OFFCHIP_TERM NONE [get_ports user_led_o[1]]
set_property OFFCHIP_TERM NONE [get_ports user_led_o[0]]


#revert back to original instance
current_instance -quiet
