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
package_output_name="ssidthp.pkg"


# Intenral variables
exit_status=0
parent_directory="`dirname \"${0}\"`" ; if [ "`echo "${parent_directory}" | grep -e "^/"`" == "" ] ; then parent_directory="`pwd`/${parent_directory}" ; fi
temporary_build_directory=`mktemp -d /tmp/SSIDTHP_build_directory.XXXXXXXXXXXXX`
realitve_package_output_directory="build_output/`date \"+%Y-%m-%d_%H.%M.%S\"`"
absolute_path_to_package_build_directory="${parent_directory}/${realitve_package_output_directory}"
absolute_path_to_package_build="${absolute_path_to_package_build_directory}/${package_output_name}"
postinstall_template_name="postinstall_template"
postinstall_output_name="postinstall"
realitve_postinstall_script_diectory_name="scripts"


function clean_exit {
	cd /
	rm -Rf "${temporary_build_directory}"
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
sed s/XXXXXXXXXXXXXXX/${ssid_to_prioritize}/g "./${realitve_postinstall_script_diectory_name}/${postinstall_template_name}" > "./${realitve_postinstall_script_diectory_name}/${postinstall_output_name}"
if [ $? != 0 ] ; then echo "ERROR! : Issue generating postinstall script from template." ; exit_status=1 ; clean_exit ; fi

# ensure the post install script is executable
chmod 755 "./${realitve_postinstall_script_diectory_name}/${postinstall_output_name}"
if [ $? != 0 ] ; then echo "ERROR! : Unable to make the postinstall script executable." ; exit_status=1 ; clean_exit ; fi

# build that package
pkgbuild --identifier ${package_identifier} --version ${package_version} --root ./root --scripts ./scripts --install-location / "${absolute_path_to_package_build}"

clean_exit
