#!/usr/bin/env ruby 
require 'rubygems'
require 'minitest/unit'
require 'minitest/autorun'
require 'fileutils'

# Before including the cards_processor, make sure that the right database is configured
# correctly and that it is deleted if it already exists.
db_file = "test/data/dystopian.sqlite"
ENV['DW_DB_FILE'] = db_file
FileUtils.rm db_file if File.exists? db_file

require 'lib/cards_archive_handler.rb'

# Create the database since we cleared it out
DataMapper.auto_migrate!

# set up all tests
TMP_DIR = "test/data/tmp/"
THIS_TEST_TMP_DIR1 = "test/data/tmp/archive_handler/tmp"
THIS_TEST_TMP_DIR2 = "test/data/tmp/archive_handler/output"
TEST_DATA_DIR = "test/data"

FileUtils.mkdir_p THIS_TEST_TMP_DIR1
FileUtils.rm_rf THIS_TEST_TMP_DIR1
FileUtils.mkdir_p THIS_TEST_TMP_DIR1

FileUtils.mkdir_p THIS_TEST_TMP_DIR2
FileUtils.rm_rf THIS_TEST_TMP_DIR2
FileUtils.mkdir_p THIS_TEST_TMP_DIR2

class TestCardsProcessor < MiniTest::Unit::TestCase
  
  # Run before each test
  def setup
  end

  def testValidArchive
    
    handler = CardsArchiveHandler.new(THIS_TEST_TMP_DIR1, THIS_TEST_TMP_DIR2)
    begin
      handler.process_new_archive(TEST_DATA_DIR + File::SEPARATOR + "cards_archive_valid.zip")
    rescue
      flunk "Exception when processing valid archive: #{$!} #{$!.backtrace.join("\n")}" 
    end

    assert File.exists?(THIS_TEST_TMP_DIR2 + File::SEPARATOR + "cards.xml"), "Output directory doesn't contain cards.xml"
    assert File.exists?(THIS_TEST_TMP_DIR2 + File::SEPARATOR + "lexington.png"), "Output directory doesn't contain lexington.png"
    assert File.exists?(THIS_TEST_TMP_DIR2 + File::SEPARATOR + "ruler.png"), "Output directory doesn't contain ruler.png"
  end

  def testInvalidArchive1
    
    handler = CardsArchiveHandler.new(THIS_TEST_TMP_DIR1, THIS_TEST_TMP_DIR2)
    begin
      handler.process_new_archive(TEST_DATA_DIR + File::SEPARATOR + "cards_archive_invalid-unknown_image.zip")
      flunk "Processing invalid archive succeeded when it should have thrown an exception" 
    rescue
      pass "Processing invalid archive (referencing unknown image) raised exception as expected: #{$!}"
    end

    #cards_archive_invalid-no_xml.zip  cards_archive_invalid-unknown_image.zip  cards_archive_valid.zip
  end

  def testInvalidArchive2
    
    handler = CardsArchiveHandler.new(THIS_TEST_TMP_DIR1, THIS_TEST_TMP_DIR2)
    begin
      handler.process_new_archive(TEST_DATA_DIR + File::SEPARATOR + "cards_archive_invalid-no_xml.zip")
      flunk "Processing invalid archive succeeded when it should have thrown an exception" 
    rescue
      pass "Processing invalid archive (referencing unknown image) raised exception as expected: #{$!}"
    end
  end
  
end
