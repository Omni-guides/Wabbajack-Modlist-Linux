[![Banner](https://github.com/Omni-guides/Wabbajack-Modlist-Linux/blob/main/images/WabbajackModlistsBanner2.png)](https://github.com/Omni-guides/Wabbajack-Modlist-Linux)

<p align="center"><b>Skyrim -</b> 
  <a href="https://github.com/Omni-guides/Wabbajack-Modlist-Linux/wiki/Skyrim:-Septimus">Septimus</a> ·
  <a href="https://github.com/Omni-guides/Wabbajack-Modlist-Linux/wiki/Skyrim-Redoran">Redoran</a> ·
  <a href="https://github.com/Omni-guides/Wabbajack-Modlist-Linux/wiki/Skyrim:-Dragonborn">Dragonborn</a> ·
  <a href="https://github.com/Omni-guides/Wabbajack-Modlist-Linux/wiki/Skyrim-AVO">Animonculory Visual Overhaul</a> ·
  <a href="https://github.com/Omni-guides/Wabbajack-Modlist-Linux/wiki/Skyrim:-Legends-of-the-Frost">Legends of the Frost</a>
</p>

<p align="center"><b>Fallout 4 -</b>
  <a href="https://github.com/Omni-guides/Wabbajack-Modlist-Linux/wiki/Fallout-4:-Welcome-to-Paradise">Welcome to Paradise</a> ·
  <a href="https://github.com/Omni-guides/Wabbajack-Modlist-Linux/wiki/Fallout-4:-MagnusOpus">Magnum Opus (Soon)</a> ·
  <a href="https://github.com/Omni-guides/Wabbajack-Modlist-Linux/wiki/Fallout-4:-LifeintheRuins">Life in the Ruins (Soon)</a>
</p>

<p align="center"><b>Other -</b>
  <a href="https://github.com/Omni-guides/Wabbajack-Modlist-Linux/wiki">Home</a> ·
  <a href="https://github.com/Omni-guides/Wabbajack-Modlist-Linux/wiki/General-Linux-Guide">General Linux</a> ·
  <a href="https://github.com/Omni-guides/Wabbajack-Modlist-Linux/wiki/Troubleshooting">Troubleshooting</a> ·
  <a href="https://github.com/Omni-guides/Wabbajack-Modlist-Linux/wiki/WIP---ENB-&-Reshade-(In-Progress...)">ENB & Reshade (WIP)</a>
  &emsp; &emsp; <b>Discontinued Lists -</b>
  <a href="https://github.com/Omni-guides/Wabbajack-Modlist-Linux/wiki/Withdrawn:--Skyrim-Journey">Journey</a>
</p>

---

DISCLAIMER - I am not affiliated with the Wabbajack group in any way, just a gamer trying to help other gamers. You may be able to get assistance with this guide from the #unofficial-linux-help channel of the main [Official Wabbajack Discord](https://discord.gg/wabbajack), but it may be best to @ me on Discord (@omni). Due to this being an unofficial guide, assistance on this from Wabbajack support directly, or the Modlist developers, is highly unlikely.

[![ko-fi](https://ko-fi.com/img/githubbutton_sm.svg)](https://ko-fi.com/D1D8H8WBD)

***

## Introduction

The contained guides are a work in progress, based mostly on my own tests and collaboration with multiple users posting in the #unofficial-linux-help channel of the [Official Wabbajack Discord](https://discord.gg/wabbajack). With thanks to all involved. Feedback is always welcome.

The steps included have been used to get Wabbajack Modlists running on Linux, but not the Wabbajack application itself. While I do have a method for running Wabbajack via bottles on Linux, I do not recommend it. With the steps in this guide, I have confirmed success with Modlists for Skyrim, Fallout 4, Oblivion and more, and on platforms such as SteamDeck (SteamOS/Arch), Garuda Linux (Arch) and Fedora, though the process should be largely the same for most Linux distros.

Until there is an officially supported version of Wabbajack for Linux, my recommendation is to use a Windows system to run the Wabbajack application and perform the initial download of the Wabbajack Modlist you want to use. I run a small-ish Windows VM on my gaming desktop with the sole purpose of running Wabbajack and to download Wabbajack lists. I then copy the downloaded Modlist folder to my Linux system, and carry out the steps in these guides.

SteamDeck users can follow the Modlist-specific guide below to get step-by-step instructions to get you up and running for your chosen Modlist.

For general Linux systems (i.e. not the SteamDeck), you can follow the steps in the [General Linux](https://github.com/Omni-guides/Wabbajack-Modlist-Linux/wiki/General-Linux-Guide) guide. This guide uses Journey as an example list, but you can replace it with your Modlist of choice, the steps should be largely the same. If you have some issues, you could check the Modlist specific guide in case there are additional steps specific to that Modlist.

Finally, if you're a Modlist developer and you want me to test your Modlist, let me know! Happy gaming!

***

#### Navigation
- [Introduction](https://github.com/Omni-guides/Wabbajack-Modlist-Linux/wiki)  
  - **Skyrim**
    - [Septimus](https://github.com/Omni-guides/Wabbajack-Modlist-Linux/wiki/Skyrim:-Septimus)
    - [Redoran](https://github.com/Omni-guides/Wabbajack-Modlist-Linux/wiki/Skyrim-Redoran)
    - [Dragonborn](https://github.com/Omni-guides/Wabbajack-Modlist-Linux/wiki/Skyrim:-Dragonborn)
    - [Animonculory Visual Overhaul](https://github.com/Omni-guides/Wabbajack-Modlist-Linux/wiki/Skyrim-AVO)
    - [Legends of the Frost](https://github.com/Omni-guides/Wabbajack-Modlist-Linux/wiki/Skyrim:-Legends-of-the-Frost)
  - **Fallout**
    - [Fallout 4 - Welcome to Paradise](https://github.com/Omni-guides/Wabbajack-Modlist-Linux/wiki/Fallout-4:-Welcome-to-Paradise)
    - [Fallout 4 - Magnum Opus (Soon)](https://github.com/Omni-guides/Wabbajack-Modlist-Linux/wiki/Fallout-4:-Magnus-Opus)
    - [Fallout 4 - Life in the Ruins (Soon)](https://github.com/Omni-guides/Wabbajack-Modlist-Linux/wiki/Fallout-4:-Life-in-the-Ruins)
  - **Other**
    - [ENB & Reshade (WIP)](https://github.com/Omni-guides/Wabbajack-Modlist-Linux/wiki/WIP---ENB-&-Reshade-(In-Progress...))
    - [General Linux (Non-SteamDeck)](https://github.com/Omni-guides/Wabbajack-Modlist-Linux/wiki/General-Linux-Guide) 
    - [Troubleshooting](https://github.com/Omni-guides/Wabbajack-Modlist-Linux/wiki/Troubleshooting)
  - **Discontinued Lists**  
    - [Skyrim - Journey](https://github.com/Omni-guides/Wabbajack-Modlist-Linux/wiki/Withdrawn:--Skyrim-Journey)
 

***
