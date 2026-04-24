set -e

echo "=== GitHub Auto Uploader ==="

read -p "GitHub Username: " username
read -p "Repository Name: " repo
read -p "Branch (default: main): " branch
branch=${branch:-main}
read -p "GitHub Token: " token

echo ""
echo "[*] Persiapan repository..."

# 🔥 FIX: hapus .git lama kalau ada
if [ -d ".git" ]; then
  echo "[!] Ditemukan folder .git lama"
  read -p "Hapus dan ulangi? (y/n): " confirm
  if [ "$confirm" = "y" ]; then
    rm -rf .git
    echo "[✔] .git lama dihapus"
  else
    echo "[!] Dibatalkan"
    exit 1
  fi
fi

# Init repo baru
git init

# Config lokal (bukan global biar aman)
git config user.name "$username"
git config user.email "$username@users.noreply.github.com"

# Safe directory
git config --global --add safe.directory "$(pwd)"

echo "[*] Menambahkan file..."
git add .

# 🔥 FIX: cek apakah ada perubahan
if git diff --cached --quiet; then
  echo "[!] Tidak ada perubahan untuk di-commit"
else
  git commit -m "Upload: $(date)"
fi

# Set branch
git branch -M "$branch"

# 🔥 FIX: handle remote
remote_url="https://$username:$token@github.com/$username/$repo.git"

if git remote | grep origin > /dev/null; then
  echo "[*] Remote origin sudah ada, mengganti..."
  git remote set-url origin "$remote_url"
else
  git remote add origin "$remote_url"
fi

echo "[*] Push ke GitHub..."

# 🔥 FIX: push dengan retry
git push -u origin "$branch" || {
  echo "[!] Push gagal, mencoba force push..."
  git push -u origin "$branch" --force
}

echo ""
echo "[✔] Upload selesai!"
echo "Repo: https://github.com/$username/$repo"
echo "Branch: $branch"
