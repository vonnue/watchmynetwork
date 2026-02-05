#!/bin/bash

INTERFACE="wlan0"
PING_HOST="8.8.8.8"
INTERVAL=10
HOSTNAME=$(cat /etc/hostname)
LOG_DIR=/var/logs/vonnue/network-monitor
LOCAL_LOG="$LOG_DIR/wifi_${HOSTNAME}.log"

if ! ip link show $INTERFACE &>/dev/null; then
    INTERFACE=$(iw dev | grep Interface | awk '{print $2}' | head -1)
fi

mkdir -p $LOG_DIR

MACHINE_INFO="Host:$HOSTNAME | User:$USER | $(uname -r)"

log_entry() {

    TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S')
    
    if ! iw dev $INTERFACE link | grep -q "Connected"; then
        echo "$TIMESTAMP | $MACHINE_INFO | STATUS:DISCONNECTED" | tee -a $LOCAL_LOG
        return
    fi
    
    WIFI_INFO=$(iw dev $INTERFACE link 2>/dev/null)
    SSID=$(echo "$WIFI_INFO" | grep "SSID" | awk '{print $2}')
    BSSID=$(echo "$WIFI_INFO" | grep "Connected to" | awk '{print $3}')
    FREQ=$(echo "$WIFI_INFO" | grep "freq" | awk '{print $2}')
    SIGNAL=$(echo "$WIFI_INFO" | grep "signal" | awk '{print $2}')
    TX_BITRATE=$(echo "$WIFI_INFO" | grep "tx bitrate" | sed 's/.*tx bitrate: //' | awk '{print $1}')
    RX_BITRATE=$(echo "$WIFI_INFO" | grep "rx bitrate" | sed 's/.*rx bitrate: //' | awk '{print $1}')
    CHANNEL=$(iwlist $INTERFACE channel 2>/dev/null | grep Current | awk '{print $5}' | tr -d ')')
    GATEWAY=$(ip route | grep default | head -1 | awk '{print $3}')
    
    GATEWAY_RESULT=$(ping -c 3 -W 2 $GATEWAY 2>/dev/null)
    if [ $? -eq 0 ]; then
        GATEWAY_PING=$(echo "$GATEWAY_RESULT" | tail -1 | awk -F'/' '{print $5}')
        GATEWAY_LOSS=$(echo "$GATEWAY_RESULT" | grep "packet loss" | awk '{print $6}')
    else
        GATEWAY_PING="FAIL"
        GATEWAY_LOSS="100%"
    fi
    
    INTERNET_RESULT=$(ping -c 3 -W 2 $PING_HOST 2>/dev/null)
    if [ $? -eq 0 ]; then
        INTERNET_PING=$(echo "$INTERNET_RESULT" | tail -1 | awk -F'/' '{print $5}')
        INTERNET_LOSS=$(echo "$INTERNET_RESULT" | grep "packet loss" | awk '{print $6}')
    else
        INTERNET_PING="FAIL"
        INTERNET_LOSS="100%"
    fi
    
    QUALITY="GOOD"

    if [ "$INTERNET_LOSS" != "0%" ] || [ "$GATEWAY_LOSS" != "0%" ]; then
        QUALITY="DEGRADED"
    fi
    if [ "$INTERNET_PING" = "FAIL" ] || [ "$GATEWAY_PING" = "FAIL" ]; then
        QUALITY="POOR"
    fi
    
    LOG_LINE="$TIMESTAMP,$HOSTNAME,$SSID,$BSSID,$FREQ,$CHANNEL,$SIGNAL,$TX_BITRATE,$RX_BITRATE,$GATEWAY_PING,$GATEWAY_LOSS,$INTERNET_PING,$INTERNET_LOSS,$QUALITY"
    
    echo "$LOG_LINE" | tee -a $LOCAL_LOG
    
}

if [ ! -f $LOCAL_LOG ]; then
    echo "timestamp,hostname,ssid,bssid,freq,channel,signal_dbm,tx_mbps,rx_mbps,gateway_ping_ms,gateway_loss,internet_ping_ms,internet_loss,quality" > $LOCAL_LOG
fi

while true; do
    log_entry
    sleep $INTERVAL
done
