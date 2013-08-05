#!/bin/bash 
#
# (C) 2013 Henri Shustak
# Licenced under the Apache Licence
# http://www.apache.org/licenses/LICENSE-2.0
# Latest copy of this script is availible from :
# http://github.com/henri/swnthp/
#
#
# About this script :
#
#         This script takes a single parameter which is the wireless network name
#         you wish to give the highest priority on an system running OS X.
#
#
# Known issues :
#
#         (1) The current version of this script may disrupt network activity if you are currently
#         connected to the network to be moved to the highest priority in the prefered network list.
#         (2) Runnin this script will not mean that you are connected to the network provided.
#         To connect to the prefered network, you try power cycling the airport card. Below
#         are two commands which should switch off and then backon the airport card : 
#              # networksetup -setairportpower en1 off
#              # networksetup -setairportpower en1 on
#
#
# Usage : set_wireless_network_to_highest_priority.bash <wireless_network_name>
#
#
# Version History : v1.0 - initial release
# 


# Internal Varibles
LOGGERTAG="swnthp"
LOGGERPRIORITY="notice"
WIRELESSHARDWAREDEVICE="en1"
CURRENTUSER=`whoami`
WIRELESSNETWORKTOPRIORITISE="${1}"
NETWORKSETUPCOMMAND="/usr/sbin/networksetup"
AIRPORTCOMMAND="/System/Library/PrivateFrameworks/Apple80211.framework/Versions/Current/Resources/airport"
SECURITYTYPE=""

# Functions
function log_message() {
	# using echo rather than logger, will keep the output on the termianl simple and within standard output.
	logger -p "${LOGGERPRIORITY}" -t "${LOGGERTAG}" "${1}"
	echo "    $1"
}
function list_networks {
	"${NETWORKSETUPCOMMAND}" -listpreferredwirelessnetworks ${WIRELESSHARDWAREDEVICE} | grep -v "Preferred networks on en1:" | cut -c 2-
}
function network_listed_as_prefered {
	list_networks | grep "${WIRELESSNETWORKTOPRIORITISE}"
	return ${?}
}

# Pre-Flight Checks
if ! [ -e "${NETWORKSETUPCOMMAND}" ] ; then log_message "ERROR! : Unable to locate required helper utility : \"${NETWORKSETUPCOMMAND}\" ." ; exit -127 ; fi
if ! [ -e "${AIRPORTCOMMAND}" ] ; then log_message "ERROR! : Unable to locate required helper utility : \"${AIRPORTCOMMAND}\" ." ; exit -127 ; fi
if [ "${CURRENTUSER}" != "root" ] ; then log_message "ERROR! : This script must be run with super user privileges." ; exit -127 ; fi
if [ ${#} -ne 1 ]; then log_message "USAGE : set_wireless_network_to_highest_priority.bash <wireless_network_name>." ; exit -127 ; fi
if [ "`network_listed_as_prefered; echo ${?}`" == "1" ] ; then 
	log_message "ERROR! : The network \"${WIRELESSNETWORKTOPRIORITISE}\" was not found in the preferred networks list."
	log_message "         Please ensure the network SSID provided to this script is within the list of"
	log_message "         prefered networks on this system and attempt to run this script again."
	exit -127
fi 

# Logic - Lets move the Wi-Fi SSID network priority to the top

# Step #1 - Find the security type used for this wireless network
SECURITYTYPE=`"${AIRPORTCOMMAND}" -s | awk -v n=$WIRELESSNETWORKTOPRIORITISE '$1==n' | head -n 1 | awk '{print $7}'`
if [ "${SECURITYTYPE}" == "" ] ; then
	log_message "ERROR! : Unable to determin the security type of the network : \"${WIRELESSNETWORKTOPRIORITISE}\""
	exit -127
fi

# Step #2 - Remove the network from the prefered network list
"${NETWORKSETUPCOMMAND}" -removepreferredwirelessnetwork ${WIRELESSHARDWAREDEVICE} "${WIRELESSNETWORKTOPRIORITISE}" 1> /dev/null
if [ ${?} != 0 ] ; then
	log_message "ERROR! : Unable to remove the network \"${WIRELESSNETWORKTOPRIORITISE}\" from the prefered network list."
	exit -127
fi

# Step #3 - Add it back to the list at index 0
"${NETWORKSETUPCOMMAND}" -addpreferredwirelessnetworkatindex ${WIRELESSHARDWAREDEVICE} "${WIRELESSNETWORKTOPRIORITISE}" 0 "${SECURITYTYPE}" 1> /dev/null
if [ ${?} != 0 ] ; then
	log_message "ERROR! : Unable to add the network \"${WIRELESSNETWORKTOPRIORITISE}\" back to the prefered network list."
	exit -127
fi

exit 0
