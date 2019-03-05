mattermost_port = 8065
mattermost_root = "http://localhost:#{mattermost_port}"
status_uri = "#{mattermost_root}/api/v4/system/ping"

# Due to https://github.com/inspec/inspec/issues/2822
# monkey patch the Inspec http resource
module Inspec::Resources
  class Http
    supports platform: 'windows'
  end
end

control 'mattermost-basic-1' do
  impact 'critical'
  title 'Mattermost Server: Basic Connectivity'
  desc 'Basic connectivity tests to test whether Mattermost is even running'
  tag 'mattermost', 'basic'

  # Basic Connectivity Tests
  describe port(mattermost_port) do
    it { should be_listening }
  end

  describe http(mattermost_root) do
    its('status') { should eq 200 }
    its('body') { should match '<title>Mattermost</title>' }
  end
end

control 'mattermost-basic-2' do
  impact 'high'
  title 'Mattermost Server: Status Endpoint tests'
  desc 'Ensuring that the Status API is reporting an Ok status'

  # Status Endpoint Tests
  http_request = http(status_uri)
  describe http_request.status do
    it { should eq 200 }
  end

  describe json(content: http_request.body) do
    its('status') { should eq 'OK' }
  end
end

control 'mattermost-basic-3' do
  impact 'medium'
  title 'Mattermost Server: Server Configuration tests'
  desc 'Ensuring that configuration of the server is in the expected state'

  # Server Configuration Tests
  describe http("#{mattermost_root}/api/v3") do
    its('status') { should eq 404 }
  end

  http_request = http("#{mattermost_root}/api/v4/config/client?format=old")
  describe http_request do
    its('status') { should eq 200 }
  end

  describe json(content: http_request.body) do
    its('Version') { should eq '5.8.0' }
  end
end

control 'mattermost-auth-1' do
  impact 'medium'
  title 'Mattermost Server: User Statistics Endpoint tests'
  desc 'Ensuring that the User Stats. endpoint is reporting the correct information'

  # WARNING - This is a major hack and inspec documentation says you should avoid this
  # and instead use a custom resource. Note this can't be global due to how inspec loads the
  # `control` above.
  #
  # Right now, it's too much effort to learn how to write a ruby based custom resource compared to
  # just a 15 line helper method
  def mattermost_authheader(root_uri)
    return @auth_header unless @auth_header.nil?
    @auth_header = 'abc123'
    request_data = {"login_id" => 'poshbot@example.com', "password" => 'Password1'}.to_json

    auth_response = http("#{root_uri}/api/v4/users/login",
      method: 'POST',
      data: request_data)

    @auth_header = "Bearer #{auth_response.headers.Token}"
  end

  # Users API Tests
  http_request = http("#{mattermost_root}/api/v4/users/stats", headers: { 'Authorization' => mattermost_authheader(mattermost_root) })
  describe http_request do
    its('status') { should eq 200 }
  end

  describe json(content: http_request.body) do
    its('total_users_count') { should be > 1 }
  end
end
