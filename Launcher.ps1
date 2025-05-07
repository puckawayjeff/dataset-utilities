# Launcher.ps1
# Main script for the Dataset Utilities project.

#Requires -Version 5.1
#Requires -RunAsAdministrator # If COM objects for Excel need admin rights, otherwise remove. Consider carefully.

# --- Configuration ---
# Set $myPSScriptRoot if not already set (e.g., when run via the BAT launcher)
if ($null -eq $myPSScriptRoot) {
    $myPSScriptRoot = Split-Path -Parent -Path $MyInvocation.MyCommand.Definition
}
$DatasetsJsonPath = Join-Path -Path $myPSScriptRoot -ChildPath "Datasets.json"
$CommonUtilitiesPath = Join-Path -Path $myPSScriptRoot -ChildPath "CommonUtilities.ps1"
$ModulesPath = Join-Path -Path $myPSScriptRoot -ChildPath "Modules"
$LogsPath = Join-Path -Path $myPSScriptRoot -ChildPath "Logs"
$ReportsPath = Join-Path -Path $myPSScriptRoot -ChildPath "Reports"
$OutputPath = Join-Path -Path $myPSScriptRoot -ChildPath "Output"

# --- Load Common Utilities using Invoke-Expression ---
try {
    # Read the content of CommonUtilities.ps1 and execute it in the current scope.
    Get-Content -Path $CommonUtilitiesPath -Raw | Invoke-Expression
    Write-Verbose "CommonUtilities.ps1 loaded successfully using Get-Content | Invoke-Expression."
}
catch {
    Write-Error "Failed to load CommonUtilities.ps1 using Get-Content | Invoke-Expression. Ensure the file exists at '$CommonUtilitiesPath'. Error: $($_.Exception.Message)"
    Read-Host "Press Enter to exit"
    Exit 1
}

# --- Global Variables ---
$Global:AllDatasets = @() # Holds all dataset configurations
$Global:ActiveDataset = $null # Holds the currently selected dataset object

# --- Target Output Mapping ---
# For converting between stored values and display values
$Global:TargetOutputMap = @{
    "paper" = "Paper (PDF)"
    "ietm"  = "IETM (IADS)"
}

# --- Directory Creation ---
# Ensure core directories exist
$coreDirectories = @($ModulesPath, $LogsPath, $ReportsPath, $OutputPath)
foreach ($dir in $coreDirectories) {
    if (-not (Test-Path -Path $dir)) {
        try {
            New-Item -ItemType Directory -Path $dir -ErrorAction Stop | Out-Null
            Write-Verbose "Created directory: $dir"
        }
        catch {
            Write-Error "Could not create directory: $dir. Error: $($_.Exception.Message)"
            Write-Warning "Please ensure you have permissions to create directories in $myPSScriptRoot"
        }
    }
}


# --- Dataset Management Functions ---

function Get-DisplayTargetOutput {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]$StoredValue
    )
    if ($Global:TargetOutputMap.ContainsKey($StoredValue)) {
        return $Global:TargetOutputMap[$StoredValue]
    }
    return $StoredValue # Fallback to stored value if not in map
}

function Display-Datasets {
    Write-Host "`n--- Configured Datasets ---" -ForegroundColor Green
    if ($Global:AllDatasets.Count -eq 0) {
        Write-Host "No datasets configured yet."
        return
    }
    for ($i = 0; $i -lt $Global:AllDatasets.Count; $i++) {
        $dataset = $Global:AllDatasets[$i]
        $displayTargetOutput = Get-DisplayTargetOutput -StoredValue $dataset.TargetOutput
        Write-Host ("[{0}] Project: {1} (DTD Revision: {2}, Target: {3})" -f ($i + 1), $dataset.ProjectName, $dataset.DTDRevision, $displayTargetOutput)
        Write-Host ("    Path: {0}" -f $dataset.NetworkPath)
    }
    Write-Host "--------------------------" -ForegroundColor Green
}

