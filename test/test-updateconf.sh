#!/usr/bin/env bash

#RSYNC_DST_JIRA_DATA_FOLDER=/path/to/new/home
#JIRA_NEW_HOME="jira\.home = ${RSYNC_DST_JIRA_DATA_FOLDER}"
#echo "Escaped Path : ${JIRA_NEW_HOME}"

# We need to use # instead of / in the sed expression to be able to support the / in the path
# https://www.unix.com/shell-programming-and-scripting/148161-expand-environment-variable-sed-when-variable-contains-slash.html

#sed "s#^[^#]*jira\.home.*#${JIRA_NEW_HOME}#g" < ./jira-application.properties.sample > ./jira-application.properties.output

# Database Configuration
DB_NEW_CONNECTION_STRING=jdbc:mysql://1.2.3.4:3306/jira?useUnicode=true\&amp\;characterEncoding=UTF8\&amp\;useSSL=false
DB_NEW_USERNAME=someuser
DB_NEW_PASSWORD=somepassword

cp -f ./dbconfig.xml.sample ./dbconfig.xml.sample.output

# FOR MAC OSX
# Need to add the empty string at the beginning for OSX compatibility
# https://myshittycode.com/2014/07/24/os-x-sed-extra-characters-at-the-end-of-l-command-error/
#sed -i "" "s#<url>.*</url>#<url>${DB_NEW_CONNECTION_STRING//&/\\&}</url>#g" dbconfig.xml.sample.output
#sed -i "" "s#<username>.*</username>#<username>${DB_NEW_USERNAME}</username>#g" dbconfig.xml.sample.output
#sed -i "" "s#<password>.*</password>#<password>${DB_NEW_PASSWORD}</password>#g" dbconfig.xml.sample.output

# FOR CENTOS
sed -i "s#<url>.*</url>#<url>${DB_NEW_CONNECTION_STRING//&/\\&}</url>#g" dbconfig.xml.sample.output
sed -i "s#<username>.*</username>#<username>${DB_NEW_USERNAME}</username>#g" dbconfig.xml.sample.output
sed -i "s#<password>.*</password>#<password>${DB_NEW_PASSWORD}</password>#g" dbconfig.xml.sample.output