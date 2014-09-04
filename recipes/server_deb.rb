# Install exact version of percona by downloading deb packages

serverVersion = node['percona']['server']['version']
versionBuild = node['percona']['server_deb']['version']
version = versionBuild.rpartition('-').first
tmp = node['percona']['server_deb']['tmp']
deb_path = File.join(tmp, "#{serverVersion}_#{versionBuild}.#{node['lsb']['codename']}_amd64")

directory deb_path do
    recursive true
    action :create
end

%w{percona-server-common percona-server-client percona-server-server}.each do |package|
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
        "/percona-server-server-#{serverVersion}_#{versionBuild}.#{node['lsb']['codename']}_amd64.deb"

    remote_file deb do
        source source
        action :create_if_missing
    end
end

dpkg_package "percona-server-#{serverVersion}" do
    source deb_path
    options "--recursive"
    action :install
end

include_recipe "percona::configure_server"

# access grants
include_recipe "percona::access_grants"

include_recipe "percona::replication"