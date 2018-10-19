## INTRUCTIONS to configure Pinaka in Benchexec:

* Get Benchmarks and Benchexec
	```
	git clone --depth=1 https://github.com/sosy-lab/sv-benchmarks
	git clone https://github.com/sosy-lab/benchexec
	cd benchexec
	```

* In current directory, add files pinaka.xml and pinaka-wrapper.sh and pinaka binary
* W.r.t the currecnt working directory, add pinaka.py file in 'benchexec/tools' sub-directory.


## INTRUCTIONS TO RUN BENCHMARKS:
* Navigate back to top-level benchexec directory
* To run a set of tasks :
	```
	sed -i 's/witness.graphml/${logfile_path_abs}${inputfile_name}-witness.graphml/' pinaka.xml
	sudo chmod o+wt '/sys/fs/cgroup/cpuset/
	sudo chmod o+wt '/sys/fs/cgroup/cpu,cpuacct/'
	sudo chmod o+wt '/sys/fs/cgroup/freezer/'
	sudo chmod o+wt '/sys/fs/cgroup/memory/'
	sudo swapoff -a
	bin/benchexec pinaka.xml --tasks="ReachSafety-TASKSET"
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