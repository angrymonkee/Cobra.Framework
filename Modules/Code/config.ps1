@{
    Name               = "Code"
    Description        = "General code development module"
    Repo               = ""
    AuthMethod         = "Authenticate-CodeRepo"
    SetupMethod        = "Configure-CodeRepo"
    BuildMethod        = "Build-CodeRepo"
    TestMethod         = "Test-CodeRepo"
    RunMethod          = "Execute-CodeRepo"
    DevMethod          = "Develop-CodeRepo"
    ReviewPullRequests = "Read-CodePullRequests"
    OpenPullRequest    = "Open-CodePullRequestById"
    GoLocations        = @{}
}