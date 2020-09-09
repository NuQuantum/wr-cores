board  = "vfchd"
target = "altera"
action = "synthesis"

syn_family  = "Arria V"
syn_device  = "5agxmb1g4f"
syn_grade   = "c4"
syn_package = "40"

syn_top     = "vfchd_wr_ref_top"
syn_project = "vfchd_wr_ref"

syn_tool = "quartus"

syn_post_project_cmd = "quartus_sh -t quartus_preflow.tcl"

files = [
    "vfchd_wr_ref.sdc",
    "quartus_preflow.tcl",
]

modules = {
    "local" : [
        "../../top/vfchd_ref_design/",
    ]
}
