# Enable Full Screen Experience on Windows
## About
This script will take you through the steps required to enable the Full Screen Experience on Windows 11 25H2.

Currently, at the time of this repo's creation, 25H2 is only available through the Windows Insider Program through the "Dev" channel.

## Steps to manually enable

These are the full steps to install and enable the Full Screen Experience. The steps that are automated in this script start after the Windows 11 25H2 update is succesfully installed.

1. **Opt into the Windows Insider Program**
	1. Go to Settings
	2. Click on "Windows Update" on the left panel
	3. Click on "Windows Insider Program"
	4. Click "Get Started"
	5. Sign into a Microsoft account if prompted
    6. Choose the "Dev" channel.
	7. Go through as many rounds of Windows Updates and reboots as required until the Windows 11 25H2 update is available to download and install.
    8. Reboot your device after the download of Windows 11 25H2
2. **Force Enable the Full Screen Experience Settings**
    1. Visit the [ViVe repo](https://github.com/thebookisclosed/ViVe/releases)
    2. Download the "Intel AMD" variation of the ViVeTool ZIP
    3. Extract all files in the ZIP (anywhere is fine)
    4. Click on your Start menu
    5. Find Command Prompt
    6. Right click on Command Prompt and choose "Run as Administrator"
    7. Navigate to the location you have extracted the ViVeTool files using the `cd` command (ex: `cd C:\Users\ScatteredBrain\Downloads\`)
    8. Run the command `ViVeTool.exe /enable /id:52580392`
    9. Run another command `ViVeTool.exe /enable /id:50902630`
    10. Close your Command Prompt
    11. Click on "Start"
    12. Search for "regedit"
    13. Click to open "Registry Editor"
    14. Navigate to the following path: `Computer\HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows NT\CurrentVersion\OEM`
        1. If you do not have `OEM` inside of `CurrentVersion`, create it
    15. Once we're inside of the OEM folder, locate the registry entry `DeviceForm`
    16. Double click on the `DeviceForm` entry and update the value to `46` (or `2e` as hexadecimal)
        1. If you do not have the `DeviceForm` entry, create it by going to New > DWord from the Registry Editor menu, set the name `DeviceForm` and set the value to `46`.
    17. Reboot your device
3. **Turn on Full Screen Experience**
    1. Open the Settings application
    2. Click on the "Gaming" tab on the left panel
    3. Click on the "Full Screen Experience" option
    4. Select the Xbox app as the launcher
    5. Set the Full Screen Experience to start on login
    6. Reboot your device - when you log in, the Xbox Experience should start by default


## Troubleshooting

While not much can be said on workarounds if these steps do not work, u/Gogsi123 has mentioned that possibly changing your device's display scaling could help enable the full screen experience.

Also keep in mind that this is beta software and there will most likely be issues ranging from minor bugs to hardware incompatibility, or even full system crashes.

## Credits

[u/Gogsi123's Original Guide on Reddit](https://www.reddit.com/r/ROGAlly/comments/1niwsfi/guide_for_enabling_the_full_screen_experience_on/)
[thebookisclosed/ViVe](https://github.com/thebookisclosed/ViVe/releases)