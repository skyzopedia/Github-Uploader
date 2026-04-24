#!/data/data/com.termux/files/usr/bin/bash

set -e

# =========================
# WARNA
# =========================
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # no color

line() {
  echo -e "${CYAN}----------------------------------------${NC}"
}

success() {
  echo -e "${GREEN}[✔] $1${NC}"
}

error() {
  echo -e "${RED}[✖] $1${NC}"
}

warn() {
  echo -e "${YELLOW}[!] $1${NC}"
}

info() {
  echo -e "${BLUE}[*] $1${NC}"
}

# =========================
# HEADER
# =========================
clear
line
echo -e "${CYAN}   🚀 GitHub Smart Uploader${NC}"
line
echo ""

# =========================
# INPUT TOKEN
# =========================
read -p "🔑 Masukkan GitHub Token: " token
echo ""

# =========================
# AMBIL USERNAME
# =========================
info "Mengambil data akun..."
username=$(curl -s -H "Authorization: token $token" https://api.github.com/user | grep '"login"' | cut -d '"' -f4)

if [ -z "$username" ]; then
  error "Token tidak valid!"
  exit 1
fi

success "Login sebagai: $username"
echo ""

# =========================
# PILIH REPO
# =========================
info "Mengambil daftar repository..."
repos=$(curl -s -H "Authorization: token $token" https://api.github.com/user/repos?per_page=100 | grep '"name"' | cut -d '"' -f4)

if [ -z "$repos" ]; then
  error "Tidak ada repository"
  exit 1
fi

line
echo -e "${CYAN}📦 Pilih Repository${NC}"
line

i=1
declare -a repo_list

while read -r repo; do
  echo -e "${YELLOW}[$i]${NC} $repo"
  repo_list[$i]=$repo
  ((i++))
done <<< "$repos"

echo ""
read -p "👉 Pilih nomor repo: " pilih_repo

repo=${repo_list[$pilih_repo]}

if [ -z "$repo" ]; then
  error "Pilihan repo tidak valid"
  exit 1
fi

success "Repo dipilih: $repo"
echo ""

# =========================
# PILIH BRANCH
# =========================
info "Mengambil daftar branch..."

branches=$(curl -s -H "Authorization: token $token" https://api.github.com/repos/$username/$repo/branches | grep '"name"' | cut -d '"' -f4)

line
echo -e "${CYAN}🌿 Pilih Branch${NC}"
line

if [ -z "$branches" ]; then
  warn "Tidak ada branch, gunakan 'main'"
  branch="main"
else
  i=1
  declare -a branch_list

  while read -r b; do
    echo -e "${YELLOW}[$i]${NC} $b"
    branch_list[$i]=$b
    ((i++))
  done <<< "$branches"

  echo -e "${YELLOW}[0]${NC} Buat branch baru"
  echo ""

  read -p "👉 Pilih nomor branch: " pilih_branch

  if [ "$pilih_branch" = "0" ]; then
    read -p "✨ Nama branch baru: " branch
  else
    branch=${branch_list[$pilih_branch]}
  fi

  if [ -z "$branch" ]; then
    error "Pilihan branch tidak valid"
    exit 1
  fi
fi

success "Branch dipilih: $branch"
echo ""

# =========================
# SETUP GIT
# =========================
info "Menyiapkan repository..."

if [ -d ".git" ]; then
  warn "Ditemukan folder .git lama"
  read -p "❓ Hapus? (y/n): " confirm
  if [ "$confirm" = "y" ]; then
    rm -rf .git
    success ".git lama dihapus"
  else
    error "Dibatalkan"
    exit 1
  fi
fi

git init > /dev/null 2>&1

git config user.name "$username"
git config user.email "$username@users.noreply.github.com"

info "Menambahkan file..."
git add .

if git diff --cached --quiet; then
  warn "Tidak ada perubahan"
else
  git commit -m "Upload: $(date)" > /dev/null 2>&1
  success "Commit berhasil"
fi

git branch -M "$branch"

remote_url="https://$token@github.com/$username/$repo.git"

if git remote | grep origin > /dev/null; then
  info "Update remote origin..."
  git remote set-url origin "$remote_url"
else
  info "Menambahkan remote..."
  git remote add origin "$remote_url"
fi

# =========================
# PUSH
# =========================
line
info "Mengupload ke GitHub..."
line

if git push -u origin "$branch"; then
  success "Upload berhasil!"
else
  warn "Push gagal, mencoba force..."
  git push -u origin "$branch" --force
  success "Force push berhasil!"
fi

echo ""
line
echo -e "${GREEN}🎉 SELESAI!${NC}"
echo -e "${CYAN}🔗 https://github.com/$username/$repo${NC}"
line
