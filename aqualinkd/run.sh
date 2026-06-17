#!/usr/bin/with-contenv bashio

CONFDIR=/data/aqualinkd
AQUA_CONF="${CONFDIR}/aqualinkd.conf"

mkdir -p "${CONFDIR}"

# Read add-on options from /data/options.json (written by HA Supervisor)
SERIAL_PORT=$(bashio::config 'serial_port')
MQTT_ADDRESS=$(bashio::config 'mqtt_address')
MQTT_DISCOVERY=$(bashio::config 'mqtt_discovery_topic')
LOG_LEVEL=$(bashio::config 'log_level')
PANEL_TYPE=$(bashio::config 'panel_type')

bashio::log.info "Writing config: serial=${SERIAL_PORT} mqtt=${MQTT_ADDRESS}"

# Generate aqualinkd.conf (overwrites on every restart so options stay in sync)
cat > "${AQUA_CONF}" << CONF
listen_address=http://0.0.0.0:80
serial_port=${SERIAL_PORT}
log_level=${LOG_LEVEL}
web_directory=/var/www/aqualinkd/
panel_type=${PANEL_TYPE}
device_id=0xFF
enable_scheduler=yes
ftdi_low_latency=YES
sync_panel_time=yes
display_warnings_in_web=yes
report_zero_spa_temp=yes
report_zero_pool_temp=yes
mqtt_address=${MQTT_ADDRESS}
mqtt_discovery_topic=${MQTT_DISCOVERY}
mqtt_timed_update=YES
CONF

# Append credentials only when provided
if bashio::config.has_value 'mqtt_user'; then
    echo "mqtt_user=$(bashio::config 'mqtt_user')" >> "${AQUA_CONF}"
fi
if bashio::config.has_value 'mqtt_passwd'; then
    echo "mqtt_passwd=$(bashio::config 'mqtt_passwd')" >> "${AQUA_CONF}"
fi

# Point aqualinkd at the persistent config
ln -sf "${AQUA_CONF}" /etc/aqualinkd.conf

# Optionally use a custom web UI config stored in /data/aqualinkd/
for f in config.js config.json; do
    [ -f "${CONFDIR}/${f}" ] && ln -sf "${CONFDIR}/${f}" "/var/www/aqualinkd/${f}"
done

# Cron schedule (used for freeze-protection timers, etc.)
if [ ! -f "${CONFDIR}/aqualinkd.schedule" ]; then
    echo "#***** AUTO GENERATED DO NOT EDIT *****" > "${CONFDIR}/aqualinkd.schedule"
fi
ln -sf "${CONFDIR}/aqualinkd.schedule" /etc/cron.d/aqualinkd
chmod 644 "${CONFDIR}/aqualinkd.schedule"

# Optional pre-start hook placed by the user in /data/aqualinkd/aqexec-pre.sh
if [ -x "${CONFDIR}/aqexec-pre.sh" ]; then
    "${CONFDIR}/aqexec-pre.sh"
fi

# Start cron in the background for scheduled pool functions
/usr/sbin/cron || true

bashio::log.info "Starting AqualinkD (serial=${SERIAL_PORT}, mqtt=${MQTT_ADDRESS})"
exec /usr/local/bin/aqualinkd -d -c "${AQUA_CONF}"
