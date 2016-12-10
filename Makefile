SFLAGS =
PORT = 9000
START_TIME = 7
INTERVAL_TIME = 10
MAX_OBJECTIVE = 99

# if "none" then run locally without server code
SERVER = none
# SERVER = 127.0.0.1

# enable coverage dumping
# COVERAGE_DUMP = 1
COVERAGE_DUMP = 0

# override for +ntb_random_seed_automatic if desired
SEED = +ntb_random_seed=2
# SEED =

CLIENT_INDEX = 0

PARALLEL_SIMS := 5
PARALLEL_SIMS_BASE_ZERO := $(shell expr ${PARALLEL_SIMS} - 1)
NUMBERS := $(shell seq 0 ${PARALLEL_SIMS_BASE_ZERO})
SIM_SYNOPSYS_PARALLEL_JOBS := $(addprefix sim_synopsys_parallel_job,${NUMBERS})

SYNOPSYS_SIM_LOG = sim_0.log
SYNOPSYS_SIM_EXEC = ./snps_work/dut
TARGET_LIST = clean build_synopsys sim_synopsys sim_synopsys_parallel sim_synopsys_parallel_perf sim_synopsys_reload sim_synopsys_default synopsys_reload synopsys server client status report_summary report_finish_time zombie shutdown help
WIDTH = 1
BUILD_LIST = \
	sv/irand_pkg.sv \
	sv/env_pkg.sv \
	sv/rseed_interface.sv \
	sv/dut.sv \
	sv/top.sv \

# UVM_DEBUG UVM_HIGH UVM_MEDIUM UVM_LOW
UVM_VERBOSITY = UVM_LOW

SYNOPSYS_SIM_COMMON = \
	+UVM_TESTNAME=test0 \
	+UVM_VERBOSITY=$(UVM_VERBOSITY) \
	+ntb_random_seed_automatic $(SEED) \
	+ntb_cache_dir=ntb_cache_dir_$(CLIENT_INDEX) \
	+ntb_delete_disk_cache=1 \
	+client_index=$(CLIENT_INDEX) \
	+server=$(SERVER) \
	+port=$(PORT) \
	+start_time=$(START_TIME) \
	+interval_time=$(INTERVAL_TIME) \
	+max_objective=$(MAX_OBJECTIVE) \
	+coverage_dump=$(COVERAGE_DUMP) \
	-ucli \
	-ucli2Proc \
	$(SFLAGS) -l $(SYNOPSYS_SIM_LOG)

#	-cm line \

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
		-cm line \
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

.PHONY: all ${JOBS}
sim_synopsys_parallel: ${SIM_SYNOPSYS_PARALLEL_JOBS} ## Runs parallel Synopsys simulations
	echo "$@ success"

sim_synopsys_parallel_perf: ## Performance of parallel simulations
	@+$(MAKE) server &
	date +%s > former_seconds.log
	@+$(MAKE) sim_synopsys_parallel
	date +%s > later_seconds.log
	paste later_seconds.log former_seconds.log | awk '{print $$1 - $$2}' >> runtime.log
	./tcl/status.tcl >> status.log
	@+$(MAKE) shutdown
	echo "$@ success"

${SIM_SYNOPSYS_PARALLEL_JOBS}: sim_synopsys_parallel_job%:
	+$(MAKE) sim_synopsys CLIENT_INDEX=$* SYNOPSYS_SIM_LOG=sim$*.log

server: ## Starts up a TCL branching server
	./tcl/server.tcl
	sleep 5

client: ## Debug client to put values into TCL branching server
	./tcl/client.tcl

status: ## Status from the TCL server
	./tcl/status.tcl

shutdown: ## shutdown the the TCL server
	./tcl/shutdown.tcl
	sleep 5

synopsys: build_synopsys sim_synopsys ## Runs a Synopsys Build and does a branching simulation

synopsys_reload: build_synopsys sim_synopsys_reload ## Builds and Reloads a simulation from file

build_synopsys: clean ## Synopsys VCS Build
	@mkdir snps_work
	vcs $(SYNOPSYS_BUILD_COMMON) $(BUILD_LIST)

sim_synopsys: ## Run a branching simulation
	$(SYNOPSYS_SIM_EXEC) $(SYNOPSYS_SIM_COMMON) -do tcl/loop.tcl

sim_synopsys_default: ## Run a simulation without any looping
	$(SYNOPSYS_SIM_EXEC) $(SYNOPSYS_SIM_COMMON) -do tcl/default.tcl

sim_synopsys_reload: ## Reload a simulation from a seed file
	$(SYNOPSYS_SIM_EXEC) $(SYNOPSYS_SIM_COMMON) -do tcl/reload.tcl

report_summary: ## Report Summary
	@echo ""
	@cat $(SYNOPSYS_SIM_LOG) | egrep "ITERATIONS TOTAL|UVM_FATAL|UVM_ERROR|COVERAGE GOAL MET"
	@echo ""

zombie: ## Print out the zombie VCS processes that result from C-c
	ps aux | grep $(USER) | grep "snps_work/dut" | awk '{print $$2}' | xargs kill -9

report_finish_time: ## Report the finish time of simulation log
	cat $(SYNOPSYS_SIM_LOG) | grep "finish at sim" | awk '{print $$NF}'

clean: ## Cleans up work area
	@rm -rf urgReport
	@rm -f replicate_*
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
	@echo ""
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}'
	@echo ""
	@echo "  Examples"
	@echo "    > make synopsys UVM_VERBOSITY=UVM_MEDIUM"
	@echo "    > make synopsys WIDTH=3"
	@echo "    > make -j5 sim_synopsys_parallel SERVER=127.0.0.1 PARALLEL_SIMS=5"
	@echo "    > make status"
	@echo "    > make sim_synopsys_reload"

.DEFAULT_GOAL := help
