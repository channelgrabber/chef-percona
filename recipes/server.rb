include_recipe "percona::package_repo"

# install packages
case node["platform_family"]
when "debian"
  version = node['percona']['server']['version']
  package "percona-server-server-#{version}" do
    action :install
    options "--force-yes"
  end
when "rhel"
  version = node['percona']['server']['version'].sub(".", "")
  # Need to remove this to avoid conflicts
  package "mysql-libs" do
    action :remove
    not_if "rpm -qa | grep Percona-Server-shared-#{version}"
  end

  # we need mysqladmin
  include_recipe "percona::client"

  package "Percona-Server-server-#{version}" do
    action :install
  end
end

include_recipe "percona::configure_server"

# access grants
include_recipe "percona::access_grants"

include_recipe "percona::replication"
