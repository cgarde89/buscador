#!/bin/bash
# buscador_funciones.sh
# Autores: Antonio Alemany, Cristian Garde, Tomeu Torres



############################################################################
############################################################################
##        ##        ##  ######  ##        ##        ##  ###########    #####
##  ########  ####  ##    ####  ##  ########  ####  ##  #########  ####  ### 
##  ########  ####  ##  #  ###  ##  ########  ####  ##  ########  ######  ##
##  ########  ####  ##  ##  ##  ##        ##  ####  ##  ########          ##
##  ########  ####  ##  ###  #  ########  ##  ####  ##  ########  ######  ##
##  ########  ####  ##  ####    ########  ##  ####  ##  ########  ######  ##
##        ##        ##  ######  ##        ##        ##        ##  ######  ##
############################################################################
################################################## Autor: Antonio Alemany ##

#Recoge el nombre de usuario que ha iniciado sesión.
nombreUsuario=`who am i | cut -d' ' -f1`


###########################################################
#                                                         #
#                 Función pintar ayuda                    #
#                Autor: Antonio Alemany                   #
#                                                         #
###########################################################
function ayuda () {
    clear
    for i in {300..331}; do
        mensaje $i
    done
}
###########################################################
###########################################################
###########################################################



###########################################################
#                                                         #
#        Función pintar los mensajes de la página         #
#                Autor: Antonio Alemany                   #
#                                                         #
###########################################################
function mensaje () {
    #strings esta configurado para PRODUCCION
    strings=/home/$nombreUsuario/.Buscador/buscador_strings
    sms=`grep -w $1 $strings | cut -f2 -d:` ##Busca cadena que contenga $1 (numero error) y lo corta a partir de ":"
    # Colorea el mensaje segun el parametro que se le pase como $2
    case "$2" in
        "rojo")
            echo -e "\e[91m${sms}\e[39m"
            ;;
        "verde")
            echo -e "\e[92m${sms}\e[39m"
            ;;
        "amarillo")
            echo -e "\e[93m${sms}\e[39m"
            ;;
        *)
            echo -e "$sms"
            ;;
    esac
}
###########################################################
###########################################################
###########################################################



