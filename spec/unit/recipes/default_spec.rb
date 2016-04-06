#
# Cookbook Name:: crl_copy
# Spec:: default
#
# Copyright (C) 2016 Schuberg Philis
#
# Created by: Stephen Hoekstra <shoekstra@schubergphilis.com>
#

require 'spec_helper'

shared_examples_for 'installs CRL Copy and config xml' do
  it 'should converge successfully' do
    expect { chef_run }.to_not raise_error
  end

  it 'should not write warning' do
    expect(chef_run).to_not write_log('crl_copy::default: No master CRLs specified, skipping crl_copy resource.').with(level: :warn)
  end

  it "should create a crl_copy[C:\\Windows\\System32\\certsrv\\CertEnroll\\#{@crl_name}.crl] resource" do
    expect(chef_run).to create_crl_copy("C:\\Windows\\System32\\certsrv\\CertEnroll\\#{crl_name}.crl").with(crl_copy_attributes)
  end

  context "it steps into crl_copy[C:\\Windows\\System32\\certsrv\\CertEnroll\\#{@crl_name}.crl]" do
    it 'creates directory C:\CrlCopy directory' do
      expect(chef_run).to create_directory('C:\CrlCopy')
    end

    it 'creates file C:\CrlCopy\crl_copy_v3.ps1' do
      expect(chef_run).to create_cookbook_file('C:\CrlCopy\crl_copy_v3.ps1')
    end

    it "should render template C:\\CrlCopy\\#{@crl_name}_CRL_Config.xml" do
      expect(chef_run).to create_template("C:\\CrlCopy\\#{crl_name}_CRL_Config.xml").with_variables(template_variables)

      template_content = <<-EOF.gsub(/^ {10}/, '')
          <?xml version="1.0" encoding="US-ASCII"?>
          <configuration>
          #{content_master_crl.chomp}

          #{content_cdps.chomp}

          #{content_smtp.chomp}

          #{content_eventvwr.chomp}

          #{content_warnings.chomp}

          #{content_adcs.chomp}

          #{content_output.chomp}
          </configuration>
        EOF

      expect(chef_run).to render_file("C:\\CrlCopy\\#{crl_name}_CRL_Config.xml").with_content(template_content)
    end

    it "should create a windows_task[CRLCopy #{@crl_name}.crl] resource" do
      expect(chef_run).to create_windows_task("CRLCopy #{crl_name}.crl").with(windows_task_attributes)
    end
  end
end

