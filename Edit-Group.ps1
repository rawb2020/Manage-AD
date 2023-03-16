# Author: Robert Crawford
# File:   Edit-Group.ps1
# Date:   03-16-2023
# Group:  NAJR Grp1
# Repo:   <GitHub/GitLab link>
###############################

function EditGroup {
    # Set console background to black
    SetConsoleBackground

    # Initializing variables
    $GroupName = "group"
    $User      = "user"

    do {
        Clear-Host
        Write-Host $menus.EditGroupBanner -BackgroundColor Black -ForegroundColor Red
        EditGroupMenu # Call AddToGroupMenu function

        $userInput = GetInput
        switch ($userInput) {
            '1' {$GroupName = SelectGroup}
            '2' {$User      = SelectUser}
            'A' {
                AddUserToGroup
                return EditGroup
            }
            'R' {
                RemoveUserFromGroup
                return EditGroup
            }
        }

    } while ($userInput -ne 'q')
}

# A function to select a Group
function SelectGroup {
    $groups = Get-ADGroup -Filter * |
    Select-Object -Property SamAccountName

    $UserInput = Read-Host "Would you like to use a GUI to select the Group? (y/n)"
    
    # If yes, open a GUI.
    if ($UserInput -like "y*") {  
        # Same idea as SelectOU in Manage-AD.ps1
        $Group = $groups |
        Out-GridView -Title "Select a Group" -OutputMode Single |
        Select-Object -ExpandProperty SamAccountName
    }

    elseif ($UserInput -like "n*") {
        Clear-Host

        # Loop through all the Group SamAccountNames in $groups and display it with a number for selection.
        for ($i = 0; $i -lt $groups.Count; $i++) {
            Write-Host "$($i)) $($groups[$i].SamAccountName)"
        }

        $groupSelection = Read-Host "Enter the number of the Group you'd like to select"
        
        # If the number is a valid selection
        if ($groupSelection -ge 0 -and $groupSelection -lt $groups.Count) {
            $Group = $groups[$groupSelection].SamAccountName # Store the selected Group SamAccountName in $Group
        }

        # If the number is invalid
        else {
            Write-Host "Sorry, $groupSelection is not a valid number. Please try again." # Print error
            pause # Pause so user can see error.
        }
    }

    # Else, we don't know what to do.
    else {
        Write-Host "Sorry, I don't know what $UserInput means. Please try again."
        pause # Pause so user can see error.
    }

    return $Group
}

# A function to select a user
function SelectUser {
    $users = Get-ADUser -Filter * |
    Select-Object -Property SamAccountName

    $UserInput = Read-Host "Would you like to use a GUI to select the User? (y/n)"
    
    # If yes, open a GUI.
    if ($UserInput -like "y*") {  
        # Same idea as SelectGroup function above
        $User = $users |
        Out-GridView -Title "Select a User" -OutputMode Single |
        Select-Object -ExpandProperty SamAccountName
    }

    elseif ($UserInput -like "n*") {
        Clear-Host

        # Loop through all the Group SamAccountNames in $groups and display it with a number for selection.
        for ($i = 0; $i -lt $users.Count; $i++) {
            Write-Host "$($i)) $($users[$i].SamAccountName)"
        }

        $userSelection = Read-Host "Enter the number of the User you'd like to select"
        
        # If the number is a valid selection
        if ($userSelection -ge 0 -and $userSelection -lt $users.Count) {
            $User = $users[$userSelection].SamAccountName # Store the selected Group SamAccountName in $Group
        }

        # If the number is invalid
        else {
            Write-Host "Sorry, $userSelection is not a valid number. Please try again." # Print error
            pause # Pause so user can see error.
        }
    }

    # Else, we don't know what to do.
    else {
        Write-Host "Sorry, I don't know what $UserInput means. Please try again."
        pause # Pause so user can see error.
    }

    return $User
}

function AddUserToGroup {
    Add-ADGroupMember -Identity $GroupName `
    -Members $User `
    -Confirm
}

function RemoveUserFromGroup {
    Remove-ADGroupMember -Identity $GroupName `
    -Members $User `
    -Confirm
}

function EditGroupMenu {
    Write-Host "+==========================================================================+"
    Write-Host "|                Add/Remove" -NoNewline
    Write-Host " $user "                     -BackgroundColor Black -ForegroundColor Green -NoNewLine
    Write-Host "to/from: "                   -NoNewline
    Write-Host "$GroupName"                  -BackgroundColor Black -ForegroundColor Green
    Write-Host "+==========================================================================+"
    Write-Host "|"
    Write-Host "|   1) Select Group: "        -NoNewline
    if ($GroupName -like "group") {
        Write-Host ""                 
    } else {
        Write-Host "$GroupName"               -BackgroundColor Black -ForegroundColor Green
    }
    Write-Host "|   2) Select User: "         -NoNewline 
    if ($User -like "user") {
        Write-Host ""
    } else {
        Write-Host "$User"                    -BackgroundColor Black -ForegroundColor Green
    }
    Write-Host "|"
    Write-Host "|" -NoNewLine
    Write-Host "   A) Add User To Group"      -BackgroundColor Black -ForegroundColor Green
    Write-Host "|"                            -NoNewline
    Write-Host "   R) Remove User From Group" -BackgroundColor Black -ForegroundColor DarkRed
    Write-Host "|"
    Write-Host "|"                            -NoNewline
    Write-Host "   Q) Quit to Main Menu"      -BackgroundColor Black -ForegroundColor Red
    Write-Host "|"
    Write-Host "+==========================================================================+"
    Write-Host ""
}