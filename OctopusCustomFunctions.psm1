$ErrorActionPreference = "Stop"

Function Get-OctopusAPIHeader
{
    <#
    .SYNOPSIS
    Creates an Octopus Authentication header object
        
    .PARAMETER apiKey
    Your API key that gives you access to the Octopus API. This will create the header object
    based on the key you pass, or the default one if set.

    If you dont pass a key it will look for one in the default location of the user environment 
    variable of _OctopusAPI
    
    .EXAMPLE
    Get-OctopusAPIHeader -apiKey "API-123213dsfdf432"
    #>
    [cmdletbinding()]
    param
    (
        [parameter(Mandatory = $false)]
        [string]$apiKey
    )

    if ([string]::IsNullOrEmpty($apiKey))
    {
        if ([environment]::GetEnvironmentVariable("_OctopusAPI", "User")) 
        {
            Write-Verbose "Found default Octopus API Key"
            $apiKey = [environment]::GetEnvironmentVariable("_OctopusAPI", "User")
        }
        else 
        {
            Write-Error "No API key passed and unable to find default"    
        }
    }

    $Authheader = New-Object "System.Collections.Generic.Dictionary[[string],[string]]" 
    $Authheader.Add("X-Octopus-ApiKey", "$apiKey")

    return $Authheader
}

Function Get-OctopusDNSName
{
    <#
    .SYNOPSIS
    Returns an Octopus DNS name
        
    .PARAMETER octopusDNSName

    This function allows you to pass a dns name or get it from the default location of the user 
    environment variable of _OctopusDNS
    
    .EXAMPLE
    Get-OctopusAPIHeader -octopusDNSName "Octopus.mydomain.com"
    #>
    [cmdletbinding()]
    param
    (
        [parameter(Mandatory = $false)]
        [string]$octopusDNSName
    )

    if ([string]::IsNullOrEmpty($octopusDNSName))
    {
        if ([environment]::GetEnvironmentVariable("_octopusDNS", "User")) 
        {
            Write-Verbose "Found default Octopus DNS Name"
            $octopusDNSName = [environment]::GetEnvironmentVariable("_octopusDNS", "User")
        }
        else 
        {
            Write-Error "No Octopus DNS name passed and unable to find default"
        }
    }

    return $octopusDNSName
}

