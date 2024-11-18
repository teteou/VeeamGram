param (
    [string]$JobName,
    [string]$JobResult
)

# Importar el módulo de Veeam
try {
    Import-Module VeeamPSSnapIn -ErrorAction Stop
    Write-LogMessage -Tag 'Info' -Message "VeeamPSSnapIn module imported successfully."
} catch {
    Write-LogMessage -Tag 'Error' -Message "Failed to import VeeamPSSnapIn module: $_"
    exit
}

# Obtener el trabajo de backup por nombre
$Job = Get-VBRJob -Name $JobName

if ($Job) {
    Write-LogMessage -Tag 'Info' -Message "Job found: $JobName"
    # Obtener la última sesión del trabajo
    $LastSession = $Job.FindLastSession()

    if ($LastSession) {
        Write-LogMessage -Tag 'Info' -Message "Last session found for Job: $JobName"
        # Obtener detalles adicionales de la sesión
        $BackupSize = $LastSession.Info.Progress.BackupSize
        $Duration = $LastSession.Info.Progress.Duration
        $VMsProcessed = $LastSession.Info.Progress.ObjectsNumber

        # Construir el mensaje para Telegram
        $Message = "Resultado del trabajo de backup: $JobName`n"
        $Message += "Estado: $JobResult`n"
        $Message += "Tamaño del backup: $BackupSize bytes`n"
        $Message += "Duración: $Duration segundos`n"
        $Message += "Máquinas virtuales procesadas: $VMsProcessed"

        # Enviar el mensaje a Telegram
        $config = (Get-Content "$PSScriptRoot\config\conf.json") -Join "`n" | ConvertFrom-Json
        $MyToken = $config.MyToken
        $ChatID = $config.ChatID
        $URI = "https://api.telegram.org/bot$($MyToken)/sendMessage?chat_id=$($ChatID)&text=$([System.Uri]::EscapeDataString($Message))"

        try {
            $response = Invoke-RestMethod -Uri $URI
            Write-LogMessage -Tag 'Info' -Message "Mensaje enviado a Telegram: $Message"
        } catch {
            Write-LogMessage -Tag 'Error' -Message "Error al enviar el mensaje a Telegram: $_"
        }
    } else {
        Write-LogMessage -Tag 'Error' -Message "No se encontró ninguna sesión para el trabajo '$JobName'."
    }
} else {
    Write-LogMessage -Tag 'Error' -Message "No se encontró el trabajo con el nombre '$JobName'."
}
