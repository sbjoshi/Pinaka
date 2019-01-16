# Pinaka 0.1

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

## SYSTEM REQUIREMENTS:
   libstdc++.so.6 & gcc 7.3.0 are required on **Ubuntu 18.04**	

## RELEASE:
Source code for the tool to be made public soon.

## Contributors
   *	Eti Chaudhary, Masters student in the Department of Computer Science and Engineering, IIT Hyderabad
   *	[Saurabh Joshi](https://sbjoshi.github.io), Assistant Professor in the Department of Computer Science and Engineering, IIT Hyderabad

## Acknowledgements
   * This project is financially supported by Department of Science and Technology (DST) of India, through ECR 2017 grant.
