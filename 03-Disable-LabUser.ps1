# Offboarding: disables an account, removes group access, and moves it to "Disabled Users".
# Usage: .\03-Disable-LabUser.ps1 -SamAccountName echen -Ticket "REQ-1002"
param(
    [Parameter(Mandatory)][string]$SamAccountName,
    [string]$Ticket  = "N/A",
    [string]$LogPath = ".\logs\offboarding_log.csv"
)
Import-Module ActiveDirectory

$disabledOU = "OU=Disabled Users,OU=Lab,$((Get-ADDomain).DistinguishedName)"
New-Item -ItemType Directory -Force -Path (Split-Path $LogPath) | Out-Null

$status = "Disabled"; $note = ""
try {
    $user   = Get-ADUser -Identity $SamAccountName -Properties MemberOf -ErrorAction Stop
    $groups = @($user.MemberOf | ForEach-Object { (Get-ADGroup $_).Name })

    Disable-ADAccount -Identity $user
    foreach ($g in $user.MemberOf) {
        Remove-ADGroupMember -Identity $g -Members $user -Confirm:$false
    }
    Set-ADUser -Identity $user -Description "Disabled $(Get-Date -Format yyyy-MM-dd) - Ticket $Ticket"
    Move-ADObject -Identity $user.DistinguishedName -TargetPath $disabledOU

    $note = "Removed from: " + ($groups -join "; ")
    Write-Host "Offboarded $SamAccountName. $note"
}
catch {
    $status = "Failed"; $note = $_.Exception.Message
    Write-Warning "Offboarding failed for $SamAccountName : $note"
}

[pscustomobject]@{
    Timestamp      = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    Action         = "Offboard"
    SamAccountName = $SamAccountName
    Ticket         = $Ticket
    Status         = $status
    Note           = $note
} | Export-Csv $LogPath -Append -NoTypeInformation
