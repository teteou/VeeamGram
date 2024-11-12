[CmdletBinding()]
param(
    [Parameter(Mandatory=$false)][string]$PreScript,
    [Parameter(Mandatory=$false)][string]$PostScript
)

####################
# Import Functions #
####################
Import-Module "$PSScriptRoot\Helpers"

# Load configuration from conf.json
$config = (Get-Content "$PSScriptRoot\config\conf.json") -Join "`n" | ConvertFrom-Json

# Validate configuration
if (-not $config.ChatID -or -not $config.MyToken) {
    Write-LogMessage -Tag 'Error' -Message "Configuración inválida en conf.json. Verifica ChatID y MyToken."
    exit
}

# Initialize logging if enabled in config
if ($config.debug_log) {
    Start-Logging "$PSScriptRoot\log\debug.log"
    Write-LogMessage -Tag 'Info' -Message "Starting NotificationHandler"
}

# Import Veeam module
Import-Module "C:\Program Files\Veeam\Backup and Replication\Console\Veeam.Backup.PowerShell\Veeam.Backup.PowerShell.psd1"

# Run PreScript if specified
if ($PreScript) {
    Write-LogMessage -Tag 'Info' -Message "Executing PreScript..."
    try {
        Start-Process -FilePath "powershell" -ArgumentList "-File $PreScript" -NoNewWindow -Wait
        Write-LogMessage -Tag 'Info' -Message "PreScript executed successfully."
    } catch {
        Write-LogMessage -Tag 'Error' -Message "Failed to execute PreScript: $_"
    }
}

# Get Veeam job and session information
try {
    $parentpid = (Get-WmiObject Win32_Process -Filter "processid='$pid'").parentprocessid.ToString()
    $parentcmd = (Get-WmiObject Win32_Process -Filter "processid='$parentpid'").CommandLine
    $job = Get-VBRJob | Where-Object { $parentcmd -like "*$($_.Id)*" }
    $session = Get-VBRBackupSession | Where-Object { ($_.OrigJobName -eq $job.Name) -and ($parentcmd -like "*$($_.Id)*") }
} catch {
    Write-LogMessage -Tag 'Error' -Message "Failed to retrieve Veeam job/session information: $_"
    exit
}

# Check if a valid session was found
if ($session) {
    $JobName = $session.OrigJobName.Trim()
    $Id = $session.Id.ToString().Trim()

    # Build arguments for the NotificationSender script
    $powershellArguments = "-File $PSScriptRoot\NotificationSender.ps1 -JobName '$JobName' -Id '$Id'"

    # Start a new process to handle the notification
    try {
        Start-Process -FilePath "powershell" -ArgumentList $powershellArguments -NoNewWindow -Wait
        Write-LogMessage -Tag 'Info' -Message "Notification process started for Job: $JobName"
    } catch {
        Write-LogMessage -Tag 'Error' -Message "Failed to start notification process: $_"
    }
} else {
    Write-LogMessage -Tag 'Warning' -Message "VBR Job Session not found. Exiting script (script should be executed as part of a VBR Job)."
}

# Run PostScript if specified
if ($PostScript) {
    Write-LogMessage -Tag 'Info' -Message "Executing PostScript..."
    try {
        Start-Process -FilePath "powershell" -ArgumentList "-File $PostScript" -NoNewWindow -Wait
        Write-LogMessage -Tag 'Info' -Message "PostScript executed successfully."
    } catch {
        Write-LogMessage -Tag 'Error' -Message "Failed to execute PostScript: $_"
    }
}

# End of script logging
if ($config.debug_log) {
    Write-LogMessage -Tag 'Info' -Message "NotificationHandler execution completed."
    Stop-Logging
}
