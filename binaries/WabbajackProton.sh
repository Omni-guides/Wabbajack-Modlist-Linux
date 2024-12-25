#!/bin/bash
#
##################################################################
#                                                                #
# Attempt to automate installing Wabbajack on Linux Steam/Proton #
#                                                                #
#              Alpha v0.02 - Omni, from 23/12/24                 #
#                                                                #
##################################################################

# - v0.01 - Initial script structure.
# - v0.02 - Added functions for most features


# Current Script Version (alpha)
script_ver=0.02

set -x
# Today's date
date=$(date +"%d%m%y")

# Set up and blank logs
LOGFILE=$HOME/wabbajack-via-proton-sh.log
echo "" >$HOME/wabbajack-via-proton-sh.log
# pre-emptively clean up wine processes
cleanup_wine-procs
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
echo -e "Wabbajack running on Linux via Proton through Steam. Please be aware that stability of the Wabbajack "
echo -e "application is not guaranteed. Please use at your own risk and accept that in the worst case, you may "
echo -e "have to remove and re-add the WabbaJack entry in Steam. You can report back to me via GitHub or the "
echo -e "Official Wabbajack Discord if you discover an issue with this script. Any other feedback, positive"
echo -e "or negative, is also most welcome."

echo -e "\e[32m\nPress any key to continue...\e[0m"
echo
read -n 1 -s -r -p ""

#############
# Functions #
#############

#############################
# Detect if running on deck #
#############################

detect_steamdeck() {
	# Steamdeck or nah?

	if [ -f "/etc/os-release" ] && grep -q "steamdeck" "/etc/os-release"; then
		steamdeck=1
		echo "Running on Steam Deck" >>$LOGFILE 2>&1
	else
		steamdeck=0
		echo "NOT A steamdeck" >>$LOGFILE 2>&1
	fi

}

###########################################
# Detect Protontricks (flatpak or native) #
###########################################

detect_protontricks() {

	echo -ne "\nDetecting if protontricks is installed..." >>$LOGFILE 2>&1

	# Check if "which protontricks" outputs "no protontricks"
	if ! which protontricks 2>/dev/null; then
		echo -e "Non-Flatpak Protontricks not found. Checking flatpak..." >>$LOGFILE 2>&1
		if [[ $(flatpak list | grep -i protontricks) ]]; then
			# Protontricks is already installed or available
			echo -e " Flatpak protontricks already installed." >>$LOGFILE 2>&1
			which_protontricks=flatpak
		else
			echo -e "\e[31m \n** Protontricks not found. Do you wish to install it? (y/n): ** \e[0m"
			read -p " " answer
			if [[ $answer =~ ^[Yy]$ ]]; then
				if [[ $steamdeck -eq 1 ]]; then
					# Install Protontricks specifically for Deck
					flatpak install -u -y --noninteractive flathub com.github.Matoking.protontricks
					which_protontricks=flatpak
				else
					read -p "Choose installation method: 1) Flatpak (preferred) 2) Native: " choice
					if [[ $choice =~ 1 ]]; then
						# Install protontricks
						flatpak install -u -y --noninteractive flathub com.github.Matoking.protontricks
						which_protontricks=flatpak
					else
						# Print message and exit
						echo -e "\nSorry, there are way too many distro's to be able to automate this!" | tee -a $LOGFILE
						echo -e "\nPlease check how to install protontricks using your OS package system (yum, dnf, apt, pacman etc)" | tee -a $LOGFILE
					fi
				fi
			fi
		fi
	else
		echo -e " Native Protontricks already found at $(which protontricks)." | tee -a $LOGFILE
		which_protontricks=native
		# Exit function if protontricks is found
		return 0
	fi

}

#############################
# Run protontricks commands #
#############################

run_protontricks() {
	# Determine the protontricks binary path
	if [ "$which_protontricks" = "flatpak" ]; then
		protontricks_bin="flatpak run com.github.Matoking.protontricks"
	else
		protontricks_bin="protontricks"
	fi

	# Construct and execute the command using eval to preserve quotes
	$protontricks_bin "$@"
}

