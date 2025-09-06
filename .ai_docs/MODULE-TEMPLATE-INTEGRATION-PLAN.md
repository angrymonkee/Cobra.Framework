# Module Template Integration - Implementation Steps

## Implementation Tasks

### 1. Add Get-ModuleTemplates Function to TemplatesManagement.ps1

**Description**: Create main function to discover templates in module directories
**Details**:

- Scan `Modules/*/templates/` directories for template files
- Support discovery of `.ps1`, `.txt`, `.md`, `.json` template files
- Return array of template objects with properties: Name, Type, Description, Path, Author, Module, Created
- Handle cases where modules don't have template directories
- Use error handling for directory access issues

### 2. Add Get-ModuleTemplatesByType Function to TemplatesManagement.ps1

**Description**: Create helper function to categorize templates by file type
**Details**:

- Accept ModuleName and TemplatePath parameters
- Parse metadata from file headers using standardized comment format:
  ```
  # Description: Template description here
  # Author: Author name
  # Category: Template category
  # Parameters: param1, param2, param3
  ```
- Generate default metadata when headers are missing or invalid
- Handle different file extensions (.ps1, .txt, .md, .json) appropriately
- Return properly formatted template objects for each discovered template

### 3. Enhance Get-CobraTemplates Function in TemplatesManagement.ps1

**Description**: Extend existing template discovery to include module templates
**Details**:

- Add `[switch]$IncludeModuleTemplates` parameter
- Call `Get-ModuleTemplates` when parameter is used or when Category equals "all"
- Merge module template results with existing template discovery results
- Maintain complete backward compatibility (existing behavior unchanged when parameter not used)
- Support filtering module templates using existing SearchTerm parameter
- Preserve all existing function parameters and behaviors

### 4. Add Copy-ModuleTemplate Function to TemplatesManagement.ps1

**Description**: Create function to copy and process module templates
**Details**:

- Accept parameters: ModuleName, TemplateName, DestinationPath, Parameters (hashtable)
- Search for template file in `Modules/$ModuleName/templates/` with extensions: .ps1, .txt, .json, .md
- Implement parameter substitution for standard placeholders:
  - `{ModuleName}` → Source module name
  - `{Date}` → Current date in yyyy-MM-dd format
  - `{Author}` → Current user from $env:USERNAME
  - Custom parameters from hashtable input (e.g., `{ProjectName}` from Parameters.ProjectName)
- Handle file not found errors with clear, actionable error messages
- Create output file with same extension as source template
- Log activity using existing Log-CobraActivity function
- Return success/failure status

### 5. Enhance Copy-CobraTemplate Function in TemplatesManagement.ps1

**Description**: Modify existing copy function to handle module templates
**Details**:

- Add logic to detect module-namespaced template names (contains exactly one dot)
- Parse module name and template name from input format "ModuleName.templatename"
- Route to Copy-ModuleTemplate function when module template is detected
- Maintain 100% existing functionality for regular template copying
- Preserve all existing parameters: TemplateName, DestinationPath, Parameters
- Add validation for module-namespaced names (module must exist, template must exist)
- Provide clear error messages for invalid module or template names

### 6. Add "cobra templates modules" Command

**Description**: Create new CLI command to list only module templates
**Details**:

- Add command processing in template CLI interface (locate in TemplatesManagement.ps1)
- List only templates from modules (exclude regular framework templates)
- Display: Module name, Template name, Description, File type
- Support optional filtering and search functionality using existing patterns
- Format output clearly showing module source for each template
- Show template count summary
- Handle case when no modules have templates

### 7. Update "cobra templates list" Command

**Description**: Enhance existing list command to optionally include module templates
**Details**:

- Add `-IncludeModuleTemplates` parameter to existing list command processing
- When parameter used, call enhanced Get-CobraTemplates with IncludeModuleTemplates flag
- Merge and display both regular and module templates in unified list
- Maintain existing output formatting but add module source indicator
- Preserve all existing list command functionality and parameters
- Show clear visual distinction between regular templates and module templates
- Maintain existing sorting and filtering capabilities

### 8. Update Copy Template Command Processing

