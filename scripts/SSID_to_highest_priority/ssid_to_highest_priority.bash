#!/bin/bash 
#
# (C) 2013 Henri Shustak
# Licenced under the Apache Licence
# http://www.apache.org/licenses/LICENSE-2.0
# Latest copy of this script is available from :
# http://github.com/henri/ssidthp/
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
#         connected to the network to be moved to the highest priority in the preferred network list.
#         (2) Running this script will not mean that you are connected to the network provided.
#         To connect to the preferred network, you should power cycling the airport card. Below
#         are two commands which should switch off and then back on the airport card : 
#              # networksetup -setairportpower en1 off
#              # networksetup -setairportpower en1 on
#
#
# Usage : set_wireless_network_to_highest_priority.bash <wireless_network_name>
#
#
# Version History : v1.0 - initial release
#                   v1.1 - minor logging improvement and bug fix relating to the selecting the correct security setting
#                   v1.2 - updated the LOGGERTAG variable to match the name of the project
#                   v1.3 - implimented automated detection of the wireless network hardware device
#                   v1.4 - fixed various spelling as well as fixed a capitalisation issue
#                   v1.5 - fixed various bugs relating to reliability particulatly when running on Mac OS X 10.5.x systems.
#                   v1.6 - resovled bug when running on Mac OS X 10.5.x systems.
#                   v1.7 - added support for checking if the network already is set as highest priority and if we are connected, to quickly bypass any changes
#


# Configuration
WIRELESSHARDWAREDEVICE="" # leave blank for automated detection
SECURITYTYPE="" # leave blank for automated detection

# Internal Varibles
LOGGERTAG="ssidthp"
LOGGERPRIORITY="notice"
CURRENTUSER=`whoami`
WIRELESSNETWORKTOPRIORITISE="${1}"
NETWORKSETUPCOMMAND="/usr/sbin/networksetup"
AIRPORTCOMMAND="/System/Library/PrivateFrameworks/Apple80211.framework/Versions/Current/Resources/airport"
DEFAULTWIRELESSNETWORKNAME=""
INITIALAIRPORTPOWERSTATUS=""
CURRENT_HIGHEST_PRIORITY_SSID=""
LOG_MESSAGE_ECHO="YES"

# Functions
function log_message() {
	# using echo rather than logger, will keep the output on the terminal simple and within standard output.
	logger -p "${LOGGERPRIORITY}" -t "${LOGGERTAG}" "${1}"
	if [ "${LOG_MESSAGE_ECHO}" == "YES" ] ; then
		echo "    $1"
	fi
}
function list_networks {
	"${NETWORKSETUPCOMMAND}" -listpreferredwirelessnetworks ${WIRELESSHARDWAREDEVICE} | grep -v "Preferred networks on en1:" | cut -c 2-
}
function network_listed_as_prefered {
	list_networks | grep -x "${WIRELESSNETWORKTOPRIORITISE}"
	return ${?}
}


