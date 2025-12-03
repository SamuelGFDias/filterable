# Script para testar compatibilidade sem outras dependências
# Cria um projeto mínimo para testar apenas o filterable_generator

$ErrorActionPreference = "Continue"
$testDir = "D:\Dev\Flutter\filterable\test_compat_temp"
$testResults = @()

# Versões a testar
$versions = @(
    "2.4.0",
    "2.4.13",
    "2.7.0",
    "2.10.0"
)

Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host "  ISOLATED COMPATIBILITY TEST" -ForegroundColor Cyan
Write-Host "  Testing without other generators" -ForegroundColor Cyan
Write-Host "========================================`n" -ForegroundColor Cyan

# Criar diretório de teste temporário
if (Test-Path $testDir) {
    Remove-Item -Path $testDir -Recurse -Force
}
New-Item -Path $testDir -ItemType Directory | Out-Null

# Criar pubspec.yaml minimalista
$pubspecContent = @"
name: test_compat
description: Compatibility test
version: 1.0.0
environment:
  sdk: ">=3.0.0 <4.0.0"

dependencies:
  filterable_annotation:
    path: ../packages/filterable_annotation

dev_dependencies:
  filterable_generator:
    path: ../packages/filterable_generator
  build_runner: ^2.4.0
"@

Set-Content -Path "$testDir\pubspec.yaml" -Value $pubspecContent

# Criar estrutura básica
New-Item -Path "$testDir\lib" -ItemType Directory | Out-Null
New-Item -Path "$testDir\lib\models" -ItemType Directory | Out-Null

# Criar modelo de teste
$modelContent = @"
import 'package:filterable_annotation/filterable_annotation.dart';

part 'test_model.filterable.g.dart';

enum Status { active, inactive }

@Filterable()
class TestModel {
  @FilterableField(label: 'Name', comparatorsType: String)
  final String name;

  @FilterableField(label: 'Status', comparatorsType: Status)
  final Status status;

  TestModel({required this.name, required this.status});
}
"@

Set-Content -Path "$testDir\lib\models\test_model.dart" -Value $modelContent

foreach ($version in $versions) {
    Write-Host "`n--- Testing build_runner $version ---" -ForegroundColor Yellow
    
    # Atualizar versão no pubspec
    $pubspec = Get-Content "$testDir\pubspec.yaml"
    $pubspec = $pubspec -replace 'build_runner:.*', "build_runner: ^$version"
    Set-Content "$testDir\pubspec.yaml" $pubspec
    
    # Limpar cache
    Remove-Item -Path "$testDir\.dart_tool" -Recurse -Force -ErrorAction SilentlyContinue
    Remove-Item -Path "$testDir\pubspec.lock" -Force -ErrorAction SilentlyContinue
    
    # Tentar instalar dependências
    Write-Host "  Installing dependencies..." -ForegroundColor Gray
    Set-Location $testDir
    $pubGetResult = dart pub get 2>&1
    
    if ($LASTEXITCODE -ne 0) {
        Write-Host "  ❌ FAILED: Dependencies" -ForegroundColor Red
        $errorMsg = ($pubGetResult | Select-String -Pattern "Because|version" | Select-Object -First 3) -join "`n"
        Write-Host "  Error: $errorMsg" -ForegroundColor Red
        $testResults += [PSCustomObject]@{
            Version = $version
            Status = "FAILED"
            Phase = "pub get"
            Error = $errorMsg
        }
        continue
    }
    
    Write-Host "  ✓ Dependencies OK" -ForegroundColor Green
    
    # Verificar versões resolvidas
    $resolvedBuildRunner = dart pub deps | Select-String -Pattern "^│   ├── build_runner" | Out-String
    $resolvedAnalyzer = dart pub deps | Select-String -Pattern "^│   ├── analyzer" | Out-String
    Write-Host "  Resolved: $($resolvedBuildRunner.Trim())" -ForegroundColor Gray
    
    # Tentar gerar código
    Write-Host "  Running build_runner..." -ForegroundColor Gray
    $buildResult = dart run build_runner build --delete-conflicting-outputs 2>&1
    
    if ($LASTEXITCODE -ne 0) {
        Write-Host "  ❌ FAILED: Build" -ForegroundColor Red
        $errorMsg = ($buildResult | Select-String -Pattern "Error|error" | Select-Object -First 2) -join "`n"
        Write-Host "  Error: $errorMsg" -ForegroundColor Red
        $testResults += [PSCustomObject]@{
            Version = $version
            Status = "FAILED"
            Phase = "build"
            Error = $errorMsg
        }
        continue
    }
    
    # Verificar arquivo gerado
    if (Test-Path "$testDir\lib\models\test_model.filterable.g.dart") {
        $content = Get-Content "$testDir\lib\models\test_model.filterable.g.dart" -Raw
        if ($content -match "buildPredicate" -and $content -match "TestStatus") {
            Write-Host "  ✓ SUCCESS" -ForegroundColor Green
            $testResults += [PSCustomObject]@{
                Version = $version
                Status = "SUCCESS"
                Phase = "complete"
                Error = ""
            }
        } else {
            Write-Host "  ⚠️  WARNING: Incomplete" -ForegroundColor Yellow
            $testResults += [PSCustomObject]@{
                Version = $version
                Status = "WARNING"
                Phase = "validation"
                Error = "Generated code incomplete"
            }
        }
    } else {
        Write-Host "  ❌ FAILED: No output" -ForegroundColor Red
        $testResults += [PSCustomObject]@{
            Version = $version
            Status = "FAILED"
            Phase = "output"
            Error = "No generated file"
        }
    }
}

# Limpar
Set-Location "D:\Dev\Flutter\filterable"
Remove-Item -Path $testDir -Recurse -Force

# Relatório
Write-Host "`n`n========================================" -ForegroundColor Cyan
Write-Host "  ISOLATED TEST RESULTS" -ForegroundColor Cyan
Write-Host "========================================`n" -ForegroundColor Cyan

$testResults | Format-Table -AutoSize

$successCount = ($testResults | Where-Object { $$.Status -eq "SUCCESS" }).Count
Write-Host "`n✓ Success: $successCount / $($testResults.Count)" -ForegroundColor Green

if ($successCount -eq $testResults.Count) {
    Write-Host "`n🎉 ALL TESTS PASSED" -ForegroundColor Green
    exit 0
} else {
    Write-Host "`n⚠️  SOME TESTS FAILED" -ForegroundColor Yellow
    exit 1
}
