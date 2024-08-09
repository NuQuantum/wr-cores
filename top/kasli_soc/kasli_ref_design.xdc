# GTP clock
set_property PACKAGE_PIN U5 [get_ports clk_125m_gtp_n]
set_property PACKAGE_PIN U6 [get_ports clk_125m_gtp_p]

# main PLL
# input
set_property PACKAGE_PIN AD23 [get_ports clk_125m_pllref_p]
#set_property PACKAGE_PIN AD24 [get_ports clk_125m_pllref_n]
set_property IOSTANDARD LVDS_25 [get_ports {clk_125m_pllref_p}]
#set_property IOSTANDARD LVDS_25 [get_ports {clk_ref_125m_n}]
#output
set_property PACKAGE_PIN G7 [get_ports clk_ref_125m_p]
set_property PACKAGE_PIN F7 [get_ports clk_ref_125m_n]
#set_property IOSTANDARD LVDS_25 [get_ports {clk_ref_125m_p}]
#set_property IOSTANDARD LVDS_25 [get_ports {clk_ref_125m_n}]
set_property DIFF_TERM TRUE [get_ports {clk_ref_125m_p}]
set_property DIFF_TERM TRUE [get_ports {clk_ref_125m_n}]

# helper PLL
set_property LOC AC23 [get_ports {ddmtd_helper_clk_p}]
#set_property LOC AC24 [get_ports {ddmtd_helper_clk_n}]
set_property IOSTANDARD LVDS_25 [get_ports {ddmtd_helper_clk_p}]
set_property IOSTANDARD LVDS_25 [get_ports {ddmtd_helper_clk_n}]
set_property DIFF_TERM TRUE [get_ports {ddmtd_helper_clk_p}]
set_property DIFF_TERM TRUE [get_ports {ddmtd_helper_clk_n}]

# Aux 10 MHz clock
set_property PACKAGE_PIN AD20 [get_ports clk_10m_ref_p]
set_property PACKAGE_PIN AD21 [get_ports clk_10m_ref_n]
set_property IOSTANDARD LVDS_25 [get_ports {clk_10m_ref_p}]
set_property IOSTANDARD LVDS_25 [get_ports {clk_10m_ref_n}]
set_property DIFF_TERM TRUE [get_ports {clk_10m_ref_p}]
set_property DIFF_TERM TRUE [get_ports {clk_10m_ref_n}]


# sfp1
set_property PACKAGE_PIN Y4 [get_ports SFP_rxp]
set_property PACKAGE_PIN Y3 [get_ports SFP_rxn]
set_property PACKAGE_PIN W2 [get_ports SFP_txp]
set_property PACKAGE_PIN U1 [get_ports SFP_txn]

# dio 0
set_property PACKAGE_PIN AD14 [get_ports dio0_p  ]
set_property PACKAGE_PIN AC14 [get_ports dio0_n  ]
set_property PACKAGE_PIN AF17 [get_ports dio0_p_1]
set_property PACKAGE_PIN AE17 [get_ports dio0_n_1]
set_property PACKAGE_PIN AA17 [get_ports dio0_p_2]
set_property PACKAGE_PIN Y17  [get_ports dio0_n_2]
set_property PACKAGE_PIN AB16 [get_ports dio0_p_3]
set_property PACKAGE_PIN AB17 [get_ports dio0_n_3]
set_property PACKAGE_PIN AC16 [get_ports dio0_p_4]
set_property PACKAGE_PIN AC17 [get_ports dio0_n_4]
set_property PACKAGE_PIN AD15 [get_ports dio0_p_5]
set_property PACKAGE_PIN AD16 [get_ports dio0_n_5]
set_property PACKAGE_PIN Y15 [get_ports dio0_p_6]
set_property PACKAGE_PIN Y16 [get_ports dio0_n_6]
set_property PACKAGE_PIN W15 [get_ports dio0_p_7]
set_property PACKAGE_PIN W16 [get_ports dio0_n_7]

set_property IOSTANDARD LVDS_25 [get_ports {dio0_*}]

# dio 1 groups 1-4
set_property PACKAGE_PIN AD26 [get_ports pulsar5_spi_p_clk ]
#set_property PACKAGE_PIN AB22 [get_ports pulsar5_spi_n_clk ]
set_property PACKAGE_PIN AF24 [get_ports pulsar5_spi_p_cs_n]
#set_property PACKAGE_PIN AA25 [get_ports pulsar5_spi_n_cs_n]
set_property PACKAGE_PIN AD25 [get_ports pulsar5_spi_p_mosi]
#set_property PACKAGE_PIN AB21 [get_ports pulsar5_spi_n_mosi]
set_property PACKAGE_PIN AF25 [get_ports pulsar5_spi_p_miso]
#set_property PACKAGE_PIN AB25 [get_ports pulsar5_spi_n_miso]

set_property IOSTANDARD LVDS_25 [get_ports {pulsar5_spi_*}]

# UART
set_property PACKAGE_PIN AA18 [get_ports UART_rxd]
set_property PACKAGE_PIN Y18 [get_ports UART_txd]
set_property IOSTANDARD LVCMOS25 [get_ports {UART_*}]

# EEPROM
set_property PACKAGE_PIN C8 [get_ports eeprom_i2c_scl_io]
set_property PACKAGE_PIN C7 [get_ports eeprom_i2c_sda_io]

set_property IOSTANDARD LVCMOS18 [get_ports eeprom_i2c_sda_io]
set_property IOSTANDARD LVCMOS18 [get_ports eeprom_i2c_scl_io]
set_property SLEW FAST [get_ports eeprom_i2c_scl_io]
set_property SLEW FAST [get_ports eeprom_i2c_sda_io]

# unresovled

set_false_path -quiet -through [get_pins -filter {REF_PIN_NAME == OQ || REF_PIN_NAME == TQ} -of [get_cells -filter {REF_NAME == OSERDESE2}]] -to [get_pins -filter {REF_PIN_NAME == D} -of [get_cells -filter {REF_NAME == ISERDESE2}]]

create_clock -name clk125_gtp_p -period 8.0 [get_nets clk_125m_gtp_p]

create_clock -name clk_ref_125m -period 8.0 [get_nets clk_125m_pllref_p]

set_clock_groups -group [get_clocks -include_generated_clocks -of [get_nets bootstrap_clk]] -group [get_clocks -include_generated_clocks -of [get_nets sys_clk]] -asynchronous

set_false_path -quiet -to [get_nets -filter {mr_ff == TRUE}]

set_false_path -quiet -to [get_pins -filter {REF_PIN_NAME == PRE} -of [get_cells -filter {ars_ff1 == TRUE || ars_ff2 == TRUE}]]

set_max_delay 2 -quiet -from [get_pins -filter {REF_PIN_NAME == Q} -of [get_cells -filter {ars_ff1 == TRUE}]] -to [get_pins -filter {REF_PIN_NAME == D} -of [get_cells -filter {ars_ff2 == TRUE}]]