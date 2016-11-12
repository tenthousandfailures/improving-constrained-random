SFLAGS =
PORT = 9000
START_TIME = 7
LOOP_TIME = 10
MAX_OBJECTIVE = 99

# if "none" then run locally without server code
SERVER = none
# SERVER = 127.0.0.1

# override for +ntb_random_seed_automatic if desired
SEED = +ntb_random_seed=2
# SEED =

SYNOPSYS_SIM_LOG = sim.log
SYNOPSYS_SIM_EXEC = ./snps_work/dut
TARGET_LIST = clean build_synopsys sim_synopsys sim_synopsys_reload sim_synopsys_default synopsys_reload synopsys server client status report_summary report_match help
WIDTH = 1
BUILD_LIST = \
	sv/irand_pkg.sv \
	sv/env_pkg.sv \
	sv/rseed_interface.sv \
	sv/dut.sv \
	sv/top.sv \

# UVM_DEBUG UVM_HIGH UVM_MEDIUM UVM_LOW
UVM_VERBOSITY = UVM_MEDIUM

SYNOPSYS_SIM_COMMON = \
	+UVM_TESTNAME=test0 \
	+UVM_VERBOSITY=$(UVM_VERBOSITY) \
	+ntb_random_seed_automatic $(SEED) \
	+server=$(SERVER) \
	+port=$(PORT) \
	+start_time=$(START_TIME) \
	+loop_time=$(LOOP_TIME) \
	+max_objective=$(MAX_OBJECTIVE) \
	-ucli \
	-ucli2Proc \
	$(SFLAGS) -l $(SYNOPSYS_SIM_LOG)

# not needed yet
# +vcs+flush_all
#	-gui=verdi \
# +UVM_RESOURCE_DB_TRACE \
# +UVM_CONFIG_DB_TRACE \

SYNOPSYS_BUILD_COMMON = \
		-sverilog \
		-ntb_opts uvm \
		-l snps_work/dut.comp.log \
		-o snps_work/dut \
		-timescale="1ns/1ns" \
		+define+UVM_NO_DEPRECATED \
		+define+UVM_OBJECT_MUST_HAVE_CONSTRUCTOR \
		+define+UVM_SV_SEED \
		+define+UVM_NO_DIRECTC \
		-gvalue width=$(WIDTH) \
		-debug_access \
		+cli+3 \
		$(SFLAGS)

# uses the default UVM seed method - not C
# +define+UVM_SV_SEED

#		-pvalue+top.width=$(WIDTH) \
#		-kdb \
#		-lca \

# to default behavior for randomization to uvm standard
# +define+UVM_NO_DIRECTC

# extra debug args
# -assert svaext \
# faster
# -debug_access \  -- this is all that is needed normally
# +cli+3 allows for calling functions
# -debug_access+r \
# -debug_access+all \

# these are not based off of file triggers
.PHONY: $(TARGET_LIST)

server: ## Starts up a TCL branching server
	./tcl/server.tcl

client: ## Debug client to put values into TCL branching server
	./tcl/client.tcl

status: ## Status from the TCL server
	./tcl/status.tcl

synopsys: build_synopsys sim_synopsys ## Runs a Synopsys Build and does a branching simulation

synopsys_reload: build_synopsys sim_synopsys_reload

build_synopsys: clean ## Synopsys VCS Build
	@mkdir snps_work
	@touch objective

	vcs $(SYNOPSYS_BUILD_COMMON) $(BUILD_LIST)

sim_synopsys: ## Run a branching simulation
	$(SYNOPSYS_SIM_EXEC) $(SYNOPSYS_SIM_COMMON) -do tcl/loop.tcl

sim_synopsys_default: ## Run a simulation without any looping
	$(SYNOPSYS_SIM_EXEC) $(SYNOPSYS_SIM_COMMON) -do tcl/default.tcl

sim_synopsys_reload: ## Reload a simulation from a seed file
	$(SYNOPSYS_SIM_EXEC) $(SYNOPSYS_SIM_COMMON) -do tcl/reload.tcl

report_match: ## Print out the matching inputs and seeds
	@echo ""
	@cat sim.log | grep "INFO STATUS" | grep "TOP" | grep -v "match = 0"
	@echo ""

report_summary: ## Report Summary
	@echo ""
	@cat sim.log | egrep "ITERATIONS TOTAL|UVM_FATAL|UVM_ERROR|COVERAGE GOAL MET"
	@echo ""

clean: ## Cleans up work area
	@rm -rf snps_work
	@rm -rf objective
	@rm -f .vcs_checkpoint*
	@rm -f inter.fsdb
	@rm -f *.log
	@rm -f *.vpd
	@rm -rf vdCovLog
	@rm -rf vericomLog
	@rm -rf work.lib++
	@rm -f seed
	@rm -f objective
	@rm -rf libnz4w_r.soLog
	@rm -f .inter.fsdb*
	@rm -f signal.tc
	@rm -f signal.rc
	@rm -f vc_hdrs.h
	@rm -f novas.rc
	@rm -f novas.conf
	@rm -rf verdiLog
	@rm -rf csrc
	@rm -f ucli.key
	@rm -rf vloganLog

help: ## Help Text
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}'

.DEFAULT_GOAL := help
