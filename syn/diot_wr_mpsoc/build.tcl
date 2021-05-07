# Create Vivado project
source ../../top/diot_wr_mpsoc/diot_wr_mpsoc.tcl

# Generate the wrapper
set design_name design_1
make_wrapper -files [get_files $design_name.bd] -top -import

# Make this newly generated wrapper our new TOP
set file "hdl/design_1_wrapper.vhd"
set file_obj [get_files -of_objects [get_filesets sources_1] [list "*$file"]]
set_property -name "file_type" -value "VHDL" -objects $file_obj

# Set 'sources_1' fileset properties
set obj [get_filesets sources_1]
set_property -name "top" -value "design_1_wrapper" -objects $obj
set_property -name "top_auto_set" -value "0" -objects $obj
