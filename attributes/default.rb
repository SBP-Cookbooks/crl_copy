#
# Cookbook Name:: crl_copy
# Attributes:: default
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
