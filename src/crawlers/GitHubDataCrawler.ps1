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

$script:TrackGitHubAPIProgressPath = Join-Path -Path $PSScriptRoot -ChildPath 'trackGitHubAPIProgress.csv'

if (!(Test-Path -Path $script:TrackGitHubAPIProgressPath)) {
    New-Item -Path $script:GitHubUsersPath -Force
    New-Item -Path $script:GitHubRepositoriesPath -Force
    New-Item -Path $script:GitHubActivitiesPath -Force
    New-Item -Path $script:TrackGitHubAPIProgressPath -Force
}

$script:StartUri = Get-Content -Path $script:TrackGitHubAPIProgressPath -Tail 1

$script:NumberOfUsers = (Get-Content -Path $script:GitHubUsersPath | Measure-Object | Select-Object -ExpandProperty Count) - 1
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

    $Uri | Out-File -FilePath $script:TrackGitHubAPIProgressPath -Append -Force

    $result = Invoke-GitHubRequest -Uri $Uri -Method $Method -AccessToken $AccessToken
    $githubUsersData = $result.Content | ConvertFrom-Json

    foreach ($githubUserData in $githubUsersData) {
        Write-Host -Object "$(Get-Date) --- $($script:NumberOfUsers + 1). Retrieving User with ID $($githubUserData.id) and name $($githubUserData.login)"
        $githubUser = New-GitHubUser -GitHubUserData $githubUserData
        $script:GitHubUsers += $githubUser

        $starredUrl = $githubUserData.starred_url -Split '{' | Select-Object -First 1
        $repositoryUris = @(
            $githubUserData.repos_url,
            $starredUrl,
            $githubUserData.subscriptions_url
        )
        foreach ($repositoryUri in $repositoryUris) {
            if ([string]::IsNullOrEmpty($repositoryUri)) {
                continue
            }

            $githubRepositoriesResult = Invoke-GitHubRequest -Uri $repositoryUri -Method $Method -AccessToken $AccessToken
            if ($null -eq $githubRepositoriesResult) {
                continue
            }

            $githubRepositoriesData = $githubRepositoriesResult.Content | ConvertFrom-Json
            if ($null -eq $githubRepositoriesData -or $githubRepositoriesData.Count -eq 0) {
                continue
            }

            $getGitHubRepositoriesParams = @{
                GitHubUserRepositoriesData = $githubRepositoriesData
                Method = $Method
                AccessToken = $AccessToken
                GitHubUserId = $githubUser.Id
                ActivityType = Get-ActivityTypeFromUri($repositoryUri)
            }
            $repositoriesData = Get-GitHubRepositories @getGitHubRepositoriesParams

            $script:GitHubRepositories += $repositoriesData.Repositories
            $script:GitHubActivities += $repositoriesData.Activities
        }

        $script:NumberOfUsers++
    }

    $script:GitHubUsers | Export-Csv -Path $script:GitHubUsersPath -Append -NoTypeInformation -Force
    $script:GitHubRepositories | Export-Csv -Path $script:GitHubRepositoriesPath -Append -NoTypeInformation -Force
    $script:GitHubActivities | Export-Csv -Path $script:GitHubActivitiesPath -Append -NoTypeInformation -Force

    $script:GitHubUsers = @()
    $script:GitHubRepositories = @()
    $script:GitHubActivities = @()

    if ($result.Headers.Count -gt 0) {
        $links = $result.Headers['Link'] -split ','
        $nextLink = $null

        foreach ($link in $links) {
            if ($link -match '<(.*since=(\d+)[^\d]*)>; rel="next"') {
                $nextLink = $Matches[1]
            }
        }

        return Get-GitHubUsers -Uri $nextLink -Method $Method -AccessToken $AccessToken
    }
}

if ($null -ne $script:StartUri) {
    Get-GitHubUsers -Uri $script:StartUri -Method 'Get' -AccessToken $AccessToken
}
else {
    Get-GitHubUsers -Uri 'https://api.github.com/users' -Method 'Get' -AccessToken $AccessToken
}
