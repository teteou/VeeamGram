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
        # Aquí iría el código para enviar el mensaje a Telegram utilizando tu bot
    } else {
        Write-Host "No se encontró ninguna sesión para el trabajo '$JobName'."
    }
} else {
    Write-Host "No se encontró el trabajo con el nombre '$JobName'."
}
