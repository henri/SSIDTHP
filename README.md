# SSID to High Priority #

<h1><img src="http://www.lbackup.org/_media/golden_safe.jpg" valign="middle"/></h1>

About
--------

This is an open source (Apache 2.0) script and package build system which is designed to make building a package to set a specific SSID as the highest priority on a OS X based system as simple as possible..

License: [Apache 2.0 License][1]


Usage Instructions
---------

- Ensure you have the developer tools and command line tools installed. In particular importance is the `pkgbuild` command.
- Duplicate the build script with an approriate name
- Edit your copy of the build script setting the *package_identifier*, *ssid_to_prioritize*, *package_output_name* and *package_version* varibles to suite you requirments.
- Run the build script and with all things going well collect your output package from the build_output directory


Notes relating to using the core script within another system
---------
 
The core part of this system is a script called "ssid_to_highest_priority.bash" which is berried within the scripts direcotry.  Usage information is located in the coments of this script and is summerized below for convenince : 
`set_wireless_network_to_highest_priority.bash <wireless_network_name>`

Finally, should you wish to use this script in another system it is important that you adhear to the licence agreement.


  [1]: http://www.apache.org/licenses/LICENSE-2.0

