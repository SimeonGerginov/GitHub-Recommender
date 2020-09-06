. (Join-Path -Path 'models' -ChildPath 'GitHubActivity.ps1')

function New-GitHubActivity {
    <#
    .SYNOPSIS
        Creates a new GitHubActivity for the specified GitHub user and repository.

    .DESCRIPTION
        Creates a new GitHubActivity for the specified GitHub user and repository.

    .PARAMETER RepositoryId
        The ID of the GitHub repository.

    .PARAMETER UserId
        The ID of the GitHub user.

    .PARAMETER ActivityType
        The type of Activity. Can be 'Fork, 'Star' and 'Watch'.

    .OUTPUTS
        [GitHubActivity - The constructed GitHubActivity objects.
    #>
    [CmdletBinding()]
    [OutputType([GitHubActivity])]
    Param(
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]
        $RepositoryId,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]
        $UserId,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [ValidateSet('Fork', 'Star', 'Watch')]
        [string]
        $ActivityType
    )

    $githubActivity = [GitHubActivity]::new()

    $githubActivity.RepositoryId = $RepositoryId
    $githubActivity.UserId = $UserId
    $githubActivity.ActivityType = $ActivityType

    $githubActivity
}

function Get-ActivityTypeFromUri {
    [CmdletBinding()]
    [OutputType([GitHubActivityType])]
    Param(
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]
        $Uri
    )

    $result = $null

    if ($Uri.EndsWith("/subscriptions")) {
        $result = [GitHubActivityType]::Watch
    }
    elseif ($Uri.EndsWith("/starred")) {
        $result = [GitHubActivityType]::Star
    }
    else {
        $result = [GitHubActivityType]::Fork
    }

    $result
}
