#!/bin/sh
 
ROOTER=/usr/lib/rooter
ROOTER_LINK="/tmp/links"
 
log() {
	modlog "Create MHI Connection $CURRMODEM" "$@"
}

ifname1="ifname"
if [ -e /etc/newstyle ]; then
	ifname1="device"
fi

check_apn() {
	IPVAR="IP"
	local COMMPORT="/dev/ttyUSB"$CPORT
	if [ -e /etc/nocops ]; then
		echo "0" > /tmp/block
	fi
	ATCMDD="AT+CGDCONT=?"
	OX=$($ROOTER/gcom/gcom-locked "$COMMPORT" "run-at.gcom" "$CURRMODEM" "$ATCMDD")
	[ "$PDPT" = "0" ] && PDPT=""
	for PDP in "$PDPT" IPV4V6; do
		if [[ "$(echo $OX | grep -o "$PDP")" ]]; then
			IPVAR="$PDP"
			break
		fi
	done
	if [ "$idV" = "0e8d" ]; then
		IPVAR="IP"
	fi

	uci set modem.modem$CURRMODEM.pdptype=$IPVAR
	uci commit modem

	log "PDP Type selected in the Connection Profile: \"$PDPT\", active: \"$IPVAR\""

	if [ "$idV" = "12d1" ]; then
		CFUNOFF="0"
	else
		CFUNOFF="4"
	fi

	ATCMDD="AT+CGDCONT?;+CFUN?"
	OX=$($ROOTER/gcom/gcom-locked "$COMMPORT" "run-at.gcom" "$CURRMODEM" "$ATCMDD")
	CGDCONT2=$(echo $OX | grep "+CGDCONT: 2,")
	CGDCONT0=$(echo $OX | grep "+CGDCONT: 0,")
	if [ -z "$CGDCONT2" ]; then
		ATCMDD="AT+CGDCONT=2,\"$IPVAR\",\"ims\""
		OX=$($ROOTER/gcom/gcom-locked "$COMMPORT" "run-at.gcom" "$CURRMODEM" "$ATCMDD")
	fi
	if `echo $OX | grep "+CGDCONT: $CID,\"$IPVAR\",\"$NAPN\"," 1>/dev/null 2>&1`
	then
		if [ -z "$(echo $OX | grep -o "+CFUN: 1")" ]; then
			OX=$($ROOTER/gcom/gcom-locked "$COMMPORT" "run-at.gcom" "$CURRMODEM" "AT+CFUN=1")
		fi
	else
		ATCMDD="AT+CGDCONT=$CID,\"$IPVAR\",\"$NAPN\""
		OX=$($ROOTER/gcom/gcom-locked "$COMMPORT" "run-at.gcom" "$CURRMODEM" "$ATCMDD")
		OX=$($ROOTER/gcom/gcom-locked "$COMMPORT" "run-at.gcom" "$CURRMODEM" "AT+CFUN=$CFUNOFF")
		OX=$($ROOTER/gcom/gcom-locked "$COMMPORT" "run-at.gcom" "$CURRMODEM" "AT+CFUN=1")
		sleep 5
	fi
	if [ -e /etc/nocops ]; then
		rm -f /tmp/block
	fi
}

set_dns() {
	local pDNS1=$(uci -q get modem.modeminfo$CURRMODEM.dns1)
	local pDNS2=$(uci -q get modem.modeminfo$CURRMODEM.dns2)
	local pDNS3=$(uci -q get modem.modeminfo$CURRMODEM.dns3)
	local pDNS4=$(uci -q get modem.modeminfo$CURRMODEM.dns4)

	local aDNS="$pDNS1 $pDNS2 $pDNS3 $pDNS4"
	local bDNS=""

	echo "$aDNS" | grep -o "[[:graph:]]" &>/dev/null
	if [ $? = 0 ]; then
		log "Using DNS settings from the Connection Profile"
		pdns=1
		for DNSV in $(echo "$aDNS"); do
			if [ "$DNSV" != "0.0.0.0" ] && [ -z "$(echo "$bDNS" | grep -o "$DNSV")" ]; then
				[ -n "$(echo "$DNSV" | grep -o ":")" ] && continue
				bDNS="$bDNS $DNSV"
			fi
		done

		bDNS=$(echo $bDNS)
		if [ $DHCP = 1 ]; then
			uci set network.wan$INTER.peerdns=0
			uci set network.wan$INTER.dns="$bDNS"
		fi
		echo "$bDNS" > /tmp/v4dns$INTER

		bDNS=""
		for DNSV in $(echo "$aDNS"); do
			if [ "$DNSV" != "0:0:0:0:0:0:0:0" ] && [ -z "$(echo "$bDNS" | grep -o "$DNSV")" ]; then
				[ -z "$(echo "$DNSV" | grep -o ":")" ] && continue
				bDNS="$bDNS $DNSV"
			fi
		done
		echo "$bDNS" > /tmp/v6dns$INTER
	else
		log "Using Provider assigned DNS"
		pdns=0
		rm -f /tmp/v[46]dns$INTER
	fi
}