###########################################################
#                                                         #
#               Función comprobacion_sintaxis             #
#   Autor: Antonio Alemany, Cristian Garde, Tomeu Torres  #
#                                                         #
###########################################################
function comprobacion_sintaxis () {
    SHORT=de:fhHi:Ls:t:u:l:
    LONG=directorios,directories,extension:,ficheros,files,hidden,ocultos,ayuda,help,ignorar:,ignore:,historial,log,ubicacion:,location:
    
    PARSED=`getopt --options $SHORT --longoptions $LONG --name "$0" -- "$@"`
    # Verifica si lo pasado a getopt ha ido bien, sino sale.
    if [[ $? != 0 ]]; then
        exit 2
    fi
    
    # Ejecuta y evalua el contenido de $PARSED como un comando del shell
    eval set -- "$PARSED"
    
    # Valor por defecto de ruta si no se le especifica una con la opción -u
    ruta="/"
    
    while true; do ## Bucle infinito para que siempre este a la escucha de opciones
        case "$1" in
            -d|--directorios|--directories)
                # Autor: Tomeu Torres
                d="-type d"
                shift
                ;;
            -e|--extension)
                # Autor: Cristian Garde
                e=".$2"
                shift 2
                ;;
            -f|--ficheros|--files)
                # Autor: Antonio Alemany
                f="-type f"
                shift
                ;;
            -h|--ocultos|--hidden)
                # Autor: Cristian Garde
                # Si h esta presente, muestra sólo los archivos y capretas ocultos
                h="."
                shift
                ;;
            -H|--ayuda|--help)
                # Autor: Antonio Alemany
                ayuda # Aquí llamamos a la función ayuda.
                ### Al encontrar esta opción sale de la ejecución de programa con el codigo de error 0
                exit 0
                ;;
            -i|--ignorar|--ignore)
                # Autor: Tomeu Torres
                i="-iname $2 -prune -o -print"
                shift 2
                ;;
            -L|--historial|--log)
                # Autor: Tomeu Torres
                historial=1
                shift
                ;;
            -s|-t)
                # Autor Cristian Garde
                if [[ $2 =~ ^[+-]{0,1}[0-9]+[cwbkMG]{0,1}$ ]]; then
                    s="-size $2"
                    shift 2
                else
                    mensaje 203 rojo
                    exit 1
                fi
                ;;
            -u|-l|--ubicacion|--location)
                # Autor: Cristian Garde
                ruta=$2
                shift 2
                ;;
            --)
                ## Controla los argumentos
                shift
                break
                ;;
        esac
    done
    

    ###########################################################
    #                                                         #
    #  Incongruencia en buscar fichero y directorio a la vez  #
    #                   Autor: Tomeu Torres                   #
    #                                                         #
    ###########################################################
    if [[ $d != "" && $f != "" ]]; then
        # Libera las variables f y d
        unset d
        unset f
		fichero=1
		directorio=1

    fi
    ###########################################################
    ###########################################################
    ###########################################################
    
    

    ###########################################################
    #                                                         #
    #    Incongruencia en buscar directorio con extensión     #
    #                  Autor: Antonio Alemany                 #
    #                                                         #
    ###########################################################
    if [[ $d != "" && $e != "" ]]; then
        # Libera las variables e y d
        unset d
        unset e
    fi
    ###########################################################
    ###########################################################
    ###########################################################
    
    

    ###########################################################
    #                                                         #
    #       Creación del historial y ejecución del buscador   #
    #   Autor: Antonio Alemany, Cristian Garde, Tomeu Torres  #
    #                                                         #
    ###########################################################
    # rutaLogs PRODUCCION
    rutaLogs="/home/$nombreUsuario/.Buscador/logs"
    fecha=`date +%d-%m-%Y_%H-%M-%S`
    tmpfile="$rutaLogs/$$.tmp"
    tmpfile2="$rutaLogs/$$.tmp2"
    
	if [[ $fichero -eq 1 && $directorio -eq 1 ]]; then # if si se han pasado las opciones d y f a la vez
		if [[ $s == "" ]]; then # if si no se utiliza la opcion s y sí se utliliza y las opciones d f
			if [[ $historial -eq 1 ]]; then # if si se utiliza la opción de log
				echo "::::::Directorios::::::::" > $tmpfile2
				find $ruta -iname "$h$1*"$e -type d $s 2>/dev/null > $tmpfile
				cantidad=`cat $tmpfile | wc -l`
                contador=1
                largo_cantidad=${#cantidad} # length caracteres variable
                while read linea; do
                    espacios=""
                	largo_contador=${#contador}
                	diferencia=`expr $largo_cantidad - $largo_contador`
                	while [[ $diferencia -gt 0 ]]; do
                		espacios="$espacios "
                		let "diferencia--"
                	done
                	echo "$espacios$contador - $linea" >> $tmpfile2
                	let "contador++"
                done <$tmpfile
                unset cantidad contador largo_cantidad largo_contador espacios diferencia linea
				echo "Se han encontrado "$(cat $tmpfile | wc -l)" coincidencias."
				mv $tmpfile2 $rutaLogs/log_$fecha.txt
				mensaje 205 verde
				rm $tmpfile
				
				echo "::::::Ficheros:::::::::::" >> $tmpfile2
                find $ruta -iname "$h$1*"$e -type f $s 2>/dev/null > $tmpfile
				cantidad=`cat $tmpfile | wc -l`
                contador=1
                largo_cantidad=${#cantidad}
                while read linea; do
                    espacios=""
                	largo_contador=${#contador}
                	diferencia=`expr $largo_cantidad - $largo_contador`
                	while [[ $diferencia -gt 0 ]]; do
                		espacios="$espacios "
                		let "diferencia--"
                	done
                	echo "$espacios$contador - $linea" >> $tmpfile2
                	let "contador++"
                done <$tmpfile
                unset cantidad contador largo_cantidad largo_contador espacios diferencia linea
				echo "Se han encontrado "$(cat $tmpfile | wc -l)" coincidencias."
				cat $tmpfile2 >> $rutaLogs/log_$fecha.txt
				rm $tmpfile
				rm $tmpfile2
				mensaje 205 verde
				
			else # else si no se utliza la opcion log pero si las opciones d y f
				echo "::::::Directorios::::::::"
				find $ruta -iname "$h$1*"$e -type d $s 2>/dev/null > $tmpfile
				cantidad=`cat $tmpfile | wc -l`
                contador=1
                largo_cantidad=${#cantidad}
                while read linea; do
                    espacios=""
                	largo_contador=${#contador}
                	diferencia=`expr $largo_cantidad - $largo_contador`
                	while [[ $diferencia -gt 0 ]]; do
                		espacios="$espacios "
                		let "diferencia--"
            	    done
                	echo "$espacios$contador - $linea"
                	let "contador++"
                done <$tmpfile
                unset cantidad contador largo_cantidad largo_contador espacios diferencia linea
				echo "Se han encontrado "$(cat $tmpfile | wc -l)" coincidencias."
				rm $tmpfile
				
				echo "::::::Ficheros:::::::::::"
				find $ruta -iname "$h$1*"$e -type f $s 2>/dev/null > $tmpfile
				cantidad=`cat $tmpfile | wc -l`
                contador=1
                largo_cantidad=${#cantidad}
                while read linea; do
                    espacios=""
                	largo_contador=${#contador}
                	diferencia=`expr $largo_cantidad - $largo_contador`
                	while [[ $diferencia -gt 0 ]]; do
                		espacios="$espacios "
                		let "diferencia--"
                	done
                	echo "$espacios$contador - $linea"
                	let "contador++"
                done <$tmpfile
                unset cantidad contador largo_cantidad largo_contador espacios diferencia linea
				echo "Se han encontrado "$(cat $tmpfile | wc -l)" coincidencias."
				rm $tmpfile
				
			fi # fin del if de $s==""
		else # else si $s!=""
			if [[ $historial -eq 1 ]]; then # si se utiliza la opcion log y s
				if [[ $i == "" ]]; then # si no se utiliza la opcion i pero si la opcion log
					echo "::::::Directorios::::::::" > $tmpfile2
					find $ruta -iname "$h$1*"$e -type d $s -printf "%p: %k KB\n" 2>/dev/null > $tmpfile
    				cantidad=`cat $tmpfile | wc -l`
                    contador=1
                    largo_cantidad=${#cantidad}
                    while read linea; do
                        espacios=""
                    	largo_contador=${#contador}
                    	diferencia=`expr $largo_cantidad - $largo_contador`
                    	while [[ $diferencia -gt 0 ]]; do
                    		espacios="$espacios "
                    		let "diferencia--"
                    	done
                    	echo "$espacios$contador - $linea" >> $tmpfile2
                    	let "contador++"
                    done <$tmpfile
                    unset cantidad contador largo_cantidad largo_contador espacios diferencia linea
				    echo "Se han encontrado "$(cat $tmpfile | wc -l)" coincidencias."
				    mensaje 205 verde
				    
					echo "::::::Ficheros:::::::::::" >> $tmpfile2
					find $ruta -iname "$h$1*"$e -type f $s -printf "%p: %k KB\n" 2>/dev/null > $tmpfile
					cantidad=`cat $tmpfile | wc -l`
                    contador=1
                    largo_cantidad=${#cantidad}
                    while read linea; do
                        espacios=""
                    	largo_contador=${#contador}
                    	diferencia=`expr $largo_cantidad - $largo_contador`
                    	while [[ $diferencia -gt 0 ]]; do
                    		espacios="$espacios "
                    		let "diferencia--"
                    	done
                    	echo "$espacios$contador - $linea" >> $tmpfile2
                    	let "contador++"
                    done <$tmpfile
                    unset cantidad contador largo_cantidad largo_contador espacios diferencia linea
					echo "Se han encontrado "$(cat $tmpfile | wc -l)" coincidencias."
					cat $tmpfile2 >> $rutaLogs/log_$fecha.txt
    				rm $tmpfile
    				rm $tmpfile2
					mensaje 205 verde
					
				else # si se utiliza la opcion i, s y la opcion de log
				    echo "::::::Directorios::::::::" > $tmpfile2
				    find $ruta -iname "$h$1*"$e -type d $s -and $i -printf "%p: %k KB\n" 2>/dev/null > $tmpfile
				    cantidad=`cat $tmpfile | wc -l`
                    contador=1
                    largo_cantidad=${#cantidad}
                    while read linea; do
                        espacios=""
                    	largo_contador=${#contador}
                    	diferencia=`expr $largo_cantidad - $largo_contador`
                    	while [[ $diferencia -gt 0 ]]; do
                    		espacios="$espacios "
                    		let "diferencia--"
                    	done
                    	echo "$espacios$contador - $linea" >> $tmpfile2
                    	let "contador++"
                    done <$tmpfile
                    unset cantidad contador largo_cantidad largo_contador espacios diferencia linea
				    echo "Se han encontrado "$(cat $tmpfile | wc -l)" coincidencias."
				    mensaje 205 verde
				    rm $tmpfile
				    
				    echo "::::::Ficheros:::::::::::" >> $tmpfile2
				    find $ruta -iname "$h$1*"$e -type f $s -and $i -printf "%p: %k KB\n" 2>/dev/null > $tmpfile
				    cantidad=`cat $tmpfile | wc -l`
                    contador=1
                    largo_cantidad=${#cantidad}
                    while read linea; do
                        espacios=""
                    	largo_contador=${#contador}
                    	diferencia=`expr $largo_cantidad - $largo_contador`
                    	while [[ $diferencia -gt 0 ]]; do
                    		espacios="$espacios "
                    		let "diferencia--"
                    	done
                    	echo "$espacios$contador - $linea" >> $tmpfile2
                    	let "contador++"
                    done <$tmpfile
                    unset cantidad contador largo_cantidad largo_contador espacios diferencia linea
				    echo "Se han encontrado "$(cat $tmpfile | wc -l)" coincidencias."
				    cat $tmpfile2 >> $rutaLogs/log_$fecha.txt
    				rm $tmpfile
    				rm $tmpfile2
				    mensaje 205 verde
				    
				fi # fin de $i==""
			else # else si no se pasa la opción log y se utlizan las opciones d, f y s
				if [[ $i == "" ]]; then # si no se utiliza la opcion i
					echo "::::::Directorios::::::::"
				    find $ruta -iname "$h$1*"$e -type d $s -printf "%p: %k KB\n" 2>/dev/null > $tmpfile
				    cantidad=`cat $tmpfile | wc -l`
                    contador=1
                    largo_cantidad=${#cantidad}
                    while read linea; do
                        espacios=""
                    	largo_contador=${#contador}
                    	diferencia=`expr $largo_cantidad - $largo_contador`
                    	while [[ $diferencia -gt 0 ]]; do
                    		espacios="$espacios "
                    		let "diferencia--"
                    	done
                    	echo "$espacios$contador - $linea"
                    	let "contador++"
                    done <$tmpfile
                    unset cantidad contador largo_cantidad largo_contador espacios diferencia linea
				    echo "Se han encontrado "$(cat $tmpfile | wc -l)" coincidencias."
				    rm $tmpfile
				    
					echo "::::::Ficheros:::::::::::"
				    find $ruta -iname "$h$1*"$e -type f $s -printf "%p: %k KB\n" 2>/dev/null > $tmpfile
				    cantidad=`cat $tmpfile | wc -l`
                    contador=1
                    largo_cantidad=${#cantidad}
                    while read linea; do
                        espacios=""
                    	largo_contador=${#contador}
                    	diferencia=`expr $largo_cantidad - $largo_contador`
                    	while [[ $diferencia -gt 0 ]]; do
                    		espacios="$espacios "
                    		let "diferencia--"
                    	done
                    	echo "$espacios$contador - $linea"
                    	let "contador++"
                    done <$tmpfile
                    unset cantidad contador largo_cantidad largo_contador espacios diferencia linea
					echo "Se han encontrado "$(cat $tmpfile | wc -l)" coincidencias."
				    rm $tmpfile
				    
				else # si se utiliza la opcion i
					echo "::::::Directorios::::::::"
				    find $ruta -iname "$h$1*"$e -type d $s -and $i -printf "%p: %k KB\n" 2>/dev/null > $tmpfile
				    cantidad=`cat $tmpfile | wc -l`
                    contador=1
                    largo_cantidad=${#cantidad}
                    while read linea; do
                        espacios=""
                    	largo_contador=${#contador}
                    	diferencia=`expr $largo_cantidad - $largo_contador`
                    	while [[ $diferencia -gt 0 ]]; do
                    		espacios="$espacios "
                    		let "diferencia--"
                    	done
                    	echo "$espacios$contador - $linea"
                    	let "contador++"
                    done <$tmpfile
                    unset cantidad contador largo_cantidad largo_contador espacios diferencia linea
				    echo "Se han encontrado "$(cat $tmpfile | wc -l)" coincidencias."
				    rm $tmpfile
				    
					echo "::::::Ficheros:::::::::::"
				    find $ruta -iname "$h$1*"$e -type f $s -and $i -printf "%p: %k KB\n" 2>/dev/null > $tmpfile
				    cantidad=`cat $tmpfile | wc -l`
                    contador=1
                    largo_cantidad=${#cantidad}
                    while read linea; do
                        espacios=""
                    	largo_contador=${#contador}
                    	diferencia=`expr $largo_cantidad - $largo_contador`
                    	while [[ $diferencia -gt 0 ]]; do
                    		espacios="$espacios "
                    		let "diferencia--"
                    	done
                    	echo "$espacios$contador - $linea"
                    	let "contador++"
                    done <$tmpfile
                    unset cantidad contador largo_cantidad largo_contador espacios diferencia linea
					echo "Se han encontrado "$(cat $tmpfile | wc -l)" coincidencias."
				    rm $tmpfile
				    
				fi # fin de $i=="" con las opfciones d y f y sin log
			fi # fin de $historial -eq 1 con las opciones d y f
		fi # fin de las opciones d y f
	else # else de si no se utlizan las opciones d y f a la vez
		if [[ $s == "" ]]; then # Si no se utiliza la opción s
			if [[ $historial -eq 1 ]]; then # Si se utliza la opción de log sin la opcion s
				if [[ $i == "" ]]; then # Si no se utliza la opción i ni s con la opcion log
				    find $ruta -iname "$h$1*"$e $f $d $s 2>/dev/null > $tmpfile
				    cantidad=`cat $tmpfile | wc -l`
                    contador=1
                    largo_cantidad=${#cantidad}
                    while read linea; do
                        espacios=""
                    	largo_contador=${#contador}
                    	diferencia=`expr $largo_cantidad - $largo_contador`
                    	while [[ $diferencia -gt 0 ]]; do
                    		espacios="$espacios "
                    		let "diferencia--"
                    	done
                    	echo "$espacios$contador - $linea" >> $tmpfile2
                    	let "contador++"
                    done <$tmpfile
                    unset cantidad contador largo_cantidad largo_contador espacios diferencia linea
				    echo "Se han encontrado "$(cat $tmpfile | wc -l)" coincidencias."
				    mv $tmpfile2 $rutaLogs/log_$fecha.txt
				    rm $tmpfile
				    mensaje 205 verde
				    
				else # Si se utiliza la opción i y log sin la opcion s
				    find $ruta -iname "$h$1*"$e $f $d $s -and $i 2>/dev/null > $tmpfile
				    cantidad=`cat $tmpfile | wc -l`
                    contador=1
                    largo_cantidad=${#cantidad}
                    while read linea; do
                        espacios=""
                    	largo_contador=${#contador}
                    	diferencia=`expr $largo_cantidad - $largo_contador`
                    	while [[ $diferencia -gt 0 ]]; do
                    		espacios="$espacios "
                    		let "diferencia--"
                    	done
                    	echo "$espacios$contador - $linea" >> $tmpfile2
                    	let "contador++"
                    done <$tmpfile
                    unset cantidad contador largo_cantidad largo_contador espacios diferencia linea
				    echo "Se han encontrado "$(cat $tmpfile | wc -l)" coincidencias."
				    mv $tmpfile2 $rutaLogs/log_$fecha.txt
				    rm $tmpfile
				    mensaje 205 verde
				    
				fi # Fin de $i=="" sin la opcion s pero con log
			else # Si no se utliza la opción log
				if [[ $i == "" ]]; then # Si no se utiliza la opción i sin log
				    find $ruta -iname "$h$1*"$e $f $d $s 2>/dev/null > $tmpfile
				    cantidad=`cat $tmpfile | wc -l`
                    contador=1
                    largo_cantidad=${#cantidad}
                    while read linea; do
                        espacios=""
                    	largo_contador=${#contador}
                    	diferencia=`expr $largo_cantidad - $largo_contador`
                    	while [[ $diferencia -gt 0 ]]; do
                    		espacios="$espacios "
                    		let "diferencia--"
                    	done
                    	echo "$espacios$contador - $linea"
                    	let "contador++"
                    done <$tmpfile
                    unset cantidad contador largo_cantidad largo_contador espacios diferencia linea
				    echo "Se han encontrado "$(cat $tmpfile | wc -l)" coincidencias."
				    rm $tmpfile
				    
				else # Si se utiliza la opción i sin log
				    find $ruta -iname "$h$1*"$e $f $d $s -and $i 2>/dev/null > $tmpfile
				    cantidad=`cat $tmpfile | wc -l`
                    contador=1
                    largo_cantidad=${#cantidad}
                    while read linea; do
                        espacios=""
                    	largo_contador=${#contador}
                    	diferencia=`expr $largo_cantidad - $largo_contador`
                    	while [[ $diferencia -gt 0 ]]; do
                    		espacios="$espacios "
                    		let "diferencia--"
                    	done
                    	echo "$espacios$contador - $linea"
                    	let "contador++"
                    done <$tmpfile
                    unset cantidad contador largo_cantidad largo_contador espacios diferencia linea
				    echo "Se han encontrado "$(cat $tmpfile | wc -l)" coincidencias."
				    rm $tmpfile
				    
				fi # fin de $i==""
			fi # fin de $historial -eq 1
		else # else si se utliza la opción s y además no se utliza la opción d y f a la vez
			if [[ $historial -eq 1 ]]; then # Si se utiliza la opción log
				if [[ $i == "" ]]; then # Si no se utiliza la opción i
				    find $ruta -iname "$h$1*"$e $f $d $s -printf "%p: %k KB\n" 2>/dev/null > $tmpfile
				    cantidad=`cat $tmpfile | wc -l`
                    contador=1
                    largo_cantidad=${#cantidad}
                    while read linea; do
                        espacios=""
                    	largo_contador=${#contador}
                    	diferencia=`expr $largo_cantidad - $largo_contador`
                    	while [[ $diferencia -gt 0 ]]; do
                    		espacios="$espacios "
                    		let "diferencia--"
                    	done
                    	echo "$espacios$contador - $linea" >> $tmpfile2
                    	let "contador++"
                    done <$tmpfile
                    unset cantidad contador largo_cantidad largo_contador espacios diferencia linea
				    echo "Se han encontrado "$(cat $tmpfile | wc -l)" coincidencias."
				    mv $tmpfile2 $rutaLogs/log_$fecha.txt
				    rm $tmpfile
				    mensaje 205 verde
				    
				else # Si se utiliza la opción i junto a log sin d y f
				    find $ruta -iname "$h$1*"$e $f $d $s -and $i -printf "%p: %k KB\n" 2>/dev/null > $tmpfile
				    cantidad=`cat $tmpfile | wc -l`
                    contador=1
                    largo_cantidad=${#cantidad}
                    while read linea; do
                        espacios=""
                    	largo_contador=${#contador}
                    	diferencia=`expr $largo_cantidad - $largo_contador`
                    	while [[ $diferencia -gt 0 ]]; do
                    		espacios="$espacios "
                    		let "diferencia--"
                    	done
                    	echo "$espacios$contador - $linea" >> $tmpfile2
                    	let "contador++"
                    done <$tmpfile
                    unset cantidad contador largo_cantidad largo_contador espacios diferencia linea
				    echo "Se han encontrado "$(cat $tmpfile | wc -l)" coincidencias."
				    mv $tmpfile2 $rutaLogs/log_$fecha.txt
				    rm $tmpfile
				    mensaje 205 verde
				    
				fi # fin de $i==""
			else # else si no se utiliza la opción log
				if [[ $i == "" ]]; then # Si no se utiliza la opción i
				    find $ruta -iname "$h$1*"$e $f $d $s -printf "%p: %k KB\n" 2>/dev/null > $tmpfile
				    cantidad=`cat $tmpfile | wc -l`
                    contador=1
                    largo_cantidad=${#cantidad}
                    while read linea; do
                        espacios=""
                    	largo_contador=${#contador}
                    	diferencia=`expr $largo_cantidad - $largo_contador`
                    	while [[ $diferencia -gt 0 ]]; do
                    		espacios="$espacios "
                    		let "diferencia--"
                    	done
                    	echo "$espacios$contador - $linea"
                    	let "contador++"
                    done <$tmpfile
                    unset cantidad contador largo_cantidad largo_contador espacios diferencia linea
				    echo "Se han encontrado "$(cat $tmpfile | wc -l)" coincidencias."
				    rm $tmpfile
				    
				else # Si se utiliza la opción i
				    find $ruta -iname "$h$1*"$e $f $d $s -and $i -printf "%p: %k KB\n" 2>/dev/null > $tmpfile
				    cantidad=`cat $tmpfile | wc -l`
                    contador=1
                    largo_cantidad=${#cantidad}
                    while read linea; do
                        espacios=""
                    	largo_contador=${#contador}
                    	diferencia=`expr $largo_cantidad - $largo_contador`
                    	while [[ $diferencia -gt 0 ]]; do
                    		espacios="$espacios "
                    		let "diferencia--"
                    	done
                    	echo "$espacios$contador - $linea"
                    	let "contador++"
                    done <$tmpfile
                    unset cantidad contador largo_cantidad largo_contador espacios diferencia linea
				    echo "Se han encontrado "$(cat $tmpfile | wc -l)" coincidencias."
				    rm $tmpfile
				    
				fi # fin de $i==""
			fi # fin de $historial -eq 1 si no se utliza la opción s y además no se utliza la opción d y f a la vez
		fi # fin de $s=="" y además no se utlizan las opciones d y f a la vez
	fi # fin de si se han pasado las opciones d y f a la vez
	
    ###########################################################
    ###########################################################
    ###########################################################
    
    

    ###########################################################
    #                                                         #
    #   Creación mensajes de error o busqueda satisfactoria   #
    #   Autor: Antonio Alemany                                #
    #                                                         #
    ###########################################################
    if [ $? -ne 0 ]; then #Si el status error no es igual a 0
        #echo "Error en la ejecución de la herramienta." 
        mensaje 201 amarillo
        mensaje 204 amarillo
    else 
        #echo "Búsqueda finalizada correctamente."
        mensaje 202 verde
    fi
    ###########################################################
    ###########################################################
    ###########################################################
}