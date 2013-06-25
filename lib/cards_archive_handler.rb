require 'fileutils'
require 'lib/const'
require 'nokogiri'
require 'lib/cards_processor'

# Class for managing uploaded cards archives.
class CardsArchiveHandler
  def initialize(tmp_directory = "tmp/incoming", output_directory = "data")
    @tmp_directory = tmp_directory
    @output_directory = output_directory
  end

  def process_new_archive(path)
    begin
      FileUtils.mkdir_p @tmp_directory if ! File.exists?(@tmp_directory)
    rescue
      raise "Creating temporary directory failed: #{$!}"
    end

    begin
      FileUtils.rm_rf Dir.glob(@tmp_directory + File::SEPARATOR + '*')
    rescue
      raise "Removing temporary directory contents failed: #{$!}"
    end

    cmd = "unzip -o '#{path}' -d '#{@tmp_directory}' 2>&1"
    output = `#{cmd}`
    raise "Executing unzip command failed. Output: #{output}" if ! $?.success?

    # Sanity checking
    cards_path = @tmp_directory + File::SEPARATOR + CARDS_FILE_NAME
    raise "Archive doesn't contain #{CARDS_FILE_NAME}" if ! File.exists?(cards_path)

    xml_doc = nil
    begin
      File.open(cards_path, "r") do |file|
        xml_doc = Nokogiri::XML.parse(file)
      end
    rescue
      raise "Parsing #{CARDS_FILE_NAME} file failed: #{$!}"
    end
 
    # Verify that all referenced images exist.
    xml_doc.css("image").each do |img|
      path = @tmp_directory + File::SEPARATOR + img.attribute("name")
      raise "Archive's #{CARDS_FILE_NAME} references image #{img.attribute("name")} that doesn't exist in the archive." if ! File.exists?(path)
    end   

    # Process the cards.xml file to add the correct versioning dates to the images and overall file
    new_cards_path = cards_path + ".new"
    CardsProcessor.new(@tmp_directory).process cards_path, new_cards_path

    # Copy files to official data directory
    FileUtils.cp Dir.glob(@tmp_directory + File::SEPARATOR + '*'), @output_directory
    FileUtils.mv @output_directory + File::SEPARATOR + CARDS_FILE_NAME + ".new", @output_directory + File::SEPARATOR + CARDS_FILE_NAME
  end
end
