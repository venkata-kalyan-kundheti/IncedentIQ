Write-Host "Starting IncidentIQ Backend Server on http://localhost:8080 ..." -ForegroundColor Cyan

# Load .env if present
$envFile = if (Test-Path "$PSScriptRoot\.env") { "$PSScriptRoot\.env" } elseif (Test-Path "$PSScriptRoot\agentops\.env") { "$PSScriptRoot\agentops\.env" } else { $null }
if ($envFile) {
    Write-Host "Loading environment from $envFile..." -ForegroundColor Green
    Get-Content $envFile | ForEach-Object {
        $line = $_.Trim()
        if ($line -and -not $line.StartsWith("#") -and $line -match "^([^=]+)=(.*)$") {
            $key = $matches[1].Trim()
            $val = $matches[2].Trim()
            [Environment]::SetEnvironmentVariable($key, $val, "Process")
        }
    }
}

Push-Location -Path "$PSScriptRoot\agentops"
try {
    if (-not $env:DB_URL) { $env:DB_URL = "jdbc:mysql://localhost:3306/agentops_db" }
    if (-not $env:DB_USERNAME) { $env:DB_USERNAME = "root" }
    if ($env:DB_PASSWORD -eq "your_database_password_here") { $env:DB_PASSWORD = "" }
    if (-not $env:JWT_SECRET) { $env:JWT_SECRET = "404E635266556A586E3272357538782F413F4428472B4B6250645367566B5970" }
    if (-not $env:JWT_EXPIRATION_MS) { $env:JWT_EXPIRATION_MS = "86400000" }

    $mvnCmd = if (Get-Command mvn -ErrorAction SilentlyContinue) { "mvn" } else { ".\mvnw.cmd" }
    $repoArg = if (Test-Path "D:\m2_repo") { "-Dmaven.repo.local=D:\m2_repo" } else { "" }

    if (-not (Test-Path "target\agentops-0.0.1-SNAPSHOT.jar")) {
        Write-Host "Backend JAR not found; packaging application..." -ForegroundColor Yellow
        if ($repoArg) {
            & $mvnCmd package -DskipTests $repoArg
        } else {
            & $mvnCmd package -DskipTests
        }
        if ($LASTEXITCODE -ne 0) {
            Write-Error "Maven package failed."
            exit $LASTEXITCODE
        }
    }

    java "-Dspring.classformat.ignore=true" -jar target\agentops-0.0.1-SNAPSHOT.jar
} finally {
    Pop-Location
}
