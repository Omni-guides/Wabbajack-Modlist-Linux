# ChangeLog: Wabbajack Proton Install Script

## v0.20 - Refactoring & Restructure

A long time coming, and a fairly comprehensive rewrite of the bash script functionality.

- **Script Modularisation:**
  - Split the script into two clear phases: **Discovery Phase** (detection, user input, environment checks) and **Configuration Phase** (system changes, downloads, registry edits).
  - Introduced a `main` function to orchestrate the flow, improving readability and maintainability.

- **Logging & User Feedback:**
  - Enhanced logging with `log`, `log_section`, and `display` functions for clearer, color-coded user feedback and better log file organization.
  - Added a detection summary before making changes, allowing the user to confirm or abort.

## Detection & Environment Handling

- **Wabbajack Path & Steam AppID:**
  - Improved detection of Wabbajack.exe and Steam AppID, with handling for multiple or missing entries.
  - User is prompted to select the correct entry if multiple are found, with better validation and error messages.

- **Compatdata Path Detection:**
  - More reliable detection of the correct `compatdata` directory, with improved error handling and user guidance.

- **Steam Library Handling:**
  - Enhanced detection and linking of Steam library folders, including Flatpak and SD card support.
  - Symlinking and backup of `libraryfolders.vdf` is now more robust and logged.

## Prefix & Registry Management

- **Registry File Flow:**
  - Registry file URLs reverted to the original, stable GitHub sources.
  - Registry application is now split into two phases (initial and final), matching the successful manual process.
  - Removed the need for individual and unreliable prefix configuration calls via protontricks, by instead using pre-curated .reg files.

- **WebView Installer:**
  - Always downloads and runs the WebView installer in the correct prefix, using the `run_protontricks` wrapper for both native and Flatpak environments.
  - Suppresses all Wine output during installation for a cleaner user experience.

- **.NET Cache Directory:**
  - Ensures the `.cache/dotnet_bundle_extract` directory is created in the correct location, with improved error handling.

## Permissions & Flatpak Support

- **Protontricks Permissions:**
  - Improved Flatpak permission handling, including SD card detection and overrides.
  - Centralised permission logic for easier future updates.

- **Dotfiles Visibility:**
  - Replaced the unreliable individual configuration of this function with the pre-cureated .reg files.

## Cleanup & Robustness

- **Process Cleanup:**
  - Better cleanup of Wine/Proton processes before and after configuration steps.

- **Error Handling:**
  - Centralised error handling with `error_exit` for consistent and informative error messages, making logging better and clearer.

- **User Prompts:**
  - All critical actions are now confirmed with the user before proceeding, reducing the risk of accidental misconfiguration.

## Miscellaneous

- **Launch Option Guidance:**
  - Clear instructions for setting `PROTON_USE_WINED3D=1 %command%` in Steam launch options for best compatibility.

- **Final Output:**
  - Improved final summary and next steps, including troubleshooting tips and Discord support info.

---

**Summary:**  
The refactored script should be more modular, robust, and user-friendly, with improved detection, error handling, and logging. 

---

Original ChangeLog list.
===============

- v0.01 - Initial script structure.
- v0.02 - Added functions for most features
- v0.03 - Completed initial functions
- v0.04 - Added handling of WebP Installer
- v0.05 - Switched out installing WebP in favour of dll + .reg files
- v0.06 - Tidied up some ordering of commands, plus output style differences.
- v0.07 - Replaced troublesome win7/win10 protontricks setting with swapping out .reg files. Also much faster.
- v0.08 - Added listing of Wabbajack Steam entries, with selection, if more than one "Wabbajack" named entry found.
- v0.09 - Initial support for Flatpak Steam libraries
- v0.10 - Better detection of flatpak protontricks (Bazzite has a wrapper that made it look like native protontricks)
- v0.11 - Better handling of the Webview Installer
- v0.12 - Added further support for Flatpak Steam, including override requirement message.
- v0.13 - Fixed incorrect protontricks-launch command for installing Webview using native protontricks.
- v0.14 - Fallback support to curl if wget is not found on the system.
- v0.15 - Add a check/creation of protontricks alias entries, for troubleshooting and future use.
- v0.16 - Replaced Wabbajack.exe and Steam Library detection to instead use shortcuts.vdf and libraryfolders.vdf to extrapolate, removing ambiguity and user input requirement.
- v0.17 - Modified the path related functions to handle spaces in the path name.
- v0.18 - Fixed Wabbajack.exe detection that was causing "blank" options being displayed (e.g if the entry in Steam was left as "Wabbajack.exe" then it would wrongly show up as a blank line.)
- v0.19 - Changed WebView instller download URL.