###############################
# Detect Protontricks Version #
###############################

protontricks_version() {

    # Get the current version of protontricks
    protontricks_version=$(run_protontricks -V | cut -d ' ' -f 2 | sed 's/[()]//g' | sed 's/\.[0-9]$//')

    # Remove any non-numeric characters from the version number
    protontricks_version_cleaned=$(echo "$protontricks_version" | sed 's/[^0-9.]//g')

    echo "Protontricks Version Cleaned = $protontricks_version_cleaned" >>$LOGFILE 2>&1

    # Compare version strings directly using simple string comparison
    if [[ "$protontricks_version_cleaned" < "1.11" ]]; then
        echo "Your protontricks version is too old! Update to version 1.11 or newer and rerun this script." | tee -a $LOGFILE
        cleaner_exit
    fi
}

###########################
# Get Wabbajack Directory #
###########################

get_wabbajack_path() {
  local wabbajack_path=""

  while true; do
    read -e -p "Enter the path to your Wabbajack application (directory or .exe): " wabbajack_input

    if [[ -z "$wabbajack_input" ]]; then
      echo "Input cannot be empty. Please try again."  | tee -a $LOGFILE
      continue
    fi

    if [[ -d "$wabbajack_input" ]]; then
      # Input is a directory
      if [[ -f "$wabbajack_input/Wabbajack.exe" ]]; then
        wabbajack_path="$wabbajack_input/Wabbajack.exe"
        break
      else
        echo "Wabbajack.exe not found in the specified directory. Please provide the correct directory or full path." | tee -a $LOGFILE
      fi
    elif [[ -f "$wabbajack_input" ]]; then
      # Input is a file
      if [[ "$wabbajack_input" == *.exe ]]; then
        wabbajack_path="$wabbajack_input"
        break
      else
        echo "The provided file is not an executable (.exe). Please provide the correct path."
      fi
    else
      echo "Invalid path. Please provide a valid directory or file path."
    fi
  done

  echo "Wabbajack path: $wabbajack_path"  >>$LOGFILE 2>&1
  application_directory=$(dirname "$wabbajack_path")
  echo "Application Directory: $application_directory"  >>$LOGFILE 2>&1
}


##################################################
# Detect Wabbajack entry in steam and get App ID #
##################################################

set_appid() {

    wabbajack_entry=`run_protontricks -l | grep -i 'Non-Steam shortcut' | grep -i wabbajack`
	APPID=$(echo $wabbajack_entry | awk {'print $NF'} | sed 's:^.\(.*\).$:\1:')

	echo "Wabbajack App ID:" $APPID >>$LOGFILE 2>&1
}

##############################
# Download WebView Installer #
##############################

webview_installer() {

  echo -e "\e[33m\nDownloading WebView Installer...\e[0m"

  # Check if MicrosoftEdgeWebView2RuntimeInstallerX64.exe exists and skip download if so
  if ! [ -f "$application_directory/MicrosoftEdgeWebView2RuntimeInstallerX64-WabbajackProton.exe" ]; then
    #cp /home/deck/Downloads/MicrosoftEdgeWebView2RuntimeInstallerX64-WabbajackProton.exe $application_directory/MicrosoftEdgeWebView2RuntimeInstallerX64-WabbajackProton.exe
    #wget https://archive.org/download/microsoft-edge-web-view-2-runtime-installer-v109.0.1518.78/MicrosoftEdgeWebView2RuntimeInstallerX64.exe -O "$application_directory/MicrosoftEdgeWebView2RuntimeInstallerX64-WabbajackProton.exe"
    wget https://pixeldrain.com/api/file/dvLfbRkg -O "$application_directory/MicrosoftEdgeWebView2RuntimeInstallerX64-WabbajackProton.exe"
  else
    echo "WebView Installer already exists, skipping download."
  fi

}

####################
# Configure Prefix #
####################

