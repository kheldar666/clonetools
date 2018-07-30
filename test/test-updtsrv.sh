#!/usr/bin/env bash

source ../src/lib/config.shlib; # load the config library functions

# We need to use # instead of / in the sed expression to be able to support the / in the path
# https://www.unix.com/shell-programming-and-scripting/148161-expand-environment-variable-sed-when-variable-contains-slash.html

# Server.xml Configuration
JIRA_SRC_HOST=src.domain.name.com
JIRA_DST_HOST=dst.another.domain.com

cp -f ./server.xml.sample ./server.xml.output

if [[ "${OSTYPE}" == "linux-gnu" ]]; then
    # FOR LINUX
    sed -i "s#$(escape_var "${JIRA_SRC_HOST}")#${JIRA_DST_HOST}#g" server.xml.output
elif [[ "$OSTYPE" == "darwin"* ]]; then
    # FOR MAC OSX
    # Need to add the empty string at the beginning for OSX compatibility
    # https://myshittycode.com/2014/07/24/os-x-sed-extra-characters-at-the-end-of-l-command-error/
    sed -i "" "s#\"$(escape_var "${JIRA_SRC_HOST}")\"#\"${JIRA_DST_HOST}\"#g" server.xml.output
else
    echo "Unsupported OS :${OSTYPE}. Exiting...."
    exit 1
fi