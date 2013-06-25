require 'digest'
require 'fileutils'
require 'lib/randstring'

class AccountInfo
  def initialize(login = nil, password_hash = nil, salt = nil)
    @login = login
    @password_hash = password_hash
    @salt = salt
  end
  attr_accessor :login
  attr_accessor :password_hash
  attr_accessor :salt
end  


class Authentication
  def initialize(password_file)
    @password_file = password_file
    @accounts = {}
    load_password_file(password_file)
  end

  def add_account(login, unhashed_password)
    if @accounts.has_key?login
      raise "The account #{login} already exists"
    end
    raise "Password cannot be empty" if unhashed_password.nil?
    add_account_internal(login, unhashed_password)
  end

  def del_account(login)
    if ! @accounts.has_key?(login)
      raise "The account #{login} does not exist"
    end
    del_account_internal(login)
  end
  
  private
  
  def load_password_file(filename)
    if File.exists? filename
      File.open(filename, "r") do |file|
        @accounts.clear
        file.each_line do |line|
          if line =~ /([^:]+):(.*):(.*)/
            @accounts[$1] = AccountInfo.new($1,$2,$3)
          end
        end
      end
    end
  end

  def add_account_internal(login, unhashed_password)
    salt = RandString.make_random_string(10)
    acct = AccountInfo.new(login, hash_password(unhashed_password, salt), salt)
    File.open(@password_file, "a"){ |file|
      file.puts "#{login}:#{acct.password_hash}:#{salt}"
    }
    @accounts[login] = acct
  end

  def hash_password(pass, salt)
    Digest::SHA256.hexdigest(pass + salt)
  end

  def del_account_internal(login)
    tmpfile = "#{@password_file}.new"
    File.open(tmpfile, "w"){ |outfile|
      File.open(@password_file, "r"){ |infile|
        infile.each_line { |line|
          outfile.print line if line !~ /^#{login}:/
        }
      }
    }
    FileUtils.mv tmpfile, @password_file
  end

end
