# Pinaka 0.1

## How Pinaka works?
Pinaka is a *single-path* symbolic execution engine incorporated with incremental solving and eager infeasibility checks. The keyword *single-path* means that at any given moment, Pinaka is focused
only on one particular path. Two paths are **never** merged. This may lead to path explosion problem as the number of branches increases in a program. That is where, eager infeasibility checks
and incremental solving helps. Along a path, when Pinaka encounters a branch, it makes two queries: (1) whether the path can proceed along the _true_ branch, and (2) whether the path can proceed
along the _false_ branch. If the answer to one of them (or both of these) is a negative, then no further exploration is done along that branch. Since the query to a solver is being made at every branch, incremental solving is used to it efficient. 

It supports two incremental modes: Partial and Full Incremental. In Partial Incremental Mode, a single solver instance is maintained along a single search path. However, a new instance is created every time a backtrack happens and a different path/branch is to be explored. In Full Incremental Mode, a single solver instance is maintained throughout the search process. Upon backtrack, the old path is logically disabled through the use of activation literals.

### Full Incremental v/s Partial Incremental
Full Incremental mode is best suited for smaller programs having a few (not too many) branches. For a program with too many paths, the number of clauses inside the solver keeps increasing as the solver is instantiated only once. Hence, when trying to verify a particular search path, all the other constraints (for the rest of the search tree explored so far) slow down the solver performance.
Consequently, Partial Incremental Mode is better suited for such cases. However, for cases having smaller search trees, the cost of instantiating a new  solver instance on any backtrack penalises Pinaka's performance more than Full Incremental Mode.

In a nutshell, the trade-off between the cost of creating new solver instance versus the size of formula inside the solver instance decides which incremental mode to choose.


### Search Strategies
Pinaka currently supports Breadth First and Depth First Search Strategies. Although, DFS undoubtedly gives a higher performance, BFS was implemented with a plan to serve as a base for incorporating state-selection heuristics or hybrid search-strategies in future.


### Solver Backend
Pinaka's incremental solver API have been built on top of CProver's SAT Solver APIs. Pinaka currently supports MiniSAT like solvers such as Glucose-Syrup, MapleSAT, MiniSAT etc.

*Pinaka does not currently support Z3 solver Backend, as the CProver version used in Pinaka itself does not provide integration of SMT solvers through APIs.* The CPROVER version used to build Pinaka invokes SMT solvers through a shell and the formula is fed through a file, which is meaningless for incremental solving. In future, we may look at SMT solver integration through APIs to better exploit incremental solving provided by SMT solvers.