save_variables() {
	echo 'MODSTART="'"$MODSTART"'"' > /tmp/variable.file
	echo 'WWAN="'"$WWAN"'"' >> /tmp/variable.file
	echo 'USBN="'"$USBN"'"' >> /tmp/variable.file
	echo 'ETHN="'"$ETHN"'"' >> /tmp/variable.file
	echo 'WDMN="'"$WDMN"'"' >> /tmp/variable.file
	echo 'BASEPORT="'"$BASEPORT"'"' >> /tmp/variable.file
}

foxunlock() {
	FIRMWARE_VERSION=$(qmicli --device-open-proxy --device="$DEVICE" \
	  --dms-foxconn-get-firmware-version=firmware-mcfg \
	  | grep "Version:" \
	  | grep -o "'.*'" \
	  | sed "s/'//g" \
	  | sed -e 's/\.[^.]*\.[^.]*$//')
	if [ -n "${FIRMWARE_VERSION}" ]; then
		log "${FIRMWARE_VERSION}"
		FIRMWARE_APPS_VERSION=$(qmicli --device-open-proxy --device="$DEVICE" \
		--dms-foxconn-get-firmware-version=apps \
		| grep "Version:" \
		| grep -o "'.*'" \
		| sed "s/'//g")

		if [ -n "${FIRMWARE_APPS_VERSION}" ]; then
			log "${FIRMWARE_APPS_VERSION}"
			IMEI=$(qmicli --device-open-proxy --device="$DEVICE" --dms-get-ids \
			| grep "IMEI:" \
			| grep -o "'.*'" \
			| sed "s/'//g")

			if [ -n "${IMEI}" ]; then
				log "${IMEI}"
			  SALT="salt" # use a static salt for now
			  MAGIC="foxc"
			  HASH="${SALT}$(printf "%s%s%s%s%s" "${FIRMWARE_VERSION}" \
				"${FIRMWARE_APPS_VERSION}" "${IMEI}" "${SALT}" "${MAGIC}" \
				| md5sum \
				| head -c 32)"
			else
			  log "Could not determine SDX55 IMEI"
			fi
		else
			log "Could not determine SDX55 firmware apps version"
		fi
	else
		log "Could not determine SDX55 firmware version"
	fi
	UNLOCK_RESULT=1
	if [ -n "${HASH}" ]; then
	  qmicli --device-open-proxy --device="$DEVICE" \
		--dms-foxconn-set-fcc-authentication-v2="${HASH},48"
	  UNLOCK_RESULT=$?

	  if [ $UNLOCK_RESULT -ne 0 ]; then
		log "SDX55 FCC unlock v2 failed"
	  else
	    log "SDX55 FCC unlock v2 succeded"
		return
	  fi
	fi

	if [ $UNLOCK_RESULT -ne 0 ]; then
	  qmicli --device-open-proxy --device="$DEVICE" \
		--dms-foxconn-set-fcc-authentication=0
	  UNLOCK_RESULT=$?

	  if [ $UNLOCK_RESULT -ne 0 ]; then
		log "SDX55 FCC unlock v1 failed"
	  else
	    log "SDX55 FCC unlock v1 succeded"
	  fi
	fi
}

