# Author: Robert Crawford
# File:   Add-User.ps1
# Date:   03-16-2023
# Group:  NAJR Grp1
# Repo:   <GitHub/GitLab link>
###############################

# Logic for setting required parameters for the new user
function AddUser {
    # Set console background to black
    SetConsoleBackground 

    # Initialize variables to default values when function is called
    $OUDN           = $defaultOUDN
    $FullName       = $null
    $FirstName      = $null
    $LastName       = $null
    $UPN            = $null
    $SamAccountName = $null
    $HomeFolder     = $null
    $ChangePassword = $true
    $AccEnabled     = $false
    $Password       = $null

    do {
        Clear-Host # clear screen
        Write-Host $menus.AddUserBanner -BackgroundColor Black -ForegroundColor Red # print banner
        AddUserMenu # Print add user menu

        $userInput = GetInput
        switch ($userInput) {
            '1' {
                # Set the FullName variable
                $FullName  = Read-Host "Full Name"

                # Some variables can be implicitly set from the Full Name:
                # FirstName, LastName, SamAccountName, and the UPN. 
                # However, we only want to implicitly set empty or null variables.
                # This prevents overwriting variables that the user has explicitly set.
                if ([String]::IsNullOrEmpty($FirstName)) {
                    # First value that preceeds the first space in $FullName
                    $FirstName = $FullName.Split(' ') | 
                    Select-Object -First 1
                }

                if ([String]::IsNullOrEmpty($LastName)) {
                    # Last value that follows the last space in $FullName
                    $LastName = $FullName.Split(' ')  | 
                    Select-Object -Last 1
                }

                if ([String]::IsNullOrEmpty($SamAccountName)) {
                    # First letter of first name + last name
                    $SamAccountName = $FirstName[0]+$LastName
                    
                    # Remove symbols and make the variable 20 characters or less.
                    $SamAccountName = CleanSamAccountName($SamAccountName)
                }

                if ([String]::IsNullOrEmpty($UPN)) {
                    # SamAccountName @ domain FQDN
                    $UPN = "$SamAccountName@$DomainFQDN"             
                }
            }
            '2' {$FirstName      = Read-Host "First Name"}
            '3' {$LastName       = Read-Host "Last Name"}
            '4' {$UPN            = Read-Host "UPN"}
            # Get the SamAccount name from user, remove invalid symbols and make it maximum 20 characters.
            '5' {$SamAccountName = CleanSamAccountName($SamAccountName = Read-Host "Sam Account Name")}
            '6' {$HomeFolder     = Read-Host "Home Folder Path"}
            '7' {$ChangePassword = Toggle($ChangePassword)} # true of false
            '8' {$AccEnabled     = Toggle($AccEnabled)} # true or false
            '9' {$OUDN           = SelectOU} # Call SelectOU function
            '0' {
                # Make sure SamAccountName is set before making a password
                # to verify that the SamAccountName isn't in the password.
                if ([String]::IsNullOrEmpty($SamAccountName)) {
                    Write-Host "Please set the Sam Account Name first."
                    pause
                }
                else {
                    $Password = GetPassword($SamAccountName)
                }
            }
            'C' {
                # Make sure a password is set before creation
                if ([String]::IsNullOrEmpty($Password)) {
                    Write-Host "Please set a password first."
                    pause
                }
                else {
                    CreateUser # Call CreateUser function
                    return AddUser # Return to AddUser function (this function)
                }
            }
        }
    } while ($userInput -ne 'q')
}

# Removes symbols from $SamAccountName and makes it 20 characters.
function CleanSamAccountName ($SamAccountName) {
    # Regular expression to check for any illegal SamAccountName characters
    $rePattern = '[/\\[\]:;\|=?,+\*\?"<>]+'

    # Check for symbols in the $SamAccountName
    if ($SamAccountName -match $rePattern) {
        # remove it from the string
        $SamAccountName = $SamAccountName -replace $rePattern
    }
    
    # Check if the length is greater than 20 characters.
    if ($SamAccountName.length -gt 20) {
        # remove end to make it 20
        $SamAccountName = $SamAccountName.Substring(0, 20)
    }

    return $SamAccountName
}

