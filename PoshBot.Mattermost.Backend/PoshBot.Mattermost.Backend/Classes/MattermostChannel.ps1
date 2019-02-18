class MattermostChannel : Room {
  [datetime]$Created
  [string]$Creator
  [bool]$IsArchived
  [bool]$IsGeneral
  [int]$MemberCount
  [string]$Purpose
}