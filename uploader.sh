#!/data/data/com.termux/files/usr/bin/bash

# Prompt user untuk input token dan info repo
read -p "GitHub Username: " USERNAME
read -p "Repository Name: " REPO_NAME
read -p "Branch (default: main): " BRANCH
read -sp "GitHub Token: " GITHUB_TOKEN
echo

# Default ke 'main' jika tidak diisi
BRANCH=${BRANCH:-main}

REPO_URL="https://${GITHUB_TOKEN}@github.com/${USERNAME}/${REPO_NAME}.git"

# Inisialisasi git repo jika belum
if [ ! -d .git ]; then
    echo "[*] Inisialisasi Git repo..."
    git init
    git remote add origin "$REPO_URL"
else
    git remote set-url origin "$REPO_URL"
fi

# Tambahkan dan commit semua file
echo "[*] Menambahkan semua file..."
git add .

COMMIT_MSG="Upload: $(date)"
echo "[*] Commit dengan pesan: $COMMIT_MSG"
git commit -m "$COMMIT_MSG"

# Push ke repo
echo "[*] Push ke GitHub..."
git branch -M "$BRANCH"
git push -u origin "$BRANCH"

echo "[✓] Upload selesai ke $REPO_NAME di cabang $BRANCH!"