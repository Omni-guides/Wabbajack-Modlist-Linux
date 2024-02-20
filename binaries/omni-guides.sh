#!/bin/bash
#
##############################################################################
#                                                                            #
# Attempt to automate as many of the steps for modlists on Linux as possible #
#                                                                            #
#                       Alpha v0.16 - Omni 20/02/2024                        #
#                                                                            #
##############################################################################


# ~-= Proton Prefix Automated Tasks =-~
# =====================================
# - DONE - Detect Modlists and present a choice
# - DONE - Detect if running on deck
# - DONE - Check if Protontricks is installed (flatpak or 'which')
# - DONE - Set protontricks permissions on $modlist_dir
# - DONE - Enable Visibility of (.)dot files
# - DONE - Install Wine Components
# - DONE - Install VCRedist 2022

# ~-= Modlist Directory Automated Tasks =-~
# =========================================
# - DONE - Detect Modlist Directory
# - DONE - Detect MO2 version
# - DONE - Blank or set MO2 Downloads Directory
# - DONE - Chown/Chmod Modlist Directory
# - DONE - Overwrite MO2 2.5 with MO2 2.4.4
# - DONE - replace path to Managed Game in MO2 (Game Root/Stock Game)
# - DONE - Edit custom Executables if possible (Game Root/Stock Game)
# - DONE - Edit Managed Game path and Custom Executables for Vanilla Game Directory
# - DONE - Detect if game is Skyrim or Fallout or ask
# - DONE - Detect Steam Library Path or ask
# - DONE - Set Resolution

# ~-= Still to try =-~
# - Automate nxmhandler popup
# - Modlist-specific fixes (e.g. Custom Skills Framework for > 1.5.97)
# - Create a "have I run before" check
# - Handle & test SDCard location (Deck Only)

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
fi

#########
# Intro #
#########

echo -e "This is an extremely experimental script, attempting to automate as much as possible of the\
 process of getting Wabbajack Modlists running on Linux/Steam Deck.\
 Please use at your own risk and accept that in the worst case, you may have to reinstall\
 The vanilla Skyrim/Fallout game, or re-copy the Modlist from Windows.\
 You can report back to me via GitHub or the Wabbajack Discord if you discover an issue\
 with this automation script. Any other feedback is also welcome.\
Phase 1 of the script deals with the Proton Prefix (e.g. $HOME/.local/share/Steam/steamapps/compatdata)\
 while Phase 2 will be handling the few changes needed in the Modlist Directory." | tee -a $LOGFILE

echo -e "Worst case if something doesn't go smoothly, you may need to recreate the Proton Prefix,\
or re-copy your Modlist Directory from Windows" | tee -a $LOGFILE

#############
# Functions #
#############

# Detect Skyrim or Fallout4

detect_game() {
    # Try to decide if Skyrim or Fallout
    if [[ $choice == *"Skyrim"* ]]; then
        gamevar="Skyrim Special Edition"
        echo "Game variable set to Skyrim."| tee -a $LOGFILE
    elif [[ $choice == *"Fallout 4"* ]]; then
        gamevar="fallout"
        echo "Game variable set to Fallout."| tee -a $LOGFILE
    else
        PS3="Please select a game (enter the number): "
        options=("Skyrim" "Fallout")

        select opt in "${options[@]}"; do
            case $opt in
                "Skyrim")
                    gamevar="Skyrim Special Edition"
                    echo "Game variable set to Skyrim."| tee -a $LOGFILE
                    break
                    ;;
                "Fallout")
                    gamevar="Fallout 4"
                    echo "Game variable set to Fallout."| tee -a $LOGFILE
                    break
                    ;;
                *) echo "Invalid option";;
            esac
        done
    fi

    echo "Game variable: $gamevar"
}

# Try to detect the Stema Library

