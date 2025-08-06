# Changelog

## [Unreleased]

### Added

- Mock data to sysconfig for development setup (commit a2220c0)
- Logic for running jobs, loading custom job scripts, health checks for repos and modules (commit 9c39c1d)
- Logging functionality to the framework (commit 947cebf)
- Install and uninstall functionality (commit 27ff7dd)

### Changed

- Enhanced code repo path handling to support switching between drives (commit 823ac68)
- Updated sysconfig to accommodate common repo locations and absolute paths (commit a8d84d7)
- Updated validation logic and jobs (commit c25b5af)

### Removed

- Deleted Test.zip from CobraModuleRegistry directory

### Fixed

- Fixed bug in import that did not properly initialize the module after it was loaded (commit f458ef4)

### Configuration

- Added sysconfig to git ignore (commit 4e221f3)
