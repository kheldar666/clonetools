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

    local SSH_COMMAND="ssh -i $(config_get SSH_PRIV_KEY) -o StrictHostKeyChecking=no -l $(config_get SSH_USER)"
    local RSYNC_OPTIONS="$(config_get RSYNC_OPTIONS)"
    local RSYNC_REMOTE_SUDO="$(config_get RSYNC_REMOTE_SUDO)"

    local RSYNC_SRC_JIRA_FOLDER="$(config_get SSH_USER)@$(config_get SSH_SRC_HOST):$(config_get RSYNC_SRC_JIRA_FOLDER)"
    local RSYNC_DST_JIRA_FOLDER="$(config_get RSYNC_DST_JIRA_FOLDER)"

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

    local SSH_COMMAND="ssh -i $(config_get SSH_PRIV_KEY) -o StrictHostKeyChecking=no -l $(config_get SSH_USER)"
    local RSYNC_OPTIONS="$(config_get RSYNC_OPTIONS)"
    local RSYNC_REMOTE_SUDO="$(config_get RSYNC_REMOTE_SUDO)"

    local RSYNC_SRC_JIRA_DATA_FOLDER="$(config_get SSH_USER)@$(config_get SSH_SRC_HOST):$(config_get RSYNC_SRC_JIRA_DATA_FOLDER)"
    local RSYNC_DST_JIRA_DATA_FOLDER="$(config_get RSYNC_DST_JIRA_DATA_FOLDER)"

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
    local RSYNC_DST_JIRA_DATA_FOLDER="$(config_get RSYNC_DST_JIRA_DATA_FOLDER)"
    local JIRA_NEW_HOME="jira\.home = ${RSYNC_DST_JIRA_DATA_FOLDER}"

    # User the " instead of ' for the sed command to allow the expansion of the variables
    # We need to use # instead of / in the sed expression to be able to support the / in the path
    # https://www.unix.com/shell-programming-and-scripting/148161-expand-environment-variable-sed-when-variable-contains-slash.html
    sed -i "s#^[^#]*jira\.home.*#${JIRA_NEW_HOME}#g" ${RSYNC_DST_JIRA_FOLDER}/atlassian-jira/WEB-INF/classes/jira-application.properties

    # Update of dbconfig.xml
    local DB_NEW_CONNECTION_STRING="$(config_get DB_JIRA_DST_CONNECTION_STRING)"
    local DB_NEW_USERNAME="$(config_get DB_JIRA_DST_USERNAME)"
    local DB_NEW_PASSWORD="$(config_get DB_JIRA_DST_PASSWORD)"

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
transferDatabase() {
    local SSH_COMMAND="ssh -i $(config_get SSH_PRIV_KEY) -o StrictHostKeyChecking=no $(config_get SSH_USER)@$(config_get DB_JIRA_SRC_HOST)"
    local MYSQL_HOST="$(config_get DB_JIRA_SRC_HOST)"
    local MYSQL_USER="$(config_get DB_JIRA_SRC_USERNAME)"
    local MYSQL_PASSWORD="$(config_get DB_JIRA_SRC_PASSWORD)"
    local MYSQL_DB="$(config_get DB_JIRA_SRC_DBNAME)"
    local MYSQLDUMP="$(config_get MYSQL_SRC_MYSQLDUMP)"

    local TIMESTAMP=$(date +"%Y-%m-%d_%H-%M-%S")
    local DUMP="$(config_get MYSQL_LOCAL_BACKUP_DIR)/BKUP_${TIMESTAMP}.sql"

    mkdir -p "$(config_get MYSQL_LOCAL_BACKUP_DIR)"

    local REMOTE_MYSQL_COMMAND="${MYSQLDUMP} --force --opt -h ${MYSQL_HOST} --user=${MYSQL_USER} -p${MYSQL_PASSWORD} --databases ${MYSQL_DB}"
    ${SSH_COMMAND} "${REMOTE_MYSQL_COMMAND}" > ${DUMP}

    echo ${DUMP} > ./lastbackup.tmp

    echo "MySQL Backup File saved as : ${DUMP}"
}

