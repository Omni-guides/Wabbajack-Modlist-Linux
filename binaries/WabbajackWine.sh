#!/bin/bash
#
##############################################################
#                                                            #
# Attempt to automate installing Wabbajack on Linux via Wine #
#                                                            #
#            Alpha v0.05 - Omni, from 12/05/2024             #
#                                                            #
##############################################################

# - v0.01 - Initial script structure
# - v0.02 - Added function for detecting the wine version
# - v0.02 - Added function for setting Wabbajack directry path
# - v0.02 - Added function for setting wine prefix path
# - v0.02 - Added function to create the Wabbajack directory and wine prefix
# - v0.03 - Added function to download required .exe files
# - v0.03 - Added function to install and configure WebView and set up Wabbajack Application entry
# - v0.04 - Added function to try to detect the Steam library.
# - v0.04 - Added function to create a Desktop item.
# - v0.04 - Added function to ask if Wabbajack should be started now.
# - v0.05 - Tweak to wine version comparison removing the requirement for 'bc'

# Current Script Version (alpha)
script_ver=0.05

# Today's date
date=$(date +"%d%m%y")

# Set up and blank logs
LOGFILE=$HOME/wabbajack-via-wine-sh.log
echo "" >$HOME/wabbajack-via-wine-sh.log
#set -x

######################
# Fancy banner thing #
######################

if [ -f "/usr/bin/toilet" ]; then
	toilet -t -f smmono12 -F border:metal "Omni-Guides (alpha)"
else
	echo "=================================================================================================="
	echo "|  #######  ##     ## ##    ## ####          ######   ##     ## #### ########   ########  ###### |"
	echo "| ##     ## ###   ### ###   ##  ##          ##    ##  ##     ##  ##  ##     ## ##       ##    ## |"
	echo "| ##     ## #### #### ####  ##  ##          ##        ##     ##  ##  ##     ## ##       ##       |"
	echo "| ##     ## ## ### ## ## ## ##  ##  ####### ##   #### ##     ##  ##  ##     ## ######    ######  |"
	echo "| ##     ## ##     ## ##  ####  ##          ##    ##  ##     ##  ##  ##     ## ##             ## |"
	echo "| ##     ## ##     ## ##   ###  ##          ##    ##  ##     ##  ##  ##     ## ##       ##    ## |"
	echo "|  #######  ##     ## ##    ## ####          ######    #######  #### ########   ########  ###### |"
	echo "============================================================================~~--(alpha)--~~======="
fi

#########
# Intro #
#########

echo ""
echo -e "This is an experimental script - an attempt to automate as much as possible of the process of getting"
echo -e "Wabbajack running on Linux. Please be aware that stability of the Wabbajack application is not guaranteed."
echo -e "Please use at your own risk and accept that in the worst case, you may have to re-run this script to "
echo -e "create a new prefix for WabbaJack. You can report back to me via GitHub or the Official Wabbajack Discord"
echo -e "if you discover an issue with this script. Any other feedback, positive or negative, is also most welcome."

echo -e "\nPress any key to continue..."
echo
read -n 1 -s -r -p ""

#############
# Functions #
#############

######################################
# Detect Wine and winetricks version #
######################################

detect_wine_version() {

	# Which version of wine is installed?
	wine_binary=$(which wine)
	echo -e "Wine Binary Path: $wine_binary" >>$LOGFILE 2>&1
	wine_version=$(wine --version | grep -o '[0-9]\.[0-9]*')

	echo -e "Wine Version: $wine_version" >>$LOGFILE 2>&1

	if [[ "$wine_version" < "9.15" ]]; then
		echo -e "Wabbajack requires Wine newer than 9.15. Please arrange this on your system and rerun this script."
		exit 0
	else
		echo -e "Wine version $wine_version, should be fine" >>$LOGFILE 2>&1
	fi

	# Is winetricks installed?
	if [[ $(which winetricks) ]]; then
		echo -e "Winetricks found at: $(which winetricks)" >>$LOGFILE 2>&1
	else
		echo -e "Winetricks not detected. Please arrange this on your system and rerun this script." >>$LOGFILE 2>&1
		exit 0
	fi

}

###########################
# Get Wabbajack Directory #
###########################

get_wineprefix_and_application_directory() {
	local application_directory_prompt="Enter the path where you want to store your application directory: "

	while true; do
		# Prompt for the application directory
		read -e -p "$application_directory_prompt" application_directory
		echo

		# Confirm the application directory
		while true; do
			echo "Are you sure you want to store the application directory in \"$application_directory\"? (y/n): "
			read -r confirm
			echo

			if [[ $confirm == "y" || $confirm == "Y" ]]; then
				# Check for existing application directory and warn
				break 2 # Break out of both loops
			elif [[ $confirm == "n" || $confirm == "N" ]]; then
				break # Break out of the inner loop, continue the outer loop
			else
				echo "Invalid input. Please enter 'y' or 'n'."
			fi
		done
	done

	local wineprefix_prompt="Do you want to create the Wine prefix in the default location (\"$application_directory/.wine\")? (y/n): "

	# Ask about the default Wine prefix location
	read -e -p "$wineprefix_prompt" confirm

	if [[ $confirm == "y" || $confirm == "Y" ]]; then
		# Set the Wine prefix in the default location
		export wineprefix="$application_directory/.wine"
	else
		# Call the get_wineprefix function to get the custom Wine prefix
		set_wineprefix
	fi

	echo "Application Directory Path: $application_directory." >>$LOGFILE 2>&1
	echo "Wine Prefix Path: $wineprefix" >>$LOGFILE 2>&1
}

