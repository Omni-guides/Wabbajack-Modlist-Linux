#!/bin/bash
#
##############################################################################
#                                                                            #
# Attempt to automate as many of the steps for modlists on Linux as possible #
#                                                                            #
#                       Alpha v0.33 - Omni 20/03/2024                        #
#                                                                            #
##############################################################################

# ~-= Proton Prefix Automated Tasks =-~
# =====================================
# - v0->0.04 Initial testing and theory
# - v0.05 - Detect Modlists and present a choice
# - v0.06 - Detect if running on deck
# - v0.06 - Check if Protontricks is installed (flatpak or 'which')
# - v0.07 - Set protontricks permissions on $modlist_dir
# - v0.08 - Enable Visibility of (.)dot files
# - v0.09 - Install Wine Components
# - v0.09 - Install VCRedist 2022

# ~-= Modlist Directory Automated Tasks =-~
# =========================================
# - v0.10 - Detect Modlist Directory
# - v0.11 - Detect MO2 version
# - v0.11 - Blank or set MO2 Downloads Directory
# - v0.13 - Chown/Chmod Modlist Directory
# - v0.13 - Overwrite MO2 2.5 with MO2 2.4.4
# - v0.14 - replace path to Managed Game in MO2 (Game Root/Stock Game)
# - v0.15 - Edit custom Executables if possible (Game Root/Stock Game)
# - v0.16 - Edit Managed Game path and Custom Executables for Vanilla Game Directory
# - v0.17 - Detect if game is Skyrim or Fallout or ask
# - v0.17 - Detect Steam Library Path or ask
# - v0.17 - Set Resolution (skyrimprefs.ini, Fallout4Prefs.ini and SSEDisplayTweaks.ini)
# - v0.18 - Handle & test SDCard location (Deck Only)
# - v0.19 - Add Check for Proton 9 to skip MO2 2.5 replacement
# - v0.20 - Convert remaining steps to functions - Detect Deck, Protontricks
# - v0.21 - Check Swap Space (Deck)
# - v0.21 - Add colouring to each user-interactive step
# - v0.21 - Require 'Enter' to be pressed after 'Y'
# - v0.21 - Fix Protontricks Install on deck
# - v0.22 - Additional colouring for clarity of user-actions.
# - v0.23 - Added steps to ensure Prefix is set to Windows 10 level, and install dotnet6 and dotnet7
# - v0.24 - Merged Log Files
# - v0.24 - Added match for Proton GE 9
# - v0.24 - Remove setting of Fullscreen and Borderless options due to some odd scaling issues with some lists.
# - v0.25 - Added handling of "Stock Folder" to enable compatibility with Modlist Fallout Anomaly
# - v0.26 - Added creation of dxvk.conf file to handle rare instances of an Assertion Failed error when running ENB.
# - v0.27 - Added handling of "Skyrim Stock" to enable compatibility with OCM
# - v0.28 - Fixed a bug with forming the required binary and workingDirectory paths when the modlist uses steamapps location
# - v0.29 - Fixed Default Library detection on Ubuntu/Debian and derivatives, at last.
# - v0.30 - Fixed a bug with the detection and listing of possible Modlist Install Directories if multiple possibilities are found.
# - v0.31 - Fixed a bug with detecting the proton version set for a modlist Steam entry. Also general tidy up of command outputs.
# - v0.32 - Complete rewrite of the detect_modlist function to better support unexpected directory paths.
# - v0.33 - Fixed bug introduced by 0.32 when detecting Modlist Directory on Steam Deck

# Set up and blank logs
LOGFILE=$HOME/omni-guide_autofix.log
LOGFILE2=$HOME/omni-guide_autofix2.log
echo "" > $HOME/omni-guide_autofix.log
echo "" > $HOME/omni-guide_autofix2.log
exec &> >(tee $LOGFILE2) 2>&1
shopt -s expand_aliases
alias protontricks='flatpak run com.github.Matoking.protontricks'

# Fancy banner thing

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
echo -e "Wabbajack Modlists running on Linux/Steam Deck. Please use at your own risk and accept that in the"
echo -e "worst case (though very unlikely), you may have to reinstall the vanilla Skyrim or Fallout game, or"
echo -e "re-copy the Modlist Install Directory from Windows. You can report back to me via GitHub or the Official"
echo -e "Wabbajack Discord if you discover an issue with this automation script. Any other feedback, positive"
echo -e "or negative, is also most welcome."

 echo -e "\nPress any key to continue..."
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

echo -ne "\nDetecting if protontricks is installed..." | tee -a $LOGFILE

if [[ $(flatpak list | grep -i protontricks) || -f /usr/bin/protontricks ]]; then
    # Protontricks is already installed or available
    echo -e " Already Istalled." | tee -a $LOGFILE
else
    echo -e "\e[31m \n** Protontricks not found. Do you wish to install it? (y/n): ** \e[0m"
    read -p " " answer
    if [[ $answer =~ ^[Yy]$ ]]; then
        if [[ $steamdeck -eq 1 ]]; then
            # Install Protontricks specifically for Deck
            flatpak install -u -y --noninteractive flathub com.github.Matoking.protontricks
        else
            read -p "Choose installation method: 1) Flatpak (preferred) 2) Native: " choice
            if [[ $choice =~ 1 ]]; then
                # Install protontricks
                flatpak install -u -y --noninteractive flathub com.github.Matoking.protontricks
            else
                # Print message and exit
                echo -e "\nSorry, there are way too many distro's to be able to automate this!" | tee -a $LOGFILE
                echo -e "\nPlease check how to install protontricks using your OS package system (yum, dnf, apt, pacman etc)" | tee -a $LOGFILE
            fi
        fi
    fi
