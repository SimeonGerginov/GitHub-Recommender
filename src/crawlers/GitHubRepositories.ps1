. (Join-Path -Path 'models' -ChildPath 'GitHubRepository.ps1')

function Get-GitHubRepositories {
    <#
    .SYNOPSIS
        Creates a new GitHubRepository for each GitHub user repository.

    .DESCRIPTION
        Creates a new GitHubRepository for each GitHub user repository.

    .PARAMETER GitHubUserRepositoriesData
        The GitHub user repositories data that is retrieved via the GitHub API.

    .OUTPUTS
        [PSCustomObject[]] - The array of constructed custom object containing
        GitHubRepository and GitHubActivity objects.
    #>
    [CmdletBinding()]
    [OutputType([GitHubRepository[]])]
    Param(
        [Parameter(Mandatory = $true)]
        [ValidateNotNull()]
        [PSCustomObject[]]
        $GitHubUserRepositoriesData,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [ValidateSet('Get')]
        [string]
        $Method,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]
        $AccessToken,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]
        $GitHubUserId,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [GitHubActivityType]
        $ActivityType
    )

    $githubRepositories = @()
    $githubActivities = @()

    foreach ($githubUserRepositoryData in $GitHubUserRepositoriesData) {
        $githubRepository = New-GitHubRepository -GitHubRepositoryData $githubUserRepositoryData

        $githubRepositoryLanguagesResult = Invoke-GitHubRequest -Uri $githubUserRepositoryData.languages_url -Method $Method -AccessToken $AccessToken
        if ($null -eq $githubRepositoryLanguagesResult) {
            continue
        }

        $githubRepositoryLanguagesData = $githubRepositoryLanguagesResult.Content | ConvertFrom-Json

        $githubRepository.Languages = Get-GitHubRepositoryLanguages -GitHubRepositoryLanguagesData $githubRepositoryLanguagesData

        $githubRepositories += $githubRepository

        if ($ActivityType -eq [GitHubActivityType]::Fork) {
            if ($githubUserRepositoryData.fork) {
                $githubActivities += New-GitHubActivity -RepositoryId $githubRepository.Id -UserId $GitHubUserId -ActivityType $ActivityType
            }
        }
        else {
            $githubActivities += New-GitHubActivity -RepositoryId $githubRepository.Id -UserId $GitHubUserId -ActivityType $ActivityType
        }
    }

    $result = [PSCustomObject]@{
        'Repositories' = $githubRepositories
        'Activities' = $githubActivities
    }

    $result
}

function New-GitHubRepository {
    <#
    .SYNOPSIS
        Creates a new GitHubRepository from the provided GitHub repository data.

    .DESCRIPTION
        Creates a new GitHubRepository from the provided GitHub repository data.

    .PARAMETER GitHubRepositoryData
        The GitHub repository data that is retrieved via the GitHub API.

    .OUTPUTS
        [GitHubRepository] - The constructed GitHubRepository object.
    #>
    [CmdletBinding()]
    [OutputType([GitHubRepository])]
    Param(
        [Parameter(Mandatory = $true)]
        [ValidateNotNull()]
        [PSCustomObject]
        $GitHubRepositoryData
    )

    $githubRepository = [GitHubRepository]::new()

    $githubRepository.Id = $GitHubRepositoryData.id
    $githubRepository.Name = $GitHubRepositoryData.name
    $githubRepository.Description = $GitHubRepositoryData.description
    $githubRepository.OwnerId = $GitHubRepositoryData.owner.id
    $githubRepository.CreatedAt = $GitHubRepositoryData.created_at
    $githubRepository.UpdatedAt = $GitHubRepositoryData.updated_at

    Write-Host -Object "Created GitHub repository with name $($githubRepository.Name)."
    $githubRepository
}

function Get-GitHubRepositoryLanguages {
    <#
    .SYNOPSIS
        Gets the languages of the specified GitHub repository.

    .DESCRIPTION
        Gets the languages of the specified GitHub repository from the provided
        GitHub repository languages data.

    .PARAMETER GitHubRepositoryLanguagesData
        The GitHub repository languages data that is retrieved via the GitHub API.

    .OUTPUTS
        [string[]] - The array of languages that are used in the specified
        GitHub repository.
    #>
    [CmdletBinding()]
    [OutputType([string[]])]
    Param(
        [Parameter(Mandatory = $true)]
        [ValidateNotNull()]
        [PSCustomObject]
        $GitHubRepositoryLanguagesData
    )

    $languages = [string[]]($GitHubRepositoryLanguagesData | Get-Member -MemberType NoteProperty | Select-Object -ExpandProperty Name)
    $languages
}
