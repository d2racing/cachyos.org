#!/bin/bash

# Script de test de disque dur externe
# Utilise smartmontools pour effectuer des tests SMART

# Couleurs pour l'affichage
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}==================================================${NC}"
echo -e "${BLUE}  Script de Test de Disque Dur Externe${NC}"
echo -e "${BLUE}==================================================${NC}"
echo ""

# Vérifier si smartctl est installé
if ! command -v smartctl &> /dev/null; then
    echo -e "${RED}Erreur: smartctl n'est pas installé${NC}"
    echo "Installation:"
    echo "  CachyOS sudo pacman -S smartmontools"
    exit 1
fi

# Lister les disques disponibles
echo -e "${YELLOW}Disques disponibles:${NC}"
if [[ "$OSTYPE" == "linux-gnu"* ]]; then
    lsblk -d -o NAME,SIZE,MODEL,TRAN | grep -E "sd|nvme"
fi
echo ""

# Demander le disque à tester
read -p "Entrez le chemin du disque à tester (ex: /dev/sdb ou /dev/disk2): " DISK

# Vérifier si le disque existe
if [ ! -e "$DISK" ]; then
    echo -e "${RED}Erreur: Le disque $DISK n'existe pas${NC}"
    exit 1
fi

echo ""
echo -e "${GREEN}Disque sélectionné: $DISK${NC}"
echo ""

# Fonction pour afficher les informations SMART
show_smart_info() {
    echo -e "${BLUE}--- Informations SMART du disque ---${NC}"
    sudo smartctl -i "$DISK"
    echo ""
}

# Fonction pour vérifier si SMART est activé
check_smart_enabled() {
    echo -e "${YELLOW}Vérification de l'activation SMART...${NC}"
    if sudo smartctl -i "$DISK" | grep -q "SMART support is: Enabled"; then
        echo -e "${GREEN}✓ SMART est activé${NC}"
    else
        echo -e "${YELLOW}SMART n'est pas activé. Tentative d'activation...${NC}"
        sudo smartctl -s on "$DISK"
    fi
    echo ""
}

# Fonction pour afficher la santé globale
check_health() {
    echo -e "${BLUE}--- État de santé global ---${NC}"
    sudo smartctl -H "$DISK"
    echo ""
}

# Fonction pour afficher les attributs SMART
show_attributes() {
    echo -e "${BLUE}--- Attributs SMART détaillés ---${NC}"
    sudo smartctl -A "$DISK"
    echo ""
}

# Fonction pour le test court
run_short_test() {
    echo -e "${YELLOW}==================================================${NC}"
    echo -e "${YELLOW}  Lancement du test SMART COURT${NC}"
    echo -e "${YELLOW}==================================================${NC}"
    echo "Durée estimée: 1-2 minutes"
    echo ""
    
    sudo smartctl -t short "$DISK"
    
    echo -e "${YELLOW}Test court en cours... Veuillez patienter 2 minutes${NC}"
    sleep 120
    
    echo ""
    echo -e "${BLUE}--- Résultats du test court ---${NC}"
    sudo smartctl -l selftest "$DISK"
    echo ""
}

# Fonction pour le test long
run_long_test() {
    echo -e "${YELLOW}==================================================${NC}"
    echo -e "${YELLOW}  Lancement du test SMART LONG${NC}"
    echo -e "${YELLOW}==================================================${NC}"
    
    # Obtenir la durée estimée du test
    DURATION=$(sudo smartctl -c "$DISK" | grep "Extended self-test routine" | awk '{print $5}')
    echo "Durée estimée: $DURATION minutes"
    echo ""
    
    read -p "Le test long peut prendre plusieurs heures. Continuer? (o/n): " CONFIRM
    if [[ $CONFIRM != "o" && $CONFIRM != "O" ]]; then
        echo "Test long annulé"
        return
    fi
    
    sudo smartctl -t long "$DISK"
    
    echo -e "${YELLOW}Test long en cours...${NC}"
    echo "Vous pouvez vérifier la progression avec:"
    echo "  sudo smartctl -a $DISK"
    echo ""
    echo "Le script va vérifier l'état toutes les 5 minutes..."
    
    # Boucle pour vérifier l'état du test
    while true; do
        sleep 300  # Attendre 5 minutes
        STATUS=$(sudo smartctl -a "$DISK" | grep "Self-test execution status")
        echo "$STATUS"
        
        if echo "$STATUS" | grep -q "completed without error\|00%"; then
            echo -e "${GREEN}Test terminé!${NC}"
            break
        fi
    done
    
    echo ""
    echo -e "${BLUE}--- Résultats du test long ---${NC}"
    sudo smartctl -l selftest "$DISK"
    echo ""
}

# Fonction pour générer un rapport complet
generate_report() {
    REPORT_FILE="disk_test_report_$(date +%Y%m%d_%H%M%S).txt"
    echo -e "${BLUE}Génération du rapport complet: $REPORT_FILE${NC}"
    
    {
        echo "=========================================="
        echo "Rapport de Test de Disque Dur"
        echo "Date: $(date)"
        echo "Disque: $DISK"
        echo "=========================================="
        echo ""
        
        echo "--- Informations du disque ---"
        sudo smartctl -i "$DISK"
        echo ""
        
        echo "--- État de santé ---"
        sudo smartctl -H "$DISK"
        echo ""
        
        echo "--- Attributs SMART ---"
        sudo smartctl -A "$DISK"
        echo ""
        
        echo "--- Historique des tests ---"
        sudo smartctl -l selftest "$DISK"
        echo ""
        
        echo "--- Erreurs enregistrées ---"
        sudo smartctl -l error "$DISK"
        echo ""
        
        echo "--- Rapport complet ---"
        sudo smartctl -a "$DISK"
        
    } > "$REPORT_FILE"
    
    echo -e "${GREEN}✓ Rapport sauvegardé: $REPORT_FILE${NC}"
    echo ""
}

# Menu principal
main_menu() {
    while true; do
        echo -e "${BLUE}==================================================${NC}"
        echo -e "${BLUE}  Menu Principal${NC}"
        echo -e "${BLUE}==================================================${NC}"
        echo "1. Afficher les informations du disque"
        echo "2. Vérifier l'état de santé"
        echo "3. Afficher les attributs SMART"
        echo "4. Lancer le test COURT (2 minutes)"
        echo "5. Lancer le test LONG (plusieurs heures)"
        echo "6. Lancer test COURT puis LONG (automatique)"
        echo "7. Générer un rapport complet"
        echo "8. Tout exécuter (tests + rapport)"
        echo "9. Quitter"
        echo ""
        read -p "Choisissez une option (1-9): " CHOICE
        echo ""
        
        case $CHOICE in
            1) show_smart_info ;;
            2) check_health ;;
            3) show_attributes ;;
            4) run_short_test ;;
            5) run_long_test ;;
            6) 
                run_short_test
                run_long_test
                ;;
            7) generate_report ;;
            8)
                show_smart_info
                check_smart_enabled
                check_health
                show_attributes
                run_short_test
                run_long_test
                generate_report
                echo -e "${GREEN}==================================================${NC}"
                echo -e "${GREEN}  Tous les tests sont terminés!${NC}"
                echo -e "${GREEN}==================================================${NC}"
                ;;
            9)
                echo -e "${GREEN}Au revoir!${NC}"
                exit 0
                ;;
            *)
                echo -e "${RED}Option invalide${NC}"
                ;;
        esac
        
        read -p "Appuyez sur Entrée pour continuer..."
        clear
    done
}

# Exécution principale
clear
show_smart_info
check_smart_enabled
main_menu