fi

if [[ $steamdeck = 1 ]]; then
    echo -e "\e[31m \nChecking for SDCard and setting permissions appropriately (may require sudo password)..\e[0m"  | tee -a $LOGFILE
    # Set protontricks SDCard permissions early to suppress warning
    sdcard_path=`df -h | grep "/run/media" | awk {'print $NF'}`
    echo $sdcard_path >>$LOGFILE 2>&1
    flatpak override --user --filesystem=$sdcard_path com.github.Matoking.protontricks
    echo -e " Done."  | tee -a $LOGFILE
fi

}


#######################################
# Detect Skyrim or Fallout 4 Function #
#######################################

detect_game() {
    # Try to decide if Skyrim or Fallout
    if [[ $choice == *"Skyrim"* ]]; then
        gamevar="Skyrim Special Edition"
        which_game="${gamevar%% *}"
        echo "Game variable set to $which_game." >>$LOGFILE 2>&1
    elif [[ $choice == *"Fallout"* ]]; then
        gamevar="Fallout 4"
        which_game="${gamevar%% *}"
        echo "Game variable set to $which_game." >>$LOGFILE 2>&1
    else
        PS3="Please select a game (enter the number): "
        options=("Skyrim" "Fallout")

        select opt in "${options[@]}"; do
            case $opt in
                "Skyrim")
                    gamevar="Skyrim Special Edition"
                    which_game="${gamevar%% *}"
                    echo "Game variable set to $which_game." >>$LOGFILE 2>&1
                    break
                    ;;
                "Fallout")
                    gamevar="Fallout 4"
                    which_game="${gamevar%% *}"
                    echo "Game variable set to $which_game." >>$LOGFILE 2>&1
                    break
                    ;;
                *) echo "Invalid option";;
            esac
        done
    fi

    echo "Game variable: $gamevar" >>$LOGFILE 2>&1
}

###################################
# Try to detect the Steam Library #
###################################

detect_steam_library() {
    # Check the default location
    steam_library=
    library_default="$HOME/.local/share/Steam/steamapps/common"
    sdcard_library_default="/run/media/mmcblk0p1/SteamLibrary/steamapps/common"
    ubuntu_library_default="$HOME/.steam/steam/steamapps/common"

    if [ -d "$library_default" ]; then
        echo "Directory $library_default exists. Checking for Skyrim/Fallout." >>$LOGFILE 2>&1

        # Check for subdirectories
        if [ -d "$library_default/$gamevar" ]; then
            echo "Subdirectory '$gamevar' found in Default Library." >>$LOGFILE 2>&1
            steam_library="$library_default/$gamevar"
            steam_library_default=1
        else
            echo "Subdirectory '$gamevar' not found in .local default location." >>$LOGFILE 2>&1
        fi
    elif [ -d "$ubuntu_library_default" ]; then
        echo "Directory $ubuntu_library_default exists. Checking for Skyrim/Fallout." >>$LOGFILE 2>&1

        # Check for subdirectories
        if [ -d "$ubuntu_library_default/$gamevar" ]; then
            echo "Subdirectory '$gamevar' found in Default Ubuntu Library." >>$LOGFILE 2>&1
            steam_library="$ubuntu_library_default/$gamevar"
            steam_library_default=1
        else
            echo "Subdirectory '$gamevar' not found in default Ubuntu location." >>$LOGFILE 2>&1
        fi
    fi

    # Check sdcard_library_default
    if [ -d "$sdcard_library_default" ]; then
        echo "Directory $sdcard_library_default exists. Checking for $gamevar." >>$LOGFILE 2>&1

        # Check for subdirectories
        if [ -d "$sdcard_library_default/$gamevar" ]; then
            echo "Subdirectory '$gamevar' found in SD Card Library Default." >>$LOGFILE 2>&1
            steam_library="$sdcard_library_default"
            basegame_sdcard=1
            steam_library_default=1
        else
            echo "Subdirectory '$gamevar' not found in SD Card default location." >>$LOGFILE 2>&1
        fi
    fi

    if [[ "$steam_library_default" -ne 1 ]]; then
    echo "Game not found in normal default locations." | tee -a $LOGFILE

    # If not found there if the user wants to attempt to detect Steam Library location automatically
    echo -e "\e[31m \n** Do you wish to attempt to locate? This can take a little time.. (y/N)** \e[0m"
    read -p " " response

    if [[ $response =~ ^[Yy]$ ]]; then

        echo -ne "\n Searching..." | tee -a $LOGFILE
        library_list=( $(find / -name libraryfolder.vdf 2>/dev/null | rev | cut -d '/' -f 2- | rev) )

        echo "Done." | tee -a $LOGFILE

        for library_entry in $library_list/common; do
        echo "Check for the game directory in $library_entry" >>$LOGFILE 2>&1
        if [ -d "$library_entry/$gamevar" ]; then
            echo "Found $gamevar in $library_entry." >>$LOGFILE 2>&1
            steam_library=$library_entry
        else
            echo "game not found there either" >>$LOGFILE 2>&1
        fi
        done
    else
        echo "Game directory $gamevar not found in any Steam Library locations." | tee -a $LOGFILE

        # Loop until a valid Steam Library path is provided
        while true; do
            # Ask the user to manually input the Steam Library path
            echo -e "\n** Enter the path to your $gamevar directory manually (e.g. /data/SteamLibrary/steamapps/common/$gamevar): **"
            read -e -r gamevar_input

            echo "Game Path Entered:" "$gamevar_input"
            steam_library_input="${gamevar_input%/*}/"
            echo "Extrapolated Steam Library Path: $steam_library_input" >>$LOGFILE 2>&1

            # Check if the game directory exists in the provided Steam Library path
            if [ -d "$steam_library_input/$gamevar" ]; then
                echo "Found $gamevar in $steam_library_input." >>$LOGFILE 2>&1
                steam_library="$steam_library_input"
                echo "Steam Library set to: $steam_library" >>$LOGFILE 2>&1
                break  # Exit the loop since a valid path is provided
            else
                echo "Game not found in $steam_library_input. Please enter a valid path to $gamevar." | tee -a $LOGFILE
            fi
        done
    fi
    fi
}

