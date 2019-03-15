# Mattermost UAT Tests

### Plain Pester

``` powershell
PS> & .\RunPester.ps1
```

### Test-Kitchen

``` powershell
PS> bundle install [other cmd line arguments here]

PS> bundle exec kitchen converge

PS> bundle exec kitchen verify

PS> bundle exec kitchen destroy
```

### Gherkin

``` powershell
PS> Invoke-Gherkin .
```
