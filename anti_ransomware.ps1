## Autor: Jmolina Kinomakino
## blog http://kinomakino.blogspot.com.es/
## @kinomakino
## Con este script podemos definir una seria de extensiones usadas por ransomware y usarlas en un servidor FSRM sobre Windows 
## para apagar el servidor y enviar un e-mail.
## Ejecuta el script con el parámetro de la carpeta que quieres monitorizar. por ejemplo : Script.ps1 c:\datos\
## El script primero borra los grupos y plantillas, no se comprueba que existen, por lo que la primera vez que se ejecuta puede
## dar algún problema. Ejecútalo varias veces y desaparecen los mensajes de error.
## De esta manera se puede programar una tarea para que se actualización.
## Si quieres incorporar extensiones propias, ten en cuenta que con la actualización las perders. Te animo a que me las envies 
## a kinomakino@hotmail.com para añadirlas al repo.

param (
    [string]$filePath
    )

## Datos de correo
Set-FsrmSetting -SmtpServer "SMTP.SMTPSERVER.COM" -AdminEmailAddress "direccion_email" -FromEmailAddress "direccion_email" 

## descarga de las extensiones
$extensiones = (Invoke-WebRequest "https://raw.githubusercontent.com/kinomakino/ransomware_file_extensions/master/extensions.csv”).Content
$grupo_ext = @()
foreach($line in $extensiones.Split("`r`n”)){ if ($line -ne "”) {$grupo_ext += $line} }
## exista o no, borramos el grupo de extensiones
Remove-FsrmFileGroup -Name "Extensiones" -Confirm:$false
## creamos el grupo de extensiones
New-FsrmFileGroup -Name "Extensiones" –IncludePattern $grupo_ext
## configuramos las acciones
$Notification = New-FsrmAction -Type Email -MailTo "direccion_email" -Subject "Cuidado, alguien quiere joderte" -Body "El usuario [Source Io Owner] ha intentado guardar [Source File Path] en [File Screen Path] en el servidor [Server]. Este archivo se encuentra en el grupo de archivos [Violated File Group], que no está permitido en el servidor." -RunLimitInterval 120 
$Notification2 = New-FsrmAction -Type Command -Command "c:\Windows\System32\shutdown.exe" -CommandParameters "-s -f -t 00" -SecurityLevel LocalService -KillTimeOut 0
## exista o no, borramos la plantilla
Remove-FsrmFileScreenTemplate -Name "Anti-Ransomware" -Confirm:$false 
## creamos la plantilla
New-FsrmFileScreenTemplate -Name "Anti-Ransomware" -Active:$true –IncludeGroup "Extensiones" -Notification $Notification,$Notification2 
## exista o no, quitamos la configuracion de la ruta a monitorizar
Remove-FsrmFileScreen $filePath -Confirm:$false
## activamos la monitorización de la ruta pasada como parámetro.
New-FsrmFileScreen -Path $filePath -Active:$true -Description "Monitorizar ransomware" –IncludeGroup "Extensiones" –Template "Anti-Ransomware" 
