# Pinaka 0.1

## How Pinaka works?
Pinaka is a *single-path* symbolic execution engine incorporated with incremental solving and eager infeasibility checks. It supports two incremental modes: Partial and Full Incremental. In Partial Incremental Mode, a single solver instance is maintained along a single search path. However, a new instance is created everytime a backtrack happens. In Full Incremental Mode, a single solver instance is maintained throughout the search process. Different search paths are verified with the help of activation literals along that path.

### Full Incremental v/s Partial Incremental
Full Incremental mode is best suited for smaller programs having few (not too many) branches. As the branching in the test input increases, the solver size increases. Hence, when trying to verify a particular search path, all the other constraints (for the rest of the search tree explored so far) slow down the solver performance.
Consequently, Partial Incremental Mode is better suited for such cases. However, for cases having smaller search trees, the cost of instantiating a new  solver instance on any backtrack penalises Pinaka's performance more than Full Incremental Mode.

In a nutshell, the trade-off between the cost of creating new solver instance versus the size of the solver instance decides the better incremental mode to choose from.


### Search Strategies
Pinaka currently supports Breadth First and Depth First Search Stretegies. Although, DFS undoubtedly gives a higher performance, BFS was implemented with a plan to serve as a base for incorporating state-selection heuristics or hybrid search-strategies in future.


### Solver Backend
Pinaka's incremental solver API have been built on top of CProver's Solver APIs. Pinaka currently supports MiniSAT like solvers such as Glucose-Syrup, MapleSAT etc.

*Pinaka cannot currently support Z3 solver Backend, as the CProver version used itself doesnot provide Z3 APIs.*


## How is Pinaka different from Symex?
Pinaka has been built on top-of Symex(commit id: 9b5a72cf992d29a905441f9dfa6802379546e1b7). The following are the key attributes by which Pinaka varies from the Symex version mentioned above.

- *Incremental Solving*: In contrast to Symex, Pinaka seizes the advantage of incremental solving on top of single path symbolic execution
- *Eager Feasibility Checks*: Pinaka fires a query to the backend solver everytime a branching condition (including looping conditions) are encountered as opposed to Symex which only does so whenever an assert is reached.
For this reason,(for Pinaka) anytime while looping, an iteration of the loop becomes infeasible, the corresponding query fired at that point will deem UNSAT. *Hence, Pinaka can do away with specifying a unrolling bound on loops.*
- *Recursive Procedures*: The Symex version Pinaka is built on has a buggy support for recursive procedures. Hence, Pinaka uses it's own forked version where the said functionality has been added.
- *Ternary Operator*: Pinaka also handles ternary operators separately from Symex.
- *Breadth First Search*: Lastly, for Pinaka also allows BFS search strategy which is not supported on the corresponding Symex version.


## Pinaka & SVCOMP 2019

- The version of Pinaka that participated in SVCOMP 2019 ran **Depth First Search** in **Partial Incremental Mode**. These choices were simply a result of better performance on SVCOMP Benchmarks.
- Pinaka made use of **Glucose-Syrup** as its solver back-end for SVCOMP 2019 to yield a better overall performance.
- Pinaka participated in all ReachSafety sub-categories EXCEPT ReachSafety-Sequentialized, Termination and NoOverflows categories.
- Currently, Pinaka does not provide support for verification of concurrent programs. Non-participation in MemSafety & SoftwareSystems categories was merely due to a lack of time for the authors to be able to test the tool on these benchmarks.
Witness Validation for Pinaka is done by CProver framework itself.

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
As Pinaka, reaches the loop header, the current state continues inside the loop i.e. `condition1 == true`, while the state corresponding `condtion1 == false` is pushed onto a queue. Now further as the state corresponding `condition1 == true` encounters the if-statements, the current state continues down the path `condition2 == true`. Similarly, another state with `condition1 == true` and `condition2 == false` is pushed onto the queue.
Further, everytime either the loop-condition or the if-else condition is encountered, corresponding query is fired to the solver to check whether the state is feasible or not. If not, the next state is picked out from the queue and the process continues.

Following from the above description, and assuming the translation by CProver neither over-approximates nor under-approximates the C to GOTO-program conversion, Pinaka only terminates on the input if and only if all the concrete feasible program paths terminate.

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

* Once the run is complete, verification outcome and statistics are printed on the terminal. An outcome of 'VERIFICATION FAILED' implies that the asserting conditions in the source file donot hold. In order to produce a counter-example/error-trace, use the following option:
```
	./pinaka --show-trace <PATH-TO-SOURCE-FILE>
```

* Other options available may be explored from the help menu as follows:
```
	./pinaka --help
	or
	./pinaka -h
```

## SVCOMP Style Exectuion
### INTRUCTIONS to configure Pinaka in Benchexec:
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
* Ensure that you modify timelimit, memorylimit and cpuCores in pinaka.xml depending upon the resource limit you have.

### INTRUCTIONS to run BENCHMARKS:
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
