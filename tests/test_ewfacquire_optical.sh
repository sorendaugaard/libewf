#!/bin/bash
# Acquire tool testing script
#
# Version: 20160411

EXIT_SUCCESS=0;
EXIT_FAILURE=1;
EXIT_IGNORE=77;

TEST_PREFIX=`dirname ${PWD}`;
TEST_PREFIX=`basename ${TEST_PREFIX} | sed 's/^lib\([^-]*\)/\1/'`;
TEST_SUFFIX="acquire_optical";

TEST_PROFILE="${TEST_PREFIX}${TEST_SUFFIX}";
TEST_DESCRIPTION="${TEST_PREFIX}${TEST_SUFFIX}";
OPTION_SETS="format:encase5 format:encase6 format:encase7 format:encase7-v2";

TEST_TOOL_DIRECTORY="../${TEST_PREFIX}tools";
TEST_TOOL="${TEST_PREFIX}acquire";
INPUT_DIRECTORY="input";
INPUT_GLOB="*.[Cc][Uu][Ee]";

test_callback()
{ 
	local TMPDIR=$1;
	local TEST_SET_DIRECTORY=$2;
	local TEST_OUTPUT=$3;
	local TEST_EXECUTABLE=$4;
	local TEST_INPUT=$5;
	shift 5;
	local ARGUMENTS=$@;

	TEST_EXECUTABLE=$( readlink_f "${TEST_EXECUTABLE}" );
	INPUT_FILE_FULL_PATH=$( readlink_f "${INPUT_FILE}" );
	INPUT_BASENAME=`echo "${INPUT_FILE_FULL_PATH}" | sed 's/[.][cC][uU][eE]$//' | sed 's/_[0-9]*$//'`;

	local TEST_LOG="${TEST_OUTPUT}.log";

	TEST_DESCRIPTION="";

	(cd ${TMPDIR} && run_test_with_arguments "${TEST_DESCRIPTION}" "${TEST_EXECUTABLE}" ${ARGUMENTS[@]} -T"${INPUT_FILE_FULL_PATH}" ${INPUT_BASENAME}*.[Ii][Ss][Oo] | sed '1,2d' > "${TEST_LOG}");
	local RESULT=$?;

	local TEST_RESULTS="${TMPDIR}/${TEST_LOG}";
	local STORED_TEST_RESULTS="${TEST_SET_DIRECTORY}/${TEST_LOG}.gz";

	if test -f "${STORED_TEST_RESULTS}";
	then
		# Using zcat here since zdiff has issues on Mac OS X.
		# Note that zcat on Mac OS X requires the input from stdin.
		zcat < "${STORED_TEST_RESULTS}" | diff "${TEST_RESULTS}" -;
		RESULT=$?;
	else
		gzip "${TEST_RESULTS}";

		mv "${TEST_RESULTS}.gz" ${TEST_SET_DIRECTORY};
	fi
	if test ${RESULT} -eq ${EXIT_SUCCESS};
	then
		run_test_with_input_and_arguments "${VERIFY_TOOL}" ${TMPDIR}/acquire_optical.* -q > /dev/null;
		local RESULT=$?;
	fi
	return ${RESULT};
}

if ! test -z ${SKIP_TOOLS_TESTS};
then
	exit ${EXIT_IGNORE};
fi

TEST_EXECUTABLE="${TEST_TOOL_DIRECTORY}/${TEST_TOOL}";

if ! test -x "${TEST_EXECUTABLE}";
then
	TEST_EXECUTABLE="${TEST_TOOL_DIRECTORY}/${TEST_TOOL}.exe";
fi

if ! test -x "${TEST_EXECUTABLE}";
then
	echo "Missing test executable: ${TEST_EXECUTABLE}";

	exit ${EXIT_FAILURE};
fi

VERIFY_TOOL="../${TEST_PREFIX}tools/${TEST_PREFIX}verify";

if ! test -x "${VERIFY_TOOL}";
then
	VERIFY_TOOL="../${TEST_PREFIX}tools/${TEST_PREFIX}verify.exe";
fi

if ! test -x "${VERIFY_TOOL}";
then
	echo "Missing executable: ${VERIFY_TOOL}";

	exit ${EXIT_FAILURE};
fi

TEST_RUNNER="tests/test_runner.sh";

if ! test -f "${TEST_RUNNER}";
then
	TEST_RUNNER="./test_runner.sh";
fi

if ! test -f "${TEST_RUNNER}";
then
	echo "Missing test runner: ${TEST_RUNNER}";

	exit ${EXIT_FAILURE};
fi

source ${TEST_RUNNER};

run_test_on_input_directory "${TEST_PROFILE}" "${TEST_DESCRIPTION}" "with_callback" "${OPTION_SETS}" "${TEST_EXECUTABLE}" "${INPUT_DIRECTORY}" "${INPUT_GLOB}" -CCase -DDescription -EEvidence -eExaminer -moptical -Mlogical -NNotes -q -tacquire_optical -u;
RESULT=$?;

exit ${RESULT};

