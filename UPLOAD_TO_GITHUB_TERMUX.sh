#!/data/data/com.termux/files/usr/bin/bash
set -e

if [ "$#" -lt 1 ]; then
  echo "Uso: ./UPLOAD_TO_GITHUB_TERMUX.sh https://github.com/USUARIO/REPOSITORIO.git"
  exit 1
fi
REPO="$1"

command -v git >/dev/null || { echo "Falta git. Instala: pkg install git"; exit 1; }

if [ ! -f .github/workflows/build-android.yml ]; then
  echo "Ejecuta este script desde la carpeta del proyecto descomprimida."
  exit 1
fi

git init
git branch -M main
git add .
git commit -m "Aliens Invasion Android v40"
git remote remove origin 2>/dev/null || true
git remote add origin "$REPO"
git push -u origin main

echo
echo "LISTO: el proyecto fue enviado a GitHub."
echo "Ahora entra a Actions y ejecuta Build Aliens Invasion Android APK."
