require 'lib/randstring'
require 'thread'

class Session
  def initialize(sid = nil, login = nil, length = 60*60)
    @sid = sid
    @login = login
    # Make a 1 hr session
    @expiry = Time.new + length
  end
  attr_accessor :sid
  attr_accessor :login
  attr_accessor :expiry
end

class SessionStore
  def initialize
    @sessions = {}  
    @session_mutex = Mutex.new
  end

  # Start a new session for the specified user.
  def start_session(login)
    sid = nil
    while ! sid || @sessions.has_key?(sid)
      sid = RandString.make_random_string(256)
    end
    @session_mutex.synchronize do 
      @sessions[sid] = Session.new(sid, login)
    end
    sid
  end

  def end_session(sid)
    @session_mutex.synchronize do
      @sessions.delete sid
    end
  end
  
  def valid_session?(sid)
    rc = false
    @session_mutex.synchronize do
      rc = @sessions.has_key?(sid)
    end
    rc
  end
end
