action = "simulation"
target = "xilinx"
syn_device = "xc6slx45t"
syn_grade = "-3"
syn_package = "fgg484"
#sim_tool = "modelsim"
sim_tool = "riviera"
top_module = "main"
fetchto = "../../ip_cores"
vlog_opt = "+incdir+../../sim"

# comment out the next line for ModelSim
#vcom_opt="-mixedsvvh"

files = [ "main.sv" ]

include_dirs = [ "../../sim",
        "../../ip_cores/general-cores/modules/wishbone/wb_lm32/src" ]

modules = { "local" : [ "../../",
			"../../modules/fabric",
			"../../ip_cores/general-cores",
			"../../ip_cores/etherbone-core",
                        "../../ip_cores/urv-core",
			"../../ip_cores/gn4124-core" ]}



