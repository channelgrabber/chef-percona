# execute access grants
execute "mysql-install-backup-db" do
  command "/usr/bin/mysqladmin -u root -p'#{node['percona']['server']['root_password']}' create #{node['percona']['backup']['db']}"
  not_if do
    FileTest.directory?("/var/lib/mysql/frontend")
  end
end
if File.exist?("#{node['percona']['backup']['sql']}") then
  execute "mysql-install-backup" do
    command "/usr/bin/mysql -u root -p'#{node['percona']['server']['root_password']}' #{node['percona']['backup']['db']} < #{node['percona']['backup']['sql']}"
  end
fi