###################
# Set Wine Prefix #
###################

set_wineprefix() {

	local wineprefix_prompt="Enter the path where you want to store your Wine prefix: "

	while true; do
		# Prompt for the path, allowing tab completion
		read -e -p "$wineprefix_prompt" wineprefix
		echo

		# Confirm the path
		while true; do
			echo "Are you sure you want to store the Wine prefix in \"$wineprefix\"? (y/n): "
			read -r confirm
			echo

			if [[ $confirm == "y" || $confirm == "Y" ]]; then
				break
			elif [[ $confirm == "n" || $confirm == "N" ]]; then
				read -e -p "$wineprefix_prompt" wineprefix
			else
				echo "Invalid input. Please enter 'y' or 'n'."
			fi
		done

		# Check for existing .wine directory
		if [[ -d "$wineprefix/.wine" ]]; then
			echo "WARNING: This will overwrite any existing directory in \"$wineprefix/.wine\"."
			while true; do
				echo "Continue? (y/n): "
				read -r confirm
				echo

				if [[ $confirm == "y" || $confirm == "Y" ]]; then
					break
				elif [[ $confirm == "n" || $confirm == "N" ]]; then
					read -e -p "$wineprefix_prompt" wineprefix
				else
					echo "Invalid input. Please enter 'y' or 'n'."
				fi
			done
		else
			break
		fi
	done

	echo

	# Set the wineprefix variable
	export wineprefix

}

#########################################
# Create Wabbajack Directory and prefix #
#########################################

create_wine_environment() {
	# Create the application directory if it doesn't exist
	mkdir -p "$application_directory"

	# Check if the Wine prefix exists and delete it if necessary
	if [[ -d "$wineprefix" ]]; then
		rm -rf "$wineprefix"
	fi

	# Create the Wine prefix directory
	mkdir -p "$wineprefix"

	# Set the WINEPREFIX variable and run wineboot
	export WINEPREFIX="$wineprefix"
	#export WINEDLLOVERRIDES="mscoree=d;mshtml=d"
	wineboot >>$LOGFILE 2>&1
}

########################################################
# Download Webview Installer and Wabbajack Application #
########################################################

download_apps() {

	echo -e "\nDownloading Wabbajack Application..."

	if ! [ -f $application_directory/Wabbajack.exe ]; then
		wget https://github.com/wabbajack-tools/wabbajack/releases/latest/download/Wabbajack.exe -O $application_directory/Wabbajack.exe
		#Set as executable
		chmod +x $application_directory/Wabbajack.exe
	fi

	echo -e "\nDownloading WebView Installer..."

	if ! [ -f $application_directory/Wabbajack/MicrosoftEdgeWebView2RuntimeInstallerX64.exe ]; then
		wget https://msedge.sf.dl.delivery.mp.microsoft.com/filestreamingservice/files/6d376ab4-4a07-4679-8918-e0dc3c0735c8/MicrosoftEdgeWebView2RuntimeInstallerX64.exe -O $application_directory/MicrosoftEdgeWebView2RuntimeInstallerX64.exe
	fi

}

############################################
# Install WebView, configure Wine settings #
############################################

install_and_configure() {

	# set based on distro? harware?...
	echo -e "\nChanging the default renderer used.." >>$LOGFILE 2>&1
	WINEPREFIX=$wineprefix winetricks renderer=vulkan >>$LOGFILE 2>&1

	# Install WebView
	echo -e "\nInstalling Webview, this can take a while, please be patient" >>$LOGFILE 2>&1
	WINEPREFIX=$wineprefix wine $HOME/Wabbajack/MicrosoftEdgeWebView2RuntimeInstallerX64.exe >>$LOGFILE 2>&1

	# Change prefix version
	echo -e "\nChange the default prefix version to win7.." >>$LOGFILE 2>&1
	WINEPREFIX=$wineprefix winecfg -v win7 >>$LOGFILE 2>&1

	# Add Wabbajack as an application
	echo -e "\nAdding Wabbajack Application to customise settings.." >>$LOGFILE 2>&1
	cat <<EOF >$HOME/Wabbajack/WJApplication.reg
Windows Registry Editor Version 5.00

[HKEY_CURRENT_USER\Software\Wine\AppDefaults\Wabbajack.exe]
"Version"="win10"
EOF

	WINEPREFIX=$wineprefix wine regedit $HOME/Wabbajack/WJApplication.reg >>$LOGFILE 2>&1

	echo
}

