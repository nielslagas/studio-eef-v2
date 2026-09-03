# Eén screenshot naar DeepSeek V4 Flash Vision sturen met een vraag.
# Gebruik: .\ask-vision.ps1 -Image pad.png -Vraag "..."
param(
  [Parameter(Mandatory = $true)][string]$Image,
  [Parameter(Mandatory = $true)][string]$Vraag,
  [int]$MaxTokens = 6000
)
$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.Drawing
$dk = [regex]::Match((Get-Content "C:\Users\Gebruiker\.dsh\.credentials.yaml" -Raw), 'DEEPSEEK_API_KEY:\s*(\S+)').Groups[1].Value

$img = [System.Drawing.Image]::FromFile((Resolve-Path $Image).Path)
$w = $img.Width; $h = $img.Height
if ($w -gt 780) { $h = [int]($h * 780 / $w); $w = 780 }
$out = New-Object System.Drawing.Bitmap($w, $h)
$g = [System.Drawing.Graphics]::FromImage($out)
$g.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
$g.DrawImage($img, 0, 0, $w, $h)
$g.Dispose(); $img.Dispose()
$ms = New-Object System.IO.MemoryStream
$codec = [System.Drawing.Imaging.ImageCodecInfo]::GetImageEncoders() | Where-Object { $_.MimeType -eq 'image/jpeg' }
$ep = New-Object System.Drawing.Imaging.EncoderParameters(1)
$ep.Param[0] = New-Object System.Drawing.Imaging.EncoderParameter([System.Drawing.Imaging.Encoder]::Quality, [long]85)
$out.Save($ms, $codec, $ep); $out.Dispose()
$url = 'data:image/jpeg;base64,' + [Convert]::ToBase64String($ms.ToArray())

$content = @(
  @{ type = 'text'; text = $Vraag },
  @{ type = 'image_url'; image_url = @{ url = $url } }
)
$body = @{ model = 'deepseek-v4-flash-vision-exp'; messages = @(@{ role = 'user'; content = $content }); max_tokens = $MaxTokens; temperature = 0.2 } | ConvertTo-Json -Depth 8
$req = Join-Path $env:TEMP 'ask-vision-req.json'
[System.IO.File]::WriteAllText($req, $body)
$resp = Join-Path $env:TEMP 'ask-vision-resp.json'
& curl.exe -s --max-time 240 "https://api.deepseek.com/chat/completions" -H "Authorization: Bearer $dk" -H "Content-Type: application/json" -d "@$req" -o $resp
$j = (Get-Content $resp -Raw) | ConvertFrom-Json
if ($j.error) { Write-Output "API-FOUT: $($j.error.message)"; exit 1 }
$t = $j.choices[0].message.content
if (-not $t -and $j.choices[0].message.reasoning_content) { $t = $j.choices[0].message.reasoning_content }
Write-Output $t
