# Skyrim + Wabbajack Modlist + Linux / SteamDeck

#### Introduction

The following guide is a work in progress, based on mutliple users posting in the #unofficial-linux-help channel of the main [Wabbajack Discord](https://discord.gg/wabbajack). With thanks to all involved.

The steps below have been used to get a Wabbajack Skyrim Modlist running on Linux, but not the Wabbajack Appliction itself (yet). I have confirmed success with SteamDeck (Arch), Garuda (Arch) and Fedora, though the process should be largely the same for most distros. 

Until there is a method or version of Wabbajack that runs under Linux, *you will require a Windows system in order to run the Wabbajack application and perform the initial download of the Wabbajack modlist you want to use*. For this example, I used the Septimus 3 modlist. The following steps will use /home/deck as a location to make the guide easier to follow for SteamDeck users, but you can replace that path with the correct path for your environment. You may also want to use a different naming convention if you are likely to have multiple modlists installed at the same time.

DISCLAIMER - I haven't actually had a chance to *play the game at length* with this set up yet, other than getting into the game world after character creation and running about a bit. Too much tweaking and getting this running in the first placeso far.

---

### For All Modlists

The following steps are required no matter which modlist you are going to run. There are sections near the end for modlist-specific fixes that I have found so far. Please do try your own, and report back any fixes/tweaks you find. I should be around in the Wabbajack Discord.

Once Wabbajack has successfully completed the download and installation of the modlist on Windows, create a new directory on the Linux system/SteamDeck to house the required files - e.g. /home/deck/Skyrim. Currently I have not found a way to have this run from the SD Card, but I will continue to work on that and update accordingly.

Copy the modlist directory from Windows into this new directory (e.g. /home/deck/Skyrim/Septimus3).

ENB will not work under Linux, so you will need to rename the d3d11.dll file in the ModList directory to stop ENB loading when Skyrim is launched.

```
mv /home/deck/Skyrim/Septimus3/Stock\ Game/d3d11.dll /home/deck/Skyrim/Septimus3/Stock\ Game/d3d11.dll.orig
```

