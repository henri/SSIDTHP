#!/usr/bin/env bash

# (C) 2013 Henri Shustak
# Licenced under the Apache Licence
# http://www.apache.org/licenses/LICENSE-2.0

# Note : The built package will only work if the SSID is actually in the prefered list.

# Example build script version 1.0

# User varibales
package_identifier="com.mydomain.ssidthp"
ssid_to_prioritize="mySSID_name"
package_version="1.0"


# Intenral variables
parent_directory="`dirname \"${0}\"`"
temporary_build_directory=`mktemp -d /tmp/SSIDTHP_build_directory.XXXXXXXXXXXXX`
exit_status=0
package_output_name="ssidthp.pkg"
realitve_package_output_directory="build_output/`date \"+%Y-%m-%d_%H.%M.%S\"`"
absolute_path_to_package_build_directory="${parent_directory}/${realitve_package_output_directory}"
absolute_path_to_package_build="${absolute_path_to_package_build_directory}/${package_output_name}"
postinstall_template_name="postinstall_template"
postinstall_output_name="postinstall"
realitve_postinstall_script_diectory_name="scripts"


function clean_exit {
	cd /
	#rm -Rf "${temporary_build_directory}"
	exit ${exit_status}
}

# change directory to the temporary build directory
cd "${temporary_build_directory}"
if [ $? != 0 ] ; then echo "ERROR! : Unable to swtich to temporary build directory." ; exit_status=1 ; clean_exit ; fi

# populate temporary build directory with approriate files
rsync -aE "${parent_directory}/" "./"
if [ $? != 0 ] ; then echo "ERROR! : Unable to copy files to temporary build directory." ; exit_status=1 ; clean_exit ; fi

# generate build output directory
mkdir "${absolute_path_to_package_build_directory}"
if [ $? != 0 ] ; then echo "ERROR! : Unable to generate output build directory." ; exit_status=1 ; clean_exit ; fi


# set the SSID to prioritize within the template postinstall script
pwd
sed s/XXXXXXXXXXXXXXX/${ssid_to_prioritize}/g "./${realitve_postinstall_script_diectory_name}/${postinstall_template_name}" > "./${realitve_postinstall_script_diectory_name}/${postinstall_output_name}"

# build that package
#pkgbuild --identifier ${package_identifier} --version ${package_version} --root ./root --scripts ./scripts --install-location / "${absolute_path_to_package_build}"

clean_exit
