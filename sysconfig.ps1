# Global settings for the Cobra Framework
# Copy this file and customize the paths for your environment

$global:CobraConfig = @{
    # Email address for notifications and tracking (customize this)
    OwnerEmail               = 'your.email@company.com'
    
    # Root directory where Cobra Framework is installed (customize this)
    CobraRoot                = 'C:\Code\Cobra.Framework'
    
    # Root directory where all your code repositories are stored (customize this)
    CodeRepo                 = 'C:\Code'
    
    # Shared location for team module registry - optional (customize this or remove if not using)
    ModuleRegistryLocation   = '\\shared\drive\CobraModuleRegistry'
    
    # Shared location for team template registry - optional (customize this or remove if not using)
    TemplateRegistryLocation = '\\shared\drive\CobraTemplateRegistry'
}

# Note: Only CobraRoot and CodeRepo are required for basic functionality
# Registry locations are optional and only needed for team sharing features