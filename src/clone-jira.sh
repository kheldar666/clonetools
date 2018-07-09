#!/usr/bin/env bash

# Script name
scriptName=`basename $0`

# loading external configuration
source ./lib/config.shlib;

# Help Screen
helpScreen() {
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

    SSH_COMMAND="ssh -i $(config_get SSH_PRIV_KEY) -o StrictHostKeyChecking=no -l $(config_get SSH_USER)"
    RSYNC_OPTIONS="$(config_get RSYNC_OPTIONS)"
    RSYNC_REMOTE_SUDO="$(config_get RSYNC_REMOTE_SUDO)"

    RSYNC_SRC_JIRA_FOLDER="$(config_get SSH_USER)@$(config_get SSH_SRC_HOST):$(config_get RSYNC_SRC_JIRA_FOLDER)"
    RSYNC_DST_JIRA_FOLDER="$(config_get RSYNC_DST_JIRA_FOLDER)"

    # Making sure the destination folders exists
    mkdir -p ${RSYNC_DST_JIRA_FOLDER}
    mkdir -p ${RSYNC_DST_JIRA_DATA_FOLDER}

    # Launching the rsync process

    if [ ${#SSH_COMMAND} -eq 0 ] ; then
       rsync ${RSYNC_OPTIONS} --exclude="logs" --exclude="temp" ${RSYNC_SRC_JIRA_FOLDER} ${RSYNC_DST_JIRA_FOLDER}
    else
        if [ ${#RSYNC_REMOTE_SUDO} -eq 0 ] ; then
            rsync ${RSYNC_OPTIONS} --exclude="logs" --exclude="temp" -e "${SSH_COMMAND}" ${RSYNC_SRC_JIRA_FOLDER} ${RSYNC_DST_JIRA_FOLDER}
        else
            rsync ${RSYNC_OPTIONS} --exclude="logs" --exclude="temp" -e "${SSH_COMMAND}" --rsync-path="${RSYNC_REMOTE_SUDO}" ${RSYNC_SRC_JIRA_FOLDER} ${RSYNC_DST_JIRA_FOLDER}
        fi
    fi

    #Recreate the excluded folders
    mkdir -p ${RSYNC_DST_JIRA_FOLDER}/logs
    mkdir -p ${RSYNC_DST_JIRA_FOLDER}/temp
}

syncJiraDataFiles() {
    echo "Synching JIRA Data files from Production to Local Folder"

    SSH_COMMAND="ssh -i $(config_get SSH_PRIV_KEY) -o StrictHostKeyChecking=no -l $(config_get SSH_USER)"
    RSYNC_OPTIONS="$(config_get RSYNC_OPTIONS)"
    RSYNC_REMOTE_SUDO="$(config_get RSYNC_REMOTE_SUDO)"

    RSYNC_SRC_JIRA_DATA_FOLDER="$(config_get SSH_USER)@$(config_get SSH_SRC_HOST):$(config_get RSYNC_SRC_JIRA_DATA_FOLDER)"
    RSYNC_DST_JIRA_DATA_FOLDER="$(config_get RSYNC_DST_JIRA_DATA_FOLDER)"

    if [ ${#SSH_COMMAND} -eq 0 ] ; then
        rsync ${RSYNC_OPTIONS} --exclude="caches" --exclude="tmp" --exclude="log"  ${RSYNC_SRC_JIRA_DATA_FOLDER} ${RSYNC_DST_JIRA_DATA_FOLDER}
    else
        if [ ${#RSYNC_REMOTE_SUDO} -eq 0 ] ; then
            rsync ${RSYNC_OPTIONS} --exclude="caches" --exclude="tmp" --exclude="log" -e "${SSH_COMMAND}" ${RSYNC_SRC_JIRA_DATA_FOLDER} ${RSYNC_DST_JIRA_DATA_FOLDER}
        else
            rsync ${RSYNC_OPTIONS} --exclude="caches" --exclude="tmp" --exclude="log" -e "${SSH_COMMAND}" --rsync-path="${RSYNC_REMOTE_SUDO}" ${RSYNC_SRC_JIRA_DATA_FOLDER} ${RSYNC_DST_JIRA_DATA_FOLDER}
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
    DB_NEW_CONNECTION_STRING="$(config_get DB_JIRA_DST_CONNECTION_STRING)"
    DB_NEW_USERNAME="$(config_get DB_JIRA_DST_USERNAME)"
    DB_NEW_PASSWORD="$(config_get DB_JIRA_DST_PASSWORD)"

    # Unlike in the test file, because of the way we load the variable, we don't need to escape again here.
    if [[ "${OSTYPE}" == "linux-gnu" ]]; then
        # FOR LINUX
        sed -i "s#<url>.*</url>#<url>${DB_NEW_CONNECTION_STRING}</url>#g" ${RSYNC_DST_JIRA_DATA_FOLDER}/dbconfig.xml
        sed -i "s#<username>.*</username>#<username>${DB_NEW_USERNAME}</username>#g" ${RSYNC_DST_JIRA_DATA_FOLDER}/dbconfig.xml
        sed -i "s#<password>.*</password>#<password>${DB_NEW_PASSWORD}</password>#g" ${RSYNC_DST_JIRA_DATA_FOLDER}/dbconfig.xml
    elif [[ "$OSTYPE" == "darwin"* ]]; then
        # FOR MAC OSX
        sed -i "" "s#<url>.*</url>#<url>${DB_NEW_CONNECTION_STRING}</url>#g" ${RSYNC_DST_JIRA_DATA_FOLDER}/dbconfig.xml
        sed -i "" "s#<username>.*</username>#<username>${DB_NEW_USERNAME}</username>#g" ${RSYNC_DST_JIRA_DATA_FOLDER}/dbconfig.xml
        sed -i "" "s#<password>.*</password>#<password>${DB_NEW_PASSWORD}</password>#g" ${RSYNC_DST_JIRA_DATA_FOLDER}/dbconfig.xml
    else
        echo "Unsupported OS :${OSTYPE}. Exiting...."
        exit 1
    fi
}
# We trigger a backup of the data on MySQL Server
backupSourceDb() {
    SSH_COMMAND="ssh -i $(config_get SSH_PRIV_KEY) -o StrictHostKeyChecking=no $(config_get SSH_USER)@$(config_get DB_JIRA_SRC_HOST)"
    MYSQL_HOST="$(config_get DB_JIRA_SRC_HOST)"
    MYSQL_USER="$(config_get DB_JIRA_SRC_USERNAME)"
    MYSQL_PASSWORD="$(config_get DB_JIRA_SRC_PASSWORD)"
    MYSQL_DB="$(config_get DB_JIRA_SRC_DBNAME)"
    MYSQLDUMP="$(config_get MYSQL_SRC_MYSQLDUMP)"

    TIMESTAMP=$(date +"%Y-%m-%d_%H-%M-%S")
    DUMP="$(config_get MYSQL_LOCAL_BACKUP_DIR)/BKUP_${TIMESTAMP}.sql"

    mkdir -p "$(config_get MYSQL_LOCAL_BACKUP_DIR)"

    REMOTE_MYSQL_COMMAND="$MYSQLDUMP --force --opt -h $MYSQL_HOST --user=$MYSQL_USER -p$MYSQL_PASSWORD --databases $MYSQL_DB"
    ${SSH_COMMAND} "${REMOTE_MYSQL_COMMAND}" > ${DUMP}
}

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
            helpScreen
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

if [ ${RESUME} -lt 5 ] ; then
    backupSourceDb
fi


echo "----------------------------------------------"
echo "JIRA Cloning is Done. Have a great day ahead !"
echo "----------------------------------------------"
