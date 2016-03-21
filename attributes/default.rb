#
# Cookbook Name:: crl_copy
# Attributes:: default
#
# Copyright (C) 2016 Schuberg Philis
#
# Created by: Stephen Hoekstra <shoekstra@schubergphilis.com>
#

# CRL Copy default attributes, these can be overridden when using the LWRP.

default['crl_copy']['eventvwr']['event_source']      = 'CRL Copy Process'
default['crl_copy']['eventvwr']['event_id']          = 5000
default['crl_copy']['eventvwr']['event_high']        = 1
default['crl_copy']['eventvwr']['event_warning']     = 2
default['crl_copy']['eventvwr']['event_information'] = 4

default['crl_copy']['pscx']['package_name']          = 'PowerShell Community Extensions 3.2.0'
default['crl_copy']['pscx']['source_url']            = 'http://download-codeplex.sec.s-msft.com/Download/Release?ProjectName=pscx&DownloadId=923562&FileTime=130585918034470000&Build=21031'
default['crl_copy']['pspki']['package_name']         = 'PowerShell PKI Module'
default['crl_copy']['pspki']['source_name']          = 'http://download-codeplex.sec.s-msft.com/Download/Release?ProjectName=pspki&DownloadId=1440723&FileTime=130716062844400000&Build=21031'

default['crl_copy']['smtp']['send_mail']             = false
default['crl_copy']['smtp']['server']                = nil
default['crl_copy']['smtp']['from']                  = nil
default['crl_copy']['smtp']['to']                    = nil
default['crl_copy']['smtp']['published_notify']      = false
default['crl_copy']['smtp']['title']                 = 'CRL Copy Process Results'
default['crl_copy']['smtp']['threshold']             = 2

default['crl_copy']['warnings']['threshold']         = 5
default['crl_copy']['warnings']['threshold_unit']    = 'Hours'

default['crl_copy']['windows_task']['frequency']          = 'Minute'
default['crl_copy']['windows_task']['frequency_modifier'] = '30'
default['crl_copy']['windows_task']['password']           = nil
default['crl_copy']['windows_task']['user']               = 'SYSTEM'
