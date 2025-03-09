#!/bin/bash
#
##############################################################################
#                                                                            #
# Attempt to automate as many of the steps for modlists on Linux as possible #
#                                                                            #
#                       Beta v0.63 - Omni 03/03/2025                         #
#                                                                            #
##############################################################################

# Full Changelog can be found here: https://github.com/Omni-guides/Wabbajack-Modlist-Linux/blob/main/binaries/omni-guides-sh.changelog.txt

# - v0.50 - Re-enabled the protontricks workaround after discovering that SteamOS doesn't yet have access to v.1.22
# - v0.51 - Switch to Beta as this should now be feature complete - barring minor or modlist-specific additions in future.
# - v0.51 - Added some cleanup of wine and winetricks processes on script exit in case some rogue processes are left over.
# - v0.52 - Added download of seguisym.ttf font file to support Bethini
# - v0.53 - First pass at optimizing the time taken to complete the tasks. (bwrap change for protontricks commands)
# - v0.54 - Add creation of protontricks alias to ease user troubleshooting post-install
# - v0.55 - Removed check for MO2 2.5 preventing an incorrect errorfrom MO2 version check when APPID is not passed correctly - Proton9/MO2 2.5 are old enough now that the check is redundant.
# - v0.56 - Added a check to catch a rare scenario where $APPID is not set correctly - the script will now exit rather than continuing and failing in odd ways. More work may be needed on this to find out why $APPID is empty on rare occasions
# - v0.57 - Added handling for UUID-based SDCard/additional directory paths
# - v0.58 - Minor correction for exit handling if APPID isn't detected
# - v0.59 - Rewrite Modlist Directory and Steam Library detection mechanisms completely, utilising Steam's .vdf files, reducing ambiguity and user intput required.
# - v0.60 - Alter protontricks alias creation to make sure flatpak protontricks is in use
# - v0.60 - Rewrite protontricks version check to be more accurate.
# - v0.61 - Minor tidy up of protontricks output and output displayed to user.
# - v0.62 - Added initial support for Fallout New Vegas modlsits (tested with Begin Again so far).
# - v0.63 - Added handling for spaces in the modlist directory name.
# - v0.63 - Added initial attempt at handling failed protontricks wine component install, now attempts to retry..

# Current Script Version (beta)
script_ver=0.63

# Set up and blank logs
LOGFILE=$HOME/omni-guides-sh.log
LOGFILE2=$HOME/omni-guides-sh2.log
echo "" >$HOME/omni-guides-sh.log
echo "" >$HOME/omni-guides-sh2.log
exec &> >(tee $LOGFILE2) 2>&1
#set -x
#Protontricks Bug
#export PROTON_VERSION="Proton Experimental"

# Fancy banner thing

if [ -f "/usr/bin/toilet" ]; then
	toilet -t -f smmono12 -F border:metal "Omni-Guides (beta)"
else
	echo "=================================================================================================="
	echo "|  #######  ##     ## ##    ## ####          ######   ##     ## #### ########   ########  ###### |"
	echo "| ##     ## ###   ### ###   ##  ##          ##    ##  ##     ##  ##  ##     ## ##       ##    ## |"
	echo "| ##     ## #### #### ####  ##  ##          ##        ##     ##  ##  ##     ## ##       ##       |"
	echo "| ##     ## ## ### ## ## ## ##  ##  ####### ##   #### ##     ##  ##  ##     ## ######    ######  |"
	echo "| ##     ## ##     ## ##  ####  ##          ##    ##  ##     ##  ##  ##     ## ##             ## |"
	echo "| ##     ## ##     ## ##   ###  ##          ##    ##  ##     ##  ##  ##     ## ##       ##    ## |"
	echo "|  #######  ##     ## ##    ## ####          ######    #######  #### ########   ########  ###### |"
	echo "============================================================================~~--(beta)--~~========"
fi

#########
# Intro #
#########
echo ""
echo -e "This script aims to automate as much as possible of the steps required to get Wabbajack Modlists running"
echo -e "on Linux/Steam Deck. Please use at your own risk and accept that in the worst case (though very unlikely),"
echo -e "you may have to reinstall the vanilla Skyrim or Fallout game, re-run Wabbajack, or re-copy the Modlist "
echo -e "Install Directory from your Wabbajack system. You can report back to me via GitHub or the Official Wabbajack"
echo -e "Discord if you discover an issue with this automation script. Any other feedback, positive or negative,"
echo -e "is also most welcome."

echo -e "\nPress any key to continue..."
read -n 1 -s -r -p ""

#############
# Functions #
#############

##########################
# Cleanup Wine Processes #
##########################

cleanup_wine_procs() {

	# Find and kill processes containing various process names
	processes=$(pgrep -f "win7|win10|ShowDotFiles|protontricks")
	if [[ -n "$processes" ]]; then
		echo "$processes" | xargs kill -9
		echo "Processes killed successfully." >>$LOGFILE 2>&1
	else
		echo "No matching processes found." >>$LOGFILE 2>&1
	fi

	pkill -9 winetricks

}

#############
# Set APPID #
#############

set_appid() {

	echo "DEBUG: Extracting APPID from choice: '$choice'" >>$LOGFILE 2>&1
	APPID=$(echo "$choice" | awk -F'[()]' '{print $2}')
	echo "DEBUG: Extracted APPID: '$APPID'" >>$LOGFILE 2>&1

	#APPID=$(echo $choice | awk {'print $NF'} | sed 's:^.\(.*\).$:\1:')
	echo "APPID=$APPID" >>$LOGFILE 2>&1

	if [ -z "$APPID" ]; then
		echo "Error: APPID cannot be empty, exiting... Please tell Omni :("
		cleaner_exit
	fi

}

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

	# Check if protontricks exists
	if command -v protontricks >/dev/null 2>&1; then
		protontricks_path=$(command -v protontricks)

		# Check if the detected binary is actually a Flatpak wrapper
		if [[ -f "$protontricks_path" ]] && grep -q "flatpak run" "$protontricks_path"; then
			echo -e "Detected Protontricks is actually a Flatpak wrapper at $protontricks_path." >>$LOGFILE 2>&1
			which_protontricks=flatpak
		else
			echo -e "Native Protontricks found at $protontricks_path." | tee -a $LOGFILE
			which_protontricks=native
			return 0 # Exit function since we confirmed native protontricks
		fi
	else
		echo -e "Non-Flatpak Protontricks not found. Checking flatpak..." >>$LOGFILE 2>&1
		if flatpak list | grep -iq protontricks; then
			echo -e "Flatpak Protontricks is already installed." >>$LOGFILE 2>&1
			which_protontricks=flatpak
		else
			echo -e "\e[31m\n** Protontricks not found. Do you wish to install it? (y/n): **\e[0m"
			read -p " " answer
			if [[ $answer =~ ^[Yy]$ ]]; then
				if [[ $steamdeck -eq 1 ]]; then
					flatpak install -u -y --noninteractive flathub com.github.Matoking.protontricks
					which_protontricks=flatpak
				else
					read -p "Choose installation method: 1) Flatpak (preferred) 2) Native: " choice
					if [[ $choice =~ 1 ]]; then
						flatpak install -u -y --noninteractive flathub com.github.Matoking.protontricks
						which_protontricks=flatpak
					else
						echo -e "\nSorry, there are too many distros to automate this!" | tee -a $LOGFILE
						echo -e "Please check how to install Protontricks using your OS package manager (yum, dnf, apt, pacman, etc.)" | tee -a $LOGFILE
					fi
				fi
			fi
		fi
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
    protontricks_version=$(run_protontricks -V | cut -d ' ' -f 2 | sed 's/[()]//g')

    # Remove any non-numeric characters from the version number
    protontricks_version_cleaned=$(echo "$protontricks_version" | sed 's/[^0-9.]//g')

    echo "Protontricks Version Cleaned = $protontricks_version_cleaned" >> "$LOGFILE" 2>&1

    # Split the version into digits
    IFS='.' read -r first_digit second_digit third_digit <<< "$protontricks_version_cleaned"

    # Check if the second digit is defined and greater than or equal to 12
    if [[ -n "$second_digit" && "$second_digit" -lt 12 ]]; then
        echo "Your protontricks version is too old! Update to version 1.12 or newer and rerun this script. If 'flatpak run com.github.Matoking.protontricks -V' returns 'unknown', then please update via flatpak." | tee -a "$LOGFILE"
        cleaner_exit
    fi
}

#######################################
# Detect Skyrim or Fallout 4 Function #
#######################################

