#!/bin/bash -e

echo "Configuring Service Director..."
echo

/docker/start_edb.sh

echo "Starting CouchDB..."
echo admin = admin >> /opt/couchdb/etc/local.ini
/etc/init.d/couchdb start

# Remove mwfm.xml to force ActivatorConfig re-run
rm -f /etc/opt/OV/ServiceActivator/config/mwfm.xml

echo "Running Service Director configuration playbooks..."
cd /docker/ansible && ansible-playbook config.yml -c local -i localhost,

. /opt/OV/ServiceActivator/bin/setenv

if [[ $(sysctl -n net.ipv6.conf.lo.disable_ipv6) == 1 ]]
then
    echo JAVA_OPTS='"$JAVA_OPTS -Djava.net.preferIPv4Stack=true"' >> "$JBOSS_HOME/bin/standalone.conf"
fi
