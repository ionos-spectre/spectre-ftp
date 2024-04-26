module Spectre
  CONFIG = {
    'ftp' => {
      'example' => {
        'host' => 'some-data.host',
        'username' => 'dummy',
        'password' => '<some-secret-password>',
      },
    },
  }
end

require_relative '../lib/spectre/ftp'

RSpec.describe 'FTP' do
  context 'ftp' do
    before do
      opts = [
        'some-data.host',
        {
          port: 21,
          ssl: nil,
        }
      ]

      ftp_session = double(Net::FTP)
      expect(ftp_session).to receive(:closed?)
      expect(ftp_session).to receive(:close)
      expect(ftp_session).to receive(:pwd).and_return('/')
      expect(ftp_session).to receive(:login)
        .with(
          Spectre::CONFIG['ftp']['example']['username'],
          Spectre::CONFIG['ftp']['example']['password']
        )

      expect(Net::FTP).to receive(:new).with(*opts).and_return(ftp_session)
      expect(ftp_session).to receive(:putbinaryfile).with('dummy.txt', 'dummy.txt')
    end

    it 'does upload a file via ftp' do
      Spectre::FTP.ftp 'some-data.host' do
        username 'dummy'
        password '<some-secret-password>'
        upload 'dummy.txt'
      end
    end

    it 'does upload a file via ftp with preconfig' do
      Spectre::FTP.ftp 'example' do
        upload 'dummy.txt'
      end
    end
  end

  context 'sftp' do
    before do
      opts = [
        'some-data.host',
        'dummy',
        {
          auth_methods: ['password'],
          port: 22,
          non_interactive: true,
          password: Spectre::CONFIG['ftp']['example']['password'],
        }
      ]

      ftp_session = double(Net::SFTP::Session)
      expect(ftp_session).to receive(:closed?)
      expect(ftp_session).to receive(:close!)
      expect(ftp_session).to receive(:connect!)

      expect(Net::SFTP).to receive(:start).with(*opts).and_return(ftp_session)

      expect(ftp_session).to receive(:upload!).with('dummy.txt', 'dummy.txt')
    end

    it 'does upload a file via sftp' do
      Spectre::FTP.sftp 'some-data.host' do
        username 'dummy'
        password '<some-secret-password>'
        upload 'dummy.txt'
      end
    end

    it 'does upload a file via sftp with preconfig' do
      Spectre::FTP.sftp 'example' do
        upload 'dummy.txt'
      end
    end
  end
end