configure_prefix() {

	# set based on distro? harware?...
	echo -e "\e[33m\nChanging the default renderer used..\e[0m" | tee -a $LOGFILE
	run_protontricks --no-bwrap "$APPID" settings renderer=vulkan >>$LOGFILE 2>&1

	# Install WebView
	echo -e "\e[33m\nInstalling Webview, this can take a while, please be patient..\e[0m" | tee -a $LOGFILE
	run_protontricks --no-bwrap -c "wine $application_directory/MicrosoftEdgeWebView2RuntimeInstallerX64-WabbajackProton.exe /silent /install" $APPID >>$LOGFILE 2>&1

	# Change prefix version
	echo -e "\e[33m\nChange the default prefix version to win7..\e[0m" | tee -a $LOGFILE
	run_protontricks --no-bwrap $APPID win7 >>$LOGFILE 2>&1

	# Add Wabbajack as an application
	echo -e "\e[33m\nAdding Wabbajack Application to customise settings..\e[0m" | tee -a $LOGFILE
	cat <<EOF >$application_directory/WJApplication.reg
Windows Registry Editor Version 5.00

[HKEY_CURRENT_USER\Software\Wine\AppDefaults\Wabbajack.exe]
"Version"="win10"
EOF

	run_protontricks --no-bwrap -c "wine regedit $application_directory/WJApplication.reg" $APPID >/dev/null 2>&1
	echo -e "\e[33m\nDone..\e[0m" >>$LOGFILE 2>&1

	# Remove additional WebView Application registry entry
	echo -e "\e[33m\nRemoving additional WebView Application enrry..\e[0m" | tee -a $LOGFILE
cat <<EOF >$application_directory/DelWebViewApp.reg
Windows Registry Editor Version 5.00

[-HKEY_CURRENT_USER\Software\Wine\AppDefaults\msedgewebview2.exe]
EOF

    run_protontricks --no-bwrap -c "wine regedit $application_directory/DelWebViewApp.reg" $APPID >/dev/null 2>&1
    echo -e "\e[33m\nDone..\e[0m">>$LOGFILE 2>&1

}

#################################
# Detect and Link Steam Library #
#################################

detect_link_steam_library() {
    # Possible Steam library locations
    steam_library_locations=(
        "$HOME/.local/share/Steam"
        "$HOME/Library/Application Support/Steam"
        "/opt/steam"
        "/usr/share/Steam"
        "/usr/local/share/Steam"
    )

    # Function to check if a directory is a Steam library
    is_steam_library() {
        local location="$1"

        if [[ -d "$location" ]]; then
            if find "$location/steamapps" -type f -name "libraryfolders.vdf" -print | grep -q "$location/steamapps/libraryfolders.vdf"; then
                return 0
            fi
        fi

        return 1
    }

    echo -e "\e[33m\nDiscovering Steam libraries..\e[0m"

    # Find the first valid Steam library location
    for location in "${steam_library_locations[@]}"; do
        if is_steam_library "$location"; then
            read -p "Found Steam install at '$location' Is this path correct for your Steam install? (y/n): " -r choice
            if [[ "$choice" =~ ^[Yy]$ ]]; then
                chosen_library="$location"
                break
            fi
        fi
    done

    # If no library was found or the user declined, ask for a custom path
    if [[ -z "$chosen_library" ]]; then
        read -e -p "Enter the path to your main Steam directory: " steam_library_path
        while true; do
            if [[ ! -d "$steam_library_path" ]]; then
                echo -e "\e[31m\nInvalid path.\e[0m Please enter a valid directory." | tee -a $LOGFILE
            elif ! is_steam_library "$steam_library_path"; then
                echo -e "\e[31m\nThe specified path does not appear to be a Steam directory. Please check the path and try again. Do not enter the path for a secondary Steam Library, only the path for your actual Steam install.\e[0m" | tee -a $LOGFILE
            else
                read -p "Confirm using '$steam_library_path' as the Steam directory path? (y/n): " -r choice
                if [[ "$choice" =~ ^[Yy]$ ]]; then
                    chosen_library="$steam_library_path"
                    break
                fi
            fi
            read -e -p "Enter the path to your Steam library: " steam_library_path
        done
    fi

    # If a valid library was found, print its location and create the symlink
    if [[ -n "$chosen_library" ]]; then
        echo "Steam library found at: $chosen_library" >>$LOGFILE 2>&1
        configure_steam_libraries
    else
        echo -e "\e[31m\nSteam library not found. Please check the installation.\e[0m" | tee -a $LOGFILE
    fi

}

