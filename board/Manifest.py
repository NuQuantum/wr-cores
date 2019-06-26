try:
    if board in ["spec", "svec", "vfchd", "clbv2", "common"]:
        modules = {"local" : [ board ] }
except NameError:
    pass
