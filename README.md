# Pinaka 0.1

- [How Pinaka works?](#how-pinaka-works)
	* [Full Incremental v/s Partial Incremental](#full-incremental-vs-partial-incremental)
	* [Search Strategies](#search-strategies)
	* [Solver Backend](#solver-backend)
- [How is Pinaka different from Symex?](#how-is-pinaka-different-from-symex)
- [Pinaka in SVCOMP 2019](#pinaka-in-svcomp-2019)
	* [Proving Termination with Pinaka](#proving-termination-with-pinaka)
- [General Execution Instructions](#general-execution-instructions)
- [SVCOMP Style Execution](#svcomp-style-execution)
	* [INSTRUCTIONS to configure Pinaka in Benchexec](#instructions-to-configure-pinaka-in-benchexec)
	* [INSTRUCTIONS to run BENCHMARKS](#instructions-to-run-benchmarks)
- [System Requirements](#system-requirements)
- [Contributors](#contributors)
- [Acknowledgements](#acknowledgements)



## How Pinaka works?
Pinaka is a *single-path* symbolic execution engine incorporated with incremental solving and eager infeasibility checks. The keyword *single-path* means that at any given moment, Pinaka is focused
only on one particular path. Two paths are **never** merged. This may lead to path explosion problem as the number of branches increase in a program. That is where eager infeasibility checks
and incremental solving help. Along a path, when Pinaka encounters a branch, it makes two queries: (1) whether the path can proceed along the _true_ branch, and (2) whether the path can proceed
along the _false_ branch. If the answer to one of them (or both of these) is a negative, then no further exploration is done along that branch. Since the query to a solver is being made at every branch, incremental solving is used to make it efficient. 

It supports two incremental modes: Partial and Full Incremental. In Partial Incremental Mode, a single solver instance is maintained along a single search path. However, a new instance is created every time a backtrack happens and a different path/branch has to be explored. In Full Incremental Mode, a single solver instance is maintained throughout the search process. Upon backtrack, the old path is logically disabled through the use of activation literals.

Consider the following snippet:
```cpp
while(x < 10)
{
	y = y + 1
	
	if(y < 5)
	{
		x = x + 1
	}
}
```
In the above snippet, suppose via some search path the loop header is reached.  At this point there are two possible paths to take, inside the loop (i.e ``x<10``) or outside the loop (i.e. ``x>=10``).

In Partial Incremental Mode, at this point we have the current state and its associated solver instance. In this mode, as mentioned above, each solver instance only encodes a single path, the current state's solver instance can be further re-used for ONE of the branching paths. Say, we reuse it for the path ``x<10``. A query will now be fired to the solver by encoding the necessary constraints from the last time a query was fired to the current program point with ``x<10``. If the query turns out to be UNSAT, a backtrack must happen and a different branch must be explored. Now a similar check is run for the state corresponding (``x>=10``). Note that for this state a new solver instance will be created and encoded till this program point.

In contrast, for Full Incremental Mode, as a single solver instance is maintained throughout the execution, both the paths (along the branches ``x<10`` and ``x>=10``) will be encoded in the same instance via the use of activation variables. Say, activation variable ``alpha_1`` is used for path along ``x<10``. Hence, the following conditions get appended to the solver instance:
	
     alpha_1 ==> x<10,  where '==>' has been used for implications.

For the feasibility checks of the path going inside the loop,  the corresponding activation variable ``alpha_1``,  in addition to those activation literals for the portion of the path before the loop header can be set as solver assumptions. By setting these assumptions, the Left Hand Side (LHS) of the implication becomes TRUE and for the implication to hold the constraints on the Right Hand Side (RHS) is enforced. Thereby, _activating_ the particular path in the search tree as enforced by the corresponding activation literals. Upon back track, a new activation literal ``alpha_2`` is introduced to enforce the alternate branch along ``x>=10`` (i.e., ``alpha_2 ==> x>=10``). Now, ``alpha_2`` as well as ``NOT alpha_1`` is set as assumptions to activate the alternate path while logically disabling the previous path.

### Full Incremental v/s Partial Incremental
Full Incremental mode is best suited for smaller programs having a few (not too many) branches. For a program with too many paths, the number of clauses inside the solver keeps increasing as the solver is instantiated only once. Hence, when trying to verify a particular search path, all the other constraints (for the rest of the search tree explored so far) slow down the solver performance. Also the memory footprint keeps increasing in Full Incremental mode.
Consequently, Partial Incremental Mode is better suited for cases where number of paths is very large. However, for cases having smaller search trees, the cost of instantiating a new  solver instance on any backtrack penalizes Pinaka's performance more than Full Incremental Mode.

In a nutshell, the trade-off between the cost of creating new solver instance versus the size of formula inside the solver instance decides which incremental mode will be faster on a given instance.


### Search Strategies
Pinaka currently supports Breadth First Search (BFS) and Depth First Search (DFS) Strategies. Although, DFS undoubtedly gives a better performance, BFS was implemented with a plan to serve as a base for incorporating state-selection heuristics or hybrid search-strategies in future.


### Solver Backend
Pinaka's incremental solver API have been built on top of [CProver](http://www.cprover.org)'s SAT Solver APIs. Pinaka currently supports MiniSAT like solvers such as [Glucose-Syrup](http://www.labri.fr/perso/lsimon/glucose/), [MapleSAT](https://sites.google.com/a/gsd.uwaterloo.ca/maplesat/), [MiniSAT](http://minisat.se/) etc.

*Pinaka does not currently support Z3 solver Backend, as the CProver version used in Pinaka itself does not provide integration of SMT solvers through APIs.* The CPROVER version used to build Pinaka invokes SMT solvers through a shell and the formula is fed through a file, which is not beneficial for incremental solving. In future, we may look at SMT solver integration through APIs to better exploit incremental solving provided by SMT solvers.


## How is Pinaka different from Symex?
Pinaka-0.1 that participated in SVCOMP 2019 has been built on top-of [Symex(commit id: 9b5a72cf992d29a905441f9dfa6802379546e1b7)](https://github.com/diffblue/symex/tree/9b5a72cf992d29a905441f9dfa6802379546e1b7). The following are the key attributes by which Pinaka varies from the Symex version mentioned above. Whenever we mention Symex in this section, we mention the version referred to above.

- *Incremental Solving*: In contrast to Symex, Pinaka seizes the advantage of incremental solving on top of single path symbolic execution.
- *Eager Feasibility Checks*: Pinaka fires a query to the backend solver every time a branching condition (including looping conditions) are encountered as opposed to Symex which only does so whenever an assert is reached. *Note that newer version of Symex has the option to do eager infeasibility, however, this feature is NOT available on the Symex version used in Pinaka-0.1*
For this reason,(for Pinaka) while exploring a loop iteration along a path, when the entry condition of the loop becomes infeasible, the corresponding query fired at that point will become UNSAT.  *Hence, Pinaka does not require specifying an unrolling bound on loops.* However, this also means that Pinaka is potentially _non-terminating_ if there is a non-terminating path in a program for some input.
- *Recursive Procedures*: The Symex version Pinaka is built on has a buggy support for recursive procedures. Hence, Pinaka uses it's own forked version where the said functionality has been added.
- *Ternary Operator*: Pinaka also handles ternary operators separately from Symex as the Symex version mentioned above is buggy.
- *Breadth First Search*: Pinaka also allows BFS search strategy which is not supported on the corresponding Symex version.

**Note**: Later version of Symex implements Eager Feasibility checks and Breadth First Search. However, these features are missing from the version/fork used by Pinaka.

## Pinaka in SVCOMP 2019

- The version of Pinaka (Pinaka-0.1) that participated in SVCOMP 2019 ran **Depth First Search** in **Partial Incremental Mode**. These choices were simply a result of better performance on SVCOMP Benchmarks during testing phase.
- Pinaka-0.1 made use of **Glucose-Syrup**(Version 4.0) as its solver back-end for SVCOMP 2019 to yield a better overall performance.
- Pinaka-0.1 participated in Termination,  NoOverflows meta-categories and  all ReachSafety sub-categories EXCEPT ReachSafety-Sequentialized. The decision to not participate in other meta-categories because of lack of time for testing Pinaka-0.1 thoroughly on those categories.
- Currently, Pinaka does not provide support for verification of concurrent programs. Non-participation in MemSafety & SoftwareSystems categories was merely due to a lack of time for the authors to be able to test the tool on these benchmarks.
- Witness generation for Pinaka-0.1 is done by CProver framework itself.

### Proving Termination with Pinaka
Once again consider the example from above:
```cpp
while(x < 10)
{
	y = y + 1
	if(y < 5)
	{
		x = x + 1
	}
}
```
In order to track the workings along the sample program, consider the two cases depicted in the image below. The program point at which the control reaches the loop header has been marked by blue in the diagrams. The dotted branching paths are the paths unexplored for which the corresponding states are pushed onto a queue.

![alt text](https://drive.google.com/uc?export=view&id=1nSKtB4Nru-_6hn7YAIGhSbLiPoCjMdsC)

Consider the case depicted in the LEFT sub-diagram, where the control reaches the loop header. As Pinaka makes use of SSA encoding, let us assume, without loss of generality, that last SSA representations for x and y before entering the loop are x1 and y1, with values 8 and 1 respectively.
- At this point the current states continues along the path x1<10, while the state corresponding x1>=10 is pushed onto the queue. As the current state is feasible (x1 is indeed less than 10), the process continues.
- Further, the assignment to y is encoded as y2 = y1 + 1
- Again, a branching state is encountered. Hence, the current state continues along y2<5, while a new state corresponding y2>=5 is pushed onto the queue.
- A feasibility check is again performed on the current state. As it is deemed feasible, the control goes inside the if-block and the assignment to x gets encoded as shown in the figure.
- At this point, Pinaka again reaches the loop header after which the described process is repeated.

Now, consider the RIGHT sub-diagram. In this case, the SSA representations for x and y before entering the loop are x1 and y1, however, with values 8 and 5.
- As Pinaka hits the loop header, the current state continues along x1<10, while the state along x1>=10 us pushed onto the queue.
- A feasibility check for the current state (till the point x1<10) is performed, following which it enters the loop (as the result will be feasible for this particular case).
- Further, the assignment to y is encoded as y2 = y1 + 1
- Again, a branching state is hit. At this point, suppose the state corresponding y2<5 is pushed onto the queue and the current state moves alone y2>=5.
- A feasibility check for the current state (i.e. along y2>=5) will result as SAT. Hence, the process continues and the loop header is hit once again.
- The edge marked as RED at this point, denotes the path further which will run infinitely.
As the looping condition further down this path will never return UNSAT from feasibility checks, Pinaka itself would not terminate for such a case.


Following from the above description, and **assuming** that CProver does not have over-approximation or under-approximation during modeling of a C program, Pinaka only terminates for a safe input program if and only if all the concrete feasible program paths terminate. For unsafe programs, Pinaka may terminate on the first assertion violation that it discovers along a path. So for unsafe program, Pinaka may terminate even though there may be paths which are non-terminating for the program. For a safe program (which does not violate assertions), Pinaka only terminates if all the feasible paths of the input programs are terminating. Loops are unwound on-the-fly if the next iteration is deemed feasible, **therefore, Pinaka does not require loop unwinding limit**.

If there are over-approximations in CProver, then Pinaka may not terminate even though the input program is terminating along all the feasible paths for all inputs. Because for a spurious state, the
entry condition of a loop may continue to be feasible and Pinaka may keep on unwinding iterations through a loop. On the other hand, if there are under-approximations in CProver, then Pinaka
may falsely declare a program to be terminating, even though there may be a feasible concrete state for which the program may not terminate.


Therefore, under the assumption that CProver does not over-approximate or under-approximate, Pinaka will terminate for a safe program (i.e., a program which does not violate assertions) if and only if all the paths of the input program is terminating on all the inputs. In general, Pinaka is a _non-terminating_ tool.


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
   *	[Akash Banerjee](https://tifitis.github.io), Master's student in the [Department of Computer Science and Engineering](https://cse.iith.ac.in), [IIT Hyderabad](http://www.iith.ac.in)
   *	Eti Chaudhary, Masters student in the [Department of Computer Science and Engineering](https://cse.iith.ac.in), [IIT Hyderabad](http://www.iith.ac.in)
   *	[Saurabh Joshi](https://sbjoshi.github.io), Assistant Professor in the [Department of Computer Science and Engineering](https://cse.iith.ac.in), [IIT Hyderabad](https://www.iith.ac.in)
## Acknowledgements
   * This project is financially supported by Department of Science and Technology (DST) of India, through ECR 2017 grant.
