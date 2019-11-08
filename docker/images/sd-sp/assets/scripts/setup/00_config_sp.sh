ENV_PREFIX=SDCONF_
VARFILE=/docker/ansible/extra_vars

echo "Configuring Service Director..."
echo

echo > $VARFILE

while IFS='=' read -r -d '' n v; do
    if [[ $n == ${ENV_PREFIX}* ]]; then
      n=${n#$ENV_PREFIX}
      echo "$n: $v" >> $VARFILE
    fi
done < <(env -0)

# Remove mwfm.xml to force ActivatorConfig re-run
rm -f /etc/opt/OV/ServiceActivator/config/mwfm.xml

echo "Running configuration playbook..."
cd /docker/ansible && ansible-playbook config.yml -c local -i localhost, -e @$VARFILE || {
    echo "Service Director configuration failed. Container will stop now."
    exit 1
}

. /opt/OV/ServiceActivator/bin/setenv

# Install license if present

LICENSEFILE=${LICENSEFILE:-/license}

if [[ -f $LICENSEFILE ]]
then
  echo "Found license file at $LICENSEFILE"
  $ACTIVATOR_OPT/bin/updateLicense -f $LICENSEFILE
fi

# Disable IPv6, otherwise WidlFly does not start

echo JAVA_OPTS='"$JAVA_OPTS -Djava.net.preferIPv4Stack=true"' >> $JBOSS_HOME/bin/standalone.conf
