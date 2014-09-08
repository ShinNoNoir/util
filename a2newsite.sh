#!/bin/bash

echo "a2newsite"

CONF_TEMPLATE=/etc/apache2/sites-available/000-default.conf

function confirm() {
    read -p "$1 ([y]es or [N]o): "
    case $(echo $REPLY | tr '[A-Z]' '[a-z]') in
        y|yes) echo "yes" ;;
        *)     echo "no" ;;
    esac
}

function prompt_params() {
	while true; do
		read -p "ServerName: " SERVER_NAME
		
		read -p "ServerAdmin: " SERVER_ADMIN
		
		DEFAULT_PATH="/var/www/$SERVER_NAME"
		read -p "DocumentRoot ($DEFAULT_PATH): " DOCUMENT_ROOT
		DOCUMENT_ROOT=${DOCUMENT_ROOT:-$DEFAULT_PATH}
		
		DEFAULT_CONF="${SERVER_NAME}.conf"
		read -p ".conf file ($DEFAULT_CONF): " CONF
		CONF_FNAME=${CONF:-$DEFAULT_CONF}
		CONF=/etc/apache2/sites-available/${CONF_FNAME}
		
		unset DEFAULT_PATH
		unset DEFAULT_CONF
	
		echo -e "\nNew site's settings:"
		echo -e "\tServerName:    $SERVER_NAME"
		echo -e "\tServerAdmin:   $SERVER_ADMIN"
		echo -e "\tDocumentRoot:  $DOCUMENT_ROOT"
		echo -e "\t.conf file:    $CONF"
		
		if [[ "yes" == $(confirm "Is this OK?") ]]
		then
			return 0
		else
			echo "Please re-enter:"
		fi
	done
}

prompt_params

echo -e "\nOK, creating new configuration file: $CONF"

SERVER_NAME_ESC=$(sed -e 's/[\/&]/\\&/g' <<< $SERVER_NAME)
SERVER_ADMIN_ESC=$(sed -e 's/[\/&]/\\&/g' <<< $SERVER_ADMIN)
DOCUMENT_ROOT_ESC=$(sed -e 's/[\/&]/\\&/g' <<< $DOCUMENT_ROOT)

sudo cat $CONF_TEMPLATE \
 | sed "s/\(\t#ServerName\)\(.*\)/\1 \2\n\tServerName $SERVER_NAME_ESC/" \
 | sed "s/\tServerAdmin .*/\tServerAdmin $SERVER_ADMIN_ESC/" \
 | sed "s:\tDocumentRoot .*:\tDocumentRoot $DOCUMENT_ROOT_ESC/public_html:" \
 > "/tmp/$CONF_FNAME"
sudo mv "/tmp/$CONF_FNAME" $CONF

echo "Creating DocumentRoot... $DOCUMENT_ROOT/public_html"
sudo mkdir -p $DOCUMENT_ROOT/public_html

echo "CHOWNing DocumentRoot/public_html to user ${USER}..."
sudo chown -R $USER:$USER $DOCUMENT_ROOT/public_html 
echo "CHMODding DocumentRoot to 755..."
sudo chmod 755 $DOCUMENT_ROOT

echo "Creating default test page..."
echo '<?php phpinfo(); ?>' > ${DOCUMENT_ROOT}/public_html/index.php

echo "Enabling server ${SERVER_NAME}..."
sudo a2ensite $SERVER_NAME

echo "Reloading Apache..."
sudo service apache2 reload