updateDBFileContent() {
    # We first check if the last backup was done and the file name saved in the proper tmp file
    if [ ! -f ./lastbackup.tmp ]; then
        echo "lastbackup.tmp file not found! Aborting..."
        exit 1
    fi

    local DUMP=$(cat ./lastbackup.tmp)

    echo "Backup File Location : ${DUMP}"

    # Now we cleanup the file before creating the second DB
    local JIRA_SRC_BASE_URL="$(config_get JIRA_SRC_BASE_URL)"
    local JIRA_DST_BASE_URL="$(config_get JIRA_DST_BASE_URL)"
    local JIRA_SRC_DBNAME="$(config_get DB_JIRA_SRC_DBNAME)"
    local JIRA_DST_DBNAME="$(config_get DB_JIRA_DST_DBNAME)"


    #Look for the first match and quit
    local ORG_STRING=$(sed -n '/Current/{p;q;}'  ${DUMP})
    local UPT_STRING=${ORG_STRING/${JIRA_SRC_DBNAME}/${JIRA_DST_DBNAME}}

    ORG_STRING="$(escape_var "${ORG_STRING}")"
    UPT_STRING="$(escape_var "${UPT_STRING}")"
    # Replace only the first occurrence for performance reason
    if [[ "${OSTYPE}" == "linux-gnu" ]]; then
        sed -i "0,/${ORG_STRING//\*/\\*}/s/${ORG_STRING//\*/\\*}/${UPT_STRING}/" ${DUMP}
    elif [[ "$OSTYPE" == "darwin"* ]]; then
        LC_CTYPE=C sed -i "" "1,/${ORG_STRING//\*/\\*}/s/${ORG_STRING//\*/\\*}/${UPT_STRING}/" ${DUMP}
    else
        echo "Unsupported OS :${OSTYPE}. Exiting...."
        exit 1
    fi

    echo "'Current Database' information updated : ${ORG_STRING} > ${UPT_STRING}"

    local ORG_STRING=$(sed -n '/CREATE/{p;q;}' ${DUMP})
    local UPT_STRING=${ORG_STRING/${JIRA_SRC_DBNAME}/${JIRA_DST_DBNAME}}

    ORG_STRING="$(escape_var "${ORG_STRING}")"
    UPT_STRING="$(escape_var "${UPT_STRING}")"
    # Replace only the first occurrence for performance reason
    if [[ "${OSTYPE}" == "linux-gnu" ]]; then
        sed -i "0,/${ORG_STRING}/s/${ORG_STRING}/${UPT_STRING}/" ${DUMP}
    elif [[ "$OSTYPE" == "darwin"* ]]; then
        LC_CTYPE=C sed -i "" "1,/${ORG_STRING}/s/${ORG_STRING}/${UPT_STRING}/" ${DUMP}
    else
        echo "Unsupported OS :${OSTYPE}. Exiting...."
        exit 1
    fi
    echo "'CREATE DATABASE' statement updated : ${ORG_STRING} > ${UPT_STRING}"

    #Look for the first match and quit
    local ORG_STRING=$(sed -n '/USE/{p;q;}' ${DUMP})
    local UPT_STRING=${ORG_STRING/${JIRA_SRC_DBNAME}/${JIRA_DST_DBNAME}}

    ORG_STRING="$(escape_var "${ORG_STRING}")"
    UPT_STRING="$(escape_var "${UPT_STRING}")"
    # Replace only the first occurrence for performance reason
    if [[ "${OSTYPE}" == "linux-gnu" ]]; then
        sed -i "0,/${ORG_STRING}/s/${ORG_STRING}/${UPT_STRING}/" ${DUMP}
    elif [[ "$OSTYPE" == "darwin"* ]]; then
        LC_CTYPE=C sed -i "" "1,/${ORG_STRING}/s/${ORG_STRING}/${UPT_STRING}/" ${DUMP}
    else
        echo "Unsupported OS :${OSTYPE}. Exiting...."
        exit 1
    fi
    echo "'USE' statement updated : ${ORG_STRING} > ${UPT_STRING}"

    # Finally, Replace ALL URL references (that takes time...)
    if [[ "${OSTYPE}" == "linux-gnu" ]]; then
        sed -i "s#${JIRA_SRC_BASE_URL//\./\\.}#${JIRA_DST_BASE_URL}#g" ${DUMP}
    elif [[ "$OSTYPE" == "darwin"* ]]; then
        LC_CTYPE=C sed -i "" "s#${JIRA_SRC_BASE_URL//\./\\.}#${JIRA_DST_BASE_URL}#g" ${DUMP}
    else
        echo "Unsupported OS :${OSTYPE}. Exiting...."
        exit 1
    fi
    #Once the update is done we delete the tmp file holding the backup name to avoid double substitution
    rm -f ./lastbackup.tmp

    #And we create a new tmp file for the next step
    echo ${DUMP} > ./lastupdtbackup.tmp

    echo "MySQL Backup File updated with new values"
}
# We trigger a backup of the data on MySQL Server
restoreDatabase() {
    # We first check if the last backup was done and the file name saved in the proper tmp file
    if [ ! -f ./lastupdtbackup.tmp ]; then
        echo "lastupdtbackup.tmp file not found! Aborting..."
        exit 1
    fi

    local DUMP=$(cat ./lastbackup.tmp)

    echo "Backup File Location : ${DUMP}"

    local SSH_COMMAND="ssh -i $(config_get SSH_PRIV_KEY) -o StrictHostKeyChecking=no $(config_get SSH_USER)@$(config_get DB_JIRA_DST_HOST)"
    local MYSQL_HOST="$(config_get DB_JIRA_DST_HOST)"
    local MYSQL_USER="$(config_get DB_JIRA_DST_USERNAME)"
    local MYSQL_PASSWORD="$(config_get DB_JIRA_DST_PASSWORD)"
    local MYSQL_DB="$(config_get DB_JIRA_DST_DBNAME)"
    local MYSQL="$(config_get MYSQL_DST_MYSQL)"

    local REMOTE_MYSQL_COMMAND="${MYSQL} -u ${MYSQL_USER} -p${MYSQL_PASSWORD} -h ${MYSQL_HOST} ${MYSQL_DB}"
    ${SSH_COMMAND} "${REMOTE_MYSQL_COMMAND}" < ${DUMP}

    rm -f ./lastupdtbackup.tmp

    echo "MySQL Backup Restored on : ${MYSQL_HOST}"
}

# Finally we start the services
startJIRA() {
    /etc/init.d/jira start
}

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
    transferDatabase
fi

if [ ${RESUME} -lt 6 ] ; then
    updateDBFileContent
fi

if [ ${RESUME} -lt 7 ] ; then
    restoreDatabase
fi

if [ ${RESUME} -lt 8 ] ; then
    startJIRA
fi

echo "----------------------------------------------"
echo "JIRA Cloning is Done. Have a great day ahead !"
echo "----------------------------------------------"
