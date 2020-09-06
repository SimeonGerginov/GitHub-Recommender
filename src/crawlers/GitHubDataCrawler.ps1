Param(
    [Parameter(Mandatory = $true)]
    [ValidateNotNullOrEmpty()]
    [string]
    $AccessToken
)

. (Join-Path -Path $PSScriptRoot -ChildPath 'GitHubCore.ps1')
. (Join-Path -Path $PSScriptRoot -ChildPath 'GitHubUsers.ps1')
. (Join-Path -Path $PSScriptRoot -ChildPath 'GitHubRepositories.ps1')
. (Join-Path -Path $PSScriptRoot -ChildPath 'GitHubActivities.ps1')

$script:dataPath = Join-Path -Path (Split-Path -Path $PSScriptRoot -Parent) -ChildPath 'data'

$script:GitHubUsersPath = Join-Path -Path $script:dataPath -ChildPath 'users.csv'
$script:GitHubRepositoriesPath = Join-Path -Path $script:dataPath -ChildPath 'repositories.csv'
$script:GitHubActivitiesPath = Join-Path -Path $script:dataPath -ChildPath 'activities.csv'

New-Item -Path $script:GitHubUsersPath -Force
New-Item -Path $script:GitHubRepositoriesPath -Force
New-Item -Path $script:GitHubActivitiesPath -Force

$script:NumberOfUsers = 0
$script:MaxNumberOfUsers = 100000

$script:GitHubUsers = @()
$script:GitHubRepositories = @()
$script:GitHubActivities = @()

function Get-GitHubUsers {
    [CmdletBinding()]
    [OutputType([Microsoft.PowerShell.Commands.HtmlWebResponseObject])]
    Param(
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]
        $Uri,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [ValidateSet('Get')]
        [string]
        $Method,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]
        $AccessToken
    )

    if ($script:NumberOfUsers -ge $script:MaxNumberOfUsers) {
        return
    }

    $result = Invoke-GitHubRequest -Uri $Uri -Method $Method -AccessToken $AccessToken
    $githubUsersData = $result.Content | ConvertFrom-Json

    foreach ($githubUserData in $githubUsersData) {
        $githubUser = New-GitHubUser -GitHubUserData $githubUserData
        $script:GitHubUsers += $githubUser

        $starredUrl = $githubUserData.starred_url -Split '{' | Select-Object -First 1
        $repositoryUri = @(
            $githubUserData.repos_url,
            $starredUrl,
            $githubUserData.subscriptions_url
        )
        foreach ($repositoryUri in $repositoryUri) {
            $githubRepositoriesResult = Invoke-GitHubRequest -Uri $repositoryUri -Method $Method -AccessToken $AccessToken
            if ($null -eq $githubRepositoriesResult) {
                continue
            }

            $githubRepositoriesData = $githubRepositoriesResult.Content | ConvertFrom-Json

            $getGitHubRepositoriesParams = @{
                GitHubUserRepositoriesData = $githubRepositoriesData
                Method = $Method
                AccessToken = $AccessToken
                GitHubUserId = $githubUser.Id
                ActivityType = Get-ActivityTypeFromUri($repositoryUri)
            }
            $result = Get-GitHubRepositories @getGitHubRepositoriesParams

            $script:GitHubRepositories += $result.Repositories
            $script:GitHubActivities += $result.Activities
        }

        $script:NumberOfUsers++
    }

    $script:GitHubUsers | Export-Csv -Path $script:GitHubUsersPath -Append -NoTypeInformation -Force
    $script:GitHubRepositories | Export-Csv -Path $script:GitHubRepositoriesPath -Append -NoTypeInformation -Force
    $script:GitHubActivities | Export-Csv -Path $script:GitHubActivitiesPath -Append -NoTypeInformation -Force

    $script:GitHubUsers = @()
    $script:GitHubRepositories = @()
    $script:GitHubActivities = @()

    $links = $result.Headers['Link'] -split ','
    $nextLink = $null

    foreach ($link in $links) {
        if ($link -match '<(.*since=(\d+)[^\d]*)>; rel="next"') {
            $nextLink = $Matches[1]
        }
    }

    return Get-GitHubUsers -Uri $nextLink -Method $Method -AccessToken $AccessToken
}

Get-GitHubUsers -Uri 'https://api.github.com/users' -Method 'Get' -AccessToken $AccessToken
