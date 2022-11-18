function Get-WifiPassword {
    $WifiSSIDs = New-Object System.Collections.Generic.List[string]
    $netshShowProfiles = netsh wlan show profiles
    $netshShowProfiles | Select-String "\:(.+)$" | ForEach-Object {$WifiSSIDs.Add($_.Matches.Groups[1].Value.Trim())}

    foreach ($SSID in $WifiSSIDs) {
        $netshShowPassword = netsh wlan show profile name="$SSID" key=clear | Select-String "Key Content\W+\:(.+)$"
        if (!($netshShowPassword)) {continue}

        $PasswordValue = $netshShowPassword.Matches.Groups[1].Value.Trim()
        [PSCustomObject]@{
            SSID = $SSID
            Password = $PasswordValue
        }
    }
}

Get-WifiPassword | Format-Table -AutoSize

