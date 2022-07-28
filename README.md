# Skyrim + Wabbajack Modlist + Linux (+Deck?)
A combination of posts from the Wabbjack Discord that I used to get WJ modlists running under Linux. This may also work on the SteamDeck, but I dont have mine yet to test with.

## THIS IS A WORK IN PROGRESS

After following [steps taken by Wabbajack discord user @Pine](https://discord.com/channels/605449136870916175/839082262552510484/1001667720267440148) I performed the following on my Linux laptop (Fedora) and also on my Linux Desktop (Garuda) to get this working via Steam. The process should be largely the same for most distros. 
Until there is a method or version of Wabbajack that runs under Linux, for this you require a Windows system to run the Wabbajack application and perform the initial download of the Wabbajack modlist you want to use. For this example, I used the Septimus 3 modlist.

DISCLAIMER - I haven't actually *played the game* with this set up yet, other than getting into the game world after character creation and running about a bit.

Once Wabbajack had successfully completed the download of the Septimus 3 modlist, I created a new directory on my Linux system to house the required files - e.g. /home/omni/Skyrim

Copy the modlist directory from Windows into this new directory (/home/omni/Skyrim/Skyrim-Septimus3)

ENB will not work under Linux, so I went into the Septimus 3 directory and renamed the d2d11.dll file to stop ENB loading when Skyrim is launched.

Next we need a nifty little program called steam-redirect, which can be found on the same github page as the more general [Linux Mod Organizer 2 installation](https://github.com/rockerbacon/modorganizer2-linux-installer). I chose to build from source.

Following the few steps outlined for [steam-redirector](https://github.com/rockerbacon/modorganizer2-linux-installer/tree/master/steam-redirector), you need to have the following packages installed to build the steam-redirector binary: 

```
Fedora: sudo dnf install gcc make mingw64-gcc mingw64-winpthreads-static

Arch (Deck?): sudo pacman -S gcc make mingw-w64-gcc mingw-w64-winpthreads
```

Next, I made a directory to temporarily host the files, downloaded the source of the MO2 Linux installer, and extracted it:

```
mkdir /home/omni.mo-source

wget https://github.com/rockerbacon/modorganizer2-linux-installer/archive/refs/tags/4.3.0.tar.gz -P /home/omni/mo-source

cd /home/omni/mo-source

tar -xpzvf /home/omni/mo-source/4.3.0.tar.gz
```

Time to build the source

```
cd /home/omni/mo-source/modorganizer2-linux-installer-4.3.0/steam-redirector/

make main.exe
```

and then copy the newly created main.exe to our Skyrim created directory (/home/omni/Skyrim), you can call it whatever you want, I went with mo-redirect.exe)

```
cp /home/omni/mo-source/modorganizer2-linux-installer-4.3.0/steam-redirector/main.exe /home/omni/Skyrim/mo-redirect.exe
```

The new mo-redirect.exe app basically points to the real location of your modlist's ModOrganizer.exe and nxmhandler.exe. It does this based on the contents of two files that have to live inside a directory called modorganizer2, and this directory has to exist in the same directory mo-redirect.exe lives. So we need to create a directory, and then create the two files mo-redirect.exe is expecting.

```
mkdir /home/omni/Skyrim/modorganizer2
```

You can use vim, nano or any other text editor you like to create these two files and the correct content, I just used:

```
echo "/home/omni/Skyrim/Skyrim-Septimus3/ModOrganizer.exe" > /home/omni/Skyrim/modorganizer2/instance_path.txt

echo "/home/omni/Skyrim/Skyrim-Septimus3/nxmhandler.exe" > /home/omni/Skyrim/modorganizer2/instance_download_path.txt
```

At this stage, the Skyrim directory should contain the following two directories and one .exe file:

```
modorganizer2  mo-redirect.exe  Skyrim-Septimus3
```

with the modorganizer2 directory containing the two created files:

```
instance_path.txt
instance_download_path.txt
```

Next step was to add mo-redirect to Steam as a non-steam game, edit the properties of it once added, and in the Compatibility tab tick the box for 'Force the use of a specific Steam Play compatibility tool', and then select the Proton version - I chose Proton 7.0-3.

![image](https://user-images.githubusercontent.com/110171124/181563703-484cca11-4c48-438b-ad1c-c332779a242f.png)

Click play on this new entry mo-redirect, and all being well, a little terminal window will appear - this is the steam-redirector doing it's job. The custom modlist splashscreen for MO2 appears and then MO2 itself. 

![image](https://user-images.githubusercontent.com/110171124/181574124-776fde2f-35b4-4987-9fed-efc32eda7937.png)

![image](https://user-images.githubusercontent.com/110171124/181574661-c58922a0-09be-4062-b76d-5c99d1394705.png)

Getting close now, but a couple of extra things I had to do to get the game to start without crashing. First, I had to ensure that MO2 was pointing to the correct new location for things like skse_loader.exe, SkyrimSE.exe, SkyrimSELauncher.exe and so on. In MO2, click the little two-cog icon at the top, which will bring up the Modify Executables window. 

![image](https://user-images.githubusercontent.com/110171124/181569435-99b953ff-bb0a-4da7-aab8-4e76b5d0f3d6.png)

I only updated 4 of these to point to the new location, though it may only actually require the first one (Septimus, in this example), though, unless you want to have the option to launch the others from MO2. Basically for each of Septimus, Skyrim Special Edition, Skyrim Special Edition Launcher and SKSE, I changed the "Binary" and "Start In" locations to point to the 'Stock Game' directory in my Septimus directory. Due to running this through proton, it will be referenced by being the Z: drive location. So for example, the Septimus entry should have a 'Binary' path of "Z:\home\omni\Skyrim\Skyrim-Septimus3\Stock Game\skse64_loader.exe" and a 'Start In' path of "Z:\home\omni\Skyrim\Skyrim-Septimus3\Stock Game".

![image](https://user-images.githubusercontent.com/110171124/181573956-5424bb8c-7ea6-4267-9a69-e01cdcd8aa2d.png)

I did this for the other entries I listed above - but even those other 3 it may not be needed unless you speficially want to run that executable from within MO2 (I was using the SkyrimSELauncher.exe for testing).

Lastly, there was one particular mod in Septimus 3 (and likely others) that was causing the game to crash while loading the main menu - Face Discoloration Fix. Thanks again to @Pine for pointing to this mod as a possible culprit, as it save a lot of troubleshooting! This particular mod will have to be unticked in MO2 - Doing this will render you out of support for the modlist because you have modified the modlist, but we're likely way out of support from the author by running under Linux in the first place :) 

You can use the filter text box at the bottom of MO2 to find it, and then click to untick:

![image](https://user-images.githubusercontent.com/110171124/181570341-34ec4a80-94c3-4b8f-b639-4e010a2366ad.png)

With that mod unclicked, click the Play button and wait. This took quite a bit of time on my laptop. So much so that I thought it had crashed and started killing processes etc. But just wait. It took my system a full 2 minutes for the Skyrim window to appear, and then another 30-40 seconds for the main menu choices to appear. Once it had loaded though, performance was good in the menus, and in-game performance will depend on your system specs and modlist chosen. Once the game has started, please follow any additional steps that the wiki for your chosen modlist asks you to carry out, in terms of mod configuration etc from inside the game.

As I stated above in the disclaimer, I have no visibility of longer term stability, so, maybe save often, and make backups of your savegames, just in case ;) Once the 

![image](https://user-images.githubusercontent.com/110171124/181572624-22e6e74c-6117-4a90-88a7-fc6ed5683a06.png)
