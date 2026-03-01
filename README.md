# OdooScript
Ceci est un script simple permettant d’installer Odoo sur un conteneur LXC sous Ubuntu 24.04.
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
