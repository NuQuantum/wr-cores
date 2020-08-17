board  = "pxie-fmc"
target = "xilinx"
action = "synthesis"

syn_device = "xczu7cg"
syn_grade = "-1"
syn_package = "ffvf1517"

syn_top = "pxie_fmc_ref_top"
syn_project = "pxie_fmc_ref_top"
syn_tool = "vivado"

files = [
    "pxie_fmc_ref_design.xdc",
]

modules = {
    "local" : [
        "../../top/pxie_fmc_ref_design/",
    ],
}

