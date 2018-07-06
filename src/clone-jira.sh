#!/usr/bin/env bash

# Script name
scriptName=`basename $0`

# loading external configuration
source ./lib/config.shlib;

RSYNC_OPTIONS="$(config_get RSYNC_OPTIONS)"
RSYNC_SSH_OPTIONS="ssh -i $(config_get SSH_PRIV_KEY) -o StrictHostKeyChecking=no -l $(config_get SSH_USER)"
RSYNC_REMOTE_SUDO="$(config_get RSYNC_REMOTE_SUDO)"

RSYNC_SRC_JIRA_FOLDER="$(config_get SSH_USER)@$(config_get SSH_SRC_HOST):$(config_get RSYNC_SRC_JIRA_FOLDER)"
RSYNC_DST_JIRA_FOLDER="$(config_get RSYNC_DST_JIRA_FOLDER)"

RSYNC_SRC_JIRA_DATA_FOLDER="$(config_get SSH_USER)@$(config_get SSH_SRC_HOST):$(config_get RSYNC_SRC_JIRA_DATA_FOLDER)"
RSYNC_DST_JIRA_DATA_FOLDER="$(config_get RSYNC_DST_JIRA_DATA_FOLDER)"

# Help Screen
help() {
  echo "${scriptName} [OPTIONS]

    Bash utility for cloning a JIRA instance to anotehr Server

    GitHub Project:
      https://github.com/kheldar666/clonetools

    Options:
      -r|--resume=STEP           Resuming the Script after step STEP. Default is 0.
"
}

stopJIRA() {
    # First we need to stop local services
    /etc/init.d/jira stop
    if [ $? -ne 0 ]; then
        read -p "JIRA did not shutdown properly, exiting? (Y/N)" yn
        case ${yn} in
            [Yy]* ) exit 1;;
            [Nn]* ) echo "Continuing....";;
        esac
    fi
}

syncJiraProgramFiles() {
    # Now we sync all data from production to local folders
    echo "Synching JIRA Program files from Production to Local Folder"

    # Making sure the destination folders exists
    mkdir -p ${RSYNC_DST_JIRA_FOLDER}
    mkdir -p ${RSYNC_DST_JIRA_DATA_FOLDER}

    # Launching the rsync process

    if [ ${#RSYNC_SSH_OPTIONS} -eq 0 ] ; then
       rsync ${RSYNC_OPTIONS} --exclude="logs" --exclude="temp" ${RSYNC_SRC_JIRA_FOLDER} ${RSYNC_DST_JIRA_FOLDER}
    else
        if [ ${#RSYNC_REMOTE_SUDO} -eq 0 ] ; then
            rsync ${RSYNC_OPTIONS} --exclude="logs" --exclude="temp" -e "${RSYNC_SSH_OPTIONS}" ${RSYNC_SRC_JIRA_FOLDER} ${RSYNC_DST_JIRA_FOLDER}
        else
            rsync ${RSYNC_OPTIONS} --exclude="logs" --exclude="temp" -e "${RSYNC_SSH_OPTIONS}" --rsync-path="${RSYNC_REMOTE_SUDO}" ${RSYNC_SRC_JIRA_FOLDER} ${RSYNC_DST_JIRA_FOLDER}
        fi
    fi

    #Recreate the excluded folders
    mkdir -p ${RSYNC_DST_JIRA_FOLDER}/logs
    mkdir -p ${RSYNC_DST_JIRA_FOLDER}/temp
}

syncJiraDataFiles() {
    echo "Synching JIRA Data files from Production to Local Folder"
    if [ ${#RSYNC_SSH_OPTIONS} -eq 0 ] ; then
        rsync ${RSYNC_OPTIONS} --exclude="caches" --exclude="tmp" --exclude="log"  ${RSYNC_SRC_JIRA_DATA_FOLDER} ${RSYNC_DST_JIRA_DATA_FOLDER}
    else
        if [ ${#RSYNC_REMOTE_SUDO} -eq 0 ] ; then
            rsync ${RSYNC_OPTIONS} --exclude="caches" --exclude="tmp" --exclude="log" -e "${RSYNC_SSH_OPTIONS}" ${RSYNC_SRC_JIRA_DATA_FOLDER} ${RSYNC_DST_JIRA_DATA_FOLDER}
        else
            rsync ${RSYNC_OPTIONS} --exclude="caches" --exclude="tmp" --exclude="log" -e "${RSYNC_SSH_OPTIONS}" --rsync-path="${RSYNC_REMOTE_SUDO}" ${RSYNC_SRC_JIRA_DATA_FOLDER} ${RSYNC_DST_JIRA_DATA_FOLDER}
        fi
    fi

    # Recreate the excluded folders
    mkdir -p ${RSYNC_DST_JIRA_DATA_FOLDER}/caches
    mkdir -p ${RSYNC_DST_JIRA_DATA_FOLDER}/tmp
    mkdir -p ${RSYNC_DST_JIRA_DATA_FOLDER}/log
}

updateJiraConfigFiles() {
    # Now we need to cleanup the Configuration files
    # Update jira-application.properties
    JIRA_NEW_HOME="jira\.home = ${RSYNC_DST_JIRA_DATA_FOLDER}"

    # User the " instead of ' for the sed command to allow the expansion of the variables
    # We need to use # instead of / in the sed expression to be able to support the / in the path
    # https://www.unix.com/shell-programming-and-scripting/148161-expand-environment-variable-sed-when-variable-contains-slash.html
    sed -i "s#^[^#]*jira\.home.*#${JIRA_NEW_HOME}#g" ${RSYNC_DST_JIRA_FOLDER}/atlassian-jira/WEB-INF/classes/jira-application.properties

    # Update of dbconfig.xml
    DB_NEW_CONNECTION_STRING="$(config_get DB_NEW_CONNECTION_STRING)"
    DB_NEW_USERNAME="$(config_get DB_NEW_USERNAME)"
    DB_NEW_PASSWORD="$(config_get DB_NEW_PASSWORD)"

    # Unlike in the test file, because of the way we load the variable, we don't need to escape again here.
    sed -i "s#<url>.*</url>#<url>${DB_NEW_CONNECTION_STRING}</url>#g" ${RSYNC_DST_JIRA_DATA_FOLDER}/dbconfig.xml
    sed -i "s#<username>.*</username>#<username>${DB_NEW_USERNAME}</username>#g" ${RSYNC_DST_JIRA_DATA_FOLDER}/dbconfig.xml
    sed -i "s#<password>.*</password>#<password>${DB_NEW_PASSWORD}</password>#g" ${RSYNC_DST_JIRA_DATA_FOLDER}/dbconfig.xml
}
# We trigger a backup of the data on MySQL Server

# We must cleanup the backup before restoring the data

# We now need to restore the Data in the UAT DB

# Finally we start the services

# Read Script Args
RESUME=0
for i in "$@"
do
    case ${i} in
        -r=*|--resume=*)
            RESUME="${i#*=}"
            shift
        ;;
        *)
            # Unknown Option
            echo "${i} => Unknown Script Option. Aborting."
            echo ""
            help
            exit 1
        ;;
    esac
done

# Functions Call
if [ ${RESUME} -lt 1 ] ; then
    stopJIRA
fi

if [ ${RESUME} -lt 2 ] ; then
    syncJiraProgramFiles
fi

if [ ${RESUME} -lt 3 ] ; then
    syncJiraDataFiles
fi

if [ ${RESUME} -lt 4 ] ; then
    updateJiraConfigFiles
fi

echo "----------------------------------------------"
echo "JIRA Cloning is Done. Have a great day ahead !"
echo "----------------------------------------------"
