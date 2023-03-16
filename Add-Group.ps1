# Author: Robert Crawford
# File:   Add-Group.ps1
# Date:   03-16-2023
# Group:  NAJR Grp1
# Repo:   <GitHub/GitLab link>
###############################

function AddGroup {

    # Initialize variables to default values
    $OUDN             = $defaultOUDN
    $GroupName        = $null
    $GroupDescription = $null
    $GroupCategory    = $true
    $GroupScope       = 0

    do {
        Clear-Host
        Write-Host $menus.AddGroupBanner -BackgroundColor Black -ForegroundColor Red
        AddGroupMenu # Print add user menu

        # Get user input
        $userInput = GetInput
        switch ($userInput) {
            '1' {$GroupName        = Read-Host "Enter a group name"}
            '2' {$GroupDescription = Read-Host "Enter a group description"}
            '3' {$GroupScope       = ChooseScope} # Call ChooseScope function
            '4' {$GroupCategory    = Toggle($GroupCategory)} # Toggle true or false
            '5' {$OUDN             = SelectOU} # Call SelectOU function in Manage-AD.ps1
            'C' {
                # Make sure group name is set
                if ([String]::IsNullOrEmpty($GroupName)) {
                    Write-Host "Please choose a Group name before creating the group"
                    pause
                }
                # Make sure group description is set
                elseif ([String]::IsNullOrEmpty($GroupDescription)) {
                    Write-Host "Please choose a description for the group before creating it."
                    pause
                }
                else {
                    CreateGroup # call CreateGroup function
                    Return AddGroup # return to AddGroup function (this one)
                }
            }
        }
    } while ($userInput -ne 'q')
}

# A function that Creates the group with the configured parameters.
# Uses New-ADGroup
function CreateGroup {

    # Convert boolean to integers.
    switch ($GroupCategory) {
        $true  { $GroupCategory = 1 }
        $false { $GroupCategory = 0 }
    }

    # Create new group
    New-ADGroup -Name $GroupName `
    -GroupScope $GroupScope `
    -Description $GroupDescription `
    -GroupCategory $GroupCategory `
    -Path $OUDN `
    -Confirm
}

# Return an integer value for the scope
function ChooseScope {
    Write-Host "Please choose a group scope below:"
    Write-Host "0. Domain Local"
    Write-Host "1. Global"
    Write-Host "2. Universal"
    Write-Host ""

    # Input validation
    do {
        $GroupScope = GetInput
        switch ($GroupScope) {
            '0' {return 0}
            '1' {return 1}
            '2' {return 2}
        }
    } while ($true)
}

# A terrible and scary function that prints a menu
# I made it here instead of the Menus.ps1 folder 
# because it uses variables and logic.
function AddGroupMenu {
    Write-Host "+==========================================================================+"
    Write-Host "|                       Add Group to: " -NoNewline
    Write-Host "$DomainFQDN"                            -BackgroundColor Black -ForegroundColor Green
    Write-Host "+==========================================================================+"
    Write-Host "|"
    Write-Host "|   1) Group Name: "            -NoNewline
    Write-Host "$GroupName"                     -BackgroundColor Black -ForegroundColor Green
    Write-Host "|   2) Group Description: "     -NoNewline 
    Write-Host "$GroupDescription"              -BackgroundColor Black -ForegroundColor Green
    Write-Host "|   3) Choose Scope: "          -NoNewLine
    if ($GroupScope -eq 0) {
        Write-Host "Domain Local"               -BackgroundColor Black -ForegroundColor Green
    } 
    elseif ($GroupScope -eq 1) {
        Write-Host "Global"                     -BackgroundColor Black -ForegroundColor Blue
    }
    else {
        Write-Host "Universal"                  -BackgroundColor Black -ForegroundColor Red
    }
    Write-Host "|   4) Current Category: "      -NoNewLine
    if ($GroupCategory) {
        Write-Host "Security"                   -BackgroundColor Black -ForegroundColor Green
    } 
    else {
        Write-Host "Distribution"               -BackgroundColor Black -ForegroundColor Red
    }
    Write-Host "|   5) OU Distinguished Name: " -NoNewLine
    Write-Host "$OUDN"                          -BackgroundColor Black -ForegroundColor Green
    Write-Host "|"
    Write-Host "|" -NoNewline
    Write-Host "   C) Create Group"             -BackgroundColor Black -ForegroundColor Green
    Write-Host "|" -NoNewline
    Write-Host "   Q) Quit to Main Menu"        -BackgroundColor Black -ForegroundColor Red
    Write-Host "|"
    Write-Host "+==========================================================================+"
    Write-Host ""
}