#!/usr/bin/env ruby

require 'rubygems'
require 'sinatra'
require 'haml'
require 'nokogiri'
require 'lib/mime'
require 'lib/const'
require 'lib/cards_archive_handler'
require 'lib/session'
require 'lib/authentication'
require 'lib/const.rb'

set :bind, '0.0.0.0'
set :port, 5001
enable :sessions


$upload_in_progress = false

# Return this from a Sinatra route to stream a file
class Streamer
  def initialize(input_io)
    @input_io = input_io
  end

  def each
    chunk_size = 10240
    while true
      chunk = @input_io.read(chunk_size)
      break if ! chunk
      yield chunk
    end

    @input_io.close
  end
end

helpers do
  def load_cards_xml
    xml_doc = nil
    cards_path = CARDS_DIR + File::SEPARATOR + CARDS_FILE_NAME
    begin
      File.open(cards_path, "r") do |file|
        xml_doc = Nokogiri::XML.parse(file)
      end
    rescue
      puts "/latest_xml_version: Loading cards file #{cards_path} failed: #{$!}. CWD: #{Dir.pwd}"
      halt 500, "Loading cards file failed"
    end
    xml_doc
  end

  def get_cards_elem(xml_doc)
    cards = xml_doc.css("cards").first
    if ! cards
      puts "/latest_xml_version: Cards file #{cards_path} has no 'cards' element"
      halt 500, "Cards file format invalid"
    end
    cards
  end
end

get "/" do
  haml :index
end

get "/latest_xml_version" do
  halt 423, "Cards archive is being updated" if $upload_in_progress

  headers "Content-Type" => "text/plain;charset=utf-8"

  xml_doc = load_cards_xml
  cards = get_cards_elem(xml_doc)

  cards.attribute("version").to_s
end

get "/latest_xml" do
  halt 423, "Cards archive is being updated" if $upload_in_progress

  headers "Content-Type" => "text/xml;charset=utf-8"
  
  cards_path = CARDS_DIR + File::SEPARATOR + CARDS_FILE_NAME
  io = nil
  begin
    io = File.open(cards_path, "r")
  rescue
    puts "/latest_xml: Loading cards file #{cards_path} failed: #{$!}. CWD: #{Dir.pwd}"
    halt 500, "Loading cards file failed"
  end
  
  headers "Content-Length" => io.stat.size

  Streamer.new io
end

get "/image" do
  halt 423, "Cards archive is being updated" if $upload_in_progress

  input_image_name = params[:name]
  
  halt 500, "The parameter 'name' must be passed, set to the image file name." if ! input_image_name
  
  xml_doc = load_cards_xml
  cards = get_cards_elem(xml_doc)

  io = nil
  image_found = false
  image_path = nil
  cards.css('image').each do |image|
    image_name = image.attribute('name')
    next if image_name.to_s != input_image_name
    image_found = true
    image_path = CARDS_DIR + File::SEPARATOR + image_name.to_s
    begin
      io = File.open(image_path,"rb")
    rescue
      puts "/image: Loading image file #{input_image_name} failed: #{$!}"
      halt 500, "Loading image failed"
    end
    break
  end
    
  if ! image_found
    puts "/image: image #{input_image_name} not found"
    halt 404, "Image not found"
  end 
  
  mime_type = Mime.instance.getMimeTypeOfFilename(image_path)
  mime_type = "application/octet-stream" if ! mime_type

  headers "Content-Type" => mime_type
  headers "Content-Length" => io.stat.size

  Streamer.new io
end

get "/upload" do
  sid = session[:sid]
  if SessionStore.instance.valid_session?(sid)
    haml :upload
  else
    haml :login
  end
end

post "/login" do
  auth = Authentication.new PASSWD_FILE
  if auth.authenticate params[:login].to_s, params[:password].to_s
    sid = SessionStore.instance.start_session(params[:login].to_s)
    session[:sid] = sid
    redirect "/upload"
  else
    haml :login, :locals => {:note => 'login or password is incorrect.'}
  end
end

post "/logout" do
  SessionStore.instance.end_session(session[:sid])
  session.delete :sid
  redirect "/"
end

post "/handle_upload" do
  sid = session[:sid]
  if !SessionStore.instance.valid_session?(sid)
    halt 401, "You must login first"
  end

  if ! params['archive']
    halt 500, "The parameter 'archive' must be passed"
  end
  file = params['archive'][:filename]
  path = params['archive'][:tempfile].path

  $upload_in_progress = true
  begin
    handler = CardsArchiveHandler.new
    handler.process_new_archive path  
    
    "Archive uploaded and processed successfully"
  rescue
    "Archive uploading failed:\n" + $!.to_s
  end
 
  $upload_in_progress = false
end