fcc_unlock() {
	VENDOR_ID_HASH="3df8c719"
	ATCMDD="at+gtfcclockgen"
	OX=$($ROOTER/gcom/gcom-locked "/dev/ttyUSB$CPORT" "run-at.gcom" "$CURRMODEM" "$ATCMDD")
	CHALLENGE=$(echo "$OX" | grep -o '0x[0-9a-fA-F]\+' | awk '{print $1}')
	 if [ -n "$CHALLENGE" ]; then
        log "Got challenge from modem: $CHALLENGE"
        HEX_CHALLENGE=$(printf "%08x" "$CHALLENGE")
        COMBINED_CHALLENGE="${HEX_CHALLENGE}$(printf "%.8s" "${VENDOR_ID_HASH}")"
        RESPONSE_HASH=$(echo "$COMBINED_CHALLENGE" | xxd -r -p | sha256sum | cut -d ' ' -f 1)
        TRUNCATED_RESPONSE=$(printf "%.8s" "$RESPONSE_HASH")
        RESPONSE=$(printf "%d" "0x$TRUNCATED_RESPONSE")

        log "Sending response to modem: $RESPONSE"
        #UNLOCK_RESPONSE=$(at_command "at+gtfcclockver=$RESPONSE")
		ATCMDD="at+gtfcclockver=$RESPONSE"
		UNLOCK_RESPONSE=$($ROOTER/gcom/gcom-locked "/dev/ttyUSB$CPORT" "run-at.gcom" "$CURRMODEM" "$ATCMDD")
		succ=$(echo "$UNLOCK_RESPONSE" | grep "+GTFCCLOCKVER: 1")
        if [ ! -z "$succ" ]; then
			log "FCC unlock succeeded"
            return
         else
            log "Unlock failed. Got response: $UNLOCK_RESPONSE"
        fi
    else
        log "Failed to obtain FCC challenge. Got: ${RAW_CHALLENGE}"
    fi

}

get_connect() {
	NAPN=$(uci -q get modem.modeminfo$CURRMODEM.apn)
	NAPN2=$(uci -q get modem.modeminfo$CURRMODEM.apn2)
	NAPN3=$(uci -q get modem.modeminfo$CURRMODEM.apn3)
	NUSER=$(uci -q get modem.modeminfo$CURRMODEM.user)
	NPASS=$(uci -q get modem.modeminfo$CURRMODEM.passw)
	NAUTH=$(uci -q get modem.modeminfo$CURRMODEM.auth)
	PDPT=$(uci -q get modem.modeminfo$CURRMODEM.pdptype)
	uci set modem.modem$CURRMODEM.apn="$NAPN"
	uci set modem.modem$CURRMODEM.apn2=$NAPN2
	uci set modem.modem$CURRMODEM.apn3=$NAPN3
	uci set modem.modem$CURRMODEM.user=$NUSER
	uci set modem.modem$CURRMODEM.passw=$NPASS
	uci set modem.modem$CURRMODEM.auth=$NAUTH
	uci set modem.modem$CURRMODEM.pin=$PINC
	uci commit modem
}

CURRMODEM=$1
source /tmp/variable.file
log "Start MHI"
MAN=$(uci get modem.modem$CURRMODEM.manuf)
MOD=$(uci get modem.modem$CURRMODEM.model)
BASEP=$(uci get modem.modem$CURRMODEM.baseport)
$ROOTER/signal/status.sh $CURRMODEM "$MAN $MOD" "Connecting"
PROT=$(uci get modem.modem$CURRMODEM.proto)

DELAY=$(uci get modem.modem$CURRMODEM.delay)
if [ -z $DELAY ]; then
	DELAY=5
fi

idV=$(uci get modem.modem$CURRMODEM.idV)
idP=$(uci get modem.modem$CURRMODEM.idP)

DP=3
CP=2

$ROOTER/common/modemchk.lua "$idV" "$idP" "$DP" "$CP"
source /tmp/parmpass

CPORT=`expr $CPORT + $BASEP`
DPORT=`expr $DPORT + $BASEP`

CPORT="92"
DPORT="92"

ln -fs /dev/wwan0at0 /dev/ttyUSB$CPORT
if [ "$idV" = "413c" ]; then
	NMEA="94"
	ln -fs /dev/wwan0nmea0 /dev/ttyUSB$NMEA
