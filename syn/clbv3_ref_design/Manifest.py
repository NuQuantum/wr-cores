board  = "clbv3"
target = "xilinx"
action = "synthesis"

syn_device = "xc7a200t"
syn_grade = "-2"
syn_package = "fbg484"

syn_top = "clbv3_wr_ref_top"
syn_project = "clbv3_wr_ref.xpr"

syn_tool = "vivado"

modules = { "local" : "../../top/clbv3_ref_design/"}
