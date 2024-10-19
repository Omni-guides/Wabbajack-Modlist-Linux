#!/bin/bash

########################
# Automate WJ via Wine #
#   Omni  -  Oct 2024  #
########################

date=$(date +"%d%m%y")

# Check current Wine prefix

echo -e "\nCurrent Wine Prefix: $WINEPREFIX"

# Set Wine prefix for this script

wineprefix=$HOME/Wabbajack/.wine
#wineprefix=$HOME/Wabbajack/.winetesting

echo -e "\nNew Wine Prefix: $wineprefix"

# Make Directory

wabbajackdir="$HOME/Wabbajack"

if [[ ! -d "$wabbajackdir" ]]; then
    mkdir -p "$wabbajackdir"
    echo -e "\nDirectory '$wabbajackdir' created."
else
    echo -e "\nDirectory '$wabbajackdir' already exists."
fi

# Download WJ and WebView

echo -e "\nDownloading Wabbajack Application if needed..."

if ! [ -f $wabbajackdir/Wabbajack.exe ]; then
        wget https://github.com/wabbajack-tools/wabbajack/releases/latest/download/Wabbajack.exe -O $wabbajackdir/Wabbajack.exe
fi

echo -e "\nDownloading WebView Installer if needed..."

if ! [ -f $wabbajackdir/Wabbajack/MicrosoftEdgeWebView2RuntimeInstallerX64.exe ]; then
        wget https://msedge.sf.dl.delivery.mp.microsoft.com/filestreamingservice/files/6d376ab4-4a07-4679-8918-e0dc3c0735c8/MicrosoftEdgeWebView2RuntimeInstallerX64.exe -O $wabbajackdir/MicrosoftEdgeWebView2RuntimeInstallerX64.exe
fi

# Clean wine prefix

if [[ ! -d "$wineprefix" ]]; then
    echo -e "\nDirectory '$wineprefix' not found."
else
    echo -e "\nDirectory '$wineprefix' deleted."
    rm -rf ""$wineprefix""
fi

# Create new prefix

echo -e "\nCreating new prefix at $wineprefix."

WINEPREFIX=$wineprefix wineboot

# Change Renderer

echo -e "\nChanging the default renderer used.."

WINEPREFIX=$wineprefix winetricks renderer=vulkan

# Install WebView

echo -e "\nInstalling Webview, this can take a while, please be patient"

WINEPREFIX=$wineprefix wine $HOME/Wabbajack/MicrosoftEdgeWebView2RuntimeInstallerX64.exe

# Change prefix version

echo -e "\nChange the default prefix version to win7.."

WINEPREFIX=$wineprefix winecfg -v win7

# Add Wabbajack as an application

echo -e "\nAdding Wabbajack Application to customise settings.."

cat <<EOF > $HOME/Wabbajack/WJApplication.reg
Windows Registry Editor Version 5.00

[HKEY_CURRENT_USER\Software\Wine\AppDefaults\Wabbajack.exe]
"Version"="win10"
EOF

WINEPREFIX=$wineprefix wine regedit $HOME/Wabbajack/WJApplication.reg

# Link Steam Library

echo -e "\nLinking Steam library.."

ln -s $HOME/.local/share/Steam $wineprefix/drive_c/Program\ Files\ \(x86\)/Steam

# Complete!

echo -e "\nDone! (hopefully) Waiting 10 seconds before starting Wabbajack.."
sleep 10

# Run Wabbajack

echo -e "\nStarting Wabbajack..."

cd $wabbajackdir ; WINEPREFIX=$wineprefix WINEDEBUG=-all wine $wabbajackdir/Wabbajack.exe