fi

uci set modem.modem$CURRMODEM.commport=$CPORT
uci set modem.modem$CURRMODEM.nmeaport=$NMEA
uci set modem.modem$CURRMODEM.dataport=$DPORT
uci set modem.modem$CURRMODEM.service=$retval
uci commit modem

if [ -e $ROOTER/modem-led.sh ]; then
	$ROOTER/modem-led.sh $CURRMODEM 2
fi

log "MHI Comm Port : /dev/ttyUSB$CPORT"

if [ -z "$idV" ]; then
	idV=$(uci -q get modem.modem$CURRMODEM.idV)
fi
QUECTEL=false
if [ "$idV" = "2c7c" ]; then
	QUECTEL=true
elif [ "$idV" = "05c6" ]; then
	QUELST="9090,9003,9215"
	if [[ $(echo "$QUELST" | grep -o "$idP") ]]; then
		QUECTEL=true
	fi
fi

if [ -e $ROOTER/connect/preconnect.sh ]; then
	if [ "$RECON" != "2" ]; then
		$ROOTER/connect/preconnect.sh $CURRMODEM
	fi
fi

if $QUECTEL; then
	if [ "$RECON" != "2" ]; then
		ATCMDD="AT+CNMI?"
		OX=$($ROOTER/gcom/gcom-locked "/dev/ttyUSB$CPORT" "run-at.gcom" "$CURRMODEM" "$ATCMDD")
		if `echo $OX | grep -o "+CNMI: [0-3],2," >/dev/null 2>&1`; then
			ATCMDD="AT+CNMI=0,0,0,0,0"
			OX=$($ROOTER/gcom/gcom-locked "/dev/ttyUSB$CPORT" "run-at.gcom" "$CURRMODEM" "$ATCMDD")
		fi
		ATCMDD="AT+QINDCFG=\"smsincoming\""
		OX=$($ROOTER/gcom/gcom-locked "/dev/ttyUSB$CPORT" "run-at.gcom" "$CURRMODEM" "$ATCMDD")
		if `echo $OX | grep -o ",1" >/dev/null 2>&1`; then
			ATCMDD="AT+QINDCFG=\"smsincoming\",0,1"
			OX=$($ROOTER/gcom/gcom-locked "/dev/ttyUSB$CPORT" "run-at.gcom" "$CURRMODEM" "$ATCMDD")
		fi
		ATCMDD="AT+QINDCFG=\"all\""
		OX=$($ROOTER/gcom/gcom-locked "/dev/ttyUSB$CPORT" "run-at.gcom" "$CURRMODEM" "$ATCMDD")
		if `echo $OX | grep -o ",1" >/dev/null 2>&1`; then
			ATCMDD="AT+QINDCFG=\"all\",0,1"
			OX=$($ROOTER/gcom/gcom-locked "/dev/ttyUSB$CPORT" "run-at.gcom" "$CURRMODEM" "$ATCMDD")
		fi
		log "Quectel Unsolicited Responses Disabled"
	fi
	$ROOTER/connect/bandmask $CURRMODEM 1
	clck=$(uci -q get custom.bandlock.cenable$CURRMODEM)
	if [ $clck = "1" ]; then
		ear=$(uci -q get custom.bandlock.earfcn$CURRMODEM)
		pc=$(uci -q get custom.bandlock.pci$CURRMODEM)
		ear1=$(uci -q get custom.bandlock.earfcn1$CURRMODEM)
		pc1=$(uci -q get custom.bandlock.pci1$CURRMODEM)
		ear2=$(uci -q get custom.bandlock.earfcn2$CURRMODEM)
		pc2=$(uci -q get custom.bandlock.pci2$CURRMODEM)
		ear3=$(uci -q get custom.bandlock.earfcn3$CURRMODEM)
		pc3=$(uci -q get custom.bandlock.pci3$CURRMODEM)
		cnt=1
		earcnt=$ear","$pc
		if [ $ear1 != "0" -a $pc1 != "0" ]; then
			earcnt=$earcnt","$ear1","$pc1
			let cnt=cnt+1
		fi
		if [ $ear2 != "0" -a $pc2 != "0" ]; then
			earcnt=$earcnt","$ear2","$pc2
			let cnt=cnt+1
		fi
		if [ $ear3 != "0" -a $pc3 != "0" ]; then
			earcnt=$earcnt","$ear3","$pc3
			let cnt=cnt+1
		fi
		earcnt=$cnt","$earcnt
		ATCMDD="at+qnwlock=\"common/4g\""
		OX=$($ROOTER/gcom/gcom-locked "/dev/ttyUSB$CPORT" "run-at.gcom" "$CURRMODEM" "$ATCMDD")
		log "$OX"
		if `echo $OX | grep "ERROR" 1>/dev/null 2>&1`
		then
			ATCMDD="at+qnwlock=\"common/lte\",2,$ear,$pc"
		else
			ATCMDD=$ATCMDD","$earcnt
		fi
		OX=$($ROOTER/gcom/gcom-locked "/dev/ttyUSB$CPORT" "run-at.gcom" "$CURRMODEM" "$ATCMDD")
		log "Cell Lock $OX"
		sleep 10
	fi
