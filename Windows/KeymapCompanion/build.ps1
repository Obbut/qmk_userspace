[CmdletBinding()]
param(
    [ValidateSet('debug', 'release')]
    [string] $Configuration = 'debug'
)

$ErrorActionPreference = 'Stop'

& (Join-Path $PSScriptRoot 'bootstrap.ps1')

$vswhere = Join-Path ${env:ProgramFiles(x86)} 'Microsoft Visual Studio\Installer\vswhere.exe'
if (Test-Path $vswhere) {
    $visualStudioRoot = & $vswhere `
        -latest `
        -products * `
        -requires Microsoft.VisualStudio.Component.VC.Tools.x86.x64 `
        -property installationPath
    if ($LASTEXITCODE -ne 0) {
        throw "Visual Studio discovery failed with exit code $LASTEXITCODE."
    }
    if ([string]::IsNullOrWhiteSpace($visualStudioRoot)) {
        $vcvars = $null
    } else {
        $vcvars = Join-Path $visualStudioRoot 'VC\Auxiliary\Build\vcvars64.bat'
    }
} else {
    $vcvars = 'C:\Program Files (x86)\Microsoft Visual Studio\2019\BuildTools\VC\Auxiliary\Build\vcvars64.bat'
}
if ([string]::IsNullOrWhiteSpace($vcvars) -or -not (Test-Path $vcvars)) {
    throw 'Visual C++ x64 build tools were not found. Install the Visual Studio C++ desktop workload.'
}

$environment = & $env:ComSpec /d /c ('call "{0}" >nul && set' -f $vcvars)
foreach ($line in $environment) {
    if ($line -match '^([^=]+)=(.*)$') {
        Set-Item -Path "env:$($matches[1])" -Value $matches[2]
    }
}

$swiftRoot = Join-Path $env:LOCALAPPDATA 'Programs\Swift'
$env:Path = @(
    (Join-Path $swiftRoot 'Runtimes\6.3.3\usr\bin'),
    (Join-Path $swiftRoot 'Toolchains\6.3.3+Asserts\usr\bin'),
    $env:Path
) -join ';'

$version = swift --version | Select-Object -First 1
if ($version -notmatch 'Swift version 6\.3\.3') {
    throw "Swift 6.3.3 is required; active toolchain is: $version"
}

swift build --package-path $PSScriptRoot --configuration $Configuration
if ($LASTEXITCODE -ne 0) {
    throw "Swift build failed with exit code $LASTEXITCODE."
}

# Stage the exact Swift runtime beside the executable. Windows searches the
# application directory first, so launching from Explorer or a tray helper can
# never bind this Swift 6.3.3 binary to an older runtime inherited through PATH.
$output = Join-Path $PSScriptRoot ".build\x86_64-unknown-windows-msvc\$Configuration"
Get-ChildItem (Join-Path $swiftRoot 'Runtimes\6.3.3\usr\bin') -Filter '*.dll' |
    Copy-Item -Destination $output -Force

Write-Host "Keymap Companion is ready at $(Join-Path $output 'KeymapCompanion.exe')"
