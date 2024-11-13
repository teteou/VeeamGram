# VeeamGram

## Descripción

**VeeamGram** es una solución que permite enviar notificaciones de trabajos de Veeam Backup & Replication directamente a Telegram utilizando un bot personalizado. El proyecto ofrece una configuración sencilla, opciones avanzadas de personalización de mensajes y manejo de logs configurable para mejorar el monitoreo y la gestión de respaldos. **VeeamGram** proporciona una experiencia robusta y flexible, adaptada a las necesidades de los usuarios que desean mantener visibilidad y control sobre sus trabajos de backup en tiempo real.

---

## Características

- Notificaciones automáticas a Telegram sobre el estado de los trabajos de backup.
- Personalización de mensajes según el estado (éxito, advertencia, error).
- Manejo de logs configurable para registrar eventos y errores.
- Fácil integración con Veeam Backup & Replication.

---

## Requisitos Previos

- [Veeam Backup & Replication](https://www.veeam.com)
- Una cuenta de Telegram y un bot creado a través de [BotFather](https://t.me/botfather).
- Acceso a la API de Telegram mediante un token de bot.

---

## Notas sobre PowerShell

- Configura este script para ejecutarse localmente. La ejecución remota de PowerShell (PS Remoting) no ha sido probada.
- Es posible que necesites configurar la política de ejecución de PowerShell a "Unrestricted" para permitir la ejecución de scripts:
  ```PowerShell
  Set-ExecutionPolicy Unrestricted
  ```
- Si prefieres no cambiar la política global de ejecución, puedes usar el siguiente comando para ejecutar los scripts:
  ```PowerShell
  Powershell.exe -ExecutionPolicy Bypass -File C:\ruta\a\src\NotificationHandler.ps1
  ```
- Si tienes problemas para ejecutar scripts descargados, es posible que debas desbloquearlos:
  ```PowerShell
  Unblock-File C:\ruta\a\src\NotificationHandler.ps1
  Unblock-File C:\ruta\a\src\NotificationSender.ps1
  Unblock-File C:\ruta\a\src\Helpers.psm1
  ```

---

## Configuración

### 0. Configuración del Bot de Telegram

#### 1. Creación del Bot

1. En Telegram, inicia una conversación con [BotFather](https://t.me/botfather).
2. Crea un nuevo bot usando el comando `/newbot` y sigue las instrucciones para asignarle un nombre y un identificador.
3. BotFather te proporcionará un token de acceso que necesitarás para configurar tu bot en `conf.json`.

#### 2. Obtener el `ChatID`

1. Envía un mensaje al bot desde tu cuenta de Telegram.
2. Para obtener tu `ChatID`, puedes utilizar el siguiente comando `curl` desde tu terminal:
   ```bash
   curl "https://api.telegram.org/bot<YOUR_BOT_TOKEN>/getUpdates"
   ```
   **Nota**: Reemplaza `<YOUR_BOT_TOKEN>` con el token proporcionado por BotFather.

3. Busca en la respuesta el `chat.id`, que será tu `ChatID`.

### 1. Crear y Configurar el Archivo `conf.json`

Crea un archivo `conf.json` en la carpeta `config` con el siguiente contenido:

```json
{
    "ChatID": "YOUR_CHAT_ID",
    "MyToken": "YOUR_BOT_TOKEN",
    "service_name": "VeeamGram",
    "enable_notifications": true,
    "notification_levels": {
        "success": true,
        "warning": true,
        "error": true
    },
    "message_template": {
        "success": "Backup completado con éxito: {job_name}",
        "warning": "Advertencia en el backup: {job_name}",
        "error": "Error en el backup: {job_name}"
    },
    "debug_log": true
}
```

---

### 2. Instalación

1. Clona el repositorio en tu servidor:
   ```bash
   git clone https://github.com/teteou/VeeamGram
   ```
2. Configura tu archivo `conf.json` con el `ChatID` y `MyToken` de tu bot de Telegram.
3. Ajusta la política de ejecución de PowerShell si es necesario (ver sección anterior).

---

### 3. Uso de los Scripts

#### **NotificationHandler.ps1**

Este script se encarga de manejar la notificación inicial desde un trabajo de Veeam. Puedes configurarlo para ejecutarse de la siguiente manera:

```PowerShell
.\src\NotificationHandler.ps1 -PreScript "C:\ruta\a\pre_script.ps1" -PostScript "C:\ruta\a\post_script.ps1"
```

- Puedes especificar scripts opcionales que se ejecuten antes (`PreScript`) y después (`PostScript`) del proceso de notificación principal.

#### **NotificationSender.ps1**

Este script maneja el envío de mensajes a Telegram utilizando la configuración proporcionada.

---

### 4. Configuración en Veeam

Para integrar **VeeamGram** con tus trabajos de Veeam Backup & Replication:

1. Haz clic derecho en el trabajo de backup deseado y selecciona "Editar".
2. Ve a la sección "Storage" y haz clic en el botón "Advanced".
3. Dirígete a la pestaña "Scripts" y configura el script para ejecutarse después del trabajo de backup:
   ```PowerShell
   Powershell.exe -File C:\ruta\a\src\NotificationHandler.ps1
   ```

---

### Créditos y Referencias

Este proyecto se basa en la mejora de un proyecto preexistente de notificaciones de Veeam a Telegram, disponible en [VeeamTelegramNotifications](https://github.com/motonuke/VeeamTelegramNotifications). **VeeamGram** incorpora funcionalidades adicionales, optimizaciones y una estructura mejorada para proporcionar una solución más flexible y personalizable.