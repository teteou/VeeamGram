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
    Write-LogMessage 'Info' "Starting NotificationSender for Job: $JobName with ID: $Id"
}

# Add Veeam commands if not already added
if (-not (Get-PSSnapin -Name VeeamPSSnapin -ErrorAction SilentlyContinue)) {
    Add-PSSnapin VeeamPSSnapin
}

# Get the Veeam session for the specified job
$session = Get-VBRBackupSession | Where-Object { ($_.OrigJobName -eq $JobName) -and ($Id -eq $_.Id.ToString()) }

# Wait for the session to complete
while ($session.IsCompleted -eq $false) {
    Write-LogMessage 'Info' 'Session not finished, sleeping for 200ms...'
    Start-Sleep -Milliseconds 200
    $session = Get-VBRBackupSession | Where-Object { ($_.OrigJobName -eq $JobName) -and ($Id -eq $_.Id.ToString()) }
}

# Gather session information
$Status = $session.Result
$JobName = $session.Name.ToString().Trim()
$JobType = $session.JobTypeString.Trim()
$JobSize = [Float]$session.BackupStats.DataSize
$TransfSize = [Float]$session.BackupStats.BackupSize
$job = Get-VBRJob -Name $session.JobName
$vms = ($job.GetObjectsInJob()).Name -join ", "
$service = $config.service_name

# Format sizes to human-readable strings
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

# Calculate job duration
$Duration = $session.Info.EndTime - $session.Info.CreationTime
$DurationFormatted = '{0:00}h {1:00}m {2:00}s' -f $Duration.Hours, $Duration.Minutes, $Duration.Seconds

# Determine the status message and image
switch ($Status) {
    "None" { $messageStatus = "En progreso"; $img = $config.default_img }
    "Warning" { $messageStatus = "Advertencia"; $img = $config.warn_img }
    "Success" { $messageStatus = "Éxito"; $img = $config.success_img }
    "Failed" { $messageStatus = "Error"; $img = $config.fail_img }
    default { $messageStatus = "Desconocido"; $img = $config.default_img }
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
        Write-LogMessage 'Info' "Notification sent to Telegram: $messageContent"
    }
} catch {
    Write-LogMessage 'Error' "Failed to send notification to Telegram: $_"
}

# End of script logging
if ($config.debug_log) {
    Write-LogMessage 'Info' "NotificationSender execution completed for Job: $JobName"
    Stop-Logging
}
