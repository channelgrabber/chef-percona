# Install exact version of percona by downloading deb packages

versionCheck =
  "dpkg --compare-versions" +
  " '#{node['percona']['server_deb']['version']}.#{node['lsb']['codename']}'" +
  " '='" +
  " `dpkg -l | grep '^ii' | grep percona-server-server-#{node['percona']['server']['version']} | awk '{print $3}'`"

if !system(versionCheck)
  serverVersion = node['percona']['server']['version']
  versionBuild = node['percona']['server_deb']['version']
  version = versionBuild.rpartition('-').first
  tmp = node['percona']['server_deb']['tmp']
  deb_path = File.join(tmp, "#{serverVersion}_#{versionBuild}.#{node['lsb']['codename']}_amd64")

  directory deb_path do
    recursive true
    action :create
  end

  %w{libdbd-mysql-perl libaio1}.each do |dependency|
    package dependency
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

    dpkg_package "#{package}-#{serverVersion}" do
      source deb
      action :install
    end
  end
end

include_recipe "percona::configure_server"

# access grants
include_recipe "percona::access_grants"

include_recipe "percona::replication"
