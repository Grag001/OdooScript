#!/usr/bin/env bash
set -euo pipefail

# ============================
#  Script d’install Odoo dev
# ============================
# Usage :
#   ./odoo.sh -v 19.0 -d Odoo19 -u odoo
# Options :
#   -v  Branche/version git (ex: 19.0, 18.0, master)
#   -d  Nom de la base de données PostgreSQL
#   -u  Nom de l’utilisateur PostgreSQL
#   -p  Mot de passe PostgreSQL (optionnel, sinon laissé vide)
#   -r  Répertoire racine d’install (défaut: /opt/odoo)
#   -h  Aide

ODDO_VERSION="19.0"
DB_NAME="Odoo19"
DB_USER="odoo19"
DB_PASSWORD=""
INSTALL_DIR="/opt/odoo"
REPO_URL="https://github.com/odoo/odoo.git"

usage() {
    echo "Usage: $0 [-v version] [-d db_name] [-u db_user] [-p db_password] [-r install_dir]"
    echo "Exemple: $0 -v 19.0 -d Odoo19 -u odoo19 -r /opt/odoo"
    exit 1
}

while getopts ":v:d:u:p:r:h" opt; do
  case ${opt} in
    v ) ODDO_VERSION="$OPTARG" ;;
    d ) DB_NAME="$OPTARG" ;;
    u ) DB_USER="$OPTARG" ;;
    p ) DB_PASSWORD="$OPTARG" ;;
    r ) INSTALL_DIR="$OPTARG" ;;
    h ) usage ;;
    \? ) echo "Option invalide: -$OPTARG" ; usage ;;
    : ) echo "Option -$OPTARG requiert une valeur." ; usage ;;
  esac
done

echo "===== Configuration ====="
echo "Version Odoo     : ${ODDO_VERSION}"
echo "Répertoire Odoo  : ${INSTALL_DIR}"
echo "DB user          : ${DB_USER}"
echo "DB name          : ${DB_NAME}"
echo "========================="

read -rp "Continuer avec ces paramètres ? [y/N] " confirm
if [[ ! "${confirm:-n}" =~ ^[Yy]$ ]]; then
    echo "Abandon."
    exit 1
fi

if [[ $EUID -ne 0 ]]; then
    echo "Merci de lancer ce script avec sudo (sudo $0 ...)."
    exit 1
fi

echo "== Mise à jour des paquets =="
apt update -y

echo "== Installation de Python, Git et PostgreSQL =="
apt install -y python3 python3-venv python3-pip git postgresql postgresql-client

echo "== Version de Python =="
python3 --version

mkdir -p "${INSTALL_DIR}"
cd "${INSTALL_DIR}"

if [[ -d "${INSTALL_DIR}/odoo" ]]; then
    echo "Répertoire ${INSTALL_DIR}/odoo déjà présent, on fait un git pull."
    cd odoo
    git fetch --all
    git checkout "${ODDO_VERSION}"
    git pull --ff-only || true
else
    echo "== Clonage du repo Odoo =="
    git clone --branch "${ODDO_VERSION}" --depth 1 "${REPO_URL}" odoo
    cd odoo
fi

echo "== Installation des dépendances Debian via debinstall.sh si présent =="
if [[ -x "./setup/debinstall.sh" ]]; then
    ./setup/debinstall.sh
else
    echo "Attention: setup/debinstall.sh introuvable ou non exécutable, étape sautée."
fi

echo "== Configuration PostgreSQL =="
# Création de l’utilisateur s’il n’existe pas déjà
if sudo -u postgres psql -tAc "SELECT 1 FROM pg_roles WHERE rolname='${DB_USER}'" | grep -q 1; then
    echo "Utilisateur PostgreSQL ${DB_USER} existe déjà, on ne le recrée pas."
else
    sudo -u postgres createuser -d -R -S "${DB_USER}"
    echo "Utilisateur PostgreSQL ${DB_USER} créé."
fi

# Création de la base si elle n’existe pas
if sudo -u postgres psql -lqt | cut -d \| -f 1 | tr -d ' ' | grep -qw "${DB_NAME}"; then
    echo "Base de données ${DB_NAME} existe déjà, on ne la recrée pas."
else
    su - postgres -c "createdb -O '${DB_USER}' -E UTF8 -T template0 '${DB_NAME}'"
    echo "Base de données ${DB_NAME} créée."
fi

# Mot de passe optionnel
if [[ -n "${DB_PASSWORD}" ]]; then
    sudo -u postgres psql -c "ALTER USER ${DB_USER} WITH PASSWORD '${DB_PASSWORD}';"
    echo "Mot de passe mis à jour pour l’utilisateur ${DB_USER}."
fi

echo "== Installation terminée =="
echo "Répertoire Odoo : ${INSTALL_DIR}/odoo"
echo "DB: ${DB_NAME} (user: ${DB_USER})"
