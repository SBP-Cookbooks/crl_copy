#
# Cookbook Name:: crl_copy
# Recipe:: default
#
# Copyright (C) 2016 Schuberg Philis
#
# Created by: Stephen Hoekstra <shoekstra@schubergphilis.com>
#

remote_file "#{Chef::Config['file_cache_path']}/pscx.msi" do
  source node['crl_copy']['pscx']['source_url']
end

package node['crl_copy']['pscx']['package_name'] do
  source "#{Chef::Config['file_cache_path']}/pscx.msi"
  installer_type :msi
end

remote_file "#{Chef::Config['file_cache_path']}/pspki.exe" do
  source node['crl_copy']['pspki']['source_name']
end

package node['crl_copy']['pspki']['package_name'] do
  source "#{Chef::Config['file_cache_path']}/pspki.exe"
  installer_type :custom
  options 'addlocal=all /qn'
end

log 'crl_copy::default: No master CRLs specified, skipping crl_copy resource.' do
  level :warn
  not_if { node['crl_copy']['master_crls'] }
end

if node['crl_copy']['master_crls']
  node['crl_copy']['master_crls'].each do |master_crl, props|
    crl_copy master_crl do
      props.each { |key, value| send(key, value) unless value.nil? }
    end
  end
end
