#
# Cookbook Name:: owncloud
# Recipe:: default
#
# Copyright (C) 2012 YOUR_NAME
# 
# All rights reserved - Do Not Redistribute
#

include_recipe "php"
include_recipe "php::module_mysql"
include_recipe "php::module_gd"
include_recipe "apache2"
include_recipe "apache2::mod_php5"
include_recipe "mysql::ruby"
include_recipe "mysql::server"
include_recipe "database"
include_recipe "ark"
include_recipe "openssl"

::Chef::Recipe.send(:include, Opscode::OpenSSL::Password)

node.set_unless['owncloud']['admin_password'] = secure_password
node.set_unless['owncloud']['db_password'] = secure_password

ark "owncloud" do
  owner node["apache"]["user"]
  action :put
  path "/var/www"
  url "http://mirrors.owncloud.org/releases/owncloud-4.5.4.tar.bz2"
  checksum "13e3be1c90e41d520123a1d0daeb4f594ad04dca7b318f999a6573088cf40657"
end

directory "/var/www/owncloud/data" do
  owner node["apache"]["user"]
  group node["apache"]["group"]
end

mysql_connection_info = {:host => "localhost", :username => 'root', :password => node['mysql']['server_root_password']}

database node["owncloud"]["db_name"] do
  connection mysql_connection_info
  provider Chef::Provider::Database::Mysql
  action :create
end

database_user node["owncloud"]["db_user"] do
  connection mysql_connection_info
  provider Chef::Provider::Database::MysqlUser
  password node["owncloud"]["db_password"]
  action :create
end

database_user node["owncloud"]["db_user"] do
  connection mysql_connection_info
  provider Chef::Provider::Database::MysqlUser
  database_name node["owncloud"]["db_name"]
  privileges [:all] 
  action :grant
end

template "/var/www/owncloud/config/autoconfig.php" do
  source "autoconfig.php.erb"
  owner node["apache"]["user"]
  group node["apache"]["group"]
  mode "0644"
end

name = cookbook_name

host = "#{name}.#{node['fqdn']}"

web_app "owncloud" do
  template "owncloud.vhost.erb"
  server_name host
  server_aliases [host]
  docroot "/var/www/#{name}"
  allow_override "All"
end
