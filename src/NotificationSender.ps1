Param(
    [String]$JobName,
    [String]$Id
)

####################
# Import Functions #
####################
Import-Module "$PSScriptRoot\Helpers"

# Load configuration from conf.json
$config = (Get-Content "$PSScriptRoot\config\conf.json") -Join "`n" | ConvertFrom-Json

# Initialize logging if enabled in config
if ($config.debug_log) {
    Start-Logging "$PSScriptRoot\log\debug.log"
    Write-LogMessage -Tag 'Info' -Message "Starting NotificationSender for Job: $JobName with ID: $Id"
}

# Import Veeam module if not already imported
try {
    Import-Module "C:\Program Files\Veeam\Backup and Replication\Console\Veeam.Backup.PowerShell\Veeam.Backup.PowerShell.psd1" -ErrorAction Stop
    Write-LogMessage -Tag 'Info' -Message "Veeam PowerShell module imported successfully."
} catch {
    Write-LogMessage -Tag 'Error' -Message "Failed to import Veeam PowerShell module: $_"
    exit
}

# Enabling TLS 1.2 for secure connections
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

# Get the Veeam session for the specified job
$session = Get-VBRBackupSession | Where-Object { ($_.OrigJobName -eq $JobName) -and ($Id -eq $_.Id.ToString()) }

if (-not $session) {
    Write-LogMessage -Tag 'Error' -Message "No valid session found for Job: $JobName with ID: $Id"
    $Status = "Desconocido"
    $JobName = $JobName -or "N/A"
    $vms = "Ninguno"
    $JobSizeRound = "0 B"
    $TransfSizeRound = "0 B"
    $DurationFormatted = "N/A"
} else {
    # Gather session information if available
    $Status = $session.Result
    $JobName = $session.Name.ToString().Trim()
    $JobType = $session.JobTypeString.Trim()
    $JobSize = [Float]$session.BackupStats.DataSize
    $TransfSize = [Float]$session.BackupStats.BackupSize
    $job = Get-VBRJob -Name $session.JobName

    if ($job) {
        $vms = ($job.GetObjectsInJob()).Name -join ", "
    } else {
        $vms = "Ninguno"
    }

    # Format sizes
    function Format-Size($size) {
        switch ($size) {
            {$_ -lt 1KB} {"{0} B" -f $size}
            {$_ -lt 1MB} {"{0:N2} KB" -f ($size / 1KB)}
            {$_ -lt 1GB} {"{0:N2} MB" -f ($size / 1MB)}
            {$_ -lt 1TB} {"{0:N2} GB" -f ($size / 1GB)}
            default {"{0:N2} TB" -f ($size / 1TB)}
        }
    }

    $JobSizeRound = Format-Size $JobSize
    $TransfSizeRound = Format-Size $TransfSize

    # Calculate duration
    if ($session.Info.EndTime -and $session.Info.CreationTime) {
        $Duration = $session.Info.EndTime - $session.Info.CreationTime
        $DurationFormatted = '{0:00}h {1:00}m {2:00}s' -f $Duration.Hours, $Duration.Minutes, $Duration.Seconds
    } else {
        $DurationFormatted = "N/A"
    }
}

# Determine the status message
$messageStatus = switch ($Status) {
    "None" { "En progreso" }
    "Warning" { "Advertencia" }
    "Success" { "Éxito" }
    "Failed" { "Error" }
    default { "Estado desconocido: $Status" }
}

# Build the notification message
$messageContent = "******* VEEAM REPORT *******`n" +
                  "**Job:** $JobName`n" +
                  "**Status:** $messageStatus`n" +
                  "**Details:**`n" +
                  "VMs in this Job: $vms`n" +
                  "Backup Size: $JobSizeRound`n" +
                  "Transferred Data: $TransfSizeRound`n" +
                  "Duration: $DurationFormatted"

# Send notification to Telegram
$MyToken = $config.MyToken
$ChatID = $config.ChatID
$URI = "https://api.telegram.org/bot$($MyToken)/sendMessage?chat_id=$($ChatID)&text=$([System.Uri]::EscapeDataString($messageContent))"

try {
    $response = Invoke-RestMethod -Uri $URI
    if ($config.debug_log) {
        Write-LogMessage -Tag 'Info' -Message "Notification sent to Telegram: $messageContent"
    }
} catch {
    Write-LogMessage -Tag 'Error' -Message "Failed to send notification to Telegram: $_"
}

# End of script logging
if ($config.debug_log) {
    Write-LogMessage -Tag 'Info' -Message "NotificationSender execution completed for Job: $JobName"
    Stop-Logging
}
