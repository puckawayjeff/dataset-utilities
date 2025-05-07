# CommonUtilities.ps1
# Contains shared functions for the Dataset Utilities project.

#Requires -Version 5.1

<#
.SYNOPSIS
    Loads dataset configurations from the Datasets.json file.
.DESCRIPTION
    This function reads the Datasets.json file from the script's root directory.
    If the file doesn't exist or is empty, it returns an empty array.
    It converts the JSON content into an array of PowerShell custom objects.
.PARAMETER DatasetsFilePath
    The full path to the Datasets.json file.
.OUTPUTS
    [array] An array of PSCustomObject, each representing a dataset. Returns an empty array on failure or if file is empty/not found.
.NOTES
    Ensure Datasets.json is in the same directory as Launcher.ps1 or provide the correct path.
#>
function Load-Datasets {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$DatasetsFilePath
    )

    if (-not (Test-Path -Path $DatasetsFilePath)) {
        Write-Warning "Datasets.json file not found at '$DatasetsFilePath'. Returning empty list."
        return @()
    }

    try {
        $jsonContent = Get-Content -Path $DatasetsFilePath -Raw
        if ([string]::IsNullOrWhiteSpace($jsonContent)) {
            # File exists but is empty, treat as no datasets
            return @()
        }
        $datasets = $jsonContent | ConvertFrom-Json
        # Ensure it's always an array, even if JSON had a single object not in an array
        if ($null -ne $datasets -and $datasets.GetType().Name -ne 'Array') {
            $datasets = @($datasets)
        }
        return $datasets
    }
    catch {
        Write-Error "Error loading or parsing Datasets.json: $($_.Exception.Message)"
        return @()
    }
}

<#
.SYNOPSIS
    Saves dataset configurations to the Datasets.json file.
.DESCRIPTION
    This function takes an array of dataset objects and writes them to the
    Datasets.json file in a formatted JSON structure.
    It will overwrite the existing file.
.PARAMETER Datasets
    An array of PSCustomObject, each representing a dataset to be saved.
.PARAMETER DatasetsFilePath
    The full path to the Datasets.json file.
.OUTPUTS
    [boolean] $true if successful, $false otherwise.
.NOTES
    This function overwrites the existing Datasets.json file.
#>
function Save-Datasets {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [array]$Datasets,
        [Parameter(Mandatory = $true)]
        [string]$DatasetsFilePath
    )

    try {
        $jsonOutput = $Datasets | ConvertTo-Json -Depth 5 # Adjust depth if necessary for complex objects
        Set-Content -Path $DatasetsFilePath -Value $jsonOutput
        return $true
    }
    catch {
        Write-Error "Error saving datasets to Datasets.json: $($_.Exception.Message)"
        return $false
    }
}

<#
.SYNOPSIS
    Prompts the user for input with a specific message.
.DESCRIPTION
    A simple helper function to get validated string input from the user.
    It can optionally enforce that the input is not empty.
.PARAMETER PromptMessage
    The message to display to the user.
.PARAMETER AllowEmpty
    [switch] If specified, allows empty input. Otherwise, prompts until non-empty input is received.
.OUTPUTS
    [string] The user's input.
#>
function Get-UserInput {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$PromptMessage,
        [switch]$AllowEmpty
    )

    do {
        $userInput = Read-Host -Prompt $PromptMessage
        if (-not $AllowEmpty -and [string]::IsNullOrWhiteSpace($userInput)) {
            Write-Warning "Input cannot be empty. Please try again."
        }
        else {
            break
        }
    } while ($true)

    return $userInput
}

<#
.SYNOPSIS
    Displays a numbered menu and gets a valid selection from the user.
.DESCRIPTION
    This function takes an array of menu options, displays them with numbers,
    and prompts the user to make a selection. It validates that the input is a
    number within the valid range of options.
.PARAMETER MenuTitle
    The title to display above the menu options.
.PARAMETER MenuOptions
    An array of strings, where each string is a menu option.
.OUTPUTS
    [int] The 1-based index of the selected menu option.
.NOTES
    The function will loop until a valid numeric choice is made.
#>
function Show-MenuAndGetChoice {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$MenuTitle,
        [Parameter(Mandatory = $true)]
        [array]$MenuOptions
    )

    Write-Host "`n$MenuTitle" -ForegroundColor Yellow
    Write-Host ("-" * $MenuTitle.Length) -ForegroundColor Yellow

    for ($i = 0; $i -lt $MenuOptions.Count; $i++) {
        Write-Host ("[{0}] {1}" -f ($i + 1), $MenuOptions[$i])
    }
    Write-Host ("-" * $MenuTitle.Length) -ForegroundColor Yellow

    $validChoice = $false
    $userChoice = 0
    while (-not $validChoice) {
        $input = Read-Host -Prompt "Enter your choice (number)"
        if ($input -match "^\d+$") {
            $userChoice = [int]$input
            if ($userChoice -ge 1 -and $userChoice -le $MenuOptions.Count) {
                $validChoice = $true
            }
            else {
                Write-Warning "Invalid choice. Please enter a number between 1 and $($MenuOptions.Count)."
            }
        }
        else {
            Write-Warning "Invalid input. Please enter a number."
        }
    }
    return $userChoice
}

# Export functions if you plan to use this as a module,
# but for dot-sourcing, this is not strictly necessary.
# For clarity in this project, we'll assume dot-sourcing.
# Export-ModuleMember -Function Load-Datasets, Save-Datasets, Get-UserInput, Show-MenuAndGetChoice
