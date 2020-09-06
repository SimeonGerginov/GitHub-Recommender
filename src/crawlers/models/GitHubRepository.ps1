<#
    Defines the representation of a GitHub repository that is being used
    by the GitHub Recommender of repositories.
#>
class GitHubRepository {
    <#
        Specifies the ID of the GitHub repository.
    #>
    [int]$Id

    <#
        Specifies the name of the GitHub repository.
    #>
    [string]$Name

    <#
        Specifies the description of the GitHub repository.
    #>
    [string]$Description

    <#
        Specifies the languages that are used in the GitHub repository.
    #>
    [string[]]$Languages

    <#
        Specifies the ID of the owner of the GitHub repository.
    #>
    [string]$OwnerId

    <#
        Specifies when was the GitHub repository created.
    #>
    [string]$CreatedAt

    <#
        Specifies when was the GitHub repository last updated.
    #>
    [string]$UpdatedAt
}
