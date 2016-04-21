## Autor: Jmolina Kinomakino
## blog http://kinomakino.blogspot.com.es/
## @kinomakino
## Con este script podemos definir una seria de extensiones usadas por ransomware y usarlas en un servidor FSRM sobre Windows 
## para apagar el servidor y enviar un e-mail.
## Ejecuta el script con el parámetro de la carpeta que quieres monitorizar. por ejemplo : Script.ps1 c:\datos\
## El script primero borra los grupos y plantillas, no se comprueba que existen, por lo que la primera vez que se ejecuta puede
## dar algún problema. Ejecútalo varias veces y desaparecen los mensajes de error.
## De esta manera se puede programar una tarea para que se actualización.

param (
    [string]$filePath
    )

## Datos de correo
Set-FsrmSetting -SmtpServer "SMTP.SMTPSERVER.COM" -AdminEmailAddress "direccion_email" -FromEmailAddress "direccion_email" 
$fileexts = (Invoke-WebRequest "https://raw.githubusercontent.com/kinomakino/ransomware_file_extensions/master/extensions.csv”).Content
$filescreengroup = @()
foreach($line in $fileexts.Split("`r`n”)){ if ($line -ne "”) {$filescreengroup += $line} }
Remove-FsrmFileGroup -Name "Extensiones" -Confirm:$false
New-FsrmFileGroup -Name "Extensiones" –IncludePattern $filescreengroup
$Notification = New-FsrmAction -Type Email -MailTo "direccion_email" -Subject "Cuidado, alguien quiere joderte" -Body "El usuario [Source Io Owner] ha intentado guardar [Source File Path] en [File Screen Path] en el servidor [Server]. Este archivo se encuentra en el grupo de archivos [Violated File Group], que no está permitido en el servidor." -RunLimitInterval 120 
$Notification2 = New-FsrmAction -Type Command -Command "c:\Windows\System32\shutdown.exe" -CommandParameters "-s -f -t 00" -SecurityLevel LocalService -KillTimeOut 0
Remove-FsrmFileScreenTemplate -Name "Anti-Ransomware" -Confirm:$false 
New-FsrmFileScreenTemplate -Name "Anti-Ransomware" -Active:$true –IncludeGroup "Extensiones" -Notification $Notification,$Notification2 
Remove-FsrmFileScreen $filePath -Confirm:$false
New-FsrmFileScreen -Path $filePath -Active:$true -Description "Monitorizar ransomware" –IncludeGroup "Extensiones" –Template "Anti-Ransomware" 
