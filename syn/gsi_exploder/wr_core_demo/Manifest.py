target = "altera"
action = "synthesis"

fetchto = "../../../ip_cores"

syn_device = "ep2agx125ef"
syn_grade = "c5"
syn_package = "25"
syn_top = "exploder_top"
syn_project = "exploder_top"

modules = {"local" : [ "../../../", "../../../top/gsi_exploder/wr_core_demo"]}

				 