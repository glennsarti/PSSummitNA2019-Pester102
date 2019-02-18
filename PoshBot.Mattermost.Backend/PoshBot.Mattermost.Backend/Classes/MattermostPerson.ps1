class MattermostPerson : Person {
  [string]$Email
  [string]$Phone
  [string]$Skype
  [bool]$IsBot
  [bool]$IsAdmin
  [bool]$IsOwner
  [bool]$IsPrimaryOwner
  [bool]$IsRestricted
  [bool]$IsUltraRestricted
  [string]$Status
  [string]$TimeZoneLabel
  [string]$TimeZone
  [string]$Presence
  [bool]$Deleted

  [hashtable]ToHash() {
    $hash = @{}
    $this | Get-Member -MemberType Property | Foreach-Object {
      $hash.Add($_.Name, $this.($_.name))
    }
    return $hash
  }
}