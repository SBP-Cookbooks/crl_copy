name             'crl_copy'
maintainer       'Stephen Hoekstra'
maintainer_email 'shoekstra@schubergphilis.com'
license          'All rights reserved'
description      'Chef cookbook to installand configure the CRL Copy PS script from Script Center'
version          '0.1.0'
source_url       'https://github.com/shoekstra/chef-crl_copy' if respond_to?(:source_url)
issues_url       'https://github.com/shoekstra/chef-crl_copy/issues' if respond_to?(:issues_url)

recipe           'crl_copy::default', 'Installs and configures script and scheduled task to manage CRL distribution.'

supports         'windows'
