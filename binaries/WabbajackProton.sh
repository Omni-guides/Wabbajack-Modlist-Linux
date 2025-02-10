#!/bin/bash
#
##################################################################
#                                                                #
# Attempt to automate installing Wabbajack on Linux Steam/Proton #
#                                                                #
#              Alpha v0.09 - Omni, from 19/01/25                 #
#                                                                #
##################################################################

# - v0.01 - Initial script structure.
# - v0.02 - Added functions for most features
# - v0.03 - Completed initial functions
# - v0.04 - Added handling of WebP Installer
# - v0.05 - Switched out installing WebP in favour of dll + .reg files
# - v0.06 - Tidied up some ordering of commands, plus output style differences.
# - v0.07 - Replaced troublesome win7/win10 protontricks setting with swapping out .reg files. Also much faster.
# - v0.08 - Added listing of Wabbajack Steam entries, with selection, if more than one "Wabbajack" named entry found.
# - v0.09 - Initial support for Flatpak Steam libraries

# Current Script Version (alpha)
script_ver=0.09

# Today's date
date=$(date +"%d%m%y")

# Set up and blank logs
LOGFILE=$HOME/wabbajack-via-proton-sh.log
echo "" >$LOGFILE
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
		echo -e "Native Protontricks already found at $(which protontricks)." | tee -a $LOGFILE
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
		read -e -p "Enter the path to your Wabbajack application (directory or .exe). For example /home/deck/Wabbajack: " wabbajack_input

		if [[ -z "$wabbajack_input" ]]; then
			echo "Input cannot be empty. Please try again." | tee -a $LOGFILE
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

	echo "Wabbajack path: $wabbajack_path" >>$LOGFILE 2>&1
	application_directory=$(dirname "$wabbajack_path")
	echo "Application Directory: $application_directory" >>$LOGFILE 2>&1
}

##################################################
# Detect Wabbajack entry in steam and get App ID #
##################################################

