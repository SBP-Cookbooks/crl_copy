name             'crl_copy'
maintainer       'Schuberg Philis'
maintainer_email 'cookbooks@schubergphilis.com'
license          'Apache-2.0'
version          '0.1.0'
description      'Installs and configures the CRL Copy PowerShell script from Script Center'
long_description IO.read(File.join(File.dirname(__FILE__), 'README.md'))
issues_url       'https://github.com/SBP-Cookbooks/crl_copy/issues'
source_url       'https://github.com/SBP-Cookbooks/crl_copy'
chef_version     '>= 14'

supports 'windows'

depends 'pspki', '~> 0.2.0'