Function Get-OctopusEnvironments
{
    <#
    .SYNOPSIS
    Will return a list of the Octopus Environment IDs and their friendly names
        
    .PARAMETER apiKey
    Your API key that gives you access to the Octopus API
    
    .PARAMETER octopusDNSName
    The DNS name of the octopus server, eg "octopus.mydomain.com"
    
    .EXAMPLE
    Get-OctopusEnvironments -apiKey "API-123213fdsfdsfds" -octopusDNSName "octopus.mydomain.com"
    
    .NOTES
    Returns a key value array.

    If you dont specify and APIkey or dns name it will look for the default values which are user environment variables:
    $apiKey = $env:_OctopusAPI
    $octopusDNSName = $env:__octopusDNS
    #>
    param
    (
        [cmdletbinding()]
        [parameter(Mandatory = $false)]
        $apiKey,
        [parameter(Mandatory = $false)]
        $octopusDNSName
    )

    $authToken = Get-OctopusAPIHeader -apiKey $apiKey
    $octopusDNSName = Get-OctopusDNSName -octopusDNSName $octopusDNSName
    $response = Invoke-RestMethod -Method Get -UseBasicParsing -Uri "$octopusDNSName/api/environments/all" -Headers $authToken

    return $response | ForEach-Object `
    {
        New-Object psobject -Property @{Name = $_.Name; ID = $_.Id}
    }
}

Function Get-OctopusMachinesInSpecificEnvironment
{
    <#
    .SYNOPSIS
    Will get all machines in a specific Environment

    .PARAMETER EnvironmentID
    The Octopus Environment ID, eg: "Environments-25"

    .PARAMETER apiKey
    Your API key that gives you access to the Octopus API

    .PARAMETER octopusDNSName
    The DNS name of the octopus server, eg "octopus.mydomain.com"

    .PARAMETER OnlyEnabledMachines
    This is a switch parameter. If used it will only return machines that are enabled

    .EXAMPLE
    Get-OctopusMachinesInSpecificEnvironment -EnvironmentID "Environments-25" -apiKey "API-324343244323fd" -octopusDNSName "octopus.mydomain.com"

    .Notes
    If you dont specify and APIkey or dns name it will look for the default values which are user environment variables:
    $apiKey = $env:_OctopusAPI
    $octopusDNSName = $env:__octopusDNS

    #>
    param
    (
        [cmdletbinding()]
        [parameter(mandatory = $true)]
        $EnvironmentID,
        [parameter(Mandatory = $false)]
        $apiKey,
        [parameter(Mandatory = $false)]
        $octopusDNSName,
        [switch]$OnlyEnabledMachines
    )

    $authToken = Get-OctopusAPIHeader -apiKey $apiKey
    $octopusDNSName = Get-OctopusDNSName -octopusDNSName $octopusDNSName
    $response = Invoke-RestMethod -Method get -UseBasicParsing -Uri "$octopusDNSName/api/environments/$EnvironmentID/machines" -Headers $authToken

    if ($OnlyEnabledMachines)
    {
        return ($response.Items | Where-Object {$_.IsDisabled -eq $false}).Name
    }
    else
    {
        return ($response.Items | Select-Object -ExpandProperty Name )
    }
}

Function Get-OctopusMachinesInSpecificRole
{
    <#
    .SYNOPSIS
    Will get all machines that are members of a specific role

    .PARAMETER Role
    The name of a role you want to query against, eg "telegraf"
    
    .PARAMETER apiKey
    Your API key that gives you access to the Octopus API

    .PARAMETER octopusDNSName
    The DNS name of the octopus server, eg "octopus.mydomain.com"

    .PARAMETER OnlyEnabledMachines
    This is a switch parameter. If used it will only return machines that are enabled
    
    .EXAMPLE
    Get-OctopusMachinesInSpecificRole -Role "telegraf" -apiKey "API-324343244323fd" -octopusDNSName "octopus.mydomain.com"
    
    .Notes
    If you dont specify and APIkey or dns name it will look for the default values which are user environment variables:
    $apiKey = $env:_OctopusAPI
    $octopusDNSName = $env:__octopusDNS
    #>
    param
    (
        [cmdletbinding()]
        [parameter(mandatory = $true)]
        $Role,
        [parameter(Mandatory = $false)]
        $apiKey,
        [parameter(Mandatory = $false)]
        $octopusDNSName,
        [switch]$OnlyEnabledMachines
    )

    $authToken = Get-OctopusAPIHeader -apiKey $apiKey
    $octopusDNSName = Get-OctopusDNSName -octopusDNSName $octopusDNSName
    $response = Invoke-RestMethod -Method get -UseBasicParsing -Uri "$octopusDNSName/api/machines/all" -Headers $authToken

    if ($OnlyEnabledMachines)
    {
        return ($response | where-object {($_.Roles -contains "$Role") -and ($_.IsDisabled -eq $false)}).Name
    }
    else 
    {
        return ($response | Where-Object {$_.Roles -contains "$Role"}).Name   
    }
}

Function Get-OctopusMachinesInSpecificRoleAndEnvironment
{
    <#
    .SYNOPSIS
    Will get all machines that are members of a specific role and environment
    
    .PARAMETER Role
    Name of role you want to query, eg "telegraf"
    
    .PARAMETER EnvironmentID
    Id of environment you want to query, eg "Environments-25"
    
    .PARAMETER apiKey
    Your API key that gives you access to the Octopus API

    .PARAMETER octopusDNSName
    The DNS name of the octopus server, eg "octopus.mydomain.com"
    
    .PARAMETER OnlyEnabledMachines
    This is a switch parameter. If used it will only return machines that are enabled
    
    .EXAMPLE
    Get-OctopusMachinesInSpecificRoleAndEnvironment -role "telegraf" -EnviromentID "Environments-25" -apiKey "API-243213213123" -octopusDNSName "octopus.mydomain.com"
    
    .Notes
    If you dont specify and APIkey or dns name it will look for the default values which are user environment variables:
    $apiKey = $env:_OctopusAPI
    $octopusDNSName = $env:__octopusDNS

    #>
    param
    (
        [cmdletbinding()]
        [parameter(mandatory = $true)]
        $Role,
        [parameter(mandatory = $true)]
        $EnvironmentID,
        [parameter(Mandatory = $false)]
        $apiKey,
        [parameter(Mandatory = $false)]
        $octopusDNSName,
        [switch]$OnlyEnabledMachines
    )

    $authToken = Get-OctopusAPIHeader -apiKey $apiKey
    $octopusDNSName = Get-OctopusDNSName -octopusDNSName $octopusDNSName
    $response = Invoke-RestMethod -Method get -UseBasicParsing -Uri "$octopusDNSName/api/machines/all" -Headers $authToken

    if ($OnlyEnabledMachines)
    {
        return ($response | Where-Object {$_.Roles -contains "$role" -and $_.environmentIds -contains "$EnvironmentID" -and $_.IsDisabled -eq $false}).Name   
    }
    else
    {
        return ($response | Where-Object {$_.Roles -contains "$role" -and $_.environmentIds -contains "$EnvironmentID"}).Name    
    }
}

Function Get-OctopusMachinesByThumbprint
{
    <#
    .SYNOPSIS
    Will get machine details based on thumbprint

    .PARAMETER Thumbprint
    The thumbprint of the machine
    
    .PARAMETER apiKey
    Your API key that gives you access to the Octopus API

    .PARAMETER octopusDNSName
    The DNS name of the octopus server, eg "octopus.mydomain.com"

    .PARAMETER OnlyEnabledMachines
    This is a switch parameter. If used it will only return machines that are enabled
    
    .EXAMPLE
    Get-OctopusMachinesByThumbprint -thumbprint "544354gfdgfdg43t" -apiKey "API-324343244323fd" -octopusDNSName "octopus.mydomain.com"
    
    .Notes
    If you dont specify and APIkey or dns name it will look for the default values which are user environment variables:
    $apiKey = $env:_OctopusAPI
    $octopusDNSName = $env:__octopusDNS 
    #>
    param
    (
        [cmdletbinding()]
        [parameter(mandatory = $true)]
        $thumbprint,
        [parameter(Mandatory = $false)]
        $apiKey,
        [parameter(Mandatory = $false)]
        $octopusDNSName,
        [switch]$OnlyEnabledMachines
    )

    $authToken = Get-OctopusAPIHeader -apiKey $apiKey
    $octopusDNSName = Get-OctopusDNSName -octopusDNSName $octopusDNSName
    $response = Invoke-RestMethod -Method get -UseBasicParsing -Uri "$octopusDNSName/api/machines/all" -Headers $authToken

    if ($OnlyEnabledMachines)
    {
        return ($response | where-object {($_.Thumbprint -eq "$thumbprint") -and ($_.IsDisabled -eq $false)})
    }
    else 
    {
        return ($response | Where-Object {$_.Thumbprint -contains "$thumbprint"})
    }
}

Function Get-OctopusMachineByCenturylinkName
{
    <#
    .SYNOPSIS
    Will get machine details based on centurylink friendly name

    .PARAMETER CLName
    The name of the server (centurylink) eg s616253shvw040
    
    .PARAMETER apiKey
    Your API key that gives you access to the Octopus API

    .PARAMETER octopusDNSName
    The DNS name of the octopus server, eg "octopus.mydomain.com"

    .PARAMETER OnlyEnabledMachines
    This is a switch parameter. If used it will only return machines that are enabled
    
    .EXAMPLE
    Get-OctopusMachineByCenturylinkName -CLName "s616253shvw040" -apiKey "API-324343244323fd" -octopusDNSName "octopus.mydomain.com"
    
    .Notes
    If you dont specify and APIkey or dns name it will look for the default values which are user environment variables:
    $apiKey = $env:_OctopusAPI
    $octopusDNSName = $env:__octopusDNS
    #>
    param
    (
        [cmdletbinding()]
        [parameter(mandatory = $true)]
        $CLName,
        [parameter(Mandatory = $false)]
        $apiKey,
        [parameter(Mandatory = $false)]
        $octopusDNSName,
        [switch]$OnlyEnabledMachines
    )

    $authToken = Get-OctopusAPIHeader -apiKey $apiKey
    $octopusDNSName = Get-OctopusDNSName -octopusDNSName $octopusDNSName
    $response = Invoke-RestMethod -Method get -UseBasicParsing -Uri "$octopusDNSName/api/machines/all" -Headers $authToken

    if ($OnlyEnabledMachines)
    {
        return ($response | where-object {(($_.Uri -like "*$CLName.*")) -and ($_.IsDisabled -eq $false)})
    }
    else 
    {
        return ($response | Where-Object {($_.Uri -like "*$CLName.*")})
    }
}

Function Get-OctopusProjectIDByName
{
    <#
    .SYNOPSIS
    Will get the project ID based on a name search. Will return a single object if direct match, or array of objects if mutliple matches

    .PARAMETER Name
    The name of the project
    
    .PARAMETER apiKey
    Your API key that gives you access to the Octopus API

    .PARAMETER octopusDNSName
    The DNS name of the octopus server, eg "octopus.mydomain.com"
    
    .EXAMPLE
    Get-OctopusProjectIDByName -Name "cis-web-api" -apiKey "API-324343244323fd" -octopusDNSName "octopus.mydomain.com"
    
    .Notes
    If you dont specify and APIkey or dns name it will look for the default values which are user environment variables:
    $apiKey = $env:_OctopusAPI
    $octopusDNSName = $env:__octopusDNS
    #>
    
    param
    (
        [cmdletbinding()]
        [parameter(mandatory = $true)]
        $Name,
        [parameter(Mandatory = $false)]
        $apiKey,
        [parameter(Mandatory = $false)]
        $octopusDNSName
    )

    $authToken = Get-OctopusAPIHeader -apiKey $apiKey
    $octopusDNSName = Get-OctopusDNSName -octopusDNSName $octopusDNSName
    $response = Invoke-RestMethod -Method get -UseBasicParsing -Uri "$octopusDNSName/api/projects?name=$name" -Headers $authToken

    if ($response.items.count -eq 0)
    {
        Write-output "No projects found"
        return $null
    }
    else
    {
        Write-Output ($response.items | Select-Object Id, Name, Slug)
        $returnObject = ($response.items | Select-Object Id, Name, Slug)
        return $returnObject
    }
}

Function ConvertTo-CommaSeperatedList
{
    <#
    .SYNOPSIS
    This is a helper function that can take a list of objects and convert them into a comma seperated list

    .PARAMETER data
    Can be passed by pipeline
    
    .EXAMPLE
    Get-OctopusMachinesInSpecificRoleAndEnvironment -role "telegraf" -EnviromentID "Environments-25" -apiKey "API-243213213123" -octopusDNSName "octopus.mydomain.com" | ConvertTo-CommaSeperatedList 
    
    .NOTES
    Made as a general helper function to give output that can be used when writing nagios config
    #>
    [cmdletbinding()]
    param
    (
        [parameter(Mandatory = $true, ValueFromPipeline = $true)]
        $data
    )
    
    Begin
    {
        $outputString = $null
    }
    Process
    {
        Write-Verbose "ConvertTo-CommaSeperatedList: Input obj = $data"
        if ($outputString -eq $null)
        {
            $outputString = $data
        }
        else 
        {
            $outputString += ",$data"    
        }    
    }
    
    End
    {
        return $outputString
    }
}

Export-ModuleMember -Function `
    Get-OctopusEnvironments, `
    Get-OctopusMachinesInSpecificEnvironment, `
    Get-OctopusMachinesInSpecificRole, `
    Get-OctopusMachinesInSpecificRoleAndEnvironment, `
    Get-OctopusMachinesByThumbprint, `
    Get-OctopusMachineByCenturylinkName, `
    Get-OctopusProjectIDByName, `
    ConvertTo-CommaSeperatedList, `
    Get-OctopusAPIHeader, `
    Get-OctopusDNSName