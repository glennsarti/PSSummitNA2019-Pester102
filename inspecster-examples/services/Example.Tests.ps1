Control "XBox Services: Disable all" -Metadata @{
    'impact' = 0.6
    'title' = 'Server: Configure the service port'
    'desc' = 'Always specify which port the SSH server should listen.'
    'tag' = @('ssh','sshd','openssh-server')
    'ref' = @('NSA-RH6-STIG - Section 3.5.2.1', 'https://www.nsa.gov/ia/_files/os/redhat/rhel5-guide-i731.pdf')
  } {

#Describe "XblAuthManager" {
  it "should not exist or be running" {
    $result = Get-Service 'XblAuthManager' -ErrorAction SilentlyContinue

    if ($result -eq $null) {
      $result | Should -BeNullOrEmpty
    } else {
      #$result.Status | Should -Be 'Stopped'
      $result.Status | Should -Be 'Started'
    }
  }
}

# Describe "Blah" -Metadata @{
#   'impact' = 0.7
#   'title' = 'Server: Casdasdasdonfigure the service port'
#   'desc' = 'Alwaasfasdys specify which port the SSH server should listen.'
#   'tag' = @('ssh','sshd','opeasdasdsdnssh-server')
#   'ref' = @('NSA-RH6-SadasdaTIG - Section 3.5.2.1', 'https://www.nsa.gov/ia/_files/os/redhat/rhel5-guide-i731.pdf')
# } {

# it "should not exist or be running" {
#   $result = Get-Service 'XblAuthManager' -ErrorAction SilentlyContinue

#   if ($result -eq $null) {
#     $result | Should -BeNullOrEmpty
#   } else {
#     #$result.Status | Should -Be 'Stopped'
#     $result.Status | Should -Be 'Started'
#   }
# }
# }
