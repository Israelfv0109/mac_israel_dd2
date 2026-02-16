src      = mac_top
tb       = mac_tb
testname = test
logs     = ./logs
verbosity= UVM_MEDIUM
.DEFAULT_GOAL := help

list: # target
	echo "# rtl" > list.f
	ls ../../rtl/*.sv >> list.f
	echo "# verification" >> list.f
	echo ../mac_tb.sv >> list.f
    
ana:
	xvlog -i ../verif -sv -f list.f -L uvm

elab: ana
	xelab -debug typical --cc_type sbct --relax ${tb} -s mac_sim

sim: elab
	xsim mac_sim -runall

waves:
	xsim mac_sim.wdb -autoloadwcfg -gui &

sim_gui: elab
	xsim mac_sim -gui

cov: 
	xcrg -cov_db_dir ./xsim.codeCov -cov_db_name mac_sim -report_dir ./cov_report

sim_uvm: elab
	xsim mac_sim "UVM_TESTNAME=${testname}"

sim_uvm_gui: elab
	xsim mac_sim -gui "UVM_TESTNAME=${testname}"

help:
	@echo ""
	@echo "==== Basic Vivado Compile/Simulator makefile ======"
	@echo " Targets: ana, elab, sim, clean, list, help, cov"
	@echo ""

clean:
	rm -rf xvlog* xelab* ana elab sim
	rm -f xsim.log xsim.jou xsim_*.backup.log xsim_*.backup.jou
	rm -rf xsim.covdb tr_db* webtalk* xsim.codecov cov_report
	rm -rf xsim.dir .Xil vivado*
	rm -f work.*.wdb
	[ ! -d work ] || rm -rf work