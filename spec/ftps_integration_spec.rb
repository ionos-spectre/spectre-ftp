require_relative '../lib/spectre/ftp'
require 'logger'
require 'fileutils'

# Integration tests for FTPS (requires running FTPS server with SSL)
# NOTE: These tests are currently skipped because FTPS requires SSL certificate setup
#
# To enable these tests:
# 1. Generate SSL certificates (see docker/ftps/generate-certs.sh)
# 2. Configure pure-ftpd with TLS support
# 3. Update docker-compose.yml with FTPS service
# 4. Remove the 'skip' tags below
#
# FTPS server details (when configured):
# - Host: localhost
# - Implicit FTPS Port: 2990
# - Explicit FTPES Port: 2121 (with TLS)
# - Username: ftpuser
# - Password: ftppass

RSpec.describe 'FTPS Integration', :integration, skip: 'Requires SSL-enabled FTP server' do
  let(:logger) { Logger.new($stdout) }
  let(:client) { Spectre::FTP::Client.new({}, logger) }
  let(:test_dir) { 'test_files' }
  let(:test_file) { 'test_upload.txt' }
  let(:test_content) { "Test content #{Time.now.to_i}" }

  before(:all) do
    FileUtils.mkdir_p('test_files')
  end

  after(:all) do
    FileUtils.rm_rf('test_files')
  end

  before(:each) do
    File.write(File.join(test_dir, test_file), test_content)
  end

  after(:each) do
    Dir.glob(File.join(test_dir, '*')).each { |f| File.delete(f) if File.file?(f) }
  end

  describe 'implicit FTPS (ftps)' do
    it 'successfully connects to FTPS server on port 990' do
      result = client.ftps 'localhost', port: 2990, username: 'ftpuser', password: 'ftppass' do
        can_connect?
      end

      expect(result).to be true
    end

    it 'uploads file via implicit FTPS' do
      uploaded_filename = nil
      client.ftps 'localhost', port: 2990, username: 'ftpuser', password: 'ftppass' do
        uploaded_filename = test_file
        upload File.join(test_dir, test_file), to: test_file
      end

      # Verify file was uploaded
      client.ftps 'localhost', port: 2990, username: 'ftpuser', password: 'ftppass' do
        file_exists = exists uploaded_filename
        expect(file_exists).to be true
      end
    end

    it 'downloads file via implicit FTPS' do
      download_path = File.join(test_dir, 'downloaded.txt')

      # Upload first
      client.ftps 'localhost', port: 2990, username: 'ftpuser', password: 'ftppass' do
        upload File.join(test_dir, test_file), to: test_file
      end

      # Then download
      client.ftps 'localhost', port: 2990, username: 'ftpuser', password: 'ftppass' do
        download test_file, to: download_path
      end

      expect(File.exist?(download_path)).to be true
      expect(File.read(download_path)).to eq(test_content)
    end

    it 'lists files via implicit FTPS' do
      files = nil
      client.ftps 'localhost', port: 2990, username: 'ftpuser', password: 'ftppass' do
        upload File.join(test_dir, test_file), to: test_file
        files = list
      end

      expect(files).not_to be_empty
      expect(files.join).to include(test_file)
    end
  end

  describe 'explicit FTPS (ftpes)' do
    it 'successfully connects via explicit FTPS on port 21' do
      result = client.ftpes 'localhost', port: 2121, username: 'ftpuser', password: 'ftppass' do
        can_connect?
      end

      expect(result).to be true
    end

    it 'uploads file via explicit FTPS' do
      uploaded_filename = nil
      client.ftpes 'localhost', port: 2121, username: 'ftpuser', password: 'ftppass' do
        uploaded_filename = test_file
        upload File.join(test_dir, test_file), to: test_file
      end

      # Verify file was uploaded
      client.ftpes 'localhost', port: 2121, username: 'ftpuser', password: 'ftppass' do
        file_exists = exists uploaded_filename
        expect(file_exists).to be true
      end
    end

    it 'downloads file via explicit FTPS' do
      download_path = File.join(test_dir, 'downloaded_explicit.txt')

      # Upload first
      client.ftpes 'localhost', port: 2121, username: 'ftpuser', password: 'ftppass' do
        upload File.join(test_dir, test_file), to: test_file
      end

      # Then download
      client.ftpes 'localhost', port: 2121, username: 'ftpuser', password: 'ftppass' do
        download test_file, to: download_path
      end

      expect(File.exist?(download_path)).to be true
      expect(File.read(download_path)).to eq(test_content)
    end

    it 'creates and removes directory via explicit FTPS' do
      dirname = "test_dir_#{Time.now.to_i}"

      client.ftpes 'localhost', port: 2121, username: 'ftpuser', password: 'ftppass' do
        mkdir dirname
      end

      # Verify directory exists
      client.ftpes 'localhost', port: 2121, username: 'ftpuser', password: 'ftppass' do
        files = list
        expect(files.join).to include(dirname)
      end

      # Remove directory
      client.ftpes 'localhost', port: 2121, username: 'ftpuser', password: 'ftppass' do
        rmdir dirname
      end
    end
  end

  describe 'SSL options' do
    it 'connects with custom SSL verify mode' do
      # Skip certificate verification for self-signed certs
      result = client.ftps 'localhost',
                           port: 2990,
                           username: 'ftpuser',
                           password: 'ftppass',
                           ssl: { implicit: true, verify_mode: OpenSSL::SSL::VERIFY_NONE } do
        can_connect?
      end

      expect(result).to be true
    end
  end
end