fi

DEVICE="/dev/wwan0mbim0"

if [ "$idV" = "1199" ]; then
	$ROOTER/connect/bandmask $CURRMODEM 0
fi
if [ "$idV" = "413c" ]; then
	foxunlock
	$ROOTER/connect/bandmask $CURRMODEM 3
fi
if [ "$idV" = "0e8d" ]; then
	fcc_unlock
	$ROOTER/connect/bandmask $CURRMODEM 2
fi
if [ "$idV" = "2cb7" ]; then
	$ROOTER/connect/bandmask $CURRMODEM 2
fi

$ROOTER/common/gettype.sh $CURRMODEM
$ROOTER/connect/get_profile.sh $CURRMODEM
get_connect
if [ -e $ROOTER/simlock.sh ]; then
	$ROOTER/simlock.sh $CURRMODEM
fi

if [ -e /usr/lib/gps/gps.sh ]; then
	/usr/lib/gps/gps.sh $CURRMODEM &
fi

if [ -e /tmp/simpin$CURRMODEM ]; then
	log " SIM Error"
	if [ -e $ROOTER/simerr.sh ]; then
		$ROOTER/simerr.sh $CURRMODEM
	fi
	exit 0
fi

$ROOTER/sms/check_sms.sh $CURRMODEM &

INTER=$(uci get modem.modeminfo$CURRMODEM.inter)
if [ -z $INTER ]; then
	INTER=$CURRMODEM
else
	if [ $INTER = 0 ]; then
		INTER=$CURRMODEM
	fi
fi
log "Profile for Modem $CURRMODEM sets interface to WAN$INTER"
OTHER=1
if [ $CURRMODEM = 1 ]; then
	OTHER=2
fi
EMPTY=$(uci get modem.modem$OTHER.empty)
if [ $EMPTY = 0 ]; then
	OINTER=$(uci get modem.modem$OTHER.inter)
	if [ ! -z $OINTER ]; then
		if [ $INTER = $OINTER ]; then
			INTER=1
			if [ $OINTER = 1 ]; then
				INTER=2
			fi
			log "Switched Modem $CURRMODEM to WAN$INTER as Modem $OTHER is using WAN$OINTER"
		fi
	fi
fi


uci set modem.modem$CURRMODEM.inter=$INTER
uci commit modem
log "Modem $CURRMODEM is using WAN$INTER"

$ROOTER/connect/handlettl.sh $CURRMODEM 0 &

log "Connect via MHI"
if [ -e $ROOTER/modem-led.sh ]; then
	$ROOTER/modem-led.sh $CURRMODEM 2
fi

if [ "$idV" = "0e8d" ]; then
	IFNAME="wwan0"
else
	IFNAME="mhi_hwip0"
	uMa=$(uci -q get modem.modem$CURRMODEM.manuf)
	if "$uMa" = "Thales" ]; then
		IFNAME="mhi_hwip0_mbim"
	fi
	if [ "$idV" = "413c" ]; then
		ATCMDD="at^qtuner_enable?"
		OX=$($ROOTER/gcom/gcom-locked "/dev/ttyUSB$CPORT" "run-at.gcom" "$CURRMODEM" "$ATCMDD")
		log "$OX"
		tr=$(echo "$OX" | grep "TRUE")
		if [ ! -z "$tr" ]; then
			ATCMDD="at^qtuner_enable=0"
			OX=$($ROOTER/gcom/gcom-locked "/dev/ttyUSB$CPORT" "run-at.gcom" "$CURRMODEM" "$ATCMDD")
			$ROOTER/luci/restartrun.sh $CURRMODEM
			exit 0
		fi
	fi
