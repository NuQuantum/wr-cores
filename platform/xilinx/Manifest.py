if (syn_device[0:4].upper()=="XC7A" or syn_device[0:4].upper()=="XC7K" or
        syn_device[0:4].upper()=="XCZU"):
	files = [ "wr_xilinx_pkg.vhd", "xwrc_platform_vivado.vhd" ]
else:
	files = [ "wr_xilinx_pkg.vhd", "xwrc_platform_xilinx.vhd" ]
modules = {"local" : ["wr_gtp_phy", "chipscope"]}
