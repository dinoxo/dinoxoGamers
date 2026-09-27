param([string]$Source = (Join-Path $PSScriptRoot '..\artwork\dinoxo_store_badge_master.png'))
$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.Drawing
$brandProject = [System.IO.Path]::GetFullPath((Join-Path $PSScriptRoot '..'))
$brandSource = [System.Drawing.Bitmap]::new([System.IO.Path]::GetFullPath($Source))

# Only exports density/size variants of the approved transparent artwork.
function Export-BrandBitmap([string]$RelativePath, [int]$Canvas, [int]$LogoSize) {
    $output = Join-Path $brandProject $RelativePath
    [System.IO.Directory]::CreateDirectory([System.IO.Path]::GetDirectoryName($output)) | Out-Null
    $bitmap = [System.Drawing.Bitmap]::new($Canvas, $Canvas, [System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
    $graphics = [System.Drawing.Graphics]::FromImage($bitmap)
    $attributes = [System.Drawing.Imaging.ImageAttributes]::new()
    try {
        $graphics.Clear([System.Drawing.Color]::Transparent)
        $graphics.CompositingMode = [System.Drawing.Drawing2D.CompositingMode]::SourceCopy
        $graphics.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
        $graphics.PixelOffsetMode = [System.Drawing.Drawing2D.PixelOffsetMode]::HighQuality
        $attributes.SetWrapMode([System.Drawing.Drawing2D.WrapMode]::TileFlipXY)
        $offset = [int](($Canvas - $LogoSize) / 2)
        $rect = [System.Drawing.Rectangle]::new($offset, $offset, $LogoSize, $LogoSize)
        $graphics.DrawImage($brandSource, $rect, 0, 0, $brandSource.Width, $brandSource.Height, [System.Drawing.GraphicsUnit]::Pixel, $attributes)
        $bitmap.Save($output, [System.Drawing.Imaging.ImageFormat]::Png)
        Write-Output $RelativePath
    } finally { $attributes.Dispose(); $graphics.Dispose(); $bitmap.Dispose() }
}

try {
    Export-BrandBitmap 'assets\images\dinoxo_store_badge.png' 512 512
    foreach ($density in @(@('mdpi', 1), @('hdpi', 1.5), @('xhdpi', 2), @('xxhdpi', 3), @('xxxhdpi', 4))) {
        $name = $density[0]
        $scale = [double]$density[1]
        Export-BrandBitmap "android\app\src\main\res\mipmap-$name\ic_launcher.png" ([int](48 * $scale)) ([int](48 * $scale))
        # The complete circular design remains inside the adaptive safe area.
        Export-BrandBitmap "android\app\src\main\res\mipmap-$name\ic_launcher_foreground.png" ([int](108 * $scale)) ([int](70 * $scale))
        Export-BrandBitmap "android\app\src\main\res\drawable-$name\brand_splash.png" ([int](288 * $scale)) ([int](192 * $scale))
    }
} finally { $brandSource.Dispose() }
