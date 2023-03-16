# Author: Robert Crawford
# File:   Manage-AD.ps1
# Date:   03-16-2023
# Group:  NAJR Grp1
# Repo:   <GitHub/GitLab link>
###############################


# Console configuration to make everything look pretty.
function SetConsoleBackground {
    $Host.UI.RawUI.BackgroundColor = "Black"
}

# Global variables for other functions
$DomainFQDN   = (Get-CimInstance -Class Win32_ComputerSystem).Domain   # Set the domain FQDN   > domain.suffix
$Domain       = $DomainFQDN.Split('.') | Select-Object -First 1        # Set the domain prefix > [domain].suffix
$DomainSuffix = $DomainFQDN.Split('.') | Select-Object -Last 1         # Set the domain suffix > domain.[suffix]
$DefaultOUDN  = "OU=UsersManaged,DC=$Domain,DC=$DomainSuffix"          # Set the default OU DN to UsersManaged

function SelectOU {
    $ous = Get-ADOrganizationalUnit -Filter * | # Store a list of OU's in $ous
    Select-Object -Property DistinguishedName   # Store only the distinguished names.
    
    $UserInput = Read-Host "Would you like to use a GUI to select the OU? (y/n)"
    
    # If yes, open a GUI.
    if ($UserInput -like "y*") {  
        # Pipe the OU's in $ous into Out-GridView which opens a GUI interface
        # -OutputMode single only allows a single OU to be selected.
        # Pipe the object returned by Out-GridView to Select-Object
        # so we can store the DistinguishedName of the object in $OUDN
        $OUDN = $ous |
        Out-GridView -Title "Select an Organizational Unit" -OutputMode Single |
        Select-Object -ExpandProperty DistinguishedName
    }

    # If no, choose an OU with shell
    elseif ($UserInput -like "n*") {
        Clear-Host

        # Loop through all the OU DN's in $ous and display it with a number for selection.
        for ($i = 0; $i -lt $ous.Count; $i++) {
            Write-Host "$($i)) $($ous[$i].DistinguishedName)"
        }

        $ouSelection = Read-Host "Enter the number of the OU you'd like to select"
        
        # If the number is a valid selection
        if ($ouSelection -ge 0 -and $ouSelection -lt $ous.Count) {
            $OUDN = $ous[$ouSelection].DistinguishedName # Store the selected OU DN in $OUDN
        }

        # If the number is invalid
        else {
            Write-Host "Sorry, $ouSelection is not a valid number. Please try again." # Print error
            pause # Pause so user can see error.
        }
    }

    # Else, we don't know what to do.
    else {
        Write-Host "Sorry, I don't know what $UserInput means. Please try again."
        pause # Pause so user can see error.
    }

    return $OUDN
}

# Returns the negated boolean value
function Toggle($BooleanValue) {
    return !($BooleanValue)
}

# A simple wrapper function for Read-Host
function GetInput {
    return Read-Host "Enter a selection"
}

# A secondary menu for managing groups
function ManageGroups {
    do {
        Clear-Host
        Write-Host $menus.EditGroupBanner -BackgroundColor Black -ForegroundColor Red
        Write-Host $menus.EditGroupMenu

        $userInput = GetInput
        switch ($userInput) {
            '1' {AddGroup} # Call AddGroup function in Add-Group.ps1
            '2' {EditGroup} # Call AddToGroup function in AddTo-Group.ps1
        }
    } while ($userInput -ne 'q')
}

function Main {
    # Set console background to black
    SetConsoleBackground

    # Store our $menus from .\Menus.ps1
    $menus = .\Menus.ps1
    
    # Dot-source required files.
    . .\Add-User
    . .\Add-Group
    . .\Edit-Group

    do {
        Clear-Host
        Write-Host $menus.ManageADBanner -BackgroundColor Black -ForegroundColor Red
        Write-Host $menus.MainMenu

        $userInput = GetInput
        switch ($userInput) {
            '1' {AddUser} # Call AddUser function in Add-User.ps1
            '2' {ManageGroups} # Call secondary menu (ManageGroups function)
            'q' {Clear-Host ; return}
        }
    } while ($userInput -ne 'q')
}

Main