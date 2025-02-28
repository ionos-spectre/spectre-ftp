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

      def list
        connect!
        file_list = @__session.list
        @__logger.info("Listing files in #{@__session.pwd}\n#{file_list}")
        file_list
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
        begin
          @__session.stat! path
        rescue Net::SFTP::StatusException => e
          return false if e.description == 'no such file'

          raise e
        end

        true
      end
    end

    class Client
      include Spectre::Delegate if defined? Spectre::Delegate

      def initialize config, logger
        @config = config['ftp'] || {}
        @logger = logger
      end

      def ftp(name, config = {}, &)
        cfg = @config[name] || {}

        host = config[:host] || cfg['host'] || name
        username = config[:username] || cfg['username']
        password = config[:password] || cfg['password']

        opts = {}
        opts[:ssl] = config[:ssl]
        opts[:port] = config[:port] || cfg['port'] || 21

        ftp_conn = FTPConnection.new(host, username, password, opts, @logger)

        begin
          ftp_conn.instance_eval(&)
        ensure
          ftp_conn.close
        end
      end

      def sftp(name, config = {}, &)
        cfg = @config[name] || {}

        host = config[:host] || cfg['host'] || name
        username = config[:username] || cfg['username']
        password = config[:password] || cfg['password']

        opts = {}
        opts[:password] = password
        opts[:port] = config[:port] || cfg['port'] || 22
        opts[:keys] = [cfg['key']] if cfg.key? 'key'
        opts[:passphrase] = cfg['passphrase'] if cfg.key? 'passphrase'

        opts[:auth_methods] = []
        opts[:auth_methods].push 'publickey' if opts[:keys]
        opts[:auth_methods].push 'password' if opts[:password]

        opts[:non_interactive] = true

        sftp_con = SFTPConnection.new(host, username, opts, @logger)

        begin
          sftp_con.instance_eval(&)
        ensure
          sftp_con.close
        end
      end
    end
  end

  Engine.register(FTP::Client, :ftp, :sftp)
end
