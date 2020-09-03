if syn_tool=="vivado":
	files = [ "wr_xilinx_pkg.vhd", "xwrc_platform_vivado.vhd" ]
elif syn_tool=="ise":
	files = [ "wr_xilinx_pkg.vhd", "xwrc_platform_xilinx.vhd" ]
modules = {"local" : ["wr_gtp_phy", "chipscope"]}
