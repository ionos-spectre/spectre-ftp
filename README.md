# Spectre FTP

[![Build](https://github.com/ionos-spectre/spectre-ftp/actions/workflows/build.yml/badge.svg)](https://github.com/ionos-spectre/spectre-ftp/actions/workflows/build.yml)
[![Gem Version](https://badge.fury.io/rb/spectre-ftp.svg)](https://badge.fury.io/rb/spectre-ftp)

This is a [spectre](https://github.com/ionos-spectre/spectre-core) module which provides FTP access functionality to the spectre framework.


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

Configure some predefined FTP connection options in your environment file

```yml
ftp:
  some_ftp_conn:
    host: some.server.com
    username: dummy
    password: '*****'
```


## Usage

With the FTP helper you can define FTP connection parameters in the environment file and use either `ftp` or `sftp` function in your *specs*.

Within the `ftp` or `sftp` block there are the following functions available:

| Method | Parameters | Description |
| -------| ---------- | ----------- |
| `upload` | `local_file`, `to: remote_file` | Uploads a file to the given destination |
| `download` | `remote_file`, `to: local_file` | Downloads a file from the server to disk |
| `can_connect?` | _none_ | Returns `true` if a connection could be established |


```ruby
sftp 'some_ftp_conn' do # use connection name from config
  upload 'dummy.txt' # uploads file to the root dir of the FTP connection
  download 'dummy.txt' # downloads file to the current working directory
  download 'dummy.txt', to: '/tmp/dummy.txt' # downloads file to the given destination
end
```

You can also use the `ftp` and `sftp` function without configuring any connection in your environment file, by providing parameters to the function.
This is helpful, when generating the connection parameters during the *spec* run.

```ruby
sftp 'some.server.com', username: 'u123456', password: '$up3rSecr37' do # use connection name from config
  upload 'dummy.txt' # uploads file to the root dir of the FTP connection
  download 'dummy.txt' # downloads file to the current working directory
  download 'dummy.txt', to: '/tmp/dummy.txt' # downloads file to the given destination
end
```
