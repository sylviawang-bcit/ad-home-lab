# Active Directory Home Lab & User Lifecycle Automation

A simulated enterprise Windows domain used to practise IT administration tasks:
user onboarding and offboarding, access provisioning, and documentation.

## Environment
- Windows Server 2022 domain controller (DC01) on AWS EC2
- Domain: corp.sylvialab.local (AD DS + DNS)

## Scripts
| Script | Purpose |
|---|---|
| `01-setup-ous-groups.ps1` | Creates the Lab OU structure and department security groups |
| `02-New-LabUsers.ps1` | Onboarding: creates accounts from `new_hires.csv`, assigns department groups, forces password change at first logon, logs results |
| `03-Disable-LabUser.ps1` | Offboarding: disables the account, removes group memberships, moves it to Disabled Users, logs the ticket number |

## OU structure
```
Lab
├── Users
│   ├── HR
│   ├── Finance
│   ├── IT
│   └── Operations
├── Groups          (GRP-HR, GRP-Finance, GRP-IT, GRP-Operations)
└── Disabled Users
```

## SOPs
- [ ] SOP-01 New user account provisioning
- [ ] SOP-02 User offboarding
- [ ] SOP-03 Password reset

## Roadmap
- [ ] Domain-joined Windows client
- [ ] Asset inventory script
- [ ] Daily health-check script (disk, services, updates)
