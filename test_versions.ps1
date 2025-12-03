# Script para testar compatibilidade com diferentes versões do build_runner
# Executa: .\test_versions.ps1

$ErrorActionPreference = "Continue"
$testResults = @()

# Versões a testar
$versions = @(
    "2.4.0",  # Versão mínima
    "2.4.6",  # Versão intermediária
    "2.4.13", # Versão atual no exemplo
    "2.5.0",  # Se existir
    "2.6.0",  # Se existir
    "2.7.0",  # Se existir
    "2.8.0",  # Se existir
    "2.9.0",  # Se existir
    "2.10.0"  # Versão mais recente do 2.x
)

Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host "  FILTERABLE COMPATIBILITY TEST" -ForegroundColor Cyan
Write-Host "  Testing build_runner versions" -ForegroundColor Cyan
Write-Host "========================================`n" -ForegroundColor Cyan

# Backup do pubspec original
Copy-Item "D:\Dev\Flutter\filterable\example\pubspec.yaml" "D:\Dev\Flutter\filterable\example\pubspec.yaml.backup"

foreach ($version in $versions) {
    Write-Host "`n--- Testing build_runner $version ---" -ForegroundColor Yellow
    
    # Atualizar pubspec.yaml
    $pubspec = Get-Content "D:\Dev\Flutter\filterable\example\pubspec.yaml.backup"
    $pubspec = $pubspec -replace 'build_runner:.*', "build_runner: ^$version"
    Set-Content "D:\Dev\Flutter\filterable\example\pubspec.yaml" $pubspec
    
    # Limpar cache
    Write-Host "Cleaning cache..." -ForegroundColor Gray
    Remove-Item -Path "D:\Dev\Flutter\filterable\example\.dart_tool" -Recurse -Force -ErrorAction SilentlyContinue
    Remove-Item -Path "D:\Dev\Flutter\filterable\example\pubspec.lock" -Force -ErrorAction SilentlyContinue
    
    # Tentar instalar dependências
    Write-Host "Installing dependencies..." -ForegroundColor Gray
    Set-Location "D:\Dev\Flutter\filterable\example"
    $pubGetOutput = flutter pub get 2>&1
    
    if ($LASTEXITCODE -ne 0) {
        Write-Host "  ❌ FAILED: Could not resolve dependencies" -ForegroundColor Red
        $testResults += [PSCustomObject]@{
            Version = $version
            Status = "FAILED"
            Phase = "pub get"
            Message = "Dependency resolution failed"
        }
        continue
    }
    
    Write-Host "  ✓ Dependencies resolved" -ForegroundColor Green
    
    # Tentar gerar código
    Write-Host "Running build_runner..." -ForegroundColor Gray
    $buildOutput = dart run build_runner build --delete-conflicting-outputs 2>&1 | Out-String
    
    if ($LASTEXITCODE -ne 0) {
        Write-Host "  ❌ FAILED: Code generation failed" -ForegroundColor Red
        Write-Host "  Error: $($buildOutput | Select-String -Pattern 'Error|error' | Select-Object -First 3)" -ForegroundColor Red
        $testResults += [PSCustomObject]@{
            Version = $version
            Status = "FAILED"
            Phase = "build_runner"
            Message = "Code generation failed"
        }
        continue
    }
    
    Write-Host "  ✓ Code generated successfully" -ForegroundColor Green
    
    # Verificar se o arquivo foi gerado
    $generatedFile = "D:\Dev\Flutter\filterable\example\lib\models\product.filterable.g.dart"
    if (Test-Path $generatedFile) {
        Write-Host "  ✓ Generated file exists" -ForegroundColor Green
        
        # Verificar se o arquivo tem conteúdo válido
        $content = Get-Content $generatedFile -Raw
        if ($content -match "buildPredicate" -and $content -match "buildSorter") {
            Write-Host "  ✓ Generated code is valid" -ForegroundColor Green
            $testResults += [PSCustomObject]@{
                Version = $version
                Status = "SUCCESS"
                Phase = "complete"
                Message = "All checks passed"
            }
        } else {
            Write-Host "  ⚠️  WARNING: Generated code may be incomplete" -ForegroundColor Yellow
            $testResults += [PSCustomObject]@{
                Version = $version
                Status = "WARNING"
                Phase = "validation"
                Message = "Generated code incomplete"
            }
        }
    } else {
        Write-Host "  ❌ FAILED: Generated file not found" -ForegroundColor Red
        $testResults += [PSCustomObject]@{
            Version = $version
            Status = "FAILED"
            Phase = "file check"
            Message = "Generated file missing"
        }
    }
}

# Restaurar pubspec original
Copy-Item "D:\Dev\Flutter\filterable\example\pubspec.yaml.backup" "D:\Dev\Flutter\filterable\example\pubspec.yaml" -Force
Remove-Item "D:\Dev\Flutter\filterable\example\pubspec.yaml.backup" -Force

# Relatório final
Write-Host "`n`n========================================" -ForegroundColor Cyan
Write-Host "  TEST RESULTS SUMMARY" -ForegroundColor Cyan
Write-Host "========================================`n" -ForegroundColor Cyan

$testResults | Format-Table -AutoSize

$successCount = ($testResults | Where-Object { $_.Status -eq "SUCCESS" }).Count
$failCount = ($testResults | Where-Object { $_.Status -eq "FAILED" }).Count
$warnCount = ($testResults | Where-Object { $_.Status -eq "WARNING" }).Count
$totalCount = $testResults.Count

Write-Host "`nResults:" -ForegroundColor Cyan
Write-Host "  ✓ Success: $successCount / $totalCount" -ForegroundColor Green
Write-Host "  ⚠️  Warnings: $warnCount / $totalCount" -ForegroundColor Yellow
Write-Host "  ❌ Failed: $failCount / $totalCount" -ForegroundColor Red

if ($successCount -eq $totalCount) {
    Write-Host "`n🎉 ALL TESTS PASSED! 🎉" -ForegroundColor Green
    exit 0
} elseif ($successCount -gt 0) {
    Write-Host "`n⚠️  PARTIAL COMPATIBILITY" -ForegroundColor Yellow
    exit 1
} else {
    Write-Host "`n❌ ALL TESTS FAILED" -ForegroundColor Red
    exit 2
}
