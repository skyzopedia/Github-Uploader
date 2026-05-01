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
while true; do
  read -p "🔑 Masukkan GitHub Token: " token

  info "Memvalidasi Token..."
  username=$(curl -s -H "Authorization: token $token" https://api.github.com/user | grep '"login"' | cut -d '"' -f4)

  if [ -n "$username" ]; then
    success "Login Sebagai: $username"
    break
  else
    error "Token Tidak Valid, Coba Lagi!"
  fi
done

echo ""

# =========================
# AMBIL REPO
# =========================
info "Mengambil Daftar Repository..."
repos=$(curl -s -H "Authorization: token $token" https://api.github.com/user/repos?per_page=100 | grep '"name"' | cut -d '"' -f4)

line
echo -e "${CYAN}📦 Pilih Repository${NC}"
line

echo -e "${YELLOW}[0]${NC} Buat Repository Baru"

i=1
declare -a repo_list

while read -r repo; do
  echo -e "${YELLOW}[$i]${NC} $repo"
  repo_list[$i]=$repo
  ((i++))
done <<< "$repos"

while true; do
  echo ""
  read -p "👉 Masukkan Nomor Repository: " pilih_repo

  if [ "$pilih_repo" = "0" ]; then
    while true; do
      read -p "✨ Masukkan Nama Repository Baru: " repo
      [ -n "$repo" ] && break || warn "Nama tidak boleh kosong"
    done

    echo ""
    echo -e "${CYAN}🔓 Pilih Visibilitas${NC}"
    echo -e "${YELLOW}[1]${NC} Public"
    echo -e "${YELLOW}[2]${NC} Private"

    while true; do
      read -p "👉 Pilih (1/2): " vis
      case $vis in
        1) private=false; break ;;
        2) private=true; break ;;
        *) warn "Pilih 1 atau 2" ;;
      esac
    done

    info "Membuat repository..."
    res=$(curl -s -X POST https://api.github.com/user/repos \
      -H "Authorization: token $token" \
      -d "{\"name\":\"$repo\",\"private\":$private}")

    echo "$res" | grep -q '"full_name"' && success "Repo dibuat" || { error "Gagal buat repo"; exit 1; }

    break
  else
    repo=${repo_list[$pilih_repo]}
    [ -n "$repo" ] && { success "Repository Dipilih: $repo"; break; } || warn "Pilihan salah"
  fi
done

echo ""

# =========================
# AMBIL BRANCH
# =========================
info "Mengambil Daftar Branch..."
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

echo -e "${YELLOW}[0]${NC} Buat Branch Baru / Default (main)"

while true; do
  echo ""
  read -p "👉 Masukkan Nomor Branch: " pilih_branch

  if [ "$pilih_branch" = "0" ]; then
    read -p "✨ Nama Branch (kosong = main): " branch
    [ -z "$branch" ] && branch="main"
    break
  else
    branch=${branch_list[$pilih_branch]}
    [ -n "$branch" ] && break || warn "Pilihan tidak valid"
  fi
done

success "Branch Dipilih: $branch"
echo ""

# =========================
# SETUP GIT (FIXED)
# =========================
info "Menyiapkan Repository Lokal..."

if [ -d ".git" ]; then
  warn "Menghapus .git lama..."
  rm -rf .git
  success ".git dihapus"
fi

git init > /dev/null 2>&1

git checkout -b "$branch" > /dev/null 2>&1 || git checkout "$branch"

git config user.name "$username"
git config user.email "$username@users.noreply.github.com"

info "Menambahkan file..."
git add .

if git diff --cached --quiet; then
  warn "Tidak ada perubahan, commit kosong..."
  git commit --allow-empty -m "Init" > /dev/null 2>&1
else
  git commit -m "Upload: $(date)" > /dev/null 2>&1
  success "Commit berhasil"
fi

remote_url="https://$token@github.com/$username/$repo.git"
git remote add origin "$remote_url" 2>/dev/null || git remote set-url origin "$remote_url"

# =========================
# PUSH
# =========================
line
info "Mengunggah ke GitHub..."
line

if git push -u origin "$branch"; then
  success "Upload Berhasil!"
else
  warn "Push gagal, force push..."
  git push -u origin "$branch" --force
  success "Force push berhasil!"
fi

echo ""
line
echo -e "${GREEN}🎉 SELESAI!${NC}"
echo -e "${CYAN}🔗 https://github.com/$username/$repo${NC}"
line
