board  = "svec"
target = "xilinx"
action = "synthesis"

syn_device = "xc6slx150t"
syn_grade = "-3"
syn_package = "fgg900"

syn_top     = "svec_wr_ref_top"
syn_project = "svec_wr_ref.xise"

syn_tool = "ise"

files = [
    "svec_wr_ref_top.ucf",
]

modules = {
    "local" : [
        "../../top/svec_ref_design/",
    ],
}

fetchto="../../ip_cores"

syn_post_project_cmd = (
    "$(TCL_INTERPRETER) " + \
    fetchto + "/general-cores/tools/sdb_desc_gen.tcl " + \
    syn_tool + " $(PROJECT_FILE);" \
    "$(TCL_INTERPRETER) syn_extra_steps.tcl $(PROJECT_FILE)"
)
