# Simple HTTP Server for Wedding Card
# Usage: powershell -ExecutionPolicy Bypass -File serve.ps1

$port = 3000
$root = Split-Path -Parent $MyInvocation.MyCommand.Path

$listener = New-Object System.Net.HttpListener
$listener.Prefixes.Add("http://localhost:$port/")
$listener.Start()

Write-Host ""
Write-Host "  Wedding Card Server" -ForegroundColor Cyan
Write-Host "  -------------------" -ForegroundColor DarkGray
Write-Host "  http://localhost:$port" -ForegroundColor Green
Write-Host ""
Write-Host "  Press Ctrl+C to stop" -ForegroundColor DarkGray
Write-Host ""

$mimeTypes = @{
    ".html" = "text/html; charset=utf-8"
    ".css"  = "text/css; charset=utf-8"
    ".js"   = "application/javascript; charset=utf-8"
    ".jpg"  = "image/jpeg"
    ".jpeg" = "image/jpeg"
    ".png"  = "image/png"
    ".gif"  = "image/gif"
    ".svg"  = "image/svg+xml"
    ".ico"  = "image/x-icon"
    ".json" = "application/json; charset=utf-8"
    ".woff" = "font/woff"
    ".woff2"= "font/woff2"
}

try {
    while ($listener.IsListening) {
        $context = $listener.GetContext()
        $request = $context.Request
        $response = $context.Response

        $path = $request.Url.LocalPath
        if ($path -eq "/") { $path = "/index.html" }

        $filePath = Join-Path $root ($path -replace "/", "\")

        if (Test-Path $filePath -PathType Leaf) {
            $ext = [System.IO.Path]::GetExtension($filePath).ToLower()
            $contentType = if ($mimeTypes.ContainsKey($ext)) { $mimeTypes[$ext] } else { "application/octet-stream" }

            $response.ContentType = $contentType
            $response.StatusCode = 200

            $bytes = [System.IO.File]::ReadAllBytes($filePath)
            $response.ContentLength64 = $bytes.Length
            $response.OutputStream.Write($bytes, 0, $bytes.Length)

            Write-Host "  200  $path" -ForegroundColor DarkGray
        } else {
            $response.StatusCode = 404
            $msg = [System.Text.Encoding]::UTF8.GetBytes("Not Found")
            $response.ContentLength64 = $msg.Length
            $response.OutputStream.Write($msg, 0, $msg.Length)

            Write-Host "  404  $path" -ForegroundColor Yellow
        }

        $response.OutputStream.Close()
    }
} finally {
    $listener.Stop()
    Write-Host "`n  Server stopped." -ForegroundColor DarkGray
}