detect_steam_library() {
# Check the default location
steam_library=
library_default="$HOME/.local/share/Steam/steamapps/common/"

if [ -d "$library_default" ]; then
    echo "Directory $library_default exists. Checking for Skyrim/Fallout." >>$LOGFILE 2>&1

    # Check for subdirectories
    if [ -d "$library_default/$gamevar" ]; then
        echo "Subdirectory 'Skyrim Special Edition' or 'Fallout 4' found in Default Library." >>$LOGFILE 2>&1
        steam_library=$library_default
        steam_library_default=1
    else
        echo "Subdirectories 'Skyrim Special Edition' and 'Fallout 4' not found in default location." >>$LOGFILE 2>&1
    fi
fi

if [[ "$steam_library_default" -ne 1 ]]; then
    echo "Directory $library_default does not exist or game not found there." | tee -a $LOGFILE

    # If not found there if the user wants to attempt to detect Steam Library location automatically
    echo -e "\e[31m \n** Do you wish to attempt to locate? This can take a little time.. (y/N)** \e[0m"
    read -n 1 -sp " " response

  if [[ $response =~ ^[Yy]$ ]]; then

    echo -ne "\n Searching..." | tee -a $LOGFILE
    library_list=( $(find / -name libraryfolder.vdf 2>/dev/null | rev | cut -d '/' -f 2- | rev) )

    echo "Done." | tee -a $LOGFILE

    for library_entry in "$library_list/common"; do
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

        echo "Game Path Entered:" "$gamevar_input" >>$LOGFILE 2>&1
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

# Overwrite MO2 2.5 with MO2 2.4.4

replace_mo2_function() {

# Download MO2 2.4.4
echo "Downloading supported MO2" | tee -a $LOGFILE
wget https://github.com/ModOrganizer2/modorganizer/releases/download/v2.4.4/Mod.Organizer-2.4.4.7z -q -nc --show-progress -O $HOME/Mod.Organizer-2.4.4.7z

# Extract over the top of MO2.5
echo "Extracting MO2 v2.4.4, overwriting MO2 v2.5.x" | tee -a $LOGFILE
7z x -y $HOME/Mod.Organizer-2.4.4.7z -o$modlist_dir  >>$LOGFILE 2>&1

# Edit the Version listed in ModOrganizer.Invalid
sed -i "/version/c\version = 2.4.4" $modlist_dir/ModOrganizer.ini
    echo "MO2 version updated in .ini"  >>$LOGFILE 2>&1

# Delete the LOOT-Warning-Checker folder
rm -rf $modlist_dir/plugins/LOOT-Warning-Checker

}

replace_gamepath() {
echo -e "\nChecking if Modlist uses Game Root, Stock Game or Vanilla Game Directory.." | tee -a $LOGFILE

game_path_line=$(grep '^gamePath' "$modlist_ini")
echo "Game Path Line: $game_path_line" >>$LOGFILE 2>&1

if [[ "$game_path_line" == *Stock\ Game* || "$game_path_line" == *STOCK\ GAME* || "$game_path_line" == *Stock\ Game\ Folder* || "$game_path_line" == *Game\ Root* ]]; then

    # Stock Game, Game Root or equivalent directory found
    echo -ne "\nFound Game Root/Stock Game or equivalent directory, editing Game Path.. " | tee -a $LOGFILE

      # Get the end of our path
    if [[ $game_path_line =~ Stock\ Game\ Folder ]]; then
    modlist_gamedir="$modlist_dir/Stock Game Folder"
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

    new_string="@ByteArray(Z:${modlist_gamedir//\//\\\\})"
    echo "New String: $new_string" >>$LOGFILE 2>&1

elif [[ "$game_path_line" == *steamapps* ]]; then
        echo -ne"Vanilla Game Directory required, editing Game Path.. "
        modlist_gamedir=$steam_library/steamapps/common/$gamevar
        echo "Modlist Gamedir: $modlist_gamedir" >>$LOGFILE 2>&1
        new_string="@ByteArray(Z:${modlist_gamedir//\//\\\\})"
        echo "New String: $new_string" >>$LOGFILE 2>&1
else
        echo "Neither Game Root, Stock Game or Vanilla Game directory found, Please launch MO and set path manually.." | tee -a $LOGFILE
fi

# replace the string in the file
file_to_modify="$modlist_dir/ModOrganizer.ini"  # Replace with the actual file path
escaped_new_string=$(printf '%s\n' "$new_string" | sed -e 's/[\/&]/\\&/g')
sed -i "/^gamePath/c\gamePath=$escaped_new_string" $file_to_modify

echo -e " Done." | tee -a $LOGFILE

}


update_executables() {

# Take the line passed to the function
echo "Original Line: $orig_line_path" >>$LOGFILE 2>&1

skse_loc=`echo "$orig_line_path" | cut -d '=' -f 2-`
echo "SKSE Loc: $skse_loc" >>$LOGFILE 2>&1

# Drive letter
drive_letter=" = Z:"

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
    path_middle=$modlist_dir
    echo "Path Middle: $path_middle" >>$LOGFILE 2>&1

    path_end=`echo "${skse_loc%/*}" | sed 's/.*\/mods/\/mods/'`
    echo "Path End: $path_end" >>$LOGFILE 2>&1
    bin_path_end=`echo "$skse_loc" | sed 's/.*\/mods/\/mods/'`
    echo "Bin Path End: $bin_path_end" >>$LOGFILE 2>&1

elif grep -q -E "(Stock Game|Game Root|STOCK GAME|Stock Game Folder)" <<< "$orig_line_path"; then
    # STOCK GAME ROOT FOUND
    echo -e "Stock/Game Root Found" >>$LOGFILE 2>&1

    # Path Middle / modlist_dr
    path_middle=$modlist_dir
    echo "Path Middle: $path_middle" >>$LOGFILE 2>&1

    # Get the end of our path
    if [[ $orig_line_path =~ Stock\ Game ]]; then
    path_end=`echo "${skse_loc%/*}" | sed 's/.*\/Stock Game/\/Stock Game/'`
    echo "Path End: $path_end" >>$LOGFILE 2>&1
    bin_path_end=`echo "$skse_loc" | sed 's/.*\/Stock Game/\/Stock Game/'`
    echo "Bin Path End: $bin_path_end" >>$LOGFILE 2>&1
    elif [[ $orig_line_path =~ Game\ Root ]]; then
    path_end=`echo "${skse_loc%/*}" | sed 's/.*\/Game Root/\/Game Root/'`
    echo "Path End: $path_end" >>$LOGFILE 2>&1
    bin_path_end=`echo "$skse_loc" | sed 's/.*\/Game Root/\/Game Root/'`
    echo "Bin Path End: $bin_path_end" >>$LOGFILE 2>&1
    elif [[ $orig_line_path =~ STOCK\ GAME ]]; then
    path_end=`echo "${skse_loc%/*}" | sed 's/.*\/STOCK GAME/\/STOCK GAME/'`
    echo "Path End: $path_end" >>$LOGFILE 2>&1
    bin_path_end=`echo "$skse_loc" | sed 's/.*\/STOCK GAME/\/STOCK GAME/'`
    echo "Bin Path End: $bin_path_end" >>$LOGFILE 2>&1
    elif [[ $orig_line_path =~ Stock\ Game\ Folder ]]; then
    path_end=`echo "$skse_loc" | sed 's/.*\/Stock Game Folder/\/Stock Game Folder/'`
    echo "Path End: $path_end" >>$LOGFILE 2>&1
    fi

elif [[ "$orig_line_path" == *"steamapps"* ]]; then
    # STEAMAPPS FOUND
    echo -e "steamapps Found" >>$LOGFILE 2>&1

    # Path Middle / modlist_dr
    path_middle=$steam_library
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

select_resolution() {
    if [ "$steamdeck" -eq 1 ]; then
        set_res="1280x800"
    else
        while true; do
            read -p "Enter your desired resolution in the format ####x####: " user_res

            # Validate the input format
            if [[ "$user_res" =~ ^[0-9]+x[0-9]+$ ]]; then
                # Ask for confirmation
                read -p "Is $user_res your desired resolution? (y/N): " confirm
                if [[ "$confirm" =~ ^[Yy]$ ]]; then
                    set_res="$user_res"
                    break
                else
                    echo "Please enter the resolution again."
                fi
            else
                echo "Invalid input format. Please enter the resolution in the format ####x####."
            fi
        done
    fi

    echo "Resolution set to: $set_res" >>$LOGFILE 2>&1
}

update_ini_files() {

    # Find all SSEDisplayTweaks.ini files in the specified directory and its subdirectories
    ini_files=$(find "$modlist_dir" -name "SSEDisplayTweaks.ini")

    if [ -n "$ini_files" ]; then
        while IFS= read -r ini_file; do
            # Use awk to replace the lines with the new values, handling spaces in paths
            awk -v res="$set_res" '/^(#?)Resolution=/ { print "Resolution=" res; next } \
                                   /^(#?)Fullscreen=/ { print "Fullscreen=false"; next } \
                                   /^(#?)#Fullscreen=/ { print "#Fullscreen=false"; next } \
                                   /^(#?)Borderless=/ { print "Borderless=true"; next } \
                                   /^(#?)#Borderless=/ { print "#Borderless=true"; next }1' "$ini_file" > temp_file && mv temp_file "$ini_file"

            echo "Updated $ini_file with Resolution=$set_res, Fullscreen=false, Borderless=true" >>$LOGFILE 2>&1
        done <<< "$ini_files"
    else
        echo "No SSEDisplayTweaks.ini files found in $modlist_dir. Please set manually in skyrimprefs.ini using the INI Editor in MO2."
    fi
}


#############################
# Detect if running on deck #
#############################

# Steamdeck or nah?

if [ -f "/etc/os-release" ] && grep -q "steamdeck" "/etc/os-release"; then
    steamdeck=1
    echo "Running on Steam Deck"| tee -a $LOGFILE
else
    steamdeck=0
    echo "NOT A steamdeck" >>$LOGFILE 2>&1
fi

###########################################
# Detect Protontricks (flatpak or native) #
###########################################

echo -ne "\nDetecting if protontricks is installed..." | tee -a $LOGFILE

if [[ $(flatpak list | grep -i protontricks) || -f /usr/bin/protontricks ]]; then
    # Protontricks is already installed or available
    echo -e " Done.\n" | tee -a $LOGFILE
else
    read -p "Protontricks not found. Do you wish to install it? (y/n): " answer
    if [[ $answer =~ ^[Yy]$ ]]; then
        if [[ $steamdeck -eq 1 ]]; then
            # Install Protontricks specifically for Deck
            flatpak install flathub com.github.Matoking.protontricks
        else
            read -p "Choose installation method: 1) Flatpak (preferred) 2) Native: " choice
            if [[ $choice =~ 1 ]]; then
                # Install protontricks
                flatpak install flathub com.github.Matoking.protontricks
            else
                # Print message and exit
                echo -e "\nSorry, there are way too many distro's to be able to automate this!" | tee -a $LOGFILE
                echo -e "\nPlease check how to install protontricks using your OS package system (yum, dnf, apt, pacman etc)" | tee -a $LOGFILE
            fi
        fi
    fi
fi

##############################################################
# List Skyrim and Fallout Modlists from Steam (protontricks) #
##############################################################

IFS=$'\n' readarray -t output_array < <(protontricks -l | grep -i 'Non-Steam shortcut' | grep -i 'Skyrim\|Fallout' | cut -d ' ' -f 3-)

echo -e "\e[33mDetected Modlists:\e[0m" | tee -a $LOGFILE

PS3="Please select an option: "  # Set prompt for select
select choice in "${output_array[@]}"; do
  MODLIST=`echo $choice | cut -d ' ' -f 3- | rev | cut -d ' ' -f 2- | rev`
  echo $choice | tee -a $LOGFILE
  echo -e "\nYou are about to run the automated steps on the Proton Prefix for:\e[32m $MODLIST\e[0m" | tee -a $LOGFILE
  break
done

echo -e "\e[31m \n** ARE YOU ABSOLUTELY SURE? (y/N)** \e[0m" | tee -a $LOGFILE

read -n 1 -sp " " response
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

expected=$(echo "$choice" | awk '{print $3}')

# Find all matching directories, store paths in an array
if [[ $steamdeck == 1 ]]; then
    matching_dirs=( $(find "$HOME/Games" /run/media/mmcblk0p1 -maxdepth 3 -type d -iname "*$expected*") )
else
    matching_dirs=( $(find "$HOME/Games" -maxdepth 3 -type d -iname "*$expected*") )
fi

# Check if multiple directories were found
if [[ ${#matching_dirs[@]} -gt 1 ]]; then
    # Display numbered options for the user to choose
    echo "Multiple possible directories detected, please select the correct one:" | tee -a $LOGFILE
    select modlist_dir in "${matching_dirs[@]}"; do
        if [[ $REPLY =~ ^[0-9]+$ && $REPLY -le ${#matching_dirs[@]} ]]; then
            echo -e "\nYou selected directory $modlist_dir" | tee -a $LOGFILE
            break
        else
            echo "Invalid option. Please enter a valid number from the list." | tee -a $LOGFILE
        fi
    done
else
    # Check if any directory was found
    if [[ ${#matching_dirs[@]} -eq 1 ]]; then
        modlist_dir=${matching_dirs[0]}
        echo -e "\nFound directory: $modlist_dir" | tee -a $LOGFILE
    else
        while true; do  # Loop until a valid directory is provided
            echo "Directory '$epected' not found. Please enter the full path manually." | tee -a $LOGFILE
            read -rp "Directory: " modlist_dir
            if [[ -d "$modlist_dir" ]]; then  # Check if the entered path exists
                break  # Exit the loop if a valid directory is found
            else
                echo "Directory not found, please check and try again.." | tee -a $LOGFILE
            fi
    done
    fi
fi

modlist_ini=$modlist_dir/ModOrganizer.ini

#####################################################
# Set protontricks permissions on Modlist Directory #
#####################################################

echo -e "\nSetting Protontricks permissions (requires sudo)... " | tee -a $LOGFILE
sudo flatpak override com.github.Matoking.protontricks --filesystem=$modlist_dir

#####################################
# Enable Visibility of (.)dot files #
#####################################

APPID=`echo $choice | awk {'print $NF'} | sed 's:^.\(.*\).$:\1:'`
echo $APPID  >>$LOGFILE 2>&1
echo -ne "\nEnabling visibility of (.)dot files... " | tee -a $LOGFILE

# Check if already settings
dotfiles_check=$(protontricks --no-bwrap -c 'WINEDEBUG=-all wine reg query "HKEY_CURRENT_USER\Software\Wine" /v ShowDotFiles' $APPID 2>/dev/null | grep ShowDotFiles | awk '{gsub(/\r/,""); print $NF}')

printf '%s\n' "$dotfiles_check">>$LOGFILE 2>&1

    if [[ "$dotfiles_check" = "Y" ]]; then
        printf '%s\n' "DotFiles already enabled... skipping" | tee -a $LOGFILE
    else
    protontricks --no-bwrap -c 'WINEDEBUG=-all wine reg add "HKEY_CURRENT_USER\Software\Wine" /v ShowDotFiles /d Y' $APPID &
    echo "Done!" | tee -a $LOGFILE
    fi

######################################
# Install Wine Components & VCRedist #
######################################

echo -e "\nInstalling Wine Components and VCRedist 2022... This can take some time, be patient!" | tee -a $LOGFILE

spinner=( '⠋' '⠙' '⠹' '⠸' '⠼' '⠴' '⠦' '⠧' '⠇' '⠏' )
protontricks --no-bwrap $APPID -q xact xact_x64 d3dcompiler_47 d3dx11_43 d3dcompiler_43 vcrun2022  >/dev/null 2>&1 &
#protontricks --no-bwrap $APPID -q xact xact_x64 d3dcompiler_47 d3dx11_43 d3dcompiler_43 vcrun2022  >>$LOGFILE 2>&1 &

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
)

# Get the output of the protontricks command
output="$(protontricks --no-bwrap $APPID list-installed)"

# Check if each component is present in the output
all_found=true
for component in "${components[@]}"; do
    if ! grep -q "$component" <<< "$output"; then
        echo "Component $component not found." >>$LOGFILE 2>&1
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

######################
# Detect MO2 Version #
######################

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

if [[ $mo2ver = *2.5* ]]; then
    echo  $vernum | tee -a $LOGFILE
    echo -e "\nError: Unsupported MO2 version" | tee -a $LOGFILE
    echo "" | tee -a $LOGFILE
    # Ask the user for input
    echo "WARNING: EXPERIMENTAL FEATURE - THIS WILL OVERWRITE THE MO2 FILES IN THE MODLIST DIRECTORY" | tee -a $LOGFILE
    read -p "Would like to attempt to replace with 2.4? (y/N) " response

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

###############################
# Confirmation before running #
###############################

echo "" | tee -a $LOGFILE
echo -e "\nFinal Checklist:" | tee -a $LOGFILE
echo -e "================" | tee -a $LOGFILE
echo -e "Modlist: $MODLIST .....\e[32m OK.\e[0m" | tee -a $LOGFILE
echo -e "Directory: $modlist_dir .....\e[32m OK.\e[0m" | tee -a $LOGFILE
echo -e "MO2 Version .....\e[32m OK.\e[0m" | tee -a $LOGFILE
#echo -e "\e[31m \n** Do you wish to continue? (sudo password required) (y/N) ** \e[0m"

#read -n 1 -sp " " response
#if [[ $response =~ ^[Yy]$ ]]; then

#################################
# chown/chmod modlist directory #
#################################

echo -e "\nChanging Ownership and Permissions of modlist directory (requires sudo password)" | tee -a $LOGFILE

sudo chown -R deck:deck $modlist_dir ; sudo chmod -R 755 $modlist_dir

#######################################################################
# Backup ModOrganizer.ini and backup gamePath & create checkmark file #
#######################################################################

# Backup ModOrganizer.ini
cp $modlist_ini $modlist_ini.bak

# Backup gamePath line
grep gamePath $modlist_ini | sed '/^backupPath/! s/gamePath/backupPath/' >> $modlist_ini

# Create checkmark file
touch $modlist_dir/.tmp_omniguides_run1

####################
# Checkmark Exists #
####################

# Check if the temporary file exists
#if [ -f "$modlist_dir/.tmp_omniguides_run1" ]; then
#  # Prompt the user for confirmation
#  read -r -p "A previous run exists. Re-run (y/N)? " response
#  case "$response" in
#    [Yy])
#      # User wants to re-run, clear the temporary file and proceed
#      rm -f "$modlist_dir/.tmp_omniguides_run1"
#      echo "Re-running..."
#      # Replace this placeholder with your actual script logic
#      your_script_logic
#      ;;
#    *)
#      # User doesn't want to re-run, exit gracefully
#      echo "Exiting..."
#      exit 0
#      ;;
#  esac
#else
#  # No previous run, proceed normally
#  echo "No previous run detected. Starting fresh..."
#  # Replace this placeholder with your actual script logic
#  your_script_logic
#fi

########################################
# Blank or set MO2 Downloads Directory #
########################################

echo -ne "\nEditing download_directory.. " | tee -a $LOGFILE
sed -i "/download_directory/c\download_directory =" $modlist_ini
echo  "Done." | tee -a $LOGFILE

######################################
# Replace path to Manage Game in MO2 #
######################################

replace_gamepath


#################################################
# Edit Custom binary and workingDirectory paths #
#################################################

grep -E -e "skse64_loader\.exe" -e "f4se_loader\.exe" "$modlist_ini"| while IFS= read -r orig_line_path; do
update_executables
done

###################
# Edit resolution #
###################

# Ask if we should set the resolution
#
echo -e "\nDo you wish to attempt to set the resolution? This can be changed manually later."
echo "(Please note that if running this script on a Steam Deck, a resolution of 1280x800 will be applied)"
echo ""
read -n 1 -sp "Select and set Resolution? (y/N): " response

    if [[ "$response" =~ ^[Yy]$ ]]; then
    echo ""
        select_resolution
        update_ini_files
    else
        echo "Resolution update cancelled."
    fi

##########################
# Small additional tasks #
##########################

# Delete MO2 plugins that don't work via Proton

file_to_delete="$modlist_dir/plugins/FixGameRegKey.py"

if [ -e "$file_to_delete" ]; then
    rm "$file_to_delete"
    echo "File deleted: $file_to_delete" | tee -a $LOGFILE
else
    echo "File does not exist: $file_to_delete" >>$LOGFILE 2>&1
fi

############
# Finished #
############

# Parting message
echo -e "\n\e[1mAll automated steps are now complete!\e[0m" | tee -a $LOGFILE
echo -e "\n\e[4mPlease follow any additional steps in the guide on github for setting resolution, disabling mods, etc\e[0m]" | tee -a $LOGFILE
echo -e "\nOnce you've done that, click Play for the modlist in Steam and get playing!" | tee -a $LOGFILE
else
        echo "" | tee -a $LOGFILE

        echo "Exiting..." | tee -a $LOGFILE
exit 1

fi

exit 0