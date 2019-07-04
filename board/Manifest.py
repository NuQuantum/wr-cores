try:
    if board in ["spec", "svec", "vfchd", "clbv2", "clbv3", "clbv4", "common"]:
        modules = {"local" : [ board ] }
except NameError:
    pass
