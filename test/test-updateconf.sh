#!/usr/bin/env bash

# We need to use # instead of / in the sed expression to be able to support the / in the path
# https://www.unix.com/shell-programming-and-scripting/148161-expand-environment-variable-sed-when-variable-contains-slash.html

# Database Configuration
DB_NEW_CONNECTION_STRING=jdbc:mysql://1.2.3.4:3306/jira?useUnicode=true\&amp\;characterEncoding=UTF8\&amp\;useSSL=false
DB_NEW_USERNAME=someuser
DB_NEW_PASSWORD=somepassword

cp -f ./dbconfig.xml.sample ./dbconfig.xml.sample.output

if [[ "${OSTYPE}" == "linux-gnu" ]]; then
    # FOR LINUX
    sed -i "s#<url>.*</url>#<url>${DB_NEW_CONNECTION_STRING//&/\\&}</url>#g" dbconfig.xml.sample.output
    sed -i "s#<username>.*</username>#<username>${DB_NEW_USERNAME}</username>#g" dbconfig.xml.sample.output
    sed -i "s#<password>.*</password>#<password>${DB_NEW_PASSWORD}</password>#g" dbconfig.xml.sample.output
elif [[ "$OSTYPE" == "darwin"* ]]; then
    # FOR MAC OSX
    # Need to add the empty string at the beginning for OSX compatibility
    # https://myshittycode.com/2014/07/24/os-x-sed-extra-characters-at-the-end-of-l-command-error/
    sed -i "" "s#<url>.*</url>#<url>${DB_NEW_CONNECTION_STRING//&/\\&}</url>#g" dbconfig.xml.sample.output
    sed -i "" "s#<username>.*</username>#<username>${DB_NEW_USERNAME}</username>#g" dbconfig.xml.sample.output
    sed -i "" "s#<password>.*</password>#<password>${DB_NEW_PASSWORD}</password>#g" dbconfig.xml.sample.output
else
    echo "Unsupported OS :${OSTYPE}. Exiting...."
    exit 1
fi