percona = node["percona"]
server  = percona["server"]
conf    = percona["conf"]
mysqld  = (conf && conf["mysqld"]) || {}
restart_lock_file = File.join(node["percona"]["server"]["datadir"], "restart.lock");

# construct an encrypted passwords helper -- giving it the node and bag name
passwords = EncryptedPasswords.new(node, percona["encrypted_data_bag"])

template "/root/.my.cnf" do
  variables(:root_password => passwords.root_password)
  owner "root"
  group "root"
  mode 0600
  source "my.cnf.root.erb"
end

if server["bind_to"]
  ipaddr = Percona::ConfigHelper.bind_to(node, server["bind_to"])
  if ipaddr && server["bind_address"] != ipaddr
    node.override["percona"]["server"]["bind_address"] = ipaddr
    node.save
  end

  log "Can't find ip address for #{server["bind_to"]}" do
    level :warn
    only_if { ipaddr.nil? }
  end
end

datadir = mysqld["datadir"] || server["datadir"]
user    = mysqld["username"] || server["username"]

# define the service
service "mysql" do
  supports :restart => true
  action server["enable"] ? :enable : :disable
end

# this is where we dump sql templates for replication, etc.
directory "/etc/mysql" do
  owner "root"
  group "root"
  mode 0755
end

# setup the data directory
directory datadir do
  owner user
  group user
  recursive true
  action :create
end

# install db to the data directory
execute "setup mysql datadir" do
  command "mysql_install_db --user=#{user} --datadir=#{datadir}"
  not_if "test -f #{datadir}/mysql/user.frm"
end

# setup the main server config file
template percona["main_config_file"] do
  source "my.cnf.#{conf ? "custom" : server["role"]}.erb"
  owner "root"
  group "root"
  mode 0744
  notifies :restart, "service[mysql]", :delayed if !File.exists?(restart_lock_file)
end

# now let's set the root password only if this is the initial install
execute "Update MySQL root password" do
  command "mysqladmin --user=root --password='' password '#{passwords.root_password}'"
  not_if "test -f /etc/mysql/grants.sql"
end

# setup the debian system user config
template "/etc/mysql/debian.cnf" do
  source "debian.cnf.erb"
  variables(:debian_password => passwords.debian_password)
  owner "root"
  group "root"
  mode 0640
  notifies :restart, "service[mysql]", :delayed if !File.exists?(restart_lock_file)

  only_if { node["platform_family"] == "debian" }
end

# Setup restart lock, so the mysql server is not restarte
file restart_lock_file do
  owner "root"
  group "root"
  mode "0644"
  action :create
end