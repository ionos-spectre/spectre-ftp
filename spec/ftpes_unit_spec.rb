CONFIG = {
  'ftp' => {
    'example' => {
      'host' => 'some-data.host',
      'username' => 'dummy',
      'password' => '<some-secret-password>',
    },
  },
}

DEFAULT_FTPES_OPTS = {
  port: 21,
  ssl: true,
  implicit_ftps: false,
}

require_relative '../lib/spectre/ftp'

RSpec.describe 'FTPES Unit Tests' do
  context 'ftpes' do
    before do
      opts = [
        'some-data.host',
        DEFAULT_FTPES_OPTS
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

    it 'does upload a file via ftpes' do
      @client.ftpes 'some-data.host' do
        username 'dummy'
        password '<some-secret-password>'
        upload 'dummy.txt'
      end
    end

    it 'does upload a file via ftpes with preconfig' do
      @client.ftpes 'example' do
        upload 'dummy.txt'
      end
    end
  end

  context 'ftpes operations' do
    before do
      opts = [
        'test.host',
        DEFAULT_FTPES_OPTS
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

      @client.ftpes 'test.host', username: 'user', password: 'pass' do
        mkdir 'testdir'
      end
    end

    it 'removes a directory' do
      expect(@ftp_session).to receive(:pwd).and_return('/home/user')
      expect(@ftp_session).to receive(:rmdir).with('testdir')

      @client.ftpes 'test.host', username: 'user', password: 'pass' do
        rmdir 'testdir'
      end
    end

    it 'deletes a file' do
      expect(@ftp_session).to receive(:pwd).and_return('/home/user')
      expect(@ftp_session).to receive(:delete).with('file.txt')

      @client.ftpes 'test.host', username: 'user', password: 'pass' do
        delete 'file.txt'
      end
    end

    it 'renames a file' do
      expect(@ftp_session).to receive(:pwd).and_return('/home/user')
      expect(@ftp_session).to receive(:rename).with('old.txt', 'new.txt')

      @client.ftpes 'test.host', username: 'user', password: 'pass' do
        rename 'old.txt', 'new.txt'
      end
    end

    it 'changes directory' do
      expect(@ftp_session).to receive(:chdir).with('/some/path')

      @client.ftpes 'test.host', username: 'user', password: 'pass' do
        chdir '/some/path'
      end
    end

    it 'gets current directory' do
      expect(@ftp_session).to receive(:pwd).and_return('/current/path')

      result = nil
      @client.ftpes 'test.host', username: 'user', password: 'pass' do
        result = pwd
      end

      expect(result).to eq('/current/path')
    end

    it 'checks if file exists' do
      expect(@ftp_session).to receive(:size).with('file.txt').and_return(1024)

      result = nil
      @client.ftpes 'test.host', username: 'user', password: 'pass' do
        result = exists 'file.txt'
      end

      expect(result).to be true
    end

    it 'returns false when file does not exist' do
      expect(@ftp_session).to receive(:size).with('missing.txt').and_raise(Net::FTPPermError)

      result = nil
      @client.ftpes 'test.host', username: 'user', password: 'pass' do
        result = exists 'missing.txt'
      end

      expect(result).to be false
    end

    it 'gets file size' do
      expect(@ftp_session).to receive(:size).with('file.txt').and_return(2048)

      result = nil
      @client.ftpes 'test.host', username: 'user', password: 'pass' do
        result = file_size 'file.txt'
      end

      expect(result).to eq(2048)
    end

    it 'gets file modification time' do
      mtime_value = Time.now
      expect(@ftp_session).to receive(:mtime).with('file.txt').and_return(mtime_value)

      result = nil
      @client.ftpes 'test.host', username: 'user', password: 'pass' do
        result = mtime 'file.txt'
      end

      expect(result).to eq(mtime_value)
    end

    it 'lists files in directory' do
      files = ['-rw-r--r--   1 user  group      100 Jan  1 12:00 file1.txt',
               'drwxr-xr-x   2 user  group     4096 Jan  2 13:00 subdir']
      expect(@ftp_session).to receive(:list).with('/some/path').and_return(files)

      result = nil
      @client.ftpes 'test.host', username: 'user', password: 'pass' do
        result = list '/some/path'
      end

      expect(result).to eq(files)
    end
  end
end
