# Global settings for the application
$global:CobraConfig = @{
    OwnerEmail             = "<your email address>"
    CodeRoot               = $env:CODE_REPO
    CobraRoot              = $env:COBRA_ROOT

    # This can be any location. Ideally should be a shared location so 
    # multiple users can benefit by sharing modules. Import will automatically 
    # look here if no artifact location is specified.
    ModuleRegistryLocation = "$env:COBRA_ROOT\CobraModuleRegistry"
}