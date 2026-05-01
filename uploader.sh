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

line(){ echo -e "${CYAN}----------------------------------------${NC}"; }
success(){ echo -e "${GREEN}[✔] $1${NC}"; }
error(){ echo -e "${RED}[✖] $1${NC}"; }
warn(){ echo -e "${YELLOW}[!] $1${NC}"; }
info(){ echo -e "${BLUE}[*] $1${NC}"; }

clear
line
echo -e "${CYAN}🚀 GitHub Smart Uploader (Stable)${NC}"
line
echo ""

# =========================
# 🔥 AUTO FIX TERMUX GIT
# =========================
git config --global --add safe.directory "$(pwd)" 2>/dev/null
git config --global init.defaultBranch main 2>/dev/null

# =========================
# 🔥 HAPUS .git DI AWAL
# =========================
if [ -d ".git" ]; then
  warn "Folder .git lama terdeteksi (awal), menghapus..."
  rm -rf .git
  success ".git berhasil dibersihkan"
fi

# =========================
# TOKEN
# =========================
while true; do
  read -p "🔑 Masukkan GitHub Token: " token

  info "Validasi token..."
  username=$(curl -s -H "Authorization: token $token" https://api.github.com/user | grep '"login"' | cut -d '"' -f4)

  [ -n "$username" ] && { success "Login: $username"; break; } || error "Token salah!"
done

echo ""

# =========================
# REPO
# =========================
info "Mengambil repository..."
repos=$(curl -s -H "Authorization: token $token" https://api.github.com/user/repos?per_page=100 | grep '"name"' | cut -d '"' -f4)

line
echo -e "${CYAN}📦 Pilih Repository${NC}"
line
echo -e "${YELLOW}[0]${NC} Buat Repository Baru"

i=1
declare -a repo_list

while read -r r; do
  echo -e "${YELLOW}[$i]${NC} $r"
  repo_list[$i]=$r
  ((i++))
done <<< "$repos"

while true; do
  read -p "👉 Nomor: " pilih_repo

  if [ "$pilih_repo" = "0" ]; then
    read -p "Nama repo: " repo
    read -p "Private? (y/n): " p
    [ "$p" = "y" ] && private=true || private=false

    curl -s -X POST https://api.github.com/user/repos \
      -H "Authorization: token $token" \
      -d "{\"name\":\"$repo\",\"private\":$private}" >/dev/null

    success "Repo dibuat"
    break
  else
    repo=${repo_list[$pilih_repo]}
    [ -n "$repo" ] && { success "Repo: $repo"; break; } || warn "Salah pilih"
  fi
done

echo ""

# =========================
# BRANCH
# =========================
info "Mengambil branch..."
branches=$(curl -s -H "Authorization: token $token" https://api.github.com/repos/$username/$repo/branches | grep '"name"' | cut -d '"' -f4)

line
echo -e "${CYAN}🌿 Pilih Branch${NC}"
line

i=1
declare -a branch_list

while read -r b; do
  echo -e "${YELLOW}[$i]${NC} $b"
  branch_list[$i]=$b
  ((i++))
done <<< "$branches"

echo -e "${YELLOW}[0]${NC} Default / Buat Baru (main)"

while true; do
  read -p "👉 Nomor: " pilih_branch

  if [ "$pilih_branch" = "0" ]; then
    read -p "Nama branch (kosong=main): " branch
    [ -z "$branch" ] && branch="main"
    break
  else
    branch=${branch_list[$pilih_branch]}
    [ -n "$branch" ] && break || warn "Pilihan salah"
  fi
done

success "Branch: $branch"
echo ""

# =========================
# SETUP GIT
# =========================
info "Setup git..."

git init > /dev/null 2>&1

git checkout -b "$branch" > /dev/null 2>&1 || git checkout "$branch"

git config user.name "$username"
git config user.email "$username@users.noreply.github.com"

git add .

if git diff --cached --quiet; then
  warn "Kosong → commit init"
  git commit --allow-empty -m "Init" > /dev/null 2>&1
else
  git commit -m "Upload: $(date)" > /dev/null 2>&1
  success "Commit OK"
fi

remote_url="https://$token@github.com/$username/$repo.git"
git remote add origin "$remote_url" 2>/dev/null || git remote set-url origin "$remote_url"

# =========================
# PUSH
# =========================
line
info "Push ke GitHub..."
line

git push -u origin "$branch" 2>/dev/null || git push -u origin "$branch" --force

success "Upload selesai!"
echo ""
echo -e "${CYAN}https://github.com/$username/$repo${NC}"
line
