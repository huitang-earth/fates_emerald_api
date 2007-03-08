#!/bin/sh 
#

if [ $# -ne 1 ]; then
    echo "TSMtools.sh: incorrect number of input arguments" 
    exit 1
fi

test_name=TSMtools.$1

if [ -f ${CLM_TESTDIR}/${test_name}/TestStatus ]; then
    if grep -c PASS ${CLM_TESTDIR}/${test_name}/TestStatus > /dev/null; then
        echo "TSMtools.sh: smoke test has already passed; results are in "
	echo "        ${CLM_TESTDIR}/${test_name}" 
        exit 0
    else
	read fail_msg < ${CLM_TESTDIR}/${test_name}/TestStatus
        prev_jobid=${fail_msg#*job}

	if [ $JOBID = $prev_jobid ]; then
            echo "TSMtools.sh: smoke test has already failed for this job - will not reattempt; "
	    echo "        results are in: ${CLM_TESTDIR}/${test_name}" 
	    exit 2
	else
	    echo "TSMtools.sh: this smoke test failed under job ${prev_jobid} - moving those results to "
	    echo "        ${CLM_TESTDIR}/${test_name}_FAIL.job$prev_jobid and trying again"
            cp -rp ${CLM_TESTDIR}/${test_name} ${CLM_TESTDIR}/${test_name}_FAIL.job$prev_jobid
        fi
    fi
fi

cfgdir=${CLM_ROOT}/tools/$1
rundir=${CLM_TESTDIR}/${test_name}
if [ -d ${rundir} ]; then
    rm -r ${rundir}
fi
mkdir -p ${rundir} 
if [ $? -ne 0 ]; then
    echo "TSMtools.sh: error, unable to create work subdirectory" 
    exit 3
fi
cd ${rundir}

echo "TSMtools.sh: calling TCBtools.sh to prepare $1 executable" 
${CLM_SCRIPTDIR}/TCBtools.sh $1
rc=$?
if [ $rc -ne 0 ]; then
    echo "TSMtools.sh: error from TCBtools.sh= $rc" 
    echo "FAIL.job${JOBID}" > TestStatus
    exit 4
fi

if [ ! -f ${cfgdir}/$1.namelist ]; then
    echo "TSMtools.sh: namelist options file ${cfgdir}/$1.namelist not found" 
    echo "FAIL.job${JOBID}" > TestStatus
    exit 5
fi


echo "TSMtools.sh: running $1; output in ${CLM_TESTDIR}/${test_name}/test.log" 

${CLM_TESTDIR}/TCB.$1/$1 < ${cfgdir/$1.namelist >> test.log 2>&1
rc=$?
if [ $rc -eq 0 ] && grep -c "TERMINATING $1" test.log > /dev/null; then
    echo "TSMtools.sh: smoke test passed" 
    echo "PASS" > TestStatus
else
    echo "TSMtools.sh: error running $1, error= $rc" 
    echo "TSMtools.sh: see ${CLM_TESTDIR}/${test_name}/test.log for details"
    echo "FAIL.job${JOBID}" > TestStatus
    exit 8
fi

exit 0