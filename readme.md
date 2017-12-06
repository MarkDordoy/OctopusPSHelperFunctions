#Octopus Custom Functions
These are some handy helper functions I've written when querying the Octopus API 

I'd recommend cloning the repo then updating your powershell profile to include the path so they load automatically.
```
$env:PSModulePath = $env:PSModulePath + ";C:\GitWork\OctopusCustomFunctions"
```

This readme might not always be kept up to date, but at time of writing it has the following functions: 
```
ConvertTo-CommaSeperatedList
Get-OctopusEnvironments
Get-OctopusMachineByCenturylinkName
Get-OctopusMachinesByThumbprint
Get-OctopusMachinesInSpecificEnvironment
Get-OctopusMachinesInSpecificRole
Get-OctopusMachinesInSpecificRoleAndEnvironment
Get-OctopusProjectIDByName
Get-OctopusAPIHeader
Get-OctopusDNSName
```

All functions have help comments to give more details around what they can do

You can set User variables for your Octopus API key and the Octopus DNS name so you dont need to pass them all the time.
You can do this as follows:

```
[Environment]::SetEnvironmentVariable("_OctopusAPI", "API-2143213214", "User")
[Environment]::SetEnvironmentVariable("_octopusDNS", "octopus.mydomain.com", "User")
```

Alternatively you can just pass the values in manually when you run the command

ToDo:
Add Pester Testing for all functions