detect_game() {
    # Try to decide if Skyrim, Fallout, Oblivion, or Fallout New Vegas/FNV
    if [[ $choice == *"Skyrim"* ]]; then
        gamevar="Skyrim Special Edition"
        which_game="${gamevar%% *}"
        echo "Game variable set to $which_game." >>"$LOGFILE" 2>&1
    elif [[ $choice == *"Fallout 4"* ]]; then
        gamevar="Fallout 4"
        which_game="${gamevar%% *}"
        echo "Game variable set to $which_game." >>"$LOGFILE" 2>&1
    elif [[ $choice == *"Fallout New Vegas"* ]] || [[ $choice == *"FNV"* ]]; then
        gamevar="Fallout New Vegas"
        which_game="${gamevar%% *}"
        echo "Game variable set to $which_game." >>"$LOGFILE" 2>&1
    elif [[ $choice == *"Oblivion"* ]]; then
        gamevar="Oblivion"
        which_game="${gamevar%% *}"
        echo "Game variable set to $which_game." >>"$LOGFILE" 2>&1
    elif [[ $choice == *"Fallout"* ]]; then
        #handle generic fallout, if no specific fallout is selected.
        PS3="Please select a Fallout game (enter the number): "
        fallout_options=("Fallout 4" "Fallout New Vegas")
        select fallout_opt in "${fallout_options[@]}"; do
            case $fallout_opt in
            "Fallout 4")
                gamevar="Fallout 4"
                which_game="${gamevar%% *}"
                echo "Game variable set to $which_game." >>"$LOGFILE" 2>&1
                break
                ;;
            "Fallout New Vegas")
                gamevar="Fallout New Vegas"
                which_game="${gamevar%% *}"
                echo "Game variable set to $which_game." >>"$LOGFILE" 2>&1
                break
                ;;
            *) echo "Invalid option" ;;
            esac
        done
    else
        PS3="Please select a game (enter the number): "
        options=("Skyrim" "Fallout 4" "Fallout New Vegas" "Oblivion")

        select opt in "${options[@]}"; do
            case $opt in
            "Skyrim")
                gamevar="Skyrim Special Edition"
                which_game="${gamevar%% *}"
                echo "Game variable set to $which_game." >>"$LOGFILE" 2>&1
                break
                ;;
            "Fallout 4")
                gamevar="Fallout 4"
                which_game="${gamevar%% *}"
                echo "Game variable set to $which_game." >>"$LOGFILE" 2>&1
                break
                ;;
            "Fallout New Vegas")
                gamevar="Fallout New Vegas"
                which_game="${gamevar%% *}"
                echo "Game variable set to $which_game." >>"$LOGFILE" 2>&1
                break
            ;;
            "Oblivion")
                gamevar="Oblivion"
                which_game="${gamevar%% *}"
                echo "Game variable set to $which_game." >>"$LOGFILE" 2>&1
                break
                ;;
            *) echo "Invalid option" ;;
            esac
        done
    fi

    echo "Game variable: $gamevar" >>"$LOGFILE" 2>&1
}

###################################
# Try to detect the Steam Library #
###################################

