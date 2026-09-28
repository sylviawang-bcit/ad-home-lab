# Creates the lab OU structure and department security groups.
# Run on DC01 in an elevated PowerShell window after the domain is created.
Import-Module ActiveDirectory

$domainDN    = (Get-ADDomain).DistinguishedName
$rootDN      = "OU=Lab,$domainDN"
$departments = "HR", "Finance", "IT", "Operations"

function New-OUIfMissing($Name, $Path) {
    if (-not (Get-ADOrganizationalUnit -Filter "Name -eq '$Name'" -SearchBase $Path -SearchScope OneLevel)) {
        New-ADOrganizationalUnit -Name $Name -Path $Path -ProtectedFromAccidentalDeletion $false
        Write-Host "Created OU: $Name"
    }
}

New-OUIfMissing "Lab" $domainDN
foreach ($ou in "Users", "Groups", "Disabled Users") { New-OUIfMissing $ou $rootDN }

foreach ($dept in $departments) {
    New-OUIfMissing $dept "OU=Users,$rootDN"
    if (-not (Get-ADGroup -Filter "Name -eq 'GRP-$dept'")) {
        New-ADGroup -Name "GRP-$dept" -GroupScope Global -GroupCategory Security `
            -Path "OU=Groups,$rootDN" -Description "$dept department staff"
        Write-Host "Created group: GRP-$dept"
    }
}
