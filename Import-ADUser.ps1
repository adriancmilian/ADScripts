<#
#>

function Import-ADUser {
    [cmdletbinding(SupportsShouldProcess)]
    param (
        [parameter(Mandatory = $true, Position = 0)]
        [string]$Csv,

        [parameter(Mandatory = $true, Position = 1)]
        [string]$UPNSuffix,

        [parameter(Mandatory = $true, Position = 2)]
        [string]$OUPath,

        [parameter(Mandatory = $false, Position = 3)]
        [string]$LogPath = ".\ImportedUsers.csv"
    )
 
    Begin {

        $Users = Import-Csv $Csv

    }#Begin

    Process {

        foreach ($User in $Users) {

            $ADUser = Get-ADUser -Filter "displayname -eq '$($User.'Display Name')'"

            if ($null -eq $ADUser) {

                Write-Verbose "Creating random 16 character complex password..."

                $Newpass = ""
                $NewPass = ([char[]]([char]33..[char]95) + ([char[]]([char]97..[char]126)) + 0..20 | Sort-Object {Get-Random})[0..16] -join ''
    
                $Securestring = ConvertTo-SecureString $Newpass -AsPlainText -Force

                Write-Verbose "Changing UPN to utilize new UPN suffix: $UPNSuffix"

                $UPN = $User.'User Logon Name'.split('@')[0] #Removes current UPN suffix
    
                $UPN += $UPNSuffix #Adds UPN suffix specified in parameter
    
    
                #Create Splat table that contains parameters to pass through to the final Add-ADUser command
                $User_Props = @{
                    'Name' = $User.Name
                    'DisplayName' = $User.'Display Name'
                    'SamAccountName' = $User.'Pre-Windows 2000 Logon Name'
                    'UserPrincipalName' = $UPN
                    'AccountPassword' = $Securestring
                    'Path' = $OUPath
                    'Enabled' = $true
                }
    
                if ($null -ne $user.Description) {
                    $User_Props.Add('Description', $user.Description)
    
                }
    
                if ($null -ne $User.'Business Phone') {
                    $User_Props.Add('OfficePhone', $User.'Business Phone')
                }
    
                if ($null -ne $User.City) {
                    $User_Props.Add('City', $User.City)
                }
    
                if ($null -ne $User.Company) {
                    $User_Props.Add('Company', $User.Company)
                }
    
                if ($null -ne $User.'Country/Region') {
                    $User_Props.Add('Country', $User.'Country/Region')
                }
    
                if ($null -ne $User.Department) {
                    $User_Props.Add('Department', $User.Department)
                }
    
                if ($null -ne $User.Office) {
                    $User_Props.Add('Office', $User.Office)
                }
    
                if ($null -ne $User.State) {
                    $User_Props.Add('State', $User.State)
                }
    
                if ($null -ne $User.'Job Title') {
                    $User_Props.Add('Title', $User.'Job Title')
                }

                if ($null -ne $User.'First Name') {
                    $User_Props.Add('Givenname', $User.'First Name')
                }

                if ($null -ne $User.'Last Name') {
                    $User_Props.Add('Surname', $User.'Last Name')
                }

                $UserObj = New-Object -TypeName PSObject -Property $User_Props

                Write-Information "Created new user:"
                Write-Output $UserObj

                New-AdUser @User_Props

                $name = $user.name

                Get-AdUser -Filter 'Name -like $name' | Set-ADObject -ProtectedFromAccidentalDeletion $true

                $ImportedUsers = @{
                    'Name' = $User.Name
                    'SamAccountName' = $User.'Pre-Windows 2000 Logon Name'
                    'UPN' = $UPN
                    'Password' = $Newpass
                }

                $obj = New-Object -TypeName psobject -Property $ImportedUsers
                
                $obj | Export-Csv $LogPath -Append

            }#If
            else {
                Write-Warning "User with the display name $User.Name already exists in AD"
            }
        }#ForEach
    }#Process
    End{}#end
}#Function