#!/bin/bash
#MoonGirl de ALejandro VIllar

#Creamos una funcion que se ejecutara si detecta que se hace un control c en el script 
controlc(){
    echo "Se recibió una señal de interrupción. Saliendo..."
    exit 1
}
trap 'controlc' SIGINT


# Dirección de conexión SSH
conexion='ies@192.168.1.119'

# Función para verificar si nmap está instalado en el servidor remoto
verificar_nmap() {
    # Comprobamos si nmap está instalado en el servidor remoto
   ssh $conexion 'command -v nmap' >/dev/null 2>&1
    if [ $? -ne 0 ]; then
        echo "nmap no está instalado en el servidor remoto."
        echo "Quieres instalar nmap en el servidor remoto? (y/n)"
        read respuesta
        if [ "$respuesta" == "y" ]; then
            echo "Introduce la contraseña de sudo para instalar nmap:"
            read -s password
	    echo $password | ssh -tt $conexion 'sudo -S apt update && sudo -S apt install nmap -y'
        else
            echo "No se instaló nmap."
            exit 1
        fi
    fi

    # Ejecutar nmap en el servidor remoto y guardar la salida en la variable
    resultado_nmap=$(ssh $conexion 'nmap localhost')
    # Formatear la salida para que sea legible en HTML (se vera en el html como si fuese la terminal utlizando el comando sed)
    #'s/$/<br>/': es una expresión regular que busca el final de cada línea ($) y lo sustituye por <br>. Esto significa que después de cada línea de texto, se añadirá <br> como un salto de línea en HTML.
    resultado_html=$(echo "$resultado_nmap" | sed 's/$/<br>/')

    # Llama a la función creacion_html con la salida formateada
    creacion_html "$resultado_html"



}

#Esta funcion utiliza el comando sar 1 2 que toma muestra por segundo luego finaliza.
comprobar_rendimiento_cpu() {
    echo "Comprobando rendimiento de la CPU en el servidor remoto..."
    resultado=$(ssh $conexion << 'BOOF' 
    sar 1 2
BOOF

)
    # busca líneas que comiencen (^) con tres grupos de dos dígitos ([0-9]{2}) separados por dos puntos (:). Este patrón coincide con las líneas que contienen una marca de tiempo en formato de hora (por ejemplo, 20:16:03).
    resultado_cpu=$(echo "$resultado" | grep -E '^[0-9]{2}:[0-9]{2}:[0-9]{2}|Average:')
    # Limpia la salida de sar para que sea legible en HTML
    #s/^/\<pre\>/: Esto agrega <pre> al principio de cada línea. El ^ es un ancla que indica el comienzo de la línea.
    #s/$/\<\/pre\>/: Esto agrega </pre> al final de cada línea. El $ es un ancla que indica el final de la línea.
    resultado_html=$(echo "$resultado_cpu" | sed 's/^/\<pre\>/; s/$/\<\/pre\>/')
    # Llama a la función creacion_html con la salida de sar formateada
    creacion_html "$resultado_html"
}


#Funcion que comprueba si el estado del apache esta activo o inactivo y l oguarda en una variable para luego llamar a la funcion del html para imrpimri el resultado por html
comprobar_estado_apache() {
    if systemctl is-active --quiet apache2; then
        resultado_apache_2="Apache está en ejecución en el servidor remoto."
    else
        resultado_apache_2="Apache no está en ejecución en el servidor remoto."
    fi
     #llama a la funcion del html pasando e resultado de la funcion
     creacion_html "$resultado_apache_2"
}


procesos_recursos() {
    # Utilizamos el comando ps para obtener los procesos ordenados por uso de recursos
    # estamos solicitando que ps muestre el PID (ID del proceso), PPID (ID del proceso padre), CMD (comando), %MEM (porcentaje de memoria utilizado) y %CPU (porcentaje de uso de CPU) para cada proceso.
    # --sort=-%mem,-%cpu: Ordena la salida según el porcentaje de memoria (%MEM) y el porcentaje de uso de CPU (%CPU) de forma descendente 
    procesos=$(ssh $conexion 'ps -eo pid,ppid,cmd,%mem,%cpu --sort=-%mem,-%cpu | head -n 6' | sed 's/^/\<pre\>/; s/$/\<\/pre\>/')
    creacion_html "$procesos"
}

#Esta funcion solo comprueba el espacio que hay en el servidor
comprobar_espacio_sistema() {
   #el comando sed hace lo mismo que en la parte de arriba da un aspecto en el html como si fuese una terminal
   resultado_espacio=$(df -h | sed 's/^/\<pre\>/; s/$/\<\/pre\>/')
   creacion_html "$resultado_espacio"
}


#Crea un html y recibe la variable

creacion_html() {
        echo "
<!DOCTYPE html>
<html lang='es'>
<head>
  <meta charset='utf-8'>
  <title>Servicios remotos</title>
  <meta name='viewport' content='width=device-width, initial-scale=1.0'>
</head>
<body>
  <h1>Moongirl de Alejandro VIllar Pérez</h1>
  <p>$1</p>
</body>
</html>" > resultados.html

}




# Preguntar al usuario qué acción quiere realizar
echo "Que accion quieres realizar?"
echo "1) Comprobar si nmap está instalado y escanear puertos en el servidor remoto"
echo "2) Comprobar rendimiento de la cpu"
echo "3) Comprobar estado de apache"
echo "4) Comprobar recursos"
echo "5) Comprobar espacio en el sistema"
read opcion

# Realizar la acción seleccionada por el usuario
case $opcion in
    1)
        verificar_nmap
        ;;
    2)
        comprobar_rendimiento_cpu
        ;;
    3)
        comprobar_estado_apache
        ;;
    4)
        procesos_recursos
        ;;
    5)
        comprobar_espacio_sistema
        ;;
    *)
        echo "Opcion no valida."
        exit 1
        ;;
esac
