# Onboarding: creates AD accounts from a CSV of new hires.
# Usage: .\02-New-LabUsers.ps1 -CsvPath .\new_hires.csv
param(
    [string]$CsvPath = ".\new_hires.csv",
    [string]$LogPath = ".\logs\onboarding_log.csv"
)
Import-Module ActiveDirectory

$domain = Get-ADDomain
$rootDN = "OU=Lab,$($domain.DistinguishedName)"
New-Item -ItemType Directory -Force -Path (Split-Path $LogPath) | Out-Null

function New-TempPassword {
    # Lab use only. In production, use an approved password tool and deliver passwords securely.
    $chars = 'ABCDEFGHJKLMNPQRSTUVWXYZabcdefghijkmnopqrstuvwxyz23456789!@#$%'
    (-join (1..12 | ForEach-Object { $chars[(Get-Random -Maximum $chars.Length)] })) + "Aa1!"
}

$results = foreach ($hire in Import-Csv $CsvPath) {
    $first = $hire.FirstName.Trim()
    $last  = $hire.LastName.Trim()
    $dept  = $hire.Department.Trim()

    # Username = first initial + last name; add a number if it already exists
    $base = (($first.Substring(0, 1) + $last).ToLower()) -replace '[^a-z0-9]', ''
    $sam  = $base; $n = 1
    while (Get-ADUser -Filter "SamAccountName -eq '$sam'") { $n++; $sam = "$base$n" }

    $status = "Created"; $note = ""
    try {
        $tempPassword = New-TempPassword
        New-ADUser -Name "$first $last" -GivenName $first -Surname $last `
            -SamAccountName $sam -UserPrincipalName "$sam@$($domain.DNSRoot)" `
            -DisplayName "$first $last" -Title $hire.Title -Department $dept `
            -Path "OU=$dept,OU=Users,$rootDN" `
            -AccountPassword (ConvertTo-SecureString $tempPassword -AsPlainText -Force) `
            -ChangePasswordAtLogon $true -Enabled $true -ErrorAction Stop
        Add-ADGroupMember -Identity "GRP-$dept" -Members $sam -ErrorAction Stop
        Write-Host "Created $sam ($dept). Temporary password: $tempPassword"
    }
    catch {
        $status = "Failed"; $note = $_.Exception.Message
        Write-Warning "Failed to create $first $last : $note"
    }

    # Passwords are never written to the log
    [pscustomobject]@{
        Timestamp      = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        Action         = "Onboard"
        SamAccountName = $sam
        Name           = "$first $last"
        Department     = $dept
        Status         = $status
        Note           = $note
    }
}

$results | Export-Csv $LogPath -Append -NoTypeInformation
$results | Format-Table Timestamp, SamAccountName, Department, Status -AutoSize
