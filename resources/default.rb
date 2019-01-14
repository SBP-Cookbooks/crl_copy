#
# Cookbook Name:: crl_copy
# Resource:: crl_copy
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

resource_name :crl_copy

default_action :create

property :master_crl, String,
         name_property: true

property :cdps, [Array, Hash],
         required: true

property :cluster_name, String,
         required: false

property :outfile, [Array, String],
         required: false

property :eventvwr_event_id, [Integer, String],
         required: false,
         default: lazy { node['crl_copy']['eventvwr']['event_id'] }

property :eventvwr_event_source, String,
         required: false,
         default: lazy { node['crl_copy']['eventvwr']['event_source'] }

property :smtp_from, [String, nil],
         required: false,
         default: lazy { node['crl_copy']['smtp']['from'] }

property :smtp_published_notify, [TrueClass, FalseClass],
         required: false,
         default: lazy { node['crl_copy']['smtp']['published_notify'] }

property :smtp_send_mail, [TrueClass, FalseClass],
         required: false,
         default: lazy { node['crl_copy']['smtp']['send_mail'] }

property :smtp_server, [String, nil],
         required: false,
         default: lazy { node['crl_copy']['smtp']['server'] }

property :smtp_threshold, [Integer, String],
         required: false,
         default: lazy { node['crl_copy']['smtp']['threshold'] }

property :smtp_title, String,
         required: false,
         default: lazy { node['crl_copy']['smtp']['title'] }

property :smtp_to, [Array, String, nil],
         required: false,
         default: lazy { node['crl_copy']['smtp']['to'] }

property :warnings_threshold, [Integer, String],
         required: false,
         default: lazy { node['crl_copy']['warnings']['threshold'] }

property :warnings_threshold_unit, String,
         required: false,
         default: lazy { node['crl_copy']['warnings']['threshold_unit'] },
         regex: /^(Days|Hours|Minutes|Seconds)$/i

property :windows_task_frequency, String,
         required: false,
         default: lazy { node['crl_copy']['windows_task']['frequency'] },
         regex: /^(Monthly|Weekly|Daily|Hourly|Minute)$/i

property :windows_task_frequency_modifier, [Integer, String],
         required: false,
         default: lazy { node['crl_copy']['windows_task']['frequency_modifier'] }

property :windows_task_password, [String, nil],
         required: false,
         default: lazy { node['crl_copy']['windows_task']['password'] }

property :windows_task_user, String,
         required: false,
         default: lazy { node['crl_copy']['windows_task']['user'] }

action :create do
  include_recipe 'pspki::default' unless node.recipe?('pspki::default')

  directory 'C:\CrlCopy'

  cookbook_file 'C:\CrlCopy\crl_copy_v3.ps1' do
    source 'crl_copy_v3.ps1'
  end

  crl_path = Chef::Util::PathHelper.cleanpath(new_resource.master_crl)

  crl_file = ::File.basename(crl_path.tr('\\', '/'))
  crl_dir  = crl_path.gsub(crl_file, '')

  htm_file = "#{::File.basename(crl_file, ::File.extname(crl_file))}_CRL_Status.htm".tr(' ', '_')
  xml_file = "#{::File.basename(crl_file, ::File.extname(crl_file))}_CRL_Config.xml".tr(' ', '_')

  out_file = new_resource.outfile
  out_file = 'C:\CrlCopy\\' + htm_file if out_file.nil?
  out_file = [out_file] unless out_file.is_a?(Array)

  smtp_to = new_resource.smtp_to
  smtp_to = [smtp_to] unless smtp_to.is_a?(Array)

  template "C:\\CrlCopy\\#{xml_file}" do
    source 'CRL_Config.XML.erb'
    variables(
      cdps: new_resource.cdps,
      cluster_name: new_resource.cluster_name,
      crl_file: crl_file,
      crl_dir: crl_dir,
      eventvwr_event_id: new_resource.eventvwr_event_id,
      eventvwr_event_source: new_resource.eventvwr_event_source,
      outfile: out_file,
      smtp_from: new_resource.smtp_from,
      smtp_published_notify: new_resource.smtp_published_notify,
      smtp_send_mail: new_resource.smtp_send_mail,
      smtp_server: new_resource.smtp_server,
      smtp_threshold: new_resource.smtp_threshold,
      smtp_title: new_resource.smtp_title,
      smtp_to: smtp_to,
      warnings_threshold: new_resource.warnings_threshold,
      warnings_threshold_unit: new_resource.warnings_threshold_unit.downcase.capitalize
    )
  end

  windows_task "CRLCopy #{crl_file}" do
    user new_resource.windows_task_user
    password new_resource.windows_task_password if new_resource.windows_task_password
    command "%SystemRoot%\\system32\\WindowsPowerShell\\v1.0\\powershell.exe C:\\CrlCopy\\crl_copy_v3.ps1 -Action Publish -XmlFile C:\\CrlCopy\\#{xml_file}"
    run_level :highest
    frequency new_resource.windows_task_frequency.downcase.to_sym
    frequency_modifier new_resource.windows_task_frequency_modifier.to_i
  end
end
