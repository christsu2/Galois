
RISCV := RISCV_HOME
OUT   := ./rtl_sim
#UVM_HOME :="/asictool/synopsys/VCS_vM-2017.03-SP2/etc/uvm-1.1"
#XILINX_VIVADO   :="/asictool/Xilinx/Vivado/2018.1"
PCIE_ENV :="../../../PCIe.vip/verif/env"
#VERIF :="/mnt/home/_eda/Desktop/nfc.Dev"
TEST = top_base_test

#  +define+USE_UVM_AS_ROOT \

UVM_FLAGS = +incdir+${UVM_HOME}/src ${UVM_HOME}/src/uvm_pkg.sv \
	    ${UVM_HOME}/src/uvm.sv ${UVM_HOME}/vcs/uvm_custom_install_vcs_recorder.sv \
	    +incdir+${UVM_HOME}/verdi ${UVM_HOME}/verdi/uvm_custom_install_verdi_recorder.sv \
	    +incdir+${UVM_HOME}/vcs 

all:
	make compile
	make run

clean:
	rm -fr work* 64 AN* $(OUT) verdi* novas*
	rm *.log *.fsdb *.vpd *.key novas*

compile:
	mkdir -p ${OUT}
	vcs -l Logs/compile.log -sverilog ${UVM_FLAGS}\
	 	-ntb_opts uvm-1.1  \
		-full64 -kdb \
		+verilog2001ext+.vp -lca  \
		-Mdir=${OUT}/rtl_simvcs_simv.csrc  \
		-debug_access+pp -debug_access+all \
		-o ${OUT}/vcs_simv \
		-timescale=1ns/10ps -licqueue \
		$(VERIF)/top/top.v \
		-f $(VERIF)/dut/dut.f 

run:
	${OUT}/vcs_simv +UVM_VERBOSITY=LOW  +UVM_TESTNAME=$(TEST) \
        -ucli -do vcs.tcl +ntb_random_seed=1 +vcs+lic+wait -l Logs/run.log		

wave:
	verdi -ssf ./waves.fsdb \
              -dbdir ${OUT}/vcs_simv.daidir &

