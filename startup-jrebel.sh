#!/bin/bash

export ORIGINAL_CATALINA_OPTS="${CATALINA_OPTS}"
#export CATALINA_OPTS="-Xms256m -Xmx2000m -javaagent:/usr/local/jrebel-5.1.2/jrebel.jar -Drebel.remoting_plugin=true"
export CATALINA_OPTS="-javaagent:/usr/local/jrebel-5.1.2/jrebel.jar -Drebel.remoting_plugin=true -agentlib:jdwp=transport=dt_socket,address=8000,server=y,suspend=y"
./bin/startup.sh
export CATALINA_OPTS="${ORIGINAL_CATALINA_OPTS}"

