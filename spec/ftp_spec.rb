CONFIG = {
  'ftp' => {
    'example' => {
      'host' => 'some-data.host',
      'username' => 'dummy',
      'password' => '<some-secret-password>',
    },
  },
}

require_relative '../lib/spectre/ftp'

RSpec.describe 'FTP' do
  context 'ftp' do
    before do
      opts = [
        'some-data.host',
        {
          port: 21,
          ssl: nil,
        }
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
        {
          port: 21,
          ssl: nil,
        }
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

  context 'sftp' do
    before do
      opts = [
        'some-data.host',
        'dummy',
        {
          auth_methods: ['password'],
          port: 22,
          non_interactive: true,
          password: CONFIG['ftp']['example']['password'],
        }
      ]

      ftp_session = double(Net::SFTP::Session)
      expect(ftp_session).to receive(:closed?)
      expect(ftp_session).to receive(:close_channel)
      expect(ftp_session).to receive(:connect!)

      expect(Net::SFTP).to receive(:start).with(*opts).and_return(ftp_session)

      expect(ftp_session).to receive(:upload!).with('dummy.txt', 'dummy.txt')

      @client = Spectre::FTP::Client.new(CONFIG, Logger.new(StringIO.new))
    end

    it 'does upload a file via sftp' do
      @client.sftp 'some-data.host' do
        username 'dummy'
        password '<some-secret-password>'
        upload 'dummy.txt'
      end
    end

    it 'does upload a file via sftp with preconfig' do
      @client.sftp 'example' do
        upload 'dummy.txt'
      end
    end
  end

  context 'sftp operations' do
    before do
      opts = [
        'test.host',
        'user',
        {
          auth_methods: ['password'],
          port: 22,
          non_interactive: true,
          password: 'pass',
        }
      ]

      @sftp_session = double(Net::SFTP::Session)
      expect(Net::SFTP).to receive(:start).with(*opts).and_return(@sftp_session)
      # Session starts as nil, then gets set, so closed? should say it's not closed
      expect(@sftp_session).to receive(:closed?).and_return(false).at_least(:once)
      expect(@sftp_session).to receive(:close_channel).at_least(:once)
      expect(@sftp_session).to receive(:connect!).at_least(:once)

      @client = Spectre::FTP::Client.new({}, Logger.new(StringIO.new))
    end

    it 'creates a directory' do
      expect(@sftp_session).to receive(:mkdir!).with('testdir')

      @client.sftp 'test.host', username: 'user', password: 'pass' do
        mkdir 'testdir'
      end
    end

    it 'removes a directory' do
      expect(@sftp_session).to receive(:rmdir!).with('testdir')

      @client.sftp 'test.host', username: 'user', password: 'pass' do
        rmdir 'testdir'
      end
    end

    it 'deletes a file' do
      expect(@sftp_session).to receive(:remove!).with('file.txt')

      @client.sftp 'test.host', username: 'user', password: 'pass' do
        delete 'file.txt'
      end
    end

    it 'renames a file' do
      expect(@sftp_session).to receive(:rename!).with('old.txt', 'new.txt')

      @client.sftp 'test.host', username: 'user', password: 'pass' do
        rename 'old.txt', 'new.txt'
      end
    end

    it 'gets current directory' do
      name_obj = double('Name', name: '/current/path')
      expect(@sftp_session).to receive(:realpath!).with('.').and_return(name_obj)

      result = nil
      @client.sftp 'test.host', username: 'user', password: 'pass' do
        result = pwd
      end

      expect(result).to eq('/current/path')
    end

    it 'checks if file exists' do
      stat_obj = double('Stat')
      expect(@sftp_session).to receive(:stat!).with('file.txt').and_return(stat_obj)

      result = nil
      @client.sftp 'test.host', username: 'user', password: 'pass' do
        result = exists 'file.txt'
      end

      expect(result).to be true
    end

    it 'returns false when file does not exist' do
      response = double('Response')
      allow(response).to receive(:code).and_return(2)
      allow(response).to receive(:message).and_return('no such file')
      exception = Net::SFTP::StatusException.new(response)
      allow(exception).to receive(:description).and_return('no such file')

      expect(@sftp_session).to receive(:stat!).with('missing.txt').and_raise(exception)

      result = nil
      @client.sftp 'test.host', username: 'user', password: 'pass' do
        result = exists 'missing.txt'
      end

      expect(result).to be false
    end

    it 'gets file size' do
      stat_obj = double('Stat', size: 2048)
      expect(@sftp_session).to receive(:stat!).with('file.txt').and_return(stat_obj)

      result = nil
      @client.sftp 'test.host', username: 'user', password: 'pass' do
        result = file_size 'file.txt'
      end

      expect(result).to eq(2048)
    end

    it 'gets file modification time' do
      mtime_value = Time.now.to_i
      stat_obj = double('Stat', mtime: mtime_value)
      expect(@sftp_session).to receive(:stat!).with('file.txt').and_return(stat_obj)

      result = nil
      @client.sftp 'test.host', username: 'user', password: 'pass' do
        result = mtime 'file.txt'
      end

      expect(result.to_i).to eq(mtime_value)
    end

    it 'lists files in directory' do
      entry1 = double('Entry', longname: '-rw-r--r-- 1 user group 100 Jan 1 file1.txt')
      entry2 = double('Entry', longname: 'drwxr-xr-x 2 user group 4096 Jan 2 subdir')
      dir_mock = double('Dir')
      expect(@sftp_session).to receive(:dir).and_return(dir_mock)
      expect(dir_mock).to receive(:foreach).with('/some/path').and_yield(entry1).and_yield(entry2)

      result = nil
      @client.sftp 'test.host', username: 'user', password: 'pass' do
        result = list '/some/path'
      end

      expect(result.length).to eq(2)
      expect(result[0]).to include('file1.txt')
    end
  end
end
