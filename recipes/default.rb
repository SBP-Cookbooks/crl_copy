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
  options '/quiet'
end

log 'crl_copy::default: No master CRLs specified, skipping crl_copy resource.' do
  level :warn
  not_if { node['crl_copy']['master_crls'] }
end

if node['crl_copy']['master_crls']
  master_crls = node['crl_copy']['master_crls']
  master_crls = [master_crls] unless master_crls.is_a?(Array)

  master_crls.each do |master_crl|
    master_crl.each do |config|
      crl_copy config.first do
        cdps config.last['cdps']
        cluster_name config.last['cluster_name'] if config.last['cluster_name']
        eventvwr_event_high config.last['eventvwr_event_high'] if config.last['eventvwr_event_high']
        eventvwr_event_id config.last['eventvwr_event_id'] if config.last['eventvwr_event_id']
        eventvwr_event_information config.last['eventvwr_event_information'] if config.last['eventvwr_event_information']
        eventvwr_event_source config.last['eventvwr_event_source'] if config.last['eventvwr_event_source']
        eventvwr_event_warning config.last['eventvwr_event_warning'] if config.last['eventvwr_event_warning']
        outfile config.last['outfile'] if config.last['outfile']
        smtp_from config.last['smtp_from'] if config.last['smtp_from']
        smtp_published_notify config.last['smtp_published_notify'] if config.last['smtp_published_notify']
        smtp_send_mail config.last['smtp_send_mail'] if config.last['smtp_send_mail']
        smtp_server config.last['smtp_server'] if config.last['smtp_server']
        smtp_threshold config.last['smtp_threshold'] if config.last['smtp_threshold']
        smtp_title config.last['smtp_title'] if config.last['smtp_title']
        smtp_to config.last['smtp_to'] if config.last['smtp_to']
        warnings_threshold config.last['warnings_threshold'] if config.last['warnings_threshold']
        warnings_threshold_unit config.last['warnings_threshold_unit'] if config.last['warnings_threshold_unit']
      end
    end
  end
end

#
# Include this cookbook's Nagios config/checks if 'nrpe' is in the run_list
#
include_recipe "#{cookbook_name}::_nrpe" if node.recipe?('nrpe')
