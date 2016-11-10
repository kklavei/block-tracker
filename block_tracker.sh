#!/bin/bash

MSG_DOWNLOAD_FAILED=0
MSG_EN[$MSG_DOWNLOAD_FAILED]="WARNING! Failed to download %b!"
MSG_DE[$MSG_DOWNLOAD_FAILED]="WARNUNG! Download von %b fehlgeschlagen!"
MSG_NOT_ROOT=1
MSG_EN[$MSG_NOT_ROOT]="You have to be root!"
MSG_DE[$MSG_NOT_ROOT]="Du musst root sein!"
MSG_README_HINT=2
MSG_EN[$MSG_README_HINT]="Please read the instructions at https://github.com/ajacobsen/block-tracker"
MSG_DE[$MSG_README_HINT]="Bitte lese die Anweisungen unter https://github.com/ajacobsen/block-tracker"


MSGVAR="MSG_$(tr '[:lower:]' '[:upper:]' <<< ${LANG:0:2})"

write_to_console() { #messagenumber #parm1 ... parmn
    local msgv
    local msg
    msgv="$MSGVAR[$1]"
    msg=${!msgv}
    if [ -z "${msg}" ]; then
      msg="${MSG_EN[$1]}"
    fi
    printf "${msg}\n" "${@:2}"
}

if [ $UID -ne 0 ]; then
    write_to_console "${MSG_NOT_ROOT}"
    exit 1
fi

# Prüfe ob /etc/hosts.d und /etc/hosts.d/00-hosts existieren
( [ -d /etc/hosts.d ] && [ -f /etc/hosts.d/00-hosts ] ) || \
    ( write_to_console "${MSG_README_HINT}")

# Download der hosts Dateien
# Entfernen von carriage returns
# Entfernen von localhost und broadcast Adressen
# Entfernen von allen Kommentaren
# Entfernen aller Zeilen, die nicht mit 0.0.0.0 beginnen
# Entfernen von Leerzeilen
wget -qO - "http://winhelp2002.mvps.org/hosts.txt"| \
    sed -e 's/\r//' -e '/^127/d' -e '/^255.255.255.255/d' -e '/::1/d' -e 's/#.*$//' -e '/^0.0.0.0/!d' -e '/^$/d'|\
    sort -u > "/etc/hosts.d/10-mvpblocklist" || \
    write_to_console "${MSG_DOWNLOAD_FAILED}" "http://winhelp2002.mvps.org/hosts.txt"
wget -qO - "http://someonewhocares.org/hosts/zero/hosts"| \
    sed -e 's/\r//' -e '/^127/d' -e '/^255.255.255.255/d' -e '/::1/d' -e 's/#.*$//' -e '/^0.0.0.0/!d' -e '/^$/d'|\
    sort -u > "/etc/hosts.d/20-some1whocaresblocklist" || \
    write_to_console "${MSG_DOWNLOAD_FAILED}" "http://someonewhocares.org/hosts/zero/hosts"
wget -qO - "http://sysctl.org/cameleon/hosts"| \
    sed -e 's/\r//' -e 's/127.0.0.1/0.0.0.0/' -e '/^255.255.255.255/d' -e '/::1/d' -e 's/#.*$//' -e '/^0.0.0.0/!d' -e '/^$/d' -e 's/[\t]/ /g' -e 's/  / /g'|\
    sort -u > "/etc/hosts.d/30-sysctlblocklist" || \
    write_to_console "${MSG_DOWNLOAD_FAILED}" "http://sysctl.org/cameleon/hosts"
wget -qO - "http://pgl.yoyo.org/as/serverlist.php?hostformat=hosts&showintro=0&mimetype=plaintext"| \
    sed -e 's/\r//' -e 's/127.0.0.1/0.0.0.0/' -e '/^255.255.255.255/d' -e '/::1/d' -e 's/#.*$//' -e '/^0.0.0.0/!d' -e '/^$/d'|\
    sort -u > "/etc/hosts.d/40-yoyo.orgblocklist" || \
    write_to_console "${MSG_DOWNLOAD_FAILED}" "http://pgl.yoyo.org/as/serverlist.php?hostformat=hosts&showintro=0&mimetype=plaintext"

printf "# DO NOT EDIT THIS FILE\\n# It is automaticly generated by block-tracker from the files in /etc/hosts.d/\\n# Your original hosts file can be found at /etc/hosts.d/00-hosts you should make any changes there" > /etc/hosts
# Verbinde Datein in /etc/hosts.d/ zu einer /etc/hosts
tmpfile=$(mktemp)
for f in /etc/hosts.d/*; do
    cat "${f}" >> "${tmpfile}"
done

sed -e 's/#.*$//' -e 's/[ \t]*$//' "${tmpfile}"| sort -u  >> /etc/hosts
rm ${tmpfile}

echo Done
