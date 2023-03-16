# Manage-AD

An over complicated and convoluted script to manage Active Directory users and groups. I got a little carried away and assume there's like 1000 other ways to make this less complicated and much better structured but if I'm being honest I have no idea how to script in PowerShell. However, this was great fun and great practice.

# Prerequisites

- PowerShell 7.3.2
- ActiveDirectory PowerShell Module.
- Lack of sanity

# Configuration

1. Download all the script files and store them in the same directory. 
2. Execute `Manage-AD.ps1` and everything should (hopefully) work fine.

# Script Structure

### Menus.ps1

This file holds strings that represent banners and menus to make the already large spaghetti script files just a little bit more bearable.

### Manage-AD.ps1

This is the 'main' file. The script execution starts here and branches off to the other script files depending on what the user wants to do. I've also included functions that are required by multiple script files in here. Why? I don't know.

### Add-User.ps1

This file holds everything relating to creating a new Active Directory user. This is the "first option" in my script main menu. It also contains a Menu function because I couldn't figure out how to display variables in the `Menus.ps1` custom object.

### Add-Group.ps1

This file holds everything relating to creating a new group in Active Directory.

### Edit-Group.ps1

This file hold everything relating to adding or removing a user from a group in Active Directory.
