#!/bin/bash


###############################################################################
# Script Name:     db_password_change.sh
# Description:     Backs up Virtualizor MySQL DB and universal.php, then
#                  rotates the MySQL root password and updates universal.php.
#
# Author:          Aman Shaikh
# Version:         1.0.0
# Last Updated:    2025-07-20
###############################################################################

# === Configuration ===
UNIVERSAL_FILE="/usr/local/virtualizor/universal.php"
MYSQL="/usr/local/emps/bin/mysql"
MYSQL_DUMP="/usr/local/emps/bin/mysqldump"
DATABASE_NAME="virtualizor"
BACKUP_DIR="/root/virtualizor_backup_$(date +%Y%m%d_%H%M%S)"
mkdir -p "$BACKUP_DIR"

# === Colors ===
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[1;34m'
NC='\033[0m' # No Color

# === Generate a random password ===
NEW_PASS=$(openssl rand -hex 5)
echo -e "${BLUE}Generated new MySQL password:${NC} $NEW_PASS"

set -e

# === Root user check ===
if [ "$(id -u)" != "0" ]; then
    echo -e "${RED}✗ This script must be run as root${NC}"
    exit 1
fi

# === Extract current DB password from universal.php ===
get_pass=$(grep "\['dbpass'\]" "$UNIVERSAL_FILE" | cut -d"'" -f4)


# === Test if current DB password is working ===
echo -e "${YELLOW}Testing current MySQL root password...${NC}"
if $MYSQL -u root -p"$get_pass" -e "SELECT 1;" &>/dev/null; then
    echo -e "${GREEN}✓ Current password is valid${NC}"
else
    echo -e "${RED}✗ Current password test failed. Aborting.${NC}"
    exit 1
fi

# === Backup universal.php ===
echo -e "${YELLOW}Backing up universal.php...${NC}"
cp "$UNIVERSAL_FILE" "$BACKUP_DIR/universal.php.bak"
if [ $? -eq 0 ]; then
    echo -e "${GREEN}✓ Backup created:${NC} $BACKUP_DIR/universal.php.bak"
else
    echo -e "${RED}✗ Failed to backup universal.php${NC}"
    exit 1
fi

# === Backup Virtualizor MySQL database ===
echo -e "${YELLOW}Creating database backup...${NC}"
DB_BACKUP="$BACKUP_DIR/virtualizor_db_$(date +%Y%m%d_%H%M%S).sql"
$MYSQL_DUMP --single-transaction --quick --lock-tables=false -u root -p"$get_pass" "$DATABASE_NAME" > "$DB_BACKUP"

if [ $? -eq 0 ]; then
    echo -e "${GREEN}✓ Database backup saved to:${NC} $DB_BACKUP"
else
    echo -e "${RED}✗ Database backup failed${NC}"
    exit 1
fi

# === Change MySQL root password ===
echo -e "${YELLOW}Updating MySQL root password...${NC}"
$MYSQL -u root -p"$get_pass" -e "SET PASSWORD FOR 'root'@'localhost' = PASSWORD('$NEW_PASS'); FLUSH PRIVILEGES;"
if [ $? -eq 0 ]; then
    echo -e "${GREEN}✓ MySQL root password updated${NC}"
else
    echo -e "${RED}✗ Failed to update MySQL password${NC}"
    exit 1
fi

# === Update the password in script context ===
get_pass="$NEW_PASS"

# === Update password in universal.php ===
echo -e "${YELLOW}Updating universal.php with new password...${NC}"
sed -i "s/\(\['dbpass'\][[:space:]]*=[[:space:]]*'\)[^']*\(';\)/\1$NEW_PASS\2/" "$UNIVERSAL_FILE"
if [ $? -eq 0 ]; then
    echo -e "${GREEN}✓ universal.php updated with new password${NC}"
else
    echo -e "${RED}✗ Failed to update universal.php${NC}"
    exit 1
fi

# === Final test: confirm new password works ===
echo -e "${YELLOW}Verifying new password works...${NC}"
if $MYSQL -u root -p"$get_pass" -e "SELECT 'Connection successful' AS Status;" &>/dev/null; then
    echo -e "${GREEN}✓ New password verified successfully${NC}"
else
    echo -e "${RED}✗ New password test failed${NC}"
    exit 1
fi

# === Done ===
echo -e "${BLUE}✔ All steps completed successfully.${NC}"
echo -e "${BLUE}Backup directory:${NC} $BACKUP_DIR"