function Get-TargetOutputSelection {
    [CmdletBinding()]
    param (
        [string]$CurrentStoredValue # Optional: for editing, pass the stored value ("paper" or "ietm")
    )

    # Options presented to the user (Key is what they type, Value is the internal stored value)
    $userOptions = @{
        "P" = "paper"
        "I" = "ietm"
    }
    
    $prompt = "Select Target Output:"
    if (-not [string]::IsNullOrWhiteSpace($CurrentStoredValue)) {
        $displayCurrent = Get-DisplayTargetOutput -StoredValue $CurrentStoredValue
        $prompt += " (current: $displayCurrent)"
    }
    Write-Host $prompt
    # Display descriptive options from $Global:TargetOutputMap based on $userOptions keys
    foreach ($key in $userOptions.Keys) {
        $storedVal = $userOptions[$key]
        $displayVal = Get-DisplayTargetOutput -StoredValue $storedVal
        Write-Host ("[{0}] {1}" -f $key, $displayVal)
    }

    $validInput = $false
    $selectedStoredValue = $CurrentStoredValue # Default to current if editing and no new input

    while (-not $validInput) {
        $input = Read-Host -Prompt "Enter your choice (P/I)"
        if (-not [string]::IsNullOrWhiteSpace($CurrentStoredValue) -and [string]::IsNullOrWhiteSpace($input)) {
            # User pressed Enter without typing anything while editing, keep current value
            $validInput = $true
            break 
        }
        if ($userOptions.ContainsKey($input.ToUpper())) {
            $selectedStoredValue = $userOptions[$input.ToUpper()]
            $validInput = $true
        }
        else {
            Write-Warning "Invalid selection. Please enter P or I."
        }
    }
    return $selectedStoredValue # Returns "paper" or "ietm"
}

function Add-NewDataset {
    Write-Host "`n--- Add New Dataset ---" -ForegroundColor Cyan
    $projectName = Get-UserInput -PromptMessage "Enter Project Name"
    $networkPath = Get-UserInput -PromptMessage "Enter Network Path (e.g., C:\data\project_x)"
    $dtdRevision = Get-UserInput -PromptMessage "Enter DTD Revision (e.g., 6.0.3, 7.1, 5.0.2b)"
    $targetOutputStoredValue = Get-TargetOutputSelection # This now returns "paper" or "ietm"

    $newDataset = [PSCustomObject]@{
        ProjectName  = $projectName
        NetworkPath  = $networkPath
        DTDRevision  = $dtdRevision
        TargetOutput = $targetOutputStoredValue # Store the simple value
    }
    $Global:AllDatasets += $newDataset
    if (Save-Datasets -Datasets $Global:AllDatasets -DatasetsFilePath $DatasetsJsonPath) {
        Write-Host "Dataset '$projectName' added successfully." -ForegroundColor Green
    }
    else {
        Write-Warning "Failed to save dataset. Check error messages above."
    }
}

