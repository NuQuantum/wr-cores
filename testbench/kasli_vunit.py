from os import environ
from os.path import join, dirname
from vunit import VUnit

ui = VUnit.from_argv(compile_builtins=False)
ui.add_vhdl_builtins()
ui.add_verilog_builtins()
ui.add_osvvm()
ui.add_verification_components()

unisim = ui.add_library("unisim", '93')
unimacro = ui.add_library("unimacro", '93')
unifast = ui.add_library("unifast", '93')
secureip =  ui.add_library("secureip")
#vcomponents = ui.add_library("vcomponents", '93')
wr_lib = ui.add_library("wr_lib")

board_path = join(dirname(__file__), "../board")
wr_path = join(dirname(__file__), "../modules")
urv_path = join(dirname(__file__), "../ip_cores/urv-core")
general_path = join(dirname(__file__), "../ip_cores/general-cores/modules")
etherbone_path = join(dirname(__file__), "../ip_cores/etherbone-core/hdl")
platform_path = join(dirname(__file__), "../platform/xilinx")
testbench_path = join(dirname(__file__), "./")
cute_path = join(dirname(__file__), "../../cute-a7-wrf/src")

# xilinx vivado
unisim_path = join(environ["XILINX_VIVADO"], "data/vhdl/src/unisims")
unimacro_path = join(environ["XILINX_VIVADO"], "data/vhdl/src/unimacro")
unifast_path = join(environ["XILINX_VIVADO"], "data/vhdl/src/unifast")
secureip_path = join(environ["XILINX_VIVADO"], "data/secureip")


# xilinx ISE
#unisim_path = join(environ["XILINX"], "vhdl/src/unisims")
#unimacro_path = join(environ["XILINX"], "vhdl/src/unimacro")

# compile secureip
secureip.add_source_files(join(secureip_path, "gtxe2_channel_fast", "*.vp"))
secureip.add_source_files(join(secureip_path, "gtxe2_channel", "*.vp"))
secureip.add_source_files(join(secureip_path, "gtxe2_common", "*.vp"))
secureip.add_source_files(join(secureip_path, "pcie_2_1", "*.vp"))
secureip.add_source_files(join(secureip_path, "iserdese2", "*.vp"))
secureip.add_source_files(join(secureip_path, "oserdese2", "*.vp"))
secureip.add_source_files(join(secureip_path, "in_fifo", "*.vp"))
secureip.add_source_files(join(secureip_path, "out_fifo", "*.vp"))
secureip.add_source_files(join(secureip_path, "phy_control", "*.vp"))
secureip.add_source_files(join(secureip_path, "phaser_in", "*.vp"))
secureip.add_source_files(join(secureip_path, "phaser_out", "*.vp"))
secureip.add_source_files(join(secureip_path, "gtpe2_channel", "*.vp"))

# compile unisim
unisim.add_source_files(join(unisim_path, "unisim_VPKG.vhd"))
unisim.add_source_files(join(unisim_path, "unisim_VCOMP.vhd"))
unisim.add_source_files(join(unisim_path, "primitive", "*.vhd"))
unisim.add_source_files(join(unisim_path, "secureip", "*.vhd"))

# compile unimacro
unimacro.add_source_files(join(unimacro_path, "unimacro_VCOMP.vhd"))

#compile unifast
unifast.add_source_files(join(unifast_path, "primitive", "*.vhd"))
unifast.add_source_files(join(unifast_path, "secureip", "*.vhd"))


#riscV build
wr_lib.add_source_files(join(urv_path, "rtl", "urv_cpu.v"))
wr_lib.add_source_files(join(urv_path, "rtl", "urv_csr.v"))
wr_lib.add_source_files(join(urv_path, "rtl", "urv_fetch.v"))
wr_lib.add_source_files(join(urv_path, "rtl", "urv_decode.v"))
wr_lib.add_source_files(join(urv_path, "rtl", "urv_timer.v"))
wr_lib.add_source_files(join(urv_path, "rtl", "urv_writeback.v"))
wr_lib.add_source_files(join(urv_path, "rtl", "urv_divide.v"))
wr_lib.add_source_files(join(urv_path, "rtl", "urv_regfile.v"))
wr_lib.add_source_files(join(urv_path, "rtl", "urv_exceptions.v"))
wr_lib.add_source_files(join(urv_path, "rtl", "urv_multiply.v"))
wr_lib.add_source_files(join(urv_path, "rtl", "urv_config.v"))
wr_lib.add_source_files(join(urv_path, "rtl", "urv_ecc.v"))
wr_lib.add_source_files(join(urv_path, "rtl", "urv_exec.v"))
wr_lib.add_source_files(join(urv_path, "rtl", "urv_defs.v"))
wr_lib.add_source_files(join(urv_path, "rtl", "urv_iram.v"))
wr_lib.add_source_files(join(urv_path, "rtl", "urv_shifter.v"))