fi
uci set modem.modem$CURRMODEM.netinterface=$IFNAME
uci commit modem

CID=$(uci -q get modem.modeminfo$CURRMODEM.context)
if [ -z "$CID" ]; then
	CID="1"
fi
pdptype="IPV4V6"
IPVAR=$(uci -q get modem.modeminfo$CURRMODEM.pdptype)
if [ -z "$IPVAR" ]; then
	IPVAR="IPV4V6"
fi
if [ "$idV" = "0e8d" ]; then
	IPVAR="IP"
fi
log "PDP Context : $CID  PDP Type : $IPVAR"
ATCMDD="AT+CGDCONT=$CID,\"$IPVAR\",\"$NAPN\""
OX=$($ROOTER/gcom/gcom-locked "/dev/ttyUSB$CPORT" "run-at.gcom" "$CURRMODEM" "$ATCMDD")
if [ "$idV" != "1199" ]; then
	OX=$($ROOTER/gcom/gcom-locked "/dev/ttyUSB$CPORT" "run-at.gcom" "$CURRMODEM" "AT+CFUN=1")
	sleep 5
fi
check_apn
	
APN=$NAPN
log "Using APN : $APN  on $IFNAME"
if [ 1 = 0 ]; then
	echo "APN=$APN" > /etc/mbim-network.conf
	echo "APN_USER=" >> /etc/mbim-network.conf
	echo "APN_PASS=" >> /etc/mbim-network.conf
	echo "APN_AUTH=" >> /etc/mbim-network.conf
	echo "PROXY=yes" >> /etc/mbim-network.conf

	/usr/lib/rooter/mhi/createnetwork $DEVICE start

	exit 0
fi	
if [ "$idV" = "0e8d" -o "$idV" = "2cb7" -o "$idV" = "1199" ]; then
	pdptype="ipv4v6"
	IPVAR=$(uci -q get modem.modeminfo$CURRMODEM.pdptype)
	case "$IPVAR" in
		"IP" )
			pdptype="ipv4"
		;;
		"IPV6" )
			pdptype="ipv6"
		;;
		"IPV4V6" )
			pdptype="ipv4v6"
		;;
	esac
	if [ "$idV" != "1199" ]; then
		pdptype="ipv4"
	fi
	isplist=$apndata"000000,$NAPN,Default,$NPASS,$CID,$NUSER,$NAUTH,$pdptype"
	if [ ! -z "$NAPN2" ]; then
		isplist=$isplist" 000000,$NAPN2,Default,$NPASS,$CID,$NUSER,$NAUTH,$pdptype"
	fi
	if [ ! -z "$NAPN3" ]; then
		isplist=$isplist" 000000,$NAPN3,Default,$NPASS,$CID,$NUSER,$NAUTH,$pdptype"
	fi
	log "$isplist"
	uci set modem.modeminfo$CURRMODEM.isplist="$isplist"
	uci commit modem		

	log "Using Netifd Method"
	uci delete network.wan$INTER
	uci set network.wan$INTER=interface
	uci set network.wan$INTER.proto=mbim
	uci set network.wan$INTER.device=$DEVICE
	uci set network.wan$INTER.metric=$INTER"0"
	uci set network.wan$INTER.currmodem=$CURRMODEM
	uci -q commit network
	rm -f /tmp/usbwait
	ifup wan$INTER
	MIFACE=$(uci -q get modem.modem$CURRMODEM.interface)
	if [ -e /sys/class/net/$MIFACE/cdc_ncm/tx_timer_usecs ]; then
		echo "0" > /sys/class/net/$MIFACE/cdc_ncm/tx_timer_usecs
	fi
	exit 0
fi


