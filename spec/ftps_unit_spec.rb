CONFIG = {
  'ftp' => {
    'example' => {
      'host' => 'some-data.host',
      'username' => 'dummy',
      'password' => '<some-secret-password>',
    },
  },
}

DEFAULT_FTPS_OPTS = {
  port: 990,
  ssl: true,
  implicit_ftps: true,
}

require_relative '../lib/spectre/ftp'

RSpec.describe 'FTPS Unit Tests' do
  context 'ftps' do
    before do
      opts = [
        'some-data.host',
        DEFAULT_FTPS_OPTS
      ]

      ftp_session = double(Net::FTP)
      expect(ftp_session).to receive(:closed?)
      expect(ftp_session).to receive(:close)
      expect(ftp_session).to receive(:pwd).and_return('/')
      expect(ftp_session).to receive(:login)
        .with(
          CONFIG['ftp']['example']['username'],
          CONFIG['ftp']['example']['password']
        )

      expect(Net::FTP).to receive(:new).with(*opts).and_return(ftp_session)
      expect(ftp_session).to receive(:putbinaryfile).with('dummy.txt', 'dummy.txt')

      @client = Spectre::FTP::Client.new(CONFIG, Logger.new(StringIO.new))
    end

    it 'does upload a file via ftps' do
      @client.ftps 'some-data.host' do
        username 'dummy'
        password '<some-secret-password>'
        upload 'dummy.txt'
      end
    end

    it 'does upload a file via ftps with preconfig' do
      @client.ftps 'example' do
        upload 'dummy.txt'
      end
    end
  end

  context 'ftps operations' do
    before do
      opts = [
        'test.host',
        DEFAULT_FTPS_OPTS
      ]

      @ftp_session = double(Net::FTP)
      expect(Net::FTP).to receive(:new).with(*opts).and_return(@ftp_session)
      expect(@ftp_session).to receive(:closed?).and_return(false).at_least(:once)
      expect(@ftp_session).to receive(:close).at_least(:once)
      expect(@ftp_session).to receive(:login).with('user', 'pass').at_least(:once)

      @client = Spectre::FTP::Client.new({}, Logger.new(StringIO.new))
    end

    it 'creates a directory' do
      expect(@ftp_session).to receive(:pwd).and_return('/home/user')
      expect(@ftp_session).to receive(:mkdir).with('testdir')

      @client.ftps 'test.host', username: 'user', password: 'pass' do
        mkdir 'testdir'
      end
    end

    it 'removes a directory' do
      expect(@ftp_session).to receive(:pwd).and_return('/home/user')
      expect(@ftp_session).to receive(:rmdir).with('testdir')

      @client.ftps 'test.host', username: 'user', password: 'pass' do
        rmdir 'testdir'
      end
    end

    it 'deletes a file' do
      expect(@ftp_session).to receive(:pwd).and_return('/home/user')
      expect(@ftp_session).to receive(:delete).with('file.txt')

      @client.ftps 'test.host', username: 'user', password: 'pass' do
        delete 'file.txt'
      end
    end

    it 'renames a file' do
      expect(@ftp_session).to receive(:pwd).and_return('/home/user')
      expect(@ftp_session).to receive(:rename).with('old.txt', 'new.txt')

      @client.ftps 'test.host', username: 'user', password: 'pass' do
        rename 'old.txt', 'new.txt'
      end
    end

    it 'changes directory' do
      expect(@ftp_session).to receive(:chdir).with('/some/path')

      @client.ftps 'test.host', username: 'user', password: 'pass' do
        chdir '/some/path'
      end
    end

    it 'gets current directory' do
      expect(@ftp_session).to receive(:pwd).and_return('/current/path')

      result = nil
      @client.ftps 'test.host', username: 'user', password: 'pass' do
        result = pwd
      end

      expect(result).to eq('/current/path')
    end

    it 'checks if file exists' do
      expect(@ftp_session).to receive(:size).with('file.txt').and_return(1024)

      result = nil
      @client.ftps 'test.host', username: 'user', password: 'pass' do
        result = exists 'file.txt'
      end

      expect(result).to be true
    end

    it 'returns false when file does not exist' do
      expect(@ftp_session).to receive(:size).with('missing.txt').and_raise(Net::FTPPermError)

      result = nil
      @client.ftps 'test.host', username: 'user', password: 'pass' do
        result = exists 'missing.txt'
      end

      expect(result).to be false
    end

    it 'gets file size' do
      expect(@ftp_session).to receive(:size).with('file.txt').and_return(2048)

      result = nil
      @client.ftps 'test.host', username: 'user', password: 'pass' do
        result = file_size 'file.txt'
      end

      expect(result).to eq(2048)
    end

    it 'gets file modification time' do
      mtime_value = Time.now
      expect(@ftp_session).to receive(:mtime).with('file.txt').and_return(mtime_value)

      result = nil
      @client.ftps 'test.host', username: 'user', password: 'pass' do
        result = mtime 'file.txt'
      end

      expect(result).to eq(mtime_value)
    end

    it 'lists files in directory' do
      files = ['-rw-r--r--   1 user  group      100 Jan  1 12:00 file1.txt',
               'drwxr-xr-x   2 user  group     4096 Jan  2 13:00 subdir']
      expect(@ftp_session).to receive(:list).with('/some/path').and_return(files)

      result = nil
      @client.ftps 'test.host', username: 'user', password: 'pass' do
        result = list '/some/path'
      end

      expect(result).to eq(files)
    end
  end

  context 'ftps ssl configuration' do
    it 'uses implicit SSL by default' do
      opts = [
        'test.host',
        DEFAULT_FTPS_OPTS
      ]

      ftp_session = double(Net::FTP)
      expect(Net::FTP).to receive(:new).with(*opts).and_return(ftp_session)
      expect(ftp_session).to receive(:closed?)
      expect(ftp_session).to receive(:close)
      expect(ftp_session).to receive(:login).with('user', 'pass')
      expect(ftp_session).to receive(:pwd).and_return('/home/user')
      expect(ftp_session).to receive(:putbinaryfile).with('test.txt', 'test.txt')

      client = Spectre::FTP::Client.new({}, Logger.new(StringIO.new))
      client.ftps 'test.host', username: 'user', password: 'pass' do
        upload 'test.txt'
      end
    end
  
    it 'allows custom SSL options' do
      opts = [
        'test.host',
        DEFAULT_FTPS_OPTS
      ]

      ftp_session = double(Net::FTP)
      expect(Net::FTP).to receive(:new).with(*opts).and_return(ftp_session)
      expect(ftp_session).to receive(:closed?)
      expect(ftp_session).to receive(:close)
      expect(ftp_session).to receive(:login).with('user', 'pass')
      expect(ftp_session).to receive(:pwd).and_return('/home/user')
      expect(ftp_session).to receive(:putbinaryfile).with('test.txt', 'test.txt')

      client = Spectre::FTP::Client.new({}, Logger.new(StringIO.new))
      client.ftps 'test.host', username: 'user', password: 'pass', ssl: { implicit: true, verify_mode: 0 } do
        upload 'test.txt'
      end
    end
  end
end
