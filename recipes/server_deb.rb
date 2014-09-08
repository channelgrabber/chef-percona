# Install exact version of percona by downloading deb packages

serverVersion = node['percona']['server']['version']
versionBuild = node['percona']['server_deb']['version']
version = versionBuild.rpartition('-').first
tmp = node['percona']['server_deb']['tmp']
deb_path = File.join(tmp, "#{serverVersion}_#{versionBuild}.#{node['lsb']['codename']}_amd64")
version_path = File.join(tmp, "version")

directory deb_path do
    recursive true
    action :create
end

%w{percona-server-common percona-server-server}.each do |package|
    deb = File.join(deb_path, "#{package}.deb")
    source =
        "http://www.percona.com" +
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

%w{libdbd-mysql-perl libaio1}.each do |dependency|
    package dependency
end

execute "percona --version" do
    command "dpkg -l | grep '^ii' | grep percona-server-server | awk '{print $3}' 1>#{version_path} 2>/dev/null"
    action :run
end

dpkg_package "percona-server-server-#{serverVersion}" do
    source deb_path
    version "#{versionBuild}.#{node['lsb']['codename']}"
    options "--recursive --force-depends --force-configure-any"
    not_if "dpkg --compare-versions #{versionBuild}.#{node['lsb']['codename']} '=' $(cat #{version_path})"
    action :install
end

execute "apt-get install -f -y --force-yes"

include_recipe "percona::configure_server"

# access grants
include_recipe "percona::access_grants"

include_recipe "percona::replication"