#
# stop network
# setup data format
# set IP family
#
STOPNET=`qmicli -p -d $DEVICE --wds-stop-network=disable-autoconnect 2>/dev/null`
AUTODIS=`qmicli -p -d $DEVICE --wds-set-autoconnect-settings=disabled 2>/dev/null`
DEVICE_DATA_FORMAT_CMD="qmicli -p -d $DEVICE --wda-get-data-format"
DEVICE_DATA_FORMAT_OUT=`$DEVICE_DATA_FORMAT_CMD`
log "$DEVICE_DATA_FORMAT_OUT"
DEVICE_LLP=`echo "$DEVICE_DATA_FORMAT_OUT" | sed -n "s/.*Link layer protocol:.*'\(.*\)'.*/\1/p"`
SETFORM=`qmicli -p -d $DEVICE --wda-set-data-format="raw-ip" 2>/dev/null`

#if [ "$idV" = "413c" ]; then
#	foxunlock
#fi

#
# start network
# check for failure
#
START_NETWORK_ARGS="apn='$APN'"
START_NETWORK_OUT=`qmicli -p -d $DEVICE --wds-start-network=$START_NETWORK_ARGS --client-no-release-cid 2>/dev/null`
log "$START_NETWORK_OUT"
CID=`echo "$START_NETWORK_OUT" | sed -n "s/.*CID.*'\(.*\)'.*/\1/p"`
if [ -z "$CID" ]; then
	log "error: network start failed, client not allocated"
	exit 0
fi
PDH=`echo "$START_NETWORK_OUT" | sed -n "s/.*handle.*'\(.*\)'.*/\1/p"`
if [ -z "$PDH" ]; then
    log "error: network start failed, no packet data handle"
	exit 0
fi

SIGNAL=`qmicli -p -d $DEVICE --nas-get-signal-info 2>/dev/null`
if [ -z "$SIGNAL" ]; then
    log "error: no cell connection"
	exit 0
fi
sstat=`qmicli -p -d $DEVICE --wds-get-packet-service-status`
log "$sstat"
ssc=$(echo "$sstat" | grep "connected")
if [ -z "$ssc" ]; then
    log "error: network not connected"
	exit 0
fi
log "Network Connected"
qmicli -p -d $DEVICE --wds-get-current-settings > /tmp/mhisettings
while IFS= read -r line; do
	read -r line
	ipf=$(echo "$line" | grep "IP Family:")
	if [ ! -z "$ipf" ]; then
		ipfam=$(echo "$ipf" | xargs | tr " " "," | cut -d, -f3)
		vs=$(echo "$ipfam" | grep "6")
		if [ ! -z "$vs" ]; then
			vs=6
			res=$(cat /tmp/mhisettings)
			log "$res"
			read -r line
			ipaddr6=$(echo "$line" | grep "$ipfam address:")
			if [ ! -z "$ipaddr6" ]; then
				ipaddrf6=$(echo "$ipaddr6" | xargs | tr " " "," | cut -d, -f3)
			fi
			read -r line
			gateway6=$(echo "$line" | grep "gateway address:")
			if [ ! -z "$gateway6" ]; then
				gatewayf6=$(echo "$gateway6" | xargs | tr " " "," | cut -d, -f4 | tr "/" "," | cut -d, -f1)
			fi
			read -r line
			dns16=$(echo "$line" | grep "primary DNS:")
			if [ ! -z "$dns16" ]; then
				dns1f6=$(echo "$dns16" | xargs | tr " " "," | cut -d, -f4)
			fi
			read -r line
			dns26=$(echo "$line" | grep "secondary DNS:")
			if [ ! -z "$dns26" ]; then
				dns2f6=$(echo "$dns26" | xargs | tr " " "," | cut -d, -f4)
			fi
			read -r line
			read -r line
			log "IP Addr6 : $ipaddrf6"
			log "Gateway6 : $gatewayf6"
			log "DNS6 : $dns1f6 $dns2f6"
		else
			vs=$(echo "$ipfam" | grep "4")
			if [ ! -z "$vs" ]; then
				res=$(cat /tmp/mhisettings)
				log "$res"
				vs=4
				read -r line
				ipaddr4=$(echo "$line" | grep "$ipfam address:")
				if [ ! -z "$ipaddr4" ]; then
					ipaddrf4=$(echo "$ipaddr4" | xargs | tr " " "," | cut -d, -f3)
				fi
				read -r line
				subnet4=$(echo "$line" | grep "subnet mask:")
				if [ ! -z "$subnet4" ]; then
					subnetf4=$(echo "$subnet4" | xargs | tr " " "," | cut -d, -f4 | tr "/" "," | cut -d, -f1)
				fi
				read -r line
				gateway4=$(echo "$line" | grep "gateway address:")
				if [ ! -z "$gateway4" ]; then
					gatewayf4=$(echo "$gateway4" | xargs | tr " " "," | cut -d, -f4 | tr "/" "," | cut -d, -f1)
				fi
				read -r line
				dns14=$(echo "$line" | grep "primary DNS:")
				if [ ! -z "$dns14" ]; then
					dns1f4=$(echo "$dns14" | xargs | tr " " "," | cut -d, -f4)
				fi
				read -r line
				dns24=$(echo "$line" | grep "secondary DNS:")
				if [ ! -z "$dns24" ]; then
					dns2f4=$(echo "$dns24" | xargs | tr " " "," | cut -d, -f4)
				fi
				read -r line
				read -r line
				log "IP Addr4 : $ipaddrf4"
				log "Subnet4 : $subnetf4"
				log "Gateway4 : $gatewayf4"
				log "DNS4 : $dns1f4 $dns2f4"
			fi
		fi
	fi
