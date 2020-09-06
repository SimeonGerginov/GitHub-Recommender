<#
    Specifies the type of activity a GitHub user can perform
    on a GitHub repository.
#>
enum GitHubActivityType {
    Fork
    Star
    Watch
}

<#
    Defines the relationship between a GitHub repository and
    a GitHub user - whether a user has forked, starred or watched
    a repository.
#>
class GitHubActivity {
    <#
        Specifies the ID of the GitHub repository.
    #>
    [int]$RepositoryId

    <#
        Specifies the ID of the GitHub user.
    #>
    [int]$UserId

    <#
        Specifies the type of Activity.
    #>
    [GitHubActivityType]$ActivityType
}
