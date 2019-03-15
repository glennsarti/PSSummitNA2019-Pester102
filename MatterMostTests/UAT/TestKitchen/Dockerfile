FROM mattermost/mattermost-preview

ENV MM_SERVICESETTINGS_SITEURL http://localhost:8056
ENV MM_LOGSETTINGS_CONSOLELEVEL ERROR
ENV MM_LOGSETTINGS_FILELEVEL DEBUG
ENV MM_SERVICESETTINGS_ENABLEUSERACCESSTOKENS true

RUN apt-get update

# Add default Test Kitchen stuff
RUN [ ! -f "/sbin/initctl" ] || dpkg-divert --local --rename --add /sbin/initctl && ln -sf /bin/true /sbin/initctl
ENV DEBIAN_FRONTEND noninteractive
ENV container docker
RUN apt-get install -y sudo openssh-server curl lsb-release
RUN if ! getent passwd kitchen; then                 useradd -d /home/<%= @username %> -m -s /bin/bash -p '*' <%= @username %>;               fi
RUN echo "<%= @username %> ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers
RUN echo "Defaults !requiretty" >> /etc/sudoers
RUN mkdir -p /home/<%= @username %>/.ssh
RUN chown -R <%= @username %> /home/<%= @username %>/.ssh
RUN chmod 0700 /home/<%= @username %>/.ssh
RUN touch /home/<%= @username %>/.ssh/authorized_keys
RUN chown <%= @username %> /home/<%= @username %>/.ssh/authorized_keys
RUN chmod 0600 /home/<%= @username %>/.ssh/authorized_keys
RUN echo '<%= IO.read(@public_key).strip %>' >> /home/<%= @username %>/.ssh/authorized_keys

# Install PowerShell
RUN apt-get install -y curl gnupg apt-transport-https
RUN curl https://packages.microsoft.com/keys/microsoft.asc | apt-key add -
RUN sh -c 'echo "deb [arch=amd64] https://packages.microsoft.com/repos/microsoft-debian-stretch-prod stretch main" > /etc/apt/sources.list.d/microsoft.list'
RUN apt-get update
RUN apt-get install -y powershell
# Install Poshbot
RUN pwsh -NonInteractive -NoProfile -Command "Install-Module Poshbot -Force"
RUN pwsh -NonInteractive -NoProfile -Command "Install-Module Pester -Force"
# Add the Mattermost backend
ADD PoshBot.Mattermost.Backend.psd1 /mm/PoshBot.Mattermost.Backend.psd1
ADD PoshBot.Mattermost.Backend.psm1 /mm/PoshBot.Mattermost.Backend.psm1
ADD RunPoshBot.ps1 /mm/RunPoshBot.ps1

# Modify the docker-entry file
ADD docker-entry.sh /mm/docker-entry.sh
RUN chmod +x /mm/docker-entry.sh
