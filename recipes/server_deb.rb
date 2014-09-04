# Install exact version of percona by downloading deb packages

serverVersion = node['percona']['server']['version']
versionBuild = node['percona']['server_deb']['version']
version = versionBuild.rpartition('-').first
tmp = node['percona']['server_deb']['tmp']

directory tmp
%w{percona-server-common percona-server-client percona-server-server}.each do |package|
    deb = File.join(tmp, "#{package}-#{serverVersion}_#{versionBuild}.deb")
    source =
        "http://www.percona.com" +
        "/downloads" +
        "/Percona-Server-#{serverVersion}" +
        "/Percona-Server-#{version}" +
        "/binary" +
        "/#{node['platform_family']}" +
        "/#{node['codename']}" +
        "/x86_64" +
        "/percona-server-server-#{serverVersion}_#{versionBuild}.#{node['codename']}_amd64.deb"

    remote_file deb do
        source source
        action :create_if_missing
    end

    apt_package "#{package}-#{serverVersion}" do
        source deb
        options "--force-yes"
        action :install
    end
end


include_recipe "percona::configure_server"

# access grants
include_recipe "percona::access_grants"

include_recipe "percona::replication"