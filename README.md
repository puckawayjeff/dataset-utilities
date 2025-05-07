# Dataset Utilities

## Project Overview

Dataset Utilities is a PowerShell-based toolkit designed to streamline the management and processing of large XML datasets, specifically tailored for MIL-STD-40051 compliant vehicle technical manuals. This project aims to replace a collection of disparate scripts and manual processes with a unified, modular, and user-friendly system.

Developed in collaboration with Gemini, this project prioritizes:
- Modularity and extensibility
- User-friendly console interface
- Data safety and integrity
- Comprehensive documentation
- Code readability and maintainability
- Efficient XML processing

## Core Features (Planned)

- **Centralized Launcher:** A main script (`Launcher.ps1`) providing menu-driven access to all functionalities.
- **Dataset Management:** Configuration of multiple datasets via a `Datasets.json` file (tracking project name, network path, DTD, platform).
- **Modular Architecture:**
    - **ReportGenerator Modules:** Generate reports from XML data (e.g., into Excel).
    - **DirectModifier Modules:** Perform direct changes to XML files (e.g., batch content updates, file operations).
    - **ReportDrivenModifier Modules:** Perform changes to XML files based on data from an input report.
- **Common Utilities:** A shared library (`CommonUtilities.ps1`) of PowerShell functions for common tasks.
- **Surgical XML Manipulation:** Using `System.Xml.XmlDocument` to make precise changes without unintended restructuring.
- **HTML Logging:** Consistent logging of module actions.
- **Performance Optimization:** Including in-memory processing for large file sets.

## Project Structure
```bash
DatasetUtilities/
├── Launcher.ps1               # Main executable script
├── Datasets.json              # Configuration for datasets
├── CommonUtilities.ps1        # Shared PowerShell functions
├── Modules/                   # Directory for all modules (*.ps1)
│   └── (ExampleModule.ps1)
├── Logs/                      # Output directory for HTML logs
├── Reports/                   # Output directory for generated reports (e.g., .xlsx)
└── Output/                    # Output directory for files modified by "Modifier" modules
```
## Getting Started
1.  Ensure you have Windows PowerShell 5.1 or later.
2.  Clone the repository.
3.  Create the directory structure as outlined above if it doesn't exist.
4.  Populate `Datasets.json` with your dataset configurations or use the launcher to add them.
5.  Run `Launcher.ps1` from a PowerShell console.
    * Note: Due to GPO restrictions on `.ps1` execution, you might need to use the `.bat` launcher workaround:
        ```batch
        SET mypath=%~dp0
        powershell -command "$myPSScriptRoot = '%mypath:~0,-1%'; $ErrorActionPreference = 'Stop'; try { . '%mypath:~0,-1%\Launcher.ps1' } catch { Write-Error $_; Read-Host 'Press Enter to exit' }"
        ```
        (The `try/catch` and `$ErrorActionPreference` are added for better error visibility when using this method).

## Development

This project adheres to the following PowerShell coding style guidelines:
- Use full cmdlet names (e.g., `Get-ChildItem` instead of `gci`).
- Use full parameter names (e.g., `-Path` instead of `-P`).
- Avoid condensing multiple commands onto a single line with semicolons.
- Provide comprehensive comments for functions and complex logic.

## License

This project is licensed under the Creative Commons Attribution-NonCommercial 4.0 International License.
See [CC BY-NC 4.0](https://creativecommons.org/licenses/by-nc/4.0/) for more information.

## Contributions

Currently, this project is being developed by Jeff Thelen in collaboration with Gemini.

---
*This README will be updated as the project progresses.*
