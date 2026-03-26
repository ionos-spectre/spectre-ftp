### v2.0.3

#### Minor
 - restructure and update documentation
 - add optional CA file support for FTPS and FTPES connections (backward compatible)
 - code style fixes

### v2.0.2

#### Minor
 - implement implicit SSL (FTPS) support
 - refactor connection config

### v2.0.1

#### Minor
 - implement additional FTP operations (mkdir, rmdir, delete, rename, chdir, pwd, exists, file_size, mtime)
 - implement integration tests
 - update dependencies and workflows

### v2.0.0

#### Major
 - adopt to spectre 2.0 with new module loading
 - rename module and use spectre delegate
 - require Ruby >= 3.2
 - add rspec tests
 - fix connection handling (connect, close)

### v1.1.1

#### Patch
 - require Ruby >= 3.2
 - fix dependencies

### v1.1.0

#### Minor
 - update version of net-sftp to 4.0.0 due to update of openssh version to >3.0.0

### v1.0.0

#### Major
 - `spectre/ftp` was extracted from `spectre-core` into this package
