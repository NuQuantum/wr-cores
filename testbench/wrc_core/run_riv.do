# Riviera run script for continuous integration (with return code)
# execute: vsim -c -do "run_riv.do"
vsim -L unisim -t 10fs work.main +access +r -ieee_nowarn
# for ModelSim (for Riviera this is already done with -ieee_nowarn)
#set StdArithNoWarnings 1
#set NumericStdNoWarnings 1
do wave_ci.do
radix -hexadecimal
run 200ms
wave zoomfull
radix -hexadecimal

