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

it 'lists files in specific directory' do
  ftp 'my-ftp-server' do
    file_list = list('/remote/path')
    
    info "Files in /remote/path: #{file_list}"
  end
end
```

### Directory Operations

```ruby
it 'creates and removes directories' do
  ftp 'my-ftp-server' do
    # Create a new directory
    mkdir 'new-folder'
    
    # Change to the directory
    chdir 'new-folder'
    
    # Get current directory
    current = pwd
    info "Current directory: #{current}"
    
    # Go back
    chdir '..'
    
    # Remove the directory
    rmdir 'new-folder'
  end
end
```

### File Management

```ruby
it 'deletes and renames files' do
  ftp 'my-ftp-server' do
    # Delete a file
    delete 'old-file.txt'
    
    # Rename a file
    rename 'file.txt', 'renamed-file.txt'
  end
end
```

### File Information

```ruby
it 'gets file information' do
  ftp 'my-ftp-server' do
    # Check if file exists
    if exists 'data.csv'
      info 'File exists'
      
      # Get file size
      size = file_size 'data.csv'
      info "File size: #{size} bytes"
      
      # Get modification time
      modified = mtime 'data.csv'
      info "Last modified: #{modified}"
    end
  end
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

### Directory Operations

```ruby
it 'manages directories' do
  sftp 'my-sftp-server' do
    # Create a new directory
    mkdir '/remote/new-folder'
    
    # Get current directory
    current = pwd
    info "Current directory: #{current}"
    
    # Remove the directory
    rmdir '/remote/new-folder'
  end
end
```

### File Management

```ruby
it 'deletes and renames files' do
  sftp 'my-sftp-server' do
    # Delete a file
    delete '/remote/old-file.txt'
    
    # Rename a file
    rename '/remote/file.txt', '/remote/renamed-file.txt'
  end
end
```

### Listing Files

```ruby
it 'lists files in directory' do
  sftp 'my-sftp-server' do
    files = list '/remote/path'
    
    files.each do |file|
      info file
    end
  end
end
```

### File Size and Modification Time

```ruby
it 'gets file metadata' do
  sftp 'my-sftp-server' do
    # Check if file exists
    if exists '/remote/data.csv'  
      # Get file size
      size = file_size '/remote/data.csv'
      info "File size: #{size} bytes"
      
      # Get modification time
      modified = mtime '/remote/data.csv'
      info "Last modified: #{modified}"
    end
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

## Consistent API for FTP and SFTP

One of the key features of this module is that **FTP and SFTP methods work exactly the same way**, making it easy to switch between protocols or test both without changing your code.

### Example: Same Operations for Both Protocols

```ruby
describe 'File Operations Work Identically' do
  let(:test_file) { 'test-file.txt' }
  let(:remote_file) { 'uploaded.txt' }
  
  setup do
    File.write(test_file, 'Test content')
  end
  
  teardown do
    File.delete(test_file) if File.exist?(test_file)
    File.delete('downloaded.txt') if File.exist?('downloaded.txt')
  end
  
  # Test with FTP
  it 'performs file operations via FTP' do
    ftp 'my-server' do
      # Create directory
      mkdir 'test-dir'
      
      # Upload file
      upload test_file, to: remote_file
      
      # Check if exists
      assert (exists remote_file).to be true
      
      # Get file info
      size = file_size remote_file
      expect size.to be_greater_than 0
      
      # Rename file
      rename remote_file, 'renamed.txt'
      
      # List files
      files = list
      expect files.to_not be_empty
      
      # Download file
      download 'renamed.txt', to: 'downloaded.txt'
      
      # Cleanup
      delete 'renamed.txt'
      rmdir 'test-dir'
    end
  end
  
  # Same test with SFTP - only the connection method changes!
  it 'performs identical operations via SFTP' do
    sftp 'my-server' do
      # Create directory
      mkdir 'test-dir'
      
      # Upload file
      upload test_file, to: remote_file
      
      # Check if exists
      assert (exists remote_file).to be true
      
      # Get file info
      size = file_size remote_file
      expect size.to be_greater_than 0
      
      # Rename file
      rename remote_file, 'renamed.txt'
      
      # List files
      files = list
      expect files.to_not be_empty
      
      # Download file
      download 'renamed.txt', to: 'downloaded.txt'
      
      # Cleanup
      delete 'renamed.txt'
      rmdir 'test-dir'
    end
  end
end
```

As you can see, the only difference between FTP and SFTP tests is whether you use `ftp` or `sftp` to initiate the connection. All file operations use the exact same method names and parameters.

---

## API Reference

### Common Methods Available for Both FTP and SFTP

All methods below work identically for both `ftp` and `sftp` connections:

| Method | Parameters | Description | Returns |
|--------|-----------|-------------|---------|
| `connect!` | - | Manually establish connection | - |
| `close` | - | Close the connection | - |
| `can_connect?` | - | Test if connection can be established | Boolean |
| `upload` | `localfile, to: remote_name` | Upload a file to server | - |
| `download` | `remotefile, to: local_name` | Download a file from server | - |
| `list` | `path = nil` (FTP) or `path = '.'` (SFTP) | List files in directory | Array of strings |
| `mkdir` | `dirname` | Create a directory | - |
| `rmdir` | `dirname` | Remove a directory | - |
| `delete` | `filename` | Delete a file | - |
| `rename` | `oldname, newname` | Rename or move a file | - |
| `chdir` | `path` | Change current directory | - |
| `pwd` | - | Get current directory | String |
| `exists` | `path` | Check if file/directory exists | Boolean |
| `file_size` | `filename` | Get file size | Integer (bytes) |
| `mtime` | `filename` | Get modification time | Time |

### SFTP-Specific Methods

These methods are available only for SFTP connections:

| Method | Parameters | Description | Returns |
|--------|-----------|-------------|---------|
| `stat` | `path` | Get detailed file attributes | Hash with :size, :mtime, :permissions, etc. |
| `private_key` | `file_path` | Set SSH private key for authentication | - |
| `passphrase` | `phrase` | Set passphrase for encrypted keys | - |

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

The FTP module provides comprehensive methods for both FTP and SFTP operations:

### File Operations
✅ **upload** - Upload files to FTP/SFTP servers  
✅ **download** - Download files from FTP/SFTP servers  
✅ **delete** - Delete files on remote servers  
✅ **rename** - Rename or move files on remote servers  
✅ **exists** - Check if a file or directory exists  
✅ **file_size** - Get the size of a file in bytes  
✅ **mtime** - Get the last modification time of a file  

### Directory Operations
✅ **mkdir** - Create a new directory  
✅ **rmdir** - Remove an empty directory  
✅ **chdir** - Change current directory (FTP)  
✅ **pwd** - Get current working directory  
✅ **list** - List files and directories  

### Connection Operations
✅ **can_connect?** - Test connection to FTP/SFTP servers  
✅ Use password or SSH key authentication (SFTP)  

### Additional SFTP Methods
✅ **stat** - Get detailed file attributes and permissions  

All methods work consistently across both FTP and SFTP implementations, making it easy to switch between protocols without changing your test code.
