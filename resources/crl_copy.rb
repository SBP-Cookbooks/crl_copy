#
# Cookbook Name:: crl_copy
# Resource:: crl_copy
#
# Copyright (C) 2016 Schuberg Philis
#
# Created by: Stephen Hoekstra <shoekstra@schubergphilis.com>
#

include Windows::Helper

resource_name :crl_copy

actions :create, :delete
default_action :create

property :master_crl, kind_of: String, required: true, name_property: true
property :cdps, kind_of: [Array, Hash], required: true, default: nil
property :cluster_name, kind_of: String, required: false, default: nil
property :has_delta_crl, kind_of: [TrueClass, FalseClass], required: true, default: false
property :outfile, kind_of: [Array, String], required: false, default: nil

property :eventvwr_event_high, kind_of: [Fixnum, String], required: false, default: lazy { node['crl_copy']['eventvwr']['event_high'] }
property :eventvwr_event_id, kind_of: [Fixnum, String], required: false, default: lazy { node['crl_copy']['eventvwr']['event_id'] }
property :eventvwr_event_information, kind_of: [Fixnum, String], required: false, default: lazy { node['crl_copy']['eventvwr']['event_information'] }
property :eventvwr_event_source, kind_of: String, required: false, default: lazy { node['crl_copy']['eventvwr']['event_source'] }
property :eventvwr_event_warning, kind_of: [Fixnum, String], required: false, default: lazy { node['crl_copy']['eventvwr']['event_warning'] }

property :smtp_from, kind_of: String, required: false, default: lazy { node['crl_copy']['smtp']['from'] }
property :smtp_published_notify, kind_of: [TrueClass, FalseClass], required: false, default: lazy { node['crl_copy']['smtp']['published_notify'] }
property :smtp_send_mail, kind_of: [TrueClass, FalseClass], required: false, default: lazy { node['crl_copy']['smtp']['send_mail'] }
property :smtp_server, kind_of: String, required: false, default: lazy { node['crl_copy']['smtp']['server'] }
property :smtp_threshold, kind_of: [Fixnum, String], required: false, default: lazy { node['crl_copy']['smtp']['threshold'] }
property :smtp_title, kind_of: String, required: false, default: lazy { node['crl_copy']['smtp']['title'] }
property :smtp_to, kind_of: [Array, String], required: false, default: lazy { node['crl_copy']['smtp']['to'] }

property :warnings_threshold, kind_of: [Fixnum, String], required: false, default: lazy { node['crl_copy']['warnings']['threshold'] }
property :warnings_threshold_unit, kind_of: String, required: false, default: lazy { node['crl_copy']['warnings']['threshold_unit'] }, regex: /^(Days|Hours|Minutes|Seconds)$/i

property :windows_task_frequency, kind_of: String, required: false, default: lazy { node['crl_copy']['windows_task']['frequency'] }, regex: /^(Monthly|Weekly|Daily|Hourly|Minute)$/i
property :windows_task_frequency_modifier, kind_of: [Fixnum, String], required: false, default: lazy { node['crl_copy']['windows_task']['frequency_modifier'] }
property :windows_task_password, kind_of: String, required: false, default: lazy { node['crl_copy']['windows_task']['password'] }
property :windows_task_user, kind_of: String, required: false, default: lazy { node['crl_copy']['windows_task']['user'] }

action :create do
  #
  # Install and configure the CRL Copy script
  # https://gallery.technet.microsoft.com/scriptcenter/Powershell-CRL-Copy-v3-d8d5ff94
  #
  directory 'C:\CrlCopy'

  cookbook_file 'C:\CrlCopy\crl_copy_v3.ps1' do
    source 'crl_copy_v3.ps1'
  end

  crl_paths = [win_friendly_path(new_resource.master_crl)]
  crl_paths << win_friendly_path(new_resource.master_crl.split('.')[0] + '+.' + new_resource.master_crl.split('.')[1]) if new_resource.has_delta_crl

  crl_paths.each do |crl_path|
    crl_file = ::File.basename(crl_path.tr('\\', '/'))
    crl_dir  = crl_path.gsub(crl_file, '')

    outfile = new_resource.outfile
    outfile = 'C:\CrlCopy' + "\\#{::File.basename(crl_file, ::File.extname(crl_file))}_CRL_Status.htm" if outfile.nil?
    outfile = [outfile] unless outfile.is_a?(Array)

    smtp_to = new_resource.smtp_to
    smtp_to = [smtp_to] unless smtp_to.is_a?(Array)

    template "C:\\CrlCopy\\#{::File.basename(crl_file, ::File.extname(crl_file))}_CRL_Config.xml" do
      source 'CRL_Config.XML.erb'
      variables(
        cdps: new_resource.cdps,
        cluster_name: new_resource.cluster_name,
        crl_file: crl_file,
        crl_dir: crl_dir,
        eventvwr_event_high: eventvwr_event_high,
        eventvwr_event_id: new_resource.eventvwr_event_id,
        eventvwr_event_information: new_resource.eventvwr_event_information,
        eventvwr_event_source: new_resource.eventvwr_event_source,
        eventvwr_event_warning: new_resource.eventvwr_event_warning,
        outfile: outfile,
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
      command "%SystemRoot%\\system32\\WindowsPowerShell\\v1.0\\powershell.exe C:\\CrlCopy\\crl_copy_v3.ps1 -Action Publish -XmlFile 'C:\\CrlCopy\\#{::File.basename(crl_file, ::File.extname(crl_file))}_CRL_Config.xml'"
      run_level :highest
      frequency new_resource.windows_task_frequency.downcase.to_sym
      frequency_modifier new_resource.windows_task_frequency_modifier.to_i
    end
  end
end

action :delete do
end
