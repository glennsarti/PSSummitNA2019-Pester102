function New-PoshBotMattermostBackend {
  <#
  .SYNOPSIS
    Create a new instance of a Mattermost backend
  .DESCRIPTION
    Create a new instance of a Mattermost backend
  .PARAMETER Configuration
    The hashtable containing backend-specific properties on how to create the Mattermost backend instance.
  .EXAMPLE
    # TODO WEE!!
    PS C:\> $backendConfig = @{Name = 'MattermostBackend'; Token = '<Mattermost-API-TOKEN>'}
    PS C:\> $backend = New-PoshBotMattermostBackend -Configuration $backendConfig

    Create a Mattermost backend using the specified API token
  .INPUTS
    Hashtable
  .OUTPUTS
    MattermostBackend
  #>
  [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseShouldProcessForStateChangingFunctions', '', Scope='Function', Target='*')]
  [cmdletbinding()]
  param(
    [parameter(Mandatory, ValueFromPipeline, ValueFromPipelineByPropertyName)]
    [Alias('BackendConfiguration')]
    [hashtable[]]$Configuration
  )

  process {
    if ($Configuration.Token -eq $null) { throw 'Configuration is missing [Token] parameter' }
    if ($Configuration.ApiUri -eq $null) { throw 'Configuration is missing [ApiUri] parameter' }
    $backend = [MattermostBackend]::new($Configuration.Token, $Configuration.ApiUri)

    if ($item.Name) {
      $backend.Name = $item.Name
    }
    $backend
  }
}

Export-ModuleMember -Function 'New-PoshBotMattermostBackend'
