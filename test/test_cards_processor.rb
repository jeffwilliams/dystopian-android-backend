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

require 'lib/cards_processor.rb'

# Create the database since we cleared it out
DataMapper.auto_migrate!

# set up all tests
TMP_DIR = "test/data/tmp/"
THIS_TEST_TMP_DIR = "test/data/tmp/cards_processor"

FileUtils.mkdir_p THIS_TEST_TMP_DIR
FileUtils.rm_rf THIS_TEST_TMP_DIR
FileUtils.mkdir_p THIS_TEST_TMP_DIR

class TestCardsProcessor < MiniTest::Unit::TestCase
  
  # Run before each test
  def setup
  end

  def test
    # Database is empty. First pass should set the dates to about now.
    cards = "test/data/cards1.xml"
    
    output = THIS_TEST_TMP_DIR + File::SEPARATOR + "output.xml"
    FileUtils.cp Dir.glob("test/data/*.png"), THIS_TEST_TMP_DIR

    first_run_time = Time.new
    CardsProcessor.new(THIS_TEST_TMP_DIR).process cards, output
  
    # Validate data
    xml_doc = nil
    File.open(output, "r") do |file|
      xml_doc = Nokogiri::XML.parse(file)
    end

    xml_doc.css("cards").each do |card|
      time = Time.parse card.attribute('version').to_s
      assert time.to_i < first_run_time.to_i + 1, "cards version time is invalid"
      assert time.to_i > first_run_time.to_i - 1, "cards version time is invalid: parsed: #{time} expected: #{first_run_time}"
    end
  
    xml_doc.css("image").each do |img|
      time = Time.parse img.attribute('version').to_s
      assert time.to_i < first_run_time.to_i + 1, "image version time is invalid"
      assert time.to_i > first_run_time.to_i - 1, "image version time is invalid"
    end

    # Change one image, and process XML. The result should have that image with a new version.
    img = THIS_TEST_TMP_DIR + File::SEPARATOR + "ruler.png"
    File.open(img, "a+") do |file|
      file.write "1"
    end
  
    sleep 5

    second_run_time = Time.new
    CardsProcessor.new(THIS_TEST_TMP_DIR).process cards, output
    
    # Validate data
    xml_doc = nil
    File.open(output, "r") do |file|
      xml_doc = Nokogiri::XML.parse(file)
    end

    # Cards file changed since the version of one of the images changed.
    xml_doc.css("cards").each do |card|
      time = Time.parse card.attribute('version').to_s
      assert time.to_i < second_run_time.to_i + 1, "cards version time is invalid [2]"
      assert time.to_i > second_run_time.to_i - 1, "cards version time is invalid: parsed: #{time} expected: #{first_run_time}"
    end

    # Only ruler.png should have changed
    xml_doc.css("image").each do |img|
      expected_time = first_run_time
      expected_time = second_run_time if img.attribute("name").to_s == 'ruler.png'
      time = Time.parse img.attribute('version').to_s
      assert time.to_i < expected_time.to_i + 1, "image version time is invalid [2]"
      assert time.to_i > expected_time.to_i - 1, "image version time is invalid [2]"
    end

    sleep 5

    # Nothing changed so versions should be the same.   
    CardsProcessor.new(THIS_TEST_TMP_DIR).process cards, output

    # Validate data
    xml_doc = nil
    File.open(output, "r") do |file|
      xml_doc = Nokogiri::XML.parse(file)
    end

    xml_doc.css("cards").each do |card|
      time = Time.parse card.attribute('version').to_s
      assert time.to_i < second_run_time.to_i + 1, "cards version time is invalid"
      assert time.to_i > second_run_time.to_i - 1, "cards version time is invalid: parsed: #{time} expected: #{first_run_time}"
    end

    xml_doc.css("image").each do |img|
      expected_time = first_run_time
      expected_time = second_run_time if img.attribute("name").to_s == 'ruler.png'
      time = Time.parse img.attribute('version').to_s
      assert time.to_i < expected_time.to_i + 1, "image version time is invalid"
      assert time.to_i > expected_time.to_i - 1, "image version time is invalid"
    end

    # Test cleaning
    
    # clear all versions out. Make sure that this cascades to delete units and images.
    CardsProcessor.new(THIS_TEST_TMP_DIR).clean_db 0

    assert_equal 0, Version.all.size, "cleaning versions failed"
    assert_equal 0, Unit.all.size, "cleaning units failed"
    assert_equal 0, Image.all.size, "cleaning images failed"
    
  end
 
end




