ALIENS INVASION - SUBIR A GITHUB DESDE ANDROID

IMPORTANTE: GitHub no descomprime automaticamente un ZIP subido como archivo.
Por eso, desde Android la forma mas sencilla es usar Termux para hacer el primer push.

1) Instala Termux desde F-Droid/GitHub oficial.
2) Copia esta carpeta al almacenamiento de Termux o trabaja desde Downloads.
3) En Termux instala git:
   pkg update
   pkg install git
4) Configura Git una vez:
   git config --global user.name "Tu nombre"
   git config --global user.email "tu@email.com"
5) Crea un repositorio VACIO en GitHub (sin README ni .gitignore).
6) Ejecuta desde esta carpeta:
   ./UPLOAD_TO_GITHUB_TERMUX.sh https://github.com/TU_USUARIO/TU_REPO.git
7) GitHub -> Actions -> Build Aliens Invasion Android APK -> Run workflow.
8) Al terminar, abre Artifacts -> aliens-invasion-v40-android y descarga la APK.

Si GitHub pide autenticacion por HTTPS, usa tu usuario y un Personal Access Token (PAT),
no tu contraseña normal de GitHub.