#################################
# Detect Modlist Directory Path #
#################################

detect_modlist_dir_path() {


  echo -e "Detecting Modlist Install Directory.." | tee -a $LOGFILE

  echo -e "DEBUG: Detect Modlist Directory Path" >>$LOGFILE 2>&1

  expected=$(echo "$choice" | awk '{print $3}')


  # Check if Steam Deck mode is enabled
  if [[ $steamdeck == 1 ]]; then
    local locations=(
      "$HOME/Games/$which_game/$expected"
      "/run/media/mmcblk0p1/Games/$which_game/$expected"
    )
  else
    local locations=(
      "$HOME/Games/$which_game/$expected"
      "$HOME/$expected"
    )
  fi

  # Loop through locations and check for directory
  for location in "${locations[@]}"; do
    if [[ -d "$location" ]]; then
      echo -e "\nDirectory found: $location" | tee -a $LOGFILE
      modlist_dir=$location
      modlist_ini=$modlist_dir/ModOrganizer.ini
      return 0
    fi
  done

  # Not found in any location, loop for valid user input
  while true; do
    echo -e "\e[31m\nModlist directory not found in expected location. Please enter the path manually.\e[0m" | tee -a $LOGFILE
    read -e -p "Path: " user_path

    # Check if user entered something (not just pressed Enter)
    if [[ -z "$user_path" ]]; then
      echo -e "\e[32mPlease enter a path.\e[0m" | tee -a $LOGFILE
      continue
    fi

    # Check if user entered a valid path (file or directory)
    if [[ ! -e "$user_path" ]]; then
      echo -e "\nWarning: Provided path \e[32m'$user_path'\e[0m does not exist." | tee -a $LOGFILE
      path_to_confirm=1
    else
      # Check if it's a directory (prevents using a file as directory)
      if [[ ! -d "$user_path" ]]; then
        echo -e "\nWarning: Provided path \e[32m'$user_path'\e[0m is not a directory." | tee -a $LOGFILE
        path_to_confirm=1
      else
        echo -e "\nUsing user-provided path: \e[32m$user_path\e[0m" | tee -a $LOGFILE
        path_to_confirm=1
        if [[ $path_to_confirm -eq 1 ]]; then
          # Confirmation section
          echo -e "\n\e[31mAre you sure \e[32m'$user_path'\e[31m is the correct path? (y/n):\e[0m" | tee -a $LOGFILE
          read -p " " confirm

            if [[ $confirm == "n" ]]; then
                echo -e "\nOkay, please try again." | tee -a $LOGFILE
                path_to_confirm=1
                continue
            else
                modlist_dir=$user_path
                modlist_ini=$modlist_dir/ModOrganizer.ini
                echo -e "\nModlist Install Directory set to \e[32m'$modlist_dir'\e[0m, continuing.." | tee -a $LOGFILE
            fi
        fi
         break
      fi
    fi
  done

modlist_ini=$modlist_dir/ModOrganizer.ini

echo -e "Modlist INI: $modlist_ini"

}

#####################################################
# Set protontricks permissions on Modlist Directory #
#####################################################

set_protontricks_perms() {

echo "Modlist Dir: $modlist_dir" >>$LOGFILE 2>&1

echo -e "\e[31m \nSetting Protontricks permissions (may require sudo password)... \e[0m" | tee -a $LOGFILE
sudo flatpak override com.github.Matoking.protontricks --filesystem="$modlist_dir"

}

#####################################
# Enable Visibility of (.)dot files #
#####################################

