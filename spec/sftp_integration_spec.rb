require_relative '../lib/spectre/ftp'
require 'logger'
require 'fileutils'

# Integration tests for SFTP (requires running SFTP server)
# Start the SFTP server with: docker-compose up -d sftp
# Run these tests with: bundle exec rspec spec/sftp_integration_spec.rb
#
# SFTP server details:
# - Host: localhost
# - Port: 2222
# - Username: sftpuser
# - Password: sftppass

RSpec.describe 'SFTP Integration', :integration do
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
    it 'successfully connects to SFTP server' do
      result = client.sftp 'localhost', port: 2222, username: 'sftpuser', password: 'sftppass' do
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

      client.sftp 'localhost', port: 2222, username: 'sftpuser', password: 'sftppass' do
        upload local_file, to: remote_file
      end

      # Verify by downloading it back
      client.sftp 'localhost', port: 2222, username: 'sftpuser', password: 'sftppass' do
        download remote_file, to: local_download
      end

      downloaded_content = File.read(local_download)
      expect(downloaded_content).to eq(content)
    end

    it 'downloads a file' do
      local_file = File.join(test_dir, test_file)
      local_retrieved = File.join(test_dir, 'retrieved.txt')

      # First upload a file
      client.sftp 'localhost', port: 2222, username: 'sftpuser', password: 'sftppass' do
        upload local_file, to: 'download_test.txt'
      end

      # Then download it
      client.sftp 'localhost', port: 2222, username: 'sftpuser', password: 'sftppass' do
        download 'download_test.txt', to: local_retrieved
      end

      retrieved_content = File.read(local_retrieved)
      expect(retrieved_content).to eq(test_content)
    end

    it 'deletes a file' do
      local_file = File.join(test_dir, test_file)

      # Upload a file first
      client.sftp 'localhost', port: 2222, username: 'sftpuser', password: 'sftppass' do
        upload local_file, to: 'to_delete.txt'
      end

      # Delete it
      client.sftp 'localhost', port: 2222, username: 'sftpuser', password: 'sftppass' do
        delete 'to_delete.txt'
      end

      # Verify it's gone
      exists = client.sftp 'localhost', port: 2222, username: 'sftpuser', password: 'sftppass' do
        exists 'to_delete.txt'
      end

      expect(exists).to be false
    end

    it 'renames a file' do
      local_file = File.join(test_dir, test_file)

      # Upload a file first
      client.sftp 'localhost', port: 2222, username: 'sftpuser', password: 'sftppass' do
        upload local_file, to: 'old_name.txt'
      end

      # Rename it
      client.sftp 'localhost', port: 2222, username: 'sftpuser', password: 'sftppass' do
        rename 'old_name.txt', 'new_name.txt'
      end

      # Verify old name doesn't exist and new name does
      exists_old = client.sftp 'localhost', port: 2222, username: 'sftpuser', password: 'sftppass' do
        exists 'old_name.txt'
      end

      exists_new = client.sftp 'localhost', port: 2222, username: 'sftpuser', password: 'sftppass' do
        exists 'new_name.txt'
      end

      expect(exists_old).to be false
      expect(exists_new).to be true
    end

    it 'checks if file exists' do
      local_file = File.join(test_dir, test_file)

      # Upload a file first
      client.sftp 'localhost', port: 2222, username: 'sftpuser', password: 'sftppass' do
        upload local_file, to: 'exists_test.txt'
      end

      # Check if it exists
      exists = client.sftp 'localhost', port: 2222, username: 'sftpuser', password: 'sftppass' do
        exists 'exists_test.txt'
      end

      expect(exists).to be true

      # Check non-existent file
      not_exists = client.sftp 'localhost', port: 2222, username: 'sftpuser', password: 'sftppass' do
        exists 'non_existent.txt'
      end

      expect(not_exists).to be false
    end

    it 'gets file size' do
      local_file = File.join(test_dir, test_file)

      # Upload a file first
      client.sftp 'localhost', port: 2222, username: 'sftpuser', password: 'sftppass' do
        upload local_file, to: 'size_test.txt'
      end

      # Get file size
      size = client.sftp 'localhost', port: 2222, username: 'sftpuser', password: 'sftppass' do
        file_size 'size_test.txt'
      end

      expect(size).to eq(test_content.bytesize)
    end

    it 'gets file modification time' do
      local_file = File.join(test_dir, test_file)

      # Upload a file first
      client.sftp 'localhost', port: 2222, username: 'sftpuser', password: 'sftppass' do
        upload local_file, to: 'mtime_test.txt'
      end

      # Get modification time
      mtime = client.sftp 'localhost', port: 2222, username: 'sftpuser', password: 'sftppass' do
        mtime 'mtime_test.txt'
      end

      expect(mtime).to be_a(Time)
      # File should have been modified within the last minute
      expect(Time.now - mtime).to be < 60
    end

    it 'gets file stat information' do
      local_file = File.join(test_dir, test_file)

      # Upload a file first
      client.sftp 'localhost', port: 2222, username: 'sftpuser', password: 'sftppass' do
        upload local_file, to: 'stat_test.txt'
      end

      # Get stat information
      stat_info = client.sftp 'localhost', port: 2222, username: 'sftpuser', password: 'sftppass' do
        stat 'stat_test.txt'
      end

      expect(stat_info).to be_a(Hash)
      expect(stat_info[:size]).to eq(test_content.bytesize)
      expect(stat_info[:mtime]).to be_a(Integer)
      expect(stat_info[:permissions]).to be_a(Integer)
    end
  end

  describe 'directory operations' do
    it 'creates a directory' do
      # Use upload subdirectory which should have write permissions
      client.sftp 'localhost', port: 2222, username: 'sftpuser', password: 'sftppass' do
        mkdir 'upload/test_directory'
      end

      # Verify by checking if it exists
      exists = client.sftp 'localhost', port: 2222, username: 'sftpuser', password: 'sftppass' do
        exists 'upload/test_directory'
      end

      expect(exists).to be true
    end

    it 'removes a directory' do
      # Create a directory first
      client.sftp 'localhost', port: 2222, username: 'sftpuser', password: 'sftppass' do
        mkdir 'upload/temp_directory'
      end

      # Remove it
      client.sftp 'localhost', port: 2222, username: 'sftpuser', password: 'sftppass' do
        rmdir 'upload/temp_directory'
      end

      # Verify it's gone
      exists = client.sftp 'localhost', port: 2222, username: 'sftpuser', password: 'sftppass' do
        exists 'upload/temp_directory'
      end

      expect(exists).to be false
    end

    it 'gets current directory' do
      current = client.sftp 'localhost', port: 2222, username: 'sftpuser', password: 'sftppass' do
        pwd
      end

      expect(current).to be_a(String)
      expect(current).to include('sftpuser')
    end

    it 'lists files in directory' do
      local_file = File.join(test_dir, test_file)

      # Upload some files
      client.sftp 'localhost', port: 2222, username: 'sftpuser', password: 'sftppass' do
        upload local_file, to: 'list_test1.txt'
        upload local_file, to: 'list_test2.txt'
      end

      # List files
      files = client.sftp 'localhost', port: 2222, username: 'sftpuser', password: 'sftppass' do
        list '.'
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

      file_exists, size, stat_size, renamed_exists, old_exists = client.sftp(
        'localhost',
        port: 2222,
        username: 'sftpuser',
        password: 'sftppass'
      ) do
        # Create directory in upload folder
        mkdir 'upload/complex_test'

        # Upload file to new directory
        upload local_file, to: 'upload/complex_test/data.txt'

        # Capture file existence
        file_exists = exists('upload/complex_test/data.txt')

        # Get file info
        size = file_size 'upload/complex_test/data.txt'

        # Get stat info
        stat_info = stat 'upload/complex_test/data.txt'
        stat_size = stat_info[:size]

        # Rename file
        rename 'upload/complex_test/data.txt', 'upload/complex_test/renamed_data.txt'

        # Capture rename results
        renamed_exists = exists('upload/complex_test/renamed_data.txt')
        old_exists = exists('upload/complex_test/data.txt')

        # Download renamed file
        download 'upload/complex_test/renamed_data.txt', to: local_result

        # Cleanup
        delete 'upload/complex_test/renamed_data.txt'
        rmdir 'upload/complex_test'

        [file_exists, size, stat_size, renamed_exists, old_exists]
      end

      # Verify results
      expect(file_exists).to be true
      expect(size).to be > 0
      expect(stat_size).to eq(size)
      expect(renamed_exists).to be true
      expect(old_exists).to be false
      expect(File.exist?(local_result)).to be true
      expect(File.read(local_result)).to eq(test_content)
    end
  end

  describe 'comparison with FTP' do
    it 'demonstrates identical API between FTP and SFTP' do
      # This test shows that the same operations work identically
      # Only the connection method and port differ
      local_file = File.join(test_dir, test_file)
      local_result = File.join(test_dir, 'api_result.txt')
      content = test_content

      operations = proc do
        # Upload
        upload local_file, to: 'api_test.txt'

        # Check exists
        file_exists = exists 'api_test.txt'

        # Get size
        size = file_size 'api_test.txt'

        # Get mtime
        modification_time = mtime 'api_test.txt'

        # Download
        download 'api_test.txt', to: local_result

        # Delete
        delete 'api_test.txt'

        # Verify deletion
        deleted = !exists('api_test.txt')

        [file_exists, size, modification_time, deleted]
      end

      # Execute the same operations with SFTP
      file_exists, size, modification_time, deleted = client.sftp(
        'localhost',
        port: 2222,
        username: 'sftpuser',
        password: 'sftppass',
        &operations
      )

      # Verify results
      expect(file_exists).to be true
      expect(size).to eq(content.bytesize)
      expect(modification_time).to be_a(Time)
      expect(deleted).to be true
      result = File.read(local_result)
      expect(result).to eq(test_content)
    end
  end
end