function GetPassword ($SamAccountName) {
    # Get the password policy
    $PasswordPolicy = Get-ADDefaultDomainPasswordPolicy
    
    do {
        # Store password as secure string
        $Password = Read-Host "Enter a password" -AsSecureString

        # Convert password to plaintext for regex matching.
        $InsecurePassword = ConvertFrom-SecureString $Password -AsPlainText

        # Verify password is long enough
        if ($InsecurePassword.Length -lt $PasswordPolicy.MinPasswordLength) {
            Write-Host "Password must be at least $($PasswordPolicy.MinPasswordLength) characters."
            continue
        }

        # Verify password doesn't contain the SamAccountName
        if ($InsecurePassword -match $SamAccountName) {
            Write-Host "Password can't contain SamAccountName."
            continue
        }

        # If password policy is enabled
        if ($PasswordPolicy.ComplexityEnabled) {
            # Verify password contains one uppercase, one lowercase, one digit, and one special character.
            if (
                     ($InsecurePassword -cmatch "[A-Z\p{Lu}\s]") `
                -and ($InsecurePassword -cmatch "[a-z\p{Ll}\s]") `
                -and ($InsecurePassword -match  "[\d]") `
                -and ($InsecurePassword -match  "[^\w]")
            ) {
                return $Password
            }
            # If password isn't complex enough, print error
            else {
                Write-Host "Password must have one uppercase, one lowercase, one special character, and one number."
            }
        }
        # If password policy isn't enabled
        else {
            return $Password
        }
    } while ($true)
}

# Creates a new user with our configuration.
function CreateUser {
    New-ADUser -Name $FullName `
    -AccountPassword $Password `
    -ChangePasswordAtLogon $ChangePassword `
    -DisplayName $FullName `
    -Enabled $AccEnabled `
    -GivenName $FirstName `
    -SamAccountName $SamAccountName `
    -Surname $LastName `
    -UserPrincipalName $UPN `
    -Confirm
}


# A terrible and scary function that prints a menu
# I made it here instead of the Menus.ps1 folder 
# because it uses variables and logic.
function AddUserMenu {
    Write-Host "+==========================================================================+"
    Write-Host "|                       Add User to: " -NoNewline
    Write-Host "$DomainFQDN"                           -BackgroundColor Black -ForegroundColor Green
    Write-Host "+==========================================================================+"
    Write-Host "|"
    Write-Host "|"                                                                   -NoNewline
    Write-Host "        If you set the Full Name first, most properties will be"     -BackgroundColor Black -ForegroundColor Red
    Write-Host "|"                                                                   -NoNewline
    Write-Host "   automatically filled out for convienience. You can still change"  -BackgroundColor Black -ForegroundColor Red
    Write-Host "|"                                                                   -NoNewline
    Write-Host "                      them individually if desired."                 -BackgroundColor Black -ForegroundColor Red
    Write-Host "|"
    Write-Host "+==========================================================================+"
    Write-Host "|"
    Write-Host "|   1) Full Name: "             -NoNewline
    Write-Host "$FullName"                      -BackgroundColor Black -ForegroundColor Green
    Write-Host "|   2) First Name: "            -NoNewline 
    Write-Host "$FirstName"                     -BackgroundColor Black -ForegroundColor Green
    Write-Host "|   3) Last Name: "             -NoNewline 
    Write-Host "$LastName"                      -BackgroundColor Black -ForegroundColor Green
    Write-Host "|   4) UPN: "                   -NoNewline
    Write-Host "$UPN"                           -BackgroundColor Black -ForegroundColor Green
    Write-Host "|   5) SamAccountName: "        -NoNewline
    Write-Host "$SamAccountName"                -BackgroundColor Black -ForegroundColor Green
    Write-Host "|   6) Home Folder Path: "      -NoNewline
    Write-Host "$HomeFolder"                    -BackgroundColor Black -ForegroundColor Green
    Write-Host "|   7) New Password on Login: " -NoNewline
    if ($ChangePassword) {
        Write-Host "$ChangePassword"            -BackgroundColor Black -ForegroundColor Green
    } else {
        Write-Host "$ChangePassword"            -BackgroundColor Black -ForegroundColor Red
    }
    Write-Host "|   8) Account is Enabled: "    -NoNewline
    if ($AccEnabled) {
        Write-Host "$AccEnabled"                -BackgroundColor Black -ForegroundColor Green
    } else {
        Write-Host "$AccEnabled"                -BackgroundColor Black -ForegroundColor Red
    }
    Write-Host "|   9) OU Distinguished Name: " -NoNewline
    Write-Host "$OUDN"                          -BackgroundColor Black -ForegroundColor Green
    Write-Host "|   0) Password - Is Set: "     -NoNewline
    if ($([String]::IsNullOrEmpty($Password))) {
        Write-Host "$(![String]::IsNullOrEmpty($Password))" -BackgroundColor Black -ForegroundColor Red
    } else {
        Write-Host "$(![String]::IsNullOrEmpty($Password))" -BackgroundColor Black -ForegroundColor Green
    }
    Write-Host "|"
    Write-Host "|   "                           -NoNewline
    Write-Host "C) Create User"                 -BackgroundColor Black -ForegroundColor Green
    Write-Host "|   "                           -NoNewline
    Write-Host "Q) Quit to Main Menu"           -BackgroundColor Black -ForegroundColor Red
    Write-Host "|"
    Write-Host "+==========================================================================+"
    Write-Host ""
}