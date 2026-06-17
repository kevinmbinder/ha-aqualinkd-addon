#!/usr/bin/with-contenv bashio

CONFDIR=/data/aqualinkd
AQUA_CONF="${CONFDIR}/aqualinkd.conf"

mkdir -p "${CONFDIR}"

SERIAL_PORT=$(bashio::config 'serial_port')
MQTT_ADDRESS=$(bashio::config 'mqtt_address')
MQTT_DISCOVERY=$(bashio::config 'mqtt_discovery_topic')
LOG_LEVEL=$(bashio::config 'log_level')
PANEL_TYPE=$(bashio::config 'panel_type')
DEVICE_ID=$(bashio::config 'device_id')

bashio::log.info "Writing config: serial=${SERIAL_PORT} mqtt=${MQTT_ADDRESS}"

cat > "${AQUA_CONF}" << CONF
serial_port=${SERIAL_PORT}
log_level=${LOG_LEVEL}
web_directory=/var/www/aqualinkd/
panel_type=${PANEL_TYPE}
device_id=${DEVICE_ID}
enable_scheduler=yes
ftdi_low_latency=YES
display_warnings_in_web=yes
report_zero_spa_temp=yes
report_zero_pool_temp=yes
mqtt_address=${MQTT_ADDRESS}
mqtt_hassio_discover_topic=${MQTT_DISCOVERY}
mqtt_timed_update=YES
CONF

if bashio::config.has_value 'mqtt_user'; then
    echo "mqtt_user=$(bashio::config 'mqtt_user')" >> "${AQUA_CONF}"
fi
if bashio::config.has_value 'mqtt_passwd'; then
    echo "mqtt_passwd=$(bashio::config 'mqtt_passwd')" >> "${AQUA_CONF}"
fi

ln -sf "${AQUA_CONF}" /etc/aqualinkd.conf

for f in config.js config.json; do
    [ -f "${CONFDIR}/${f}" ] && ln -sf "${CONFDIR}/${f}" "/var/www/aqualinkd/${f}"
done

if [ ! -f "${CONFDIR}/aqualinkd.schedule" ]; then
    echo "#***** AUTO GENERATED DO NOT EDIT *****" > "${CONFDIR}/aqualinkd.schedule"
fi
ln -sf "${CONFDIR}/aqualinkd.schedule" /etc/cron.d/aqualinkd
chmod 644 "${CONFDIR}/aqualinkd.schedule"

if [ -x "${CONFDIR}/aqexec-pre.sh" ]; then
    "${CONFDIR}/aqexec-pre.sh"
fi

/usr/sbin/cron || true

bashio::log.info "Starting AqualinkD (serial=${SERIAL_PORT}, mqtt=${MQTT_ADDRESS})"
exec /usr/local/bin/aqualinkd -d -c "${AQUA_CONF}"
