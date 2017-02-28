# Abstract

Constrained Random simulation is so critical to modern verification environments that it is a major component of the SystemVerilog language itself. This paper proposes a method that improves how UVM Constrained Random simulations are run. By abstracting the purpose of a simulation to be achieving "Objective Functions" (nominally coverage goals), it is possible to have the simulation autonomously explore deep possibilities from multiple points in time of a standard UVM testbench governed by feedback. This method has a number of benefits including: faster automated coverage closure, an efficient final stimulus solution and proposed higher quality of coverage.

# Background

This repository is the example code referenced in the paper "Improving Constrained Random Testing by Achieving Simulation Verification Goals through Objective Functions, Rewinding and Dynamic Seed Manipulation" which was published at [DVCon 2017](http://www.dvcon.com) in San Jose, California by [Eldon Nelson](http://tenthousandfailures.com).

# Getting Started

Use the "make help" command to enumerate the available Make targets that are available. The output will look similar to the below:

```
> make help

clean                      Cleans up work area
help                       Help Text
server                     Starts up a TCL branching server
shutdown                   Shutdown the the TCL server
status                     Status from the TCL server
synopsys                   Runs a Synopsys Build and does ...
synopsys_reload            Builds and Reloads a simulation from file
...
```

The simplest example of running is to run the following Make targets which will run a simulation locally using the algorithm.

```
> make clean
> make synopsys
```

Afterwards you can replicate the optimal solution by running.

```
> make synopsys_sim_reload
```

# Advanced Arguments

There are a number of Make parameters that can effect the simulation.

PARAMETER      | DEFAULT            | DESCRIPTION
---------------|--------------------|------------
WIDTH          | 3                  | the bit width of the inputs A and B of the DUT
SERVER         | none               | the IP address of the TCL server to coordinate the parallel simulations. if set to "none" will run locally without the aid of a server
PORT           | 9000               | the port of the IP address of the TCL server to coordinate the parallel simulations
START_TIME     | 7                  | the start time in simulation units to start the algorithm
INTERVAL_TIME  | 10                 | the interval time in simulation unitis to start the algorithm
MAX_OBJECTIVE  | 100                | the value of the "Objective Function" that is required to satisify the simulation
COVERAGE_DUMP  | 0                  | if set to 1 will dump code coverage as well as functional coverage
SEED           | +ntb_random_seed=2 | the seed used in the simulation
PARALLEL_SIMS  | 5                  | the number of parallel simulations to run
UVM_VERBOSITY  | UVM_LOW            | the verbosity of the UVM log

# Examples

```
> make synopsys WIDTH=3
```

The above will build and run a local simulation with a DUT with both inputs being 3 bits each. It will iterate on the simulation until it finds the combination of inputs that satisfy the "Objective Function". The resultant "replicate" file will allow for an efficient rerun.

```
> make sim_synopsys_reload
```

The above will run a local simulation using a file named "replicate" in the git repo root to run an efficent rerun from a pervious run.

```
> make -j5 sim_synopsys_parallel SERVER=127.0.0.1 PARALLEL_SIMS=5
```

The above will run a parallel simulation that will coordinate with a TCL server on localhost on port 9000. It will launch 5 parallel cooperating simulations.

# Requirements

This code was developed and tested with VCS 2016.06 on 64 bit Linux. Patches to port to other simulators are accepted. The concepts should be implementable on current SystemVerilog simulators.
