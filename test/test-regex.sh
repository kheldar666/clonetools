#!/usr/bin/env bash

# loading external configuration
source ../src/lib/config.shlib;

TEST_STRING="CREATE DATABASE /*!32312 IF NOT EXISTS*/ \`jira\` /*!40100 DEFAULT CHARACTER SET utf8 COLLATE utf8_bin */;"

echo ${TEST_STRING}

ESCAPED_STRING="$(escape_var "${TEST_STRING}")"

echo ${ESCAPED_STRING}