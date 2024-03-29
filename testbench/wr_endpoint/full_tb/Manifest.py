target = "xilinx"
action = "simulation"
syn_device = "xc6slx45t"
syn_grade = "-3"
syn_package = "fgg484"
#sim_tool = "modelsim"
sim_tool = "riviera"
top_module = "main"
files = "main.sv"
fetchto = "../../../ip_cores"

vcom_opt="-relax -packagevhdlsv"
vlog_opt="+incdir+../../../sim +incdir+../../../sim/fabric_emu"

include_dirs = [ "../../../sim", "../../../sim/fabric_emu" ]

modules ={"git" : ["git@ohwr.org:hdl-core-lib/general-cores.git" ],
	  "local" : ["../../../modules/wr_endpoint", 
	             "../../../modules/timing",
	             "../../../modules/fabric",
	             "../../../modules/wr_tbi_phy",
	             "../old_ep",
	             "../../../platform/xilinx/wr_gtp_phy" ] };
