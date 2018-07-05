#!/usr/bin/env bash

RSYNC_DST_JIRA_DATA_FOLDER=/path/to/new/home
JIRA_NEW_HOME="jira\.home = ${RSYNC_DST_JIRA_DATA_FOLDER}"
echo "Escaped Path : ${JIRA_NEW_HOME}"

# We need to use # instead of / in the sed expression to be able to support the / in the path
# https://www.unix.com/shell-programming-and-scripting/148161-expand-environment-variable-sed-when-variable-contains-slash.html

sed "s#^[^#]*jira\.home.*#${JIRA_NEW_HOME}#g" < ./jira-application.properties.sample > ./jira-application.properties.output