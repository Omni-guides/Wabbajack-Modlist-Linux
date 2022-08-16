# Skyrim + Wabbajack Modlist + Linux / SteamDeck

DISCLAIMER - I am not affiliated with the Wabbajack group in any way, just a gamer trying to help other gamers. You may be able to get assistance with this guide from the #unofficial-linux-help channel of the main [Wabbajack Discord](https://discord.gg/wabbajack), but it may be best to @ me (@omni). Due to this being an unofficial guide, assistance from the wabbajack support directly on this is unlikely.

#### Introduction

The following guide is a work in progress, based on my own tests, and along with mutliple users posting in the #unofficial-linux-help channel. With thanks to all involved. Feedback is always welcome.

The steps below have been used to get a Wabbajack Skyrim Modlist running on Linux, but **not** the Wabbajack Appliction itself (yet). I have confirmed success with SteamDeck (Arch), Garuda (Arch) and Fedora, though the process should be largely the same for most distros. 

Until there is a method or version of Wabbajack that runs under Linux, **you will require a Windows system in order to run the Wabbajack application and perform the initial download of the Wabbajack modlist you want to use**. 

For this example, I used the Septimus 3 modlist. 

I've split the guide into a SteamDeck-specific guide, and below that a more general Linux distro guide, in an attempt to make the guide easier to follow for SteamDeck users. I chose the directory structure and naming convention I use here to enable the ability to have multiple modlists installed at the same time. You can however use whatever suits you and your environment.

---

### For All Modlists

The following steps are required no matter which modlist you are going to run. There are sections near the end of this guide for modlist-specific fixes that I have found so far. Please do try your own and report back any fixes/tweaks you find or additional steps you needed to do, so we can expand this guide to be as helpful as possible. I should be around in the Wabbajack Discord, even if you just fancy a chat.