Next we need a nifty little program called steam-redirect, which can be found on the same github page as the more general [Linux Mod Organizer 2 installation](https://github.com/rockerbacon/modorganizer2-linux-installer). I chose to build from source. 

Following the few steps outlined for [steam-redirector](https://github.com/rockerbacon/modorganizer2-linux-installer/tree/master/steam-redirector), you need to have the following packages installed to build the steam-redirector binary. To enable the ability to install packages on SteamDeck via pacman, follow [these steps](https://www.reddit.com/r/SteamDeck/comments/t8al0i/install_arch_packages_on_your_steam_deck/): 

```
Fedora: sudo dnf install gcc make mingw64-gcc mingw64-winpthreads-static

Arch (SteamDeck): sudo pacman -S gcc make mingw-w64-gcc mingw-w64-winpthreads
```

Create a directory to temporarily host the source files, download the source of the MO2 Linux installer, and extract it:

```
mkdir /home/deck/mo-source

wget https://github.com/rockerbacon/modorganizer2-linux-installer/archive/refs/tags/4.3.0.tar.gz -P /home/deck/mo-source

cd /home/deck/mo-source

tar -xpzvf /home/deck/mo-source/4.3.0.tar.gz
```

Time to build the source

```
cd /home/deck/mo-source/modorganizer2-linux-installer-4.3.0/steam-redirector/

make main.exe
```

and then copy the newly created main.exe to our Skyrim created directory (/home/deck/Skyrim), you can call it whatever you want, I went with mo-redirect.exe)

```
cp /home/deck/mo-source/modorganizer2-linux-installer-4.3.0/steam-redirector/main.exe /home/deck/Skyrim/mo-redirect.exe
```

The new mo-redirect.exe app basically points to the real location of your modlist's ModOrganizer.exe and nxmhandler.exe. It does this based on the contents of two files that have to live inside a directory called modorganizer2, and this directory has to exist in the same directory mo-redirect.exe lives. So we need to create a directory, and then create the two files mo-redirect.exe is expecting.

```
mkdir /home/deck/Skyrim/modorganizer2
```

You can use vim, nano or any other text editor you like to create these two files and the correct content, I just used:

```
echo "/home/deck/Skyrim/Septimus3/ModOrganizer.exe" > /home/deck/Skyrim/modorganizer2/instance_path.txt

echo "/home/deck/Skyrim/Septimus3/nxmhandler.exe" > /home/deck/Skyrim/modorganizer2/instance_download_path.txt
```

At this stage, the Skyrim directory should contain the following two directories and one .exe file:

```
modorganizer2  mo-redirect.exe  Septimus3
```

with the modorganizer2 directory containing the two created files:

```
instance_path.txt
instance_download_path.txt
```

Next step is to add mo-redirect to Steam as a non-steam game, edit the properties of it once added, and in the Compatibility tab tick the box for 'Force the use of a specific Steam Play compatibility tool', and then select the Proton version - I chose Proton 7.0-3.

![image](https://user-images.githubusercontent.com/110171124/181563703-484cca11-4c48-438b-ad1c-c332779a242f.png)

Click play on this new entry mo-redirect, and all being well, a little terminal window will appear - this is the steam-redirector doing it's job. The custom modlist splashscreen for MO2 appears and then MO2 itself. If the terminal window just pops up for a second and vanishes, double check the contents of the instance_path.txt and instance_download_path.txt files, and that they are present in the correct directory - e.g. /home/deck/Skyrim/modorganizer2/instances_path.txt

![image](https://user-images.githubusercontent.com/110171124/181574124-776fde2f-35b4-4987-9fed-efc32eda7937.png)

![image](https://user-images.githubusercontent.com/110171124/181574661-c58922a0-09be-4062-b76d-5c99d1394705.png)

Getting close now. Next, we have to ensure that MO2 was pointing to the correct new location for the required executables. In MO2, click the little two-cog icon at the top, which will bring up the Modify Executables window (this icon may differ for some modlists that use custom icon sets)

![image](https://user-images.githubusercontent.com/110171124/181569435-99b953ff-bb0a-4da7-aab8-4e76b5d0f3d6.png)

With the example ModList of Septimus 3, the executable that needs edited is simply called 'Septimus'. This will be different depending on the ModList you have chosen. Change the "Binary" and "Start In" locations to point to the 'Stock Game' directory in the Septimus directory. Due to running this through proton, it will be referenced by being the Z: drive location. So for example, the Septimus entry should have a 'Binary' path of "Z:\home\deck\Skyrim\Septimus3\Stock Game\skse64_loader.exe" and a 'Start In' path of "Z:\home\deck\Skyrim\Septimus3\Stock Game".

![image](https://user-images.githubusercontent.com/110171124/183409643-c45c04e2-7b6c-46d9-bbac-8a7ea0cc4645.png)

There is an issue with missing NPC Voices. Apparently this is an issue with Proton, so it may ultimately be resolved in time without needing these steps. We need to add xact and xact_x64 to the Wine/Proton environment Steam created for mo-redirect.exe. The easiest way to accomplish this is to use protontricks. This can be installed via the Discover store (or via command-line depending on which Linux Distro you run):

![image](https://user-images.githubusercontent.com/110171124/183392721-f4ed554a-8bb7-4cc2-a4b9-29c56b8b5a39.png)

![image](https://user-images.githubusercontent.com/110171124/183392763-f005a96d-4a78-4b7b-9fd1-ba4961126d10.png)

To enable the use of protontricks via the command line, add an alias and then restart the terminal window:

```
echo "alias protontricks='flatpak run com.github.Matoking.protontricks'" >> ~/.bashrc
```

Adding the required packages can be done via the ProtonTricks gui, but perhaps the easiest way is via command line. First, find the APP ID of the Non-Steam Game we added for mo-redirect.exe. In a terminal run:

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

At this stage, the steps required may differ depending on the modlist you have chosen, and the mods that the modlist includes. 

---

### Modlist-specific Steps

#### Septimus 3

There are a couple of extra things I had to do to get Septimus 3 to start without crashing, and function correctly. There is an incompatiblity with one particular mod in Septimus 3 (and likely other Modlists) that was causing the game to crash while loading the main menu - Face Discoloration Fix. However, disabling this mod alone results in the faces of NPCs being discoloured, so after a bit of trial and error, I found that we also need to disable the mod: VHR - Vanilla Hair Replacer - Disabling these two mods will render you out of support for the modlist because you have modified the modlist, but we're likely way out of support from the author by running under Linux in the first place :) 

It's a shame to lose what these mods bring to the modlist, and perhaps there are ways to get them working in future.

You can use the filter text box at the bottom of MO2 to find the mods in question, and then click to untick.

Face Discoloration Fix:

![image](https://user-images.githubusercontent.com/110171124/181570341-34ec4a80-94c3-4b8f-b639-4e010a2366ad.png)

Repeat for Vanilla Hair Replacer:

![image](https://user-images.githubusercontent.com/110171124/183409625-0f28331a-260d-4cc3-900a-10a342bbc873.png)

---

#### Journey

With the above NPC Voice fix in place, I didn't need to carry out any more steps. It 'just worked'.

---

At last!

With NPC Voices fixed, and any ModList-specific fixes from above applied, we should now be ready! Click the Play button in Mod Organizer, and wait. This took quite a bit of time on my laptop. So long that I thought it had crashed and I started killing processes etc. But just wait... It took my laptop a full 2 minutes for the Skyrim window to appear, and then another 30-40 seconds for the main menu choices to appear. On SteamDeck, it took approximately 3 minutes and 45 seconds before I could interact with the in-game menu. Once it had loaded though, performance was good in the menus, and in-game performance will depend on your system specs and modlist chosen. 

On SteamDeck, I limit FPS and Refresh rate to 40, and it does a pretty good job at maintaining that in Septimus and Journey modlists. Other lists may vary, and I do plan to test more as my time allows. Once you have started a new game, please follow any additional steps that the wiki for your chosen modlist asks you to carry out, in terms of mod configuration from inside the game.

As I stated above in the disclaimer, I have no visibility of longer term stability, so, maybe save often, and make backups of your savegames, just in case ;) 

If you need help with any of the above, or better yet have another fix, tweak or workaround to help get these modlists running on Linux, then please do stop by the channel on the Wabbajack discord, I should be around.

![image](https://user-images.githubusercontent.com/110171124/181572624-22e6e74c-6117-4a90-88a7-fc6ed5683a06.png)
