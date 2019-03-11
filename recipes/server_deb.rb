# Install exact version of percona by downloading deb packages

serverVersion = node['percona']['server']['version']
versionBuild = node['percona']['server_deb']['version']
version = versionBuild.rpartition('-').first

currentVersion = `dpkg -l | grep '^ii' | grep percona-server-server | awk '{print $3}'`.strip
unless currentVersion.empty? || Gem::Dependency.new('percona', "~>#{serverVersion}.0").match?('percona', currentVersion.partition("-").first)
  Chef::Application.fatal!("Unable to migrate percona-server-server (#{currentVersion}) to #{serverVersion}")
end

tmp = node['percona']['server_deb']['tmp']
debPath = File.join(tmp, "#{serverVersion}_#{versionBuild}.#{node['lsb']['codename']}_amd64")
packages = %w{percona-server-common percona-server-client percona-server-server}

directory debPath do
    recursive true
    action :create
end

packages.each do |package|
    deb = File.join(debPath, "#{package}.deb")
    source =
        "https://www.percona.com" +
        "/downloads" +
        "/Percona-Server-#{serverVersion}" +
        "/Percona-Server-#{version}" +
        "/binary" +
        "/#{node['platform_family']}" +
        "/#{node['lsb']['codename']}" +
        "/x86_64" +
        "/#{package}-#{serverVersion}_#{versionBuild}.#{node['lsb']['codename']}_amd64.deb"

    remote_file deb do
        source source
        action :create_if_missing
    end
end

%w{libmecab2 libjemalloc1 zlib1g-dev libaio1}.each do |dependency|
    package dependency
end

unless Gem::Dependency.new('percona', version).match?('percona', (currentVersion.empty? ? versionBuild : currentVersion).partition("-").first)
  packages.each do |package|
    dpkg_package "#{package}-#{serverVersion}" do
        source File.join(debPath, "#{package}.deb")
        version "#{versionBuild}.#{node['lsb']['codename']}"
        options "--force-configure-any"
        action :install
    end
  end
end

include_recipe "percona::configure_server"

# access grants
include_recipe "percona::access_grants"

include_recipe "percona::replication"