If you are installing on Linux, but **not** the SteamDeck, you can skip ahead to [Instructions for Linux](https://github.com/Omni-guides/Skyrim-Wabbajack_Modlist-Linux/edit/main/README.md#general-linux-instructions).

#### Instructions for SteamDeck

These steps will need to be carried out in Desktop mode, but once complete, you can launch the modlist from Game Mode.

**Step 1 - Create the directory**

Once Wabbajack has successfully completed the download and installation of the modlist on your Windows system, create a new directory on the SteamDeck to house the required files - this can either be on the internal storage, or with the use of a specific launch parameter described below, can live on the sdcard. Open up Konsole and run **only one** of the following, depending on where you want to store the ModList:

Create Directory on Internal Storage:
```
mkdir -p /home/deck/Games/Skyrim/Septimus3
```

**OR**

Create Directory on SDCard:
```
sudo mkdir /run/media/mmcblk0p1/Games/Skyrim/Septimus3
```

Copy the modlist directory from Windows into this newly created directory. There are many ways to do this. I chose to enable ssh on my Deck, and then use rsync to transfer. There are too many options to discuss here, but it should be relatively easy to search for methods. I copied the modlist directory to /home/deck/Games/Skyrim/Septimus3/Septimus3-WJ - the reason for this structure should hopefully become clear as we go through the steps.

**Step 2 - Disable ENB**

ENB will not work under Linux, so you will need to rename the d3d11.dll file in the ModList directory to stop ENB loading when Skyrim is launched.

```
mv /home/deck/Games/Skyrim/Septimus3/Septimus3-WJ/Stock\ Game/d3d11.dll /home/deck/Games/Skyrim/Septimus3/Septimus3-WJ/Stock\ Game/d3d11.dll.orig
```

**Step 3 - Steam Redirector**

Next we need a nifty little program called steam-redirector. Information about this program can be found on the same github page as the more general [Linux Mod Organizer 2 installation](https://github.com/rockerbacon/modorganizer2-linux-installer). You can download it from here using the command below, or you can choose to build from source yourself following the instructions provided on the [steam-redirector](https://github.com/rockerbacon/modorganizer2-linux-installer/tree/master/steam-redirector) github page.

To download the version I have pre-built, run **only one** of the following commands in Konsole, depending on your storage location.

Download the pre-built SteamDeck mo-redirect.exe to Internal Storage:
```
wget https://github.com/Omni-guides/Skyrim-Wabbajack_Modlist-Linux/raw/main/mo-redirect.exe -O /home/deck/Games/Skyrim/Septimus3/mo-redirect.exe
```

**OR**

Download the pre-built SteamDeck mo-redirect.exe to SDCard:
```
wget https://github.com/Omni-guides/Skyrim-Wabbajack_Modlist-Linux/raw/main/SteamDeck-mo-redirect.exe -O /run/media/mmcblk0p1/Games/Skyrim/Septimus3/mo-redirect.exe
```

This mo-redirect.exe is a wrapper app that basically points to the real location of your modlist's ModOrganizer.exe and nxmhandler.exe. It does this based on the contents of two files that have to live inside a specific directory called modorganizer2. This directory has to exist in the same directory mo-redirect.exe lives. So we need to create a directory, and then create the two files mo-redirect.exe is expecting.

Run **only one** of the following commands in Konsole, depending on where you are storing the modlist.

Create the Directory on Internal Storage:
```
mkdir /home/deck/Games/Skyrim/Septimus3/modorganizer2
```

**OR**

Create the Directory on SDCard:
```
mkdir /run/media/mmcblk0p1/Games/Skyrim/Septimus3/modorganizer2
```

Create the two required files, firstly ModOrganizer.exe. Run **only one** of the following:

Internal Storage:
```
echo "/home/deck/Games/Skyrim/Septimus3/Septimus3-WJ/ModOrganizer.exe" > /home/deck/Games/Skyrim/Septimus3/modorganizer2/instance_path.txt
```

**OR**

SDCard
```
echo "/run/media/mmcblk0p1/Games/Skyrim/Septimus3/Septimus3-WJ/ModOrganizer.exe" > /run/media/mmcblk0p1/Games/Skyrim/Septimus3/modorganizer2/instance_path.txt
```

and then nxmhandler.exe. Again, only **run one** of the following:

Internal Storage:
```
echo "/home/deck/Games/Skyrim/Septimus3/Septimus3-WJ/nxmhandler.exe" > /home/deck/Games/Skyrim/Septimus3/modorganizer2/instance_download_path.txt
```

**OR**

SDCard:
```
echo "/run/media/mmcblk0p1/Games/Skyrim/Septimus3/Septimus3-WJ/nxmhandler.exe" > /run/media/mmcblk0p1/Games/Skyrim/Septimus3/modorganizer2/instance_download_path.txt
```

At this stage, the /home/deck/Games/Skyrim/Septimus3 directory (or SDCard equivalent) should contain the following two directories and one .exe file:

```
modorganizer2  mo-redirect.exe  Septimus3-WJ
```

with the modorganizer2 directory containing the two created files:

```
instance_path.txt
instance_download_path.txt
```

**Step 4 - Add the redirector as a Non-Steam Game**

Next step is to add mo-redirect.exe to Steam as a non-steam game. Once added, edit the properties of the new mo-redirect.exe entry. You can give it a more sensible name, e.g. "Skyrim - Septimus 3",  and then in the Compatibility tab tick the box for 'Force the use of a specific Steam Play compatibility tool', then select the Proton version - I chose Proton 7.0-3.

![image](https://user-images.githubusercontent.com/110171124/181563703-484cca11-4c48-438b-ad1c-c332779a242f.png)

**IMPORTANT FOR SDCARD USERS** - You must add the following to the Launch Options for the mo-redirect.exe Non-Steam game, otherwise the Proton environment won't have access to your SDCard contents:

```
STEAM_COMPAT_MOUNTS=/run/media/mmcblk0p1 %command%
```
Like so:

![Screenshot_20220816_221418](https://user-images.githubusercontent.com/110171124/184987838-3688c045-551d-499a-ac2c-cba4b84255ed.png)

**Step 5 - Start and Configure ModOrganizer2**

Click play on this new entry mo-redirect.exe (or whatever you renamed it to) in Steam, and all being well, a little terminal window will appear - this is the steam-redirector doing it's job. The custom modlist splashscreen for MO2 should appear, followed by ModOrganizer2 itself. If the terminal window just pops up for a second and vanishes, double check the contents of the instance_path.txt and instance_download_path.txt files as above, and that they are present in the correct directory - e.g. /home/deck/Games/Skyrim/Septimus3/modorganizer2/instances_path.txt

![image](https://user-images.githubusercontent.com/110171124/181574124-776fde2f-35b4-4987-9fed-efc32eda7937.png)

![image](https://user-images.githubusercontent.com/110171124/181574661-c58922a0-09be-4062-b76d-5c99d1394705.png)

Getting close now. Next, we have to ensure that ModOrganizer2 is pointing to the correct **new** location for the required executables. In MO2, click the little two-cog icon at the top, which will bring up the Modify Executables window (please note that this icon may differ for some modlists that use custom icon sets):

![image](https://user-images.githubusercontent.com/110171124/181569435-99b953ff-bb0a-4da7-aab8-4e76b5d0f3d6.png)

With the example ModList of Septimus 3, the executable that needs edited is simply called 'Septimus'. This will be different depending on the ModList you have chosen. Change the "Binary" and "Start In" locations to point to the 'Stock Game' directory inside our Septimus3-WJ directory. Due to running this through proton, it will be referenced by being the Z: drive location. So for example, the Septimus entry should have a 'Binary' path of "Z:\home\deck\Games\Skyrim\Septimus3\Septimus3-WJ\Stock Game\skse64_loader.exe" and a 'Start In' path of "Z:\home\deck\Games\Skyrim\Septimus3\Septimus3-WJ\Stock Game". You can use the three dots beside the "Binary" and "Start In" entries to manually locate via GUI.

![image](https://user-images.githubusercontent.com/110171124/183409643-c45c04e2-7b6c-46d9-bbac-8a7ea0cc4645.png)

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

At this stage, the steps required may differ depending on the modlist you have chosen, and the mods that the modlist includes. Skip ahead to the [Modlist-Specific Steps](https://github.com/Omni-guides/Skyrim-Wabbajack_Modlist-Linux#modlist-specific-steps) for what to do next, depending on your chosen ModList.

---

#### General Linux Instructions

If you're looking to run a modlist on a general Linux system, and not a SteamDeck, these steps should hopefully get you up and running. 

**Step 1 - Create the directory**

Once Wabbajack has successfully completed the download and installation of the modlist on your Windows system, create a new directory on the Linux system to house the required files:

```
mkdir -p /home/omni/Games/Skyrim/Septimus3
```

Copy the modlist directory from Windows into this newly created directory. There are many ways to do this. I chose rsync over ssh to transfer. There are too many options to discuss here, but it should be relatively easy to search for methods if you are unsure.

I copied the modlist directory to /home/omni/Games/Skyrim/Septimus3/Septimus3-WJ - the reason for this structure should hopefully become clear as we go through the steps.

**Step 2 - Disable ENB**

ENB will not work under Linux, so you will need to rename the d3d11.dll file in the ModList directory to stop ENB loading when Skyrim is launched.

```
mv /home/omni/Games/Skyrim/Septimus3/Septimus3-WJ/Stock\ Game/d3d11.dll /home/omni/Games/Skyrim/Septimus3/Septimus3-WJ/Stock\ Game/d3d11.dll.orig
```

**Step 3 - Steam Redirector**

Next we need a nifty little program called steam-redirector. Information about this program can be found on the same github page as the more general [Linux Mod Organizer 2 installation](https://github.com/rockerbacon/modorganizer2-linux-installer). You can download it from here for Arch or Fedora using one of the commands below, or you can choose to build from source yourself following the instructions provided on the [steam-redirector](https://github.com/rockerbacon/modorganizer2-linux-installer/tree/master/steam-redirector) github page.

To download the version I have pre-built, run the following commands in a terminal:

```
wget https://github.com/Omni-guides/Skyrim-Wabbajack_Modlist-Linux/raw/main/mo-redirect.exe -O /home/omni/Games/Skyrim/Septimus3/mo-redirect.exe
```

The new mo-redirect.exe app basically points to the real location of your modlist's ModOrganizer.exe and nxmhandler.exe. It does this based on the contents of two files that have to live inside a specific directory called modorganizer2. This directory has to exist in the same directory mo-redirect.exe lives. So we need to create a directory, and then create the two files mo-redirect.exe is expecting.

Run the following command in a terminal window:

```
mkdir /home/omni/Games/Skyrim/Septimus3/modorganizer2
```

Next create the two required files, firstly ModOrganizer.exe:

```
echo "/home/omni/Games/Skyrim/Septimus3/Septimus3-WJ/ModOrganizer.exe" > /home/omni/Games/Skyrim/Septimus3/modorganizer2/instance_path.txt
```

and then nxmhandler.exe:

```
echo "/home/omni/Games/Skyrim/Septimus3/Septimus3-WJ/nxmhandler.exe" > /home/omni/Games/Skyrim/Septimus3/modorganizer2/instance_download_path.txt
```

At this stage, the /home/omni/Games/Skyrim/Septimus3 directory should contain the following two directories and one .exe file:

```
modorganizer2  mo-redirect.exe  Septimus3-WJ
```

with the modorganizer2 directory containing the two created files:

```
instance_path.txt
instance_download_path.txt
```

**Step 4 - Add the redirector as a Non-Steam Game**

The next step is to add mo-redirect.exe to Steam as a non-steam game. Once added, edit the properties of the new mo-redirect.exe entry. You can give it a more sensible name, e.g. "Skyrim - Septimus 3",  and then in the Compatibility tab tick the box for 'Force the use of a specific Steam Play compatibility tool', then select the Proton version - I chose Proton 7.0-3.

![image](https://user-images.githubusercontent.com/110171124/181563703-484cca11-4c48-438b-ad1c-c332779a242f.png)

**Step 5 - Start and Configure ModOrganizer2**

Click play on this new entry mo-redirect.exe (or whatever you renamed it to) in Steam, and all being well, a little terminal window will appear - this is the steam-redirector doing it's job. The custom modlist splashscreen for MO2 should appear, followed by ModOrganizer2 itself. If the terminal window just pops up for a second and vanishes, double check the contents of your instance_path.txt and instance_download_path.txt files as above, and that they are present in the correct directory - e.g. /home/omni/Games/Skyrim/Septimus3/modorganizer2/instances_path.txt and instances_download_path.txt

![image](https://user-images.githubusercontent.com/110171124/181574124-776fde2f-35b4-4987-9fed-efc32eda7937.png)

![image](https://user-images.githubusercontent.com/110171124/181574661-c58922a0-09be-4062-b76d-5c99d1394705.png)

Getting close now. Next, we have to ensure that ModOrganizer2 is pointing to the correct **new** location for the required executables. In MO2, click the little two-cog icon at the top, which will bring up the Modify Executables window (please note that this icon may differ for some modlists that use custom icon sets):

![image](https://user-images.githubusercontent.com/110171124/181569435-99b953ff-bb0a-4da7-aab8-4e76b5d0f3d6.png)

With the example ModList of Septimus 3, the executable that needs edited is simply called 'Septimus'. This will be different depending on the ModList you have chosen. Change the "Binary" and "Start In" locations to point to the 'Stock Game' directory inside our Septimus3-WJ directory. Due to running this through proton, it will be referenced by being the Z: drive location. So for example, the Septimus entry should have a 'Binary' path of "Z:\home\omni\Games\Skyrim\Septimus3\Septimus3-WJ\Stock Game\skse64_loader.exe" and a 'Start In' path of "Z:\home\omni\Games\Skyrim\Septimus3\Septimus3-WJ\Stock Game". You can use the three dots beside the "Binary" and "Start In" entries to manually locate via GUI.

![image](https://user-images.githubusercontent.com/110171124/183409643-c45c04e2-7b6c-46d9-bbac-8a7ea0cc4645.png)

**Step 6 - Required Fixes for all ModLists**

Now on to required fixes. This has been required for each of the modlists I have manager to get running. There is an issue with missing NPC Voices -  Apparently this is an issue with Proton, so it may ultimately be resolved in time  with a newer version of Proton, without needing these steps, but for now, we need to add xact and xact_x64 to the Wine/Proton environment Steam created for mo-redirect.exe. The easiest way to accomplish this is to use protontricks. This can be installed via the Discover store, as a flatpak, or perhaps via your chosen distro's package manager:

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

At this stage, the steps required may differ depending on the modlist you have chosen, and the mods that the modlist includes. Skip ahead to the [Modlist-Specific Steps](https://github.com/Omni-guides/Skyrim-Wabbajack_Modlist-Linux#modlist-specific-steps) for what to do next, depending on your chosen ModList.

---


### Modlist-specific Steps

#### Septimus 3

There are a couple of extra things I had to do to get Septimus 3 to start without crashing, and function correctly. There is an incompatiblity with one particular mod in Septimus 3 (and likely other Modlists) that was causing the game to crash while loading the main menu - Face Discoloration Fix. However, disabling this mod alone results in the faces of NPCs being discoloured, so after a bit of trial and error, I found that we also need to disable the mod: VHR - Vanilla Hair Replacer - Disabling these two mods will render you out of support for the modlist because you have modified the modlist, but we're likely way out of support from the author by running under Linux in the first place :) 

It's a shame to lose what these mods bring to the modlist, and perhaps there are ways to get them working in future. Open to any help on narrowing down what would be required to allow those mods to function.

You can use the filter text box at the bottom of MO2 to find the mods in question, and then click to untick.

Face Discoloration Fix:

![image](https://user-images.githubusercontent.com/110171124/181570341-34ec4a80-94c3-4b8f-b639-4e010a2366ad.png)

Repeat for Vanilla Hair Replacer:

![image](https://user-images.githubusercontent.com/110171124/183409625-0f28331a-260d-4cc3-900a-10a342bbc873.png)

#### Journey

With the above NPC Voice fix in place, I didn't need to carry out any more steps. It 'just worked'.

---

At last!

With NPC Voices fixed, and any ModList-specific fixes from above applied, we should now be ready! Click the Play button in Mod Organizer, and wait. This took quite a bit of time on my laptop. So long, in fact, that I thought it had crashed and I started killing processes etc. But just wait... It took my laptop a full 2 minutes for the Skyrim window to appear, and then another 30-40 seconds for the main menu choices to appear. On SteamDeck, it took approximately 3 minutes and 45 seconds before I could interact with the in-game menu. Once it had loaded though, performance was good in the menus, and in-game performance will depend on your system specs and modlist chosen. 

On SteamDeck, I limit FPS and Refresh rate to 40, and it does a pretty good job at maintaining that in Septimus and Journey modlists. Other lists may vary, and I do plan to test more as my time allows. Some users have reported about switching to the Low preset provided with some modlists, which can aid FPS and Battery life, at the expesnve of graphical fidelity. YMMV. I would love to get feedback on performance of various lists, and any tweaks that you made!

Once you have started a new game, please follow any additional steps that the wiki for your chosen modlist asks you to carry out, in terms of mod configuration from inside the game.

As an addition to the disclaimer at the top of this guide, I have no visibility of longer term stability, so, save often, and maybe even make backups of your savegames, just in case ;) 

If you need help with any of the above, or better yet have another fix, tweak or workaround to help get these modlists running on Linux, then please do stop by the channel on the Wabbajack Discord, I should be around so just @ me (@omni).

If you've read this far, then well done! I'd appreciate a Star for this guide, just to show if I'm on the right track. I'm also open to any feedback, positive or negative.

Enjoy!

![image](https://user-images.githubusercontent.com/110171124/181572624-22e6e74c-6117-4a90-88a7-fc6ed5683a06.png)