enable_dotfiles() {

APPID=`echo $choice | awk {'print $NF'} | sed 's:^.\(.*\).$:\1:'`
echo $APPID >>$LOGFILE 2>&1
echo -ne "\nEnabling visibility of (.)dot files... " | tee -a $LOGFILE

# Check if already settings
dotfiles_check=$(protontricks --no-bwrap -c 'WINEDEBUG=-all wine reg query "HKEY_CURRENT_USER\Software\Wine" /v ShowDotFiles' $APPID 2>/dev/null | grep ShowDotFiles | awk '{gsub(/\r/,""); print $NF}')

printf '%s\n' "$dotfiles_check" >>$LOGFILE 2>&1

    if [[ "$dotfiles_check" = "Y" ]]; then
        printf '%s\n' "DotFiles already enabled... skipping" | tee -a $LOGFILE
    else
    protontricks --no-bwrap -c 'WINEDEBUG=-all wine reg add "HKEY_CURRENT_USER\Software\Wine" /v ShowDotFiles /d Y' $APPID &
    echo "Done!" | tee -a $LOGFILE
    fi

}

###############################################
# Set Windows 10 version in the proton prefix #
###############################################

set_win10_prefix() {

protontricks --no-bwrap  $APPID win10 >>$LOGFILE 2>&1

}

######################################
# Install Wine Components & VCRedist #
######################################

install_wine_components() {

echo -e "\nInstalling Wine Components and VCRedist 2022... This can take some time, be patient!" | tee -a $LOGFILE

spinner=( '⠋' '⠙' '⠹' '⠸' '⠼' '⠴' '⠦' '⠧' '⠇' '⠏' )
protontricks --no-bwrap $APPID -q xact xact_x64 d3dcompiler_47 d3dx11_43 d3dcompiler_43 vcrun2022 dotnet6 dotnet7  >/dev/null 2>&1 &


pid=$!  # Store the PID of the background process

while kill -0 $pid > /dev/null 2>&1; do
  for i in "${spinner[@]}"; do
    echo -en "\r${i}\c"
    sleep 0.1
  done
done

wait $pid  # Wait for the process to finish

# Clear the spinner and move to the next line
echo -en "\r\033[K"     # Clear the spinner line

if [[ $? -ne 0 ]]; then  # Check for non-zero exit code (error)
  echo -e "\nError: Component install failed with exit code $?" | tee -a $LOGFILE
else
  echo -e "\nWine Component install completed successfully." | tee -a $LOGFILE
fi

# Double check they actually installed

# List of components to check for
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

# Get the output of the protontricks command
output="$(protontricks --no-bwrap $APPID list-installed)"

# Check if each component is present in the output
all_found=true
for component in "${components[@]}"; do
    if ! grep -q "$component" <<< "$output"; then
        echo "Component $component not found."
        all_found=false
    fi
done

# Display a summary message
if [[ $all_found == true ]]; then
    echo "All required components found." >>$LOGFILE 2>&1
else
    echo -ne "\nSome required components are missing, retrying install..." | tee -a $LOGFILE
    protontricks --no-bwrap $APPID -q xact xact_x64 d3dcompiler_47 d3dx11_43 d3dcompiler_43 vcrun2022  >/dev/null 2>&1 &
    echo "Done." | tee -a $LOGFILE
fi

}

######################
# MO2 Version Check  #
######################

mo2_version_check() {

detect_mo2_version

detect_proton_version

if [[ "$proton_ver" == *"9."* ]] || [[ "$proton_ver" == "GE-Proton9"* ]]; then

echo "Proton 9 detected... should be fine.." >>$LOGFILE 2>&1

elif [[ $mo2ver = *2.5* ]]; then
    #echo  $vernum | tee -a $LOGFILE
    echo -e "\nError: Unsupported MO2 version" | tee -a $LOGFILE
    echo "" | tee -a $LOGFILE
    # Ask the user for input
    echo "WARNING: EXPERIMENTAL FEATURE - THIS WILL OVERWRITE THE MO2 FILES IN THE MODLIST DIRECTORY" | tee -a $LOGFILE

    echo -e "\e[31m \n** Would like to attempt to replace with 2.4? (y/N) ** \e[0m"
    read -p " " response

    # Check the user's response
    if [[ $response =~ ^[Yy]$ ]]; then
        replace_mo2_function
        echo "Function called successfully!" >>$LOGFILE 2>&1
    else
        echo "Sadly, Mod Organizer 2.5 doesn't work via Proton 8. Exiting..." | tee -a $LOGFILE
        exit 1  # Exit with an error code
    fi
else
    echo -ne $vernum | tee -a $LOGFILE
fi

}

######################
# Detect MO2 Version #
######################

detect_mo2_version() {

if [[ -f "$modlist_ini" ]]; then
    echo -e "\nModOrganizer.ini found, proceeding.." >>$LOGFILE 2>&1
else
    echo -e "\nModOrganizer.ini not found! Exiting.." | tee -a $LOGFILE
    exit 1
fi

# Ensure ModOrganizer.ini can be found
echo -ne "\nDetecting MO2 Version... " | tee -a $LOGFILE

# Build regular expression for matching 2.5.[0-9]+
mo2ver=`grep version $modlist_ini`
vernum=`echo  $mo2ver | awk {'print $NF'}`

echo -e "$vernum" | tee -a $LOGFILE
}

#########################
# Detect Proton Version #
#########################

detect_proton_version() {

# Get compatdata location
compatdata_dir="${steam_library%/*common*}"

echo "Compatdata directory: $compatdata_dir/compatdata" >>$LOGFILE 2>&1

echo -ne "Detecting Proton Version:... " | tee -a $LOGFILE

proton_ver=`head -n 1 $compatdata_dir/compatdata/$APPID/config_info`

echo -e "$proton_ver" | tee -a $LOGFILE


}

