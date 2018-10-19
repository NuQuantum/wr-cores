action= "simulation"
target= "xilinx"
syn_device="xc6slx45t"
sim_tool="modelsim"
top_module="main"
sim_top="main"

vcom_opt="-mixedsvvh l"

fetchto="../../../ip_cores"

include_dirs=["../../../sim"]

modules = { "local" : ["../../..",
                       "../../../modules/wr_streamers",
                       "../../../ip_cores/general-cores"]}
					  
files = ["main.sv"]

