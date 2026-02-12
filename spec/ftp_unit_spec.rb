CONFIG = {
  'ftp' => {
    'example' => {
      'host' => 'some-data.host',
      'username' => 'dummy',
      'password' => '<some-secret-password>',
    },
  },
}

DEFAULT_FTP_OPTS = {
  port: 21,
  ssl: false,
  implicit_ftps: false,
}

require_relative '../lib/spectre/ftp'

RSpec.describe 'FTP Unit Tests' do
  context 'ftp' do
    before do
      opts = [
        'some-data.host',
        DEFAULT_FTP_OPTS
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

    it 'does upload a file via ftp' do
      @client.ftp 'some-data.host' do
        username 'dummy'
        password '<some-secret-password>'
        upload 'dummy.txt'
      end
    end

    it 'does upload a file via ftp with preconfig' do
      @client.ftp 'example' do
        upload 'dummy.txt'
      end
    end
  end

  context 'ftp operations' do
    before do
      opts = [
        'test.host',
        DEFAULT_FTP_OPTS
      ]

      @ftp_session = double(Net::FTP)
      expect(Net::FTP).to receive(:new).with(*opts).and_return(@ftp_session)
      expect(@ftp_session).to receive(:closed?).at_least(:once)
      expect(@ftp_session).to receive(:close).at_least(:once)
      expect(@ftp_session).to receive(:login).with('user', 'pass')

      @client = Spectre::FTP::Client.new({}, Logger.new(StringIO.new))
    end

    it 'creates a directory' do
      expect(@ftp_session).to receive(:pwd).and_return('/home/user')
      expect(@ftp_session).to receive(:mkdir).with('testdir')

      @client.ftp 'test.host', username: 'user', password: 'pass' do
        mkdir 'testdir'
      end
    end

    it 'removes a directory' do
      expect(@ftp_session).to receive(:pwd).and_return('/home/user')
      expect(@ftp_session).to receive(:rmdir).with('testdir')

      @client.ftp 'test.host', username: 'user', password: 'pass' do
        rmdir 'testdir'
      end
    end

    it 'deletes a file' do
      expect(@ftp_session).to receive(:pwd).and_return('/home/user')
      expect(@ftp_session).to receive(:delete).with('file.txt')

      @client.ftp 'test.host', username: 'user', password: 'pass' do
        delete 'file.txt'
      end
    end

    it 'renames a file' do
      expect(@ftp_session).to receive(:pwd).and_return('/home/user')
      expect(@ftp_session).to receive(:rename).with('old.txt', 'new.txt')

      @client.ftp 'test.host', username: 'user', password: 'pass' do
        rename 'old.txt', 'new.txt'
      end
    end

    it 'changes directory' do
      expect(@ftp_session).to receive(:chdir).with('/new/path')

      @client.ftp 'test.host', username: 'user', password: 'pass' do
        chdir '/new/path'
      end
    end

    it 'gets current directory' do
      expect(@ftp_session).to receive(:pwd).and_return('/current/path')

      result = nil
      @client.ftp 'test.host', username: 'user', password: 'pass' do
        result = pwd
      end

      expect(result).to eq('/current/path')
    end

    it 'checks if file exists' do
      expect(@ftp_session).to receive(:size).with('file.txt').and_return(1024)

      result = nil
      @client.ftp 'test.host', username: 'user', password: 'pass' do
        result = exists 'file.txt'
      end

      expect(result).to be true
    end

    it 'returns false when file does not exist' do
      expect(@ftp_session).to receive(:size).with('missing.txt').and_raise(Net::FTPPermError)

      result = nil
      @client.ftp 'test.host', username: 'user', password: 'pass' do
        result = exists 'missing.txt'
      end

      expect(result).to be false
    end

    it 'gets file size' do
      expect(@ftp_session).to receive(:size).with('file.txt').and_return(1024)

      result = nil
      @client.ftp 'test.host', username: 'user', password: 'pass' do
        result = file_size 'file.txt'
      end

      expect(result).to eq(1024)
    end

    it 'gets file modification time' do
      mtime = Time.now
      expect(@ftp_session).to receive(:mtime).with('file.txt').and_return(mtime)

      result = nil
      @client.ftp 'test.host', username: 'user', password: 'pass' do
        result = mtime 'file.txt'
      end

      expect(result).to eq(mtime)
    end

    it 'lists files in directory' do
      files = ['file1.txt', 'file2.txt']
      expect(@ftp_session).to receive(:list).with('/some/path').and_return(files)

      result = nil
      @client.ftp 'test.host', username: 'user', password: 'pass' do
        result = list '/some/path'
      end

      expect(result).to eq(files)
    end
  end
end
