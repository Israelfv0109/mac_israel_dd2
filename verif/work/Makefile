testname = tb_mac_top
logs     = ./logs
defines  = XCELIUM
verb     = UVM_MEDIUM

compile_switches = -f list.f -l ${logs}/comp.log +define+${testname}+ \
                   -access +rwc -timescale 1ns/1ps -sv -linedebug

compile_switches_uvm = -f list.f -uvmhome CDNS-1.2 -uvm -l ${logs}/comp.log \
                       +define+${testname}+ +UVM_TESTNAME=${testname} +UVM_VERBOSITY=${verb} \
                       -access +rwc -timescale 1ns/1ps -sv -linedebug

compile_switches_pa = -f list.f -uvmhome CDNS-1.2 -uvm -l ${logs}/comp.log \
                      +define+${defines}+ +UVM_TESTNAME=${testname} +UVM_VERBOSITY=${verb} \
                      -access +rwc -timescale 1ns/1ps -sv -linedebug -define UPF -covoverwrite -lps

# --- TARGETS ---

sim:
	mkdir -p ./logs
	xrun -incdir .. -f list.f -l ./logs/comp.log +define+tb_mac_top+ -access +rwc -timescale 1ns/1ps -sv -linedebug
	
sim_uvm:
	mkdir -p $(logs)
	xrun ${compile_switches_uvm} -abvevalnochange 

sim_uvm_gui:
	mkdir -p $(logs)
	xrun ${compile_switches_uvm} -gui

sim_cov:
	mkdir -p $(logs)
	xrun $(compile_switches) -cov_cgsample -covoverwrite -coverage u -covtest $(testname)

cov_merge:
	imc -exec cov_merge.tcl

sim_uvm_cov:
	mkdir -p $(logs)
	xrun ${compile_switches_uvm} -cov_cgsample

cov_gui:
	imc -load test

simvision:
	simvision shm_db &

formal:
	# Ajustada la ruta para subir 2 niveles (../../fv)
	jaspergold ../../fv/static_fv_jg.tcl -acquire_proj -no_gui

formal_gui:
	# Ajustada la ruta para subir 2 niveles (../../fv)
	jaspergold ../../fv/static_fv_jg.tcl -acquire_proj &

clean:
	rm -rf xrun* waves* xcelium* logs shm_db .sim* .svm* *.diag uvm_test_name.svh jgproject

sim_pa:
	echo "\`include \"../../verif/test/${testname}.svh\""  > uvm_test_name.svh
	xrun ${compile_switches_pa}