**Description**: Modify template copy command parser to handle module syntax
**Details**:

- Locate existing copy command processing in TemplatesManagement.ps1
- Add detection for module-namespaced template names (format: "Module.templatename")
- Validate module name exists in framework before attempting copy
- Pass module and template names to enhanced Copy-CobraTemplate function
- Maintain backward compatibility with existing copy command syntax
- Provide helpful error messages for malformed module template names
- Support parameter passing for module templates using existing mechanisms

### 9. Enhance Show-CobraTemplateHelp Function

**Description**: Update help system to document module template commands
**Details**:

- Locate Show-CobraTemplateHelp function in TemplatesManagement.ps1
- Add new section: "MODULE TEMPLATE COMMANDS"
- Document `cobra templates modules` command with examples
- Document `cobra templates list -IncludeModuleTemplates` usage
- Show examples of copying module templates: `cobra templates copy Email.meeting-followup`
- Explain module.template naming convention and requirements
- Add parameter substitution examples for module templates
- Include troubleshooting section for common module template issues

### 10. Add Register-ModuleTemplates Function to Core.ps1

**Description**: Create function to register template capabilities during module loading
**Details**:

- Add function in Core.ps1 near other registration functions
- Accept ModuleName and Config parameters
- Check if module config has `Integrations.Templates.Enabled = $true`
- Validate that configured template directory exists and is accessible
- Log template registration activity using Log-CobraActivity
- Store template capability information in global module registry
- Handle modules that don't have template integration configured
- Return registration success/failure status

### 11. Update Register-CobraStandaloneModule Function in Core.ps1

**Description**: Integrate template registration into standalone module registration
**Details**:

- Locate Register-CobraStandaloneModule function in Core.ps1
- Add call to Register-ModuleTemplates after existing registration logic
- Pass module Name and Config parameters to template registration
- Maintain all existing registration functionality without changes
- Ensure registration process works correctly for modules with and without templates
- Add error handling so template registration failures don't break module registration
- Log template registration results in module registration activity

### 12. Update Register-CobraRepository Function in Core.ps1

**Description**: Integrate template registration into repository module registration
**Details**:

- Locate Register-CobraRepository function in Core.ps1
- Add call to Register-ModuleTemplates after existing registration logic
- Pass module Name and Config parameters to template registration
- Maintain all existing registration functionality without changes
- Ensure registration process works correctly for modules with and without templates
- Add error handling so template registration failures don't break module registration
- Log template registration results in module registration activity

### 13. Create Template Standards Documentation

**Description**: Document template file naming conventions and standards
**Details**:

- Create new file: `TEMPLATE-STANDARDS.md` in repository root
- Define template file naming conventions (lowercase, hyphens, descriptive)
- Document standardized metadata header format with required and optional fields
- Establish template quality guidelines (clear descriptions, proper parameters, examples)
- Create examples for different template types (.ps1, .txt, .md, .json)
- Document parameter substitution capabilities and syntax
- Include template directory structure requirements for modules
- Add guidelines for template versioning and maintenance

### 14. Update Email Module Templates

**Description**: Enhance existing Email module templates for compliance and examples
**Details**:

- Review existing templates in `Modules/Email/templates/` directory
- Add standardized metadata headers to all existing template files
- Ensure templates follow naming conventions from standards document
- Create 2-3 additional example templates to demonstrate different types
- Test all Email module templates with new discovery and copy functions
- Document Email module template usage in module README
- Add template parameter examples and usage instructions

### 15. Add Templates to AzureDevOps Module

**Description**: Create template directory and templates for AzureDevOps module
**Details**:

- Create `templates/` directory in `Modules/AzureDevOps/`
- Add templates:
  - `pull-request-template.md` - PR description template
  - `work-item-function.ps1` - PowerShell function for work item operations
  - `pipeline-config.json` - Basic pipeline configuration
- Include proper metadata headers in all templates
- Test template discovery and copying functionality with AzureDevOps templates
- Document AzureDevOps module template capabilities in module README
- Add template usage examples in module documentation

### 16. Add Templates to GRTS Module

