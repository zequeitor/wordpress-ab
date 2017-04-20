#!/bin/bash 

# For cygwin, APACHEBENCH could be /usr/sbin/ab2, else ab will suffice on linux/unix systems.
#
# This script is a fork of https://gist.github.com/electrawn/6815208
# 
# Fixed variable names
# Added concurrency and requests parameters
# Added curl and ab detection
# 
# Script source: https://github.com/zequeitor/wordpress-ab

APACHEBENCH=`which ab`||(echo "AB not installed"; kill $$)
CURL=`which curl`||(echo "Curl not installed"; kill $$)
CONCURRENCY=5
REQUESTS=20
COOKIE_JAR="ab-cookie-jar"
USERNAME='foo@bar'
PASSWORD='password'
HOST="127.0.0.1"
BASEURL="http://${HOST}"
LOGINURL="${BASEURL}/wp-login.php"
ADMINURL="${BASEURL}/wp-admin"
POSTDATA="log=${USERNAME}&pwd=${PASSWORD}&rememberme=forever&wp-submit=Log%20In&redirect_to=${ADMINURL}/"


[ -e ${COOKIE_JAR} ] && rm ${COOKIE_JAR}

# this will login to wp and download the session cookie
${CURL} --insecure --connect-timeout 60 --cookie-jar ${COOKIE_JAR} --data ${POSTDATA} ${LOGINURL}

[ -e ${COOKIE_JAR} ] && echo "WP cookie created: ${COOKIE_JAR}"

# now you have a WP session cookie!
# Pipe Audit: print file, ignore first 4 lines of curls cookie jar, 
# only print records tab delimited 6 and 7 from the jar, convert newlines for later header injection.
COOKIES=$(cat ${COOKIE_JAR} | tail -n +5 | awk '{print $6"="$7}' | tr '\n' ';')

echo "Cookies String is:"
echo ${COOKIES}
echo "=================="

echo "Testing Posts:"
${APACHEBENCH} -n ${REQUESTS} -c ${CONCURRENCY} -H "Cookie: ${COOKIES}" ${ADMINURL}/edit.php

echo "Testing Pages:"
${APACHEBENCH} -n ${REQUESTS} -c ${CONCURRENCY} -H "Cookie: ${COOKIES}" ${ADMINURL}/edit.php?post_type=page

echo "Testing Front Page:"
${APACHEBENCH} -n ${REQUESTS} -c ${CONCURRENCY} ${BASEURL}/
