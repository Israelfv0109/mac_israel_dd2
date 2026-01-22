src=booth
testname=booth_tb
top      = tb_booth_multiplier
verbosity=UVM_MEDIUM
.DEFAULT_GOAL := help

list: # target
	@echo "# rtl" > list.f
	@echo "../rtl/${src}_rtl.sv" >> list.f
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
