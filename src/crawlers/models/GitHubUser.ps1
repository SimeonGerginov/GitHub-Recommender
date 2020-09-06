<#
    Defines the type of a GitHub user.
#>
enum GitHubUserType {
    User
    Organization
}

<#
    Defines the representation of a GitHub user that is being used
    by the GitHub Recommender of repositories.
#>
class GitHubUser {
    <#
        Specifies the ID of the GitHub user.
    #>
    [int]$Id

    <#
        Specifies the name of the GitHub user.
    #>
    [string]$Name

    <#
        Specifies the type of the GitHub user.
    #>
    [GitHubUserType]$Type
}
