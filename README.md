Introduction
------------

This package is the server-side for managing the Dystopian Wars Card-Browser 
Andoid app's cards archives. The package consists of a Sinatra web application 
that serves card images and XML files, and the utilities for managing the 
server.

All executables should be run relative to the base directory. For example, to
create the database run 'bin/createdb.rb'; don't do 'cd bin; ./createdb.rb' or
add bin/ to your PATH.


Setup
-----

To get the server up and running you'll need ruby and rubygems. First install 
the bundler gem. Then run

  bundle install

to install all the dependencies of this app.

Once installed, follow these steps:

1. Create the sqlite database:

    bin/createdb.rb

2. Add at least one user. This user is required in order to upload new card archives:
  
    bin/adduser.rb

3. Run the web application using rackup:

    rackup -p 5001 server/config.ru

This will run the server on port 5001. You should now be able to connect to the
server using a URL such as: 
  
  http://server:5001/


Architecture and Behaviour
--------------------------

The server hosts one version of the cards archive for the Android application.
The cards archive consists of a cards.xml file, and a set of PNG image files.

The cards.xml hosted by the server has the format shown in the following example:

    <cards version="2013-06-27 22:32:32 -0400">
      <faction name="britannia">
        <unit name="ruler class battleship">
          <image name="ruler.png" zorder="1" version="2013-06-27 22:32:32 -0400"/>
          <image name="britannia_bg1.png" zorder="0" version="2013-06-27 22:32:32 -0400"/>
        </unit>
        <unit name="lexington class cruiser">
          <image name="lexington.png" zorder="1" version="2013-06-27 22:32:32 -0400"/>
          <image name="britannia_bg1.png" zorder="0" version="2013-06-27 22:32:32 -0400"/>
        </unit>
      </faction>
    </cards>


Directories
-----------

The following directories exist under the base directory:

  * bin:  Command-line utilities

  * data: Data directory containing the current cards.xml and related images. This is 
          the data served by the application.

  * db:   SQLite database directory. Each time a new card archive is processed information
          about previous processing runs is loaded from this database for determining card and
          image versions.

  * etc:  Configuration files.

  * lib:  Ruby files containing shared code.

  * log:  Created on first run. Contains log files.

  * server: Implementation of the web application

  * test: Testcases

  * tmp:  Temporary files. Used when processing incoming archives.

Utilities
---------

The following utilities are found under the bin/ directory. They expect to be run from the base directory, i.e. 'bin/thing.rb'


  * adduser.rb:   Create a new user to allow login for upload.

  * deluser.rb:   Delete a user

  * createdb.rb:  Create the SQLite database.

  * process.rb:   Rudimentary script to process a card archive. Currently just processes test data.