wr_lib.add_source_files(join(urv_path, "rtl", "urv_pkg.vhd"))

# general cores
wr_lib.add_source_files(join(general_path, "axi", "*.vhd"))
wr_lib.add_source_files(join(general_path, "common", "*.vhd"))

wr_lib.add_source_files(join(general_path, "genrams", "genram_pkg.vhd"))
wr_lib.add_source_files(join(general_path, "genrams", "memory_loader_pkg.vhd"))
wr_lib.add_source_files(join(general_path, "genrams/common", "*.vhd"))
wr_lib.add_source_files(join(general_path, "genrams/generic", "*.vhd"))
wr_lib.add_source_files(join(general_path, "genrams/xilinx", "*.vhd"))

wr_lib.add_source_files(join(general_path, "wishbone", "wishbone_pkg.vhd"))
wr_lib.add_source_files(join(general_path, "wishbone/wb_uart", "*.vhd"))
wr_lib.add_source_files(join(general_path, "wishbone/wb_onewire_master", "sockit_owm.v"))
wr_lib.add_source_files(join(general_path, "wishbone/wb_onewire_master", "*.vhd"))
wr_lib.add_source_files(join(general_path, "wishbone/wb_slave_adapter", "*.vhd"))
wr_lib.add_source_files(join(general_path, "wishbone/wb_clock_monitor", "*.vhd"))
wr_lib.add_source_files(join(general_path, "wishbone/wb_crossbar", "*.vhd"))
wr_lib.add_source_files(join(general_path, "wishbone/wbgen2", "*.vhd"))
wr_lib.add_source_files(join(general_path, "wishbone/wb_axi4lite_bridge", "*.vhd"))

# etherbone cores
wr_lib.add_source_files(join(etherbone_path, "eb_slave_core", "etherbone_pkg.vhd"))

# xilinx platform
wr_lib.add_source_files(join(platform_path, "wr_xilinx_pkg.vhd"))
wr_lib.add_source_files(join(platform_path, "wr_gtp_phy/family7-gtx", "whiterabbit_gtxe2_channel_wrapper_gt.vhd"))
wr_lib.add_source_files(join(platform_path, "wr_gtp_phy/family7-gtx", "wr_gtx_phy_family7.vhd"))
wr_lib.add_source_files(join(platform_path, "wr_gtp_phy", "gtp_bitslide.vhd"))
wr_lib.add_source_files(join(platform_path, "xwrc_platform_vivado.vhd"))
#wr_lib.add_source_files(join(platform_path, "xwrc_platform_xilinx.vhd"))
#wr_lib.add_source_files(join(platform_path, "wrc_platform_xilinx.vhd"))

# white rabbit cores
wr_lib.add_source_files(join(wr_path, "wr_tbi_phy", "disparity_gen_pkg.vhd"))
wr_lib.add_source_files(join(wr_path, "fabric", "wr_fabric_pkg.vhd"))
wr_lib.add_source_files(join(wr_path, "fabric", "xwrf_mux.vhd"))
wr_lib.add_source_files(join(wr_path, "wr_streamers", "*.vhd"))
wr_lib.add_source_files(join(wr_path, "wr_softpll_ng", "*.vhd"))
wr_lib.add_source_files(join(wr_path, "wr_mini_nic", "*.vhd"))
wr_lib.add_source_files(join(wr_path, "wr_pps_gen", "*.vhd"))
wr_lib.add_source_files(join(wr_path, "timing", "*.vhd"))
wr_lib.add_source_files(join(wr_path, "wr_dacs", "*.vhd"))

#wr_lib.add_source_files(join(wr_path, "wr_endpoint", "endpoint_pkg.vhd"))
#wr_lib.add_source_files(join(wr_path, "wr_endpoint", "endpoint_private_pkg.vhd"))
#wr_lib.add_source_files(join(wr_path, "wr_endpoint", "ep_crc32_pkg.vhd"))
#wr_lib.add_source_files(join(wr_path, "wr_endpoint", "ep_registers_pkg.vhd"))
#wr_lib.add_source_files(join(wr_path, "wr_endpoint", "ep_rx_wb_master.vhd"))
#wr_lib.add_source_files(join(wr_path, "wr_endpoint", "*.vhd"))

