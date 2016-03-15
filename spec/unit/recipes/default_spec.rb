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

    it 'installs the PSCX PowerShell module with default values' do
      expect(chef_run).to create_remote_file('/Chef/cache/pscx.msi').with(
        source: 'http://download-codeplex.sec.s-msft.com/Download/Release?ProjectName=pscx&DownloadId=923562&FileTime=130585918034470000&Build=21031'
      )

      expect(chef_run).to install_package('PowerShell Community Extensions 3.2.0').with(
        source: '/Chef/cache/pscx.msi',
        installer_type: :msi
      )
    end

    it 'installs the PSPKI PowerShell module with default values' do
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

  describe "when specifying the ['crl_copy']['eventvwr'] attributes" do
    cached(:chef_run) do
      ChefSpec::SoloRunner.new(file_cache_path: '/Chef/cache', step_into: :crl_copy) do |node|
        node.set['crl_copy']['eventvwr']['event_source']      = 'CRL Copy Event'
        node.set['crl_copy']['eventvwr']['event_id']          = 6000
        node.set['crl_copy']['eventvwr']['event_high']        = 2
        node.set['crl_copy']['eventvwr']['event_warning']     = 4
        node.set['crl_copy']['eventvwr']['event_information'] = 8

        node.set['crl_copy']['master_crls']['C:\Windows\System32\certsrv\CertEnroll\issuingca1.crl'].tap do |master_crl|
          master_crl['cdps']['internal cdp1']['retrieval']      = 'www'
          master_crl['cdps']['internal cdp1']['retrieval_path'] = 'http://www.f.internal/pki/'
          master_crl['cdps']['internal cdp1']['push']           = 'true'
          master_crl['cdps']['internal cdp1']['push_method']    = 'file'
          master_crl['cdps']['internal cdp1']['push_path']      = '\\\\www.f.internal\pki\\'
        end
      end.converge(described_recipe)
    end

    it 'should converge successfully' do
      expect { chef_run }.to_not raise_error
    end

    it 'should not write warning' do
      expect(chef_run).to_not write_log('crl_copy::default: No master CRLs specified, skipping crl_copy resource.').with(level: :warn)
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
          }
        },
        'eventvwr_event_source'      => 'CRL Copy Event',
        'eventvwr_event_id'          => 6000,
        'eventvwr_event_high'        => 2,
        'eventvwr_event_warning'     => 4,
        'eventvwr_event_information' => 8,
        'smtp_send_mail'             => false,
        'smtp_server'                => nil,
        'smtp_from'                  => nil,
        'smtp_to'                    => nil,
        'smtp_published_notify'      => false,
        'smtp_title'                 => 'CRL Copy Process Results',
        'smtp_threshold'             => 2,
        'warnings_threshold'         => 5,
        'warnings_threshold_unit'    => 'Hours'
      )
    end

    context 'it steps into crl_copy[C:\Windows\System32\certsrv\CertEnroll\issuingca1.crl]' do
      it 'creates directory C:\CrlCopy\issuingca1 directory' do
        expect(chef_run).to create_directory('C:\CrlCopy\issuingca1')
      end

      it 'creates file C:\CrlCopy\issuingca1\CRL_Copy.ps1' do
        expect(chef_run).to create_cookbook_file('C:\CrlCopy\issuingca1\CRL_Copy.ps1')
      end

      it 'renders template C:\CrlCopy\issuingca1\CRL_Config.XML' do
        expect(chef_run).to create_template('C:\CrlCopy\issuingca1\CRL_Config.XML').with_variables(
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
          crl_file: 'issuingca1.crl',
          crl_dir: 'C:\Windows\System32\certsrv\CertEnroll\\',
          eventvwr_event_high: 2,
          eventvwr_event_id: 6000,
          eventvwr_event_information: 8,
          eventvwr_event_source: 'CRL Copy Event',
          eventvwr_event_warning: 4,
          outfile: ['C:\Windows\System32\certsrv\CertEnroll\CRLCopy.htm'],
          smtp_from: nil,
          smtp_published_notify: false,
          smtp_send_mail: false,
          smtp_server: nil,
          smtp_threshold: 2,
          smtp_title: 'CRL Copy Process Results',
          smtp_to: [nil],
          warnings_threshold: 5,
          warnings_threshold_unit: 'Hours'
        )

        template_content = <<-EOF.gsub(/^ {10}/, '')
          <?xml version="1.0" encoding="US-ASCII"?>
          <configuration>
              <master_crl>
                  <name>issuingca1.crl</name>
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
                  <send_SMTP></send_SMTP> <!-- no value for FALSE -->
                  <SmtpServer></SmtpServer>
                  <from></from>
                  <to></to>
                  <published_notify></published_notify> <!-- no value for FALSE -->
                  <title>CRL Copy Process Results</title>
                  <SMTPThreshold>2</SMTPThreshold> <!-- event level when an SMTP message is sent -->
              </SMTP>

              <eventvwr>
                  <EventSource>CRL Copy Event</EventSource>
                  <EventID>6000</EventID>
                  <EventHigh>2</EventHigh>
                  <EventWarning>4</EventWarning>
                  <EventInformation>8</EventInformation>
              </eventvwr>

              <warnings>
                  <threshold>5</threshold>
                  <threshold_unit>Hours</threshold_unit> <!-- days, hours, minutes or seconds -->
              </warnings>

              <ADCS>
                  <cluster></cluster> <!-- no value for FALSE -->
              </ADCS>

              <output>
                  <outfile>C:\\Windows\\System32\\certsrv\\CertEnroll\\CRLCopy.htm</outfile>
              </output>
          </configuration>
        EOF

        expect(chef_run).to render_file('C:\CrlCopy\issuingca1\CRL_Config.XML').with_content(template_content)
      end
    end
  end

  describe "when specifying the ['crl_copy']['master_crl'] attribute" do
    context "when specifying one master CRL with all parameters" do
      cached(:chef_run) do
        ChefSpec::SoloRunner.new(file_cache_path: '/Chef/cache', step_into: :crl_copy) do |node|
          node.set['crl_copy']['master_crls']['C:\Windows\System32\certsrv\CertEnroll\issuingca1.crl'].tap do |master_crl|
            master_crl['cdps']['internal cdp1']['retrieval']      = 'www'
            master_crl['cdps']['internal cdp1']['retrieval_path'] = 'http://www.f.internal/pki/'
            master_crl['cdps']['internal cdp1']['push']           = 'true'
            master_crl['cdps']['internal cdp1']['push_method']    = 'file'
            master_crl['cdps']['internal cdp1']['push_path']      = '\\\\www.f.internal\pki\\'
            master_crl['cdps']['internal ldap']['retrieval']      = 'ldap'
            master_crl['cdps']['internal ldap']['retrieval_path'] = 'dc=f,dc=internal'
            master_crl['cdps']['internal ldap']['push']           = ''
            master_crl['cdps']['internal ldap']['push_method']    = ''
            master_crl['cdps']['internal ldap']['push_path']      = ''
            master_crl['cdps']['external cdp']['retrieval']       = 'www'
            master_crl['cdps']['external cdp']['retrieval_path']  = 'http://pki.g.internal/pki/'
            master_crl['cdps']['external cdp']['push']            = ''
            master_crl['cdps']['external cdp']['push_method']     = ''
            master_crl['cdps']['external cdp']['push_path']       = ''
            master_crl['eventvwr_event_source']                   = 'CRL Copy Event'
            master_crl['eventvwr_event_id']                       = 6000
            master_crl['eventvwr_event_high']                     = 2
            master_crl['eventvwr_event_warning']                  = 4
            master_crl['eventvwr_event_information']              = 8
            master_crl['outfile']                                 = 'C:\Windows\System32\certsrv\CertEnroll\CRLCopy.htm'
            master_crl['smtp_send_mail']                          = true
            master_crl['smtp_server']                             = 'exchange.f.internal'
            master_crl['smtp_from']                               = 'crlcopy@f.internal'
            master_crl['smtp_to']                                 = ['pfox@f.internal', 'pierref@f.internal']
            master_crl['smtp_published_notify']                   = true
            master_crl['smtp_title']                              = 'CRL Copy Process Results'
            master_crl['smtp_threshold']                          = 2
            master_crl['warnings_threshold']                      = 60
            master_crl['warnings_threshold_unit']                 = 'Minutes'
          end
        end.converge(described_recipe)
      end

      it 'should converge successfully' do
        expect { chef_run }.to_not raise_error
      end

      it 'should not write warning' do
        expect(chef_run).to_not write_log('crl_copy::default: No master CRLs specified, skipping crl_copy resource.').with(level: :warn)
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
          'eventvwr_event_source'      => 'CRL Copy Event',
          'eventvwr_event_id'          => 6000,
          'eventvwr_event_high'        => 2,
          'eventvwr_event_warning'     => 4,
          'eventvwr_event_information' => 8,
          'outfile'                    => 'C:\Windows\System32\certsrv\CertEnroll\CRLCopy.htm',
          'smtp_send_mail'             => true,
          'smtp_server'                => 'exchange.f.internal',
          'smtp_from'                  => 'crlcopy@f.internal',
          'smtp_to'                    => ['pfox@f.internal', 'pierref@f.internal'],
          'smtp_published_notify'      => true,
          'smtp_title'                 => 'CRL Copy Process Results',
          'smtp_threshold'             => 2,
          'warnings_threshold'         => 60,
          'warnings_threshold_unit'    => 'Minutes'
        )
      end

      context 'it steps into crl_copy[C:\Windows\System32\certsrv\CertEnroll\issuingca1.crl]' do
        it 'creates directory C:\CrlCopy\issuingca1 directory' do
          expect(chef_run).to create_directory('C:\CrlCopy\issuingca1')
        end

        it 'creates file C:\CrlCopy\issuingca1\CRL_Copy.ps1' do
          expect(chef_run).to create_cookbook_file('C:\CrlCopy\issuingca1\CRL_Copy.ps1')
        end

        it 'renders template C:\CrlCopy\issuingca1\CRL_Config.XML' do
          expect(chef_run).to create_template('C:\CrlCopy\issuingca1\CRL_Config.XML').with_variables(
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
            crl_file: 'issuingca1.crl',
            crl_dir: 'C:\Windows\System32\certsrv\CertEnroll\\',
            eventvwr_event_high: 2,
            eventvwr_event_id: 6000,
            eventvwr_event_information: 8,
            eventvwr_event_source: 'CRL Copy Event',
            eventvwr_event_warning: 4,
            outfile: ['C:\Windows\System32\certsrv\CertEnroll\CRLCopy.htm'],
            smtp_from: 'crlcopy@f.internal',
            smtp_published_notify: true,
            smtp_send_mail: true,
            smtp_server: 'exchange.f.internal',
            smtp_threshold: 2,
            smtp_title: 'CRL Copy Process Results',
            smtp_to: ['pfox@f.internal', 'pierref@f.internal'],
            warnings_threshold: 60,
            warnings_threshold_unit: 'Minutes'
          )

          template_content = <<-EOF.gsub(/^ {12}/, '')
            <?xml version="1.0" encoding="US-ASCII"?>
            <configuration>
                <master_crl>
                    <name>issuingca1.crl</name>
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
                    <EventSource>CRL Copy Event</EventSource>
                    <EventID>6000</EventID>
                    <EventHigh>2</EventHigh>
                    <EventWarning>4</EventWarning>
                    <EventInformation>8</EventInformation>
                </eventvwr>

                <warnings>
                    <threshold>60</threshold>
                    <threshold_unit>Minutes</threshold_unit> <!-- days, hours, minutes or seconds -->
                </warnings>

                <ADCS>
                    <cluster></cluster> <!-- no value for FALSE -->
                </ADCS>

                <output>
                    <outfile>C:\\Windows\\System32\\certsrv\\CertEnroll\\CRLCopy.htm</outfile>
                </output>
            </configuration>
          EOF

          expect(chef_run).to render_file('C:\CrlCopy\issuingca1\CRL_Config.XML').with_content(template_content)
        end
      end
    end

    context "when specifying one master CRL with minimal attributes" do
      cached(:chef_run) do
        ChefSpec::SoloRunner.new(file_cache_path: '/Chef/cache', step_into: :crl_copy) do |node|
          node.set['crl_copy']['master_crls']['C:\Windows\System32\certsrv\CertEnroll\issuingca1.crl'].tap do |master_crl|
            master_crl['cdps']['internal cdp1']['retrieval']      = 'www'
            master_crl['cdps']['internal cdp1']['retrieval_path'] = 'http://www.f.internal/pki/'
            master_crl['cdps']['internal cdp1']['push']           = 'true'
            master_crl['cdps']['internal cdp1']['push_method']    = 'file'
            master_crl['cdps']['internal cdp1']['push_path']      = '\\\\www.f.internal\pki\\'
          end
        end.converge(described_recipe)
      end

      it 'should converge successfully' do
        expect { chef_run }.to_not raise_error
      end

      it 'should not write warning' do
        expect(chef_run).to_not write_log('crl_copy::default: No master CRLs specified, skipping crl_copy resource.').with(level: :warn)
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
            }
          },
          'eventvwr_event_source'      => 'CRL Copy Process',
          'eventvwr_event_id'          => 5000,
          'eventvwr_event_high'        => 1,
          'eventvwr_event_warning'     => 2,
          'eventvwr_event_information' => 4,
          'smtp_send_mail'             => false,
          'smtp_server'                => nil,
          'smtp_from'                  => nil,
          'smtp_to'                    => nil,
          'smtp_published_notify'      => false,
          'smtp_title'                 => 'CRL Copy Process Results',
          'smtp_threshold'             => 2,
          'warnings_threshold'         => 5,
          'warnings_threshold_unit'    => 'Hours'
        )
      end

      context 'it steps into crl_copy[C:\Windows\System32\certsrv\CertEnroll\issuingca1.crl]' do
        it 'creates directory C:\CrlCopy\issuingca1 directory' do
          expect(chef_run).to create_directory('C:\CrlCopy\issuingca1')
        end

        it 'creates file C:\CrlCopy\issuingca1\CRL_Copy.ps1' do
          expect(chef_run).to create_cookbook_file('C:\CrlCopy\issuingca1\CRL_Copy.ps1')
        end

        it 'renders template C:\CrlCopy\issuingca1\CRL_Config.XML' do
          expect(chef_run).to create_template('C:\CrlCopy\issuingca1\CRL_Config.XML').with_variables(
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
            crl_file: 'issuingca1.crl',
            crl_dir: 'C:\Windows\System32\certsrv\CertEnroll\\',
            eventvwr_event_high: 1,
            eventvwr_event_id: 5000,
            eventvwr_event_information: 4,
            eventvwr_event_source: 'CRL Copy Process',
            eventvwr_event_warning: 2,
            outfile: ['C:\Windows\System32\certsrv\CertEnroll\CRLCopy.htm'],
            smtp_from: nil,
            smtp_published_notify: false,
            smtp_send_mail: false,
            smtp_server: nil,
            smtp_threshold: 2,
            smtp_title: 'CRL Copy Process Results',
            smtp_to: [nil],
            warnings_threshold: 5,
            warnings_threshold_unit: 'Hours'
          )

          template_content = <<-EOF.gsub(/^ {12}/, '')
            <?xml version="1.0" encoding="US-ASCII"?>
            <configuration>
                <master_crl>
                    <name>issuingca1.crl</name>
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
                    <send_SMTP></send_SMTP> <!-- no value for FALSE -->
                    <SmtpServer></SmtpServer>
                    <from></from>
                    <to></to>
                    <published_notify></published_notify> <!-- no value for FALSE -->
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
                    <outfile>C:\\Windows\\System32\\certsrv\\CertEnroll\\CRLCopy.htm</outfile>
                </output>
            </configuration>
          EOF

          expect(chef_run).to render_file('C:\CrlCopy\issuingca1\CRL_Config.XML').with_content(template_content)
        end
      end
    end

    context "when specifying two master CRLs with minimal attributes" do
      cached(:chef_run) do
        ChefSpec::SoloRunner.new(file_cache_path: '/Chef/cache', step_into: :crl_copy) do |node|
          node.set['crl_copy']['master_crls']['C:\Windows\System32\certsrv\CertEnroll\issuingca1.crl'].tap do |master_crl|
            master_crl['cdps']['internal cdp1']['retrieval']      = 'www'
            master_crl['cdps']['internal cdp1']['retrieval_path'] = 'http://www.f.internal/pki/'
            master_crl['cdps']['internal cdp1']['push']           = 'true'
            master_crl['cdps']['internal cdp1']['push_method']    = 'file'
            master_crl['cdps']['internal cdp1']['push_path']      = '\\\\www.f.internal\pki\\'
          end
          node.set['crl_copy']['master_crls']['C:\Windows\System32\certsrv\CertEnroll\issuingca2.crl'].tap do |master_crl|
            master_crl['cdps']['internal cdp1']['retrieval']      = 'www'
            master_crl['cdps']['internal cdp1']['retrieval_path'] = 'http://www.f.internal/pki/'
            master_crl['cdps']['internal cdp1']['push']           = 'true'
            master_crl['cdps']['internal cdp1']['push_method']    = 'file'
            master_crl['cdps']['internal cdp1']['push_path']      = '\\\\www.f.internal\pki\\'
          end
        end.converge(described_recipe)
      end

      it 'should converge successfully' do
        expect { chef_run }.to_not raise_error
      end

      it 'should not write warning' do
        expect(chef_run).to_not write_log('crl_copy::default: No master CRLs specified, skipping crl_copy resource.').with(level: :warn)
      end

      %w(issuingca1 issuingca2).each do |issuingca|
        it "should create a crl_copy[C:\\Windows\\System32\\certsrv\\CertEnroll\\#{issuingca}.crl] resource" do
          expect(chef_run).to create_crl_copy("C:\\Windows\\System32\\certsrv\\CertEnroll\\#{issuingca}.crl").with(
            'cdps' => {
              'internal cdp1' => {
                'retrieval'      => 'www',
                'retrieval_path' => 'http://www.f.internal/pki/',
                'push'           => 'true',
                'push_method'    => 'file',
                'push_path'      => '\\\\www.f.internal\pki\\'
              }
            },
            'eventvwr_event_source'      => 'CRL Copy Process',
            'eventvwr_event_id'          => 5000,
            'eventvwr_event_high'        => 1,
            'eventvwr_event_warning'     => 2,
            'eventvwr_event_information' => 4,
            'smtp_send_mail'             => false,
            'smtp_server'                => nil,
            'smtp_from'                  => nil,
            'smtp_to'                    => nil,
            'smtp_published_notify'      => false,
            'smtp_title'                 => 'CRL Copy Process Results',
            'smtp_threshold'             => 2,
            'warnings_threshold'         => 5,
            'warnings_threshold_unit'    => 'Hours'
          )
        end

        context "it steps into crl_copy[C:\\Windows\\System32\\certsrv\\CertEnroll\\#{issuingca}.crl]" do
          it "creates directory C:\\CrlCopy\\#{issuingca} directory" do
            expect(chef_run).to create_directory("C:\\CrlCopy\\#{issuingca}")
          end

          it "creates file C:\\CrlCopy\\#{issuingca}\\CRL_Copy.ps1" do
            expect(chef_run).to create_cookbook_file("C:\\CrlCopy\\#{issuingca}\\CRL_Copy.ps1")
          end

          it "renders template C:\\CrlCopy\\#{issuingca}\\CRL_Config.XML" do
            expect(chef_run).to create_template("C:\\CrlCopy\\#{issuingca}\\CRL_Config.XML").with_variables(
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
              crl_file: "#{issuingca}.crl",
              crl_dir: 'C:\Windows\System32\certsrv\CertEnroll\\',
              eventvwr_event_high: 1,
              eventvwr_event_id: 5000,
              eventvwr_event_information: 4,
              eventvwr_event_source: 'CRL Copy Process',
              eventvwr_event_warning: 2,
              outfile: ['C:\Windows\System32\certsrv\CertEnroll\CRLCopy.htm'],
              smtp_from: nil,
              smtp_published_notify: false,
              smtp_send_mail: false,
              smtp_server: nil,
              smtp_threshold: 2,
              smtp_title: 'CRL Copy Process Results',
              smtp_to: [nil],
              warnings_threshold: 5,
              warnings_threshold_unit: 'Hours'
            )

            template_content = <<-EOF.gsub(/^ {14}/, '')
              <?xml version="1.0" encoding="US-ASCII"?>
              <configuration>
                  <master_crl>
                      <name>#{issuingca}.crl</name>
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
                      <send_SMTP></send_SMTP> <!-- no value for FALSE -->
                      <SmtpServer></SmtpServer>
                      <from></from>
                      <to></to>
                      <published_notify></published_notify> <!-- no value for FALSE -->
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
                      <outfile>C:\\Windows\\System32\\certsrv\\CertEnroll\\CRLCopy.htm</outfile>
                  </output>
              </configuration>
            EOF

            expect(chef_run).to render_file("C:\\CrlCopy\\#{issuingca}\\CRL_Config.XML").with_content(template_content)
          end
        end
      end
    end
  end

  describe "when specifying ['crl_copy']['pscx'] and ['crl_copy']['pspki'] attributes" do
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

    it 'installs the PSCX PowerShell module with specified source and package name' do
      expect(chef_run).to create_remote_file('/Chef/cache/pscx.msi').with(
        source: 'http://test'
      )

      expect(chef_run).to install_package('pscx package name').with(
        source: '/Chef/cache/pscx.msi',
        installer_type: :msi
      )
    end

    it 'installs the PSPKI PowerShell module with specified source and package name' do
      expect(chef_run).to create_remote_file('/Chef/cache/pspki.exe').with(
        source: 'http://test'
      )

      expect(chef_run).to install_package('pspki package name').with(
        source: '/Chef/cache/pspki.exe',
        installer_type: :custom,
        options: '/quiet'
      )
    end

    it 'should write warning' do
      expect(chef_run).to write_log('crl_copy::default: No master CRLs specified, skipping crl_copy resource.').with(level: :warn)
    end
  end

  describe "when specifying the ['crl_copy']['smtp'] attributes" do
    cached(:chef_run) do
      ChefSpec::SoloRunner.new(file_cache_path: '/Chef/cache', step_into: :crl_copy) do |node|
        node.set['crl_copy']['smtp']['send_mail']          = true
        node.set['crl_copy']['smtp']['server']             = 'exchange.f.internal'
        node.set['crl_copy']['smtp']['from']               = 'crlcopy@f.internal'
        node.set['crl_copy']['smtp']['to']                 = ['pfox@f.internal', 'pierref@f.internal']
        node.set['crl_copy']['smtp']['published_notify']   = true
        node.set['crl_copy']['smtp']['title']              = 'CRL Copy Process Results'
        node.set['crl_copy']['smtp']['threshold']          = 2

        node.set['crl_copy']['master_crls']['C:\Windows\System32\certsrv\CertEnroll\issuingca1.crl'].tap do |master_crl|
          master_crl['cdps']['internal cdp1']['retrieval'] = 'www'
          master_crl['cdps']['internal cdp1']['retrieval_path'] = 'http://www.f.internal/pki/'
          master_crl['cdps']['internal cdp1']['push'] = 'true'
          master_crl['cdps']['internal cdp1']['push_method'] = 'file'
          master_crl['cdps']['internal cdp1']['push_path'] = '\\\\www.f.internal\pki\\'
        end
      end.converge(described_recipe)
    end

    it 'should converge successfully' do
      expect { chef_run }.to_not raise_error
    end

    it 'should not write warning' do
      expect(chef_run).to_not write_log('crl_copy::default: No master CRLs specified, skipping crl_copy resource.').with(level: :warn)
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
          }
        },
        'eventvwr_event_source'      => 'CRL Copy Process',
        'eventvwr_event_id'          => 5000,
        'eventvwr_event_high'        => 1,
        'eventvwr_event_warning'     => 2,
        'eventvwr_event_information' => 4,
        'smtp_send_mail'             => true,
        'smtp_server'                => 'exchange.f.internal',
        'smtp_from'                  => 'crlcopy@f.internal',
        'smtp_to'                    => ['pfox@f.internal', 'pierref@f.internal'],
        'smtp_published_notify'      => true,
        'smtp_title'                 => 'CRL Copy Process Results',
        'smtp_threshold'             => 2,
        'warnings_threshold'         => 5,
        'warnings_threshold_unit'    => 'Hours'
      )
    end

    context 'it steps into crl_copy[C:\Windows\System32\certsrv\CertEnroll\issuingca1.crl]' do
      it 'creates directory C:\CrlCopy\issuingca1 directory' do
        expect(chef_run).to create_directory('C:\CrlCopy\issuingca1')
      end

      it 'creates file C:\CrlCopy\issuingca1\CRL_Copy.ps1' do
        expect(chef_run).to create_cookbook_file('C:\CrlCopy\issuingca1\CRL_Copy.ps1')
      end

      it 'renders template C:\CrlCopy\issuingca1\CRL_Config.XML' do
        expect(chef_run).to create_template('C:\CrlCopy\issuingca1\CRL_Config.XML').with_variables(
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
          crl_file: 'issuingca1.crl',
          crl_dir: 'C:\Windows\System32\certsrv\CertEnroll\\',
          eventvwr_event_high: 1,
          eventvwr_event_id: 5000,
          eventvwr_event_information: 4,
          eventvwr_event_source: 'CRL Copy Process',
          eventvwr_event_warning: 2,
          outfile: ['C:\Windows\System32\certsrv\CertEnroll\CRLCopy.htm'],
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
                  <name>issuingca1.crl</name>
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
                  <outfile>C:\\Windows\\System32\\certsrv\\CertEnroll\\CRLCopy.htm</outfile>
              </output>
          </configuration>
        EOF

        expect(chef_run).to render_file('C:\CrlCopy\issuingca1\CRL_Config.XML').with_content(template_content)
      end
    end
  end

  describe "when specifying the ['crl_copy']['warnings'] attributes" do
    cached(:chef_run) do
      ChefSpec::SoloRunner.new(file_cache_path: '/Chef/cache', step_into: :crl_copy) do |node|
        node.set['crl_copy']['warnings']['threshold']      = 60
        node.set['crl_copy']['warnings']['threshold_unit'] = 'Minutes'

        node.set['crl_copy']['master_crls']['C:\Windows\System32\certsrv\CertEnroll\issuingca1.crl'].tap do |master_crl|
          master_crl['cdps']['internal cdp1']['retrieval'] = 'www'
          master_crl['cdps']['internal cdp1']['retrieval_path'] = 'http://www.f.internal/pki/'
          master_crl['cdps']['internal cdp1']['push'] = 'true'
          master_crl['cdps']['internal cdp1']['push_method'] = 'file'
          master_crl['cdps']['internal cdp1']['push_path'] = '\\\\www.f.internal\pki\\'
        end
      end.converge(described_recipe)
    end

    it 'should converge successfully' do
      expect { chef_run }.to_not raise_error
    end

    it 'should not write warning' do
      expect(chef_run).to_not write_log('crl_copy::default: No master CRLs specified, skipping crl_copy resource.').with(level: :warn)
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
          }
        },
        'eventvwr_event_source'      => 'CRL Copy Process',
        'eventvwr_event_id'          => 5000,
        'eventvwr_event_high'        => 1,
        'eventvwr_event_warning'     => 2,
        'eventvwr_event_information' => 4,
        'smtp_send_mail'             => false,
        'smtp_server'                => nil,
        'smtp_from'                  => nil,
        'smtp_to'                    => nil,
        'smtp_published_notify'      => false,
        'smtp_title'                 => 'CRL Copy Process Results',
        'smtp_threshold'             => 2,
        'warnings_threshold'         => 60,
        'warnings_threshold_unit'    => 'Minutes'
      )
    end

    context 'it steps into crl_copy[C:\Windows\System32\certsrv\CertEnroll\issuingca1.crl]' do
      it 'creates directory C:\CrlCopy\issuingca1 directory' do
        expect(chef_run).to create_directory('C:\CrlCopy\issuingca1')
      end

      it 'creates file C:\CrlCopy\issuingca1\CRL_Copy.ps1' do
        expect(chef_run).to create_cookbook_file('C:\CrlCopy\issuingca1\CRL_Copy.ps1')
      end

      it 'renders template C:\CrlCopy\issuingca1\CRL_Config.XML' do
        expect(chef_run).to create_template('C:\CrlCopy\issuingca1\CRL_Config.XML').with_variables(
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
          crl_file: 'issuingca1.crl',
          crl_dir: 'C:\Windows\System32\certsrv\CertEnroll\\',
          eventvwr_event_high: 1,
          eventvwr_event_id: 5000,
          eventvwr_event_information: 4,
          eventvwr_event_source: 'CRL Copy Process',
          eventvwr_event_warning: 2,
          outfile: ['C:\Windows\System32\certsrv\CertEnroll\CRLCopy.htm'],
          smtp_from: nil,
          smtp_published_notify: false,
          smtp_send_mail: false,
          smtp_server: nil,
          smtp_threshold: 2,
          smtp_title: 'CRL Copy Process Results',
          smtp_to: [nil],
          warnings_threshold: 60,
          warnings_threshold_unit: 'Minutes'
        )

        template_content = <<-EOF.gsub(/^ {10}/, '')
          <?xml version="1.0" encoding="US-ASCII"?>
          <configuration>
              <master_crl>
                  <name>issuingca1.crl</name>
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
                  <send_SMTP></send_SMTP> <!-- no value for FALSE -->
                  <SmtpServer></SmtpServer>
                  <from></from>
                  <to></to>
                  <published_notify></published_notify> <!-- no value for FALSE -->
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
                  <threshold>60</threshold>
                  <threshold_unit>Minutes</threshold_unit> <!-- days, hours, minutes or seconds -->
              </warnings>

              <ADCS>
                  <cluster></cluster> <!-- no value for FALSE -->
              </ADCS>

              <output>
                  <outfile>C:\\Windows\\System32\\certsrv\\CertEnroll\\CRLCopy.htm</outfile>
              </output>
          </configuration>
        EOF

        expect(chef_run).to render_file('C:\CrlCopy\issuingca1\CRL_Config.XML').with_content(template_content)
      end
    end
  end
end
