#!/bin/bash

echo "GitHub Username: "
read username
echo "Repository Name: "
read repo
echo "Branch (default: main): "
read branch
branch=${branch:-main}
echo "GitHub Token: "
read token

# Inisialisasi Git
echo "[*] Inisialisasi Git repo..."
git init

# Tambahkan direktori aktif sebagai safe.directory
current_dir=$(pwd)
git config --global --add safe.directory "$current_dir"

# Tambahkan remote origin
git remote remove origin 2>/dev/null
git remote add origin https://$username:$token@github.com/$username/$repo.git

# Tambahkan semua file, commit, dan push
echo "[*] Menambahkan semua file..."
git add .
echo "[*] Commit dengan pesan: Upload"
git commit -m "Upload: $(date)"

echo "[*] Push ke GitHub..."
git branch -M $branch
git push -u origin $branch

echo "[v] Upload selesai ke $repo di cabang $branch!"
