# Spectre FTP

[![Build](https://github.com/ionos-spectre/spectre-ftp/actions/workflows/build.yml/badge.svg)](https://github.com/ionos-spectre/spectre-ftp/actions/workflows/build.yml)
[![Gem Version](https://badge.fury.io/rb/spectre-ftp.svg)](https://badge.fury.io/rb/spectre-ftp)

This is a [spectre](https://github.com/ionos-spectre/spectre-core) module which allows you to test file transfer operations using FTP (File Transfer Protocol) and SFTP (Secure FTP). This is useful for testing systems that upload or download files from FTP servers.

Using [net-ftp](https://github.com/ruby/net-ftp) and [net-sftp](https://www.rubydoc.info/gems/net-sftp/2.0.5/Net/SFTP).


## Install

```bash
$ sudo gem install spectre-ftp
```


## Configure

Add the module to your `spectre.yml`

```yml
include:
 - spectre/ftp
```

Configure your FTP/SFTP servers in your environment file:

```yaml
# environments/development.env.yml
ftp:
  my-ftp-server:
    host: ftp.example.com
    username: testuser
    password: secretpass
    port: 21
  
  my-sftp-server:
    host: sftp.example.com
    username: testuser
    password: secretpass
    port: 22
    key: /path/to/private_key  # Optional: use SSH key instead of password
    passphrase: keypassword    # Optional: if your key has a passphrase
```

---

## FTP Operations

### Connecting and Testing Connection

```ruby
it 'connects to FTP server' do
  ftp 'my-ftp-server' do
    # Check if we can connect
    can_connect = can_connect?
    
    assert can_connect.to be true
  end
end
```

### Downloading Files

```ruby
it 'downloads a file from FTP server' do
  ftp 'my-ftp-server' do
    # Download remote file to local directory
    download 'remote-file.txt'
    
    # Or specify a different local name
    download 'remote-file.txt', to: 'local-copy.txt'
  end
  
  # Verify the file was downloaded
  assert File.exist?('local-copy.txt').to be true
end
```

### Uploading Files

```ruby
it 'uploads a file to FTP server' do
  # Create a test file
  File.write('test-upload.txt', 'This is test content')
  
  ftp 'my-ftp-server' do
    # Upload local file to server
    upload 'test-upload.txt'
    
    # Or specify a different remote name
    upload 'test-upload.txt', to: 'remote-file.txt'
  end
end
```

### Listing Files

```ruby
it 'lists files on FTP server' do
  ftp 'my-ftp-server' do
    file_list = list
    
    info "Files on server: #{file_list}"
  end
  
  assert file_list.to_not be_empty
end
```

### Complete FTP Test Example

```ruby
describe 'FTP File Transfer' do
  setup do
    bag.test_file = "test_#{uuid}.txt"
    File.write(bag.test_file, 'Test content for FTP upload')
  end
  
  teardown do
    File.delete(bag.test_file) if File.exist?(bag.test_file)
    File.delete('downloaded.txt') if File.exist?('downloaded.txt')
  end
  
  it 'uploads and downloads files successfully' do
    # Upload file
    ftp 'my-ftp-server' do
      upload bag.test_file, to: 'uploaded.txt'
    end
    
    info 'File uploaded successfully'
    
    # Download the same file
    ftp 'my-ftp-server' do
      download 'uploaded.txt', to: 'downloaded.txt'
    end
    
    info 'File downloaded successfully'
    
    # Verify content matches
    original = File.read(bag.test_file)
    downloaded = File.read('downloaded.txt')
    
    assert downloaded.to be original
  end
end
```

---

## SFTP Operations

SFTP (Secure FTP) uses SSH for secure file transfers. The methods are similar to FTP but with added security features.

### Connecting with Password

```ruby
it 'connects to SFTP server with password' do
  sftp 'my-sftp-server' do
    can_connect = can_connect?
    
    assert can_connect.to be true
  end
end
```

### Connecting with SSH Key

```ruby
it 'connects to SFTP server with SSH key' do
  sftp 'my-sftp-server' do
    private_key '/path/to/id_rsa'
    passphrase 'keypassword'  # If key is encrypted
    
    can_connect = can_connect?
    
    assert can_connect.to be true
  end
end
```

### Downloading Files

```ruby
it 'downloads file via SFTP' do
  sftp 'my-sftp-server' do
    download '/remote/path/file.txt', to: 'local-file.txt'
  end
  
  assert File.exist?('local-file.txt').to be true
end
```

### Uploading Files

```ruby
it 'uploads file via SFTP' do
  File.write('upload.txt', 'Content to upload')
  
  sftp 'my-sftp-server' do
    upload 'upload.txt', to: '/remote/path/uploaded.txt'
  end
end
```

### Checking File Information

```ruby
it 'gets file information' do
  sftp 'my-sftp-server' do
    file_info = stat '/remote/path/file.txt'
    
    info "File size: #{file_info[:size]}"
    info "Modified: #{file_info[:mtime]}"
    info "Permissions: #{file_info[:permissions]}"
  end
end
```

### Checking if File Exists

```ruby
it 'checks if remote file exists' do
  sftp 'my-sftp-server' do
    file_exists = exists '/remote/path/file.txt'
    
    if file_exists
      info 'File exists on server'
    else
      info 'File does not exist'
    end
    
    assert file_exists.to be true
  end
end
```

### Complete SFTP Test Example

```ruby
describe 'SFTP File Operations' do
  setup do
    bag.local_file = "test_#{uuid}.txt"
    bag.remote_file = "/upload/test_#{uuid}.txt"
    
    File.write(bag.local_file, 'SFTP test content')
  end
  
  teardown do
    File.delete(bag.local_file) if File.exist?(bag.local_file)
  end
  
  context 'with SSH key authentication' do
    it 'uploads, verifies, and downloads file' do
      # Upload file
      sftp 'my-sftp-server' do
        private_key '/home/user/.ssh/id_rsa'
        upload bag.local_file, to: bag.remote_file
      end
      
      info 'File uploaded'
      
      # Check if file exists
      sftp 'my-sftp-server' do
        private_key '/home/user/.ssh/id_rsa'
        file_exists = exists bag.remote_file
        
        assert file_exists.to be true
      end
      
      # Get file information
      sftp 'my-sftp-server' do
        private_key '/home/user/.ssh/id_rsa'
        file_info = stat bag.remote_file
        
        info "File size: #{file_info[:size]} bytes"
        expect file_info[:size].to be_greater_than 0
      end
      
      # Download for verification
      sftp 'my-sftp-server' do
        private_key '/home/user/.ssh/id_rsa'
        download bag.remote_file, to: 'verified.txt'
      end
      
      # Verify content
      original = File.read(bag.local_file)
      downloaded = File.read('verified.txt')
      
      assert downloaded.to be original
      
      File.delete('verified.txt')
    end
  end
end
```

---

## Common Use Cases

### 1. Testing File Upload Systems

```ruby
it 'uploads file to integration partner' do
  order_data = generate_order_export()
  File.write('order-export.csv', order_data)
  
  ftp 'partner-ftp' do
    upload 'order-export.csv', to: "/incoming/order_#{uuid}.csv"
  end
  
  info 'Order export uploaded to partner FTP'
end
```

### 2. Testing Automated File Retrieval

```ruby
it 'downloads daily report from vendor' do
  today = Date.today.strftime('%Y%m%d')
  
  sftp 'vendor-sftp' do
    download "/reports/daily_#{today}.csv", to: 'report.csv'
  end
  
  assert File.exist?('report.csv').to be true
  
  # Process and validate the report
  report_data = File.read('report.csv')
  expect report_data.to contain 'Transaction'
end
```

### 3. Testing File Format Validation

```ruby
it 'validates uploaded file format' do
  # Create invalid file
  File.write('invalid.txt', 'wrong format')
  
  ftp 'validation-server' do
    upload 'invalid.txt', to: '/incoming/test.txt'
  end
  
  # Wait for validation process
  sleep 2
  
  # Check if file was moved to error folder
  ftp 'validation-server' do
    error_files = list('/errors')
    
    expect error_files.to contain 'test.txt'
  end
end
```

### 4. Connection Testing

```ruby
describe 'FTP Server Availability' do
  it 'verifies connection to production FTP', tags: [:smoke] do
    sftp 'production-sftp' do
      can_connect = can_connect?
      
      assert can_connect.to be true
    end
  end
end
```

---

## Tips and Best Practices

### 1. Use Unique Filenames
Always use unique filenames (with UUIDs or timestamps) to avoid conflicts:

```ruby
bag.filename = "test_#{uuid}_#{Time.now.to_i}.txt"
```

### 2. Clean Up Test Files
Always clean up files created during tests:

```ruby
teardown do
  File.delete(bag.test_file) if File.exist?(bag.test_file)
end
```

### 3. Test Connection Before Operations
Check connection before attempting file operations:

```ruby
it 'ensures server is accessible' do
  ftp 'my-server' do
    skip 'FTP server not available' unless can_connect?
    
    # Continue with file operations
  end
end
```

### 4. Handle Large Files Carefully
For large file transfers, consider timeouts:

```ruby
it 'downloads large file' do
  measure do
    ftp 'my-server' do
      download 'large-file.zip', to: 'local-large.zip'
    end
  end
  
  info "Download took #{duration} seconds"
  property download_time: duration
end
```

### 5. Use SFTP When Possible
Prefer SFTP over FTP for better security:

```ruby
# Good - secure
sftp 'server' do
  upload 'sensitive-data.csv'
end

# Avoid - insecure for sensitive data
ftp 'server' do
  upload 'sensitive-data.csv'
end
```

---

## Troubleshooting

### Connection Issues

**Problem**: Cannot connect to FTP server  
**Solution**: 
- Verify host, username, and password in environment config
- Check if server is accessible from your network
- Verify port numbers (21 for FTP, 22 for SFTP)

### Authentication Failures (SFTP)

**Problem**: SSH key authentication fails  
**Solution**:
- Verify the path to your private key file
- Check if key requires a passphrase
- Ensure key is in correct format (usually RSA or ED25519)

### File Not Found

**Problem**: Cannot download file  
**Solution**:
- Verify the remote file path is correct
- Check if you have read permissions
- Use `list` to see available files

### Upload Failures

**Problem**: Cannot upload file  
**Solution**:
- Verify local file exists before upload
- Check if you have write permissions on remote server
- Verify remote directory exists

---

## Summary

The FTP module provides simple methods to:

✅ Upload files to FTP/SFTP servers  
✅ Download files from FTP/SFTP servers  
✅ List files on remote servers  
✅ Check file existence and properties  
✅ Test connection to FTP/SFTP servers  
✅ Use password or SSH key authentication  

Use this module to test any system that transfers files via FTP or SFTP, including data exports, report generation, and partner integrations.
