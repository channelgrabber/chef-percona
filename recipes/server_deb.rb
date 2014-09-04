# Install exact version of percona by downloading deb packages

serverVersion = node['percona']['server']['version']
versionBuild = node['percona']['server_deb']['version']
version = versionBuild.rpartition('-').first
tmp = node['percona']['server_deb']['tmp']
deb_path = File.join(tmp, version, versionBuild)

directory path do
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

    dpkg_package "#{package}-#{serverVersion}" do
        source deb
        version "#{versionBuild}.#{node['lsb']['codename']}"
        action :install
    end
end

dpkg_package "percona-server-#{serverVersion}" doe
    source deb_path
    options "--recursive"
    action :install
end

include_recipe "percona::configure_server"

# access grants
include_recipe "percona::access_grants"

include_recipe "percona::replication"