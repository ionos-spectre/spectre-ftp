# Spectre FTP

[![Build](https://github.com/ionos-spectre/spectre-ftp/actions/workflows/build.yml/badge.svg)](https://github.com/ionos-spectre/spectre-ftp/actions/workflows/build.yml)
[![Gem Version](https://badge.fury.io/rb/spectre-ftp.svg)](https://badge.fury.io/rb/spectre-ftp)

This is a [spectre](https://github.com/ionos-spectre/spectre-core) module which allows you to test file transfer operations using:
- **FTP** (File Transfer Protocol)
- **FTPS** (FTP over SSL/TLS)
- **SFTP** (SSH File Transfer Protocol)

This is useful for testing systems that upload or download files from FTP servers.

Using [net-ftp](https://github.com/ruby/net-ftp) and [net-sftp](https://www.rubydoc.info/gems/net-sftp/2.0.5/Net/SFTP).


## Install

```bash
$ sudo gem install spectre-ftp
```

## Development and Testing

### Unit Tests

Run unit tests with mocked FTP/SFTP connections:

```bash
bundle exec rspec --tag ~integration
```

### Integration Tests

```bash
# Start Docker servers
docker-compose up -d

# Run integration tests
bundle exec rspec --tag integration

# Stop Docker servers
docker-compose down
```


## Configure

Add the module to your `spectre.yml`

```yml
include:
 - spectre/ftp
```

Configure your FTP/SFTP/FTPS servers in your environment file:

```yaml
# environments/development.env.yml
ftp:
  my-ftp-server:
    host: ftp.example.com
    username: testuser
    password: secretpass
    port: 21
  
  my-ftps-server:
    host: ftps.example.com
    username: testuser
    password: secretpass
    port: 990  # Default FTPS port (implicit SSL)
    ssl:
      implicit: true  # Implicit SSL (default for ftps() method)
  
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

## Testing

### Unit Tests vs Integration Tests

This gem includes two types of tests:

**Unit Tests** (mocked) - Fast tests that use mocked FTP/SFTP connections:
- Located in [spec/ftp_spec.rb](spec/ftp_spec.rb)
- Run with: `bundle exec rspec --tag ~integration`
- No external dependencies required
- Test the API and method signatures

**Integration Tests** (real servers) - Tests against actual FTP/SFTP servers:
- Located in [spec/ftp_integration_spec.rb](spec/ftp_integration_spec.rb) and [spec/sftp_integration_spec.rb](spec/sftp_integration_spec.rb)
- Run with: `bundle exec rspec --tag integration`
- Requires Docker and docker-compose
- Tests actual file transfer operations
- Verifies compatibility with net-ftp and net-sftp gems

See [INTEGRATION_TESTING.md](INTEGRATION_TESTING.md) for detailed integration testing documentation.

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

## FTPS Operations

FTPS (FTP over SSL/TLS) provides secure file transfer using SSL/TLS encryption. 
The `ftps()` method uses **implicit SSL** by default, where the SSL connection is established immediately.

### Understanding FTPS Modes

There are two FTPS modes:

1. **Implicit FTPS** (default, port 990):
   - SSL/TLS connection established immediately upon connection
   - Used by `ftps()` method by default
   - Configuration: `ssl: { implicit: true }`

2. **Explicit FTPS** (port 21):
   - Connection starts as plain FTP, then upgrades to SSL/TLS using AUTH TLS command
   - Also called FTPES or "explicit TLS"
   - Configuration: `ssl: true`

### Connecting to FTPS Server

```ruby
it 'connects to FTPS server' do
  # Uses port 990 and implicit SSL
  ftps 'my-ftps-server' do
    can_connect = can_connect?
    
    assert can_connect.to be true
  end
end
```

### Configuring FTPS in Environment File

```yaml
# environments/production.env.yml
ftp:
  # Implicit FTPS (default)
  my-ftps-server:
    host: ftps.example.com
    username: secureuser
    password: securepass
    port: 990  # default for implicit FTPS, can be omitted
    ssl:
      implicit: true  # default for ftps()
  
  # Explicit FTPS (if needed)
  explicit-ftps-server:
    host: ftp.example.com
    username: user
    password: pass
    port: 21
    ssl: true  # or ssl: { } for explicit mode
```

### Uploading Files via FTPS

```ruby
it 'uploads sensitive file via FTPS' do
  File.write('confidential.txt', 'Sensitive data')
  
  ftps 'my-ftps-server' do
    upload 'confidential.txt'
  end
end
```

### Using Explicit FTPS

If you need explicit FTPS (AUTH TLS) instead of implicit SSL:

```ruby
it 'uses explicit FTPS' do
  ftps 'explicit-server', ssl: true, port: 21 do
    upload 'file.txt'
  end
end
```

### Custom SSL Options

You can pass additional SSL options for certificate verification, ciphers, etc.:

```ruby
it 'connects with custom SSL options' do
  ftps 'secure-server', ssl: { 
    implicit: true, 
    verify_mode: OpenSSL::SSL::VERIFY_NONE  # Skip certificate verification
  } do
    upload 'data.json'
  end
end
```

### Downloading Files via FTPS

```ruby
it 'downloads encrypted backup' do
  ftps 'backup-server' do
    download 'backup-2024.tar.gz', to: 'local-backup.tar.gz'
  end
  
  assert File.exist?('local-backup.tar.gz').to be true
end
```

### All FTP Operations Work with FTPS

All operations available for `ftp()` work identically with `ftps()`:

- **Directory Operations**: `mkdir`, `rmdir`, `chdir`, `pwd`
- **File Operations**: `upload`, `download`, `delete`, `rename`
- **File Information**: `exists`, `file_size`, `mtime`, `list`
- **Connection Testing**: `can_connect?`

```ruby
it 'performs secure file operations' do
  ftps 'secure-server' do
    # Create directory
    mkdir 'secure-data'
    chdir 'secure-data'
    
    # Upload file
    upload 'data.json'
    
    # Verify file exists
    assert exists('data.json').to be true
    
    # Check file size
    size = file_size 'data.json'
    info "Uploaded file size: #{size} bytes"
    
    # Get modification time
    modified = mtime 'data.json'
    info "Last modified: #{modified}"
  end
end
```

### Using Custom Port with FTPS

```ruby
it 'connects to FTPS on custom port' do
  ftps 'custom-server', port: 2990 do
    # Operations here will use port 2990 with SSL
    can_connect = can_connect?
    
    assert can_connect.to be true
  end
end
```

### Disabling SSL (for explicit FTPS or testing)

```ruby
it 'connects with SSL disabled' do
  ftps 'test-server', ssl: false do
    # This will behave like regular FTP
    upload 'test.txt'
  end
end
```

### Complete FTPS Example

```ruby
describe 'Secure File Transfer' do
  setup do
    bag.secure_file = "secure_#{uuid}.txt"
    File.write(bag.secure_file, 'Confidential content')
  end
  
  teardown do
    File.delete(bag.secure_file) if File.exist?(bag.secure_file)
    File.delete('downloaded-secure.txt') if File.exist?('downloaded-secure.txt')
  end
  
  it 'securely transfers files via FTPS' do
    # Upload encrypted
    ftps 'secure-server' do
      upload bag.secure_file, to: 'encrypted-upload.txt'
      
      # Verify upload
      assert exists('encrypted-upload.txt').to be true
      
      size = file_size 'encrypted-upload.txt'
      info "Uploaded file size: #{size} bytes"
    end
    
    # Download encrypted
    ftps 'secure-server' do
      download 'encrypted-upload.txt', to: 'downloaded-secure.txt'
      
      # Clean up remote file
      delete 'encrypted-upload.txt'
    end
    
    # Verify content
    original = File.read(bag.secure_file)
    downloaded = File.read('downloaded-secure.txt')
    
    assert downloaded.to be original
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

---

## Contributing

We welcome contributions! This section covers the development setup and testing procedures.

### Prerequisites

- Ruby 3.4+ (or compatible version)
- Docker and Docker Compose (for integration tests)
- Bundler for dependency management

### Getting Started

1. **Clone the repository**
   ```bash
   git clone https://github.com/ionos-spectre/spectre-ftp.git
   cd spectre-ftp
   ```

2. **Install dependencies**
   ```bash
   bundle install
   ```

### Running Tests

The project includes both unit tests (mocked) and integration tests (against real FTP/SFTP servers).

#### Unit Tests

Unit tests use mocked FTP/SFTP connections and don't require Docker:

```bash
bundle exec rake spec_unit
```

These tests run quickly and verify the API behavior without actual network connections.

#### Integration Tests

Integration tests run against real FTP and SFTP servers in Docker containers:

```bash
bundle exec rake integration
```

This command automatically:
- Cleans up any existing Docker containers
- Starts fresh FTP and SFTP servers
- Waits for servers to be ready
- Runs all integration tests
- Cleans up Docker containers after completion

**Note**: Always use `rake integration` instead of running RSpec directly with the integration tag, as it ensures proper Docker lifecycle management.

#### Run All Tests

To run both unit and integration tests together:

```bash
bundle exec rake spec
```

### Docker Setup

The project includes Docker configurations for testing:

- **FTP Server**: pure-ftpd running on port 2121
  - Username: `ftpuser`
  - Password: `ftppass`
  
- **SFTP Server**: OpenSSH-based SFTP on port 2222
  - Username: `sftpuser`
  - Password: `sftppass`

#### Manual Docker Management

If you need to manually control the Docker servers:

```bash
# Start servers
bundle exec rake docker:up

# View logs
bundle exec rake docker:logs

# Stop servers
bundle exec rake docker:down
```

The Docker containers are defined in `docker-compose.yml` with configurations in:
- `docker/ftp/` - FTP server configuration
- `docker/sftp/` - SFTP server configuration

### Project Structure

```
spectre-ftp/
├── lib/
│   └── spectre/
│       └── ftp.rb              # Main implementation
├── spec/
│   ├── ftp_spec.rb             # Unit tests (mocked)
│   ├── ftp_integration_spec.rb # FTP integration tests
│   └── sftp_integration_spec.rb # SFTP integration tests
├── docker/
│   ├── ftp/                    # FTP server Docker config
│   └── sftp/                   # SFTP server Docker config
├── docker-compose.yml          # Docker orchestration
└── Rakefile                    # Test tasks
```

### Making Changes

1. **Write tests first**: Add unit tests for new functionality
2. **Implement the feature**: Update `lib/spectre/ftp.rb`
3. **Run unit tests**: `bundle exec rake spec_unit`
4. **Add integration tests**: If needed, add tests to verify against real servers
5. **Run integration tests**: `bundle exec rake integration`
6. **Update documentation**: Add examples to README.md

### Submitting Pull Requests

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/my-new-feature`)
3. Make your changes with tests
4. Ensure all tests pass (`bundle exec rake spec`)
5. Commit your changes (`git commit -am 'Add new feature'`)
6. Push to the branch (`git push origin feature/my-new-feature`)
7. Create a Pull Request

### Code Style

- Follow Ruby community style guidelines
- Keep methods focused and single-purpose
- Add tests for all new functionality
- Update documentation for user-facing changes
