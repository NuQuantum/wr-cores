vlog main.sv +incdir+"." +incdir+../../sim
null make -f Makefile
vsim -L unisim -t 10fs work.main +access +r
set StdArithNoWarnings 1
set NumericStdNoWarnings 1
do wave.do
radix -hexadecimal
run 20ms
wave zoomfull
radix -hexadecimal

