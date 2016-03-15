#
# Cookbook Name:: crl_copy
# Spec:: default
#
# Copyright (C) 2016 Schuberg Philis
#
# Created by: Stephen Hoekstra <shoekstra@schubergphilis.com>
#

require 'spec_helper'

describe 'crl_copy::default' do
  describe 'when all attributes are default' do
    cached(:chef_run) do
      ChefSpec::SoloRunner.new(file_cache_path: '/Chef/cache').converge(described_recipe)
    end

    it 'should converge successfully' do
      expect { chef_run }.to_not raise_error
    end

    it 'installs the PSCX PowerShell module'do
      expect(chef_run).to create_remote_file('/Chef/cache/pscx.msi').with(
        source: 'http://download-codeplex.sec.s-msft.com/Download/Release?ProjectName=pscx&DownloadId=923562&FileTime=130585918034470000&Build=21031'
      )

      expect(chef_run).to install_package('PowerShell Community Extensions 3.2.0').with(
        source: '/Chef/cache/pscx.msi',
        installer_type: :msi
      )
    end

    it 'installs the PSPKI PowerShell module' do
      expect(chef_run).to create_remote_file('/Chef/cache/pspki.exe').with(
        source: 'http://download-codeplex.sec.s-msft.com/Download/Release?ProjectName=pspki&DownloadId=1440723&FileTime=130716062844400000&Build=21031'
      )

      expect(chef_run).to install_package('PowerShell PKI Module').with(
        source: '/Chef/cache/pspki.exe',
        installer_type: :custom,
        options: '/quiet'
      )
    end

    it 'should write warning' do
      expect(chef_run).to write_log('crl_copy::default: No master CRLs specified, skipping crl_copy resource.').with(level: :warn)
    end
  end

  describe "when specifying custom powershell module attributes" do
    let(:chef_run) do
      ChefSpec::SoloRunner.new(file_cache_path: '/Chef/cache') do |node|
        node.set['crl_copy']['pscx']['package_name']  = 'pscx package name'
        node.set['crl_copy']['pscx']['source_url']    = 'http://test'
        node.set['crl_copy']['pspki']['package_name'] = 'pspki package name'
        node.set['crl_copy']['pspki']['source_name']  = 'http://test'
      end.converge(described_recipe)
    end

    it 'converge successfully' do
      expect { chef_run }.to_not raise_error
    end

    it 'installs the PSCX PowerShell module'do
      expect(chef_run).to create_remote_file('/Chef/cache/pscx.msi').with(
        source: 'http://test'
      )

      expect(chef_run).to install_package('pscx package name').with(
        source: '/Chef/cache/pscx.msi',
        installer_type: :msi
      )
    end

    it 'installs the PSPKI PowerShell module' do
      expect(chef_run).to create_remote_file('/Chef/cache/pspki.exe').with(
        source: 'http://test'
      )

      expect(chef_run).to install_package('pspki package name').with(
        source: '/Chef/cache/pspki.exe',
        installer_type: :custom,
        options: '/quiet'
      )
    end
  end

  describe "when specifying one CRL in the ['crl_copy']['master_crl'] attribute with all resource attributes" do
    cached(:chef_run) do
      ChefSpec::SoloRunner.new(file_cache_path: '/Chef/cache', step_into: :crl_copy) do |node|
        node.set['crl_copy']['master_crls']['C:\Windows\System32\certsrv\CertEnroll\issuingca.crl'].tap do |master_crl|
          master_crl['cdps']['internal cdp1']['retrieval'] = 'www'
          master_crl['cdps']['internal cdp1']['retrieval_path'] = 'http://www.f.internal/pki/'
          master_crl['cdps']['internal cdp1']['push'] = 'true'
          master_crl['cdps']['internal cdp1']['push_method'] = 'file'
          master_crl['cdps']['internal cdp1']['push_path'] = '\\\\www.f.internal\pki\\'
          master_crl['cdps']['internal ldap']['retrieval'] = 'ldap'
          master_crl['cdps']['internal ldap']['retrieval_path'] = 'dc=f,dc=internal'
          master_crl['cdps']['internal ldap']['push'] = ''
          master_crl['cdps']['internal ldap']['push_method'] = ''
          master_crl['cdps']['internal ldap']['push_path'] = ''
          master_crl['cdps']['external cdp']['retrieval'] = 'www'
          master_crl['cdps']['external cdp']['retrieval_path'] = 'http://pki.g.internal/pki/'
          master_crl['cdps']['external cdp']['push'] = ''
          master_crl['cdps']['external cdp']['push_method'] = ''
          master_crl['cdps']['external cdp']['push_path'] = ''
          master_crl['eventvwr_event_source'] = 'CRL Copy Process'
          master_crl['eventvwr_event_id'] = 5000
          master_crl['eventvwr_event_high'] = 1
          master_crl['eventvwr_event_warning'] = 2
          master_crl['eventvwr_event_information'] = 4
          master_crl['outfile'] = ['c:\windows\system32\certsrv\certenroll\CRLCopy.htm', '\\\\www.f.internal\pki\CRLCopy.htm']
          master_crl['smtp_send_mail'] = true
          master_crl['smtp_server'] = 'exchange.f.internal'
          master_crl['smtp_from'] = 'crlcopy@f.internal'
          master_crl['smtp_to'] = ['pfox@f.internal', 'pierref@f.internal']
          master_crl['smtp_published_notify'] = true
          master_crl['smtp_title'] = 'CRL Copy Process Results'
          master_crl['smtp_threshold'] = 2
          master_crl['warnings_threshold'] = 5
          master_crl['warnings_threshold_unit'] = 'Hours'
        end
      end.converge(described_recipe)
    end

    it 'should converge successfully' do
      expect { chef_run }.to_not raise_error
    end

    it 'should not write warning' do
      expect(chef_run).to_not write_log('crl_copy::default: No master CRLs specified, skipping crl_copy resource.').with(level: :warn)
    end

    it 'should create a crl_copy[C:\Windows\System32\certsrv\CertEnroll\issuingca.crl] resource' do
      expect(chef_run).to create_crl_copy('C:\Windows\System32\certsrv\CertEnroll\issuingca.crl').with(
        'cdps' => {
          'internal cdp1' => {
            'retrieval'      => 'www',
            'retrieval_path' => 'http://www.f.internal/pki/',
            'push'           => 'true',
            'push_method'    => 'file',
            'push_path'      => '\\\\www.f.internal\pki\\'
          },
          'internal ldap' => {
            'retrieval'      => 'ldap',
            'retrieval_path' => 'dc=f,dc=internal',
            'push'           => '',
            'push_method'    => '',
            'push_path'      => ''
          },
          'external cdp' => {
            'retrieval'      => 'www',
            'retrieval_path' => 'http://pki.g.internal/pki/',
            'push'           => '',
            'push_method'    => '',
            'push_path'      => ''
          }
        },
        'eventvwr_event_source'      => 'CRL Copy Process',
        'eventvwr_event_id'          => 5000,
        'eventvwr_event_high'        => 1,
        'eventvwr_event_warning'     => 2,
        'eventvwr_event_information' => 4,
        'outfile'                    => ['c:\windows\system32\certsrv\certenroll\CRLCopy.htm', '\\\\www.f.internal\pki\CRLCopy.htm'],
        'smtp_send_mail'             => true,
        'smtp_server'                => 'exchange.f.internal',
        'smtp_from'                  => 'crlcopy@f.internal',
        'smtp_to'                    => ['pfox@f.internal', 'pierref@f.internal'],
        'smtp_published_notify'      => true,
        'smtp_title'                 => 'CRL Copy Process Results',
        'smtp_threshold'             => 2
      )
    end

    context 'it steps into crl_copy' do
      it 'creates directory C:\CrlCopy\issuingca directory' do
        expect(chef_run).to create_directory('C:\CrlCopy\issuingca')
      end

      it 'creates file C:\CrlCopy\issuingca\CRL_Copy.ps1' do
        expect(chef_run).to create_cookbook_file('C:\CrlCopy\issuingca\CRL_Copy.ps1')
      end

      it 'renders template C:\CrlCopy\issuingca\CRL_Config.XML' do
        expect(chef_run).to create_template('C:\CrlCopy\issuingca\CRL_Config.XML').with_variables(
          cdps: {
            'internal cdp1' => {
              'retrieval'      => 'www',
              'retrieval_path' => 'http://www.f.internal/pki/',
              'push'           => 'true',
              'push_method'    => 'file',
              'push_path'      => '\\\\www.f.internal\pki\\'
            },
            'internal ldap' => {
              'retrieval'      => 'ldap',
              'retrieval_path' => 'dc=f,dc=internal',
              'push'           => '',
              'push_method'    => '',
              'push_path'      => ''
            },
            'external cdp' => {
              'retrieval'      => 'www',
              'retrieval_path' => 'http://pki.g.internal/pki/',
              'push'           => '',
              'push_method'    => '',
              'push_path'      => ''
            }
          },
          cluster_name: nil,
          eventvwr_event_id: 5000,
          eventvwr_event_information: 4,
          eventvwr_event_high: 1,
          eventvwr_event_source: 'CRL Copy Process',
          eventvwr_event_warning: 2,
          outfile: ['c:\windows\system32\certsrv\certenroll\CRLCopy.htm', '\\\\www.f.internal\pki\CRLCopy.htm'],
          smtp_from: 'crlcopy@f.internal',
          smtp_published_notify: true,
          smtp_send_mail: true,
          smtp_server: 'exchange.f.internal',
          smtp_threshold: 2,
          smtp_title: 'CRL Copy Process Results',
          smtp_to: ['pfox@f.internal', 'pierref@f.internal'],
          warnings_threshold: 5,
          warnings_threshold_unit: 'Hours'
        )

        template_content = <<-EOF.gsub(/^ {10}/, '')
          <?xml version="1.0" encoding="US-ASCII"?>
          <configuration>
              <master_crl>
                  <name>issuingca.crl</name>
                  <retrieval>file</retrieval>
                  <path>C:\\Windows\\System32\\certsrv\\CertEnroll\\</path>
              </master_crl>

              <cdps>
                  <cdp>
                      <name>internal cdp1</name>
                      <retrieval>www</retrieval>
                      <retrieval_path>http://www.f.internal/pki/</retrieval_path>
                      <push>true</push>  <!-- no value for FALSE -->
                      <push_method>file</push_method>
                      <push_path>\\\\www.f.internal\\pki\\</push_path>
                  </cdp>

                  <cdp>
                      <name>internal ldap</name>
                      <retrieval>ldap</retrieval>
                      <retrieval_path>dc=f,dc=internal</retrieval_path>
                      <push></push>  <!-- no value for FALSE -->
                      <push_method></push_method>
                      <push_path></push_path>
                  </cdp>

                  <cdp>
                      <name>external cdp</name>
                      <retrieval>www</retrieval>
                      <retrieval_path>http://pki.g.internal/pki/</retrieval_path>
                      <push></push>  <!-- no value for FALSE -->
                      <push_method></push_method>
                      <push_path></push_path>
                  </cdp>
              </cdps>

              <SMTP>
                  <send_SMTP>true</send_SMTP> <!-- no value for FALSE -->
                  <SmtpServer>exchange.f.internal</SmtpServer>
                  <from>crlcopy@f.internal</from>
                  <to>pfox@f.internal,pierref@f.internal</to>
                  <published_notify>true</published_notify> <!-- no value for FALSE -->
                  <title>CRL Copy Process Results</title>
                  <SMTPThreshold>2</SMTPThreshold> <!-- event level when an SMTP message is sent -->
              </SMTP>

              <eventvwr>
                  <EventSource>CRL Copy Process</EventSource>
                  <EventID>5000</EventID>
                  <EventHigh>1</EventHigh>
                  <EventWarning>2</EventWarning>
                  <EventInformation>4</EventInformation>
              </eventvwr>

              <warnings>
                  <threshold>5</threshold>
                  <threshold_unit>Hours</threshold_unit> <!-- days, hours, minutes or seconds -->
              </warnings>

              <ADCS>
                  <cluster></cluster> <!-- no value for FALSE -->
              </ADCS>

              <output>
                  <outfile>c:\\windows\\system32\\certsrv\\certenroll\\CRLCopy.htm,\\\\www.f.internal\\pki\\CRLCopy.htm</outfile>
              </output>
          </configuration>
        EOF

        expect(chef_run).to render_file('C:\CrlCopy\issuingca\CRL_Config.XML').with_content(template_content)
      end
    end
  end

  describe "when specifying two CRLs in the ['crl_copy']['master_crl'] attribute with all resource attributes" do
    cached(:chef_run) do
      ChefSpec::SoloRunner.new(file_cache_path: '/Chef/cache') do |node|
        node.set['crl_copy']['master_crls']['C:\Windows\System32\certsrv\CertEnroll\issuingca1.crl'].tap do |master_crl|
          master_crl['cdps']['internal cdp1']['retrieval'] = 'www'
          master_crl['cdps']['internal cdp1']['retrieval_path'] = 'http://www.f.internal/pki/'
          master_crl['cdps']['internal cdp1']['push'] = 'true'
          master_crl['cdps']['internal cdp1']['push_method'] = 'file'
          master_crl['cdps']['internal cdp1']['push_path'] = '\\\\www.f.internal\pki\\'
          master_crl['cdps']['internal ldap']['retrieval'] = 'ldap'
          master_crl['cdps']['internal ldap']['retrieval_path'] = 'dc=f,dc=internal'
          master_crl['cdps']['internal ldap']['push'] = ''
          master_crl['cdps']['internal ldap']['push_method'] = ''
          master_crl['cdps']['internal ldap']['push_path'] = ''
          master_crl['cdps']['external cdp']['retrieval'] = 'www'
          master_crl['cdps']['external cdp']['retrieval_path'] = 'http://pki.g.internal/pki/'
          master_crl['cdps']['external cdp']['push'] = ''
          master_crl['cdps']['external cdp']['push_method'] = ''
          master_crl['cdps']['external cdp']['push_path'] = ''
          master_crl['eventvwr_event_source'] = 'CRL Copy Process'
          master_crl['eventvwr_event_id'] = 5000
          master_crl['eventvwr_event_high'] = 1
          master_crl['eventvwr_event_warning'] = 2
          master_crl['eventvwr_event_information'] = 4
          master_crl['outfile'] = ['c:\windows\system32\certsrv\certenroll\CRLCopy.htm', '\\\\www.f.internal\pki\CRLCopy.htm']
          master_crl['smtp_send_mail'] = true
          master_crl['smtp_server'] = 'exchange.f.internal'
          master_crl['smtp_from'] = 'crlcopy@f.internal'
          master_crl['smtp_to'] = ['pfox@f.internal', 'pierref@f.internal']
          master_crl['smtp_published_notify'] = true
          master_crl['smtp_title'] = 'CRL Copy Process Results'
          master_crl['smtp_threshold'] = 2
          master_crl['warnings_threshold'] = 5
          master_crl['warnings_threshold_unit'] = 'Hours'
        end
        node.set['crl_copy']['master_crls']['C:\Windows\System32\certsrv\CertEnroll\issuingca2.crl'].tap do |master_crl|
          master_crl['cdps']['internal cdp1']['retrieval'] = 'www'
          master_crl['cdps']['internal cdp1']['retrieval_path'] = 'http://www.f.internal/pki/'
          master_crl['cdps']['internal cdp1']['push'] = 'true'
          master_crl['cdps']['internal cdp1']['push_method'] = 'file'
          master_crl['cdps']['internal cdp1']['push_path'] = '\\\\www.f.internal\pki\\'
          master_crl['cdps']['internal ldap']['retrieval'] = 'ldap'
          master_crl['cdps']['internal ldap']['retrieval_path'] = 'dc=f,dc=internal'
          master_crl['cdps']['internal ldap']['push'] = ''
          master_crl['cdps']['internal ldap']['push_method'] = ''
          master_crl['cdps']['internal ldap']['push_path'] = ''
          master_crl['cdps']['external cdp']['retrieval'] = 'www'
          master_crl['cdps']['external cdp']['retrieval_path'] = 'http://pki.g.internal/pki/'
          master_crl['cdps']['external cdp']['push'] = ''
          master_crl['cdps']['external cdp']['push_method'] = ''
          master_crl['cdps']['external cdp']['push_path'] = ''
          master_crl['eventvwr_event_source'] = 'CRL Copy Process'
          master_crl['eventvwr_event_id'] = 5000
          master_crl['eventvwr_event_high'] = 1
          master_crl['eventvwr_event_warning'] = 2
          master_crl['eventvwr_event_information'] = 4
          master_crl['outfile'] = ['c:\windows\system32\certsrv\certenroll\CRLCopy.htm', '\\\\www.f.internal\pki\CRLCopy.htm']
          master_crl['smtp_send_mail'] = true
          master_crl['smtp_server'] = 'exchange.f.internal'
          master_crl['smtp_from'] = 'crlcopy@f.internal'
          master_crl['smtp_to'] = ['pfox@f.internal', 'pierref@f.internal']
          master_crl['smtp_published_notify'] = true
          master_crl['smtp_title'] = 'CRL Copy Process Results'
          master_crl['smtp_threshold'] = 2
          master_crl['warnings_threshold'] = 5
          master_crl['warnings_threshold_unit'] = 'Hours'
        end
      end.converge(described_recipe)
    end

    it 'should create a crl_copy[C:\Windows\System32\certsrv\CertEnroll\issuingca1.crl] resource' do
      expect(chef_run).to create_crl_copy('C:\Windows\System32\certsrv\CertEnroll\issuingca1.crl').with(
        'cdps' => {
          'internal cdp1' => {
            'retrieval'      => 'www',
            'retrieval_path' => 'http://www.f.internal/pki/',
            'push'           => 'true',
            'push_method'    => 'file',
            'push_path'      => '\\\\www.f.internal\pki\\'
          },
          'internal ldap' => {
            'retrieval'      => 'ldap',
            'retrieval_path' => 'dc=f,dc=internal',
            'push'           => '',
            'push_method'    => '',
            'push_path'      => ''
          },
          'external cdp' => {
            'retrieval'      => 'www',
            'retrieval_path' => 'http://pki.g.internal/pki/',
            'push'           => '',
            'push_method'    => '',
            'push_path'      => ''
          }
        },
        'eventvwr_event_source'      => 'CRL Copy Process',
        'eventvwr_event_id'          => 5000,
        'eventvwr_event_high'        => 1,
        'eventvwr_event_warning'     => 2,
        'eventvwr_event_information' => 4,
        'outfile'                    => ['c:\windows\system32\certsrv\certenroll\CRLCopy.htm', '\\\\www.f.internal\pki\CRLCopy.htm'],
        'smtp_send_mail'             => true,
        'smtp_server'                => 'exchange.f.internal',
        'smtp_from'                  => 'crlcopy@f.internal',
        'smtp_to'                    => ['pfox@f.internal', 'pierref@f.internal'],
        'smtp_published_notify'      => true,
        'smtp_title'                 => 'CRL Copy Process Results',
        'smtp_threshold'             => 2
      )
    end

    it 'should create a crl_copy[C:\Windows\System32\certsrv\CertEnroll\issuingca2.crl] resource' do
      expect(chef_run).to create_crl_copy('C:\Windows\System32\certsrv\CertEnroll\issuingca2.crl').with(
        'cdps' => {
          'internal cdp1' => {
            'retrieval'      => 'www',
            'retrieval_path' => 'http://www.f.internal/pki/',
            'push'           => 'true',
            'push_method'    => 'file',
            'push_path'      => '\\\\www.f.internal\pki\\'
          },
          'internal ldap' => {
            'retrieval'      => 'ldap',
            'retrieval_path' => 'dc=f,dc=internal',
            'push'           => '',
            'push_method'    => '',
            'push_path'      => ''
          },
          'external cdp' => {
            'retrieval'      => 'www',
            'retrieval_path' => 'http://pki.g.internal/pki/',
            'push'           => '',
            'push_method'    => '',
            'push_path'      => ''
          }
        },
        'eventvwr_event_source'      => 'CRL Copy Process',
        'eventvwr_event_id'          => 5000,
        'eventvwr_event_high'        => 1,
        'eventvwr_event_warning'     => 2,
        'eventvwr_event_information' => 4,
        'outfile'                    => ['c:\windows\system32\certsrv\certenroll\CRLCopy.htm', '\\\\www.f.internal\pki\CRLCopy.htm'],
        'smtp_send_mail'             => true,
        'smtp_server' => 'exchange.f.internal',
        'smtp_from'                  => 'crlcopy@f.internal',
        'smtp_to'                    => ['pfox@f.internal', 'pierref@f.internal'],
        'smtp_published_notify'      => true,
        'smtp_title'                 => 'CRL Copy Process Results',
        'smtp_threshold' => 2
      )
    end
  end

  describe 'when using cookbook attributes as resource defaults' do
    describe "when specifying one CDP in the ['crl_copy']['master_crl'] attribute" do
      cached(:chef_run) do
        ChefSpec::SoloRunner.new(file_cache_path: '/Chef/cache', step_into: :crl_copy) do |node|
          node.set['crl_copy']['eventvwr']['event_source']      = 'CRL Copy Process'
          node.set['crl_copy']['eventvwr']['event_id']          = 5000
          node.set['crl_copy']['eventvwr']['event_high']        = 1
          node.set['crl_copy']['eventvwr']['event_warning']     = 2
          node.set['crl_copy']['eventvwr']['event_information'] = 4
          node.set['crl_copy']['smtp']['send_mail']             = true
          node.set['crl_copy']['smtp']['server']                = 'exchange.f.internal'
          node.set['crl_copy']['smtp']['from']                  = 'crlcopy@f.internal'
          node.set['crl_copy']['smtp']['to']                    = ['pfox@f.internal', 'pierref@f.internal']
          node.set['crl_copy']['smtp']['published_notify']      = true
          node.set['crl_copy']['smtp']['title']                 = 'CRL Copy Process Results'
          node.set['crl_copy']['smtp']['threshold']             = 2
          node.set['crl_copy']['warnings']['threshold']         = 5
          node.set['crl_copy']['warnings']['threshold_unit']    = 'Hours' # days, hours, minutes or seconds

          node.set['crl_copy']['master_crls']['C:\Windows\System32\certsrv\CertEnroll\issuingca.crl'].tap do |master_crl|
            master_crl['cdps']['internal cdp1']['retrieval'] = 'www'
            master_crl['cdps']['internal cdp1']['retrieval_path'] = 'http://www.f.internal/pki/'
            master_crl['cdps']['internal cdp1']['push'] = 'true'
            master_crl['cdps']['internal cdp1']['push_method'] = 'file'
            master_crl['cdps']['internal cdp1']['push_path'] = '\\\\www.f.internal\pki\\'
            master_crl['outfile'] = ['c:\windows\system32\certsrv\certenroll\CRLCopy.htm', '\\\\www.f.internal\pki\CRLCopy.htm']
          end
        end.converge(described_recipe)
      end

      it 'should converge successfully' do
        expect { chef_run }.to_not raise_error
      end

      it 'should not write warning' do
        expect(chef_run).to_not write_log('crl_copy::default: No master CRLs specified, skipping crl_copy resource.').with(level: :warn)
      end

      it 'should create a crl_copy[C:\Windows\System32\certsrv\CertEnroll\issuingca.crl] resource' do
        expect(chef_run).to create_crl_copy('C:\Windows\System32\certsrv\CertEnroll\issuingca.crl').with(
          cdps: {
            'internal cdp1' => {
              'retrieval'      => 'www',
              'retrieval_path' => 'http://www.f.internal/pki/',
              'push'           => 'true',
              'push_method'    => 'file',
              'push_path'      => '\\\\www.f.internal\pki\\'
            }
          },
          'outfile' => ['c:\windows\system32\certsrv\certenroll\CRLCopy.htm', '\\\\www.f.internal\pki\CRLCopy.htm']
        )
      end

      context 'it steps into crl_copy' do
        it 'creates directory C:\CrlCopy\issuingca directory' do
          expect(chef_run).to create_directory('C:\CrlCopy\issuingca')
        end

        it 'creates file C:\CrlCopy\issuingca\CRL_Copy.ps1' do
          expect(chef_run).to create_cookbook_file('C:\CrlCopy\issuingca\CRL_Copy.ps1')
        end

        it 'renders template C:\CrlCopy\issuingca\CRL_Config.XML' do
          expect(chef_run).to create_template('C:\CrlCopy\issuingca\CRL_Config.XML').with_variables(
            cdps: {
              'internal cdp1' => {
                'retrieval'      => 'www',
                'retrieval_path' => 'http://www.f.internal/pki/',
                'push'           => 'true',
                'push_method'    => 'file',
                'push_path'      => '\\\\www.f.internal\pki\\'
              }
            },
            cluster_name: nil,
            eventvwr_event_high: 1,
            eventvwr_event_id: 5000,
            eventvwr_event_information: 4,
            eventvwr_event_source: 'CRL Copy Process',
            eventvwr_event_warning: 2,
            outfile: ['c:\windows\system32\certsrv\certenroll\CRLCopy.htm', '\\\\www.f.internal\pki\CRLCopy.htm'],
            smtp_from: 'crlcopy@f.internal',
            smtp_published_notify: true,
            smtp_send_mail: true,
            smtp_server: 'exchange.f.internal',
            smtp_threshold: 2,
            smtp_title: 'CRL Copy Process Results',
            smtp_to: ['pfox@f.internal', 'pierref@f.internal'],
            warnings_threshold: 5,
            warnings_threshold_unit: 'Hours'
          )

          template_content = <<-EOF.gsub(/^ {12}/, '')
            <?xml version="1.0" encoding="US-ASCII"?>
            <configuration>
                <master_crl>
                    <name>issuingca.crl</name>
                    <retrieval>file</retrieval>
                    <path>C:\\Windows\\System32\\certsrv\\CertEnroll\\</path>
                </master_crl>

                <cdps>
                    <cdp>
                        <name>internal cdp1</name>
                        <retrieval>www</retrieval>
                        <retrieval_path>http://www.f.internal/pki/</retrieval_path>
                        <push>true</push>  <!-- no value for FALSE -->
                        <push_method>file</push_method>
                        <push_path>\\\\www.f.internal\\pki\\</push_path>
                    </cdp>
                </cdps>

                <SMTP>
                    <send_SMTP>true</send_SMTP> <!-- no value for FALSE -->
                    <SmtpServer>exchange.f.internal</SmtpServer>
                    <from>crlcopy@f.internal</from>
                    <to>pfox@f.internal,pierref@f.internal</to>
                    <published_notify>true</published_notify> <!-- no value for FALSE -->
                    <title>CRL Copy Process Results</title>
                    <SMTPThreshold>2</SMTPThreshold> <!-- event level when an SMTP message is sent -->
                </SMTP>

                <eventvwr>
                    <EventSource>CRL Copy Process</EventSource>
                    <EventID>5000</EventID>
                    <EventHigh>1</EventHigh>
                    <EventWarning>2</EventWarning>
                    <EventInformation>4</EventInformation>
                </eventvwr>

                <warnings>
                    <threshold>5</threshold>
                    <threshold_unit>Hours</threshold_unit> <!-- days, hours, minutes or seconds -->
                </warnings>

                <ADCS>
                    <cluster></cluster> <!-- no value for FALSE -->
                </ADCS>

                <output>
                    <outfile>c:\\windows\\system32\\certsrv\\certenroll\\CRLCopy.htm,\\\\www.f.internal\\pki\\CRLCopy.htm</outfile>
                </output>
            </configuration>
          EOF

          expect(chef_run).to render_file('C:\CrlCopy\issuingca\CRL_Config.XML').with_content(template_content)
        end
      end
    end

    describe "when specifying three CDPs in the ['crl_copy']['master_crl'] attribute" do
      cached(:chef_run) do
        ChefSpec::SoloRunner.new(file_cache_path: '/Chef/cache', step_into: :crl_copy) do |node|
          node.set['crl_copy']['eventvwr']['event_source']      = 'CRL Copy Process'
          node.set['crl_copy']['eventvwr']['event_id']          = 5000
          node.set['crl_copy']['eventvwr']['event_high']        = 1
          node.set['crl_copy']['eventvwr']['event_warning']     = 2
          node.set['crl_copy']['eventvwr']['event_information'] = 4
          node.set['crl_copy']['smtp']['send_mail']             = true
          node.set['crl_copy']['smtp']['server']                = 'exchange.f.internal'
          node.set['crl_copy']['smtp']['from']                  = 'crlcopy@f.internal'
          node.set['crl_copy']['smtp']['to']                    = ['pfox@f.internal', 'pierref@f.internal']
          node.set['crl_copy']['smtp']['published_notify']      = true
          node.set['crl_copy']['smtp']['title']                 = 'CRL Copy Process Results'
          node.set['crl_copy']['smtp']['threshold']             = 2
          node.set['crl_copy']['warnings']['threshold']         = 5
          node.set['crl_copy']['warnings']['threshold_unit']    = 'Hours' # days, hours, minutes or seconds

          node.set['crl_copy']['master_crls']['C:\Windows\System32\certsrv\CertEnroll\issuingca.crl'].tap do |master_crl|
            master_crl['cdps']['internal cdp1']['retrieval'] = 'www'
            master_crl['cdps']['internal cdp1']['retrieval_path'] = 'http://www.f.internal/pki/'
            master_crl['cdps']['internal cdp1']['push'] = 'true'
            master_crl['cdps']['internal cdp1']['push_method'] = 'file'
            master_crl['cdps']['internal cdp1']['push_path'] = '\\\\www.f.internal\pki\\'
            master_crl['cdps']['internal ldap']['retrieval'] = 'ldap'
            master_crl['cdps']['internal ldap']['retrieval_path'] = 'dc=f,dc=internal'
            master_crl['cdps']['internal ldap']['push'] = ''
            master_crl['cdps']['internal ldap']['push_method'] = ''
            master_crl['cdps']['internal ldap']['push_path'] = ''
            master_crl['cdps']['external cdp']['retrieval'] = 'www'
            master_crl['cdps']['external cdp']['retrieval_path'] = 'http://pki.g.internal/pki/'
            master_crl['cdps']['external cdp']['push'] = ''
            master_crl['cdps']['external cdp']['push_method'] = ''
            master_crl['cdps']['external cdp']['push_path'] = ''
            master_crl['outfile'] = ['c:\windows\system32\certsrv\certenroll\CRLCopy.htm', '\\\\www.f.internal\pki\CRLCopy.htm']
          end
        end.converge(described_recipe)
      end

      it 'should create a crl_copy[C:\Windows\System32\certsrv\CertEnroll\issuingca.crl] resource' do
        expect(chef_run).to create_crl_copy('C:\Windows\System32\certsrv\CertEnroll\issuingca.crl').with(
          'cdps' => {
            'internal cdp1' => {
              'retrieval'      => 'www',
              'retrieval_path' => 'http://www.f.internal/pki/',
              'push'           => 'true',
              'push_method'    => 'file',
              'push_path'      => '\\\\www.f.internal\pki\\'
            },
            'internal ldap' => {
              'retrieval'      => 'ldap',
              'retrieval_path' => 'dc=f,dc=internal',
              'push'           => '',
              'push_method'    => '',
              'push_path'      => ''
            },
            'external cdp' => {
              'retrieval'      => 'www',
              'retrieval_path' => 'http://pki.g.internal/pki/',
              'push'           => '',
              'push_method'    => '',
              'push_path'      => ''
            }
          },
        )
      end

      context 'it steps into crl_copy' do
        it 'renders template C:\CrlCopy\issuingca\CRL_Config.XML' do
          expect(chef_run).to create_template('C:\CrlCopy\issuingca\CRL_Config.XML').with_variables(
            cdps: {
              'internal cdp1' => {
                'retrieval'      => 'www',
                'retrieval_path' => 'http://www.f.internal/pki/',
                'push'           => 'true',
                'push_method'    => 'file',
                'push_path'      => '\\\\www.f.internal\pki\\'
              },
              'internal ldap' => {
                'retrieval'      => 'ldap',
                'retrieval_path' => 'dc=f,dc=internal',
                'push'           => '',
                'push_method'    => '',
                'push_path'      => ''
              },
              'external cdp' => {
                'retrieval'      => 'www',
                'retrieval_path' => 'http://pki.g.internal/pki/',
                'push'           => '',
                'push_method'    => '',
                'push_path'      => ''
              }
            },
            cluster_name: nil,
            eventvwr_event_high: 1,
            eventvwr_event_id: 5000,
            eventvwr_event_information: 4,
            eventvwr_event_source: 'CRL Copy Process',
            eventvwr_event_warning: 2,
            outfile: ['c:\windows\system32\certsrv\certenroll\CRLCopy.htm', '\\\\www.f.internal\pki\CRLCopy.htm'],
            smtp_from: 'crlcopy@f.internal',
            smtp_published_notify: true,
            smtp_send_mail: true,
            smtp_server: 'exchange.f.internal',
            smtp_threshold: 2,
            smtp_title: 'CRL Copy Process Results',
            smtp_to: ['pfox@f.internal', 'pierref@f.internal'],
            warnings_threshold: 5,
            warnings_threshold_unit: 'Hours'
          )

          template_content = <<-EOF.gsub(/^ {8}/, '')
            <cdps>
                <cdp>
                    <name>internal cdp1</name>
                    <retrieval>www</retrieval>
                    <retrieval_path>http://www.f.internal/pki/</retrieval_path>
                    <push>true</push>  <!-- no value for FALSE -->
                    <push_method>file</push_method>
                    <push_path>\\\\www.f.internal\\pki\\</push_path>
                </cdp>

                <cdp>
                    <name>internal ldap</name>
                    <retrieval>ldap</retrieval>
                    <retrieval_path>dc=f,dc=internal</retrieval_path>
                    <push></push>  <!-- no value for FALSE -->
                    <push_method></push_method>
                    <push_path></push_path>
                </cdp>

                <cdp>
                    <name>external cdp</name>
                    <retrieval>www</retrieval>
                    <retrieval_path>http://pki.g.internal/pki/</retrieval_path>
                    <push></push>  <!-- no value for FALSE -->
                    <push_method></push_method>
                    <push_path></push_path>
                </cdp>
            </cdps>
          EOF

          expect(chef_run).to render_file('C:\CrlCopy\issuingca\CRL_Config.XML').with_content(template_content)
        end
      end
    end

    describe "when specifying one CDP with \"push = false\" in the ['crl_copy']['master_crl'] attribute" do
      cached(:chef_run) do
        ChefSpec::SoloRunner.new(file_cache_path: '/Chef/cache', step_into: :crl_copy) do |node|
          node.set['crl_copy']['eventvwr']['event_source']      = 'CRL Copy Process'
          node.set['crl_copy']['eventvwr']['event_id']          = 5000
          node.set['crl_copy']['eventvwr']['event_high']        = 1
          node.set['crl_copy']['eventvwr']['event_warning']     = 2
          node.set['crl_copy']['eventvwr']['event_information'] = 4
          node.set['crl_copy']['smtp']['send_mail']             = true
          node.set['crl_copy']['smtp']['server']                = 'exchange.f.internal'
          node.set['crl_copy']['smtp']['from']                  = 'crlcopy@f.internal'
          node.set['crl_copy']['smtp']['to']                    = ['pfox@f.internal', 'pierref@f.internal']
          node.set['crl_copy']['smtp']['published_notify']      = true
          node.set['crl_copy']['smtp']['title']                 = 'CRL Copy Process Results'
          node.set['crl_copy']['smtp']['threshold']             = 2
          node.set['crl_copy']['warnings']['threshold']         = 5
          node.set['crl_copy']['warnings']['threshold_unit']    = 'Hours' # days, hours, minutes or seconds

          node.set['crl_copy']['master_crls']['C:\Windows\System32\certsrv\CertEnroll\issuingca.crl']['cdps']['internal cdp1']['retrieval'] = 'www'
          node.set['crl_copy']['master_crls']['C:\Windows\System32\certsrv\CertEnroll\issuingca.crl']['cdps']['internal cdp1']['retrieval_path'] = 'http://www.f.internal/pki/'
          node.set['crl_copy']['master_crls']['C:\Windows\System32\certsrv\CertEnroll\issuingca.crl']['cdps']['internal cdp1']['push'] = 'false'
          node.set['crl_copy']['master_crls']['C:\Windows\System32\certsrv\CertEnroll\issuingca.crl']['cdps']['internal cdp1']['push_method'] = 'file'
          node.set['crl_copy']['master_crls']['C:\Windows\System32\certsrv\CertEnroll\issuingca.crl']['cdps']['internal cdp1']['push_path'] = '\\\\www.f.internal\pki\\'
          node.set['crl_copy']['master_crls']['C:\Windows\System32\certsrv\CertEnroll\issuingca.crl']['outfile'] = ['c:\windows\system32\certsrv\certenroll\CRLCopy.htm', '\\\\www.f.internal\pki\CRLCopy.htm']
        end.converge(described_recipe)
      end

      it 'should create a crl_copy[C:\Windows\System32\certsrv\CertEnroll\issuingca.crl] resource' do
        expect(chef_run).to create_crl_copy('C:\Windows\System32\certsrv\CertEnroll\issuingca.crl').with(
          cdps: {
            'internal cdp1' => {
              'retrieval'      => 'www',
              'retrieval_path' => 'http://www.f.internal/pki/',
              'push'           => 'false',
              'push_method'    => 'file',
              'push_path'      => '\\\\www.f.internal\pki\\'
            },
          },
        )
      end

      context 'it steps into crl_copy' do
        it 'renders template C:\CrlCopy\issuingca\CRL_Config.XML' do
          expect(chef_run).to create_template('C:\CrlCopy\issuingca\CRL_Config.XML').with_variables(
            cdps: {
              'internal cdp1' => {
                'retrieval'      => 'www',
                'retrieval_path' => 'http://www.f.internal/pki/',
                'push'           => 'false',
                'push_method'    => 'file',
                'push_path'      => '\\\\www.f.internal\pki\\'
              },
            },
            cluster_name: nil,
            eventvwr_event_high: 1,
            eventvwr_event_id: 5000,
            eventvwr_event_information: 4,
            eventvwr_event_source: 'CRL Copy Process',
            eventvwr_event_warning: 2,
            outfile: ['c:\windows\system32\certsrv\certenroll\CRLCopy.htm', '\\\\www.f.internal\pki\CRLCopy.htm'],
            smtp_from: 'crlcopy@f.internal',
            smtp_published_notify: true,
            smtp_send_mail: true,
            smtp_server: 'exchange.f.internal',
            smtp_threshold: 2,
            smtp_title: 'CRL Copy Process Results',
            smtp_to: ['pfox@f.internal', 'pierref@f.internal'],
            warnings_threshold: 5,
            warnings_threshold_unit: 'Hours'
          )

          template_content = <<-EOF.gsub(/^ {8}/, '')
            <cdps>
                <cdp>
                    <name>internal cdp1</name>
                    <retrieval>www</retrieval>
                    <retrieval_path>http://www.f.internal/pki/</retrieval_path>
                    <push></push>  <!-- no value for FALSE -->
                    <push_method>file</push_method>
                    <push_path>\\\\www.f.internal\\pki\\</push_path>
                </cdp>
            </cdps>
          EOF

          expect(chef_run).to render_file('C:\CrlCopy\issuingca\CRL_Config.XML').with_content(template_content)
        end
      end
    end

    describe "when ['crl_copy']['smtp']['published_notify'] and ['crl_copy']['smtp']['send_mail'] attributes are false" do
      cached(:chef_run) do
        ChefSpec::SoloRunner.new(file_cache_path: '/Chef/cache', step_into: :crl_copy) do |node|
          node.set['crl_copy']['eventvwr']['event_source']      = 'CRL Copy Process'
          node.set['crl_copy']['eventvwr']['event_id']          = 5000
          node.set['crl_copy']['eventvwr']['event_high']        = 1
          node.set['crl_copy']['eventvwr']['event_warning']     = 2
          node.set['crl_copy']['eventvwr']['event_information'] = 4
          node.set['crl_copy']['smtp']['send_mail']             = false
          node.set['crl_copy']['smtp']['server']                = 'exchange.f.internal'
          node.set['crl_copy']['smtp']['from']                  = 'crlcopy@f.internal'
          node.set['crl_copy']['smtp']['to']                    = ['pfox@f.internal', 'pierref@f.internal']
          node.set['crl_copy']['smtp']['published_notify']      = false
          node.set['crl_copy']['smtp']['title']                 = 'CRL Copy Process Results'
          node.set['crl_copy']['smtp']['threshold']             = 2
          node.set['crl_copy']['warnings']['threshold']         = 5
          node.set['crl_copy']['warnings']['threshold_unit']    = 'Hours' # days, hours, minutes or seconds

          node.set['crl_copy']['master_crls'] = {
            'C:\Windows\System32\certsrv\CertEnroll\issuingca.crl' => {}
          }
        end.converge(described_recipe)
      end

      it 'should create a crl_copy[C:\Windows\System32\certsrv\CertEnroll\issuingca.crl] resource' do
        expect(chef_run).to create_crl_copy('C:\Windows\System32\certsrv\CertEnroll\issuingca.crl')
      end

      context 'it steps into crl_copy' do
        it 'renders template C:\CrlCopy\issuingca\CRL_Config.XML' do
          expect(chef_run).to create_template('C:\CrlCopy\issuingca\CRL_Config.XML').with_variables(
            cdps: nil,
            cluster_name: nil,
            eventvwr_event_high: 1,
            eventvwr_event_id: 5000,
            eventvwr_event_information: 4,
            eventvwr_event_source: 'CRL Copy Process',
            eventvwr_event_warning: 2,
            outfile: [nil],
            smtp_from: 'crlcopy@f.internal',
            smtp_published_notify: false,
            smtp_send_mail: false,
            smtp_server: 'exchange.f.internal',
            smtp_threshold: 2,
            smtp_title: 'CRL Copy Process Results',
            smtp_to: ['pfox@f.internal', 'pierref@f.internal'],
            warnings_threshold: 5,
            warnings_threshold_unit: 'Hours'
          )

          template_content = <<-EOF.gsub(/^ {8}/, '')
            <SMTP>
                <send_SMTP></send_SMTP> <!-- no value for FALSE -->
                <SmtpServer>exchange.f.internal</SmtpServer>
                <from>crlcopy@f.internal</from>
                <to>pfox@f.internal,pierref@f.internal</to>
                <published_notify></published_notify> <!-- no value for FALSE -->
                <title>CRL Copy Process Results</title>
                <SMTPThreshold>2</SMTPThreshold> <!-- event level when an SMTP message is sent -->
            </SMTP>
          EOF

          expect(chef_run).to render_file('C:\CrlCopy\issuingca\CRL_Config.XML').with_content(template_content)
        end
      end
    end
  end
end
