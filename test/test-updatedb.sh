#!/usr/bin/env bash

# loading external functions
source ../src/lib/config.shlib;

JIRA_SRC_BASE_URL=https://www.example.com/jira
JIRA_DST_BASE_URL=https://uat.example.com/jira

JIRA_SRC_DBNAME=jira
JIRA_DST_DBNAME=jira-uat

cp -f ./test.sql.orig ./test.sql
DUMP=./test.sql


if [[ "${OSTYPE}" == "linux-gnu" ]]; then
    # FOR LINUX
    sed -i "s#${JIRA_SRC_BASE_URL//\./\\.}#${JIRA_DST_BASE_URL}</url>#g" ${DUMP}
    ORG_STRING=$(sed -n "s#\(.*Current Database[^\`]*\`${JIRA_SRC_DBNAME}\`\)#\1#p"  ${DUMP})
    UPT_STRING=${ORG_STRING/${JIRA_SRC_DBNAME}/${JIRA_DST_DBNAME}}

    sed -i "s#${ORG_STRING//\*/\\*}#${UPT_STRING}#g" ${DUMP}


    ORG_STRING=$(sed -n "s#\(CREATE DATABASE[^\`]*\`${JIRA_SRC_DBNAME}\`\)#\1#p"  ${DUMP})
    UPT_STRING=${ORG_STRING/${JIRA_SRC_DBNAME}/${JIRA_DST_DBNAME}}

    sed -i "s#${ORG_STRING//\*/\\*}#${UPT_STRING}#g" ${DUMP}

    ORG_STRING=$(sed -n "s#\(USE[^\`]*\`${JIRA_SRC_DBNAME}\`\)#\1#p"  ${DUMP})
    UPT_STRING=${ORG_STRING/${JIRA_SRC_DBNAME}/${JIRA_DST_DBNAME}}

    sed -i "s#${ORG_STRING//\*/\\*}#${UPT_STRING}#g" ${DUMP}
elif [[ "$OSTYPE" == "darwin"* ]]; then
    # FOR MAC OSX
    # Need to add the empty string at the beginning for OSX compatibility
    # https://myshittycode.com/2014/07/24/os-x-sed-extra-characters-at-the-end-of-l-command-error/
    #LC_CTYPE=C sed -i "" "s#${JIRA_SRC_BASE_URL//\./\\.}#${JIRA_DST_BASE_URL}#g" ${DUMP}
    #
    ORG_STRING=$(sed -n "s#\(.*Current Database[^\`]*\`${JIRA_SRC_DBNAME}\`\)#\1#p"  ${DUMP})
    UPT_STRING=${ORG_STRING/${JIRA_SRC_DBNAME}/${JIRA_DST_DBNAME}}

    sed -i "" "s#${ORG_STRING//\*/\\*}#${UPT_STRING}#g" ${DUMP}


    ORG_STRING=$(sed -n "s#\(CREATE DATABASE[^\`]*\`${JIRA_SRC_DBNAME}\`\)#\1#p"  ${DUMP})
    UPT_STRING=${ORG_STRING/${JIRA_SRC_DBNAME}/${JIRA_DST_DBNAME}}

    sed -i "" "s#${ORG_STRING//\*/\\*}#${UPT_STRING}#g" ${DUMP}

    ORG_STRING=$(sed -n "s#\(USE[^\`]*\`${JIRA_SRC_DBNAME}\`\)#\1#p"  ${DUMP})
    UPT_STRING=${ORG_STRING/${JIRA_SRC_DBNAME}/${JIRA_DST_DBNAME}}

    sed -i "" "s#${ORG_STRING//\*/\\*}#${UPT_STRING}#g" ${DUMP}
else
    echo "Unsupported OS :${OSTYPE}. Exiting...."
    exit 1
fi