configure_steam_libraries() {

    echo -e "\e[33m\nConfiguring Steam libraries..\e[0m"

# Make directories

steam_config_directory="$chosen_library/steamapps/compatdata/$APPID/drive_c/Program Files (x86)/Steam/config"
echo -e "Creating directory $steam_config_directory" >>$LOGFILE 2>&1
mkdir -p "$steam_config_directory"

# copy real libraryfolders.vdf to config directory
echo -e "Copying libraryfolders.vdf to config directory" >>$LOGFILE 2>&1
cp  "$chosen_library/config/libraryfolders.vdf" "$steam_config_directory/."

# Edit this new libraryfolders.vdf file to convert linux path to Z:\ path with double backslashes

#sed -E 's|("path"[[:space:]]+)"(/)|\1"Z:\\\\|; s|/|\\\\|g' "$steam_config_directory/libraryfolders.vdf" > "$steam_config_directory/libraryfolders2.vdf"
#cp "$steam_config_directory/libraryfolders2.vdf" "$steam_config_directory/libraryfolders.vdf"
#rm "$steam_config_directory/libraryfolders2.vdf"

}

##########################################
# Create dotnet_bundle_extract directory #
##########################################

create_dotnet_cache_dir() {
  local user_name=$(whoami)
  local cache_dir="$application_directory/home/$user_name/.cache/dotnet_bundle_extract"

  mkdir -p "$cache_dir"
}

##########################
# Cleanup Wine Processes #
##########################

cleanup_wine-procs() {

while true; do
  pids_delweb=$(ps aux | grep "DelWebViewApp" | grep -v grep | awk '{print $2}')
  pids_wjapl=$(ps aux | grep "WJApplication" | grep -v grep | awk '{print $2}')

  if [ -z "$pids_delweb" ] && [ -z "$pids_wjapl" ]; then
    echo "No processes found."
  else
    all_pids=$(echo "$pids_delweb" "$pids_wjapl" | tr ' ' '\n')
    kill -9 $(echo "$all_pids")  >>$LOGFILE 2>&1
  fi

  sleep 5 # Check every 5 seconds
done

}

#####################
# Exit more cleanly #
#####################

cleaner_exit() {

	# Clean up wine and winetricks processes
	wineserver -k
	exit 1

}

####################
# END OF FUNCTIONS #
####################

#######################
# Note Script Version #
#######################

echo -e "Script Version $script_ver" >>$LOGFILE 2>&1

######################
# Note Date and Time #
######################

echo -e "Script started at: $(date +'%Y-%m-%d %H:%M:%S')" >>$LOGFILE 2>&1

#############################
# Detect if running on deck #
#############################

detect_steamdeck

###########################################
# Detect Protontricks (flatpak or native) #
###########################################

detect_protontricks

###############################
# Detect Protontricks Version #
###############################

protontricks_version

###########################
# Get Wabbajack Directory #
###########################

get_wabbajack_path

###########################
# Set APPID and run steps #
###########################

set_appid

##########################################
# Download and install WebView Installer #
##########################################

webview_installer

####################
# Configure Prefix #
####################

configure_prefix

#################################
# Detect and Link Steam Library #
#################################

detect_link_steam_library

##########################################
# Create dotnet_bundle_extract directory #
##########################################

create_dotnet_cache_dir

##########################
# Cleanup Wine Processes #
##########################

cleanup_wine-procs

########
# Exit #
########

cleanup_wine-procs

echo -e "\e[32m\nSet up complete.\e[0m"

cleaner_exit
