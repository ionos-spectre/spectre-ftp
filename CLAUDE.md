# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is a Ruby gem that provides FTP/FTPS/FTPES/SFTP client functionality for the Spectre testing framework. It wraps `net-ftp` and `net-sftp` libraries with a unified API.

**Key Design Principle:** All four protocols (FTP, FTPS, FTPES, SFTP) expose the same method interface, allowing seamless protocol switching without code changes.

## Development Commands

### Running Tests

```bash
# Run all tests (unit + integration)
bundle exec rake spec

# Run only unit tests (no Docker required)
bundle exec rake spec_unit

# Run integration tests with automatic Docker lifecycle management
bundle exec rake integration
```

**IMPORTANT:** Always use `bundle exec rake integration` for integration tests (not `bundle exec rspec --tag integration`), as the rake task handles Docker container startup/shutdown.

### Code Quality

```bash
# Run RuboCop linter
bundle exec rubocop

# Auto-fix RuboCop issues
bundle exec rubocop -a
```

### Docker Management

```bash
# Manually start test servers (FTP on port 2121, SFTP on port 2222)
bundle exec rake docker:up

# Stop test servers
bundle exec rake docker:down

# View server logs
bundle exec rake docker:logs
```

### Building and Publishing

```bash
# Build gem locally
bundle exec rake build

# Install gem locally
bundle exec rake install
```

## Architecture

### Core Structure

The gem consists of a single main file: [lib/spectre/ftp.rb](lib/spectre/ftp.rb)

**Three main classes:**

1. **`Spectre::FTP::Client`** (lines 287-362)
   - Entry point for all FTP operations
   - Provides methods: `ftp()`, `ftps()`, `ftpes()`, `sftp()`
   - Manages connection configuration and lifecycle
   - Automatically closes connections after block execution

2. **`Spectre::FTP::FTPConnection`** (lines 8-137)
   - Wraps `Net::FTP` for FTP/FTPS/FTPES protocols
   - Handles connection, authentication, file operations
   - Supports SSL/TLS via `ssl:` and `implicit:` options

3. **`Spectre::FTP::SFTPConnection`** (lines 139-285)
   - Wraps `Net::SFTP` for SSH-based file transfers
   - Supports password and SSH key authentication
   - Implements same API as FTPConnection for consistency

### Connection Methods

- **`ftp(name, config = {}, &block)`** - Plain FTP (port 21, no SSL)
- **`ftps(name, ca_file, config = {}, &block)`** - Implicit SSL (port 990)
- **`ftpes(name, ca_file, config = {}, &block)`** - Explicit SSL (port 21)
- **`sftp(name, config = {}, &block)`** - SFTP over SSH (port 22)

All methods:
- Accept server name (looks up config from environment files)
- Execute block in context of connection object
- Automatically close connection after block

### Unified API Methods

Both FTPConnection and SFTPConnection implement these methods identically:

- Connection: `connect!`, `close`, `can_connect?`
- File transfer: `upload(local, to:)`, `download(remote, to:)`
- File operations: `delete(file)`, `rename(old, new)`, `exists(path)`
- Directory operations: `mkdir(dir)`, `rmdir(dir)`, `list(path)`, `pwd()`
- File info: `file_size(file)`, `mtime(file)`

**SFTP-specific:** `stat(path)` - Returns detailed file attributes hash

### Spectre Framework Integration

- Includes `Spectre::Delegate` module when running within Spectre (line 9, 140, 288)
- Registers with `Spectre::Engine` if available (line 365)
- Can be used standalone without Spectre framework

## Testing Strategy

### Unit Tests (spec/*_unit_spec.rb)
- Mock Net::FTP and Net::SFTP objects
- Test API behavior without network connections
- Fast, no external dependencies

### Integration Tests (spec/*_integration_spec.rb)
- Connect to real FTP/SFTP servers in Docker containers
- Test actual file transfers and operations
- Tagged with `:integration` metadata

**Docker Test Servers:**
- FTP: `stilliard/pure-ftpd` on localhost:2121 (user: ftpuser/ftppass)
- SFTP: Custom OpenSSH container on localhost:2222 (user: sftpuser/sftppass)

## Important Implementation Details

### FTP Connection Options

The `ftp()` method accepts options passed to Net::FTP constructor:
- `:port` - Port number (default 21)
- `:ssl` - Enable SSL/TLS (default false)
- `:implicit` - Use implicit FTPS (default false, becomes `:implicit_ftps`)

### SFTP Authentication

SFTP supports multiple auth methods configured via:
- `password(pass)` - Sets password auth (line 154-157)
- `private_key(path)` - Sets key-based auth (line 159-162)
- `passphrase(phrase)` - Sets key passphrase (line 164-166)

Auth methods array is built dynamically based on provided credentials (line 348-350).

### Connection Lazy Loading

Both connection classes use lazy connection pattern:
- `connect!` checks if session exists/is open before connecting (line 29, 168)
- All operations call `connect!` first
- Connection reused across multiple operations in same block

### Error Handling

- FTP `exists()` catches `Net::FTPPermError` and `Net::FTPTempError` (line 119)
- SFTP `exists()` catches `Net::SFTP::StatusException` with 'no such file' check (line 212-213)

## Configuration

Server configurations stored in environment YAML files under `ftp:` key. Example:

```yaml
ftp:
  my-server:
    host: ftp.example.com
    username: user
    password: pass
    port: 21
    ssl: false
    implicit: false
    key: /path/to/private_key      # SFTP only
    passphrase: keypass             # SFTP only
```

## Ruby Version

Requires Ruby 3.4+ (specified in gemspec:13)

## RuboCop Configuration

Many style cops disabled in [.rubocop.yml](.rubocop.yml) to support existing codebase style:
- Frozen string literals disabled
- Documentation requirements disabled
- Method parentheses optional
- Metrics checks disabled
