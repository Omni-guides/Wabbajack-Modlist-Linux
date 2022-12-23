# Wabbajack Modlist + Linux / SteamDeck

DISCLAIMER - I am not affiliated with the Wabbajack group in any way, just a gamer trying to help other gamers. You may be able to get assistance with this guide from the #unofficial-linux-help channel of the main [Wabbajack Discord](https://discord.gg/wabbajack), but it may be best to @ me (@omni). Due to this being an unofficial guide, assistance from the wabbajack support directly on this is unlikely.

### Introduction

**I will shorlty be reorganising this guide to make it easier to follow for the multiple lists that have now been tested. This should be available in the next couple of weeks and make things much easier to follow.**

The following guide is a work in progress, based on my own tests, and along with mutliple users posting in the #unofficial-linux-help channel. With thanks to all involved. Feedback is always welcome.

The steps below have been used to get Wabbajack Modlists running on Linux, but **not** the Wabbajack Appliction itself. While I do have a method for running Wabbajack on bottles on Linux, I *do not* recommend it. I have confirmed success with Modlists for Skyrim, Fallout 4, Oblivion and more, on platforms such as SteamDeck (SteamOS/Arch), Garuda Linux (Arch) and Fedora, though the process should be largely the same for most distros. 

Until there is an officially supported version of Wabbajack for Linux, my recommendation is to use a Windows system in order to run the Wabbajack application and perform the initial download of the Wabbajack modlist you want to use. I run a smallish Windows VM on my gaming desktop that's sole purpose is to run Wabbajack and download Wabbajack lists.

For this guide, I have used the Septimus 4 modlist for the SteamDeck instructions, and Journey for the general Linux steps, just to give examples of different kinds of lists ('Stock Game' vs 'Game Root', for example). Other lists may require slightly different tweaks, but the majority of the steps will be the same. 

I've split the guide into a SteamDeck-specific guide, and below that a more general Linux distro guide, in an attempt to make the guide easier to follow for SteamDeck users. I chose the directory structure and naming convention I use here to enable the ability to have multiple modlists installed at the same time. You can however use whatever suits you and your environment.

---

