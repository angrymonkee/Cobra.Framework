# Global settings for the application
$global:CobraConfig = @{
    OwnerEmail             = "<your email address>" # test@test.com
    CodeRepo               = # C:\Code
    CobraRoot              = # C:\Code\Cobra.Framework

    # This can be any location. Ideally should be a shared location so 
    # multiple users can benefit by sharing modules. Import will automatically 
    # look here if no artifact location is specified.
    ModuleRegistryLocation = "C:\Code\CobraModuleRegistry"
}