## How is Pinaka different from Symex?
Pinaka-0.1 that participated in SVCOMP 2019 has been built on top-of [Symex(commit id: 9b5a72cf992d29a905441f9dfa6802379546e1b7)](https://github.com/diffblue/symex/tree/9b5a72cf992d29a905441f9dfa6802379546e1b7). The following are the key attributes by which Pinaka varies from the Symex version mentioned above.

- *Incremental Solving*: In contrast to Symex, Pinaka seizes the advantage of incremental solving on top of single path symbolic execution
- *Eager Feasibility Checks*: Pinaka fires a query to the backend solver every time a branching condition (including looping conditions) are encountered as opposed to Symex which only does so whenever an assert is reached. *Note that newer version of Symex has the option to do eager infeasibility, however, this feature is NOT available on the Symex version used in Pinaka-0.1*
For this reason,(for Pinaka) anytime while looping, during an iteration of a loop when along a path, when the entry condition of the loop becomes infeasible, the corresponding query fired at that point will deem UNSAT.  *Hence, Pinaka does not require specifying an unrolling bound on loops.* However, this also means that Pinaka is _non-terminating_ if there is a non-terminating path in a program for some input.
- *Recursive Procedures*: The Symex version Pinaka is built on has a buggy support for recursive procedures. Hence, Pinaka uses it's own forked version where the said functionality has been added.
- *Ternary Operator*: Pinaka also handles ternary operators separately from Symex as the Symex version used for Pinaka is buggy.
- *Breadth First Search*: Pinaka also allows BFS search strategy which is not supported on the corresponding Symex version.


## Pinaka & SVCOMP 2019

- The version of Pinaka (Pinaka-0.1) that participated in SVCOMP 2019 ran **Depth First Search** in **Partial Incremental Mode**. These choices were simply a result of better performance on SVCOMP Benchmarks during testing phase.
- Pinaka-0.1 made use of **Glucose-Syrup** as its solver back-end for SVCOMP 2019 to yield a better overall performance.
- Pinaka-0.1 participated in Termination,  NoOverflows meta-categories and  all ReachSafety sub-categories EXCEPT ReachSafety-Sequentialized. The decision to not participate in other meta-categories because of lack of time for testing Pinaka-0.1 thoroughly on those categories.
- Currently, Pinaka does not provide support for verification of concurrent programs. Non-participation in MemSafety & SoftwareSystems categories was merely due to a lack of time for the authors to be able to test the tool on these benchmarks.
- Witness generation for Pinaka-0.1 is done by CProver framework itself.

### Proving Termination with Pinaka
Consider the following snippet :
```cpp
while(condition1)
{
	if(condition2)
	{
		//Statements
	}

	//Body
}
```
As Pinaka, reaches the loop header along a path, the current state continues inside the loop i.e. `condition1 == true` if it's feasible, while the state corresponding `condition1 == false` is pushed onto a queue. Now further as the path corresponding to `condition1 == true` encounters the if-statements, the current state continues down the path `condition2 == true` if found feasible. Similarly, another state with `condition1 == true` and `condition2 == false` is pushed onto the queue.
Further, every time either the loop-condition or the if-else condition is encountered, corresponding query is fired to the solver to check whether the state is feasible or not. If not, the next state is picked out from the queue and the process continues.

Following from the above description, and **assuming** that CProver does not have over-approximation or under-approximation during modelling of a C program, Pinaka only terminates for a given input program if and only if all the concrete feasible program paths terminate. 

If there are over-approximations in CProver, then Pinaka may not terminate even though the input program is terminating along all paths for all inputs. Because for a spurious state, the
entry condition of a loop may continue to be feasible and Pinaka may keep on going iterating through a loop. On the other hand, if there are under-approximations in CProver, then Pinaka
may falsely declare a program to be terminating, even though there may be a feasible concrete state for which the program may not terminate.


Therefore, under the assumption that CProver does not over-approximate or under-approximate, Pinaka will terminate if and only if all the paths of the input program is terminating on all the inputs. In general, Pinaka is a _non-terminating_ tool.


Note that Pinaka creates fresh copies of the variables (SSA style) that are modified in the loop every time a new iteration is traversed in a path to capture different set of values that a 
program variable may hold in different iterations.

One may also note from the above observations that an explicit loop unrolling bound is not required by Pinaka.

## General Execution Instructions
* Clone this repository
	```
	git clone https://github.com/sbjoshi/Pinaka.git
    cd Pinaka
    unzip bin.zip
    cd bin
	```

* In order to run the tool with it's default settings run the following command:
	```
	./pinaka <PATH-TO-SOURCE-FILE>
	```
	where \<PATH-TO-SOURCE-FILE\> must strictly point to a **C file**.

**NOTE:** By default Pinaka uses *Depth First Search* as it's search strategy in *Full Incremental Mode*.

* In order to run BFS or Partial Incremental Mode, either one or a combination of the following options may be provided to the tool:
```
	./pinaka --bfs --partial-incremental <PATH-TO-SOURCE-FILE>
```

* Once the run is complete, verification outcome and statistics are printed on the terminal. An outcome of 'VERIFICATION FAILED' implies that the asserting conditions in the source file do not hold. In order to produce a counter-example/error-trace, use the following option:
```
	./pinaka --show-trace <PATH-TO-SOURCE-FILE>
```

* Other options available may be explored from the help menu as follows:
```
	./pinaka --help
	or
	./pinaka -h
```

## SVCOMP Style Execution
### INSTRUCTIONS to configure Pinaka in Benchexec:
* Clone this repository
	```
	git clone https://github.com/sbjoshi/Pinaka.git
        cd Pinaka
        unzip bin.zip
        cd ..
	```
* Get Benchmarks and Benchexec
	```
	git clone --depth=1 https://github.com/sosy-lab/sv-benchmarks
	git clone https://github.com/sosy-lab/benchexec
	cd benchexec
	```
* Copy relevant files to appropriate places in benchexec
	```
	cp ../Pinaka/svcomp19_config/pinaka.xml ../Pinaka/svcomp19_config/pinaka-wrapper.sh .
	cp ../Pinaka/bin/pinaka .
	cp ../Pinaka/svcomp19_config/pinaka.py benchexec/tools
	```
* Ensure that you modify time-limit, memory-limit and cpuCores in pinaka.xml depending upon the resource limit you have.

### INSTRUCTIONS to run BENCHMARKS:
* Navigate back to top-level benchexec directory
* To run a set of tasks :
	```
	sed -i 's/witness.graphml/${logfile_path_abs}${inputfile_name}-witness.graphml/' pinaka.xml
	sudo chmod o+wt '/sys/fs/cgroup/cpuset/'
	sudo chmod o+wt '/sys/fs/cgroup/cpu,cpuacct/'
	sudo chmod o+wt '/sys/fs/cgroup/freezer/'
	sudo chmod o+wt '/sys/fs/cgroup/memory/'
	sudo swapoff -a
	bin/benchexec pinaka.xml --tasks="ReachSafety-<TASKSET>"
	```
**NOTE:** 
-  TASKSET needs to be replaced for the particular task to be run whose names can be found in pinaka.xml file.<br />
		*Example*: bin/benchexec pinaka.xml --tasks="ReachSafety-BitVectors"
- 'tasks' option may be removed to run the tool on all verification tasks at once. 	
	  
Results i.e. graphml witnesses will be stored in results directory (wrt. pwd).

* To validate violation-witnesses:
	```
	wget https://raw.githubusercontent.com/sosy-lab/sv-comp/master/benchmark-defs/cpa-seq-validate-correctness-witnesses.xml
	wget https://raw.githubusercontent.com/sosy-lab/sv-comp/master/benchmark-defs/cpa-seq-validate-violation-witnesses.xml
	git clone --depth=1 https://github.com/sosy-lab/cpachecker.git
	cd cpachecker
	ant
	cd ..
	ln -s cpachecker/scripts/cpa.sh cpa.sh
	ln -s cpachecker/config/ config
	### manually tweak the requiredfiles and option name=-witness lines in cpa-seq-validate*.xml
	bin/benchexec cpa-seq-validate-correctness-witnesses.xml
	bin/benchexec cpa-seq-validate-violation-witnesses.xml
	```

## SYSTEM REQUIREMENTS:
   The tool has been tested to be stable on **Ubuntu 18.04**	

## RELEASE:
Source code for the tool to be made public soon.

## Contributors
   *	Eti Chaudhary, Masters student in the Department of Computer Science and Engineering, IIT Hyderabad
   *	[Saurabh Joshi](https://sbjoshi.github.io), Assistant Professor in the Department of Computer Science and Engineering, IIT Hyderabad

## Acknowledgements
   * This project is financially supported by Department of Science and Technology (DST) of India, through ECR 2017 grant.
