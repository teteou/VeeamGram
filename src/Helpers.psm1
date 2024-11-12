# This function logs messages with a specified tag
function Write-LogMessage {
    param(
        [string]$Tag,
        [string]$Message
    )
    # Construct the log message format
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $formattedMessage = "[$timestamp] [$Tag] $Message"
    
    # Write to console
    Write-Host $formattedMessage
    
    # If logging is active, write to transcript
    if ($global:transcriptActive) {
        Add-Content -Path $global:logFilePath -Value $formattedMessage
    }
}

# This function starts logging to a specified file path
function Start-Logging {
    param(
        [string]$Path
    )
    # Ensure the directory exists
    $logDir = Split-Path -Path $Path -Parent
    if (-not (Test-Path -Path $logDir)) {
        New-Item -ItemType Directory -Path $logDir -Force | Out-Null
    }
    
    # Ensure the log file exists
    if (-not (Test-Path -Path $Path)) {
        New-Item -ItemType File -Path $Path -Force | Out-Null
    }
    
    try {
        $global:logFilePath = $Path
        $global:transcriptActive = $true
        Start-Transcript -Path $Path -Force -Append
        Write-LogMessage -Tag 'Info' -Message "Transcript logging started at $Path"
    } catch {
        Write-LogMessage -Tag 'Warning' -Message "Failed to start transcript logging. It may already be active."
    }
}

# This function stops logging if it was started
function Stop-Logging {
    if ($global:transcriptActive) {
        try {
            Stop-Transcript
            $global:transcriptActive = $false
            Write-LogMessage -Tag 'Info' -Message "Transcript logging stopped."
        } catch {
            Write-LogMessage -Tag 'Error' -Message "Failed to stop transcript logging: $_"
        }
    }
}