[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'
$dependencies = @(
    @{ Name = 'swift-cwinrt'; Revision = 'eb46cdb66f770a1e006f9fcfebbf9e99a0fba811' },
    @{ Name = 'swift-uwp'; Revision = 'd1a96986570189f8aa9ed089e9c4dab3c96e688c' },
    @{ Name = 'swift-windowsfoundation'; Revision = '1efad430c4920d80d063bfaa526dd011d8ee8379' },
    @{ Name = 'swift-windowsappsdk'; Revision = '317527def617c5b7b3153380a85390bf7d3ec5b2' },
    @{ Name = 'swift-winui'; Revision = '17c77ebaf8585039ab2f25d8aaf19f6e0aead93b' }
)

$root = Join-Path $PSScriptRoot 'Dependencies'
New-Item -ItemType Directory -Force -Path $root | Out-Null

foreach ($dependency in $dependencies) {
    $path = Join-Path $root $dependency.Name
    if (-not (Test-Path (Join-Path $path '.git'))) {
        git clone "https://github.com/thebrowsercompany/$($dependency.Name).git" $path
    }
    git -C $path fetch --quiet origin $dependency.Revision
    git -C $path checkout --quiet --detach $dependency.Revision
}

# The archived swift-winui snapshot accidentally carries an ARM64 bootstrap DLL
# while its generated projections support x64. Replace it with the matching x64
# binary from Microsoft's exact Windows App SDK NuGet release.
$windowsAppSDKVersion = '1.7.250909003'
$package = Join-Path $root "Microsoft.WindowsAppSDK.$windowsAppSDKVersion.nupkg"
if (-not (Test-Path $package)) {
    Invoke-WebRequest -UseBasicParsing `
        -Uri "https://www.nuget.org/api/v2/package/Microsoft.WindowsAppSDK/$windowsAppSDKVersion" `
        -OutFile $package
}
$extractedRoot = Join-Path $root "Microsoft.WindowsAppSDK.$windowsAppSDKVersion"
$relativeBootstrap = 'runtimes/win-x64/native/Microsoft.WindowsAppRuntime.Bootstrap.dll'
$x64Bootstrap = Join-Path $extractedRoot $relativeBootstrap
if (-not (Test-Path $x64Bootstrap)) {
    New-Item -ItemType Directory -Force -Path $extractedRoot | Out-Null
    tar -xf $package -C $extractedRoot $relativeBootstrap
    if ($LASTEXITCODE -ne 0) {
        throw 'Could not extract the Windows App SDK x64 bootstrap DLL.'
    }
}
$projectionBootstrap = Join-Path $root `
    'swift-windowsappsdk\Sources\CWinAppSDK\nuget\bin\Microsoft.WindowsAppRuntime.Bootstrap.dll'
Copy-Item -LiteralPath $x64Bootstrap -Destination $projectionBootstrap -Force

Write-Host 'Swift/WinRT dependencies are ready.'
