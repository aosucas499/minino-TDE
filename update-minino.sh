#!/bin/bash

# =============================================================================
# Script para ejecutar en la iso y añadir mejoras.
# =============================================================================

# -----------------------------------------------------------------------------
# Definición de las funciones utilizadas en el script
# -----------------------------------------------------------------------------

# Instala Gimp en el sistema
# ---

function instalarGimp {
    sudo apt-get install gimp -y
}

# Instala GIT en el sistema
# ---

function instalarGit {

    # Añadir paquete "git" para descargar directamente al sistema desde Github.
    sudo apt update && sudo apt-get install git -y
}

# Activa el autologin para el usuario "usuario"
# ---

function activarAutoLogin {

cat << EOF >> /etc/lightdm/lightdm.conf 

[Seat:*]
pam-service=lightdm
pam-autologin-service=lightdm-autologin
autologin-user=usuario
autologin-user-timeout=0
session-wrapper=/etc/X11/Xsession
greeter-session=lightdm-greeter

EOF

}

# Corrige la opción de menú duplicidad para ImageMagick
# ---

function corregirImageMagick {

    # Menú gráficos duplicados en ImageMagik-corregido
    sudo rm /usr/share/applications/display-im6.q16.desktop
}

# Ejecuta la función correspondiente a cada una de las opciones del script
# ---

function ejecutarAccionOpcional {

    echo "Ejecutamos $1()"
    ($1)
}

# Invocamos ("callback") las funciones asociadas a las opciones 
# seleccionadas por el usuario
# ---

function procesarAccionesOpcionales {

    # Dividimos (el separador es "|" ) las opciones seleccionadas por el usuario
    # ---

    IFS="|" read -a vals <<< $1

    # Solicitamos (una a una) que se procesen dichas opciones

    for i in "${vals[@]}"
    do
        ejecutarAccionOpcional $i
    done

}

# -----------------------------------------------------------------------------
# Cuerpo del script
# -----------------------------------------------------------------------------

# Realizamos las opciones por defecto de nuestro script
# ---

instalarGit
corregirImageMagick

# Permitimos seleccionar opciones personalizadas
# ---

# Mostramos las opciones personalizables

opc=$( \
    zenity \
        --list \
        --title="Elija las personalizaciones que desea apliar" \
        --checklist \
        --column="Aplicar" \
        --column="funcionAEjecutar" \
        --column="Descripción" \
        --hide-column=2 \
    True activarAutoLogin "Inicio de sesión automático" \
    False instalarGimp "Instalar Gimp" \
)

# Comprobamos que no se pulse el botón Cancelar

if [[ "$?" != 0 ]]; then
    echo "Sin problemas, ya personalizaremos Minino otro día ;)"
    exit 0
fi

# Procesamos las opciones elegidas por el usuario
# ---

procesarAccionesOpcionales $opc