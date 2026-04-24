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
NC='\033[0m'

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
info "Mengambil Data Akun..."
username=$(curl -s -H "Authorization: token $token" https://api.github.com/user | grep '"login"' | cut -d '"' -f4)

if [ -z "$username" ]; then
  error "Token Tidak Valid!"
  exit 1
fi

success "Berhasil Login Sebagai: $username"
echo ""

# =========================
# PILIH REPO
# =========================
info "Mengambil Daftar Repository..."
repos=$(curl -s -H "Authorization: token $token" https://api.github.com/user/repos?per_page=100 | grep '"name"' | cut -d '"' -f4)

if [ -z "$repos" ]; then
  error "Tidak Ditemukan Repository"
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
read -p "👉 Masukkan Nomor Repository: " pilih_repo

repo=${repo_list[$pilih_repo]}

if [ -z "$repo" ]; then
  error "Pilihan Repository Tidak Valid"
  exit 1
fi

success "Repository Dipilih: $repo"
echo ""

# =========================
# PILIH BRANCH
# =========================
info "Mengambil Daftar Branch..."

branches=$(curl -s -H "Authorization: token $token" https://api.github.com/repos/$username/$repo/branches | grep '"name"' | cut -d '"' -f4)

line
echo -e "${CYAN}🌿 Pilih Branch${NC}"
line

if [ -z "$branches" ]; then
  warn "Tidak Ditemukan Branch, Menggunakan 'main'"
  branch="main"
else
  i=1
  declare -a branch_list

  while read -r b; do
    echo -e "${YELLOW}[$i]${NC} $b"
    branch_list[$i]=$b
    ((i++))
  done <<< "$branches"

  echo -e "${YELLOW}[0]${NC} Buat Branch Baru"
  echo ""

  read -p "👉 Masukkan Nomor Branch: " pilih_branch

  if [ "$pilih_branch" = "0" ]; then
    read -p "✨ Masukkan Nama Branch Baru: " branch
  else
    branch=${branch_list[$pilih_branch]}
  fi

  if [ -z "$branch" ]; then
    error "Pilihan Branch Tidak Valid"
    exit 1
  fi
fi

success "Branch Dipilih: $branch"
echo ""

# =========================
# SETUP GIT
# =========================
info "Menyiapkan Repository..."

if [ -d ".git" ]; then
  warn "Ditemukan Folder .git Lama"
  read -p "❓ Apakah Ingin Menghapusnya? (y/n): " confirm
  if [ "$confirm" = "y" ]; then
    rm -rf .git
    success "Folder .git Lama Berhasil Dihapus"
  else
    error "Proses Dibatalkan"
    exit 1
  fi
fi

git init > /dev/null 2>&1

git config user.name "$username"
git config user.email "$username@users.noreply.github.com"

info "Menambahkan File ke Stage..."
git add .

if git diff --cached --quiet; then
  warn "Tidak Ada Perubahan untuk Di-commit"
else
  git commit -m "Upload: $(date)" > /dev/null 2>&1
  success "Commit Berhasil Dibuat"
fi

git branch -M "$branch"

remote_url="https://$token@github.com/$username/$repo.git"

if git remote | grep origin > /dev/null; then
  info "Memperbarui Remote Origin..."
  git remote set-url origin "$remote_url"
else
  info "Menambahkan Remote Origin..."
  git remote add origin "$remote_url"
fi

# =========================
# PUSH
# =========================
line
info "Mengunggah ke GitHub..."
line

if git push -u origin "$branch"; then
  success "Upload Berhasil!"
else
  warn "Push Gagal, Mencoba Force Push..."
  git push -u origin "$branch" --force
  success "Force Push Berhasil!"
fi

echo ""
line
echo -e "${GREEN}🎉 PROSES SELESAI!${NC}"
echo -e "${CYAN}🔗 https://github.com/$username/$repo${NC}"
line