function Edit-ExistingDataset {
    Write-Host "`n--- Edit Existing Dataset ---" -ForegroundColor Cyan
    if ($Global:AllDatasets.Count -eq 0) {
        Write-Host "No datasets configured to edit."
        return
    }
    Display-Datasets
    $choice = 0
    while ($choice -lt 1 -or $choice -gt $Global:AllDatasets.Count) {
        $input = Get-UserInput -PromptMessage "Enter the number of the dataset to edit (or 0 to cancel)"
        if ($input -eq '0') { return }
        if ($input -match "^\d+$") {
            $choice = [int]$input
            if ($choice -lt 1 -or $choice -gt $Global:AllDatasets.Count) {
                Write-Warning "Invalid selection."
            }
        } else {
            Write-Warning "Invalid input. Please enter a number."
        }
    }
    $datasetToEdit = $Global:AllDatasets[$choice - 1]
    Write-Host "Editing dataset: $($datasetToEdit.ProjectName)"

    $newProjectName = Get-UserInput -PromptMessage "Enter new Project Name (current: $($datasetToEdit.ProjectName))" -AllowEmpty
    if (-not [string]::IsNullOrWhiteSpace($newProjectName)) { $datasetToEdit.ProjectName = $newProjectName }

    $newNetworkPath = Get-UserInput -PromptMessage "Enter new Network Path (current: $($datasetToEdit.NetworkPath))" -AllowEmpty
    if (-not [string]::IsNullOrWhiteSpace($newNetworkPath)) { $datasetToEdit.NetworkPath = $newNetworkPath }

    $newDTDRevision = Get-UserInput -PromptMessage "Enter new DTD Revision (current: $($datasetToEdit.DTDRevision))" -AllowEmpty
    if (-not [string]::IsNullOrWhiteSpace($newDTDRevision)) { $datasetToEdit.DTDRevision = $newDTDRevision }
    
    # Pass the current *stored* value to the selection function
    $newTargetOutputStoredValue = Get-TargetOutputSelection -CurrentStoredValue $datasetToEdit.TargetOutput
    $datasetToEdit.TargetOutput = $newTargetOutputStoredValue # Update with the new stored value


    if (Save-Datasets -Datasets $Global:AllDatasets -DatasetsFilePath $DatasetsJsonPath) {
        Write-Host "Dataset updated successfully." -ForegroundColor Green
    }
    else {
        Write-Warning "Failed to save updated dataset. Consider reloading datasets from file to revert changes."
    }
}

function Remove-SelectedDataset {
    Write-Host "`n--- Remove Dataset ---" -ForegroundColor Cyan
    if ($Global:AllDatasets.Count -eq 0) {
        Write-Host "No datasets configured to remove."
        return
    }
    Display-Datasets
    $choice = 0
    while ($choice -lt 1 -or $choice -gt $Global:AllDatasets.Count) {
        $input = Get-UserInput -PromptMessage "Enter the number of the dataset to remove (or 0 to cancel)"
        if ($input -eq '0') { return }
        if ($input -match "^\d+$") {
            $choice = [int]$input
            if ($choice -lt 1 -or $choice -gt $Global:AllDatasets.Count) {
                Write-Warning "Invalid selection."
            }
        } else {
            Write-Warning "Invalid input. Please enter a number."
        }
    }
    $datasetToRemove = $Global:AllDatasets[$choice - 1]

    # Confirmation
    $confirmation = Get-UserInput -PromptMessage "Are you sure you want to remove dataset '$($datasetToRemove.ProjectName)'? (yes/no)"
    if ($confirmation.ToLower() -ne 'yes') { 
        Write-Host "Removal cancelled."
        return
    }

    # If the dataset to remove is the active one, clear ActiveDataset
    if ($null -ne $Global:ActiveDataset -and $Global:ActiveDataset.ProjectName -eq $datasetToRemove.ProjectName -and $Global:ActiveDataset.NetworkPath -eq $datasetToRemove.NetworkPath) {
        $Global:ActiveDataset = $null
        Write-Host "Active dataset was removed. No dataset is currently active." -ForegroundColor Yellow
    }

    $tempDatasets = @()
    $tempDatasets += $Global:AllDatasets | Where-Object { $_ -ne $datasetToRemove } 
    $Global:AllDatasets = $tempDatasets


    if (Save-Datasets -Datasets $Global:AllDatasets -DatasetsFilePath $DatasetsJsonPath) {
        Write-Host "Dataset '$($datasetToRemove.ProjectName)' removed successfully." -ForegroundColor Green
    }
    else {
        Write-Warning "Failed to save changes after removing dataset. Consider reloading datasets from file."
    }
}

