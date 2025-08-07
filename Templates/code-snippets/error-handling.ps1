# Description: Standard error handling with logging
# Author: Cobra Framework
# Created: 2025-08-07 16:39:53
# Type: Code Snippet

try {
    # Your code here
}
catch {
    Write-Host "Error in {FunctionName}: $($_.Exception.Message)" -ForegroundColor Red
    Log-CobraActivity "Error in {FunctionName}: $($_.Exception.Message)"
    throw
}