wr_lib.add_source_files(join(wr_path, "wr_endpoint", "endpoint_private_pkg.vhd"))
wr_lib.add_source_files(join(wr_path, "wr_endpoint", "ep_rx_pcs_8bit.vhd"))
wr_lib.add_source_files(join(wr_path, "wr_endpoint", "ep_tx_pcs_8bit.vhd"))
wr_lib.add_source_files(join(wr_path, "wr_endpoint", "ep_tx_pcs_16bit.vhd"))
wr_lib.add_source_files(join(wr_path, "wr_endpoint", "ep_rx_pcs_16bit.vhd"))
wr_lib.add_source_files(join(wr_path, "wr_endpoint", "ep_autonegotiation.vhd"))
wr_lib.add_source_files(join(wr_path, "wr_endpoint", "ep_mdio_regs.vhd"))
wr_lib.add_source_files(join(wr_path, "wr_endpoint", "ep_1000basex_pcs.vhd"))
wr_lib.add_source_files(join(wr_path, "wr_endpoint", "ep_rx_crc_size_check.vhd"))
wr_lib.add_source_files(join(wr_path, "wr_endpoint", "ep_rx_bypass_queue.vhd"))
wr_lib.add_source_files(join(wr_path, "wr_endpoint", "ep_rx_path.vhd"))
wr_lib.add_source_files(join(wr_path, "wr_endpoint", "ep_rx_wb_master.vhd"))
wr_lib.add_source_files(join(wr_path, "wr_endpoint", "ep_rx_oob_insert.vhd"))
wr_lib.add_source_files(join(wr_path, "wr_endpoint", "ep_rx_early_address_match.vhd"))
wr_lib.add_source_files(join(wr_path, "wr_endpoint", "ep_clock_alignment_fifo.vhd"))
wr_lib.add_source_files(join(wr_path, "wr_endpoint", "ep_tx_path.vhd"))
wr_lib.add_source_files(join(wr_path, "wr_endpoint", "ep_tx_crc_inserter.vhd"))
wr_lib.add_source_files(join(wr_path, "wr_endpoint", "ep_tx_header_processor.vhd"))
wr_lib.add_source_files(join(wr_path, "wr_endpoint", "ep_tx_vlan_unit.vhd"))
wr_lib.add_source_files(join(wr_path, "wr_endpoint", "ep_tx_packet_injection.vhd"))
wr_lib.add_source_files(join(wr_path, "wr_endpoint", "ep_packet_filter.vhd"))
wr_lib.add_source_files(join(wr_path, "wr_endpoint", "ep_rx_vlan_unit.vhd"))
wr_lib.add_source_files(join(wr_path, "wr_endpoint", "ep_ts_counter.vhd"))
wr_lib.add_source_files(join(wr_path, "wr_endpoint", "ep_rx_status_reg_insert.vhd"))
wr_lib.add_source_files(join(wr_path, "wr_endpoint", "ep_timestamping_unit.vhd"))
wr_lib.add_source_files(join(wr_path, "wr_endpoint", "ep_leds_controller.vhd"))
wr_lib.add_source_files(join(wr_path, "wr_endpoint", "ep_rtu_header_extract.vhd"))
wr_lib.add_source_files(join(wr_path, "wr_endpoint", "ep_rx_buffer.vhd"))
wr_lib.add_source_files(join(wr_path, "wr_endpoint", "ep_sync_detect.vhd"))
wr_lib.add_source_files(join(wr_path, "wr_endpoint", "ep_sync_detect_16bit.vhd"))
wr_lib.add_source_files(join(wr_path, "wr_endpoint", "ep_wishbone_controller.vhd"))
wr_lib.add_source_files(join(wr_path, "wr_endpoint", "ep_registers_pkg.vhd"))
wr_lib.add_source_files(join(wr_path, "wr_endpoint", "ep_crc32_pkg.vhd"))
wr_lib.add_source_files(join(wr_path, "wr_endpoint", "ep_tx_inject_ctrl.vhd"))
wr_lib.add_source_files(join(wr_path, "wr_endpoint", "endpoint_pkg.vhd"))
wr_lib.add_source_files(join(wr_path, "wr_endpoint", "wr_endpoint.vhd"))
wr_lib.add_source_files(join(wr_path, "wr_endpoint", "xwr_endpoint.vhd"))

wr_lib.add_source_files(join(wr_path, "wrc_core", "*.vhd"))

# gmii core
wr_lib.add_source_files(join(cute_path, "xwrf_gmii", "*.vhd"))

# board level
wr_lib.add_source_files(join(board_path, "common", "*.vhd"))
wr_lib.add_source_files(join(board_path, "kasli", "*.vhd"))

# tb cores
wr_lib.add_source_files(join(testbench_path, "sgmii_core", "*.vhd"))

# testbench
wr_lib.add_source_files(join(testbench_path, "Kasli", "kasli_testbench.vhd"))
wr_lib.add_source_files(join(testbench_path, "Kasli", "tb_kasli_axi_rw.vhd"))

wr_lib.set_sim_option("disable_ieee_warnings", True)
wr_lib.set_sim_option("modelsim.vsim_flags", ["-suppress 14408",])

ui.main()