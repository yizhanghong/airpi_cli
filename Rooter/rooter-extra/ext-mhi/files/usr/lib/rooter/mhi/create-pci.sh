#!/bin/sh
 
ROOTER=/usr/lib/rooter
ROOTER_LINK="/tmp/links"

log() {
	modlog "Create PCie $CURRMODEM" "$@"
}


display_top() {
	log "*****************************************************************"
	log "*"
}

display_bottom() {
	log "*****************************************************************"
}


display() {
	local line1=$1
	log "* $line1"
	log "*"
}

save_variables() {
	echo 'MODSTART="'"$MODSTART"'"' > /tmp/variable.file
	echo 'WWAN="'"$WWAN"'"' >> /tmp/variable.file
	echo 'USBN="'"$USBN"'"' >> /tmp/variable.file
	echo 'ETHN="'"$ETHN"'"' >> /tmp/variable.file
	echo 'WDMN="'"$WDMN"'"' >> /tmp/variable.file
	echo 'BASEPORT="'"$BASEPORT"'"' >> /tmp/variable.file
}

ifname1="ifname"
if [ -e /etc/newstyle ]; then
	ifname1="device"
fi

echo 1 > /tmp/gotpcie
echo 1 > /tmp/gotpcie1
echo 1 > /tmp/usbwait

if [ ! -f /tmp/bootend.file ]; then
	log "Delay for boot up"
	sleep 1
	while [ ! -f /tmp/bootend.file ]; do
		sleep 1
	done
	sleep 1
fi

log "Connecting a MHI Modem"

uci delete network.xlatd1
uci commit network

