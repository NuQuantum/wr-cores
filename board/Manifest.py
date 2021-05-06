try:
    if board in ["spec", "svec", "vfchd", "clbv2", "clbv3", "clbv4", "pxie-fmc", "diot-sb", "common"]:
        modules = {"local" : [ board ] }
except NameError:
    pass
