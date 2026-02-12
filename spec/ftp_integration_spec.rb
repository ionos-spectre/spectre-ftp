require_relative '../lib/spectre/ftp'
require 'logger'
require 'fileutils'

# Integration tests for FTP (requires running FTP server)
# Start the FTP server with: docker-compose up -d ftp
# Run these tests with: bundle exec rspec spec/ftp_integration_spec.rb
#
# FTP server details:
# - Host: localhost
# - Port: 2121
# - Username: ftpuser
# - Password: ftppass

RSpec.describe 'FTP Integration', :integration do
  let(:logger) { Logger.new($stdout) }
  let(:client) { Spectre::FTP::Client.new({}, logger) }
  let(:test_dir) { 'test_files' }
  let(:test_file) { 'test_upload.txt' }
  let(:test_content) { "Test content #{Time.now.to_i}" }

  before(:all) do
    # Create test directory and file
    FileUtils.mkdir_p('test_files')
  end

  after(:all) do
    # Cleanup test directory
    FileUtils.rm_rf('test_files')
  end

  before(:each) do
    # Create test file for each test
    File.write(File.join(test_dir, test_file), test_content)
  end

  after(:each) do
    # Cleanup test files
    Dir.glob(File.join(test_dir, '*')).each { |f| File.delete(f) if File.file?(f) }
  end

  describe 'connection' do
    it 'successfully connects to FTP server' do
      result = client.ftp 'localhost', port: 2121, username: 'ftpuser', password: 'ftppass' do
        can_connect?
      end

      expect(result).to be true
    end
  end

  describe 'file operations' do
    it 'uploads a file' do
      local_file = File.join(test_dir, test_file)
      local_download = File.join(test_dir, 'downloaded.txt')
      remote_file = test_file
      content = test_content

      client.ftp 'localhost', port: 2121, username: 'ftpuser', password: 'ftppass' do
        upload local_file, to: remote_file
      end

      # Verify by downloading it back
      client.ftp 'localhost', port: 2121, username: 'ftpuser', password: 'ftppass' do
        download remote_file, to: local_download
      end

      downloaded_content = File.read(local_download)
      expect(downloaded_content).to eq(content)
    end

    it 'downloads a file' do
      local_file = File.join(test_dir, test_file)
      local_retrieved = File.join(test_dir, 'retrieved.txt')

      # First upload a file
      client.ftp 'localhost', port: 2121, username: 'ftpuser', password: 'ftppass' do
        upload local_file, to: 'download_test.txt'
      end

      # Then download it
      client.ftp 'localhost', port: 2121, username: 'ftpuser', password: 'ftppass' do
        download 'download_test.txt', to: local_retrieved
      end

      retrieved_content = File.read(local_retrieved)
      expect(retrieved_content).to eq(test_content)
    end

    it 'deletes a file' do
      local_file = File.join(test_dir, test_file)

      # Upload a file first
      client.ftp 'localhost', port: 2121, username: 'ftpuser', password: 'ftppass' do
        upload local_file, to: 'to_delete.txt'
      end

      # Delete it
      client.ftp 'localhost', port: 2121, username: 'ftpuser', password: 'ftppass' do
        delete 'to_delete.txt'
      end

      # Verify it's gone
      exists = client.ftp 'localhost', port: 2121, username: 'ftpuser', password: 'ftppass' do
        exists 'to_delete.txt'
      end

      expect(exists).to be false
    end

    it 'renames a file' do
      local_file = File.join(test_dir, test_file)

      # Upload a file first
      client.ftp 'localhost', port: 2121, username: 'ftpuser', password: 'ftppass' do
        upload local_file, to: 'old_name.txt'
      end

      # Rename it
      client.ftp 'localhost', port: 2121, username: 'ftpuser', password: 'ftppass' do
        rename 'old_name.txt', 'new_name.txt'
      end

      # Verify old name doesn't exist and new name does
      exists_old = client.ftp 'localhost', port: 2121, username: 'ftpuser', password: 'ftppass' do
        exists 'old_name.txt'
      end

      exists_new = client.ftp 'localhost', port: 2121, username: 'ftpuser', password: 'ftppass' do
        exists 'new_name.txt'
      end

      expect(exists_old).to be false
      expect(exists_new).to be true
    end

    it 'checks if file exists' do
      local_file = File.join(test_dir, test_file)

      # Upload a file first
      client.ftp 'localhost', port: 2121, username: 'ftpuser', password: 'ftppass' do
        upload local_file, to: 'exists_test.txt'
      end

      # Check if it exists
      exists = client.ftp 'localhost', port: 2121, username: 'ftpuser', password: 'ftppass' do
        exists 'exists_test.txt'
      end

      expect(exists).to be true

      # Check non-existent file
      not_exists = client.ftp 'localhost', port: 2121, username: 'ftpuser', password: 'ftppass' do
        exists 'non_existent.txt'
      end

      expect(not_exists).to be false
    end

    it 'gets file size' do
      local_file = File.join(test_dir, test_file)

      # Upload a file first
      client.ftp 'localhost', port: 2121, username: 'ftpuser', password: 'ftppass' do
        upload local_file, to: 'size_test.txt'
      end

      # Get file size
      size = client.ftp 'localhost', port: 2121, username: 'ftpuser', password: 'ftppass' do
        file_size 'size_test.txt'
      end

      expect(size).to eq(test_content.bytesize)
    end

    it 'gets file modification time' do
      local_file = File.join(test_dir, test_file)

      # Upload a file first
      client.ftp 'localhost', port: 2121, username: 'ftpuser', password: 'ftppass' do
        upload local_file, to: 'mtime_test.txt'
      end

      # Get modification time
      mtime = client.ftp 'localhost', port: 2121, username: 'ftpuser', password: 'ftppass' do
        mtime 'mtime_test.txt'
      end

      expect(mtime).to be_a(Time)
      # File should have been modified within the last minute
      expect(Time.now - mtime).to be < 60
    end
  end

  describe 'directory operations' do
    it 'creates a directory' do
      client.ftp 'localhost', port: 2121, username: 'ftpuser', password: 'ftppass' do
        mkdir 'test_directory'
      end

      # Verify by listing
      files = client.ftp 'localhost', port: 2121, username: 'ftpuser', password: 'ftppass' do
        list
      end

      expect(files.join("\n")).to include('test_directory')
    end

    it 'removes a directory' do
      # Create a directory first
      client.ftp 'localhost', port: 2121, username: 'ftpuser', password: 'ftppass' do
        mkdir 'temp_directory'
      end

      # Remove it
      client.ftp 'localhost', port: 2121, username: 'ftpuser', password: 'ftppass' do
        rmdir 'temp_directory'
      end

      # Verify it's gone
      files = client.ftp 'localhost', port: 2121, username: 'ftpuser', password: 'ftppass' do
        list
      end

      expect(files.join("\n")).not_to include('temp_directory')
    end

    it 'changes directory and gets current directory' do
      # Create a directory and change to it
      current = client.ftp 'localhost', port: 2121, username: 'ftpuser', password: 'ftppass' do
        mkdir 'nav_test'
        chdir 'nav_test'

        current_dir = pwd

        # Go back
        chdir '..'

        current_dir
      end

      expect(current).to include('nav_test')
    end

    it 'lists files in directory' do
      local_file = File.join(test_dir, test_file)

      # Upload some files
      client.ftp 'localhost', port: 2121, username: 'ftpuser', password: 'ftppass' do
        upload local_file, to: 'list_test1.txt'
        upload local_file, to: 'list_test2.txt'
      end

      # List files
      files = client.ftp 'localhost', port: 2121, username: 'ftpuser', password: 'ftppass' do
        list
      end

      files_str = files.join("\n")
      expect(files_str).to include('list_test1.txt')
      expect(files_str).to include('list_test2.txt')
    end
  end

  describe 'complex scenarios' do
    it 'performs multiple operations in sequence' do
      local_file = File.join(test_dir, test_file)
      local_result = File.join(test_dir, 'complex_result.txt')

      file_exists, size, renamed_exists, old_exists = client.ftp 'localhost', port: 2121, username: 'ftpuser',
                                                                              password: 'ftppass' do
        # Create directory
        mkdir 'complex_test'
        chdir 'complex_test'

        # Upload file
        upload local_file, to: 'data.txt'

        # Capture values for assertions
        file_exists = exists('data.txt')
        size = file_size 'data.txt'

        # Rename file
        rename 'data.txt', 'renamed_data.txt'

        # Capture rename results
        renamed_exists = exists('renamed_data.txt')
        old_exists = exists('data.txt')

        # Download renamed file
        download 'renamed_data.txt', to: local_result

        # Cleanup
        delete 'renamed_data.txt'
        chdir '..'
        rmdir 'complex_test'

        [file_exists, size, renamed_exists, old_exists]
      end

      # Verify results
      expect(file_exists).to be true
      expect(size).to be > 0
      expect(renamed_exists).to be true
      expect(old_exists).to be false
      expect(File.exist?(local_result)).to be true
      expect(File.read(local_result)).to eq(test_content)
    end
  end
end
