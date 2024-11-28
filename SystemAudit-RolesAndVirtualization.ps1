# Outputs
$rolesString = "Not Audited"
# Get OS information
$osInfo = Get-CimInstance -ClassName Win32_OperatingSystem
$computerSystem = Get-WmiObject -Class Win32_ComputerSystem

# Check if OS is a server variant
if ($osInfo.ProductType -eq 2 -or $osInfo.ProductType -eq 3) {
    
    # Import the ServerManager module
    Import-Module ServerManager

    # Get and output installed roles
    $installedRoles = Get-WindowsFeature | Where-Object { $_.InstallState -eq 'Installed' -and $_.FeatureType -eq 'Role' }

    # Initialize rolesString as an empty string
    $rolesString = ""

    # If roles are installed, join their display names into a single string
    if ($installedRoles) {
        $rolesString = ($installedRoles | ForEach-Object { $_.DisplayName }) -join ', '
    } 

    # Check for SQL Server services
    $sqlServices = Get-Service -Name 'MSSQL*' -ErrorAction SilentlyContinue
    
    # Check if any SQL services were found and append "SQL Server" if applicable
    if ($sqlServices -ne $null) {
        if ([string]::IsNullOrWhiteSpace($rolesString)) {
            $rolesString = "SQL Server"
        } else {
            $rolesString += ', SQL Server'
        }
    }

    # If $rolesString is still empty, assign "No Roles Installed"
    if ([string]::IsNullOrWhiteSpace($rolesString)) {
        $rolesString = "No Roles Installed"
    }

	#Add the Tag Server for servers
    if ([string]::IsNullOrWhiteSpace($rolesString)) {
        $rolesString = "Server"
    } else {
        $rolesString += ', Server'
    }

} else {
    $rolesString = "Workstation"
}

	# Determine if the system is Physical or Virtual (VMware and Hyper-V)
	if ($computerSystem.Manufacturer -like "*VMware*") {
        if ([string]::IsNullOrWhiteSpace($rolesString)) {
            $rolesString = "VMware virtual machine"
        } else {
            $rolesString += ', VMware virtual machine'
        }
	} elseif ($computerSystem.Manufacturer -like "*Microsoft*" -and $computerSystem.Model -like "*Virtual Machine*") {
        if ([string]::IsNullOrWhiteSpace($rolesString)) {
            $rolesString = "Hyper-V virtual machine"
        } else {
            $rolesString += ', Hyper-V virtual machine'
        }
	} else {
         if ([string]::IsNullOrWhiteSpace($rolesString)) {
            $rolesString = "Physical machine"
        } else {
            $rolesString += ', Physical machine'
        }
	}

#This call performs an implicit string conversion. To see what is actually set in
#the variable, uncomment the following line and look at the script output
#"$rolesString"
Start-Process -FilePath "$env:RMM_HOME\CLI.exe" -ArgumentList ("setVariable rolesString ""$rolesString""") -Wait

