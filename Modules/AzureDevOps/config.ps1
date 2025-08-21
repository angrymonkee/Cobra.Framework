# AzureDevOps Standalone Module Configuration
# This module does not depend on a repository

@{
    # Basic module information
    Name         = "AzureDevOps"
    Description  = "Comprehensive Azure DevOps integration for enhanced developer productivity with PR management, sprint tasks, user stories, and CLI automation"
    Version      = "1.0.0"
    Author       = "Cobra Framework Team"
    ModuleType   = "Standalone"
    
    # Creation metadata
    Created      = "2025-08-19"
    LastModified = "2025-08-19"
    
    # Module capabilities
    Capabilities = @(
        "Configuration",
        "Status", 
        "Help",
        "WorkItems",
        "Builds",
        "PullRequests",
        "Sprints",
        "Pipelines",
        "Repositories",
        "HierarchicalInterface"
    )
    
    # Dependencies (other Cobra modules this module requires)
    Dependencies = @()
    
    # Module-specific configuration
    Settings     = @{
        # Global Azure DevOps settings
        DefaultTimeout         = 30
        EnableLogging          = $true
        EnableTeamsIntegration = $true
        
        # Work item templates configuration
        Templates              = @{
            Bug        = @{
                Title    = "[BUG] {Summary}"
                Priority = 2
                Severity = "Medium"
                Tags     = @("bug", "triage")
            }
            Task       = @{
                Title    = "[TASK] {Summary}"
                Priority = 2
                Tags     = @("task")
            }
            UserStory  = @{
                Title    = "[STORY] {Summary}"
                Priority = 2
                Tags     = @("user-story", "feature")
            }
            CodeReview = @{
                Title    = "[CODE REVIEW] {Summary}"
                Priority = 1
                Tags     = @("code-review", "quality")
            }
        }
        
        # Teams integration
        Teams                  = @{
            Enabled          = $true
            WebhookUrl       = $null
            NotifyOnBuild    = $true
            NotifyOnPR       = $true
            NotifyOnWorkItem = $false
        }
        
        # CLI automation settings
        AutoSetDefaults        = $true
        CacheResults           = $true
        CacheTimeout           = 300  # 5 minutes
    }
    
    # Command aliases
    Aliases      = @{
        "azdevops" = "AzureDevOpsDriver"
    }
    
    # Integration points
    Integrations = @{
        # Dashboard integration
        Dashboard = @{
            Enabled      = $true
            ShowInStatus = $true
            Priority     = "High"
        }
        
        # AI integration  
        AI        = @{
            Enabled        = $true
            SupportedTypes = @("WorkItemGeneration", "PullRequestAnalysis", "SprintPlanning")
        }
        
        # Template integration
        Templates = @{
            Enabled           = $true
            TemplateDirectory = "templates"
        }
    }
}