describe 'crl_copy::default' do
  let(:crl_name) do
    'issuingca1'
  end

  let(:content_adcs) do
    <<-EOF.gsub(/^ {2}/, '')
      <ADCS>
          <cluster></cluster> <!-- no value for FALSE -->
      </ADCS>
    EOF
  end

  let(:content_cdps) do
    <<-EOF.gsub(/^ {2}/, '')
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
    EOF
  end

  let(:content_eventvwr) do
    <<-EOF.gsub(/^ {2}/, '')
      <eventvwr>
          <EventSource>CRL Copy Process</EventSource>
          <EventID>5000</EventID>
          <EventHigh>1</EventHigh>
          <EventWarning>2</EventWarning>
          <EventInformation>4</EventInformation>
      </eventvwr>
    EOF
  end

  let(:content_master_crl) do
    <<-EOF.gsub(/^ {2}/, '')
      <master_crl>
          <name>#{crl_name}.crl</name>
          <retrieval>file</retrieval>
          <path>C:\\Windows\\System32\\certsrv\\CertEnroll\\</path>
      </master_crl>
    EOF
  end

  let(:content_output) do
    <<-EOF.gsub(/^ {2}/, '')
      <output>
          <outfile>C:\\CrlCopy\\#{crl_name}_CRL_Status.htm</outfile>
      </output>
    EOF
  end

  let(:content_smtp) do
    <<-EOF.gsub(/^ {2}/, '')
      <SMTP>
          <send_SMTP></send_SMTP> <!-- no value for FALSE -->
          <SmtpServer></SmtpServer>
          <from></from>
          <to></to>
          <published_notify></published_notify> <!-- no value for FALSE -->
          <title>CRL Copy Process Results</title>
          <SMTPThreshold>2</SMTPThreshold> <!-- event level when an SMTP message is sent -->
      </SMTP>
    EOF
  end

  let(:content_warnings) do
    <<-EOF.gsub(/^ {2}/, '')
      <warnings>
          <threshold>5</threshold>
          <threshold_unit>Hours</threshold_unit> <!-- days, hours, minutes or seconds -->
      </warnings>
    EOF
  end

  let(:crl_copy_attributes_default) do
    {
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
    }
  end

  let(:template_variables_default) do
    {
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
      crl_file: "#{crl_name}.crl",
      crl_dir: 'C:\Windows\System32\certsrv\CertEnroll\\',
      eventvwr_event_high: 1,
      eventvwr_event_id: 5000,
      eventvwr_event_information: 4,
      eventvwr_event_source: 'CRL Copy Process',
      eventvwr_event_warning: 2,
      outfile: ["C:\\CrlCopy\\#{crl_name}_CRL_Status.htm"],
      smtp_from: nil,
      smtp_published_notify: false,
      smtp_send_mail: false,
      smtp_server: nil,
      smtp_threshold: 2,
      smtp_title: 'CRL Copy Process Results',
      smtp_to: [nil],
      warnings_threshold: 5,
      warnings_threshold_unit: 'Hours'
    }
  end

  let(:windows_task_attributes_default) do
    {
      user: 'SYSTEM',
      command: "%SystemRoot%\\system32\\WindowsPowerShell\\v1.0\\powershell.exe C:\\CrlCopy\\crl_copy_v3.ps1 -Action Publish -XmlFile C:\\CrlCopy\\#{crl_name}_CRL_Config.xml",
      run_level: :highest,
      frequency: :minute,
      frequency_modifier: 30
    }
  end

  describe 'when all attributes are default' do
    cached(:chef_run) do
      ChefSpec::SoloRunner.new(file_cache_path: '/Chef/cache').converge(described_recipe)
    end

    it 'should converge successfully' do
      expect { chef_run }.to_not raise_error
    end

    it 'installs the PSCX PowerShell module using default values' do
      expect(chef_run).to create_remote_file('/Chef/cache/pscx.msi').with(
        source: 'http://download-codeplex.sec.s-msft.com/Download/Release?ProjectName=pscx&DownloadId=923562&FileTime=130585918034470000&Build=21031'
      )

      expect(chef_run).to install_package('PowerShell Community Extensions 3.2.0').with(
        source: '/Chef/cache/pscx.msi',
        installer_type: :msi
      )
    end

    it 'installs the PSPKI PowerShell module using default values' do
      expect(chef_run).to create_remote_file('/Chef/cache/pspki.exe').with(
        source: 'http://download-codeplex.sec.s-msft.com/Download/Release?ProjectName=pspki&DownloadId=1440723&FileTime=130716062844400000&Build=21031'
      )

      expect(chef_run).to install_package('PowerShell PKI Module').with(
        source: '/Chef/cache/pspki.exe',
        installer_type: :custom,
        options: 'addlocal=all /qn'
      )
    end

    it 'should write warning' do
      expect(chef_run).to write_log('crl_copy::default: No master CRLs specified, skipping crl_copy resource.').with(level: :warn)
    end
  end

  describe 'when master_crl attribute has minimum attributes' do
    let(:chef_run) do
      ChefSpec::SoloRunner.new(file_cache_path: '/Chef/cache', step_into: :crl_copy) do |node|
        node.set['crl_copy']['master_crls']["C:\\Windows\\System32\\certsrv\\CertEnroll\\#{crl_name}.crl"].tap do |master_crl|
          master_crl['cdps']['internal cdp1']['retrieval']      = 'www'
          master_crl['cdps']['internal cdp1']['retrieval_path'] = 'http://www.f.internal/pki/'
          master_crl['cdps']['internal cdp1']['push']           = 'true'
          master_crl['cdps']['internal cdp1']['push_method']    = 'file'
          master_crl['cdps']['internal cdp1']['push_path']      = '\\\\www.f.internal\pki\\'
        end
      end.converge(described_recipe)
    end

    let(:crl_copy_attributes) { crl_copy_attributes_default }
    let(:template_variables) { template_variables_default }
    let(:windows_task_attributes) { windows_task_attributes_default }

    it_behaves_like 'installs CRL Copy and config xml'
  end

  describe 'when master_crl attribute has minimum attributes and two CRLs' do
    let(:chef_run) do
      ChefSpec::SoloRunner.new(file_cache_path: '/Chef/cache', step_into: :crl_copy) do |node|
        node.set['crl_copy']['master_crls']["C:\\Windows\\System32\\certsrv\\CertEnroll\\#{crl_name}.crl"].tap do |master_crl|
          master_crl['cdps']['internal cdp1']['retrieval']      = 'www'
          master_crl['cdps']['internal cdp1']['retrieval_path'] = 'http://www.f.internal/pki/'
          master_crl['cdps']['internal cdp1']['push']           = 'true'
          master_crl['cdps']['internal cdp1']['push_method']    = 'file'
          master_crl['cdps']['internal cdp1']['push_path']      = '\\\\www.f.internal\pki\\'
        end
        node.set['crl_copy']['master_crls']['C:\\Windows\\System32\\certsrv\\CertEnroll\\issuingca2.crl'].tap do |master_crl|
          master_crl['cdps']['internal cdp1']['retrieval']      = 'www'
          master_crl['cdps']['internal cdp1']['retrieval_path'] = 'http://www.f.internal/pki/'
          master_crl['cdps']['internal cdp1']['push']           = 'true'
          master_crl['cdps']['internal cdp1']['push_method']    = 'file'
          master_crl['cdps']['internal cdp1']['push_path']      = '\\\\www.f.internal\pki\\'
        end
      end.converge(described_recipe)
    end

    context 'issuingca1' do
      let(:crl_name) { 'issuingca1' }
      let(:crl_copy_attributes) { crl_copy_attributes_default }
      let(:template_variables) { template_variables_default }
      let(:windows_task_attributes) { windows_task_attributes_default }

      it_behaves_like 'installs CRL Copy and config xml'
    end

    context 'issuingca2' do
      let(:crl_name) { 'issuingca2' }
      let(:crl_copy_attributes) { crl_copy_attributes_default }
      let(:template_variables) { template_variables_default }
      let(:windows_task_attributes) { windows_task_attributes_default }

      it_behaves_like 'installs CRL Copy and config xml'
    end
  end

  describe 'when master_crl attribute has minimum attributes and multiple CDP locations' do
    let(:chef_run) do
      ChefSpec::SoloRunner.new(file_cache_path: '/Chef/cache', step_into: :crl_copy) do |node|
        node.set['crl_copy']['master_crls']["C:\\Windows\\System32\\certsrv\\CertEnroll\\#{crl_name}.crl"].tap do |master_crl|
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
        end
      end.converge(described_recipe)
    end

    let(:content_cdps) do
      <<-EOF.gsub(/^ {4}/, '')
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
    end

    let(:crl_copy_attributes) do
      crl_copy_attributes_default.merge(
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
        }
      )
    end

    let(:template_variables) do
      template_variables_default.merge(
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
        }
      )
    end

    let(:windows_task_attributes) { windows_task_attributes_default }

    it_behaves_like 'installs CRL Copy and config xml'
  end

  describe 'when master_crl attribute has minimum attributes and cluster_name attribute' do
    let(:chef_run) do
      ChefSpec::SoloRunner.new(file_cache_path: '/Chef/cache', step_into: :crl_copy) do |node|
        node.set['crl_copy']['master_crls']["C:\\Windows\\System32\\certsrv\\CertEnroll\\#{crl_name}.crl"].tap do |master_crl|
          master_crl['cdps']['internal cdp1']['retrieval']      = 'www'
          master_crl['cdps']['internal cdp1']['retrieval_path'] = 'http://www.f.internal/pki/'
          master_crl['cdps']['internal cdp1']['push']           = 'true'
          master_crl['cdps']['internal cdp1']['push_method']    = 'file'
          master_crl['cdps']['internal cdp1']['push_path']      = '\\\\www.f.internal\pki\\'
          master_crl['cluster_name']                            = 'cluster'
        end
      end.converge(described_recipe)
    end

    let(:content_adcs) do
      <<-EOF.gsub(/^ {4}/, '')
        <ADCS>
                      <cluster>cluster</cluster> <!-- no value for FALSE -->
                  </ADCS>
      EOF
    end

    let(:crl_copy_attributes) do
      crl_copy_attributes_default.merge(
        'cluster_name' => 'cluster'
      )
    end

    let(:template_variables) do
      template_variables_default.merge(
        cluster_name: 'cluster'
      )
    end

    let(:windows_task_attributes) { windows_task_attributes_default }

    it_behaves_like 'installs CRL Copy and config xml'
  end

  describe 'when master_crl attribute has minimum attributes and eventvwr attributes' do
    let(:chef_run) do
      ChefSpec::SoloRunner.new(file_cache_path: '/Chef/cache', step_into: :crl_copy) do |node|
        node.set['crl_copy']['master_crls']["C:\\Windows\\System32\\certsrv\\CertEnroll\\#{crl_name}.crl"].tap do |master_crl|
          master_crl['cdps']['internal cdp1']['retrieval']      = 'www'
          master_crl['cdps']['internal cdp1']['retrieval_path'] = 'http://www.f.internal/pki/'
          master_crl['cdps']['internal cdp1']['push']           = 'true'
          master_crl['cdps']['internal cdp1']['push_method']    = 'file'
          master_crl['cdps']['internal cdp1']['push_path']      = '\\\\www.f.internal\pki\\'
          master_crl['eventvwr_event_source']                   = 'CRL Copy Event'
          master_crl['eventvwr_event_id']                       = 6000
          master_crl['eventvwr_event_high']                     = 2
          master_crl['eventvwr_event_warning']                  = 4
          master_crl['eventvwr_event_information']              = 8
        end
      end.converge(described_recipe)
    end

    let(:content_eventvwr) do
      <<-EOF.gsub(/^ {4}/, '')
        <eventvwr>
            <EventSource>CRL Copy Event</EventSource>
            <EventID>6000</EventID>
            <EventHigh>2</EventHigh>
            <EventWarning>4</EventWarning>
            <EventInformation>8</EventInformation>
        </eventvwr>
      EOF
    end

    let(:crl_copy_attributes) do
      crl_copy_attributes_default.merge(
        'eventvwr_event_source'      => 'CRL Copy Event',
        'eventvwr_event_id'          => 6000,
        'eventvwr_event_high'        => 2,
        'eventvwr_event_warning'     => 4,
        'eventvwr_event_information' => 8
      )
    end

    let(:template_variables) do
      template_variables_default.merge(
        eventvwr_event_high: 2,
        eventvwr_event_id: 6000,
        eventvwr_event_information: 8,
        eventvwr_event_source: 'CRL Copy Event',
        eventvwr_event_warning: 4
      )
    end

    let(:windows_task_attributes) { windows_task_attributes_default }

    it_behaves_like 'installs CRL Copy and config xml'
  end

  describe 'when master_crl attribute has minimum attributes and has_delta_crl attribute' do
    let(:chef_run) do
      ChefSpec::SoloRunner.new(file_cache_path: '/Chef/cache', step_into: :crl_copy) do |node|
        node.set['crl_copy']['master_crls']["C:\\Windows\\System32\\certsrv\\CertEnroll\\#{crl_name}.crl"].tap do |master_crl|
          master_crl['cdps']['internal cdp1']['retrieval']      = 'www'
          master_crl['cdps']['internal cdp1']['retrieval_path'] = 'http://www.f.internal/pki/'
          master_crl['cdps']['internal cdp1']['push']           = 'true'
          master_crl['cdps']['internal cdp1']['push_method']    = 'file'
          master_crl['cdps']['internal cdp1']['push_path']      = '\\\\www.f.internal\pki\\'
          master_crl['has_delta_crl']                           = true
        end
      end.converge(described_recipe)
    end

    let(:crl_copy_attributes) do
      crl_copy_attributes_default.merge(
        'has_delta_crl' => true
      )
    end

    context 'issuingca1' do
      let(:crl_name) { 'issuingca1' }

      let(:template_variables) do
        template_variables_default
      end

      let(:windows_task_attributes) { windows_task_attributes_default }

      it_behaves_like 'installs CRL Copy and config xml'

      it 'creates directory C:\CrlCopy directory' do
        expect(chef_run).to create_directory('C:\CrlCopy')
      end

      it 'creates file C:\CrlCopy\crl_copy_v3.ps1' do
        expect(chef_run).to create_cookbook_file('C:\CrlCopy\crl_copy_v3.ps1')
      end

      it "should render template C:\\CrlCopy\\#{@crl_name}+_CRL_Config.xml" do
        expect(chef_run).to create_template("C:\\CrlCopy\\#{crl_name}+_CRL_Config.xml").with_variables(
          template_variables_default.merge(
            crl_file: "#{crl_name}+.crl",
            outfile: ["C:\\CrlCopy\\#{crl_name}+_CRL_Status.htm"]
          )
        )

        template_content = <<-EOF.gsub(/^ {10}/, '')
          <?xml version="1.0" encoding="US-ASCII"?>
          <configuration>
              <master_crl>
                  <name>#{crl_name}+.crl</name>
                  <retrieval>file</retrieval>
                  <path>C:\\Windows\\System32\\certsrv\\CertEnroll\\</path>
              </master_crl>

          #{content_cdps.chomp}

          #{content_smtp.chomp}

          #{content_eventvwr.chomp}

          #{content_warnings.chomp}

          #{content_adcs.chomp}

              <output>
                  <outfile>C:\\CrlCopy\\#{crl_name}+_CRL_Status.htm</outfile>
              </output>
          </configuration>
        EOF

        expect(chef_run).to render_file("C:\\CrlCopy\\#{crl_name}+_CRL_Config.xml").with_content(template_content)
      end

      it "should create a windows_task[CRLCopy #{@crl_name}+.crl] resource" do
        expect(chef_run).to create_windows_task("CRLCopy #{crl_name}+.crl").with(
          windows_task_attributes_default.merge(
            command: '%SystemRoot%\system32\WindowsPowerShell\v1.0\powershell.exe C:\CrlCopy\crl_copy_v3.ps1 -Action Publish -XmlFile C:\CrlCopy\issuingca1+_CRL_Config.xml'
          )
        )
      end
    end
  end

  describe 'when master_crl attribute has minimum attributes and outfile attribute' do
    let(:chef_run) do
      ChefSpec::SoloRunner.new(file_cache_path: '/Chef/cache', step_into: :crl_copy) do |node|
        node.set['crl_copy']['master_crls']["C:\\Windows\\System32\\certsrv\\CertEnroll\\#{crl_name}.crl"].tap do |master_crl|
          master_crl['cdps']['internal cdp1']['retrieval']      = 'www'
          master_crl['cdps']['internal cdp1']['retrieval_path'] = 'http://www.f.internal/pki/'
          master_crl['cdps']['internal cdp1']['push']           = 'true'
          master_crl['cdps']['internal cdp1']['push_method']    = 'file'
          master_crl['cdps']['internal cdp1']['push_path']      = '\\\\www.f.internal\pki\\'
          master_crl['outfile']                                 = 'C:\Windows\System32\certsrv\CertEnroll\CRLCopy.htm'
        end
      end.converge(described_recipe)
    end

    let(:content_output) do
      <<-EOF.gsub(/^ {4}/, '')
        <output>
                      <outfile>C:\\Windows\\System32\\certsrv\\CertEnroll\\CRLCopy.htm</outfile>
                  </output>
      EOF
    end

    let(:crl_copy_attributes) do
      crl_copy_attributes_default.merge(
        'outfile' => 'C:\Windows\System32\certsrv\CertEnroll\CRLCopy.htm'
      )
    end

    let(:template_variables) do
      template_variables_default.merge(
        outfile: ['C:\Windows\System32\certsrv\CertEnroll\CRLCopy.htm']
      )
    end

    let(:windows_task_attributes) { windows_task_attributes_default }

    it_behaves_like 'installs CRL Copy and config xml'
  end

  describe 'when master_crl attribute has minimum attributes and smtp attributes' do
    let(:chef_run) do
      ChefSpec::SoloRunner.new(file_cache_path: '/Chef/cache', step_into: :crl_copy) do |node|
        node.set['crl_copy']['master_crls']["C:\\Windows\\System32\\certsrv\\CertEnroll\\#{crl_name}.crl"].tap do |master_crl|
          master_crl['cdps']['internal cdp1']['retrieval']      = 'www'
          master_crl['cdps']['internal cdp1']['retrieval_path'] = 'http://www.f.internal/pki/'
          master_crl['cdps']['internal cdp1']['push']           = 'true'
          master_crl['cdps']['internal cdp1']['push_method']    = 'file'
          master_crl['cdps']['internal cdp1']['push_path']      = '\\\\www.f.internal\pki\\'
          master_crl['smtp_send_mail']                          = true
          master_crl['smtp_server']                             = 'exchange.f.internal'
          master_crl['smtp_from']                               = 'crlcopy@f.internal'
          master_crl['smtp_to']                                 = ['pfox@f.internal', 'pierref@f.internal']
          master_crl['smtp_published_notify']                   = true
          master_crl['smtp_title']                              = 'CRL Copy Process Results'
          master_crl['smtp_threshold']                          = 2
        end
      end.converge(described_recipe)
    end

    let(:content_smtp) do
      <<-EOF.gsub(/^ {4}/, '')
        <SMTP>
            <send_SMTP>true</send_SMTP> <!-- no value for FALSE -->
            <SmtpServer>exchange.f.internal</SmtpServer>
            <from>crlcopy@f.internal</from>
            <to>pfox@f.internal,pierref@f.internal</to>
            <published_notify>true</published_notify> <!-- no value for FALSE -->
            <title>CRL Copy Process Results</title>
            <SMTPThreshold>2</SMTPThreshold> <!-- event level when an SMTP message is sent -->
        </SMTP>
      EOF
    end

    let(:crl_copy_attributes) do
      crl_copy_attributes_default.merge(
        'smtp_send_mail'        => true,
        'smtp_server'           => 'exchange.f.internal',
        'smtp_from'             => 'crlcopy@f.internal',
        'smtp_to'               => ['pfox@f.internal', 'pierref@f.internal'],
        'smtp_published_notify' => true,
        'smtp_title'            => 'CRL Copy Process Results',
        'smtp_threshold'        => 2
      )
    end

    let(:template_variables) do
      template_variables_default.merge(
        smtp_from: 'crlcopy@f.internal',
        smtp_published_notify: true,
        smtp_send_mail: true,
        smtp_server: 'exchange.f.internal',
        smtp_threshold: 2,
        smtp_title: 'CRL Copy Process Results',
        smtp_to: ['pfox@f.internal', 'pierref@f.internal']
      )
    end

    let(:windows_task_attributes) { windows_task_attributes_default }

    it_behaves_like 'installs CRL Copy and config xml'
  end

  describe 'when master_crl attribute has minimum attributes and warnings attribute' do
    let(:chef_run) do
      ChefSpec::SoloRunner.new(file_cache_path: '/Chef/cache', step_into: :crl_copy) do |node|
        node.set['crl_copy']['master_crls']["C:\\Windows\\System32\\certsrv\\CertEnroll\\#{crl_name}.crl"].tap do |master_crl|
          master_crl['cdps']['internal cdp1']['retrieval']      = 'www'
          master_crl['cdps']['internal cdp1']['retrieval_path'] = 'http://www.f.internal/pki/'
          master_crl['cdps']['internal cdp1']['push']           = 'true'
          master_crl['cdps']['internal cdp1']['push_method']    = 'file'
          master_crl['cdps']['internal cdp1']['push_path']      = '\\\\www.f.internal\pki\\'
          master_crl['warnings_threshold']                      = 60
          master_crl['warnings_threshold_unit']                 = 'Minutes'
        end
      end.converge(described_recipe)
    end

    let(:content_warnings) do
      <<-EOF.gsub(/^ {4}/, '')
        <warnings>
                      <threshold>60</threshold>
                      <threshold_unit>Minutes</threshold_unit> <!-- days, hours, minutes or seconds -->
                  </warnings>
        EOF
    end

    let(:crl_copy_attributes) do
      crl_copy_attributes_default.merge(
        'warnings_threshold'      => 60,
        'warnings_threshold_unit' => 'Minutes'
      )
    end

    let(:template_variables) do
      template_variables_default.merge(
        warnings_threshold: 60,
        warnings_threshold_unit: 'Minutes'
      )
    end

    let(:windows_task_attributes) { windows_task_attributes_default }

    it_behaves_like 'installs CRL Copy and config xml'
  end

  describe 'when master_crl attribute has minimum attributes and windows_task attribute' do
    let(:chef_run) do
      ChefSpec::SoloRunner.new(file_cache_path: '/Chef/cache', step_into: :crl_copy) do |node|
        node.set['crl_copy']['master_crls']["C:\\Windows\\System32\\certsrv\\CertEnroll\\#{crl_name}.crl"].tap do |master_crl|
          master_crl['cdps']['internal cdp1']['retrieval']      = 'www'
          master_crl['cdps']['internal cdp1']['retrieval_path'] = 'http://www.f.internal/pki/'
          master_crl['cdps']['internal cdp1']['push']           = 'true'
          master_crl['cdps']['internal cdp1']['push_method']    = 'file'
          master_crl['cdps']['internal cdp1']['push_path']      = '\\\\www.f.internal\pki\\'
          master_crl['windows_task_frequency']                  = 'Daily'
          master_crl['windows_task_frequency_modifier']         = '1'
          master_crl['windows_task_password']                   = 'Password'
          master_crl['windows_task_user']                       = 'Username'
        end
      end.converge(described_recipe)
    end

    let(:crl_copy_attributes) do
      crl_copy_attributes_default.merge(
        'windows_task_frequency'          => 'Daily',
        'windows_task_frequency_modifier' => '1',
        'windows_task_password'           => 'Password',
        'windows_task_user'               => 'Username'
      )
    end

    let(:template_variables) do
      template_variables_default
    end

    let(:windows_task_attributes) do
      windows_task_attributes_default.merge(
        user: 'Username',
        password: 'Password',
        command: '%SystemRoot%\system32\WindowsPowerShell\v1.0\powershell.exe C:\CrlCopy\crl_copy_v3.ps1 -Action Publish -XmlFile C:\CrlCopy\issuingca1_CRL_Config.xml',
        run_level: :highest,
        frequency: :daily,
        frequency_modifier: 1
      )
    end

    it_behaves_like 'installs CRL Copy and config xml'
  end
end