lspci -Dk > /tmp/mhipci
while IFS= read -r line; do
	dev=$(echo "$line" | grep "Device")
	if [ -z "$dev" ]; then
		dev=$(echo "$line" | grep "SDX55")
	fi
	if [ -z "$dev" ]; then
		dev=$(echo "$line" | grep "SDX24")
	fi
	if [ ! -z "$dev" ]; then
		read -r line
		kd=$(echo "$line" | grep "Kernel driver")
		if [ -z "$kd" ]; then
			read -r line
		fi
		mhi=$(echo "$line" | grep "mhi-pci-generic")
		if [ ! -z "$mhi" ]; then
			dev=$(echo "$dev" | tr " " "," | cut -d, -f1)
			size=${#dev}
			if [ "$size" -eq 7 ]; then
				pcinum="0000:$dev"
			else
				pcinum="$dev"
			fi
			break			
		fi
		mhi=$(echo "$line" | grep "mtk_t7xx")
		if [ ! -z "$mhi" ]; then
			dev=$(echo "$dev" | tr " " "," | cut -d, -f1)
			size=${#dev}
			if [ "$size" -eq 7 ]; then
				pcinum="0000:$dev"
			else
				pcinum="$dev"
			fi
			break			
		fi
	fi
done < /tmp/mhipci

vendor=$(cat /sys/bus/pci/devices/$pcinum/vendor)
vendor=${vendor:2:4}
if [ "$vendor" != "14c3" ]; then
	echo "1" > /sys/bus/pci/devices/$pcinum/remove
	log "PCi Remove"
	sleep 25
	echo "1" > /sys/bus/pci/rescan
	log "Rescan"
	sleep 5
fi
MODCNT=2
COUNTER=1
retresult=0
while [ $COUNTER -le $MODCNT ]; do
	EMPTY=$(uci get modem.modem$COUNTER.empty)
	if [ "$EMPTY" -ne 0 ]; then
		retresult=$COUNTER
		break
	fi
	let COUNTER=COUNTER+1
done

source /tmp/variable.file
CURRMODEM=1
uci set modem.modem$CURRMODEM.empty=0
uci commit modem
echo "$retresult" > /tmp/gotpcie1

MODSTART=`expr $MODSTART + 1`
save_variables

echo 'on' > /sys/devices/platform/soc/11280000.pcie/pci0000:00/0000:00:00.0/$pcinum/power/control
vendor=$(cat /sys/bus/pci/devices/$pcinum/vendor)
vendor=${vendor:2:4}
device=$(cat /sys/bus/pci/devices/$pcinum/device)
device=${device:2}

subvendor=$(cat /sys/bus/pci/devices/$pcinum/subsystem_vendor)
subvendor=${subvendor:2:4}
subdevice=$(cat /sys/bus/pci/devices/$pcinum/subsystem_device)
subdevice=${subdevice:2}

display_top; display "Modem Vendor and Device ID"
display "ID=$pcinum : $vendor $device Sub $subvendor $subdevice"; display_bottom

PCI_VENDOR_ID_QCOM="17cb"
PCI_VENDOR_ID_QUECTEL="1eac"
PCI_VENDOR_ID_FOXCONN="105b"
PCI_VENDOR_ID_THALES="1269"
PCI_VENDOR_ID_FIB="14c3"
		
case "$vendor" in
	"$PCI_VENDOR_ID_QCOM" )
		if [ "$device" = 0308 ]; then
			if [ "$subvendor" = 1c5d ]; then
				log "Telit FN990 not supported"
				exit 0
			else
				if [ "$subvendor" = 18d7 -a "$subdevice" = 0301 ]; then
					uPr="EM9293"
					uMa="Sierra"
					uVid="1199"
					uPid="90d3"
				else
					uVid="2c7c"
					uMa="Quectel"
					uPid="0801"
					uPr="RM520"
					# subvendor - 17cb  subdevice - 5201	GLAA
					# subvendor - 17cb  subdevice - 0308	GLAP
					# subvendor - 1eac  subdevice - 3003
				fi
			fi
		else
			if [ "$device" = 0309 ]; then
				if [ "$subvendor" = 17cb ]; then
					ATCMDD="ATI"
					OX=$($ROOTER/gcom/gcom-locked "/dev/wwan0at0" "run-at.gcom" "$CURRMODEM" "$ATCMDD")
					FM190=$(echo "$OX" | grep "FM190")
					if [ ! -z "$FM190" ]; then
						uVid="2cb7"
						uMa="Fibocom"
						uPid="0001"
						uPr="FM190"
					else
						uVid="2c7c"
						uMa="Quectel"
						uPid="0122"
						uPr="RM551"
					fi
					# subvendor - 17cb  subdevice - 0309
				else
					log "Modem not supported"
					exit 0
				fi
			else
				if [ "$device" = 0306 ]; then
					if [ "$subvendor" = 17cb -a "$subdevice" = 010c ]; then
						ATCMDD="ATI"
						OX=$($ROOTER/gcom/gcom-locked "/dev/wwan0at0" "run-at.gcom" "$CURRMODEM" "$ATCMDD")
						t99=$(echo "$OX" | grep "T99W175")
						if [ ! -z "$t99" ]; then
							uVid="413c"
							uMa="Foxconn"
							uPid="81df"
							uPr="T99W175"
						else
							uVid="2c7c"
							uMa="Quectel"
							uPid="0800"
							uPr="RM500"
						fi
					else
						if [ "$subvendor" = 17cb -a "$subdevice" = 5051 ]; then
							uVid="2c7c"
							uMa="Quectel"
							uPid="0800"
							uPr="RM505"
						else
							if [ "$subvendor" = 105b -a "$subdevice" = e0b0 ]; then
								uVid="413c"
								uMa="Foxconn"
								uPid="81df"
								uPr="T99W175"
							else
								if [ "$subvendor" = 18d7 -a "$subdevice" = 0200 ]; then
									uVid="1199"
									uMa="Sierra"
									uPid="90d3"
									uPr="EM919x"
								else
									log "Modem not supported"
									exit 0
								fi
							fi
						fi
					fi
				else
					if [ "$device" = 0304 ]; then
						if [ "$subvendor" = 17cb -a "$subdevice" = 0307 ]; then
							uVid="2c7c"
							uMa="Quectel"
							uPid="0620"
							uPr="EM160/120"
						else
							log "Modem not supported"
							exit 0
						fi
					fi
				fi
			fi
		fi
	;;
	"$PCI_VENDOR_ID_QUECTEL" )
		if [ "$device" = 1004 -o "$device" = 1007 ]; then 
			uVid="2c7c"
			uMa="Quectel"
			uPid="0801"
			uPr="RM520"
		fi
		if [ "$device" = 1001  -o "$device" = 2001 ]; then
			uVid="2c7c"
			uMa="Quectel"
			uPid="0620"
			uPr="EM120"
		fi
		if [ "$device" = 1002  -o "$device" = 100d ]; then
			uVid="2c7c"
			uMa="Quectel"
			uPid="0620"
			uPr="EM160"
		fi
	;;
	"$PCI_VENDOR_ID_FOXCONN" )
		if [ "$device" = e0ab  -o "$device" = e0b0 -o "$device" = e0b1 -o "$device" = e0bf -o "$device" = e0c3  -o "$device" = e0af ]; then
			uVid="413c"
			uMa="Foxconn"
			uPid="81df"
			uPr="T99W175"
		else
			log "Foxconn not supported"
			exit 0
		fi
	;;
	"$PCI_VENDOR_ID_THALES" )
		log "Thales not supported"
		exit 0
	;;
	"$PCI_VENDOR_ID_FIB" )
		uVid="0e8d"
		uMa="Fibocom"
		uPid="7127"
		uPr="FM350"
	;;
	
esac


display_top; display "Start of Modem Detection and Connection Information"
display "Product=${uPr:-?} $vendor $device Sub $subvendor $subdevice"; display_bottom

list=$(ls /dev | grep "wwan0")
echo "$list" > /tmp/devwwan
i=1
while IFS= read -r line; do
	log "Interface Name : "$i" /dev/"$line
	let i=$i+1
done < /tmp/devwwan

uci set modem.modem$CURRMODEM.empty=0
uci set modem.modem$CURRMODEM.uVid=$uVid
uci set modem.modem$CURRMODEM.uPid=$uPid
uci set modem.modem$CURRMODEM.idV=$uVid
uci set modem.modem$CURRMODEM.idP=$uPid
uci set modem.modem$CURRMODEM.baseport=0
uci set modem.modem$CURRMODEM.maxport=0
uci set modem.modem$CURRMODEM.proto=91
uci set modem.modem$CURRMODEM.manuf=$uMa
uci set modem.modem$CURRMODEM.model=$uPr
uci set modem.modem$CURRMODEM.serial=xxxx
uci set modem.modem$CURRMODEM.celltype="-"
uci set modem.modem$CURRMODEM.active=1
uci set modem.modem$CURRMODEM.connected=0
uci commit modem
if [ -e $ROOTER/modem-led.sh ]; then
	$ROOTER/modem-led.sh $CURRMODEM 1
fi

rm -f /tmp/usbwait
rm -f /tmp/gotpcie1
/usr/lib/rooter/mhi/create_mhi.sh $CURRMODEM

