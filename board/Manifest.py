try:
    if board in ["spec", "svec", "vfchd", "clbv2", "clbv3", "common"]:
        modules = {"local" : [ board ] }
except NameError:
    pass
