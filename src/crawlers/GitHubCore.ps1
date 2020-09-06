function Invoke-GitHubRequest {
    <#
    .SYNOPSIS
        A wrapper around Invoke-WebRequest that understands the GitHub API.

    .DESCRIPTION
        A wrapper around Invoke-WebRequest that understands the GitHub API. It also
        understands how to parse and handle errors from the REST API calls.

    .PARAMETER Uri
        The REST Uri that indicates what GitHub REST action will be performed.

    .PARAMETER Method
        The type of REST method being performed. This only supports a reduced set of the
        possible REST methods (get).

    .PARAMETER AccessToken
        The Access Token that is used for the GitHub REST action.

    .OUTPUTS
        [Microsoft.PowerShell.Commands.HtmlWebResponseObject] - The result of the REST operation,
        in whatever form it comes in.

    .EXAMPLE
        Invoke-GitHubRequest -Uri 'https://api.github.com/users' -Method 'Get' -AccessToken 'MyAccessToken'

        Gets information about the first batch of returned users from the GitHub API.
    #>
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

    $result = $null
    $retriesCount = 60

    $base64Token = [System.Convert]::ToBase64String([char[]] $AccessToken)
    $invokeWebRequestParams = @{
        Uri = $Uri
        Method = $Method
        Headers = @{
            Authorization = "Basic $base64Token"
        }
    }

    while ($retriesCount -gt 0) {
        try {
            $result = Invoke-WebRequest @invokeWebRequestParams
            break
        }
        catch {
            if ($_.ErrorDetails.Message -Match 'Repository access blocked') {
                break
            }
            elseif ($_.ErrorDetails.Message -Match 'API rate limit exceeded') {
                Write-Warning -Message $_.ErrorDetails.Message -ErrorAction Continue
                Write-Warning -Message $_.Exception.Message -ErrorAction Continue
                Start-Sleep -Seconds 60
                $retriesCount -= 1
            }
            else {
                Write-Error -Message $_.ErrorDetails.Message -ErrorAction Stop
            }
        }
        finally {
            $error.Clear()
        }
    }

    return $result
}