![image](https://github.com/Omni-guides/Wabbajack-Modlist-Linux/blob/main/images/Septimus4-GoodLuck.png)

---

## For All Modlists

The following steps are required no matter which modlist you are going to run. There are sections near the end of this guide for modlist-specific fixes that I have found so far. Please do try your own and report back any fixes/tweaks you find or additional steps you needed to do so we can expand this guide to be as helpful as possible. I should be around in the Wabbajack Discord to try and help, or even if you just fancy a chat.

If you are installing on Linux, but **not** the SteamDeck, you can skip ahead to [Instructions for Linux](https://github.com/Omni-guides/Wabbajack-Modlist-Linux/blob/main/README.md#general-linux-instructions).

See the very bottom of the page for some troubleshooting tips.

---

---

### Instructions for SteamDeck

These steps will need to be carried out in Desktop mode, but once complete you will be able to launch the modlist and play the game from Game Mode. **If you are going to follow this guide and install Septimus 4, then make sure you first launch vanilla Skyrim and download the Anniversary Edition content.**

**Step 1 - Create the directory**

Once Wabbajack has successfully completed the download and installation of the modlist on your Windows system, create a new directory on the SteamDeck to house the required files - this can either be on the internal storage, or with the use of a specific launch parameter described below, can live on the sdcard. Open up Konsole and run **only one** of the following, depending on where you want to store the ModList:

Create Directory on **Internal Storage**:
```
mkdir -p /home/deck/Games/Skyrim/Septimus4
```

**OR**

Create Directory on **SDCard**:
```
mkdir -p /run/media/mmcblk0p1/Games/Skyrim/Septimus4
```

Copy the modlist directory from Windows into this newly created directory. There are many ways to do this. I chose to enable ssh on my Deck, and then use rsync to transfer. There are too many options to discuss here, but it should be relatively easy to search for methods. I copied the modlist directory to /home/deck/Games/Skyrim/Septimus4/Septimus4-WJ - the reason for this structure should hopefully become clear as we go through the steps. **Do not include any spaces in the directory path at this level** - it does not play well with the Proton/mo-redirect/MO2 combination even with the spaces being escaped, for whatever reason..

Finally for this step, it's best to make sure that the newly copied files have sufficient permissions for your user. Run **only one** of the following for each action (owner and permissions), depending on where you want to store the ModList:

Change the owner and permissions of the directory on **Internal Storage**:
```
sudo chown -R deck:deck /home/deck/Games/Skyrim/Septimus4/Septimus4-WJ
sudo chmod -R 755 /home/deck/Games/Skyrim/Septimus4/Septimus4-WJ
```

**OR**

Change the owner and permissions of the directory on **SDCard**:
```
sudo chown -R deck:deck /run/media/mmcblk0p1/Games/Skyrim/Septimus4/Septimus4-WJ
sudo chmod -R 755 /run/media/mmcblk0p1/Games/Skyrim/Septimus4/Septimus4-WJ
```

**Step 2 - Disable ENB**

Depending on the Modlist you are trying to run, the method for disabling ENB will differ. While ENB can work under Linux, it is likely going to badly impact performance on the Deck, so I would advise you to disable it. To do that for Septimus 4, we just need to disable the 'ENB - Binaries' entry in MO2


![image](https://github.com/Omni-guides/Wabbajack-Modlist-Linux/blob/main/images/Septimus4DisableENB.png)

For other modlists (usually ones that still use the 'Stock Game' directory mechanism), simply rename the d3d11.dll file in the ModList directory to stop ENB loading when Skyrim is launched. 

So for Septimus 4, **this isn't necessary**, but as an example for the Journey Modlist, you would run the following in Konsole:

```
mv /home/deck/Games/Skyrim/Journey/Journey-WJ/Stock\ Game/d3d11.dll /home/deck/Games/Skyrim/Journey/Journey-WJ/Stock\ Game/d3d11.dll.orig
```

If you really want to run the Linux ENB on the deck, you can follow the ENB link down in the [General Linux Steps](https://github.com/Omni-guides/Wabbajack-Modlist-Linux/blob/main/README.md#general-linux-instructions) below.

**Step 3 - Steam Redirector**

Next we need a nifty little program called steam-redirector. Information about this program can be found on the same github page as the more general [Linux Mod Organizer 2 installation](https://github.com/rockerbacon/modorganizer2-linux-installer). You can download it from here using the command below, or you can choose to build from source yourself following the instructions provided on the [steam-redirector](https://github.com/rockerbacon/modorganizer2-linux-installer/tree/master/steam-redirector) github page.

To download the version I have pre-built, run **only one** of the following commands in Konsole, depending on your storage location.

Download the pre-built mo-redirect.exe to **Internal Storage**:
```
wget https://github.com/Omni-guides/Wabbajack-Modlist-Linux/raw/main/mo-redirect.exe -O /home/deck/Games/Skyrim/Septimus4/mo-redirect.exe
```

**OR**

Download the pre-built mo-redirect.exe to **SDCard**:
```
wget https://github.com/Omni-guides/Wabbajack-Modlist-Linux/raw/main/mo-redirect.exe -O /run/media/mmcblk0p1/Games/Skyrim/Septimus4/mo-redirect.exe
```

This mo-redirect.exe is a wrapper app that basically points to the real location of your modlist's ModOrganizer.exe and nxmhandler.exe. It does this based on the contents of two files that have to live inside a specific directory called modorganizer2. This directory has to exist in the same directory mo-redirect.exe lives. So we need to create a directory, and then create the two files mo-redirect.exe is expecting.

Run **only one** of the following commands in Konsole, depending on where you are storing the modlist.

Create the Directory on **Internal Storage**:
```
mkdir /home/deck/Games/Skyrim/Septimus4/modorganizer2
```

**OR**

Create the Directory on **SDCard**:
```
mkdir /run/media/mmcblk0p1/Games/Skyrim/Septimus4/modorganizer2
```

Create the two required files, firstly ModOrganizer.exe. Run **only one** of the following:

**Internal Storage**:
```
echo "/home/deck/Games/Skyrim/Septimus4/Septimus4-WJ/ModOrganizer.exe" > /home/deck/Games/Skyrim/Septimus4/modorganizer2/instance_path.txt
```

**OR**

**SDCard**:
```
echo "/run/media/mmcblk0p1/Games/Skyrim/Septimus4/Septimus4-WJ/ModOrganizer.exe" > /run/media/mmcblk0p1/Games/Skyrim/Septimus4/modorganizer2/instance_path.txt
```

and then nxmhandler.exe. Again, only **run one** of the following:

**Internal Storage**:
```
echo "/home/deck/Games/Skyrim/Septimus4/Septimus4-WJ/nxmhandler.exe" > /home/deck/Games/Skyrim/Septimus4/modorganizer2/instance_download_path.txt
```

**OR**

**SDCard**:
```
echo "/run/media/mmcblk0p1/Games/Skyrim/Septimus4/Septimus4-WJ/nxmhandler.exe" > /run/media/mmcblk0p1/Games/Skyrim/Septimus4/modorganizer2/instance_download_path.txt
```

At this stage, the /home/deck/Games/Skyrim/Septimus4 directory (or SDCard equivalent) should contain the following two directories and one .exe file:

```
modorganizer2  mo-redirect.exe  Septimus4-WJ
```

with the modorganizer2 directory containing the two created files:

```
instance_path.txt
instance_download_path.txt
```

**Step 4 - Add the redirector as a Non-Steam Game**

Next step is to add mo-redirect.exe to Steam as a non-steam game. Once added, edit the properties of the new mo-redirect.exe entry. You can give it a more sensible name, e.g. "Skyrim - Septimus 4",  and then in the Compatibility tab tick the box for 'Force the use of a specific Steam Play compatibility tool', then select the Proton version - I chose Proton 7.0-4.

![image](https://github.com/Omni-guides/Wabbajack-Modlist-Linux/blob/main/images/SteamCompatibilityProton.png)

**IMPORTANT FOR SDCARD USERS** - You must add the following to the Launch Options for the mo-redirect.exe Non-Steam game, otherwise the Proton environment won't have access to your SDCard contents:

```
STEAM_COMPAT_MOUNTS=/run/media/mmcblk0p1 %command%
```
Like so:

![Screenshot_20220816_221418](https://user-images.githubusercontent.com/110171124/184987838-3688c045-551d-499a-ac2c-cba4b84255ed.png)

**Step 5 - Start and Configure ModOrganizer2**

Click play on this new entry mo-redirect.exe (or whatever you renamed it to) in Steam, and all being well, a little terminal window will appear - this is the steam-redirector doing it's job. If the terminal window just pops up for a second and vanishes, double check the contents of the instance_path.txt and instance_download_path.txt files as above, and that they are present in the correct directory - e.g. /home/deck/Games/Skyrim/Septimus4/modorganizer2/instances_path.txt, or check that the Proton version you have selected is 7.0-4 (or whatever the latest Steam-supplied stable version is).

![image](https://github.com/Omni-guides/Wabbajack-Modlist-Linux/blob/main/images/Septimus4MORedirectTerminal.png)

Depending on the path on Windows that you copied the ModList files from, you may see an error pop-up about yout account lacking permission:

![image](https://github.com/Omni-guides/Wabbajack-Modlist-Linux/blob/main/images/MO2DownloadsError.png)

To fix this, we just need to strip the now incorrect download directory from the ModOrganizer.ini file:

```
sed -i "s/download_directory=.*/download_directory=/" /home/deck/Games/Skyrim/Septimus4/Septimus4-WJ/ModOrganizer.ini
```

Occasionally, a modlist provides a ModOrganizer.ini file that contains spaces either side of the '=' sign. You may need to manually edit the file yourself to edit, as needed.

If you had this error, fix as above and then re-run mo-redirect.exe from Steam.

Another error box will appear, complaining that it "Cannot open instance 'Portable'. This is because we copied the ModList directory (inclusive of the built-in MO2) from Windows, so the path has changed:

![image](https://github.com/Omni-guides/Wabbajack-Modlist-Linux/blob/main/images/Septimus4PortableError.png)

To fix this, we need to point MO2 to our new location. Click OK, and then Browse:

** If you are installing Dragonborn, then please check the [modlist-specific steps for Dragonbornas](https://github.com/Omni-guides/Wabbajack-Modlist-Linux/edit/main/README.md#dragonborn) it differs from all other modlists currecntly! This will be cleared up in the upcoming guide re-write. ** 

![image](https://user-images.githubusercontent.com/110171124/185071655-30f8fe66-d83d-48d0-acf5-398951d0001e.png)

A GUI file browser will appear, and we need to expand the directories path to reveal the 'Root Game' directory:

![image](https://github.com/Omni-guides/Wabbajack-Modlist-Linux/blob/main/images/Septimus4GameRoot.png)

With that done, the custom modlist splashscreen for MO2 should appear, followed by ModOrganizer2 itself. 

![image](https://github.com/Omni-guides/Wabbajack-Modlist-Linux/blob/main/images/Septimus4Splash.png)

You may also get a pop-up asking if you want to Register for handling nxm links, like so:

![image](https://user-images.githubusercontent.com/110171124/185072115-97215185-7237-4973-9674-5281a7daf305.png)

I usually just hit "No, don't ask again" as I wont be downloading any new mods via this version of MO2.

Getting close now. Next, we have to ensure that ModOrganizer2 is pointing to the correct **new** location for the required executables. In MO2, click the little two-cog icon at the top, which will bring up the Modify Executables window (please note that this icon may differ for some modlists that use custom icon sets):

![image](https://user-images.githubusercontent.com/110171124/181569435-99b953ff-bb0a-4da7-aab8-4e76b5d0f3d6.png)

With the example ModList of Septimus 4, the executable that needs edited is simply called 'Septimus'. This will be different depending on the ModList you have chosen. We need to change the "Binary" and "Start In" locations to point to the directory inside our Septimus4-WJ directory that houses the skse64_loader.exe application. Due to running this through proton, it will be referenced by being the Z: drive location. So for example, the paths we need for Septimus4 entry should be:

'Binary' path: 
```
Z:\home\deck\Games\Skyrim\Septimus4\Septimus4-WJ\mods\Skyrim Script Extender\Root\skse64_loader.exe
```
and a 'Start In' path of:

```
Z:\home\deck\Games\Skyrim\Septimus4\Septimus4-WJ\mods\Skyrim Script Extender\Root\
```

You can copy and paste the path, or use the three dots beside the "Binary" and "Start In" entries to manually locate via GUI.

![image](https://github.com/Omni-guides/Wabbajack-Modlist-Linux/blob/main/images/Septimus4MO2Executables.png)

**Step 6 - Required Fixes for all ModLists**

Now on to required fixes. This has been required for each of the modlists I have managed to get running. There is an issue with missing NPC Voices -  apparently this is an issue with Proton. It may ultimately be resolved in time with a newer version of Proton without needing these steps, but for now, we need to add xact and xact_x64 to the Wine/Proton environment Steam created for mo-redirect.exe. The easiest way to accomplish this is to use protontricks. This can be installed via the Discover store on the Deck:

![image](https://user-images.githubusercontent.com/110171124/183392721-f4ed554a-8bb7-4cc2-a4b9-29c56b8b5a39.png)

![image](https://user-images.githubusercontent.com/110171124/183392763-f005a96d-4a78-4b7b-9fd1-ba4961126d10.png)

To enable the use of protontricks via the command line, open Konsole if it isn't open already, and run the following command to add an alias:

```
echo "alias protontricks='flatpak run com.github.Matoking.protontricks'" >> ~/.bashrc
```

then close and reopen Konsole. We can now invoke protontricks from the command line.

Adding the required packages can be done via the ProtonTricks gui, but perhaps the easiest way is via command line. First, find the AppID of the Non-Steam Game we added for mo-redirect.exe. In a terminal run:

```
protontricks -l | grep mo-redirect
```

Replace mo-redirect if you have renamed the Non-Steam Game added earlier. The output should look something like below, though your AppID will differ from mine:

```
Non-Steam shortcut: mo-redirect.exe (3595949753)
```

With the AppID now known, install the required xact and xact_x64 packages into this Proton environment (use your own AppID from the command above):

```
protontricks 3595949753 xact xact_x64
```

This may take a little time to complete, but just let it run the course.

**Step 7 - Next Steps**

At this stage, the steps required may differ depending on the modlist you have chosen, and the mods that the modlist includes. Skip ahead to the [Modlist-Specific Steps](https://github.com/Omni-guides/Wabbajack_Modlist-Linux#modlist-specific-steps) for what to do next, depending on your chosen ModList.

---

---

### General Linux Instructions

If you're looking to run a modlist on a general Linux system, and not a SteamDeck, these steps should hopefully get you up and running, though the steps for your specific distro may vary. To give an alternative example list, I will use the Journey Modlist for the below guide.

**Step 1 - Create the directory**

Once Wabbajack has successfully completed the download and installation of the modlist on your Windows system, create a new directory on the Linux system to house the required files:

```
mkdir -p /home/omni/Games/Skyrim/Journey
```

Copy the modlist directory from Windows into this newly created directory. There are many ways to do this. I chose rsync over ssh to transfer. There are too many options to discuss here, but it should be relatively easy to search for methods if you are unsure.

I copied the modlist directory to /home/omni/Games/Skyrim/Journey/Journey-WJ - the reason for this structure should hopefully become clear as we go through the steps.

Finally for this step, it's best to make sure that the newly copied files have sufficient permissions for your user. Run **only one** of the following, depending on where you want to store the ModList:

Change the owner of the directory:
```
sudo chown -R omni:omni /home/omni/Games/Skyrim/Journey/Journey-WJ
```

and then change the permissions of the directory:
```
sudo chmod -R 755 /home/omni/Games/Skyrim/Journey/Journey-WJ
```

**Step 2 - Disable ENB**

While ENB will work under Linux, it is outside the scope of this guide. You can visit [the ENB Website](http://enbdev.com/download_mod_tesskyrimse.htm) to download the latest version of ENB, which will include a 'LinuxVersion' folder inside the zip file you download. It contains a replacement d3d11.dll file to use under Linux. However, for the purposes of this guide, I still suggest you disable ENB until you are happy with the stability of the modlist under Linux. 

Depending on the Modlist you are trying to run, the method for disabling ENB will differ. To disable ENB for Journey, we just need to rename the d3d11.dll file in the ModList directory:

```
mv /home/omni/Games/Skyrim/Journey/Journey-WJ/Stock\ Game/d3d11.dll /home/omni/Games/Skyrim/Journey/Journey-WJ/Stock\ Game/d3d11.dll.orig
```

For other modlists, such as Septimus 4, you may need to disable the ENB - Binaries mod in MO2. See the SteamDeck instructions above for an example.

**Step 3 - Steam Redirector**

Next we need a nifty little program called steam-redirector. Information about this program can be found on the same github page as the more general [Linux Mod Organizer 2 installation](https://github.com/rockerbacon/modorganizer2-linux-installer). You can download it from here for Arch or Fedora using one of the commands below, or you can choose to build from source yourself following the instructions provided on the [steam-redirector](https://github.com/rockerbacon/modorganizer2-linux-installer/tree/master/steam-redirector) github page.

To download the version I have pre-built, run the following commands in a terminal:

```
wget https://github.com/Omni-guides/Wabbajack_Modlist-Linux/raw/main/mo-redirect.exe -O /home/omni/Games/Skyrim/Journey/mo-redirect.exe
```

The new mo-redirect.exe app basically points to the real location of your modlist's ModOrganizer.exe and nxmhandler.exe. It does this based on the contents of two files that have to live inside a specific directory called modorganizer2. This directory has to exist in the same directory mo-redirect.exe lives. So we need to create a directory, and then create the two files mo-redirect.exe is expecting.

Run the following command in a terminal window:

```
mkdir /home/omni/Games/Skyrim/Journey/modorganizer2
```

Next create the two required files, firstly ModOrganizer.exe:

```
echo "/home/omni/Games/Skyrim/Journey/Journey-WJ/ModOrganizer.exe" > /home/omni/Games/Skyrim/Journey/modorganizer2/instance_path.txt
```

and then nxmhandler.exe:

```
echo "/home/omni/Games/Skyrim/Journey/Journey-WJ/nxmhandler.exe" > /home/omni/Games/Skyrim/Journey/modorganizer2/instance_download_path.txt
```

At this stage, the /home/omni/Games/Skyrim/Journey directory should contain the following two directories and one .exe file:

```
modorganizer2  mo-redirect.exe  Journey-WJ
```

with the modorganizer2 directory containing the two created files:

```
instance_path.txt
instance_download_path.txt
```

**Step 4 - Add the redirector as a Non-Steam Game**

The next step is to add mo-redirect.exe to Steam as a non-steam game. Once added, edit the properties of the new mo-redirect.exe entry. You can give it a more sensible name, e.g. "Skyrim - Journey",  and then in the Compatibility tab tick the box for 'Force the use of a specific Steam Play compatibility tool', then select the Proton version - I chose Proton 7.0-4.

![image](https://github.com/Omni-guides/Wabbajack-Modlist-Linux/blob/main/images/SteamCompatibilityProton.png)

**Step 5 - Start and Configure ModOrganizer2**

Click play on this new entry mo-redirect.exe (or whatever you renamed it to) in Steam, and all being well a little terminal window will appear - this is the steam-redirector doing it's job. If the terminal window just pops up for a second and vanishes, double check the contents of the instance_path.txt and instance_download_path.txt files as above, and that they are present in the correct directory - e.g. /home/deck/Games/Skyrim/Septimus4/modorganizer2/instances_path.txt, or check that the Proton version you have selected is 7.0-4 (or whatever the latest Steam-supplied stable version is).

![image](https://github.com/Omni-guides/Wabbajack-Modlist-Linux/blob/main/images/LinuxMORedirectTerminal.png)

Depending on the path on Windows that you copied the ModList files from, you may see an error pop-up about yout account lacking permission:

![image](https://github.com/Omni-guides/Wabbajack-Modlist-Linux/blob/main/images/MO2DownloadsError.png)

To fix this, we just need to strip the now incorrect download directory from the ModOrganizer.ini file:

```
sed -i "s/download_directory=.*/download_directory=/" /home/omni/Games/Skyrim/Journey/Journey-WJ/ModOrganizer.ini
```

If you had this error, fix as above and then re-run mo-redirect.exe from Steam.

Another error box will appear, complaining that it "Cannot open instance 'Portable'. This is because we copied the ModList directory (inclusive of the built-in MO2) from Windows, so the path has changed:

![image](https://github.com/Omni-guides/Wabbajack-Modlist-Linux/blob/main/images/JourneyPortableError.png)

To fix this, we need to point MO2 to our new location. Click OK, and then Browse:

![image](https://user-images.githubusercontent.com/110171124/185071655-30f8fe66-d83d-48d0-acf5-398951d0001e.png)

A GUI file browser will appear, and we need to expand the directories path to reveal the 'Stock Game' directory:

![image](https://github.com/Omni-guides/Wabbajack-Modlist-Linux/blob/main/images/JourneyStockGame.png)

With that done, the custom modlist splashscreen for MO2 should appear, followed by ModOrganizer2 itself. 

![image](https://github.com/Omni-guides/Wabbajack-Modlist-Linux/blob/main/images/JourneySplash.png)

You may also get a pop-up asking if you want to Register for handling nxm links, like so:

![image](https://user-images.githubusercontent.com/110171124/185072115-97215185-7237-4973-9674-5281a7daf305.png)

I usually just hit "No, don't ask again" as I wont be downloading any new mods via this version of MO2.

Getting close now. Next, we have to ensure that ModOrganizer2 is pointing to the correct **new** location for the required executables. In MO2, click the little two-cog icon at the top, which will bring up the Modify Executables window (please note that this icon may differ for some modlists that use custom icon sets):

![image](https://github.com/Omni-guides/Wabbajack-Modlist-Linux/blob/main/images/JourneyExecutableTools.png)

With the example ModList of Journey, the executable that needs edited is simply called 'Journey'. This will be different depending on the ModList you have chosen. Change the "Binary" and "Start In" locations to point to the 'Stock Game' directory inside our journey-WJ directory. Due to running this through proton, it will be referenced by being the Z: drive location. So for example, the Journey entry should have a 'Binary' path of "Z:\home\omni\Games\Skyrim\Journey\Journey-WJ\Stock Game\skse64_loader.exe" and a 'Start In' path of "Z:\home\omni\Games\Skyrim\Journey\Journey-WJ\Stock Game". You can use the three dots beside the "Binary" and "Start In" entries to manually locate via GUI.

![image](https://github.com/Omni-guides/Wabbajack-Modlist-Linux/blob/main/images/JourneyExecutablePaths.png)

**Step 6 - Required Fixes for all ModLists**

Now on to required fixes. This has been required for each of the modlists I have managed to get running. There is an issue with missing NPC Voices -  apparently this is an issue with Proton, so it may ultimately be resolved in time  with a newer version of Proton without needing these steps, but for now, we need to add xact and xact_x64 to the Wine/Proton environment Steam created for mo-redirect.exe. The easiest way to accomplish this is to use protontricks. This can be installed via the Discover store, as a flatpak, or perhaps via your chosen distro's package manager:

![image](https://user-images.githubusercontent.com/110171124/183392721-f4ed554a-8bb7-4cc2-a4b9-29c56b8b5a39.png)

![image](https://user-images.githubusercontent.com/110171124/183392763-f005a96d-4a78-4b7b-9fd1-ba4961126d10.png)

If using the Flatpak version, you may need to manually enable the use of protontricks via the command line. Open a terminal and run the following command to add an alias:

```
echo "alias protontricks='flatpak run com.github.Matoking.protontricks'" >> ~/.bashrc
```

then close and reopen the terminal, or start a new session. We can now invoke protontricks from the command line.

Adding the required packages can be done via the ProtonTricks gui, but perhaps the easiest way is via command line. First, find the AppID of the Non-Steam Game we added for mo-redirect.exe. In a terminal run:

```
protontricks -l | grep mo-redirect
```

Replace mo-redirect if you have renamed the Non-Steam Game added earlier. The output should look something like below, though your AppID will differ from mine:

```
Non-Steam shortcut: mo-redirect.exe (3595949753)
```

With the AppID now known, install the required xact and xact_x64 packages into this Proton environment (use your own AppID from the command above):

```
protontricks 3595949753 xact xact_x64
```

This may take a little time to complete, but just let it run the course.

**Step 7 - Next Steps**

At this stage, the steps required may differ depending on the modlist you have chosen, and the mods that the modlist includes. Skip ahead to the [Modlist-Specific Steps](https://github.com/Omni-guides/Wabbajack_Modlist-Linux#modlist-specific-steps) for what to do next, depending on your chosen ModList.

---

---

## Modlist-specific Steps

This section deals with tweaks and fixes for specific ModLists that have been found so far. They are likely required regardless of whether you are running on the SteamDeck, or a general Linux system.

### Septimus 4

Thankfully, Septimus 4 has fewer tweaks to get running than Septimus 3 did. No mods need disabled now (unless you count ENB!) however two of the mods included in Septimus 4 rely on the latest 2022 version of Microsoft Visual C++ Redistributable - it has to be 2022, 2019 will not suffice. Sadly, 2022 isn't listed in the installable items via protontricks as yet so we need to install it ourselves. We need to get this installed into the Proton prefix Steam created for our mo-redirect.exe application. The following one-liner should do everything you need (just replace the text "mo-redirect.exe" with whatever your Non-Steam Game entry is called and is listed via protontricks -l.

```
APPID=`protontricks -l | grep "mo-redirect.exe" | awk {'print $7'} | sed 's:^.\(.*\).$:\1:' | tail -1` ; wget https://aka.ms/vs/17/release/vc_redist.x64.exe -O '/home/deck/.local/share/Steam/steamapps/compatdata/'"$APPID"'/pfx/dosdevices/c:/vc_redist.x64.exe' ; protontricks -c 'wine /home/deck/.local/share/Steam/steamapps/compatdata/'"$APPID"'/pfx/dosdevices/c:/vc_redist.x64.exe' $APPID
```

However, if you aren't keen on that giant command, or just want to do the steps one by one, you can do the following. Firstly, we need to download the vc_redist.x64.exe installer inside the Profont prefix. Run the following command, replacing my Game ID with your own from above (and alter the paths to suit your environment):

```
wget https://aka.ms/vs/17/release/vc_redist.x64.exe -O /home/deck/.local/share/Steam/steamapps/compatdata/3595949753/pfx/drives/c/vc_redist.x64.exe
```

Then we can enter the shell of our Proton environment:

```
protontricks 3595949753 shell
```

If successful, it should display a little C: prompt in your terminal window. Your terminal may misbehave after running the wine command - you can regain control by typing 'reset', even if you can't see the characters as you type.

Finally, run the installer:

```
wine vc_redist.x64.exe
```

![image](https://github.com/Omni-guides/Wabbajack-Modlist-Linux/blob/main/images/Septimus4WineShell.png)


![image](https://github.com/Omni-guides/Wabbajack-Modlist-Linux/blob/main/images/SeptimusVCRedistInstallStart.png)

Check the box to agree, and then click install. It should complete quickly.

![image](https://github.com/Omni-guides/Wabbajack-Modlist-Linux/blob/main/images/SeptimusVCRedistInstallComplete.png)

That should be everything you need to get Septimus 4 running on SteamDeck / Linux. As a note, there can be an error that appears when you click Play in MO2 for Septimus 4, complaining about binkw64.dll. This can also happen on Windows, and can apparently be safely ignored/closed (though it is really annoying, so if someone works out how to stop/suppress it, then let me know!). You may end up on the deck in the situation where the game window starts behind this error message, in which case you need to close it, or use the window switching function via the Steam button on the bottom left of the deck.

![image](https://github.com/Omni-guides/Wabbajack-Modlist-Linux/blob/main/images/Septimus4-binkError.png)

Move on the the Conclusion!

---

### Dragonborn

A new list by GuitarNinja, that is designed with the Steam Deck in mind!

This one should be relatively easy to get up and running, with only a few minor additional steps. Firstl, as with Septimus 4, we need to install vcredist2022. The following one-liner should do everything you need (just replace the text "mo-redirect.exe" with whatever your Non-Steam Game entry is called and is listed via protontricks -l.

```
APPID=`protontricks -l | grep "mo-redirect.exe" | awk {'print $7'} | sed 's:^.\(.*\).$:\1:' | tail -1` ; wget https://aka.ms/vs/17/release/vc_redist.x64.exe -O '/home/deck/.local/share/Steam/steamapps/compatdata/'"$APPID"'/pfx/dosdevices/c:/vc_redist.x64.exe' ; protontricks -c 'wine /home/deck/.local/share/Steam/steamapps/compatdata/'"$APPID"'/pfx/dosdevices/c:/vc_redist.x64.exe' $APPID
```

The next slight change from other modlists is that Dragonborn doesn't provide it's own GameRoot or StockGame folder in order to point MO2 at on first launch. For this we need to point at the Vanilla Skyrim location on the deck/Linux, which will probably exist in the equivalent of the /home/deck/.local directory. By default, Wine/Proton applications do not have visibility of .(dot) files and folders, so we need to tweak it via Protontricks. Firstly, close down MO2 and mo-redirect.exe if it doesn't close automatically. Next, open up the Protontricks gui for our Dragonborn instance (replace mo-redirect.exe with the name of your Non-steam game entry, if you changed it):

```
APPID=`protontricks -l | grep "mo-redirect.exe" | awk {'print $6'} | sed 's:^.\(.*\).$:\1:' | tail -1` ; protontricks $APPID --gui

```

Keep the 'default' selection highlighted, and click Next:

![image](https://github.com/Omni-guides/Wabbajack-Modlist-Linux/blob/main/images/ProtonTricks_GUI_winecfg.png)
 
Select the 'winecfg' entry, and click Next. 
 
![image](https://github.com/Omni-guides/Wabbajack-Modlist-Linux/blob/main/images/ProtonTricks_GUI_winecfg2.png)
       
This should open up a little windows style Properties box. From there, click the Drvies tab at the top, and then check the box for showing 'dot files':
 
![image](https://github.com/Omni-guides/Wabbajack-Modlist-Linux/blob/main/images/Protontricks_GUI-dotfiles.png)
 
With that setting in place, MO2 will have visibility of the required .local directory in order to point MO2 at when you first launch it:

![image](https://github.com/Omni-guides/Wabbajack-Modlist-Linux/blob/main/images/Dragonborn_Executables_skse.png)
 
This leads us to the final alteration from other lists - Dragonborn still uses the GameRoot mechanism, it just uses the vanilla Skyrim directory to do so. So for the Dragonborn exectuable, we actually need to point MO2 at a file that doesn't exist (but will exist, once GameRoot runs when you click launch - and is then removed again when the game closes).
 
The path you need for the Dragonborn application will be:

```
Z:\home\deck\.local\share\Steam\steamapps\common\Skyrim Special Edition\skse64_loader.exe
```
 
with a 'start in' path of:

```
Z:\home\deck\.local\share\Steam\steamapps\common\Skyrim Special Edition
```
With these in place, Dragonborn should now start successfully. 
 
---

### Journey

With the above NPC Voice fix in place, I didn't need to carry out any more steps. It 'just worked' \o/

---

### Wildlander

I wouldn't recommend this one for the Deck yet. I managed to get fairly decent performence with a custom profile somewhere between Low and Potato, but couldn't work around the Face Discoloration myself. I believe the Modlist team on this one are keen on having a workable SteamDeck profile - I'd be happy to help them test! :)

I believe a future version of the list will no longer include the requirement of the Face Discoloration Fix mod, so for general Linux gaming, this will likely be easy to get running. Performance on the Steam Deck will remain to be seen. I know they are doing a lot of work on controller support also, so this is definitely one to watch!

---

### Other Modlist Notes

There is an incompatiblity with one particular mod that is fairly widely used - Face Discoloration Fix. This mod appears to be flat out incompatible with Wine/Proton and will cause the game to crash while loading the main menu. However, disabling this mod alone usually results in the faces of NPCs being discoloured (funnily enough..), so after a bit of trial and error, I found that we also need to disable the mod: VHR - Vanilla Hair Replacer - Disabling these two mods will render you out of support for the modlist because you have modified the modlist, but we're likely way out of support from the author by running under Linux in the first place :) There may be other modlists that have Face Discoloration Fix, but not VHR... I'm afraid it's a bit trial and error to narrow down.

It's a shame to lose what these mods bring to the modlist, and perhaps there are ways to get them working in future. Open to any help on narrowing down what would be required to allow Face Discoloration Fix to function.

You can use the filter text box at the bottom of MO2 to find the mods in question, and then click to untick.

Face Discoloration Fix:

![image](https://user-images.githubusercontent.com/110171124/181570341-34ec4a80-94c3-4b8f-b639-4e010a2366ad.png)

Repeat for Vanilla Hair Replacer:

![image](https://user-images.githubusercontent.com/110171124/185082764-99e8a072-732f-4610-ae82-33dc68fd0bda.png)

---

### Conclusion

At last!

If you've read this far, then well done! I'd appreciate a Star for this guide, just to show if I'm on the right track. I'm also open to any feedback, positive or negative.

With NPC Voices fixed, and any ModList-specific fixes from above applied, we should now be ready! Click the Play button in Mod Organizer, and wait. This took quite a bit of time on my laptop. So long, in fact, that I thought it had crashed and I started killing processes etc. But just wait... It took my laptop a full 2 minutes for the Skyrim window to appear, and then another 30-40 seconds for the main menu choices to appear. On SteamDeck, it took approximately 3 minutes and 45 seconds before I could interact with the in-game menu. Once it had loaded though, performance was good in the menus, and in-game performance will depend on your system specs and modlist chosen. 

On SteamDeck, I limit FPS and Refresh rate to 40, and it does a pretty good job at maintaining that in Journey modlists, where Septimus 4 fluctuates between 30 and 40, though I am still testing more performance tweaks. Other lists may vary, and I do plan to test more as my time allows. Some users have reported about switching to the Low preset provided with some modlists, which can aid FPS and Battery life, at the expesnve of graphical fidelity. YMMV. I would love to get feedback on performance of various lists, and any tweaks that you made!

Once you have started a new game, please follow any additional steps that the wiki for your chosen modlist asks you to carry out, in terms of mod configuration from inside the game.

As an addition to the disclaimer at the top of this guide, I have no visibility of longer term stability, so, save often, and maybe even make backups of your savegames, just in case ;) 

If you need help with any of the above, or better yet have another fix, tweak or workaround to help get these modlists running on Linux, then please do stop by the channel on the Wabbajack Discord, I should be around so just @ me (@omni).

Enjoy!

![image](https://github.com/Omni-guides/Wabbajack-Modlist-Linux/blob/main/images/Septimus4-GoodLuck.png)


## Troubleshooting

#### The mo-redirect.exe terminal window flicks up for a second, then vanishes!

This is usually caused by either incorrect paths in the instance_path.txt and instance_download_path.txt files, or by the path to the modlist containing a space. For example '/home/deck/Games/Skyrim/LostLegacy' is fine, but '/home/deck/Games/Skyrim/Lost\ Legacy' is not, even if you escape the space with a backslash.

---

#### Skyrim crashes on startup after a short black flicker on the screen!

Make sure you definitely disabled ENB - either by renaming the d3d11.dll file, or by disabling the mods, depending on your  modlist.

---

#### My shell is messed up after using protontricks and I cant see anything I type!

This is just something that happens when dealing with wine prefixes in a terminal. You can regain control of your terminal by typing 'reset' end hitting return, even if you can't see the characters you type.

---

#### My ModList requires a vc_redist dependency

VC Redist versions up to 2019 can be installed easily with protontricks, e.g. protontricks <APPID> vcredist2019 

However, some newer lists also now require VC Redist 2022, so we have to get the latest version of the vc_redist from Microsoft and install it.

You can find it here for a manual download : https://support.microsoft.com/en-us/help/2977003/the-latest-supported-visual-c-downloads

At the time of writing this, the latest redistributable bundles all versions from 2015 up to 2022.
To install it, copy the vc_redist.x64.exe file to your Steamdeck, then jump into a protontricks shell and run `wine vc_redist.x64.exe` at the file's location to install it. Replace the APPID 3595949753 below with your APPID from protontricks -l

```
wget https://aka.ms/vs/17/release/vc_redist.x64.exe -O /home/deck/.local/share/Steam/steamapps/compatdata/3595949753/pfx/drives/c/vc_redist.x64.exe
```
If running it directly via Konsole on the deck in Desktop Mode, run:

```
protontricks -c 'wine /home/deck/.local/share/Steam/steamapps/compatdata/3595949753/pfx/dosdevices/c:/VC_redist.x64.exe'
```

If you are running it via ssh, you will have to run it 'headless':

```
protontricks -c 'wine /home/deck/.local/share/Steam/steamapps/compatdata/3595949753/pfx/dosdevices/c:/VC_redist.x64.exe  -q -norestart'
```
 Or you can use the following one-liner to do all the steps - just ensure you change "Septimus 4" to better match wahtever your modlist entry in Steam is called, listed in protontricks -l

```
APPID=`protontricks -l | grep "Septimus 4" | awk {'print $7'} | sed 's:^.\(.*\).$:\1:' | tail -1` ; wget https://aka.ms/vs/17/release/vc_redist.x64.exe -O '/home/deck/.local/share/Steam/steamapps/compatdata/'"$APPID"'/pfx/dosdevices/c:/vc_redist.x64.exe' ; protontricks -c 'wine /home/deck/.local/share/Steam/steamapps/compatdata/'"$APPID"'/pfx/dosdevices/c:/vc_redist.x64.exe' $APPID
```
---

#### binkw64.dll error when clicking play in MO2

This is a known issue and happens on both Windows and Linux. Apparently it can be safely ignored. So far I can only attribute it to something in the 'Game Root' mechanism, but I do not yet have a way to fix or suppress the error, you can just close the window.

![image](https://github.com/Omni-guides/Wabbajack-Modlist-Linux/blob/main/images/Septimus4-binkError.png)

---

#### My modlists uses 'Game Root' and keeps crashing

I have seen instances of Game Root being built when starting the game, but it doesn't get 'unbuilt' if the game crashes. This can range from an error about not being able to fin SkyrimSE.exe, all the way to continually loading the ENB binary even if you have disabled it in MO2.

To clean things up, you can go to the Tools menu in MO2, then Tool Plugins -> Root Builder -> clear

Than launch the game again, and it should rebuild the Game Root cleanly.

![image](https://github.com/Omni-guides/Wabbajack-Modlist-Linux/blob/main/images/Septimus4CleanGameRoot.png)

