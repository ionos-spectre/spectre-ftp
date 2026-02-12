require 'net/ftp'
require 'net/sftp'
require 'logger'
require 'json'

module Spectre
  module FTP
    class FTPConnection
      include Spectre::Delegate if defined? Spectre::Delegate

      def initialize host, username, password, opts, logger
        @__logger = logger
        @__session = nil

        @__host = host
        @__username = username
        @__password = password
        @__opts = opts
      end

      def username user
        @__username = user
      end

      def password pass
        @__password = pass
      end

      def connect!
        return unless @__session.nil? or @__session.closed?

        @__logger.info "Connecting to '#{@__host}' with user '#{@__username}'"
        @__session = Net::FTP.new(@__host, @__opts)
        @__session.login @__username, @__password
      end

      def close
        return unless @__session and !@__session.closed?

        @__session.close
      end

      def can_connect?
        connect!
        true
      rescue StandardError
        false
      end

      def download remotefile, to: File.basename(remotefile)
        connect!
        @__logger.info(
          "Downloading \
          '#{@__username}@#{@__host}:#{File.join @__session.pwd, remotefile}' \
          to '#{File.expand_path to}'"
        )
        @__session.getbinaryfile(remotefile, to)
      end

      def upload localfile, to: File.basename(localfile)
        connect!
        @__logger.info(
          "Uploading '#{File.expand_path localfile}' \
          to '#{@__username}@#{@__host}:#{File.join @__session.pwd, to}'"
        )
        @__session.putbinaryfile(localfile, to)
      end

      def list path = nil
        connect!
        file_list = path ? @__session.list(path) : @__session.list
        @__logger.info("Listing files in #{path || @__session.pwd}\n#{file_list}")
        file_list
      end

      def mkdir dirname
        connect!
        @__logger.info("Creating directory '#{dirname}' in #{@__session.pwd}")
        @__session.mkdir(dirname)
      end

      def rmdir dirname
        connect!
        @__logger.info("Removing directory '#{dirname}' in #{@__session.pwd}")
        @__session.rmdir(dirname)
      end

      def delete filename
        connect!
        @__logger.info("Deleting file '#{filename}' in #{@__session.pwd}")
        @__session.delete(filename)
      end

      def rename oldname, newname
        connect!
        @__logger.info("Renaming '#{oldname}' to '#{newname}' in #{@__session.pwd}")
        @__session.rename(oldname, newname)
      end

      def chdir path
        connect!
        @__logger.info("Changing directory to '#{path}'")
        @__session.chdir(path)
      end

      def pwd
        connect!
        current_dir = @__session.pwd
        @__logger.info("Current directory: #{current_dir}")
        current_dir
      end

      def exists path
        connect!
        begin
          @__session.size(path)
          true
        rescue Net::FTPPermError, Net::FTPTempError
          false
        end
      end

      def file_size filename
        connect!
        size = @__session.size(filename)
        @__logger.info("File size of '#{filename}': #{size} bytes")
        size
      end

      def mtime filename
        connect!
        modification_time = @__session.mtime(filename)
        @__logger.info("Modification time of '#{filename}': #{modification_time}")
        modification_time
      end
    end

    class SFTPConnection
      include Spectre::Delegate if defined? Spectre::Delegate

      def initialize host, username, opts, logger
        @__logger = logger
        @__session = nil
        @__host = host
        @__username = username
        @__opts = opts
      end

      def username user
        @__username = user
      end

      def password pass
        @__opts[:password] = pass
        @__opts[:auth_methods].push 'password' unless @__opts[:auth_methods].include? 'password'
      end

      def private_key file_path
        @__opts[:keys] = [file_path]
        @__opts[:auth_methods].push 'publickey' unless @__opts[:auth_methods].include? 'publickey'
      end

      def passphrase phrase
        @__opts[:passphrase] = phrase
      end

      def connect!
        return unless @__session.nil? or @__session.closed?

        @__logger.info("Connecting to '#{@__host}' with user '#{@__username}'")
        @__session = Net::SFTP.start(@__host, @__username, @__opts)
        @__session.connect!
      end

      def close
        return if @__session.nil? or @__session.closed?

        @__session.close_channel
      end

      def can_connect?
        connect!
        true
      rescue StandardError
        false
      end

      def download remotefile, to: File.basename(remotefile)
        connect!
        @__logger.info "Downloading '#{@__username}@#{@__host}:#{remotefile}' to '#{File.expand_path to}'"
        @__session.download!(remotefile, to)
      end

      def upload localfile, to: File.basename(localfile)
        connect!
        @__logger.info "Uploading '#{File.expand_path localfile}' to '#{@__username}@#{@__host}:#{to}'"
        @__session.upload!(localfile, to)
      end

      def stat path
        connect!
        file_info = @__session.stat! path
        @__logger.info "Stat '#{path}'\n#{JSON.pretty_generate file_info.attributes}"
        file_info.attributes
      end

      def exists path
        connect!
        begin
          @__session.stat! path
        rescue Net::SFTP::StatusException => e
          return false if e.description == 'no such file'

          raise e
        end

        true
      end

      def list path = '.'
        connect!
        files = []
        @__session.dir.foreach(path) do |entry|
          files << entry.longname
        end
        @__logger.info("Listing files in #{path}\n#{files}")
        files
      end

      def mkdir dirname
        connect!
        @__logger.info("Creating directory '#{dirname}'")
        @__session.mkdir!(dirname)
      end

      def rmdir dirname
        connect!
        @__logger.info("Removing directory '#{dirname}'")
        @__session.rmdir!(dirname)
      end

      def delete filename
        connect!
        @__logger.info("Deleting file '#{filename}'")
        @__session.remove!(filename)
      end

      def rename oldname, newname
        connect!
        @__logger.info("Renaming '#{oldname}' to '#{newname}'")
        @__session.rename!(oldname, newname)
      end

      # # SFTP is stateless and doesn't have a concept of current directory
      # # All operations use absolute paths or paths relative to the user's home directory
      # # This method is a no-op for API compatibility with FTP
      # def chdir path
      #   connect!
      #   @__logger.info("Note: SFTP is stateless - paths are always absolute or relative to home directory")
      # end

      def pwd
        connect!
        current_dir = @__session.realpath!('.')
        @__logger.info("Current directory: #{current_dir.name}")
        current_dir.name
      end

      def file_size filename
        connect!
        stat_info = @__session.stat!(filename)
        size = stat_info.size
        @__logger.info("File size of '#{filename}': #{size} bytes")
        size
      end

      def mtime filename
        connect!
        stat_info = @__session.stat!(filename)
        modification_time = Time.at(stat_info.mtime)
        @__logger.info("Modification time of '#{filename}': #{modification_time}")
        modification_time
      end
    end

    class Client
      include Spectre::Delegate if defined? Spectre::Delegate

      def initialize config, logger
        @config = config['ftp'] || {}
        @logger = logger
      end

      def ftps(name, config = {}, &)
        config[:ssl] ||= { implicit: true }
        config[:port] ||= 990

        ftp(name, config, &)
      end

      def ftp(name, config = {}, &)
        cfg = @config[name] || {}

        hostname = config.delete(:host) || cfg['host'] || name
        username = config.delete(:username) || cfg['username']
        password = config.delete(:password) || cfg['password']

        config[:port] = config[:port] || cfg['port'] || 21
        config[:ssl] = config[:ssl] || cfg['ssl']

        ftp_conn = FTPConnection.new(hostname, username, password, config, @logger)

        begin
          ftp_conn.instance_eval(&)
        ensure
          ftp_conn.close
        end
      end

      def sftp(name, config = {}, &)
        cfg = @config[name] || {}

        host = config.delete(:host) || cfg['host'] || name
        username = config.delete(:username) || cfg['username']
        password = config.delete(:password) || cfg['password']

        config[:password] = password
        config[:port] ||= cfg['port'] || 22
        config[:keys] = [cfg['key']] if cfg.key? 'key'
        config[:passphrase] = cfg['passphrase'] if cfg.key? 'passphrase'

        config[:auth_methods] = []
        config[:auth_methods].push 'publickey' if config[:keys]
        config[:auth_methods].push 'password' if config[:password]

        config[:non_interactive] = true

        sftp_con = SFTPConnection.new(host, username, config, @logger)

        begin
          sftp_con.instance_eval(&)
        ensure
          sftp_con.close
        end
      end
    end
  end

  Engine.register(FTP::Client, :ftp, :sftp, :ftps) if defined? Engine
end
