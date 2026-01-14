# Generate keymap SVG images using Docker
# Requires Docker Desktop to be running

$ErrorActionPreference = "Stop"
Set-Location $PSScriptRoot

$OutputDir = "images"
$ImageName = "qmk-keymap-drawer"

# Create output directory if needed
New-Item -ItemType Directory -Force -Path $OutputDir | Out-Null

# Build Docker image if needed
$imageExists = docker image inspect $ImageName 2>$null
if (-not $imageExists) {
    Write-Host "Building Docker image (this may take a few minutes on first run)..."
    docker build -t $ImageName .
}

# Layer names (must match keymap.yaml)
$Layers = @("Default", "Lower", "Raise", "Function")

# Draw each layer separately
foreach ($layer in $Layers) {
    $lowercase = $layer.ToLower()
    Write-Host "Drawing $layer layer..."
    docker run --rm `
        -v "${PWD}:/workdir" `
        -w /workdir `
        $ImageName `
        keymap -c keymap-drawer.yaml draw keymap.yaml -s $layer -o "$OutputDir/keymap-$lowercase.svg"
}

Write-Host "Generated layer images in $OutputDir/"
