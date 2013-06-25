require 'rubygems'
require 'data_mapper'

DataMapper::Logger.new($stderr, :debug)

DB_FILE = "db/dystopian.sqlite"
db_file = DB_FILE
if ENV['DW_DB_FILE']
  db_file = ENV['DW_DB_FILE']
end

path = "sqlite://#{Dir.pwd}/#{db_file}"
DataMapper.setup(:default, path)

# Model
class Version
  include DataMapper::Resource

  property :id,             Serial
  property :processed,      DateTime
  # SHA1 hash of the _input_ cards file processed for this version. This is the input file without version fields.
  property :sha1sum,        String
  # Date when the contents of the cards file last changed.
  property :last_modified,  DateTime

  has n, :units, :constraint => :destroy
end

class Unit
  include DataMapper::Resource

  property :id,            Serial
  # SHA1 hash of the image file for this unit
  property :sha1sum,       String
  property :name,          String
  property :filename,      String
  # Date when the contents for the image file last changed
  property :last_modified, DateTime

  belongs_to :version
end

DataMapper.finalize

# Utility class for data management