################################################
# Overwrite MO2 2.5 with MO2 2.4.4 if required #
################################################

replace_mo2_function() {

# Download MO2 2.4.4
echo "Downloading supported MO2" | tee -a $LOGFILE
wget https://github.com/ModOrganizer2/modorganizer/releases/download/v2.4.4/Mod.Organizer-2.4.4.7z -q -nc --show-progress --progress=bar:force:noscroll -O $HOME/Mod.Organizer-2.4.4.7z

# Extract over the top of MO2.5
echo "Extracting MO2 v2.4.4, overwriting MO2 v2.5.x" | tee -a $LOGFILE
7z x -y $HOME/Mod.Organizer-2.4.4.7z -o$modlist_dir

# Edit the Version listed in ModOrganizer.Invalid
sed -i "/version/c\version = 2.4.4" $modlist_dir/ModOrganizer.ini
    echo "MO2 version updated in .ini"

# Delete the LOOT-Warning-Checker folder
rm -rf $modlist_dir/plugins/LOOT-Warning-Checker

}

###############################
# Confirmation before running #
###############################

confirmation_before_running() {

echo "" | tee -a $LOGFILE
echo -e "Final Checklist:" | tee -a $LOGFILE
echo -e "================" | tee -a $LOGFILE
echo -e "Modlist: $MODLIST .....\e[32m OK.\e[0m" | tee -a $LOGFILE
echo -e "Directory: $modlist_dir .....\e[32m OK.\e[0m" | tee -a $LOGFILE
echo -e "MO2 Version .....\e[32m OK.\e[0m" | tee -a $LOGFILE

}

#################################
# chown/chmod modlist directory #
#################################

chown_chmod_modlist_dir() {

echo -e "\e[31m \nChanging Ownership and Permissions of modlist directory (may require sudo password) \e[0m" | tee -a $LOGFILE

sudo chown -R deck:deck $modlist_dir ; sudo chmod -R 755 $modlist_dir

}

#######################################################################
# Backup ModOrganizer.ini and backup gamePath & create checkmark file #
#######################################################################

backup_and_checkmark() {

# Backup ModOrganizer.ini
cp $modlist_ini $modlist_ini.$(date +"%Y%m%d_%H%M%S").bak

# Backup gamePath line
grep gamePath $modlist_ini | sed '/^backupPath/! s/gamePath/backupPath/' >> $modlist_ini

# Create checkmark file
touch $modlist_dir/.tmp_omniguides_run1

}

########################################
# Blank or set MO2 Downloads Directory #
########################################

blank_downloads_dir() {

echo -ne "\nEditing download_directory.. " | tee -a $LOGFILE
sed -i "/download_directory/c\download_directory =" $modlist_ini
echo  "Done." | tee -a $LOGFILE

}

############################################
# Replace the gamePath in ModOrganizer.ini #
############################################

replace_gamepath() {

echo "Use SDCard?: $basegame_sdcard" >>$LOGFILE 2>&1
echo -ne "\nChecking if Modlist uses Game Root, Stock Game, etc, etc.." | tee -a $LOGFILE

game_path_line=$(grep '^gamePath' "$modlist_ini")
echo "Game Path Line: $game_path_line" >>$LOGFILE 2>&1

if [[ "$game_path_line" == *Stock\ Game* || "$game_path_line" == *STOCK\ GAME* || "$game_path_line" == *Stock\ Game\ Folder* || "$game_path_line" == *Stock\ Folder* || "$game_path_line" == *Skyrim\ Stock* || "$game_path_line" == *Game\ Root* ]]; then

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
    fi

    if [[ "$modlist_sdcard" -eq "1" ]]; then
    echo "Using SDCard" >>$LOGFILE 2>&1
    modlist_gamedir_sdcard="${modlist_gamedir#*mmcblk0p1}"
    sdcard_new_path="$modlist_gamedir_sdcard"
    new_string="@ByteArray(D:${sdcard_new_path//\//\\\\})"
    echo "New String: $new_string" >>$LOGFILE 2>&1
    else
    new_string="@ByteArray(Z:${modlist_gamedir//\//\\\\})"
    echo "New String: $new_string" >>$LOGFILE 2>&1
    fi

elif [[ "$game_path_line" == *steamapps* ]]; then
        echo -ne "Vanilla Game Directory required, editing Game Path.. " >>$LOGFILE 2>&1
        modlist_gamedir=$steam_library
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
file_to_modify="$modlist_dir/ModOrganizer.ini"  # Replace with the actual file path
escaped_new_string=$(printf '%s\n' "$new_string" | sed -e 's/[\/&]/\\&/g')
sed -i "/^gamePath/c\gamePath=$escaped_new_string" $file_to_modify

echo -e " Done." | tee -a $LOGFILE

}

##########################################
# Update Executables in ModOrganizer.ini #
##########################################

