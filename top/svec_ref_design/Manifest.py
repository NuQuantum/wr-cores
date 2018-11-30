fetchto = "../../ip_cores"

files = [
    "svec_wr_ref_top.vhd",
]

modules = {
    "local" : [
        "../../",
    ],
    "git" : [
        "git://ohwr.org/hdl-core-lib/general-cores.git",
        "git://ohwr.org/hdl-core-lib/vme64x-core.git",
        "git://ohwr.org/hdl-core-lib/etherbone-core.git",
    ],
}
