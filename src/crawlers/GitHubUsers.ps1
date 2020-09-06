. (Join-Path -Path 'models' -ChildPath 'GitHubUser.ps1')

function New-GitHubUser {
    <#
    .SYNOPSIS
        Creates a new GitHubUser from the provided GitHub user data.

    .DESCRIPTION
        Creates a new GitHubUser from the provided GitHub user data.

    .PARAMETER GitHubUserData
        The GitHub user data that is retrieved via the GitHub API.

    .OUTPUTS
        [GitHubUser] - The constructed GitHubUser object.
    #>
    [CmdletBinding()]
    [OutputType([GitHubUser])]
    Param(
        [Parameter(Mandatory = $true)]
        [ValidateNotNull()]
        [PSCustomObject]
        $GitHubUserData
    )

    $githubUser = [GitHubUser]::new()

    $githubUser.Id = $GitHubUserData.id
    $githubUser.Name = $GitHubUserData.login
    $githubUser.Type = $GitHubUserData.type.ToString()

    Write-Host -Object "Created GitHub user with name $($githubUser.Name)."
    $githubUser
}