update_executables() {

# Take the line passed to the function
echo "Original Line: $orig_line_path" >>$LOGFILE 2>&1

skse_loc=`echo "$orig_line_path" | cut -d '=' -f 2-`
echo "SKSE Loc: $skse_loc" >>$LOGFILE 2>&1

# Drive letter
if [[ "$modlist_sdcard" -eq 1 ]]; then
    echo "Using SDCard" >>$LOGFILE 2>&1
    drive_letter=" = D:"
else
    drive_letter=" = Z:"
fi

# Find the workingDirectory number

binary_num=`echo "$orig_line_path" | cut -d '=' -f -1`
echo "Binary Num: $binary_num" >>$LOGFILE 2>&1

# Find the equvalent workingDirectory
justnum=`echo "$binary_num" | cut -d '\' -f 1`
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
        echo $modlist_dir >>$LOGFILE 2>&1
        path_middle="${modlist_dir#*mmcblk0p1}"
    else
        path_middle=$modlist_dir
    fi

    echo "Path Middle: $path_middle" >>$LOGFILE 2>&1

    path_end=`echo "${skse_loc%/*}" | sed 's/.*\/mods/\/mods/'`
    echo "Path End: $path_end" >>$LOGFILE 2>&1
    bin_path_end=`echo "$skse_loc" | sed 's/.*\/mods/\/mods/'`
    echo "Bin Path End: $bin_path_end" >>$LOGFILE 2>&1

elif grep -q -E "(Stock Game|Game Root|STOCK GAME|Stock Game Folder|Stock Folder|Skyrim Stock)" <<< "$orig_line_path"; then
    # STOCK GAME ROOT FOUND
    echo -e "Stock/Game Root Found" >>$LOGFILE 2>&1

    # Path Middle / modlist_dr
    if [[ "$modlist_sdcard" -eq "1" ]]; then
        echo "Using SDCard" >>$LOGFILE 2>&1
        path_middle="${modlist_dir#*mmcblk0p1}"
        drive_letter=" = D:"
    else
        path_middle=$modlist_dir
    fi
    echo "Path Middle: $path_middle" >>$LOGFILE 2>&1

    # Get the end of our path
    if [[ $orig_line_path =~ Stock\ Game ]]; then
    dir_type="stockgame"
    path_end=`echo "${skse_loc%/*}" | sed 's/.*\/Stock Game/\/Stock Game/'`
    echo "Path End: $path_end" >>$LOGFILE 2>&1
    bin_path_end=`echo "$skse_loc" | sed 's/.*\/Stock Game/\/Stock Game/'`
    echo "Bin Path End: $bin_path_end" >>$LOGFILE 2>&1
    elif [[ $orig_line_path =~ Game\ Root ]]; then
    dir_type="gameroot"
    path_end=`echo "${skse_loc%/*}" | sed 's/.*\/Game Root/\/Game Root/'`
    echo "Path End: $path_end" >>$LOGFILE 2>&1
    bin_path_end=`echo "$skse_loc" | sed 's/.*\/Game Root/\/Game Root/'`
    echo "Bin Path End: $bin_path_end" >>$LOGFILE 2>&1
    elif [[ $orig_line_path =~ STOCK\ GAME ]]; then
    dir_type="STOCKGAME"
    path_end=`echo "${skse_loc%/*}" | sed 's/.*\/STOCK GAME/\/STOCK GAME/'`
    echo "Path End: $path_end" >>$LOGFILE 2>&1
    bin_path_end=`echo "$skse_loc" | sed 's/.*\/STOCK GAME/\/STOCK GAME/'`
    echo "Bin Path End: $bin_path_end" >>$LOGFILE 2>&1
    elif [[ $orig_line_path =~ Stock\ Folder ]]; then
    dir_type="stockfolder"
    path_end=`echo "${skse_loc%/*}" | sed 's/.*\/Stock Folder/\/Stock Folder/'`
    echo "Path End: $path_end" >>$LOGFILE 2>&1
    bin_path_end=`echo "$skse_loc" | sed 's/.*\/Stock Folder/\/Stock Folder/'`
    echo "Bin Path End: $bin_path_end" >>$LOGFILE 2>&1
    elif [[ $orig_line_path =~ Skyrim\ Stock ]]; then
    dir_type="skyrimstock"
    path_end=`echo "${skse_loc%/*}" | sed 's/.*\/Skyrim Stock/\/Skyrim Stock/'`
    echo "Path End: $path_end" >>$LOGFILE 2>&1
    bin_path_end=`echo "$skse_loc" | sed 's/.*\/Skyrim Stock/\/Skyrim Stock/'`
    echo "Bin Path End: $bin_path_end" >>$LOGFILE 2>&1
    elif [[ $orig_line_path =~ Stock\ Game\ Folder ]]; then
    dir_type="stockgamefolder"
    path_end=`echo "$skse_loc" | sed 's/.*\/Stock Game Folder/\/Stock Game Folder/'`
    echo "Path End: $path_end" >>$LOGFILE 2>&1
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
        path_middle=${steam_library%%steamapps*}
    fi
    echo "Path Middle: $path_middle" >>$LOGFILE 2>&1
    path_end=`echo "${skse_loc%/*}" | sed 's/.*\/steamapps/\/steamapps/'`
    echo "Path End: $path_end" >>$LOGFILE 2>&1
    bin_path_end=`echo "$skse_loc" | sed 's/.*\/steamapps/\/steamapps/'`
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
    # Convert binary entries:

    sed -i "\|^${bin_path_start}|s|^.*$|${full_bin_path}|" $modlist_ini
    # Convert workingDirectory entries
    sed -i "\|^${path_start}|s|^.*$|${new_path}|" $modlist_ini
fi

}

