require 'lib/model'

class TimeFormat
  def self.parse(time)
    Time.parse time
  end

  def self.format(time)
    time.strftime "%Y-%m-%d %H:%M:%S %z"
  end
end

# Process an input XML file (cards file) that describes units and their associated files
# to produce an output XML file. The output file has the same format, except for each unit
# has a date-and-time field set to when the unit's image file has last changed, and the cards
# element has a date-and-time field describing the last time the cards file itself changed. 
# This is used by remote applications to detect which image files have changed and need downloading.
class CardsProcessor
  def initialize(image_directory)
    @image_directory = image_directory
  end

  def process(xml_file, output_xml_file)
    @processing_started_time = Time.new

    prev_version = load_previous_version
    new_version = create_new_version(xml_file, prev_version)

    @xml_doc = nil
    File.open(xml_file, "r") do |file|
      @xml_doc = Nokogiri::XML.parse(file)
    end

    # Get all images from the previous version as a hash
    # by image name.
    prev_images = load_previous_version_images
    new_images = {}

    cards = @xml_doc.css('cards')
    raise "XML file is invalid: It must have a cards element." if ! cards
    @image_file_different = false
    cards.first.css("unit").each do |unit|
      process_unit unit, prev_version, new_version, prev_images, new_images
    end

    # If the input cards XML file is different than the last input cards XML file we
    # processed, OR the contents of one of the image files has changed, then
    # increase the version's date.
    if prev_version.nil? || new_version.sha1sum != prev_version.sha1sum || @image_file_different
      puts "Cards file XML has changed"
      new_version.last_modified = @processing_started_time
    end

    new_version.save
    cards.first['version'] = TimeFormat.format(new_version.last_modified)

    # Keep only the newest 5 versions in the database. Why not just keep 1? 
    # Just in case we need to track down a bug.
    clean_db(5)
  
    File.open(output_xml_file,"w") do |file|
      file.puts @xml_doc.to_xml
    end
  end

  # If we have more than N versions in the database, remove the oldest ones until we reach N.
  def clean_db(prev_versions)
puts "CLEAN DB CALLED"
    if Version.count > prev_versions
      to_remove = Version.count - prev_versions
      puts "Removing #{to_remove} old versions from database"
      Version.all(:limit => to_remove, :order => [ :processed.asc ]).each do |old_version|
        old_version.units.all.each do |old_unit|
          #old_unit.images.all.each do |old_image|
          #  old_image.destroy
          #end
          old_unit.destroy
        end
        old_version.destroy
      end
    end
  end

  private 
  def process_unit(unit, prev_version, new_version, prev_images, new_images)
    new_db_unit = create_new_unit unit, new_version

    # Process the images in this unit
    unit.css("image").each do |image|

      # First, check if we've already computed the sha1 for this image 
      # in this processing pass (it could have been referenced from another unit)
      new_db_image = new_images[image.attribute('name').to_s]
      if new_db_image
        new_db_image = new_images[image.attribute('name').to_s]
        time = new_db_image.last_modified
        # Update the XML node so that it's version attribute is the computed version
        image['version'] = TimeFormat.format(time)
        new_db_unit.images << new_db_image
      else
        new_db_image = create_new_image image, new_db_unit

        # Check if this image was already present in the previous version
        prev_db_image = prev_images[image.attribute('name').to_s]
        is_modified = modified_since_last_time prev_db_image, new_db_image

        if is_modified
          puts "Image #{new_db_image.name} contents have changed since last time"
          # If any image file is modified, the cards file is different since the image version
          # will change.
          @image_file_different = true
        end

        # Modify the Image in the XML document and the new database Image.
        # If the SHA1 hash changed since last time, or there was no previous version,
        # set the version field to the current time. Otherwise, set it to the time
        # of the last version.
        time = @processing_started_time
        time = prev_db_image.last_modified if ! is_modified
        image['version'] = TimeFormat.format(time)
        new_db_image.last_modified = time

        new_images[new_db_image.name] = new_db_image
      end
    end
  end

  # Compare a previous and a new Unit database object, and see if the new Unit 
  # image file has changed since the previous Unit. If the previous unit is nil,
  # then true is returned as if the unit has changed.
  def modified_since_last_time(previous_db_image, new_db_image)
    return true if ! previous_db_image
    previous_db_image.sha1sum != new_db_image.sha1sum
  end

  # Create a new Unit database object with all fields set, but not yet saved.
  # xml_unit: The unit element from the input card xml file
  # new_version: The Version database object for the new version we are creating
  def create_new_unit(xml_unit, new_version)
    unit_name = xml_unit.attribute('name')

    new_version.units.new(
      :name => unit_name
    )
  end

  def create_new_image(xml_image, new_unit)
    image_name = xml_image.attribute('name').to_s
    path = @image_directory + File::SEPARATOR + image_name
    raise "Error: the image file #{image_name} referenced from the unit #{new_name.name} doesn't exist" if ! File.exists?(path)
    sha1sum = sha1(path)

    new_unit.images.new(
      :sha1sum => sha1sum,
      :name => image_name
    )

  end

  def create_new_version(xml_file, prev_version)
    sha1sum = sha1(xml_file)
 
    time = @processing_started_time
    time = prev_version.last_modified if prev_version

    new_version = Version.new(
      :processed => Time.now,
      :sha1sum => sha1sum,
      :last_modified => time
    )
  end

  # Load the information about the last version of the cards file from the database.
  def load_previous_version
    Version.all(:limit => 1, :order => [ :processed.desc ]).first
  end

  # Load Image objects from the previous version from the 
  # database and put them in a hash by name.
  def load_previous_version_images
    images = {}
    version = load_previous_version
    return images if ! version
    version.units.all.each do |unit|
      unit.images.all.each do |image|
        images[image.name.to_s] = image
      end
    end
    images
  end

  def images_from_xml(xml_file)
    images = {}
    xml_file.css("image").each do
    end
    
  end

  # Calculate the SHA1 hash of a file as a hex string.
  def sha1(path)
    result = nil
    chunk_size = 10240
    File.open(path, "r") do |file|
      sha1 = Digest::SHA1.new

      while true
        chunk = file.read chunk_size
        break if ! chunk
        sha1.update chunk
      end
      result = sha1.hexdigest
    end
    result
  end

end

