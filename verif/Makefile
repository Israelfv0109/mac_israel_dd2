src=lvl1
testname=mac_tb
top      = tb_mac_top
verbosity=UVM_MEDIUM
.DEFAULT_GOAL := help

list: # target
	@echo "# rtl" > list.f
	@echo "../rtl/lvl3_rtl.sv" >> list.f
	@echo "../rtl/lvl2_rtl.sv" >> list.f
	@echo "../rtl/lvl1_rtl.sv" >> list.f
	@echo "# verification" >> list.f
	@echo "./${testname}.sv" >> list.f
	
ana: list
	xvlog -sv -f list.f -L uvm
elab: ana
	xelab -debug typical --relax ${top}
sim: elab
	xsim work.${top} -runall

waves:
	xsim work.${top}.wdb -autoloadwcfg -gui &

sim_gui: elab
	xsim work.${top} -runall -gui
cov: 
	xcrg -report_format html -dir xsim.covdb
sim_uvm: elab
	xsim work.${top} "UVM_TESTNAME=${testname}"
	
sim_uvm_gui: elab
	xsim work.${top} -gui "UVM_TESTNAME=${testname}"
help:
	@echo ""
	@echo "==== Basic Vivado Compile/Simulator makefile ======"
	@echo " Targets:"
	@echo " ana    --> Analyzes the HDL file with xvlog command"
	@echo " elab   --> Elaborates de design with xelab command"
	@echo " sim    --> Simulates the design with xsim command"
	@echo " clean  --> Clean support files"
	@echo " help   --> this help menu =)"
	@echo ""
clean:
	rm -rf xvlog* xelab* xsim* webtalk* tr_db* ana elab sim .Xil vivado* work*
	rm -rf xsim.dir


logs     = ./logs
defines  = XCELIUM
verb     = UVM_MEDIUM

compile_switches = -f list.f -l ${logs}/comp.log +define+${testname}+ -access +rwc -timescale 1ns/1ps -sv
compile_switches_uvm = -f list.f -uvmhome CDNS-1.2 -uvm -l ${logs}/comp.log +define+${testname}+ +UVM_TESTNAME=${testname} +UVM_VERBOSITY=${verb} -access +rwc -timescale 1ns/1ps -sv
compile_switches_pa = -f list.f -uvmhome CDNS-1.2 -uvm -l ${logs}/comp.log +define+${defines}+ +UVM_TESTNAME=${testname} +UVM_VERBOSITY=${verb} -access +rwc -timescale 1ns/1ps -sv -define UPF -covoverwrite -lps_1801 ../power/chip_wrapper.upf -lps_dbc -lps_relax_1801 -lps_verbose 5 -lps_common_options

csim:
	xrun ${compile_switches}

