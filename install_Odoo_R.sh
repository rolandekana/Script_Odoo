#!/bin/bash

# Variables
ODOO_VERSION=17.0
ODOO_USER=odoo17
ODOO_HOME=/opt/$ODOO_USER
ODOO_CONFIG=/etc/$ODOO_USER.conf
ODOO_PORT=8069
PG_VERSION=14
WKHTMLTOX_URL=https://github.com/wkhtmltopdf/packaging/releases/download/0.12.6-1/wkhtmltox_0.12.6-1.focal_amd64.deb

# Mise à jour du système
#sudo apt update && sudo apt upgrade -y

# Installation des dépendances nécessaires
sudo apt install -y build-essential wget git python3.11-dev python3.11-venv \
    libfreetype-dev libxml2-dev libzip-dev libsasl2-dev \
    libjpeg-dev node-less zlib1g-dev libpq-dev \
    libxslt1-dev libldap2-dev libtiff5-dev libopenjp2-7-dev libcap-dev

# Création de l'utilisateur système pour Odoo
sudo adduser --system --shell /bin/bash --gecos 'Utilisateur Odoo' --group --home $ODOO_HOME $ODOO_USER

# Installation de PostgreSQL
sudo apt install -y postgresql
sudo -u postgres createuser --superuser $ODOO_USER
sudo systemctl enable postgresql
sudo systemctl start postgresql
#sudo -u postgres createdb -O $ODOO_USER $ODOO_USER

# Téléchargement et installation de wkhtmltopdf
#wget $WKHTMLTOX_URL
#sudo apt install -y ./wkhtmltox_0.12.6-1.focal_amd64.deb
sudo apt install wkhtmltopdf

# Téléchargement d'Odoo
sudo -u $ODOO_USER git clone --depth 1 --branch $ODOO_VERSION https://www.github.com/odoo/odoo $ODOO_HOME/odoo17
sudo -u $ODOO_USER git clone --depth 1 --branch $ODOO_VERSION https://jmartinsaben@github.com/odoo/enterprise.git $ODOO_HOME/odoo17

# Création et activation de l'environnement virtuel Python
sudo -u $ODOO_USER python3.11 -m venv $ODOO_HOME/odoo-venv
source $ODOO_HOME/odoo-venv/bin/activate

# Installation des dépendances Python
sudo -H -u $ODOO_USER $ODOO_HOME/odoo-venv/bin/pip3 install wheel setuptools pip --upgrade
sudo -H -u $ODOO_USER $ODOO_HOME/odoo-venv/bin/pip3 install -r $ODOO_HOME/odoo/requirements.txt

# Création du répertoire pour les modules personnalisés
sudo -u $ODOO_USER mkdir $ODOO_HOME/custom-addons

# Création du fichier de configuration Odoo
sudo tee $ODOO_CONFIG > /dev/null <<EOF
[options]
admin_passwd = m0d1fyth15
db_host = False
db_port = False
db_user = $ODOO_USER
db_password = False
addons_path = $ODOO_HOME/odoo/addons,$ODOO_HOME/custom-addons
logfile = /var/log/odoo/$ODOO_USER.log
EOF

# Création du répertoire de logs
sudo mkdir /var/log/odoo
sudo chown $ODOO_USER:$ODOO_USER /var/log/odoo

# Création du service systemd pour Odoo
sudo tee /etc/systemd/system/$ODOO_USER.service > /dev/null <<EOF
[Unit]
Description=Odoo
Requires=postgresql.service
After=network.target postgresql.service

[Service]
Type=simple
SyslogIdentifier=$ODOO_USER
User=$ODOO_USER
Group=$ODOO_USER
ExecStart=$ODOO_HOME/odoo-venv/bin/python $ODOO_HOME/odoo/odoo-bin -c $ODOO_CONFIG
StandardOutput=journal+console

[Install]
WantedBy=multi-user.target
EOF

# Redémarrage de systemd et démarrage du service Odoo
sudo systemctl daemon-reload
sudo systemctl start $ODOO_USER
sudo systemctl enable $ODOO_USER

# Affichage du statut du service Odoo
sudo systemctl status $ODOO_USER

echo "Installation d'Odoo $ODOO_VERSION terminée avec succès !"
echo "Vous pouvez accéder à Odoo via http://YOUR_SERVER_IP_ADDRESS:$ODOO_PORT"
