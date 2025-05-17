#!/data/data/com.termux/files/usr/bin/bash

read -p "GitHub Username: " username
read -p "Repository Name: " repo
read -p "Branch (default: main): " branch
branch=${branch:-main}
read -p "GitHub Token: " token

echo "[*] Inisialisasi Git repo…"
git init

# Setup user info (gunakan username GitHub dan email default)
git config --global user.name "$username"
git config --global user.email "$username@users.noreply.github.com"

# Tandai direktori ini sebagai aman
git config --global --add safe.directory "$(pwd)"

echo "[*] Menambahkan semua file…"
git add .

# Commit dengan timestamp
git commit -m "Upload: $(date)"

# Pastikan branch bernama main (atau sesuai input)
git branch -M $branch

# Tambahkan remote
git remote add origin https://$username:$token@github.com/$username/$repo.git

echo "[*] Push ke GitHub…"
git push -u origin $branch

echo "[v] Upload selesai ke $repo di cabang $branch!"
