vsim -L unisim work.main -voptargs="+acc" -sv_seed random 
set StdArithNoWarnings 1
set NumericStdNoWarnings 1
do wave_ci.do
run 10us
wave zoomfull
radix -hex
quit 


