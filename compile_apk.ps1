$versionName = "1.2"
$versionCode = 3
$containerCpus = 4
$containerMemory = "8g"
$outputApkName = "DinoxoGamers-V1.2.apk"
$projectDir = "c:\IA\dinoxoGamers"
$destProjectPath = [System.IO.Path]::Combine($projectDir, $outputApkName)

# Remove previous APKs
Get-ChildItem -Path $projectDir -Filter "*.apk" -Recurse | Remove-Item -Force -ErrorAction SilentlyContinue

Write-Host "========================================="
Write-Host " Compilando Dinoxo Gamers APK ($outputApkName)"
Write-Host "========================================="

Write-Host "[1/4] Iniciando contenedor Flutter con caches persistentes..."
$containerId = (docker run -d --cpus $containerCpus --memory $containerMemory `
    -v dinoxo_android_keystore:/root/.android `
    -v dinoxo_flutter_pub_cache:/root/.pub-cache `
    -v dinoxo_gradle_cache:/root/.gradle `
    -v dinoxo_android_ndk:/opt/android-sdk-linux/ndk `
    -v dinoxo_android_platforms:/opt/android-sdk-linux/platforms `
    -v dinoxo_android_cmake:/opt/android-sdk-linux/cmake `
    ghcr.io/cirruslabs/flutter:stable sleep 3600)

if (-not $containerId -or $LASTEXITCODE -ne 0) {
    throw "Fallo al iniciar el contenedor de compilacion."
}
$containerId = $containerId.Trim()

try {
    Write-Host "[2/4] Copiando proyecto al contenedor..."
    docker exec $containerId mkdir -p /app
    docker cp "${projectDir}/." "${containerId}:/app"

    Write-Host "[3/4] Ejecutando análisis, tests y compilando APK Release..."
    docker exec -w /app -e GRADLE_OPTS="-Dorg.gradle.jvmargs='-Xmx4g -XX:+UseParallelGC' -Dorg.gradle.parallel=true -Dorg.gradle.workers.max=$containerCpus" $containerId bash -c "flutter pub get && flutter test && flutter build apk --release --build-name=$versionName --build-number=$versionCode"


    if ($LASTEXITCODE -ne 0) {
        throw "Error durante la compilacion de Flutter en el contenedor."
    }

    Write-Host "[4/4] Extrayendo APK generado a la raiz del proyecto..."
    docker cp "${containerId}:/app/build/app/outputs/flutter-apk/app-release.apk" "$destProjectPath"

    if (Test-Path "$destProjectPath") {
        $apk = Get-Item "$destProjectPath"
        Write-Host "========================================="
        Write-Host " ¡APK DE DINOXO GAMERS GENERADO CON ÉXITO!"
        Write-Host " Archivo: $($apk.FullName)"
        Write-Host " Tamaño: $([math]::Round($apk.Length / 1MB, 2)) MB"
        Write-Host " Versión: V$versionName (Código: $versionCode)"
        Write-Host "========================================="
    } else {
        throw "No se encontro el archivo APK en $destProjectPath"
    }
} finally {
    Write-Host "Limpiando contenedor..."
    docker rm -f $containerId | Out-Null
}