#################################################
# Edit Custom binary and workingDirectory paths #
#################################################

edit_binary_working_paths() {

grep -E -e "skse64_loader\.exe" -e "f4se_loader\.exe" "$modlist_ini"| while IFS= read -r orig_line_path; do
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
                echo "Invalid input format. Please enter the resolution in the format 1920x1200."  | tee -a $LOGFILE
            fi
        done
    fi

    echo "Resolution set to: $set_res" | tee -a $LOGFILE
}

######################################
# Update the resolution in INI files #
######################################

update_ini_resolution() {

echo -ne "\nEditing Resolution in prefs files... " | tee -a $LOGFILE

# Find all SSEDisplayTweaks.ini files in the specified directory and its subdirectories
ini_files=$(find "$modlist_dir" -name "SSEDisplayTweaks.ini")

if [[ $gamevar == "Skyrim Special Edition" && -n "$ini_files" ]]; then
    while IFS= read -r ini_file; do
        # Use awk to replace the lines with the new values, handling spaces in paths
        awk -v res="$set_res" '/^(#?)Resolution=/ { print "Resolution=" res; next } \
                               /^(#?)Fullscreen=/ { print "Fullscreen=false"; next } \
                               /^(#?)#Fullscreen=/ { print "#Fullscreen=false"; next } \
                               /^(#?)Borderless=/ { print "Borderless=true"; next } \
                               /^(#?)#Borderless=/ { print "#Borderless=true"; next }1' "$ini_file" > $HOME/temp_file && mv $HOME/temp_file "$ini_file"

        echo "Updated $ini_file with Resolution=$set_res, Fullscreen=false, Borderless=true" >>$LOGFILE 2>&1
        #echo "Updated $ini_file with Resolution=$set_res" >>$LOGFILE 2>&1
        echo -e " Done." >>$LOGFILE 2>&1
    done <<< "$ini_files"
elif [[ $gamevar == "Fallout 4" ]]; then
    echo "Not Skyrim, skipping SSEDisplayTweaks" >>$LOGFILE 2>&1
#else
#    echo "No SSEDisplayTweaks.ini files found in $modlist_dir. Please set manually in skyrimprefs.ini using the INI Editor in MO2." | tee -a $LOGFILE
fi

##########

# Split $set_res into two variables
isize_w=$(echo "$set_res" | cut -d'x' -f1)
isize_h=$(echo "$set_res" | cut -d'x' -f2)

# Find all instances of skyrimprefs.ini or Fallout4Prefs.ini in specified directories

if [[ $gamevar == "Skyrim Special Edition" ]]; then
    ini_files=$(find "$modlist_dir/profiles" "$modlist_dir/Stock Game" "$modlist_dir/Game Root" "$modlist_dir/STOCK GAME" "$modlist_dir/Stock Game Folder" "$modlist_dir/Stock Folder" "$modlist_dir/Skyrim Stock" -iname "skyrimprefs.ini" 2>/dev/null)
elif [[ $gamevar == "Fallout 4" ]]; then
    ini_files=$(find "$modlist_dir/profiles" "$modlist_dir/Stock Game" "$modlist_dir/Game Root" "$modlist_dir/STOCK GAME" "$modlist_dir/Stock Game Folder" "$modlist_dir/Stock Folder" -iname "Fallout4Prefs.ini" 2>/dev/null)
fi

if [ -n "$ini_files" ]; then
    while IFS= read -r ini_file; do
        # Use awk to replace the lines with the new values in skyrimprefs.ini
        awk -v isize_w="$isize_w" -v isize_h="$isize_h" '/^iSize W/ { print "iSize W = " isize_w; next } \
                                                           /^iSize H/ { print "iSize H = " isize_h; next }1' "$ini_file" > $HOME/temp_file && mv $HOME/temp_file "$ini_file"

        echo "Updated $ini_file with iSize W=$isize_w, iSize H=$isize_h" >>$LOGFILE 2>&1
    done <<< "$ini_files"
else
    echo "No suitable prefs.ini files found in specified directories. Please set manually in skyrimprefs.ini or Fallout4Prefs.ini using the INI Editor in MO2." | tee -a $LOGFILE
fi

echo -e "Done." | tee -a $LOGFILE

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
    echo "File deleted: $file_to_delete" | tee -a $LOGFILE
else
    echo "File does not exist: $file_to_delete" >>$LOGFILE 2>&1
fi

}

###########################
# Check Swap Space (Deck) #
###########################

check_swap_space() {

if [ $steamdeck = 1 ]; then

swapspace=`swapon -s | grep swapfil | awk {'print $3'}`
echo "Swap Space: $swapspace" >>$LOGFILE 2>&1

    if [[ $swapspace -gt 16000000 ]]; then
    echo "Swap Space is good... continuing."
    else
    echo "Swap space too low - I *STRONGLY RECOMMEND* you run CryoUtilities and accept the recommended settings."
    fi
fi

}

##########################
# Modlist Specific Steps #
##########################

