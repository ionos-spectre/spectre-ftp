# Spectre FTP

[![Build](https://github.com/ionos-spectre/spectre-ftp/actions/workflows/build.yml/badge.svg)](https://github.com/ionos-spectre/spectre-ftp/actions/workflows/build.yml)
[![Gem Version](https://badge.fury.io/rb/spectre-ftp.svg)](https://badge.fury.io/rb/spectre-ftp)

This is a [spectre](https://github.com/ionos-spectre/spectre-core) module which allows you to test file transfer operations using:
- **FTP** (File Transfer Protocol) - Plain FTP on port 21
- **FTPS** (FTP over SSL/TLS) - Implicit SSL on port 990
- **FTPES** (FTP over SSL/TLS) - Explicit SSL on port 21  
- **SFTP** (SSH File Transfer Protocol) - SSH-based on port 22

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

Configure your FTP/FTPS/FTPES/SFTP servers in your environment file:

```yaml
# environments/development.env.yml
ftp:
  my-ftp-server:
    host: ftp.example.com
    username: testuser
    password: secretpass
    # port: 21        # default for ftp()
    # ssl: false      # default for ftp()
    # implicit: false # default for ftp()
  
  my-ftps-server:
    host: ftps.example.com
    username: testuser
    password: secretpass
    # port: 990      # default for ftps()
    # ssl: true      # default for ftps()
    # implicit: true # default for ftps()
  
  my-ftpes-server:
    host: ftpes.example.com
    username: testuser
    password: secretpass
    # port: 21        # default for ftpes()
    # ssl: true       # default for ftpes()
    # implicit: false # default for ftpes()
  
  my-sftp-server:
    host: sftp.example.com
    username: testuser
    password: secretpass
    # port: 22  # default for sftp()
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


## Consistent API Across All Protocols

One of the key features of this module is that **FTP, FTPS, FTPES, and SFTP methods work exactly the same way**, making it easy to switch between protocols without changing your code.

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
  
  # Plain FTP (unencrypted)
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
  
  # FTPS (implicit SSL) - same operations!
  it 'performs identical operations via FTPS' do
    ftps 'my-server' do
      mkdir 'test-dir'
      upload test_file, to: remote_file
      assert (exists remote_file).to be true
      size = file_size remote_file
      expect size.to be_greater_than 0
      rename remote_file, 'renamed.txt'
      files = list
      expect files.to_not be_empty
      download 'renamed.txt', to: 'downloaded.txt'
      delete 'renamed.txt'
      rmdir 'test-dir'
    end
  end
  
  # FTPES (explicit SSL) - same operations!
  it 'performs identical operations via FTPES' do
    ftpes 'my-server' do
      mkdir 'test-dir'
      upload test_file, to: remote_file
      assert (exists remote_file).to be true
      size = file_size remote_file
      expect size.to be_greater_than 0
      rename remote_file, 'renamed.txt'
      files = list
      expect files.to_not be_empty
      download 'renamed.txt', to: 'downloaded.txt'
      delete 'renamed.txt'
      rmdir 'test-dir'
    end
  end
  
  # SFTP (SSH) - same operations!
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

As you can see, the only difference is which connection method you use (`ftp`, `ftps`, `ftpes`, or `sftp`). All file operations use the exact same method names and parameters.

---

## API Reference

### Common Methods for All Protocols

All methods below work identically for `ftp()`, `ftps()`, `ftpes()`, and `sftp()` connections:

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


## FTPS and FTPES - Secure FTP Operations

This module provides two secure FTP variants that use the same operations as `ftp()` but with SSL/TLS encryption:

The `ftps()` method establishes an SSL/TLS connection immediately upon connecting. This is also known as "implicit FTPS".

**Settings:** `port: 990`, `ssl: true`, `implicit: true`

The `ftpes()` method starts as a plain FTP connection, then upgrades to SSL/TLS using the AUTH TLS command. This is also known as "explicit FTPS" or "FTPES".

**Settings:** `port: 21`, `ssl: true`, `implicit: false`

You can override the port in each of the functions, but the SSL method will be forced as described. If you want full control over the options use `ftp()`


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
