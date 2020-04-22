action= "simulation"
target= "xilinx"
syn_device="xc6slx45t"
sim_tool="modelsim"
top_module="main"

fetchto="../../ip_cores"
vlog_opt="+incdir+../../../sim +incdir"

include_dirs = ["../../../ip_cores/general-cores/modules/wishbone/wb_lm32/src" ]

modules = { "local" : ["../../..",
                       "../../../modules/wr_streamers",
                       "../../../top/spec_1_1/wr_streamers_demo",
                       "../../../ip_cores/general-cores"]}

files = ["main.sv","synthesis_descriptor.vhd"]