modlist_specific_steps() {

if [[ $MODLIST == *"Wildlander"* ]]; then
    echo ""
    echo -e "Running steps specific to \e[32m $MODLIST\e[0m". This can take some time, be patient! | tee -a $LOGFILE
    # Install dotnet72
    spinner=( '⠋' '⠙' '⠹' '⠸' '⠼' '⠴' '⠦' '⠧' '⠇' '⠏' )
    protontricks --no-bwrap $APPID -q dotnet472  >/dev/null 2>&1 &

    pid=$!  # Store the PID of the background process

    while kill -0 $pid > /dev/null 2>&1; do
        for i in "${spinner[@]}"; do
        echo -en "\r${i}\c"
        sleep 0.1
        done
    done

    wait $pid  # Wait for the process to finish

    # Clear the spinner and move to the next line
    echo -en "\r\033[K"     # Clear the spinner line

    if [[ $? -ne 0 ]]; then  # Check for non-zero exit code (error)
        echo -e "\nError: Component install failed with exit code $?" | tee -a $LOGFILE
    else
        echo -e "\nWine Component install completed successfully." | tee -a $LOGFILE
    fi

    # Set Resolution in the odd place Wildlander uses:

fi

}

######################################
# Create DXVK Graphics Pipeline file #
######################################

create_dxvk_file() {

echo "Use SDCard for DXVK File?: $basegame_sdcard" >>$LOGFILE 2>&1
echo -e "\nCreating dxvk.conf file - Checking if Modlist uses Game Root, Stock Game or Vanilla Game Directory.."  >>$LOGFILE 2>&1

game_path_line=$(grep '^gamePath' "$modlist_ini")
echo "Game Path Line: $game_path_line" >>$LOGFILE 2>&1

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
    echo "Using SDCard" >>$LOGFILE 2>&1
    modlist_gamedir_sdcard="${modlist_gamedir#*mmcblk0p1}"
    echo "dxvk.enableGraphicsPipelineLibrary = False" >"$modlist_gamedir_sdcard/dxvk.conf"
    fi

elif [[ "$game_path_line" == *steamapps* ]]; then
        echo -ne "Vanilla Game Directory required, editing Game Path.. " >>$LOGFILE 2>&1
        modlist_gamedir=$steam_library
        echo "dxvk.enableGraphicsPipelineLibrary = False" >"$modlist_gamedir/dxvk.conf"
        if [[ "$basegame_sdcard" -eq "1" ]]; then
        echo "Using SDCard" >>$LOGFILE 2>&1
        modlist_gamedir_sdcard="${modlist_gamedir#*mmcblk0p1}"
        echo "dxvk.enableGraphicsPipelineLibrary = False" >"$modlist_dir/$gamevar/dxvk.conf"
        fi
fi

}

####################
# END OF FUNCTIONS #
####################





#############################
# Detect if running on deck #
#############################

detect_steamdeck

###########################################
# Detect Protontricks (flatpak or native) #
###########################################

detect_protontricks

##############################################################
# List Skyrim and Fallout Modlists from Steam (protontricks) #
##############################################################

#list_modlists

IFS=$'\n' readarray -t output_array < <(protontricks -l | grep -i 'Non-Steam shortcut' | grep -i 'Skyrim\|Fallout' | cut -d ' ' -f 3- )

echo "" | tee -a $LOGFILE

echo -e "\e[33mDetected Modlists:\e[0m" | tee -a $LOGFILE

PS3=$'\e[31mPlease Select: \e[0m'  # Set prompt for select
select choice in "${output_array[@]}"; do
  MODLIST=`echo $choice | cut -d ' ' -f 3- | rev | cut -d ' ' -f 2- | rev`
  echo -e "\n$choice" | tee -a $LOGFILE
  echo -e "\nYou are about to run the automated steps on the Proton Prefix for:\e[32m $MODLIST\e[0m" | tee -a $LOGFILE
  break
done

echo -e "\e[31m \n** ARE YOU ABSOLUTELY SURE? (y/N)** \e[0m" | tee -a $LOGFILE

read -p " " response
if [[ $response =~ ^[Yy]$ ]]; then

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

#####################################################
# Set protontricks permissions on Modlist Directory #
#####################################################

set_protontricks_perms

#####################################
# Enable Visibility of (.)dot files #
#####################################

enable_dotfiles

###############################################
# Set Windows 10 version in the proton prefix #
###############################################

set_win10_prefix

######################################
# Install Wine Components & VCRedist #
######################################

install_wine_components

######################
# MO2 Version Check  #
######################

mo2_version_check

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

check_swap_space

##########################
# Modlist Specific Steps #
##########################

modlist_specific_steps

############
# Finished #
############

# Merge Log files
cat $LOGFILE2 >> $LOGFILE
rm $LOGFILE2

# Parting message
echo -e "\n\e[1mAll automated steps are now complete!\e[0m" | tee -a $LOGFILE
echo -e "\n\e[4mPlease follow any additional steps in the guide on github for disabling mods etc\e[0m]" | tee -a $LOGFILE
echo -e "\nOnce you've done that, click Play for the modlist in Steam and get playing!" | tee -a $LOGFILE
else
        echo "" | tee -a $LOGFILE

        echo "Exiting..." | tee -a $LOGFILE
exit 1

fi

exit 0