done < /tmp/mhisettings


INTER=1
log "Applying IP settings to wan$INTER"

if [ -z "$ipaddrf4" ]; then
	log "Add 464xlat interface"
	uci delete network.xlatd$INTER
	uci set network.xlatd$INTER=interface
	uci set network.xlatd$INTER.proto='464xlat'
	uci set network.xlatd$INTER.tunlink='wan'$INTER
	uci set network.xlatd$INTER.ip6prefix='64:ff9b::/96'
	uci set network.xlatd$INTER.dns='1.1.1.1'
	uci set network.xlatd$INTER.metric=$INTER"0"
	uci set network.xlatd$INTER.ip4table='default'
	uci set network.xlatd$INTER.ip6table='default'
	ifup xlatd$INTER
fi
 
uci delete network.wan$INTER
uci set network.wan$INTER=interface
uci set network.wan$INTER.proto=static
uci set network.wan$INTER.device="$IFNAME"
uci set network.wan$INTER.metric=$INTER"0"
if [ ! -z "$ipaddrf4" ]; then
	uci set network.wan$INTER.ipaddr="$ipaddrf4"
	uci set network.wan$INTER.gateway="$gatewayf4"
	uci add_list network.wan$INTER.dns="$dns1f4"
	if [ ! -z "$dns2f4" ]; then
		uci add_list network.wan$INTER.dns="$dns2f4"
	fi
	uci set network.wan$INTER.netmask="$subnetf4"
fi
if [ ! -z "$ipaddrf6" ]; then
	uci set network.wan$INTER.ip6addr="$ipaddrf6"
	uci set network.wan$INTER.ip6gw="$gatewayf6"
	uci add_list network.wan$INTER.dns="$dns1f6"
	if [ ! -z "$dns2f6" ]; then
		uci add_list network.wan$INTER.dns="$dns2f6"
	fi
fi
uci commit network
ip link set dev $IFNAME arp off
ifup wan$INTER


ln -fs $ROOTER/signal/modemsignal.sh $ROOTER_LINK/getsignal$CURRMODEM
$ROOTER_LINK/getsignal$CURRMODEM $CURRMODEM $PROT &
rm -f /tmp/usbwait
log "Modem Connected"
if [ -e $ROOTER/modem-led.sh ]; then
	$ROOTER/modem-led.sh $CURRMODEM 3
fi

ln -fs $ROOTER/connect/conmon.sh $ROOTER_LINK/con_monitor$CURRMODEM
$ROOTER_LINK/con_monitor$CURRMODEM $CURRMODEM &
uci set modem.modem$CURRMODEM.connected=1
uci commit modem

if [ -e $ROOTER/connect/postconnect.sh ]; then
	$ROOTER/connect/postconnect.sh $CURRMODEM
fi