# Pre-Flight Checks
if ! [ -e "${NETWORKSETUPCOMMAND}" ] ; then log_message "ERROR! : Unable to locate required helper utility : \"${NETWORKSETUPCOMMAND}\" ." ; exit -127 ; fi
if ! [ -e "${AIRPORTCOMMAND}" ] ; then log_message "ERROR! : Unable to locate required helper utility : \"${AIRPORTCOMMAND}\" ." ; exit -127 ; fi
if [ "${CURRENTUSER}" != "root" ] ; then log_message "ERROR! : This script must be run with super user privileges." ; exit -127 ; fi
if [ "`${AIRPORTCOMMAND} -I | awk -F \"AirPort: \" '{print $2}'`" == "Off" ] ; then log_message "ERROR! : Wireless hardware is powered off."  ; exit -127 ; fi
if [ ${#} -ne 1 ]; then log_message "USAGE : set_wireless_network_to_highest_priority.bash <wireless_network_name>." ; exit -127 ; fi

# Check if there was a WIRELESSHARDWAREDEVICE varible specified (eg. en1, en0)
if [ "${WIRELESSHARDWAREDEVICE}" == "" ] ; then 
	# attempt to dynamically calculate which device should be used, based on default names for network devices.
	if [ `uname -r | awk -F "." '{print $1}'` -le 10 ] ; then DEFAULTWIRELESSNETWORKNAME="AirPort" ; else DEFAULTWIRELESSNETWORKNAME="Wi-Fi" ; fi
	WIRELESSHARDWAREDEVICE=`networksetup -listallhardwareports | grep "${DEFAULTWIRELESSNETWORKNAME}" -A 1 | tail -n 1 | awk -F "Device: " '{print $2}'`
fi
	
# Check if the wireless network we are setting as the highest priority is even in the list of prefered networks.
if [ `uname -r | awk -F "." '{print $1}'` -le 9 ] ; then 
	# Running on Mac OS 10.5 or earlier (not great support with this script), which means skipping this check.
	log_message "This script is designed to work with Mac OS X 10.6 or later." 
else
	# Running on Mac OS 10.6 or later carry out additional check
	if [ "`network_listed_as_prefered; echo ${?}`" == "1" ] ; then 
		log_message "ERROR! : The network \"${WIRELESSNETWORKTOPRIORITISE}\" was not found in the preferred networks list."
		log_message "         Please ensure the network SSID provided to this script is within the list of"
		log_message "         preferred networks on this system and attempt to run this script again."
		exit -127
	fi
fi


# Logic - Lets move the Wi-Fi SSID network priority to the top

# Step #2 - Find the security type used for this wireless network
if [ "${SECURITYTYPE}" == "" ] ; then 
	# Attempt auto discovery of security type if there one has not been manually specified
	if [ `uname -r | awk -F "." '{print $1}'` -le 9 ] ; then 
		# Discover security type on Mac OS X 10.5 and earlier
		SECURITYTYPE=`"${AIRPORTCOMMAND}" -s | awk -v n="${WIRELESSNETWORKTOPRIORITISE}" '$1==n' | head -n 1 | awk '{print $5}' | awk -F "(" '{print $1}'`
	else
		# Discover security type on Mac OS X 10.6 and later
		SECURITYTYPE=`"${AIRPORTCOMMAND}" -s | awk -v n="${WIRELESSNETWORKTOPRIORITISE}" '$1==n' | head -n 1 | awk '{print $7}' | awk -F "(" '{print $1}'`
	fi
	if [ "${SECURITYTYPE}" == "" ] ; then
		# Check the scurity type for the SSID to prioritize was found during auto discovery.
		log_message "ERROR! : Unable to determine the security type of the network : \"${WIRELESSNETWORKTOPRIORITISE}\""
		exit -127
	fi
fi

# Step #1 - Check if this network has the highest priority and if we are currently connected
CURRENT_HIGHEST_PRIORITY_SSID=`"${NETWORKSETUPCOMMAND}" -listpreferredwirelessnetworks ${WIRELESSHARDWAREDEVICE} | head -n 2 | tail -n 1 | awk -F "\t" '{print $2}'`
if [ "${CURRENT_HIGHEST_PRIORITY_SSID}" == "${WIRELESSNETWORKTOPRIORITISE}" ] ; then
	LOG_MESSAGE_ECHO="NO"
	log_message "Network \"${WIRELESSNETWORKTOPRIORITISE}\" is already the preferred network."
	exit 0
fi

# Step #2 - Remove the network from the preferred network list
"${NETWORKSETUPCOMMAND}" -removepreferredwirelessnetwork ${WIRELESSHARDWAREDEVICE} "${WIRELESSNETWORKTOPRIORITISE}" | logger -p "${LOGGERPRIORITY}" -t "${LOGGERTAG}"
if [ ${?} != 0 ] ; then
	log_message "ERROR! : Unable to remove the network \"${WIRELESSNETWORKTOPRIORITISE}\" from the preferred network list."
	exit -127
fi

# Step #3 - Add it back to the list at index 0
"${NETWORKSETUPCOMMAND}" -addpreferredwirelessnetworkatindex ${WIRELESSHARDWAREDEVICE} "${WIRELESSNETWORKTOPRIORITISE}" 0 "${SECURITYTYPE}" | logger -p "${LOGGERPRIORITY}" -t "${LOGGERTAG}"
if [ ${?} != 0 ] ; then
	log_message "ERROR! : Unable to add the network \"${WIRELESSNETWORKTOPRIORITISE}\" back to the preferred network list."
	exit -127
fi

exit 0

