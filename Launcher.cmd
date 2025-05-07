@ECHO OFF
REM Set the current directory of the batch file to the variable 'mypath'.
REM %~dp0 expands to the drive letter and path of the batch file.
SET mypath=%~dp0

REM Launch PowerShell and execute the Launcher.ps1 script.
REM The PowerShell command is broken into multiple lines for clarity using the caret (^) for line continuation.
powershell -command ^
    "$myPSScriptRoot = '%mypath:~0,-1%'; " ^
    "$ErrorActionPreference = 'Stop'; " ^
    "try { " ^
    "    Get-Content -Raw -Path '%mypath:~0,-1%\Launcher.ps1' | Invoke-Expression " ^
    "} catch { " ^
    "    Write-Error $_; " ^
    "    Read-Host 'Press Enter to exit' " ^
    "}"

REM Explanation of the PowerShell commands:
REM
REM $myPSScriptRoot = '%mypath:~0,-1%';
REM   - Sets a PowerShell variable '$myPSScriptRoot' to the path of the batch file's directory.
REM   - '%mypath:~0,-1%' removes the trailing backslash from the 'mypath' variable,
REM     which is a common requirement for path handling in PowerShell.
REM
REM $ErrorActionPreference = 'Stop';
REM   - Configures PowerShell to stop script execution immediately if an error occurs.
REM   - This is generally a good practice for script robustness.
REM
REM try { ... } catch { ... }
REM   - Implements error handling.
REM
REM Get-Content -Raw -Path '%mypath:~0,-1%\Launcher.ps1'
REM   - Reads the entire content of 'Launcher.ps1' as a single string.
REM   - Aliases like 'cat' or 'type' could also be used but 'Get-Content -Raw' is explicit.
REM
REM Invoke-Expression
REM   - Executes the string content read from 'Launcher.ps1'.
REM   - This is the core part that allows running the .ps1 content.
REM   - Aliases like 'iex' are common but 'Invoke-Expression' is more descriptive.
REM
REM Write-Error $_;
REM   - If an error occurs within the 'try' block, this command writes the error message to the console.
REM   - $_ is an automatic variable in PowerShell that contains the current object in the pipeline,
REM     which in a 'catch' block is the error record.
REM
REM Read-Host 'Press Enter to exit'
REM   - If an error occurs, this pauses the script and waits for the user to press Enter before closing the window.
REM   - This allows the user to read the error message.

REM End of the batch script.