# 🔐 Virtualizor MySQL Password Rotation Script

A secure Bash script to **automatically rotate MySQL root password** for Virtualizor, while ensuring your configuration and database are backed up safely.

---

🛑 Important Notes
Ensure no Virtualizor operations are running during execution.

---

## 📜 About

This script is designed for **Virtualizor installations using the EMPS stack** (Embedded MySQL + PHP stack) and performs the following actions:

1. Verifies current MySQL root password using credentials from `universal.php`
2. Creates a timestamped backup of:
   - `universal.php` (Virtualizor config)
   - Virtualizor MySQL database
3. Generates a new strong random password
4. Applies the new password to MySQL
5. Updates `universal.php` with the new password
6. Confirms that the new password works

---

## ✅ Features

- 🔐 Secure password generation (`openssl`)
- 📦 Automatic timestamped backups
- 🛡️ Failsafe checks before making any change
- 📁 Backup stored in `/root/virtualizor_backup_<timestamp>/`
- 🧩 Fully standalone and root-safe

---

## 📁 Files Created

Each run generates:

/root/virtualizor_backup_YYYYMMDD_HHMMSS/
├── universal.php.bak
└── virtualizor_db_YYYYMMDD_HHMMSS.sql

## 🚀 Usage

### Step 1: Download the Script

```bash
git clone https://github.com/Xdfx00/Virtualizor-database-scripts.git
cd Virtualizor-database-scripts
chmod +x db_password_change.sh
./db_password_change.sh
