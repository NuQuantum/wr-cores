# Modelsim run script for continuous integration (with return code)
# execute: vsim -c -do "run_ci.do"
vsim -L unisim work.main +access +r  
set StdArithNoWarnings 1
set NumericStdNoWarnings 1
do wave_ci.do
run 100ms
wave zoomfull
radix -hex
null coverage save coverage.ucdb
quit 


