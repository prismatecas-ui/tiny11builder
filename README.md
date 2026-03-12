# tiny11builder
*Scripts to build a trimmed-down Windows 11 image - now with a **Native GUI**!*

## 🖥️ New: Tiny11 GUI
Tiny11 builder now features an elegant, responsive native WPF interface! No more typing complex commands or handling execution policies manually.
- **Smart Detection**: Automatically detects language (EN/PT-BR) and mounted drives.
- **Granular Control**: Select exactly which app categories or individual apps to remove via a dedicated "App Customization" window.
- **Real-time Monitoring**: Follow the complete build log directly within the application.
- **Auto-Elevation**: Handles admin privileges and security unblocking automatically after the first run.

---

Also, for the very first time, **introducing tiny11 core builder**! A more powerful script, designed for a quick and dirty development testbed. Just the bare minimum, none of the fluff. 
This script generates a significantly reduced Windows 11 image. However, **it's not suitable for regular use due to its lack of serviceability - you can't add languages, updates, or features post-creation**. tiny11 Core is not a full Windows 11 substitute but a rapid testing or development tool, potentially useful for VM environments.

---

## ⚠️ Script versions:
- **tiny11maker.ps1** : The regular script, which removes a lot of bloat but keeps the system serviceable. You can add languages, updates, and features post-creation. This is the recommended script for regular use.
- ⚠️ **tiny11coremaker.ps1** : The core script, which removes even more bloat but also removes the ability to service the image. You cannot add languages, updates, or features post-creation. This is recommended for quick testing or development use.

## Instructions:

### 🚀 Recommended: Using the GUI
1. Mount the Windows 11 ISO image.
2. Right-click **`Tiny11Gui.ps1`** and select **Run with PowerShell**.
3. If prompted with a security warning on the first run, press **[R] Run once**.
4. Select your source drive, choose the build engine (regular or core), and customize your apps.
5. Click **Optimize ISO** and wait for completion.

### 💻 Advanced: Using Command Line
1. Mount the Windows 11 ISO image.
2. Open **PowerShell 5.1** as Administrator. 
3. Start the script:
```powershell
./tiny11maker.ps1 -ISO <letter> -ImageIndex <number>
``` 
> You can see more options by running `Get-Help ./tiny11maker.ps1`.

---

## 📦 App Management
We now have detailed documentation for all manageable applications:
- 📄 [Detailed App List with IDs](docs/lista_de_apps.md)
- ✅ [Simple App Checklist](docs/lista_simples_apps.txt)

---

## What is removed:
<table>
  <tbody>
    <tr>
      <th>Tiny11maker</th>
      <th>Tiny11coremaker</th>
    </tr>
    <tr>
      <td>
        <ul>
          <li>Clipchamp</li>
          <li>News</li>
          <li>Weather</li>
          <li>Xbox</li>
          <li>GetHelp</li>
          <li>GetStarted</li>
          <li>Office Hub</li>
          <li>Solitaire</li>
          <li>PeopleApp</li>
          <li>PowerAutomate</li>
          <li>ToDo</li>
          <li>Alarms</li>
          <li>Mail and Calendar</li>
          <li>Feedback Hub</li>
          <li>Maps</li>
          <li>Sound Recorder</li>
          <li>Your Phone</li>
          <li>Media Player</li>
          <li>QuickAssist</li>
          <li>Internet Explorer</li>
          <li>Tablet PC Math</li>
          <li>Edge</li>
          <li>OneDrive</li>
        </ul>
      </td>
      <td>
        <ul>
          <li>all from regular tiny +</li>
          <li>Windows Component Store (WinSxS)</li>
          <li>Windows Defender (only disabled, can be enabled back if needed)</li>
          <li>Windows Update (wouldn't work without WinSxS, enabling it would put the system in a state of failure)</li>
          <li>WinRE</li>
        </ul>
      </td>
    </tr>
  </tbody>
</table>

Keep in mind that **you cannot add back features in tiny11 core**! <br>
You will be asked during image creation if you want to enable .net 3.5 support!

---

## Known issues:
- Although Edge is removed, there are some remnants in the Settings, but the app in itself is deleted. 
- You might have to update Winget before being able to install any apps, using Microsoft Store.
- Outlook and Dev Home might reappear after some time. This is an ongoing battle, though the latest script update tries to prevent this more aggressively.
- If you are using this script on arm64, you might see a glimpse of an error while running the script. This is caused by the fact that the arm64 image doesn't have OneDriveSetup.exe included in the System32 folder.

---

## Features and Roadmap:
- [x] **Native GUI Interface** (New!)
- [x] **Automated Security Unblocking** (New!)
- [x] **Disable Telemetry** (Implemented!)
- [x] **Ad Suppression** (Implemented!)
- [x] **Multilingual Support** (Detected automatically!)
- [x] **Granular App Removal** (Implemented via GUI!)
- [ ] Improved architecture detection

And that's pretty much it for now!
## ❤️ Support the Project

If this project has helped you, please consider showing your support! A small donation helps me dedicate more time to projects like this.
Thank you!

**[Patreon](http://patreon.com/ntdev) | [PayPal](http://paypal.me/ntdev2) | [Ko-fi](http://ko-fi.com/ntdev)**
Thanks for trying it and let me know how you like it!
