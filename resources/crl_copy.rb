#
# Cookbook Name:: crl_copy
# Resource:: crl_copy
#
# Copyright (C) 2016 Schuberg Philis
#
# Created by: Stephen Hoekstra <shoekstra@schubergphilis.com>
#

resource_name :crl_copy

actions :create, :delete
default_action :create

property :master_crl, kind_of: String, required: true, name_property: true
property :cdps, kind_of: [Array, Hash], required: true, default: nil
property :cluster_name, kind_of: String, required: false, default: nil
property :outfile, kind_of: [Array, String], required: false, default: nil

property :eventvwr_event_high, kind_of: [Fixnum, String], required: false, default: 1
property :eventvwr_event_id, kind_of: [Fixnum, String], required: false, default: 5000
property :eventvwr_event_information, kind_of: [Fixnum, String], required: false, default: 4
property :eventvwr_event_source, kind_of: String, required: false, default: 'CRL Copy Process'
property :eventvwr_event_warning, kind_of: [Fixnum, String], required: false, default: 2

property :smtp_from, kind_of: String, required: false, default: nil
property :smtp_published_notify, kind_of: [TrueClass, FalseClass], required: false, default: nil
property :smtp_send_mail, kind_of: [TrueClass, FalseClass], required: false, default: nil
property :smtp_server, kind_of: String, required: false, default: nil
property :smtp_threshold, kind_of: [Fixnum, String], required: false, default: 2
property :smtp_title, kind_of: String, required: false, default: 'CRL Copy Process Results'
property :smtp_to, kind_of: [Array, String], required: false, default: nil

property :warnings_threshold, kind_of: [Fixnum, String], required: false, default: 5
property :warnings_threshold_unit, kind_of: String, required: false, default: 'Hours', regex: /^(Days|Hours|Minutes|Seconds)$/i

action :create do
  #
  # Install and configure the CRL Copy script
  # https://gallery.technet.microsoft.com/scriptcenter/Powershell-CRL-Copy-v3-d8d5ff94
  #

  crl_path = new_resource.master_crl.tr('\\', '/')
  crl_file = ::File.basename(crl_path)
  crl_dir = 'C:\CrlCopy\\' + ::File.basename(crl_file, ::File.extname(crl_file))

  directory crl_dir

  cookbook_file "#{crl_dir}\\CRL_Copy.ps1" do
    source 'CRL_Copy.ps1'
  end

  cdps = new_resource.cdps
  cdps = [cdps] unless cdps.is_a?(Array)

  outfile = new_resource.outfile
  outfile = [outfile] unless outfile.is_a?(Array)

  smtp_from = new_resource.smtp_from
  smtp_from = node['crl_copy']['smtp']['from'] if smtp_from.nil?

  smtp_published_notify = new_resource.smtp_published_notify
  smtp_published_notify = node['crl_copy']['smtp']['published_notify'] if smtp_published_notify.nil?

  smtp_send_mail = new_resource.smtp_send_mail
  smtp_send_mail = node['crl_copy']['smtp']['send_mail'] if smtp_send_mail.nil?

  smtp_server = new_resource.smtp_server
  smtp_server = node['crl_copy']['smtp']['server'] if smtp_server.nil?

  smtp_title = new_resource.smtp_title
  smtp_title = node['crl_copy']['smtp']['title'] if smtp_title.nil?

  smtp_to = new_resource.smtp_to
  smtp_to = node['crl_copy']['smtp']['to'] if smtp_to.nil?
  smtp_to = [smtp_to] unless smtp_to.is_a?(Array)

  warnings_threshold_unit = new_resource.warnings_threshold_unit.downcase.capitalize

  template "#{crl_dir}\\CRL_Config.XML" do
    source 'CRL_Config.XML.erb'
    variables(
      cdps: cdps,
      cluster_name: new_resource.cluster_name,
      eventvwr_event_high: eventvwr_event_high,
      eventvwr_event_id: new_resource.eventvwr_event_id,
      eventvwr_event_information: new_resource.eventvwr_event_information,
      eventvwr_event_source: new_resource.eventvwr_event_source,
      eventvwr_event_warning: new_resource.eventvwr_event_warning,
      outfile: outfile,
      smtp_from: smtp_from,
      smtp_published_notify: smtp_published_notify,
      smtp_send_mail: smtp_send_mail,
      smtp_server: smtp_server,
      smtp_threshold: new_resource.smtp_threshold,
      smtp_title: smtp_title,
      smtp_to: smtp_to,
      warnings_threshold: new_resource.warnings_threshold,
      warnings_threshold_unit: warnings_threshold_unit
    )
  end
end

action :delete do
end
