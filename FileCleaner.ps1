<#
.SYNOPSIS
    Takes a path name and cleans files older than specified number of days if they are the specified file types.
.EXAMPLE
    Simple example with a log file in the running script path
    .\FileCleaner.ps1 -Directory "C:\Temp\Logs" -OlderThanDays 30

    Simple example with no logging
    .\FileCleaner.ps1 -Directory "C:\Temp\Logs" -OlderThanDays 7 -DoNotWriteLogFile
    
    Example using custom file types and a custom log path
    .\FileCleaner.ps1 -Directory "C:\Temp\Logs" -OlderThanDays 30 -FileTypes ".log" -LogFilePath "C:\Temp\$(Get-Date -Format 'yyyyMMdd').log"
    
    Example using file names
    .\FileCleaner.ps1 -Directory "C:\Temp\Logs" -OlderThanDays 30 -FileNamesRegex "PSM.*|Log.*"

    Example using file names with no logging
    .\FileCleaner.ps1 -Directory "C:\Temp\Logs" -OlderThanDays 30 -FileNamesRegex "PSM.*|Log.*" -DoNotWriteLogFile
.OUTPUTS
    If parameter LogFilePath is defined, a .log file will be written to the path.
    If parameter DoNotWriteLogFile is defined, only console output will be shown.
    If parameters LogFilePath and DoNotWriteLogFile are NOT defined, a .log file will be written to the path where the script was run
    If parameters LogFilePath and DoNotWriteLogFile are both defined, only console output will be shown.
.NOTES
    Author: kjentech
    GitHub: https://github.com/kjentech/PowerShellSnippets
#>
[CmdletBinding(DefaultParameterSetName = 'ByFileTypes')]
param (
    [Parameter(Mandatory = $true)]
    [System.IO.DirectoryInfo]$Directory = "C:\Temp",
    #[System.IO.DirectoryInfo]$Directory = "C:\Program Files (x86)\CyberArk\PSM\Logs\Components",

    [Parameter(Mandatory = $true)][string]$OlderThanDays = 7,
    
    [string]$LogFilePath = "$PSScriptRoot\Deleted_files_$(Get-Date -f 'yyyyMMdd-HHmm').log",
    
    [switch]$DoNotWriteLogFile,

    [Parameter(ParameterSetName = 'ByFileTypes')]
    [ValidateScript({
            if ($_ -match "^\.\w+$") {
                $true
            }
            else {
                throw "[-] File extensions must begin with '.',  can only contain letters or numbers and cannot end on special characters.
                `'$_' is not a valid file extension. Examples of valid file extensions include '.log' and '.txt'"
            }
        })][string[]]$FileTypes = @(".log", ".txt"),
    
    [Parameter(ParameterSetName = 'ByFileNames')]
    [string[]]$FileNamesRegex,
    [switch]$IncludeSubDirectories
)
        
begin {
    $ErrorFound = $null
    if ($PSBoundParameters.Keys.Contains("DoNotWriteLogFile")) {
        Write-Verbose "[INFO] Script started at $(Get-Date -DisplayHint Time)" -Verbose
        if ($PSBoundParameters.Keys.Contains("LogFilePath")) {
            Write-Warning "[!] NOT LOGGING: `$LogFilePath set but ignoring" -Verbose
        }
        else {
            Write-Verbose "[INFO] Not logging output" -Verbose
        }
    }
    else {
        if (Test-Path -Path $LogFilePath -PathType Container) {
            # correcting if the input was a folder
            $LogFilePath = "$LogFilePath\Deleted_files_$(Get-Date -f 'yyyyMMdd-HHmm').log"
        }

        Start-Transcript -Path $LogFilePath -Append
        Write-Verbose "[INFO] Logging to $LogFilePath" -Verbose
        Write-Verbose "[INFO] Script started at $(Get-Date -DisplayHint Time)" -Verbose
    }


    switch ($PSBoundParameters.Keys) {
        "Directory" { Write-Verbose "[INFO] Cleaning folder: $Directory" -Verbose }
        "OlderThanDays" { Write-Verbose "[INFO] Only cleaning files older than $OlderThanDays days" -Verbose }
        "FileNamesRegex" { Write-Verbose "[INFO] Only cleaning files with file names matching this regex: $FileNamesRegex" -Verbose }
    }
    if (-not [string]::IsNullOrEmpty($FileTypes)) {Write-Verbose "[INFO] Only cleaning these file types: $($FileTypes -join ", ")" -Verbose }


}
        
process {
    # Check for directory, skip to End block if not present
    if ((Test-Path -Path $Directory) -eq $false) {
        Write-Verbose "[-] Directory does not exist" -Verbose
        $ErrorFound = $true
        return
    }
    
    # Enumerate files, get files of the $FileTypes file types and LastWriteTime older than $OlderThanDays days
    if ($PSBoundParameters.Keys.Contains("IncludesSubDirectories")) {
        $Files = Get-ChildItem -Path $Directory -File -Recurse -Force
        Write-Verbose "[+] Total amount of files in $Directory`: $($Files.Count)" -Verbose
    } else {
        $Files = $Directory.EnumerateFiles()
        Write-Verbose "[+] Total amount of files in $Directory`: $($Files.Count.Length)" -Verbose
    }
        
    # Choose which files to delete depending on which parameter set was used
    switch ($PSCmdlet.ParameterSetName) {

        # If ByFileNames, match on regex and olderthandays
        "ByFileNames" {
            $FilesToDelete = $Files | Where-Object {
                $_.BaseName -match $FileNamesRegex -and
                $_.LastWriteTime -lt (Get-Date -Date ((Get-Date).AddDays(-$OlderThanDays)))
            }
        }

        # If ByFileTypes, match on filetypes and olderthandays
        "ByFileTypes" {
            $FilesToDelete = $Files | Where-Object {
                $_.Extension -in $FileTypes -and
                $_.LastWriteTime -lt (Get-Date -Date ((Get-Date).AddDays(-$OlderThanDays)))
                #$_.LastWriteTime -lt (Get-Date -Date (Get-Date) -Hour 11 -Minute 30 -Second 30) #LastWriteTime BEFORE 13:29
            }
        }
    }
    
    
    # Skip to End block if no files should be deleted
    if ($FilesToDelete.Count -eq 0) {
        Write-Verbose "[*] No files to be deleted" -Verbose
        return
    }
    Write-Verbose "[+] Files to delete in $Directory`: $($FilesToDelete.Count)" -Verbose
    
    # Delete files
    foreach ($File in $FilesToDelete.FullName) {
        try {
            Remove-Item -Path $File -Force -ErrorAction Stop
            Write-Verbose "[+] Deleted $File" -Verbose
        }
        catch {
            Write-Verbose "[-] Couldn't delete $File" -Verbose
            $ErrorFound = $true
        }
    }
    
    Write-Verbose "[+] Deleted $([math]::floor(($FilesToDelete | select -ExpandProperty Length | Measure-Object -Sum).sum/1mb))MB in $($FilesToDelete.Count) files" -Verbose
} #process
        
end {
    if ($ErrorFound) {
        Write-Verbose "[*] Script exited at $(Get-Date -DisplayHint Time) with errors" -Verbose
    }
    else {
        Write-Verbose "[+] Script exited at $(Get-Date -DisplayHint Time) with no errors" -Verbose
    }
        
    if (-not ($PSBoundParameters.Keys.Contains("DoNotWriteLogFile"))) { Stop-Transcript }
}