detect_steam_library() {

	local libraryfolders_vdf="$HOME/.steam/steam/config/libraryfolders.vdf"

	if [[ ! -f "$libraryfolders_vdf" ]]; then
		echo "libraryfolders.vdf not found in ~/.steam/steam/config/. Please ensure Steam is installed." | tee -a "$LOGFILE"
		return 1
	fi

	local library_paths=()
	while IFS='' read -r line; do
		if [[ "$line" =~ \"path\" ]]; then
			local path=$(echo "$line" | sed 's/.*"path"\s*"\(.*\)"/\1/')
			if [[ -n "$path" ]]; then
				library_paths+=("$path/steamapps/common")
			fi
		fi
	done <"$libraryfolders_vdf"

	local found=0
	for library_path in "${library_paths[@]}"; do
		if [[ -d "$library_path/$gamevar" ]]; then
			steam_library="$library_path"
			found=1
			echo "Found '$gamevar' in $steam_library." >>$LOGFILE 2>&1
			break
		else
			echo "Checking $library_path: '$gamevar' not found." >>$LOGFILE 2>&1
		fi
	done

	if [[ "$found" -eq 0 ]]; then
		echo "Vanilla game not found in Steam library locations." | tee -a "$LOGFILE"

		while true; do
			echo -e "\n** Enter the path to your Vanilla $gamevar directory manually (e.g. /data/SteamLibrary/steamapps/common/$gamevar): **"
			read -e -r gamevar_input

			steam_library_input="${gamevar_input%/*}/"

			if [[ -d "$steam_library_input/$gamevar" ]]; then
				steam_library="$steam_library_input"
				echo "Found $gamevar in $steam_library_input." | tee -a "$LOGFILE"
				echo "Steam Library set to: $steam_library" >>$LOGFILE 2>&1
				break
			else
				echo "Game not found in $steam_library_input. Please enter a valid path to Vanilla $gamevar." | tee -a "$LOGFILE"
			fi
		done
	fi

	echo "Steam Library Location: $steam_library" >>$LOGFILE 2>&1

	if [[ "$steamdeck" -eq 1 && "$steam_library" == "/run/media"* ]]; then
		basegame_sdcard=1
	fi

}

#################################
# Detect Modlist Directory Path #
#################################

detect_modlist_dir_path() {
    echo -e "Detecting $MODLIST Install Directory.." | tee -a "$LOGFILE"
    local modlist_entries
    local selected_entry
    local modlist_ini_temp
    local modlist_grep_pattern

    # Create a grep pattern for similar matches
    modlist_grep_pattern=$(echo "$MODLIST" | sed 's/ /.*\|/g') #Replace spaces with ".*|"
    modlist_grep_pattern=".*${modlist_grep_pattern}.*"          # Add wildcards to start and end.
    echo "modlist_grep_pattern: $modlist_grep_pattern" >>"$LOGFILE" 2>&1

    # Find all entries with ModOrganizer.exe and similar $MODLIST matches
    modlist_entries=$(strings ~/.steam/steam/userdata/*/config/shortcuts.vdf | grep "ModOrganizer.exe" | grep -iE "$modlist_grep_pattern")

    echo "Modlist entries found in shortcuts.vdf: \"$modlist_entries\"" >>"$LOGFILE" 2>&1

    if [[ -z "$modlist_entries" ]]; then
        echo "No ModOrganizer.exe entries found named similar to $MODLIST in shortcuts.vdf."
        echo "Displaying all ModOrganizer.exe entries:"

        local all_modlist_entries=$(strings ~/.steam/steam/userdata/*/config/shortcuts.vdf | grep "ModOrganizer.exe")

        if [[ -z "$all_modlist_entries" ]]; then
            echo "No ModOrganizer.exe entries found in shortcuts.vdf."
            return 1 # fail out
        fi

        local entry_count_all=$(echo "$all_modlist_entries" | wc -l)
        if [[ "$entry_count_all" -eq 1 ]]; then
            local path=$(echo "$all_modlist_entries" | sed -n 's/.*\(.*ModOrganizer\.exe\).*/\1/p')
            modlist_dir=$(dirname "$path")
            modlist_dir="${modlist_dir//$'\n'/}"
            read -p "Use ModOrganizer directory: $modlist_dir? (y/n): " confirm
            if [[ "$confirm" == "y" ]]; then
                modlist_ini_temp="$modlist_dir/ModOrganizer.ini"
            else
                return 1 # user declined, fail.
            fi
        else
            local i=1
            while IFS= read -r entry; do
                local path="$entry" # Use the entry directly
                path="${path//\"/}" # Remove all double quotes
                path="${path//\'/}" # Remove all single quotes
                local dir=$(dirname "$path")
                dir="${dir//$'\n'/}" # Remove trailing newline
                # Add color to the output
                echo -e "\e[33m$i) $dir\e[0m"
                ((i++))
            done <<<"$all_modlist_entries"

            # Prompt user to select an entry
            read -p "Enter the number of the desired entry: " selected_entry

            if [[ ! "$selected_entry" =~ ^[0-9]+$ || "$selected_entry" -lt 1 || "$selected_entry" -gt "$((i - 1))" ]]; then
                echo "Invalid selection."
                return 1 # Indicate failure
            fi

            # Extract the selected entry
            local selected_line=$(echo "$all_modlist_entries" | sed -n "${selected_entry}p")
            local path="$selected_line" # Use the selected line directly
            path="${path//\"/}" # Remove all double quotes
            path="${path//\'/}" # Remove all single quotes
            modlist_dir=$(dirname "$path")
            modlist_dir="${modlist_dir//$'\n'/}" # Remove trailing newline
            modlist_ini_temp="$modlist_dir/ModOrganizer.ini"
        fi

    else
        # Matching entries found
        local entry_count=$(echo "$modlist_entries" | wc -l)
        if [[ "$entry_count" -gt 1 ]]; then
            echo "Multiple ModOrganizer.exe entries found matching $MODLIST:"
            local i=1
            while IFS= read -r entry; do
                local path="$entry" # Use the entry directly
                path="${path//\"/}" # Remove all double quotes
                path="${path//\'/}" # Remove all single quotes
                local dir=$(dirname "$path")
                dir="${dir//$'\n'/}" # Remove trailing newline
                # Add color to the output
                echo -e "\e[33m$i) $dir\e[0m"
                ((i++))
            done <<<"$modlist_entries"

            # Prompt user to select an entry
            read -p "Enter the number of the desired entry: " selected_entry

            if [[ ! "$selected_entry" =~ ^[0-9]+$ || "$selected_entry" -lt 1 || "$selected_entry" -gt "$((i - 1))" ]]; then
                echo "Invalid selection."
                return 1 # Indicate failure
            fi

            # Extract the selected entry
            local selected_line=$(echo "$modlist_entries" | sed -n "${selected_entry}p")
            local path="$selected_line" # Use the selected line directly
            path="${path//\"/}" # Remove all double quotes
            path="${path//\'/}" # Remove all single quotes
            modlist_dir=$(dirname "$path")
            modlist_dir="${modlist_dir//$'\n'/}" # Remove trailing newline
            modlist_ini_temp="$modlist_dir/ModOrganizer.ini"
        else
            # Single matching entry
            path="$modlist_entries" # Use the variable directly
            path="${path//\"/}" # Remove all double quotes
            path="${path//\'/}" # Remove all single quotes
            modlist_dir=$(dirname "$path")
            modlist_dir="${modlist_dir//$'\n'/}" # Remove trailing newline
            modlist_ini_temp="$modlist_dir/ModOrganizer.ini"
        fi
    fi

    # Check if ModOrganizer.ini exists
    if [[ -f "$modlist_ini_temp" ]]; then
        modlist_ini="$modlist_ini_temp"
        echo "Modlist directory: $modlist_dir" >>"$LOGFILE" 2>&1
        echo "Modlist INI location: $modlist_ini" >>"$LOGFILE" 2>&1
        return 0
    else
        echo "ModOrganizer.ini not found in $modlist_dir"
        return 1 # fail out
    fi
}

#####################################################
# Set protontricks permissions on Modlist Directory #
#####################################################

set_protontricks_perms() {

	if [ "$which_protontricks" = "flatpak" ]; then
		echo -ne "\nSetting Protontricks permissions... " | tee -a $LOGFILE
		#Catch User flatpak install
		flatpak override --user com.github.Matoking.protontricks --filesystem="$modlist_dir"
		echo "Done!" | tee -a $LOGFILE
		if [[ $steamdeck = 1 ]]; then
			echo -e "\e[31m \nChecking for SDCard and setting permissions appropriately..\e[0m" | tee -a $LOGFILE
			# Set protontricks SDCard permissions early to suppress warning
			sdcard_path=$(df -h | grep "/run/media" | awk {'print $NF'})
			echo $sdcard_path >>$LOGFILE 2>&1
			flatpak override --user --filesystem=$sdcard_path com.github.Matoking.protontricks
			flatpak override --user --filesystem=/run/media/mmcblk0p1 com.github.Matoking.protontricks
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

	echo "APPID=$APPID" >>$LOGFILE 2>&1
	echo -ne "\nEnabling visibility of (.)dot files... " | tee -a $LOGFILE

	# Check if already settings
	dotfiles_check=$(run_protontricks -c 'WINEDEBUG=-all wine reg query "HKEY_CURRENT_USER\Software\Wine" /v ShowDotFiles' $APPID 2>/dev/null | grep ShowDotFiles | awk '{gsub(/\r/,""); print $NF}')

	printf '%s\n' "$dotfiles_check" >>$LOGFILE 2>&1

	if [[ "$dotfiles_check" = "Y" ]]; then
		printf '%s\n' "DotFiles already enabled... skipping" | tee -a $LOGFILE
	else
		run_protontricks -c 'WINEDEBUG=-all wine reg add "HKEY_CURRENT_USER\Software\Wine" /v ShowDotFiles /d Y /f' $APPID 2>/dev/null &
		echo "Done!" | tee -a $LOGFILE
	fi

}

###############################################
# Set Windows 10 version in the proton prefix #
###############################################

set_win10_prefix() {

	run_protontricks --no-bwrap $APPID win10 >>$LOGFILE 2>&1

}

######################################
# Install Wine Components & VCRedist #
######################################

install_wine_components() {
    echo -e "\nInstalling Wine Components... This can take some time, be patient!" | tee -a "$LOGFILE"
    local protontricks_components
    local components
    local protontricks_appid="$APPID" #default to previously detected appid
    local spinner=('⠋' '⠙' '⠹' '⠸' '⠼' '⠴' '⠦' '⠧' '⠇' '⠏')
    local spinner_index=0

    if [[ "$gamevar" == "Skyrim Special Edition" ]] || [[ "$gamevar" == "Fallout 4" ]]; then
        protontricks_components=(
            "xact"
            "xact_x64"
            "d3dcompiler_47"
            "d3dx11_43"
            "d3dcompiler_43"
            "vcrun2022"
            "dotnet6"
            "dotnet7"
        )
        components=(
            "xact"
            "xact_x64"
            "d3dcompiler_47"
            "d3dx11_43"
            "d3dcompiler_43"
            "vcrun2022"
            "dotnet6"
            "dotnet7"
        )
    elif [[ "$gamevar" == "Fallout New Vegas" ]]; then
        protontricks_components=(
            "fontsmooth=rgb"
            "xact"
            "xact_x64"
            "d3dx9_43"
            "d3dx9"
            "vcrun2022"
        )
        components=(
            "fontsmooth=rgb"
            "xact"
            "xact_x64"
            "d3dx9_43"
            "d3dx9"
            "vcrun2022"
        )
        protontricks_appid="22380" #force appid to 22380 for FNV protontricks
    elif [[ "$gamevar" == "Oblivion" ]]; then
        protontricks_components=(
            "fontsmooth=rgb"
            "xact"
            "xact_x64"
            "d3dx9_43"
            "d3dx9"
            "vcrun2022"
        )
        components=(
            "fontsmooth=rgb"
            "xact"
            "xact_x64"
            "d3dx9_43"
            "d3dx9"
            "vcrun2022"
        )
    else
        echo "Unsupported game: $gamevar" | tee -a "$LOGFILE"
        return 1
    fi

    echo "Executing: run_protontricks --no-bwrap \"$protontricks_appid\" -q \"${protontricks_components[@]}\"" | tee -a "$LOGFILE"
    run_protontricks --no-bwrap "$protontricks_appid" -q "${protontricks_components[@]}" >/dev/null 2>&1 &
    pid=$!

    while kill -0 "$pid" 2>/dev/null; do
        echo -en "\rProtontricks running... ${spinner[spinner_index]}"
        spinner_index=$(( (spinner_index + 1) % ${#spinner[@]} ))
        sleep 0.2 # Adjust sleep time for smoother animation
    done
    wait "$pid"
    echo -en "\r\033[K" # Clear the spinner line

    if [[ $? -ne 0 ]]; then
        echo -e "\nError: Component install failed." | tee -a "$LOGFILE"
        return 1
    fi

    echo -e "\nWine Component install completed." | tee -a "$LOGFILE"

    # Check they installed
    output="$(run_protontricks --no-bwrap "$protontricks_appid" list-installed 2>/dev/null)"
    echo "Components Found: $output" >>"$LOGFILE" 2>&1

    all_found=true
    for component in "${components[@]}"; do
        if ! grep -q "$component" <<<"$output"; then
            echo "Component $component not found." | tee -a "$LOGFILE"
            all_found=false
        fi
    done

    if [[ $all_found == false ]]; then
        echo -e "\nError: Some required components are missing after install." | tee -a "$LOGFILE"
        return 1
    fi

    echo "All required components found." >>"$LOGFILE" 2>&1
}

######################
# Detect MO2 Version #
######################

detect_mo2_version() {
    echo "Modlist INI: $modlist_ini" >>$LOGFILE 2>&1

    if [[ -f "$modlist_ini" ]]; then
        echo -e "\nModOrganizer.ini found, proceeding.." >>$LOGFILE 2>&1
    else
        echo -e "\nModOrganizer.ini not found! Exiting.." | tee -a $LOGFILE
        cleaner_exit
    fi

    echo -ne "\nDetecting MO2 Version... " >>$LOGFILE 2>&1

    # Build regular expression for matching 2.5.[0-9]+
    mo2ver=$(grep version "$modlist_ini")
    vernum=$(echo "$mo2ver" | awk -F "=" '{print $NF}')

    echo -e "$vernum" >>$LOGFILE 2>&1
}


####################################
# Detect compatdata Directory Path #
####################################

detect_compatdata_path() {

    #local compat_data_path=""
    local appid_to_check="$APPID" #default to previously detected appid

    if [[ "$gamevar" == "Fallout New Vegas" ]]; then
        appid_to_check="22380"
    fi

    # Check common Steam library locations first
    for path in "$HOME/.local/share/Steam/steamapps/compatdata" "$HOME/.steam/steam/steamapps/compatdata"; do
        if [[ -d "$path/$appid_to_check" ]]; then
            compat_data_path="$path/$appid_to_check"
            echo -e "compatdata Path detected: $compat_data_path" >>"$LOGFILE" 2>&1
            break
        fi
    done

    # If not found in common locations, use find command
    if [[ -z "$compat_data_path" ]]; then
        find / -type d -name "compatdata" 2>/dev/null | while read -r compatdata_dir; do
            if [[ -d "$compatdata_dir/$appid_to_check" ]]; then
                compat_data_path="$compatdata_dir/$appid_to_check"
                echo -e "compatdata Path detected: $compat_data_path" >>"$LOGFILE" 2>&1
                break
            fi
        done
    fi

    if [[ -z "$compat_data_path" ]]; then
        echo "Directory named '$appid_to_check' not found in any compatdata directories."
        echo -e "Please ensure you have started the Steam entry for the modlist at least once, even if it fails.."
    else
        echo "Found compatdata directory with '$appid_to_check': $compat_data_path" >>"$LOGFILE" 2>&1
    fi
}

#########################
# Detect Proton Version #
#########################

detect_proton_version() {

	echo -e "Compatdata: $compat_data_path" >>$LOGFILE 2>&1

	echo -ne "Detecting Proton Version:... " >>$LOGFILE 2>&1

	proton_ver=$(head -n 1 "$compat_data_path/config_info")

	echo -e "$proton_ver" >>$LOGFILE 2>&1

}

###############################
# Confirmation before running #
###############################

confirmation_before_running() {

	echo "" | tee -a $LOGFILE
	echo -e "Detail Checklist:" | tee -a $LOGFILE
	echo -e "=================" | tee -a $LOGFILE
	echo -e "Modlist: $MODLIST .....\e[32m OK.\e[0m" | tee -a $LOGFILE
	echo -e "Directory: $modlist_dir .....\e[32m OK.\e[0m" | tee -a $LOGFILE
	echo -e "Proton Version: $proton_ver .....\e[32m OK.\e[0m" | tee -a $LOGFILE
	echo -e "App ID: $APPID" | tee -a $LOGFILE

}

#################################
# chown/chmod modlist directory #
#################################

chown_chmod_modlist_dir() {

    echo -e "\e[31m \nChanging Ownership and Permissions of modlist directory (may require sudo password) \e[0m" | tee -a $LOGFILE

    user=$(whoami)
    group=$(id -gn)

    echo -e "User is $user and Group is $group" >>$LOGFILE 2>&1

    sudo chown -R "$user:$group" "$modlist_dir"
    sudo chmod -R 755 "$modlist_dir"

}


#######################################################################
# Backup ModOrganizer.ini and backup gamePath & create checkmark file #
#######################################################################

backup_and_checkmark() {

    echo "Backing up ModOrganizer.ini: $modlist_ini" >>$LOGFILE 2>&1

    # Backup ModOrganizer.ini
    cp "$modlist_ini" "$modlist_ini.$(date +"%Y%m%d_%H%M%S").bak"

    # Backup gamePath line
    grep gamePath "$modlist_ini" | sed '/^backupPath/! s/gamePath/backupPath/' >> "$modlist_ini"

    # Create checkmark file
    touch "$modlist_dir/.tmp_omniguides_run1"

}

########################################
# Blank or set MO2 Downloads Directory #
########################################

blank_downloads_dir() {

    echo -ne "\nEditing download_directory.. " | tee -a $LOGFILE
    sed -i "/download_directory/c\download_directory =" "$modlist_ini"
    echo "Done." | tee -a $LOGFILE

}

############################################
# Replace the gamePath in ModOrganizer.ini #
############################################

replace_gamepath() {

    echo "Using Steam Library Path: $steam_library" >>$LOGFILE 2>&1
    echo "Use SDCard?: $basegame_sdcard" >>$LOGFILE 2>&1
    echo -ne "\nChecking if Modlist uses Game Root, Stock Game, etc, etc.." | tee -a $LOGFILE
    game_path_line=$(grep '^gamePath' "$modlist_ini")
    echo "Game Path Line: $game_path_line" >>$LOGFILE 2>&1

    if [[ "$game_path_line" == *Stock\ Game* || "$game_path_line" == *STOCK\ GAME* || "$game_path_line" == *Stock\ Game\ Folder* || "$game_path_line" == *Stock\ Folder* || "$game_path_line" == *Skyrim\ Stock* || "$game_path_line" == *Game\ Root* || $game_path_line == *root\\\\Skyrim\ Special\ Edition* ]]; then

        # Stock Game, Game Root or equivalent directory found
        echo -ne "\nFound Game Root/Stock Game or equivalent directory, editing Game Path.. " >>$LOGFILE 2>&1

        # Get the end of our path
        if [[ $game_path_line =~ Stock\ Game\ Folder ]]; then
            modlist_gamedir="$modlist_dir/Stock Game Folder"
            echo "Modlist Gamedir: $modlist_gamedir" >>$LOGFILE 2>&1
        elif [[ $game_path_line =~ Stock\ Folder ]]; then
            modlist_gamedir="$modlist_dir/Stock Folder"
        elif [[ $game_path_line =~ Skyrim\ Stock ]]; then
            modlist_gamedir="$modlist_dir/Skyrim Stock"
            echo "Modlist Gamedir: $modlist_gamedir" >>$LOGFILE 2>&1
        elif [[ $game_path_line =~ Game\ Root ]]; then
            modlist_gamedir="$modlist_dir/Game Root"
            echo "Modlist Gamedir: $modlist_gamedir" >>$LOGFILE 2>&1
        elif [[ $game_path_line =~ STOCK\ GAME ]]; then
            modlist_gamedir="$modlist_dir/STOCK GAME"
            echo "Modlist Gamedir: $modlist_gamedir" >>$LOGFILE 2>&1
        elif [[ $game_path_line =~ Stock\ Game ]]; then
            modlist_gamedir="$modlist_dir/Stock Game"
            echo "Modlist Gamedir: $modlist_gamedir" >>$LOGFILE 2>&1
        elif [[ $game_path_line =~ root\\\\Skyrim\ Special\ Edition ]]; then
            modlist_gamedir="$modlist_dir/root/Skyrim Special Edition"
            echo "Modlist Gamedir: $modlist_gamedir" >>$LOGFILE 2>&1
        fi

        if [[ "$modlist_sdcard" -eq "1" ]]; then
            echo "Using SDCard" >>$LOGFILE 2>&1
            modlist_gamedir_sdcard="${modlist_gamedir#*mmcblk0p1}"
            sdcard_new_path="$modlist_gamedir_sdcard"

            # Strip /run/media/deck/UUID if present
            if [[ "$sdcard_new_path" == /run/media/deck/* ]]; then
                sdcard_new_path="/${sdcard_new_path#*/run/media/deck/*/*}"
                echo "SD Card Path after stripping: $sdcard_new_path" >>$LOGFILE 2>&1
            fi

            new_string="@ByteArray(D:${sdcard_new_path//\//\\\\})"
            echo "New String: $new_string" >>$LOGFILE 2>&1
        else
            new_string="@ByteArray(Z:${modlist_gamedir//\//\\\\})"
            echo "New String: $new_string" >>$LOGFILE 2>&1
        fi

    elif [[ "$game_path_line" == *steamapps* ]]; then
        echo -ne "Vanilla Game Directory required, editing Game Path.. " >>$LOGFILE 2>&1
        modlist_gamedir="$steam_library/$gamevar"
        echo "Modlist Gamedir: $modlist_gamedir" >>$LOGFILE 2>&1
        if [[ "$basegame_sdcard" -eq "1" ]]; then
            echo "Using SDCard" >>$LOGFILE 2>&1
            modlist_gamedir_sdcard="${modlist_gamedir#*mmcblk0p1}"
            sdcard_new_path="$modlist_gamedir_sdcard/$gamevar"
            new_string="@ByteArray(D:${sdcard_new_path//\//\\\\})"
            echo "New String: $new_string" >>$LOGFILE 2>&1
        else
            new_string="@ByteArray(Z:${modlist_gamedir//\//\\\\})"
            echo "New String: $new_string" >>$LOGFILE 2>&1
        fi
    else
        echo "Neither Game Root, Stock Game or Vanilla Game directory found, Please launch MO and set path manually.." | tee -a $LOGFILE
    fi

    # replace the string in the file
    file_to_modify="$modlist_dir/ModOrganizer.ini" # Replace with the actual file path
    escaped_new_string=$(printf '%s\n' "$new_string" | sed -e 's/[\/&]/\\&/g')
    sed -i "/^gamePath/c\gamePath=$escaped_new_string" "$file_to_modify"

    echo -e " Done." | tee -a $LOGFILE

}

##########################################
# Update Executables in ModOrganizer.ini #
##########################################

update_executables() {

    # Take the line passed to the function
    echo "Original Line: $orig_line_path" >>$LOGFILE 2>&1

    skse_loc=$(echo "$orig_line_path" | cut -d '=' -f 2-)
    echo "SKSE Loc: $skse_loc" >>$LOGFILE 2>&1

    # Drive letter
    if [[ "$modlist_sdcard" -eq 1 ]]; then
        echo "Using SDCard" >>$LOGFILE 2>&1
        drive_letter=" = D:"
    else
        drive_letter=" = Z:"
    fi

    # Find the workingDirectory number

    binary_num=$(echo "$orig_line_path" | cut -d '=' -f -1)
    echo "Binary Num: $binary_num" >>$LOGFILE 2>&1

    # Find the equvalent workingDirectory
    justnum=$(echo "$binary_num" | cut -d '\' -f 1)
    bin_path_start=$(echo "$binary_num" | tr -d ' ' | sed 's/\\/\\\\/g')
    path_start=$(echo "$justnum\\workingDirectory" | sed 's/\\/\\\\/g')
    echo "Path Start: $path_start" >>$LOGFILE 2>&1
    # Decide on steam apps or Stock Game etc

    if [[ "$orig_line_path" == *"mods"* ]]; then
        # mods path type found
        echo -e "mods path Found" >>$LOGFILE 2>&1

        # Path Middle / modlist_dr
        if [[ "$modlist_sdcard" -eq 1 ]]; then
            echo "Using SDCard" >>$LOGFILE 2>&1
            drive_letter=" = D:"
            echo "$modlist_dir" >>$LOGFILE 2>&1
            path_middle="${modlist_dir#*mmcblk0p1}"
            # Strip /run/media/deck/UUID
            if [[ "$path_middle" == /run/media/*/* ]]; then
                path_middle="/${path_middle#*/run/media/*/*/*}"
                echo "Path Middle after stripping: $path_middle" >>$LOGFILE 2>&1
            fi
        else
            path_middle="$modlist_dir"
        fi

        echo "Path Middle: $path_middle" >>$LOGFILE 2>&1

        path_end=$(echo "${skse_loc%/*}" | sed 's/.*\/mods/\/mods/')
        echo "Path End: $path_end" >>$LOGFILE 2>&1
        bin_path_end=$(echo "$skse_loc" | sed 's/.*\/mods/\/mods/')
        echo "Bin Path End: $bin_path_end" >>$LOGFILE 2>&1
        elif grep -q -E "(Stock Game|Game Root|STOCK GAME|Stock Game Folder|Stock Folder|Skyrim Stock|root/Skyrim Special Edition)" <<<"$orig_line_path"; then
        # STOCK GAME ROOT FOUND
        echo -e "Stock/Game Root Found" >>$LOGFILE 2>&1

        # Path Middle / modlist_dr
        if [[ "$modlist_sdcard" -eq 1 ]]; then
            echo "Using SDCard" >>$LOGFILE 2>&1
            drive_letter=" = D:"
            echo "Modlist Dir: $modlist_dir" >>$LOGFILE 2>&1
            path_middle="${modlist_dir#*mmcblk0p1}"
            # Strip /run/media/deck/UUID
            if [[ "$path_middle" == /run/media/*/* ]]; then
                path_middle="/${path_middle#*/run/media/*/*/*}"
                echo "Path Middle after stripping: $path_middle" >>$LOGFILE 2>&1
            fi
        else
            path_middle="$modlist_dir"
        fi
        echo "Path Middle: $path_middle" >>$LOGFILE 2>&1

        # Get the end of our path
        if [[ $orig_line_path =~ Stock\ Game ]]; then
            dir_type="stockgame"
            path_end=$(echo "${skse_loc%/*}" | sed 's/.*\/Stock Game/\/Stock Game/')
            echo "Path End: $path_end" >>$LOGFILE 2>&1
            bin_path_end=$(echo "$skse_loc" | sed 's/.*\/Stock Game/\/Stock Game/')
            echo "Bin Path End: $bin_path_end" >>$LOGFILE 2>&1
        elif [[ $orig_line_path =~ Game\ Root ]]; then
            dir_type="gameroot"
            path_end=$(echo "${skse_loc%/*}" | sed 's/.*\/Game Root/\/Game Root/')
            echo "Path End: $path_end" >>$LOGFILE 2>&1
            bin_path_end=$(echo "$skse_loc" | sed 's/.*\/Game Root/\/Game Root/')
            echo "Bin Path End: $bin_path_end" >>$LOGFILE 2>&1
        elif [[ $orig_line_path =~ STOCK\ GAME ]]; then
            dir_type="STOCKGAME"
            path_end=$(echo "${skse_loc%/*}" | sed 's/.*\/STOCK GAME/\/STOCK GAME/')
            echo "Path End: $path_end" >>$LOGFILE 2>&1
            bin_path_end=$(echo "$skse_loc" | sed 's/.*\/STOCK GAME/\/STOCK GAME/')
            echo "Bin Path End: $bin_path_end" >>$LOGFILE 2>&1
        elif [[ $orig_line_path =~ Stock\ Folder ]]; then
            dir_type="stockfolder"
            path_end=$(echo "${skse_loc%/*}" | sed 's/.*\/Stock Folder/\/Stock Folder/')
            echo "Path End: $path_end" >>$LOGFILE 2>&1
            bin_path_end=$(echo "$skse_loc" | sed 's/.*\/Stock Folder/\/Stock Folder/')
            echo "Bin Path End: $bin_path_end" >>$LOGFILE 2>&1
        elif [[ $orig_line_path =~ Skyrim\ Stock ]]; then
            dir_type="skyrimstock"
            path_end=$(echo "${skse_loc%/*}" | sed 's/.*\/Skyrim Stock/\/Skyrim Stock/')
            echo "Path End: $path_end" >>$LOGFILE 2>&1
            bin_path_end=$(echo "$skse_loc" | sed 's/.*\/Skyrim Stock/\/Skyrim Stock/')
            echo "Bin Path End: $bin_path_end" >>$LOGFILE 2>&1
        elif [[ $orig_line_path =~ Stock\ Game\ Folder ]]; then
            dir_type="stockgamefolder"
            path_end=$(echo "$skse_loc" | sed 's/.*\/Stock Game Folder/\/Stock Game Folder/')
            echo "Path End: $path_end" >>$LOGFILE 2>&1
        elif [[ $orig_line_path =~ root\/Skyrim\ Special\ Edition ]]; then
            dir_type="rootskyrimse"
            path_end="/${skse_loc# }"
            echo "Path End: $path_end" >>$LOGFILE 2>&1
            bin_path_end="/${skse_loc# }"
            echo "Bin Path End: $bin_path_end" >>$LOGFILE 2>&1
        fi
        elif [[ "$orig_line_path" == *"steamapps"* ]]; then
        # STEAMAPPS FOUND
        echo -e "steamapps Found" >>$LOGFILE 2>&1

        # Path Middle / modlist_dr
        if [[ "$basegame_sdcard" -eq "1" ]]; then
            echo "Using SDCard" >>$LOGFILE 2>&1
            path_middle="${steam_library#*mmcblk0p1}"
            drive_letter=" = D:"
        else
            echo "Steamapps Steam Library Path: $steam_library"
            path_middle=${steam_library%%steamapps*}
        fi
        echo "Path Middle: $path_middle" >>$LOGFILE 2>&1
        path_end=$(echo "${skse_loc%/*}" | sed 's/.*\/steamapps/\/steamapps/')
        echo "Path End: $path_end" >>$LOGFILE 2>&1
        bin_path_end=$(echo "$skse_loc" | sed 's/.*\/steamapps/\/steamapps/')
        echo "Bin Path End: $bin_path_end" >>$LOGFILE 2>&1

    else
        echo "No matching pattern found in the path: $orig_line_path" >>$LOGFILE 2>&1
        bail_out=1
        echo $bail_out >>$LOGFILE 2>&1

    fi

    echo "Bail Out: $bail_out" >>$LOGFILE 2>&1

    if [[ $bail_out -eq 1 ]]; then
        echo "Exiting function due to bail_out" >>$LOGFILE 2>&1
        return
    else
        # Combine them all together
        full_bin_path="$bin_path_start$drive_letter$path_middle$bin_path_end"
        echo "Full Bin Path: $full_bin_path" >>$LOGFILE 2>&1
        full_path="$path_start$drive_letter$path_middle$path_end"
        echo "Full Path: $full_path" >>$LOGFILE 2>&1

        # Replace forwardslashes with double backslashes
        new_path=${full_path//\//\\\\\\\\}
        echo "New Path: $new_path" >>$LOGFILE 2>&1

        # Convert the lines in ModOrganizer.ini, if it isn't already

        sed -i "\|^${bin_path_start}|s|^.*$|${full_bin_path}|" "$modlist_ini"
        # Convert workingDirectory entries
        sed -i "\|^${path_start}|s|^.*$|${new_path}|" "$modlist_ini"
    fi

}

#################################################
# Edit Custom binary and workingDirectory paths #
#################################################

edit_binary_working_paths() {

	grep -E -e "skse64_loader\.exe" -e "f4se_loader\.exe" "$modlist_ini" | while IFS= read -r orig_line_path; do
		update_executables
	done

}

################################
# Set or Select the Resolution #
################################

select_resolution() {
	if [ "$steamdeck" -eq 1 ]; then
		set_res="1280x800"
	else
		while true; do
			echo -e "\e[31m ** Enter your desired resolution in the format 1920x1200: ** \e[0m"
			read -p " " user_res

			# Validate the input format
			if [[ "$user_res" =~ ^[0-9]+x[0-9]+$ ]]; then
				# Ask for confirmation
				echo -e "\e[31m \n** Is $user_res your desired resolution? (y/N): ** \e[0m"
				read -p " " confirm
				if [[ "$confirm" =~ ^[Yy]$ ]]; then
					set_res="$user_res"
					break
				else
					echo "Please enter the resolution again." | tee -a $LOGFILE
				fi
			else
				echo "Invalid input format. Please enter the resolution in the format 1920x1200." | tee -a $LOGFILE
			fi
		done
	fi

	echo "Resolution set to: $set_res" | tee -a $LOGFILE
}

######################################
# Update the resolution in INI files #
######################################

update_ini_resolution() {

    echo -ne "\nEditing Resolution in prefs files... " | tee -a "$LOGFILE"

    # Find all SSEDisplayTweaks.ini files in the specified directory and its subdirectories
    ini_files=$(find "$modlist_dir" -name "SSEDisplayTweaks.ini")

    if [[ "$gamevar" == "Skyrim Special Edition" && -n "$ini_files" ]]; then
        while IFS= read -r ini_file; do
            # Use awk to replace the lines with the new values, handling spaces in paths
            awk -v res="$set_res" '/^(#?)Resolution[[:space:]]*=/ { print "Resolution=" res; next } \
                                    /^(#?)Fullscreen[[:space:]]*=/ { print "Fullscreen=false"; next } \
                                    /^(#?)#Fullscreen[[:space:]]*=/ { print "#Fullscreen=false"; next } \
                                    /^(#?)Borderless[[:space:]]*=/ { print "Borderless=true"; next } \
                                    /^(#?)#Borderless[[:space:]]*=/ { print "#Borderless=true"; next }1' "$ini_file" >"$ini_file.new"

            cp "$ini_file.new" "$ini_file"
            echo "Updated $ini_file with Resolution=$set_res, Fullscreen=false, Borderless=true" >>"$LOGFILE" 2>&1
            echo -e " Done." >>"$LOGFILE" 2>&1
        done <<<"$ini_files"
    elif [[ "$gamevar" == "Fallout 4" ]]; then
        echo "Not Skyrim, skipping SSEDisplayTweaks" >>"$LOGFILE" 2>&1
    fi

    ##########

    # Split $set_res into two variables
    isize_w=$(echo "$set_res" | cut -d'x' -f1)
    isize_h=$(echo "$set_res" | cut -d'x' -f2)

    # Find all instances of skyrimprefs.ini, Fallout4Prefs.ini, falloutprefs.ini, or Oblivion.ini in specified directories

    if [[ "$gamevar" == "Skyrim Special Edition" ]]; then
        ini_files=$(find "$modlist_dir/profiles" "$modlist_dir/Stock Game" "$modlist_dir/Game Root" "$modlist_dir/STOCK GAME" "$modlist_dir/Stock Game Folder" "$modlist_dir/Stock Folder" "$modlist_dir/Skyrim Stock" -iname "skyrimprefs.ini" 2>/dev/null)
    elif [[ "$gamevar" == "Fallout 4" ]]; then
        ini_files=$(find "$modlist_dir/profiles" "$modlist_dir/Stock Game" "$modlist_dir/Game Root" "$modlist_dir/STOCK GAME" "$modlist_dir/Stock Game Folder" "$modlist_dir/Stock Folder" -iname "Fallout4Prefs.ini" 2>/dev/null)
    elif [[ "$gamevar" == "Fallout New Vegas" ]]; then
        ini_files=$(find "$modlist_dir/profiles" "$modlist_dir/Stock Game" "$modlist_dir/Game Root" "$modlist_dir/STOCK GAME" "$modlist_dir/Stock Game Folder" "$modlist_dir/Stock Folder" -iname "falloutprefs.ini" 2>/dev/null)
    elif [[ "$gamevar" == "Oblivion" ]]; then
        ini_files=$(find "$modlist_dir/profiles" "$modlist_dir/Stock Game" "$modlist_dir/Game Root" "$modlist_dir/STOCK GAME" "$modlist_dir/Stock Game Folder" "$modlist_dir/Stock Folder" -iname "Oblivion.ini" 2>/dev/null)
    fi

    if [ -n "$ini_files" ]; then
        while IFS= read -r ini_file; do
            # Use awk to replace the lines with the new values in the appropriate ini file
            if [[ "$gamevar" == "Skyrim Special Edition" ]] || [[ "$gamevar" == "Fallout 4" ]] || [[ "$gamevar" == "Fallout New Vegas" ]]; then
                awk -v isize_w="$isize_w" -v isize_h="$isize_h" '/^iSize W/ { print "iSize W = " isize_w; next } \
                                                                    /^iSize H/ { print "iSize H = " isize_h; next }1' "$ini_file" >"$HOME/temp_file" && mv "$HOME/temp_file" "$ini_file"
            elif [[ "$gamevar" == "Oblivion" ]]; then
                awk -v isize_w="$isize_w" -v isize_h="$isize_h" '/^iSize W=/ { print "iSize W=" isize_w; next } \
                                                                    /^iSize H=/ { print "iSize H=" isize_h; next }1' "$ini_file" >"$HOME/temp_file" && mv "$HOME/temp_file" "$ini_file"
            fi

            echo "Updated $ini_file with iSize W=$isize_w, iSize H=$isize_h" >>"$LOGFILE" 2>&1
        done <<<"$ini_files"
    else
        echo "No suitable prefs.ini files found in specified directories. Please set manually using the INI Editor in MO2." | tee -a "$LOGFILE"
    fi

    echo -e "Done." | tee -a "$LOGFILE"

}

###################
# Edit resolution #
###################

edit_resolution() {

    # Ask if we should set the resolution
    #
    echo -e "\nDo you wish to attempt to set the resolution? This can be changed manually later."
    echo "(Please note that if running this script on a Steam Deck, a resolution of 1280x800 will be applied)"
    echo -e "\e[31m \n** Select and set Resolution? (y/N): ** \e[0m"
    read -p " " response

    if [[ "$response" =~ ^[Yy]$ ]]; then
        echo ""
        select_resolution
        update_ini_resolution

    else
        echo "Resolution update cancelled." >>$LOGFILE 2>&1
    fi

}

##########################
# Small additional tasks #
##########################

small_additional_tasks() {

    # Delete MO2 plugins that don't work via Proton

    file_to_delete="$modlist_dir/plugins/FixGameRegKey.py"

    if [ -e "$file_to_delete" ]; then
        rm "$file_to_delete"
        echo "File deleted: $file_to_delete" >>$LOGFILE 2>&1
    else
        echo "File does not exist: $file_to_delete" >>"$LOGFILE" 2>&1
    fi

    # Download Font to support Bethini
    wget https://github.com/mrbvrz/segoe-ui-linux/raw/refs/heads/master/font/seguisym.ttf -q -nc -O "$compat_data_path/pfx/drive_c/windows/Fonts/seguisym.ttf"

}

###########################
# Check Swap Space (Deck) #
###########################

check_swap_space() {

	if [ $steamdeck = 1 ]; then

		swapspace=$(swapon -s | grep swapfil | awk {'print $3'})
		echo "Swap Space: $swapspace" >>$LOGFILE 2>&1

		if [[ $swapspace -gt 16000000 ]]; then
			echo "Swap Space is good... continuing." >>$LOGFILE 2>&1
		else
			echo "Swap space too low - I *STRONGLY RECOMMEND* you run CryoUtilities and accept the recommended settings." >>$LOGFILE 2>&1
		fi
	fi

}

##########################
# Modlist Specific Steps #
##########################

modlist_specific_steps() {

    if [[ $MODLIST == *"Wildlander"* ]]; then
        echo ""
        echo -e "Running steps specific to \e[32m$MODLIST\e[0m". This can take some time, be patient! | tee -a "$LOGFILE"
        # Install dotnet72
        spinner=('⠋' '⠙' '⠹' '⠸' '⠼' '⠴' '⠦' '⠧' '⠇' '⠏')
        run_protontricks --no-bwrap "$APPID" -q dotnet472 >/dev/null 2>&1 &

        pid=$! # Store the PID of the background process

        while kill -0 "$pid" >/dev/null 2>&1; do
            for i in "${spinner[@]}"; do
                echo -en "\r${i}\c"
                sleep 0.1
            done
        done

        wait "$pid" # Wait for the process to finish

        # Clear the spinner and move to the next line
        echo -en "\r\033[K" # Clear the spinner line

        if [[ $? -ne 0 ]]; then # Check for non-zero exit code (error)
            echo -e "\nError: Component install failed with exit code $?" | tee -a "$LOGFILE"
        else
            echo -e "\nWine Component install completed successfully." | tee -a "$LOGFILE"
        fi

        # Output list of components to check
        new_output="$(run_protontricks --no-bwrap "$APPID" list-installed 2>/dev/null)"
        echo "Components Found: $new_output" >>"$LOGFILE" 2>&1

    fi

    if [[ "$MODLIST" == *"Librum"* ]] || [[ "$MODLIST" == *"Apostasy"* ]]; then
        echo ""
        echo -e "Running steps specific to \e[32m$MODLIST\e[0m". This can take some time, be patient! | tee -a "$LOGFILE"
        # Install dotnet 4.0
        echo -ne "\nInstalling .NET 4..."
        run_protontricks --no-bwrap "$APPID" -q dotnet40 >/dev/null 2>&1
        echo -e " Done."
        # Download dotnet8
        echo -e "\nDownloading .NET 8 Runtime" | tee -a "$LOGFILE"
        wget https://download.visualstudio.microsoft.com/download/pr/77284554-b8df-4697-9a9e-4c70a8b35f29/6763c16069d1ab8fa2bc506ef0767366/dotnet-runtime-8.0.5-win-x64.exe -q -nc --show-progress --progress=bar:force:noscroll -O "$HOME/Downloads/dotnet-runtime-8.0.5-win-x64.exe"
        # Install it
        echo -ne "\nInstalling .NET 8 Runtime...."
        run_protontricks --no-bwrap -c 'WINEDEBUG=-all wine "$HOME/Downloads/dotnet-runtime-8.0.5-win-x64.exe" /Q' "$APPID" 2>/dev/null
        echo -e " Done."

        # Re-set win10
        set_win10_prefix

        # Output list of components to check
        new_output="$(run_protontricks --no-bwrap "$APPID" list-installed 2>/dev/null)"
        echo "Components Found: $new_output" >>"$LOGFILE" 2>&1
    fi

    if [[ $(echo "${MODLIST// /}" | tr '[:upper:]' '[:lower:]') == *"nordicsouls"* ]]; then
        echo ""
        echo -e "Running steps specific to \e[32m$MODLIST\e[0m". This can take some time, be patient! | tee -a "$LOGFILE"
        # Install dotnet 4.0
        echo -ne "\nInstalling .NET 4..."
        run_protontricks --no-bwrap "$APPID" -q dotnet40 >/dev/null 2>&1
        echo -e " Done."

        # Re-set win10
        set_win10_prefix

        # Output list of components to check
        new_output="$(run_protontricks --no-bwrap "$APPID" list-installed 2>/dev/null)"
        echo "Components Found: $new_output" >>"$LOGFILE" 2>&1
    fi

    if [[ $(echo "${MODLIST// /}" | tr '[:upper:]' '[:lower:]') == *"livingskyrim"* ]] || [[ $(echo "${MODLIST// /}" | tr '[:upper:]' '[:lower:]') == *"lsiv"* ]] || [[ $(echo "${MODLIST// /}" | tr '[:upper:]' '[:lower:]') == *"ls4"* ]]; then
        echo ""
        echo -e "Running steps specific to \e[32m$MODLIST\e[0m". This can take some time, be patient! | tee -a "$LOGFILE"
        # Install dotnet 4.0
        echo -ne "\nInstalling .NET 4..."
        run_protontricks --no-bwrap "$APPID" -q dotnet40 >/dev/null 2>&1
        echo -e " Done."

        # Re-set win10
        set_win10_prefix

        # Output list of components to check
        new_output="$(run_protontricks --no-bwrap "$APPID" list-installed 2>/dev/null)"
        echo "Components Found: $new_output" >>"$LOGFILE" 2>&1
    fi

    if [[ $(echo "${MODLIST// /}" | tr '[:upper:]' '[:lower:]') == *"lostlegacy"* ]]; then
        echo ""
        echo -e "Running steps specific to \e[32m$MODLIST\e[0m". This can take some time, be patient! | tee -a "$LOGFILE"
        # Install dotnet 4.0
        echo -ne "\nInstalling .NET 4..."
        run_protontricks --no-bwrap "$APPID" -q dotnet48 >/dev/null 2>&1
        echo -e " Done."

        # Re-set win10
        set_win10_prefix

        # Output list of components to check
        new_output="$(run_protontricks --no-bwrap "$APPID" list-installed 2>/dev/null)"
        echo "Components Found: $new_output" >>"$LOGFILE" 2>&1
    fi
}

######################################
# Create DXVK Graphics Pipeline file #
######################################

create_dxvk_file() {

    echo "Use SDCard for DXVK File?: $basegame_sdcard" >>"$LOGFILE" 2>&1
    echo -e "\nCreating dxvk.conf file - Checking if Modlist uses Game Root, Stock Game or Vanilla Game Directory.." >>"$LOGFILE" 2>&1

    game_path_line=$(grep '^gamePath' "$modlist_ini")
    echo "Game Path Line: $game_path_line" >>"$LOGFILE" 2>&1

    if [[ "$game_path_line" == *Stock\ Game* || "$game_path_line" == *STOCK\ GAME* || "$game_path_line" == *Stock\ Game\ Folder* || "$game_path_line" == *Stock\ Folder* || "$game_path_line" == *Skyrim\ Stock* || "$game_path_line" == *Game\ Root* ]]; then

        # Get the end of our path
        if [[ $game_path_line =~ Stock\ Game\ Folder ]]; then
            echo "dxvk.enableGraphicsPipelineLibrary = False" >"$modlist_dir/Stock Game Folder/dxvk.conf"
        elif [[ $game_path_line =~ Stock\ Folder ]]; then
            echo "dxvk.enableGraphicsPipelineLibrary = False" >"$modlist_dir/Stock Folder/dxvk.conf"
        elif [[ $game_path_line =~ Skyrim\ Stock ]]; then
            echo "dxvk.enableGraphicsPipelineLibrary = False" >"$modlist_dir/Skyrim Stock/dxvk.conf"
        elif [[ $game_path_line =~ Game\ Root ]]; then
            echo "dxvk.enableGraphicsPipelineLibrary = False" >"$modlist_dir/Game Root/dxvk.conf"
        elif [[ $game_path_line =~ STOCK\ GAME ]]; then
            echo "dxvk.enableGraphicsPipelineLibrary = False" >"$modlist_dir/STOCK GAME/dxvk.conf"
        elif [[ $game_path_line =~ Stock\ Game ]]; then
            echo "dxvk.enableGraphicsPipelineLibrary = False" >"$modlist_dir/Stock Game/dxvk.conf"
        fi

        if [[ "$modlist_sdcard" -eq "1" ]]; then
            echo "Using SDCard" >>"$LOGFILE" 2>&1
            modlist_gamedir_sdcard="${modlist_gamedir#*mmcblk0p1}"
            echo "dxvk.enableGraphicsPipelineLibrary = False" >"$modlist_gamedir/dxvk.conf"
        fi

    elif [[ "$game_path_line" == *steamapps* ]]; then
        echo -ne "Vanilla Game Directory required, editing Game Path.. " >>"$LOGFILE" 2>&1
        modlist_gamedir="$steam_library"
        echo "dxvk.enableGraphicsPipelineLibrary = False" >"$modlist_gamedir/dxvk.conf"
        if [[ "$basegame_sdcard" -eq "1" ]]; then
            echo "Using SDCard" >>"$LOGFILE" 2>&1
            modlist_gamedir_sdcard="${modlist_gamedir#*mmcblk0p1}"
            echo "dxvk.enableGraphicsPipelineLibrary = False" >"$modlist_dir/$gamevar/dxvk.conf"
        fi
    fi

}

#############################
# Create protontricks alias #
#############################

protontricks_alias() {
    if [[ "$which_protontricks" = "flatpak" ]]; then
        local protontricks_alias_exists=$(grep "^alias protontricks=" ~/.bashrc)
        local launch_alias_exists=$(grep "^alias protontricks-launch" ~/.bashrc)

        if [[ -z "$protontricks_alias_exists" ]]; then
            echo -e "\nAdding protontricks alias to ~/.bashrc"
            echo "alias protontricks='flatpak run com.github.Matoking.protontricks'" >> ~/.bashrc
            source ~/.bashrc
        else
            echo "protontricks alias already exists in ~/.bashrc" >> "$LOGFILE" 2>&1
        fi

        if [[ -z "$launch_alias_exists" ]]; then
            echo -e "\nAdding protontricks-launch alias to ~/.bashrc"
            echo "alias protontricks-launch='flatpak run --command=protontricks-launch com.github.Matoking.protontricks'" >> ~/.bashrc
            source ~/.bashrc
        else
            echo "protontricks-launch alias already exists in ~/.bashrc" >> "$LOGFILE" 2>&1
        fi
    else
        echo "Protontricks is not installed via flatpak, skipping alias creation." >> "$LOGFILE" 2>&1
    fi
}

############################
# FNV Launch Option Notice #
############################

fnv_launch_options() {
    if [[ "$gamevar" == "Fallout New Vegas" ]]; then
        #local compat_data_path=""
        #local appid_to_check="22380"

        # Check common Steam library locations first
        for path in "$HOME/.local/share/Steam/steamapps/compatdata" "$HOME/.steam/steam/steamapps/compatdata"; do
            if [[ -d "$path/$appid_to_check" ]]; then
                compat_data_path="$path/$appid_to_check"
                break
            fi
        done

        # If not found in common locations, use find command
        #if [[ -z "$compat_data_path" ]]; then
        #    find / -type d -name "compatdata" 2>/dev/null | while read -r compatdata_dir; do
        #        if [[ -d "$compatdata_dir/$appid_to_check" ]]; then
        #            compat_data_path="$compatdata_dir/$appid_to_check"
        #            break
        #        fi
        #    done
        #fi

        if [[ -n "$compat_data_path" ]]; then
            echo -e "\e[31m \n***For $MODLIST, please add the following line to the Launch Options in Steam for your '$MODLIST' entry:*** \e[0m"
            echo -e "\e[32m \nSTEAM_COMPAT_DATA_PATH=\"$compat_data_path/22380\" %command% \e[0m"
            echo -e "\e[31m \nThis is essential for the modlist to load correctly. \e[0m"
        else
            echo -e "\nCould not determine the compatdata path for Fallout New Vegas. Please manually set the correct path in the Launch Options."
        fi
    fi
}


#####################
# Exit more cleanly #
#####################

cleaner_exit() {

    # Clean up wine and winetricks processes
    cleanup_wine_procs
    # Merge Log files
    echo "Merging Log Files.." >>"$LOGFILE" 2>&1
    cat "$LOGFILE2" | grep -v -e "[⠋⠙⠹⠸⠼⠴⠦⠧⠇⠏]" >>"$LOGFILE"
    echo "Removing Logfile2.." >>"$LOGFILE" 2>&1
    rm "$LOGFILE2"

    exit 1

}

####################
# END OF FUNCTIONS #
####################

#######################
# Note Script Version #
#######################

echo -e "Script Version $script_ver" >>"$LOGFILE" 2>&1

######################
# Note Date and Time #
######################

echo -e "Script started at: $(date +'%Y-%m-%d %H:%M:%S')" >>"$LOGFILE" 2>&1

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

##########################################
# Create protontricks alias in ~/.bashrc #
##########################################

protontricks_alias

##############################################################
# List Skyrim and Fallout Modlists from Steam (protontricks) #
##############################################################

IFS=$'\n' readarray -t output_array < <(run_protontricks -l | tr -d $'\r' | grep -i 'Non-Steam shortcut' | grep -i 'Skyrim\|Fallout\|FNV\|Oblivion' | cut -d ' ' -f 3-)

#declare -p output_array # Inspect the array

if [[ ${#output_array[@]} -eq 0 ]]; then
    echo "" | tee -a "$LOGFILE"
    echo -e "\e[31mError: No modlists detected for Skyrim, Oblivion or Fallout/FNV!\e[0m"
    echo -e "\nPlease make sure your entry in Steam is something like 'Skyrim - ModlistName'"
    echo -e "or 'Fallout - ModlistName' AND that you have pressed play in Steam at least once!" | tee -a "$LOGFILE"
    cleaner_exit
fi

echo "" | tee -a "$LOGFILE"

echo -e "\e[33mDetected Modlists:\e[0m" | tee -a "$LOGFILE"

# Print numbered list with color
for i in "${!output_array[@]}"; do
    echo -e "\e[32m$((i + 1)))\e[0m ${output_array[$i]}"
done

read -p $'\e[31mPlease Select: \e[0m' choice_num

if [[ "$choice_num" =~ ^[0-9]+$ ]] && [[ "$choice_num" -ge 1 ]] && [[ "$choice_num" -le "${#output_array[@]}" ]]; then
    choice="${output_array[$((choice_num - 1))]}"
    echo -e "\nYou are about to run the automated steps on the Proton Prefix for: $choice" | tee -a "$LOGFILE"
    MODLIST=$(echo "$choice" | cut -d ' ' -f 3- | rev | cut -d ' ' -f 2- | rev)
    echo "MODLIST: $MODLIST" >>"$LOGFILE" 2>&1
else
    echo "Invalid selection."
    exit 1
fi

echo -e "\e[31m \n** ARE YOU ABSOLUTELY SURE? (y/N)** \e[0m" | tee -a "$LOGFILE"

read -p " " response
if [[ $response =~ ^[Yy]$ ]]; then

    ######################################################
    # Pre-emptively cleanup any left-over wine processes #
    ######################################################

    cleanup_wine_procs

    #############
    # Set APPID #
    #############

    set_appid

    ################################
    # Detect Game - Skyrim/Fallout #
    ################################

    detect_game

    ########################
    # Detect Steam Library #
    ########################

    detect_steam_library

    #################################
    # Detect Modlist Directory Path #
    #################################

    detect_modlist_dir_path

    #Check for a space in the path
    #if [[ "$modlist_dir" = *" "* ]]; then
    #   modlist_dir_nospace="${modlist_dir// /}"
    #   echo -e "\n\e[31mError: Space detected in the path: $modlist_dir\e[0m"
    #   echo -e "\n\e[32mSpaces in the directory name do not work well with MO2 via Proton, please rename the directory to remove the space, update the Steam Entry, and then re-run this script!\e[0m"
    #   echo -e "\n\e[33mFor example, instead of $modlist_dir, call the directory $modlist_dir_nospace.\e[0m"
    #   cleaner_exit
    #fi

    # Set modlist_sdcard if required
    if [[ $modlist_dir == "/run/media"* ]]; then
        modlist_sdcard=1
    else
        modlist_sdcard=0
    fi

    echo "Modlist Dir $modlist_dir" >>"$LOGFILE" 2>&1
    echo "Modlist INI $modlist_ini" >>"$LOGFILE" 2>&1

    #####################################################
    # Set protontricks permissions on Modlist Directory #
    #####################################################

    set_protontricks_perms

    #####################################
    # Enable Visibility of (.)dot files #
    #####################################

    enable_dotfiles

    ######################################
    # Install Wine Components & VCRedist #
    ######################################

    install_wine_components

    ####################################
    # Detect compatdata Directory Path #
    ####################################

    detect_compatdata_path

    ######################
    # MO2 Version Check #
    ######################

    detect_mo2_version

    detect_proton_version

    ###############################
    # Confirmation before running #
    ###############################

    confirmation_before_running

    #################################
    # chown/chmod modlist directory #
    #################################

    chown_chmod_modlist_dir

    #######################################################################
    # Backup ModOrganizer.ini and backup gamePath & create checkmark file #
    #######################################################################

    backup_and_checkmark

    ########################################
    # Blank or set MO2 Downloads Directory #
    ########################################

    blank_downloads_dir

    ######################################
    # Replace path to Manage Game in MO2 #
    ######################################

    replace_gamepath

    #################################################
    # Edit Custom binary and workingDirectory paths #
    #################################################

    edit_binary_working_paths

    ###################
    # Edit resolution #
    ###################

    edit_resolution

    ######################################
    # Create DXVK Graphics Pipeline file #
    ######################################

    create_dxvk_file

    ##########################
    # Small additional tasks #
    ##########################

    small_additional_tasks

    ###########################
    # Check Swap Space (Deck) #
    ###########################

    #check_swap_space

    ##########################
    # Modlist Specific Steps #
    ##########################

    modlist_specific_steps

    ############################
    # FNV Launch Option Notice #
    ############################

    fnv_launch_options

    ############
    # Finished #
    ############

    # Parting message
    echo -e "\n\e[1mAll automated steps are now complete!\e[0m" | tee -a "$LOGFILE"

    cleaner_exit
    break # Exit the loop
  elif [[ $response =~ ^[Nn]$ ]]; then
    echo "" | tee -a "$LOGFILE"
    #rest of script
    echo "Exiting..." | tee -a "$LOGFILE"
    cleaner_exit
    break # Exit the loop
  else
    echo "Invalid input. Please enter y or n." | tee -a "$LOGFILE"
  fi
done

exit 0