function Select-ActiveDataset {
    Write-Host "`n--- Select Active Dataset ---" -ForegroundColor Cyan
    if ($Global:AllDatasets.Count -eq 0) {
        Write-Host "No datasets configured. Please add a dataset first."
        return
    }
    Display-Datasets
    $choice = 0
    while ($choice -lt 1 -or $choice -gt ($Global:AllDatasets.Count)) {
        $input = Get-UserInput -PromptMessage "Enter the number of the dataset to make active (or 0 to clear active dataset)"
        if ($input -eq '0') {
            $Global:ActiveDataset = $null
            Write-Host "No dataset is currently active." -ForegroundColor Yellow
            return
        }
        if ($input -match "^\d+$") {
            $choice = [int]$input
            if ($choice -lt 1 -or $choice -gt $Global:AllDatasets.Count) {
                Write-Warning "Invalid selection."
            }
        } else {
            Write-Warning "Invalid input. Please enter a number."
        }
    }
    $Global:ActiveDataset = $Global:AllDatasets[$choice - 1]
    Write-Host "Dataset '$($Global:ActiveDataset.ProjectName)' is now active." -ForegroundColor Green
}

# --- Main Menu Functions ---

function Show-MainMenu {
    $menuTitle = "Main Menu"
    if ($null -ne $Global:ActiveDataset) {
        $menuTitle += " (Active Dataset: $($Global:ActiveDataset.ProjectName))"
    } else {
        $menuTitle += " (No Active Dataset)"
    }

    $menuOptions = @(
        "List Available Modules (Not Implemented Yet)", # Placeholder
        "Manage Datasets",
        "Exit"
    )
    return Show-MenuAndGetChoice -MenuTitle $menuTitle -MenuOptions $menuOptions
}

function Show-DatasetManagementMenu {
    $menuTitle = "Dataset Management"
    if ($null -ne $Global:ActiveDataset) {
        $menuTitle += " (Active: $($Global:ActiveDataset.ProjectName))"
    }

    $menuOptions = @(
        "Display Configured Datasets",
        "Add New Dataset",
        "Edit Existing Dataset",
        "Remove Dataset",
        "Select Active Dataset",
        "Back to Main Menu"
    )
    return Show-MenuAndGetChoice -MenuTitle $menuTitle -MenuOptions $menuOptions
}


# --- Main Script Logic ---

# Load existing datasets at startup
$Global:AllDatasets = Load-Datasets -DatasetsFilePath $DatasetsJsonPath
if ($Global:AllDatasets -is [System.Management.Automation.ErrorRecord]) { 
    Write-Error "Critical error loading datasets. The application might not function correctly."
    $Global:AllDatasets = @()
}


# Main application loop
$mainMenuChoice = 0
while ($mainMenuChoice -ne 3) { # Option 3 is Exit
    $mainMenuChoice = Show-MainMenu

    switch ($mainMenuChoice) {
        1 {
            Write-Host "`nModule listing and execution is not yet implemented." -ForegroundColor Yellow
            Read-Host "Press Enter to continue..."
        }
        2 {
            # Dataset Management Sub-Menu
            $datasetMenuChoice = 0
            while ($datasetMenuChoice -ne 6) { # Option 6 is Back to Main Menu
                $datasetMenuChoice = Show-DatasetManagementMenu
                switch ($datasetMenuChoice) {
                    1 { Display-Datasets }
                    2 { Add-NewDataset }
                    3 { Edit-ExistingDataset }
                    4 { Remove-SelectedDataset }
                    5 { Select-ActiveDataset }
                    6 { Write-Host "Returning to Main Menu..." }
                    default { Write-Warning "Invalid dataset menu choice." }
                }
                if ($datasetMenuChoice -ne 6) {
                    Read-Host -Prompt "Press Enter to continue..."
                }
            }
        }
        3 {
            Write-Host "Exiting Dataset Utilities. Goodbye!"
        }
        default {
            Write-Warning "Invalid main menu choice."
        }
    }
}
