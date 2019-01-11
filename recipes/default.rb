#
# Cookbook Name:: crl_copy
# Recipe:: default
#
# Copyright:: 2016-2019, Schuberg Philis
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

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