set_appid() {
    wabbajack_entries=$(run_protontricks -l | grep -i 'Non-Steam shortcut' | grep -i wabbajack)

    if [[ -z "$wabbajack_entries" ]]; then
        echo "No Wabbajack entries found. Please ensure your entry in steam contains 'Wabbajack' in some way.." | tee -a $LOGFILE
        exit 1
    fi

    IFS=$'\n' read -d '' -r -a entries_array <<< "$wabbajack_entries"

    if [[ ${#entries_array[@]} -gt 1 ]]; then
        echo "Multiple Wabbajack entries found:"

        for i in "${!entries_array[@]}"; do
            stripped_entry=$(echo "${entries_array[i]}" | sed 's/^Non-Steam shortcut: //i')
            echo "$((i + 1)). $stripped_entry"
        done

        echo "Please select the entry you want to use (1-${#entries_array[@]}):"
        read -r selection

        if ! [[ "$selection" =~ ^[0-9]+$ ]] || ((selection < 1 || selection > ${#entries_array[@]})); then
            echo "Invalid selection." | tee -a $LOGFILE
            exit 1
        fi

        selected_entry="${entries_array[$((selection - 1))]}"
    else
        selected_entry="${entries_array[0]}"
    fi

    APPID=$(echo "$selected_entry" | awk {'print $NF'} | sed 's:^.\(.*\).$:\1:')

    echo "Wabbajack App ID:" $APPID >>$LOGFILE 2>&1

    # If $APPID is empty, produce an error
    if [[ -z "$APPID" ]]; then
        echo "APPID empty, something went wrong.." | tee -a $LOGFILE
        exit 1
    fi
}

####################################
# Detect compatdata Directory Path #
####################################

detect_compatdata_path() {

	# Check common Steam library locations first
	for path in "$HOME/.local/share/Steam/steamapps/compatdata" "$HOME/.steam/steam/steamapps/compatdata" "$HOME/.var/app/com.valvesoftware.Steam/.local/share/Steam/steamapps/compatdata"; do
		if [[ -d "$path/$APPID" ]]; then
			compat_data_path="$path/$APPID"
			echo -e "compatdata Path detected: $compat_data_path" >>$LOGFILE 2>&1
			break
		fi
	done

	# If not found in common locations, use find command
	if [[ -z "$compat_data_path" ]]; then
		find / -type d -name "compatdata" 2>/dev/null | while read -r compatdata_dir; do
			if [[ -d "$compatdata_dir/$APPID" ]]; then
				compat_data_path="$compatdata_dir/$appid"
				echo -e "compatdata Path detected: $compat_data_path" >>$LOGFILE 2>&1
				break
			fi
		done
	fi

	if [[ -z "$compat_data_path" ]]; then
		echo "Directory named '$APPID' not found in any compatdata directories."
		echo -e "Please ensure you have started the Steam entry for the modlist at least once, even if it fails.."
	else
		echo "Found compatdata directory with '$APPID': $compat_data_path" >>$LOGFILE 2>&1
	fi
}

#####################################################
# Set protontricks permissions on Modlist Directory #
#####################################################

set_protontricks_perms() {

	if [ "$which_protontricks" = "flatpak" ]; then
		echo "Setting Protontricks Permissions" >>$LOGFILE 2>&1

		#echo -e "\e[31m \nSetting Protontricks permissions (may require sudo password)... \e[0m" | tee -a $LOGFILE
		echo -e "\e[33m \nSetting Protontricks permissions... \e[0m" | tee -a $LOGFILE
		#Catch System flatpak install
		#sudo flatpak override com.github.Matoking.protontricks --filesystem="$application_directory"
		#Catch User flatpak install
		flatpak override --user com.github.Matoking.protontricks --filesystem="$application_directory"

		if [[ $steamdeck = 1 ]]; then
			echo -e "\e[33m \nChecking for SDCard and setting permissions appropriately..\e[0m" | tee -a $LOGFILE
			# Set protontricks SDCard permissions early to suppress warning
			sdcard_path=$(df -h | grep "/run/media" | awk {'print $NF'})
			echo $sdcard_path >>$LOGFILE 2>&1
			flatpak override --user --filesystem=$sdcard_path com.github.Matoking.protontricks
			echo -e " Done." | tee -a $LOGFILE
		fi
	else
		echo -e "Using Native protontricks, skip setting permissions" >>$LOGFILE 2>&1
	fi

}

#####################################
# Enable Visibility of (.)dot files #
#####################################

enable_dotfiles() {

	echo $APPID >>$LOGFILE 2>&1
	echo -ne "\e[33m \nEnabling visibility of (.)dot files... \e[0m" | tee -a $LOGFILE

	# Check if already settings
	dotfiles_check=$(run_protontricks -c 'WINEDEBUG=-all wine reg query "HKEY_CURRENT_USER\Software\Wine" /v ShowDotFiles' $APPID 2>/dev/null | grep ShowDotFiles | awk '{gsub(/\r/,""); print $NF}')

	printf '%s\n' "$dotfiles_check" >>$LOGFILE 2>&1

	if [[ "$dotfiles_check" = "Y" ]]; then
		printf '%s\n' "DotFiles already enabled... skipping" | tee -a $LOGFILE
	else

        if run_protontricks -c 'WINEDEBUG=-all wine reg add "HKEY_CURRENT_USER\Software\Wine" /v ShowDotFiles /d Y /f' $APPID 2>/dev/null; then
            echo "Done!" | tee -a $LOGFILE
        else
            echo -e "\e[31mError: Failed to enable dot files visibility.\e[0m" | tee -a $LOGFILE
            exit 1 # Exit the function if the command fails
        fi
	fi

}

##############################
# Download WebView Installer #
##############################

webview_installer() {

    echo -e "\e[33m\nDownloading WebView Installer...\e[0m"

    # Check if MicrosoftEdgeWebView2RuntimeInstallerX64.exe exists and skip download if so
    if ! [ -f "$application_directory/MicrosoftEdgeWebView2RuntimeInstallerX64-WabbajackProton.exe" ]; then
        if wget https://pixeldrain.com/api/file/dvLfbRkg -O "$application_directory/MicrosoftEdgeWebView2RuntimeInstallerX64-WabbajackProton.exe" >>$LOGFILE 2>&1; then
            echo "Download completed successfully."
        else
            echo -e "\e[31mError: Failed to download WebView Installer.\e[0m"
            exit 1 # Exit the script if the download fails
        fi
    else
        echo "WebView Installer already exists, skipping download."
    fi
}

####################
# Configure Prefix #
####################

configure_prefix() {

    # set based on distro? hardware?...
    echo -e "\e[33m\nChanging the default renderer used..\e[0m" | tee -a $LOGFILE
    if run_protontricks "$APPID" settings renderer=vulkan  >>$LOGFILE 2>&1 ; then
        echo "Renderer changed to Vulkan." >>$LOGFILE 2>&1
    else
        echo -e "\e[31mError: Failed to change renderer.\e[0m" | tee -a $LOGFILE
        exit 1
    fi

	# Copy in place win10 based system.reg
    echo -e "\e[33m\nChange the default prefix version to win10..\e[0m" | tee -a $LOGFILE
    wget https://github.com/Omni-guides/Wabbajack-Modlist-Linux/raw/refs/heads/main/files/system.reg.win10 -O "$compat_data_path/pfx/system.reg" >>$LOGFILE 2>&1
	echo "Prefix version changed to win10."  >>$LOGFILE 2>&1

    # Install WebView
    echo -e "\e[33m\nInstalling Webview, this can take a while, please be patient..\e[0m" | tee -a $LOGFILE
    if run_protontricks -c "wine $application_directory/MicrosoftEdgeWebView2RuntimeInstallerX64-WabbajackProton.exe /silent /install" $APPID >>$LOGFILE 2>&1; then
        echo "WebView installed successfully." | tee -a $LOGFILE
    else
        echo -e "\e[31mError: Failed to install WebView.\e[0m" | tee -a $LOGFILE
        exit 1
    fi

    # Copy in place WebP .dll
    echo -e "\e[33m\nConfiguring WebP..\e[0m" | tee -a $LOGFILE
    if mkdir -p "$compat_data_path/pfx/drive_c/Program Files (x86)/WebP Codec"  && \
       mkdir -p "$compat_data_path/pfx/drive_c/Program Files/WebP Codec"  && \
       wget https://github.com/Omni-guides/Wabbajack-Modlist-Linux/raw/refs/heads/main/files/WebpWICCodec.dll-32 -O "$compat_data_path/pfx/drive_c/Program Files (x86)/WebP Codec/WebpWICCodec.dll"  >>$LOGFILE 2>&1 && \
       wget https://github.com/Omni-guides/Wabbajack-Modlist-Linux/raw/refs/heads/main/files/WebpWICCodec.dll-64 -O "$compat_data_path/pfx/drive_c/Program Files/WebP Codec/WebpWICCodec.dll"  >>$LOGFILE 2>&1; then
        echo "WebP configured successfully." | tee -a $LOGFILE
    else
        echo -e "\e[31mError: Failed to configure WebP.\e[0m" | tee -a $LOGFILE
        exit 1
    fi

    # Copy in place win7 based system.reg
    #echo -e "\e[33m\nChange the default prefix version to win7..\e[0m" | tee -a $LOGFILE
    #cp /home/deck/WabbajackFiles/WJProton/system.reg.win7 $compat_data_path/pfx/system.reg
    #    echo "Prefix version changed to win7." | tee -a $LOGFILE

    # Copy in system.reg and user.reg
    echo -e "\e[33m\nConfiguring Registry..\e[0m" | tee -a $LOGFILE
    if wget https://github.com/Omni-guides/Wabbajack-Modlist-Linux/raw/refs/heads/main/files/system.reg.github -O "$compat_data_path/pfx/system.reg"  >>$LOGFILE 2>&1 && \
       wget https://github.com/Omni-guides/Wabbajack-Modlist-Linux/raw/refs/heads/main/files/user.reg.github -O "$compat_data_path/pfx/user.reg" >>$LOGFILE 2>&1 ; then
        echo "Registry configured successfully." | tee -a $LOGFILE
    else
        echo -e "\e[31mError: Failed to configure registry.\e[0m" | tee -a $LOGFILE
        exit 1
    fi
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
        "$HOME/.var/app/com.valvesoftware.Steam/.local/share/Steam" # Flatpak Steam location
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
            chosen_library="$location"
            break
        fi
    done

    # If no library was found, ask for a custom path
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
        configure_steam_libraries || {
            echo -e "\e[31m\nFailed to configure Steam libraries. Exiting.\e[0m" | tee -a $LOGFILE
            exit 1
        }
    else
        echo -e "\e[31m\nSteam library not found. Please check the installation.\e[0m" | tee -a $LOGFILE
        exit 1
    fi
}

configure_steam_libraries() {
    echo -e "\e[33m\nConfiguring Steam libraries..\e[0m"

    # Make directories
    steam_config_directory="$chosen_library/steamapps/compatdata/$APPID/pfx/drive_c/Program Files (x86)/Steam/config"
    echo -e "Creating directory $steam_config_directory" >>$LOGFILE 2>&1
    mkdir -p "$steam_config_directory" || {
        echo -e "\e[31m\nFailed to create directory $steam_config_directory. Exiting.\e[0m" | tee -a $LOGFILE
        exit 1
    }

    # Copy or symlink libraryfolders.vdf to config directory
    if [[ "$chosen_library" == "$HOME/.var/app/com.valvesoftware.Steam/.local/share/Steam" ]]; then
        # For Flatpak Steam, adjust the paths accordingly
        echo -e "Symlinking libraryfolders.vdf to config directory for Flatpak" >>$LOGFILE 2>&1
        ln -s "$chosen_library/config/libraryfolders.vdf" "$steam_config_directory/libraryfolders.vdf" >>$LOGFILE 2>&1 || {
            echo -e "\e[31m\nFailed to symlink libraryfolders.vdf (Flatpak Steam).\e[0m" >>$LOGFILE 2>&1 | tee -a $LOGFILE
        }
    else
        echo -e "Symlinking libraryfolders.vdf to config directory" >>$LOGFILE 2>&1
        ln -s "$chosen_library/config/libraryfolders.vdf" "$steam_config_directory/libraryfolders.vdf" >>$LOGFILE 2>&1 || {
            echo -e "\e[31m\nFailed to symlink libraryfolders.vdf.\e[0m" >>$LOGFILE 2>&1 | tee -a $LOGFILE
        }
    fi

    mv "$chosen_library/steamapps/compatdata/$APPID/pfx/drive_c/Program Files (x86)/Steam/steamapps/libraryfolders.vdf" \
       "$chosen_library/steamapps/compatdata/$APPID/pfx/drive_c/Program Files (x86)/Steam/steamapps/libraryfolders.vdf.bak" >>$LOGFILE 2>&1 || {
        echo -e "\e[31m\nFailed to backup libraryfolders.vdf.\e[0m" >>$LOGFILE 2>&1
    }
}


##########################################
# Create dotnet_bundle_extract directory #
##########################################

create_dotnet_cache_dir() {
    local user_name=$(whoami)
    local cache_dir="$application_directory/home/$user_name/.cache/dotnet_bundle_extract"

    # Check if the directory already exists
    if [ -d "$cache_dir" ]; then
        echo "Directory already exists: $cache_dir, skipping..." >>$LOGFILE 2>&1
        return 0
    fi

    # Create the directory
    mkdir -p "$cache_dir"
    if [ $? -ne 0 ]; then
        echo "Error: Failed to create directory: $cache_dir" >&2
        exit 1
    fi

    echo "Directory successfully created: $cache_dir" >>$LOGFILE 2>&1
}


##########################
# Cleanup Wine Processes #
##########################

cleanup_wine_procs() {

	# Find and kill processes containing "WabbajackProton.exe" or "renderer"
	processes=$(pgrep -f "WabbajackProton.exe|renderer=vulkan|win7|win10|ShowDotFiles|MicrosoftEdgeWebView2RuntimeInstallerX64-WabbajackProton.exe")
	if [[ -n "$processes" ]]; then
		echo "$processes" | xargs -r kill -9
		echo "Processes killed successfully." >>$LOGFILE 2>&1
	else
		echo "No matching wine processes found." >>$LOGFILE 2>&1
	fi

}

#####################
# Exit more cleanly #
#####################

cleaner_exit() {

	if [[ "$steamdeck" != "1" ]]; then
		if [ -f /usr/binwineserver ]; then
			wineserver -k
			exit 1
		else
			exit 1
		fi
	else
		exit 1
	fi

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

#########################################
# pre-emptively clean up wine processes #
#########################################

cleanup_wine_procs

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

####################################
# Detect compatdata Directory Path #
####################################

detect_compatdata_path

#####################################################
# Set protontricks permissions on Modlist Directory #
#####################################################

set_protontricks_perms

#####################################
# Enable Visibility of (.)dot files #
#####################################

enable_dotfiles

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

cleanup_wine_procs

########
# Exit #
########

echo -e "\e[32m\nSet up complete.\e[0m"

cleaner_exit