#################################
# Detect and Link Steam Library #
#################################

detect_link_steam_library() {

	# Possible Steam library locations
	steam_library_locations=(
		"$HOME/.local/share/Steam/steamapps"
		"$HOME/.steam/steam/steamapps"
		"$HOME/Library/Application Support/Steam/steamapps"
		"/opt/steam/steamapps"
		"/usr/share/Steam/steamapps"
		"/usr/local/share/Steam/steamapps"
	)

	# Function to check if a directory is a Steam library
	is_steam_library() {
		local location="$1"

		if [[ -d "$location" ]]; then
			if find "$location" -type f -name "libraryfolders.vdf" -print | grep -q "$location"; then
				return 0
			fi
		fi

		return 1
	}

	# Find all valid Steam library locations
	valid_steam_libraries=()
	for location in "${steam_library_locations[@]}"; do
		if is_steam_library "$location"; then
			valid_steam_libraries+=("$location")
		fi
	done

	# Filter out symlinked libraries
	filtered_steam_libraries=()
	for location in "${valid_steam_libraries[@]}"; do
		if ! [[ -L "$(dirname "$location")" ]]; then
			filtered_steam_libraries+=("$location")
		fi
	done

	# If multiple valid libraries were found, ask the user to choose
	if [[ ${#filtered_steam_libraries[@]} -gt 1 ]]; then
		echo "Multiple Steam libraries found. Please select one:"
		for i in "${!filtered_steam_libraries[@]}"; do
			echo "$((i + 1)). ${filtered_steam_libraries[$i]}"
		done

		read -p "Enter the number of the desired library: " choice
		if [[ ! "$choice" =~ ^[0-9]+$ ]]; then
			echo "Invalid choice. Please enter a number."
			exit 1
		fi

		chosen_library="${filtered_steam_libraries[$((choice - 1))]}"
	elif [[ ${#filtered_steam_libraries[@]} -eq 1 ]]; then
		chosen_library="${filtered_steam_libraries[0]}"
	else
		# If no library was found, ask the user for the path
		read -e -p "Steam library not found. Please enter the path: " steam_library_path
		if [[ ! -d "$steam_library_path" ]]; then
			echo "Invalid path. Please enter a valid directory."
			exit 1
		fi

		if ! is_steam_library "$steam_library_path"; then
			echo "The specified path does not appear to be a Steam library. Please check the path and try again."
			exit 1
		fi

		chosen_library="$steam_library_path"
	fi

	# If a valid library was found, print its location
	if [[ -n "$chosen_library" ]]; then
		echo "Steam library found at: $chosen_library"
	else
		echo "Steam library not found. Please check the installation."
	fi

	# Link Steam Library
	echo -e "\nLinking Steam library.."
	ln -s $chosen_library $wineprefix/drive_c/Program\ Files\ \(x86\)/Steam

}

############################
# Create Desktop Shortcut? #
############################

create_desktop_shortcut() {
	echo "Do you want to create a desktop shortcut for Wabbajack? (y/n):"
	read -r create_shortcut

	if [[ $create_shortcut == "y" || $create_shortcut == "Y" ]]; then
		desktop_file="$HOME/Desktop/WabbajackTest.desktop"
		cat >"$desktop_file" <<EOF
[Desktop Entry]
Name=Wabbajack
Exec=env HOME="$HOME" WINEPREFIX=$wineprefix wine $application_directory/Wabbajack.exe
Type=Application
StartupNotify=true
Path=~/Wabbajack
Icon=$application_directory/Wabbajack.ico
EOF
		chmod +x "$desktop_file"
		echo "Desktop shortcut created at $desktop_file"
	fi

	#Grab an icon for it
	wget -q -O $application_directory/Wabbajack.ico https://raw.githubusercontent.com/wabbajack-tools/wabbajack/main/Wabbajack.Launcher/Assets/wabbajack.ico
}

####################
# Start Wabbajack? #
####################

start_wabbajack() {

	echo "Do you want to start Wabbajack now? (y/n):"
	read -r start_wabbajack

	if [[ $start_wabbajack == "y" || $start_wabbajack == "Y" ]]; then
		echo -e "\nTidying up before starting Wabbajack.."
		sleep 10

		# Run Wabbajack
		echo -e "\nStarting Wabbajack..."
		cd $application_directory
		WINEPREFIX=$wineprefix WINEDEBUG=-all wine $application_directory/Wabbajack.exe >>$LOGFILE 2>&1
	fi
}

#####################
# Run the Functions #
#####################

# Detect Wine and winetricks version
detect_wine_version

# Get Wabbajack Directory
get_wineprefix_and_application_directory

# Create Wabbajack Directory
create_wine_environment

# Download Webview Installer and Wabbajack Application
download_apps

# Install WebView, configure Wine settings
install_and_configure

# Detect and Link Steam Library
detect_link_steam_library

# Create Desktop Shortcut?
create_desktop_shortcut

# Start Wabbajack?
start_wabbajack

echo "Set up complete. "

exit
