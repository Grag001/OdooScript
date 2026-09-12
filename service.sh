#!/usr/bin/env bash
set -euo pipefail

# ==========================================
#  Script de création du service Odoo
# ==========================================
# Usage :
#   ./install_service.sh -u odoo -r /opt/odoo
# Options :
#   -u  Nom de l’utilisateur système qui exécutera Odoo (défaut: utilisateur courant ou 'odoo')
#   -r  Répertoire racine d’install (défaut: /opt/odoo)
#   -h  Aide

SYSTEM_USER="${SUDO_USER:-odoo}"
INSTALL_DIR="/opt/odoo"

usage() {
    echo "Usage: $0 [-u system_user] [-r install_dir]"
    echo "Exemple: $0 -u odoo -r /opt/odoo"
    exit 1
}

while getopts ":u:r:h" opt; do
  case ${opt} in
    u ) SYSTEM_USER="$OPTARG" ;;
    r ) INSTALL_DIR="$OPTARG" ;;
    h ) usage ;;
    \? ) echo "Option invalide: -$OPTARG" ; usage ;;
    : ) echo "Option -$OPTARG requiert une valeur." ; usage ;;
  esac
done

ODOO_BIN="${INSTALL_DIR}/odoo/odoo-bin"

echo "===== Configuration du Service ====="
echo "Utilisateur Odoo : ${SYSTEM_USER}"
echo "Exécutable Odoo  : ${ODOO_BIN}"
echo "===================================="

# Vérification des droits root
if [[ $EUID -ne 0 ]]; then
    echo "Merci de lancer ce script avec sudo (sudo $0 ...)."
    exit 1
fi

# Vérification que l'exécutable existe bien
if [[ ! -f "${ODOO_BIN}" ]]; then
    echo "Erreur : L'exécutable Odoo n'a pas été trouvé à l'emplacement ${ODOO_BIN}."
    echo "Vérifiez le chemin d'installation avec l'option -r."
    exit 1
fi

# Vérification de l'existence de l'utilisateur système
if ! id -u "${SYSTEM_USER}" > /dev/null 2>&1; then
    echo "L'utilisateur système '${SYSTEM_USER}' n'existe pas. Création en cours..."
    useradd -m -d "${INSTALL_DIR}" -U -r -s /bin/bash "${SYSTEM_USER}"
fi

# Assurer que l'utilisateur a les droits sur le dossier Odoo
chown -R "${SYSTEM_USER}:${SYSTEM_USER}" "${INSTALL_DIR}"

echo "== Création du fichier /etc/systemd/system/odoo.service =="

cat <<EOF > /etc/systemd/system/odoo.service
[Unit]
Description=Odoo Open Source ERP and CRM
Requires=postgresql.service
After=network.target postgresql.service

[Service]
ExecStart=/usr/bin/python3 ${ODOO_BIN}
StandardOutput=journal+console
EOF

echo "== Rechargement de systemd =="
systemctl daemon-reload

echo "== Activation du service Odoo (démarrage automatique) =="
systemctl enable odoo.service

echo "== Démarrage du service Odoo =="
systemctl restart odoo.service

echo "== Terminé ! =="
echo "Vous pouvez vérifier l'état du service avec :"
echo "  sudo systemctl status odoo"
echo "Vous pouvez consulter les logs avec :"
echo "  sudo journalctl -u odoo -f"
