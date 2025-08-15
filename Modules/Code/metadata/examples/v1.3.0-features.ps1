# Version 1.3.0 specific example

# This example is specific to version 1.3.0 of the Code module

Write-Host "Code Module v1.3.0 - New Features Demo" -ForegroundColor Cyan

# New feature in 1.3.0: Advanced authentication
cobra code auth --provider github --enterprise

# Enhanced setup with templates
cobra code setup --template "microservice"

# Improved build with parallel execution
cobra code build --parallel --jobs 4

Write-Host "Version 1.3.0 features demonstrated!" -ForegroundColor Green