**Description**: Create template directory and templates for GRTS module
**Details**:

- Create `templates/` directory in `Modules/GRTS/`
- Add templates:
  - `build-script.ps1` - Build automation script template
  - `deployment-config.json` - Deployment configuration template
  - `test-script.ps1` - Test execution script template
- Include proper metadata headers in all templates
- Test template discovery and copying functionality with GRTS templates
- Document GRTS module template capabilities in module README
- Add template usage examples relevant to GRTS workflows

### 17. Create Module Template Developer Guide

**Description**: Create comprehensive guide for module developers
**Details**:

- Create new file: `MODULE-TEMPLATE-GUIDE.md` in repository root
- Document step-by-step process for adding templates to existing modules
- Explain template directory structure requirements (`Modules/ModuleName/templates/`)
- Show metadata header format with examples for each file type
- Provide parameter substitution guide with examples and best practices
- Include troubleshooting section for common template development issues
- Add section on testing templates before publishing
- Include integration examples showing config.ps1 template configuration

### 18. Add Template Integration Config to Module config.ps1 Files

**Description**: Standardize template configuration in module config files
**Details**:

- Define standard configuration format for template integration in modules
- Add `Integrations.Templates` section to config.ps1 files for modules with templates:
  ```powershell
  Integrations = @{
      Templates = @{
          Enabled = $true
          TemplateDirectory = "templates"
      }
  }
  ```
- Update Email module config.ps1 with template configuration
- Update AzureDevOps module config.ps1 with template configuration
- Update GRTS module config.ps1 with template configuration
- Document configuration options and requirements
- Test configuration parsing during module registration

### 19. Add Tab Completion for Module Templates

**Description**: Enhance command-line tab completion for module template names
**Details**:

- Locate tab completion logic in CobraProfile.ps1 or related files
- Add completion for module template names in format "Module.templatename"
- Support completion for module names when typing template commands
- Add parameter name completion for templates that define parameter metadata
- Test tab completion functionality with multiple modules and templates
- Ensure completion works for both `cobra templates copy` and related commands
- Handle completion performance with large numbers of templates

### 20. Create Comprehensive Test Suite

**Description**: Develop testing framework for all module template functionality
**Details**:

- Create test file: `test-module-templates.ps1` in repository root
- Write tests for all new template discovery functions (Get-ModuleTemplates, Get-ModuleTemplatesByType)
- Test template copying functionality with various parameter combinations
- Test error handling scenarios (missing templates, invalid modules, permission issues)
- Test CLI command integration (list, modules, copy commands)
- Create performance tests for template discovery with multiple modules
- Test backward compatibility - ensure existing template functionality unchanged
- Validate tab completion functionality
- Test module registration with template integration
- Create integration tests using Email, AzureDevOps, and GRTS modules
- Document test execution procedures and expected results

## Success Criteria

**Core Functionality Must Work**:

- [ ] `cobra templates list -IncludeModuleTemplates` shows all module templates
- [ ] `cobra templates modules` lists only module templates with clear formatting
- [ ] `cobra templates copy Email.meeting-followup` copies template with parameter substitution
- [ ] Parameter substitution works for {ModuleName}, {Date}, {Author}, and custom parameters
- [ ] Template metadata parsing works from standardized file headers
- [ ] Module templates use namespaced naming: Module.templatename format

**Integration Must Be Seamless**:

- [ ] Module registration automatically detects and registers template capabilities
- [ ] Template functionality integrates with existing activity logging
- [ ] All CLI commands work intuitively without breaking existing workflows
- [ ] Tab completion works for module template names and parameters
- [ ] Existing template functionality remains completely unchanged
- [ ] Error messages are clear and actionable for all failure scenarios

**Documentation and Examples Must Be Complete**:

- [ ] At least 3 modules (Email, AzureDevOps, GRTS) have working template examples
- [ ] Developer guide enables new module developers to add templates easily
- [ ] Template standards are well-defined and easy to follow
- [ ] All functions have comprehensive error handling and user feedback
- [ ] Test suite validates all functionality and catches regressions

**Total Implementation**: 20 detailed steps covering all aspects of module template integration
