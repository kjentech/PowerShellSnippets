# PowerShellSnippets


## FileCleaner.ps1
A simple file cleaning script with very verbose logging.

>Simple example with a log file in the running script path

    .\FileCleaner.ps1 -Directory "C:\Temp\Logs" -OlderThanDays 30

>Simple example with no logging

    .\FileCleaner.ps1 -Directory "C:\Temp\Logs" -OlderThanDays 7 -DoNotWriteLogFile
    
>Example using custom file types and a custom log path

    .\FileCleaner.ps1 -Directory "C:\Temp\Logs" -OlderThanDays 30 -FileTypes ".log" -LogFilePath "C:\Temp\$(Get-Date -Format 'yyyyMMdd').log"
    
>Example using file names

    .\FileCleaner.ps1 -Directory "C:\Temp\Logs" -OlderThanDays 30 -FileNamesRegex "PSM.*|Log.*"

>Example using file names with no logging

    .\FileCleaner.ps1 -Directory "C:\Temp\Logs" -OlderThanDays 30 -FileNamesRegex "PSM.*|Log.*" -DoNotWriteLogFile