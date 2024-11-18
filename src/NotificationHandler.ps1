param (
    [string]$JobName,
    [string]$JobResult
)

# Importar el módulo de Veeam
Import-Module VeeamPSSnapIn

# Obtener el trabajo de backup por nombre
$Job = Get-VBRJob -Name $JobName

if ($Job) {
    # Obtener la última sesión del trabajo
    $LastSession = $Job.FindLastSession()

    if ($LastSession) {
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
