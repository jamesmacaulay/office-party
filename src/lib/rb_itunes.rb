##
# rb-itunes, a Ruby wrapper for iTunes on both Windows and Mac OS X
#
# Created by Kai Steinbach in April 2007.
# Copyright (c) 2007. All rights reserved.
#
# At the time of creation there are 3 ways of using iTunes functionality
# within Ruby:
# - appscript on Mac OS X
# - rb-osa on Mac OS X
# - WIN32OLE on Win32 
# The aim of this wrapper is to promote cross-platform itunes Ruby
# that will work with either one of the three.
# 
# Note that this API is not a replacement for iTunes. It does not have
# functionality on its own, but is a way of using iTunes and its
# information.
#
# HISTORY:
# - 0.1.5 [2007-04-12]
#   App.new on Mac will try rb-appscript by default, it will
#   then try rbosa. It has a parameter to override this default.
# - 0.1.4 [2007-04-11]
#   implemented Playlist.query_track_fields for appscript (fast) and
#   also for win32ole and rbosa (slow for large playlists).
#   Toggle for Playlist.repeat_mode= changed to match iTunes GUI.
#   Several methods added to set track details and support volume/mute.
# - 0.1.3 [2007-04-10]
#   added patch #10012 fixing :pause for player_state on win32ole
# - 0.1.2 [2007-04-09]
#   added descriptions for creating somewhat useful RDoc output
# - 0.1.1 [2007-04-08]
#   added appscript compatibility to the existing classes and methods
# - 0.1.0 [2007-04-04]
#   initial draft based on rbosa and win32ole functionality, implementing only a
#   fraction of the API like required for a web remote control application for iTunes
#
# REMARKS:
# - see this source code for sections marked with TODO
# - check the class methods against the Windows SDK or the ASDictionary output of
#   iTunes on Mac to see what is currently completely missing
# - have a look at http://rb-itunes.rubyforge.org and especially the
#   Dev-Doc: http://rb-itunes.rubyforge.org/devdoc.html
#
#--
# - the special_kind on windows only works for USERplaylists, for some other playlists you need to check the "kind"
#   first, because special_kind might not be answered. rbosa does not distinguish between 3 kinds of playlists, and it's
#   playlist class only has a special_kind attribute, not a "kind"
# - database_id (mac) is 4 fields on win32: sourceID,playlistID,trackID,databaseID 
#++
module RbItunes

  __AUTHOR__ =  "Kai Steinbach" # modified by James MacAulay
  __VERSION__ = "0.1.5.1"
  __DATE__ =    "2009-01-13"

  ##
  # Represents the iTunes Application, comparable to "IiTunes Interface" on Win and the "iTunes Suite" on Mac
  ##
  class App
    private
      @_itunes     # here we store the instance of the real itunes app, that will do all the work for us
      @_itunes_api # either :rbosa, :win32ole or :appscript

    public
    # This is here for debugging only, and will be removed in a final version. Don't use!
    def get_native_object
      @_itunes
    end
  
    # This is here for debugging only, and will be removed in a final version. Don't use!
    def which_api
      @_itunes_api
    end

    # loads dependencies and creates an appriate native iTunes reference 
    # object via win32ole on windows and appscript (default) or rbosa on Mac.
    # If you want to use rbosa on a system that has both rb-appscript and
    # rbosa installed, you can create the instance with
    # i = App.new(false) - that might be good for development and tests.
    def initialize(prefer_appscript_over_rbosa = true)
      if RUBY_PLATFORM =~ /dar(00)?win/
        require 'rubygems'
        if prefer_appscript_over_rbosa then
          begin
            require 'appscript'
            @_itunes = Appscript.app('iTunes')
            @_itunes_api = :appscript
          rescue LoadError
          end  
        end
        if not @_itunes then
          require 'rbosa'
          OSA.utf8_strings= true
          @_itunes = OSA.app('iTunes')
          @_itunes_api = :rbosa
        end
      
      elsif RUBY_PLATFORM.match('mswin')
        require 'win32ole'
        @_itunes = WIN32OLE.new('iTunes.Application')  
        @_itunes_api = :win32ole
      
      elsif RUBY_PLATFORM.match('maybe-linux-crossover-or-so')
        #any other platform that can iTunes? Wine? Crossover? Then change this code here
      
      else
        raise "For this platform rb-itunes does not yet know how to access Apple iTunes."
      end
    end
  
    # Plays the current track.
    def play
      @_itunes.play
    end
  
    # Pauses the current track. Note that sometimes it could stop iTunes rather
    # than pause it. This seems to be depending on the current playlist and the
    # state of the iTunes GUI.
    def pause
      @_itunes.pause
    end
  
    # Toggles Pause and Play on the current track. Note that sometimes it could
    # stop iTunes rather than pause it. This seems to be depending on the current
    # playlist and the state of the iTunes GUI.
    def playpause
      @_itunes.playpause
    end
  
    # Goes to the previous track. If the current track is the first track of the
    # current playlist, this may put iTunes to stop.
    def previous_track
      if @_itunes_api == :win32ole
        @_itunes.previoustrack
      else
        @_itunes.previous_track
      end
    end
  
    # Goes to the next track. If the current track is the last track of the
    # current playlist, this may put iTunes to stop.
    def next_track
      if @_itunes_api == :win32ole
        @_itunes.nexttrack
      else
        @_itunes.next_track
      end
    end
  
    # Stops iTunes.
    def stop
      @_itunes.stop
    end 
  
    # Returns the sound volume of iTunes - a value between 0 and 100.
    def sound_volume
      if @_itunes_api == :win32ole
        @_itunes.soundvolume
      elsif @_itunes_api == :appscript
        @_itunes.sound_volume.get
      else
        @_itunes.sound_volume
      end
    end

    # Sets the sound volume of iTunes to a new value (between 0 and 100).
    def sound_volume= ( new_sound_volume)
      if @_itunes_api == :win32ole
        @_itunes.soundvolume= new_sound_volume
      elsif @_itunes_api == :appscript
        @_itunes.sound_volume.set new_sound_volume
        @_itunes.sound_volume.get
      else
        @_itunes.sound_volume= new_sound_volume
      end
    end
  
    # Returns if iTunes is muted (true/false).
    def mute
      if @_itunes_api == :rbosa
        @_itunes.mute?
      elsif @_itunes_api == :appscript
        @_itunes.mute.get
      else
        @_itunes.mute
      end
    end
  
    # Sets the mute of iTunes (true/false).
    def mute= (new_mute_value)
      if @_itunes_api == :appscript
        @_itunes.mute.set new_mute_value
        @_itunes.mute.get
      else
        @_itunes.mute = new_mute_value
      end
    end
  
    # Returns the player position of the current track in seconds.
    def player_position
      if @_itunes_api == :win32ole
        @_itunes.playerposition
      elsif @_itunes_api == :appscript
        @_itunes.player_position.get
      else
        @_itunes.player_position
      end
    end
  
    # Sets the player position of the current track.
    def player_position= (position)
      if @_itunes_api == :win32ole
        @_itunes.playerposition = position
      elsif @_itunes_api == :appscript
        @_itunes.player_position.set position
        @_itunes.player_position.get
      else
        @_itunes.player_position = position
      end
    end
  
    # Returns the current track as an Track. See source for discussion on more specialised class types.
    def current_track
      if @_itunes_api == :win32ole
        tmp_track = @_itunes.currenttrack
      elsif @_itunes_api == :appscript
        tmp_track = @_itunes.current_track.get
      else
        tmp_track = @_itunes.current_track
      end
      # TODO: should we check the properties of the tmp_track
      # and return a more specialised class appropriately?
      #
      # Mac: audio_CD_track, device_track, file_track
      #      shared_track, URL_track
      # Win: FileOrCDTrack, URLTrack
      Track.new tmp_track, @_itunes_api
    end

    # Returns the current playlist as an Playlist. See source for discussion on more specialised class types.
    def current_playlist
      if @_itunes_api == :win32ole
        tmp_playlist = @_itunes.currentplaylist
      elsif @_itunes_api == :appscript
        tmp_playlist = @_itunes.current_playlist.get
      else
        tmp_playlist = @_itunes.current_playlist
      end
      # TODO: should we check the properties of the tmp_playlist
      # and return a more specialised class appropriately?
      #
      # Mac: audio_CD_playlist, device_playlist, library_playlist
      #      radio_tuner_playlist, user_playlist, folder_playlist
      # Win: AudioCDPlaylist, LibraryPlaylist, UserPlaylist
      Playlist.new tmp_playlist, @_itunes_api
    end
  
    # For win32ole compatibility reasons, returns an Integer
    # representing the current player state of iTunes.
    #
    # It is recommended to use player_state instead of this method, as it
    # can distinguish between :paused and :stopped. In contrast playerstate
    # returns 0 for both paused and stopped.
    #
    # This method (without the underscore) natively
    # exists on Windows only. Possible return values are
    # 0 stopped or paused, 1 playing, 2 fast forwarding, 3 rewinding.
    def playerstate
      if @_itunes_api == :win32ole
        @_itunes.playerstate
      else
        case player_state
        when :playing
          1
        when :fast_forwarding
          2
        when :rewinding
          3
        else
          # currenty includes both "stopped" and "paused"
          0 
        end
      end
    end
  
    # Returns a symbol representing the current player state of iTunes.
    # 
    # Possible values are :playing, :paused, :stopped, :fast_forwarding
    # and :rewinding.
    #
    # Attension:
    # * rbosa usually returns an OSA::ITunes::EPLS::...
    #   in place of a Symbol, hence using rb-itunes might
    #   break existing rbosa code.
    # * rb-appscript usually returns a Symbol - no change
    # * win32ole only has playerstate returning an Integer,
    #   and it is recommended to use player_state instead.
    def player_state
      if @_itunes_api == :win32ole
        case @_itunes.playerstate
        when 1
          :playing
        when 2
          :fast_forwarding
        when 3
          :rewinding
        else
          # on windows we can only distinguish between paused
          # and stopped using the following trick:
          begin
            # the next line raises an WIN32OLERuntimeError if stopped
            dummy =  @_itunes.playerposition
            # if we get to here, the player is paused 
            :paused
          rescue
            :stopped
          end
        end
      elsif @_itunes_api == :appscript
        @_itunes.player_state.get.to_s.downcase.to_sym
      else
        @_itunes.player_state.to_s.downcase.to_sym      
      end
    end
  
    # Returns an SourceCollection
    def sources
      if @_itunes_api == :appscript
        SourceCollection.new @_itunes.sources.get, @_itunes_api
      else
        SourceCollection.new @_itunes.sources, @_itunes_api
      end
    end  
  
    # an attempt to make it easy to move current win32ole users to rb-itunes...
    alias_method :previoustrack,    :previous_track
    alias_method :nexttrack,        :next_track
    alias_method :playerposition,   :player_position
    alias_method :playerposition=,  :player_position=
    alias_method :currenttrack,     :current_track
    alias_method :currentplaylist,  :current_playlist
    alias_method :soundvolume,      :sound_volume
    alias_method :soundvolume=,      :sound_volume=

    # both mac and windows itunes apps call this "playpause",
    # but in ruby you might default to this following alias?
    alias_method :play_pause,       :playpause
  
  end


  # Represents the iTunes item (mac) / IITObject (win32)
  #
  # Playlist, Track and Source inherit from it.
  class Item
    private
      @_itunes_object
      @_itunes_api

    public
  
    # This is here for debugging only, and will be removed in a final version. Don't use!
    def get_native_object
      @_itunes_object
    end

    # When creating an Items, we expect the native object and a symbol as parameters.
    # The methods saves both in private instance variables. The symbol represents which
    # variant the native object is - either :win32ole, :appscript or :rbosa.
    def initialize ( itunes_object, itunes_api )
      @_itunes_object = itunes_object
      @_itunes_api = itunes_api
    end
  
    # Returns the name.
    def name
      if @_itunes_api == :appscript
        @_itunes_object.name.get
      else
        @_itunes_object.name
      end
    end
    # Sets the same to the value.
    def name= (val)
      if @_itunes_api == :appscript
        @_itunes_object.name.set val
        @_itunes_object.name.get
      else
        @_itunes_object.name= val
      end
    end
  
    # Avoid using for now!
    #
    # Only the Windows iTunes has this method on this "IITObject" level. 
    # TODO: it is a good question, what to do on the Mac, if a developer
    # asks for an index. Maybe we can go up to the container and get the
    # index from there?
    # 
    # At the moment using the persistent_id is a HACK! it will not allow retrieving
    # the Item using this ID. It does however allow check against 
    # current_track / current_playlist's .index when looping through a list of those
    def index
      if @_itunes_api == :win32ole
        @_itunes_object.index
      elsif @_itunes_api == :appscript
        @_itunes_object.persistent_ID.get
      else
        @_itunes_object.persistent_id
      end
    end

    #TODO: def Container (Mac only!) ?
    #TODO: def persistent_ID (Mac only!) ?
    #      (note that on Windows there is no persistent_ID)
    #TODO: SourceID PlaylistID TrackID TrackDatabaseID (windows only) ?
    # "These are runtime IDs, they are only valid while the current instance
    #     of iTunes is running."
    #TODO: GetITObjectIDs (windows only)
  end


  # Represents the iTunes Track
  class Track < Item
    # Sets the rating of the track (0..100) 
    def rating= ( track_rating)
      if @_itunes_api == :appscript
        @_itunes_object.rating.set track_rating
        @_itunes_object.rating.get
      else
        @_itunes_object.rating = track_rating
      end
    end
  
    # Returns the rating of the track (0..100) 
    def rating
      if @_itunes_api == :appscript
        @_itunes_object.rating.get
      else
        @_itunes_object.rating
      end
    end

    # Returns if the track is enabled for playback. true/false
    def enabled
      if @_itunes_api == :rbosa
        @_itunes_object.enabled?
      elsif @_itunes_api == :appscript
        @_itunes_object.enabled.get
      else
        @_itunes_object.enabled
      end
    end
  
    # Sets if the track is enabled for playback. true/false
    def enabled= (val)
      if @_itunes_api == :appscript
        @_itunes_object.enabled.set val
        @_itunes_object.enabled.get
      else
        @_itunes_object.enabled= val
      end
    end
  
    # Returns the name of the artist of the track.
    def artist
      if @_itunes_api == :appscript
        @_itunes_object.artist.get
      else
        @_itunes_object.artist
      end
    end

    # Sets the artist of the track.
    def artist=( new_artist )
      if @_itunes_api == :appscript
        @_itunes_object.artist.set new_artist
        @_itunes_object.artist.get
      else
        @_itunes_object.artist = new_artist
      end
    end
  
    # Returns the name of the album of the track.
    def album
      if @_itunes_api == :appscript
        @_itunes_object.album.get
      else
        @_itunes_object.album
      end
    end

    # Sets the name of the album of the track.
    def album=( new_album_name )
      if @_itunes_api == :appscript
        @_itunes_object.album.set new_album_name
        @_itunes_object.album.get
      else
        @_itunes_object.album = new_album_name
      end
    end 
  
    # Returns the year of the track.
    def year
      if @_itunes_api == :appscript
        @_itunes_object.year.get
      else
        @_itunes_object.year
      end
    end
  
    # Sets the year of the track.
    def year=( new_year )
      if @_itunes_api == :appscript
        @_itunes_object.year.set new_year
        @_itunes_object.year.get
      else
        @_itunes_object.year = new_year
      end
    end

    # Returns the genre of the track.
    def genre
      if @_itunes_api == :appscript
        @_itunes_object.genre.get
      else
        @_itunes_object.genre
      end
    end
  
    # Sets the genre of the track.
    def genre=( new_genre )
      if @_itunes_api == :appscript
        @_itunes_object.genre.set new_genre
        @_itunes_object.genre.get
      else
        @_itunes_object.genre = new_genre
      end
    end
  
    # Returns the lyrics of the track.
    def lyrics
      if @_itunes_api == :appscript
        @_itunes_object.lyrics.get
      else
        @_itunes_object.lyrics
      end
    end

    # Sets the lyrics of the track.
    def lyrics=( new_lyrics )
      if @_itunes_api == :appscript
        @_itunes_object.lyrics.set new_lyrics
        @_itunes_object.lyrics.get
      else
        @_itunes_object.lyrics = new_lyrics
      end
    end 
  
    # Returns the composer of the track.
    def composer
      if @_itunes_api == :appscript
        @_itunes_object.composer.get
      else
        @_itunes_object.composer
      end
    end
  
    # Sets the composer of the track.
    def composer=( new_composer )
      if @_itunes_api == :appscript
        @_itunes_object.composer.set new_composer
        @_itunes_object.composer.get
      else
        @_itunes_object.composer = new_composer
      end
    end 
  
    # Returns a formated length of the track (MM:SS).
    def time
      if @_itunes_api == :appscript
        @_itunes_object.time.get
      else
        @_itunes_object.time
      end
    end
  
    # Returns the track number of the track on the track's album.
    def track_number
      if @_itunes_api == :win32ole
        @_itunes_object.tracknumber
      elsif @_itunes_api == :appscript
        @_itunes_object.track_number.get
      else
        @_itunes_object.track_number
      end
    end

    # Sets the track number of the track on the track's album.
    def track_number=( new_track_number )
      if @_itunes_api == :win32ole
        @_itunes_object.tracknumber= new_track_number
      elsif @_itunes_api == :appscript
        @_itunes_object.track_number.set new_track_number
        @_itunes_object.track_number.get
      else
        @_itunes_object.track_number = new_track_number
      end
    end 
  
    # Careful with this one, as it is different between Windows and Mac!
    #
    # The Mac ASDictionary extract says this is "the common, unique ID for
    # this track. If two tracks in different playlists have the same
    # database ID, they are sharing the same data."
    #
    # TODO: Need to test if on the Mac this ID chances, when iTunes is
    # restarted. On Win apparently it does so ...
    #
    # On Windows this method does not exist on the Track level,
    # but instead on the IiTunesObject level, and called "TrackDatabaseID".
    # The Windows SDK says: "Returns the ID that identifies the track, 
    # independent of its playlist. Valid for a track. Will be zero for a
    # source or playlist. If the same music file is in two different
    # playlists, each of the tracks will have the same track database ID.
    # This is a runtime ID, it is only valid while the current instance
    # of iTunes is running."
    #
    # Maybe later this method moves to Item, and we implement it
    # exactly like on Windows - returning 0 for a source or playlist.
    def database_id
      if @_itunes_api == :win32ole
        @_itunes_object.trackdatabaseid
      elsif @_itunes_api == :appscript
        @_itunes_object.database_ID.get
      else
        @_itunes_object.database_id
      end
    end

    # Returns how often this track has been played.
    def played_count
      if @_itunes_api == :win32ole
        @_itunes_object.playedcount
      elsif @_itunes_api == :appscript
        @_itunes_object.played_count.get
      else
        @_itunes_object.played_count
      end
    end
  
    # Returns when this track was last played.
    def played_date
      if @_itunes_api == :win32ole
        @_itunes_object.playeddate
      elsif @_itunes_api == :appscript
        @_itunes_object.played_date.get
      else
        @_itunes_object.played_date
      end
    end
  
    # Careful with this one, as it is different between Windows and Mac!
    #
    # In windows this is only available in FileOrCDTracks, normal Tracks
    # or URLTracks don't have skipped_count nor skipped_date.
    # At the moment the function does nothing to handle this.
    # 
    # TODO: Test with a URLTrack on Windows and implement required
    # checks / work arounds.
    #
    # If all goes well, returns how often this track was skipped.
    def skipped_count
      if @_itunes_api == :win32ole
        @_itunes_object.skippedcount
      elsif @_itunes_api == :appscript
        @_itunes_object.skipped_count.get
      else
        @_itunes_object.skipped_count
      end
    end
  
    # Careful with this one, as it is different between Windows and Mac!
    #
    # see skipped_count for details.
    #
    # If all goes well, returns when this track was lasted skipped.
    def skipped_date
      if @_itunes_api == :win32ole
        @_itunes_object.skippeddate
      elsif @_itunes_api == :appscript
        @_itunes_object.skipped_date.get
      else
        @_itunes_object.skipped_date
      end
    end

    # Do NOT use, as it is fundamentally different between Windows and Mac!
    # 
    # TODO: decide what to do with this!
    # We probably want to have kind_as_string and kind_as_integer ...
    #
    # On Windows there are 2 methods
    # * kind_as_string (returns a String)
    # * kind (returns an Interger). Possible values are (0) Unknown,
    #   (1) File, (2) CD, (3) URL, (4) Device, (5) Shared library
    #
    # On the Mac the kind method returns a string, eg. "MPEG audio file".
    #
    # In the rb-itunes implementation this method always returns nil.
    def kind
      nil
    end
  
    alias_method :enabled?,       :enabled
    alias_method :tracknumber,    :track_number
    alias_method :tracknumber=,   :track_number=
    alias_method :playedcount,    :played_count
    alias_method :playeddate,     :played_date
    alias_method :skippedcount,   :skipped_count
    alias_method :skippeddate,    :skipped_date
    alias_method :database_ID,    :database_id
  end

  # Represents the iTunes File or CD Track
  #
  # on Win32, it is here where the skipped_count and skipped_date should be
  # however, on Mac they are already in the Track equivalent class.
  #
  # This class currently adds nothing to what it inherits from Track,
  # and we might not even use it in the end. Many of the methods of the
  # more specialised classes are in different places between Windows and
  # Mac OS X, which makes me think maybe rb-itunes should ignore them,
  # and just do everything in Track.
  class FileOrCDTrack < Track
    # TODO: a file track has a location ... that should be here
  end

  # Represents the iTunes URL Track
  #
  # see FileOrCDTrack for thoughts on whether rb-itunes
  # should actually have those specialised classes, because
  # maybe it would be better do have everything in Track
  # instead of having FileOrCDTrack and URLTrack.
  #
  # TODO: check places where an Track is created or returned,
  # and make sure those places know how to distinguish between a
  # normal track and a URLTrack appropriately.
  #
  # TODO: there are details in the windows SDK, that are missing here.
  # On the Mac some of those details are on the Track level
  # (Podcast, Category, Description, LongDescription), some others 
  # are on the App level, and need the URLTrack as a parameter
  # (download, updateAllPodcasts, updatePodcast).
  class URLTrack < Track
    # Returns the URL of the stream, that this track represents. 
    def url
      if @_itunes_api == :win32ole
        @_itunes_object.url
      elsif @_itunes_api == :appscript
        @_itunes_object.address.get
      else
        @_itunes_object.address
      end
    end
  
    # Sets the URL of the stream, that this track represents. 
    def url= (new_url)
      if @_itunes_api == :win32ole
        @_itunes_object.url= new_url
      elsif @_itunes_api == :appscript
        @_itunes_object.address.set new_url
        @_itunes_object.address.get
      else
        @_itunes_object.address= new_url
      end
    end
    alias_method :address,   :url
    alias_method :address=,  :url=
  end

  # Represents the iTunes Playlist
  class Playlist < Item
    # Sets if this playlist should shuffle or not. true/false
    def shuffle= (should_shuffle)
      if @_itunes_api == :appscript
        @_itunes_object.shuffle.set should_shuffle
        @_itunes_object.shuffle.get
      else
        @_itunes_object.shuffle= should_shuffle
      end
    end

    # Returns if this playlist is set to shuffle or not. true/false
    def shuffle
      if @_itunes_api == :rbosa
        @_itunes_object.shuffle?
      elsif @_itunes_api == :appscript
        @_itunes_object.shuffle.get
      else
        @_itunes_object.shuffle
      end
    end

    # Ideally do NOT use, as it is fundamentally different between Windows and Mac!
    #
    # only an application written "on" the win32ole would expect the kind property of a playlist.
    # on mac os x there is no such thing - the mac's playlist only has the special_kind
    # note that on windows only the "UserPlaylist" has a special_kind property, while 
    # "Playlist" and "URLPlaylist" only have .kind.
    #
    # returns
    # 0 for unknown, 1 for Library, 2 for User, 3 for CD, 4 for Device and 5 for Radio
    #
    # always returns 2 on the mac
    #
    # TODO: sort out how this should really work.
    def kind
      if @_itunes_api == :win32ole then
        @_itunes_object.kind
      else
        return 2 #just to get my example app working for now
      end
    end
  
    # Returns an TrackCollection of the tracks of this playlist.
    def tracks
      if @_itunes_api == :appscript then
        TrackCollection.new @_itunes_object.tracks.get, @_itunes_api
      else
        TrackCollection.new @_itunes_object.tracks, @_itunes_api
      end
    end

    # Returns the total duration of this playlist's content, in seconds.
    def duration
      if @_itunes_api == :appscript then
        @_itunes_object.duration.get
      else
        @_itunes_object.duration
      end
    end

    # Returns a MM:SS formated string representing the total duration of this playlist's content.
    def time
      if @_itunes_api == :appscript then
        @_itunes_object.time.get
      else
        @_itunes_object.time
      end
    end
  
    # Starts playing this playlist.
    def play
      if @_itunes_api == :win32ole
        @_itunes_object.playfirsttrack
      else
        @_itunes_object.play
      end
    end

    # Returns a Fixnum representing the current song_repeat state of the
    # playlist. 0 - no repeat, 1 -repeat song, 2 - repeat all.
    # Being an equivalent to song_repeat, this method without the
    # underscore in the name natively exists in the win32ole itunes only.
    def songrepeat
      if @_itunes_api == :win32ole
        @_itunes_object.songrepeat
      elsif @_itunes_api == :rbosa
        if @_itunes_object.song_repeat == OSA::ITunes::ERPT::ONE then
          1
        elsif @_itunes_object.song_repeat == OSA::ITunes::ERPT::ALL then
          2
        else
          0
        end
      elsif @_itunes_api == :appscript
        if @_itunes_object.song_repeat.get == :one then
          1
        elsif @_itunes_object.song_repeat == :all then
          2
        else
          0
        end
      else
        #for any other platform: check and return 0..2
      end
    end
  
    PLAYLIST_REPEAT_MODES = [:off, :one, :all]
  
    # Careful with this one, as it is different between different implementations on the Mac!
    #
    # Returns a Symbol representing the current songrepeat state of the playlist.
    # :off, :one, :all
    def song_repeat
      if @_itunes_api == :win32ole
        PLAYLIST_REPEAT_MODES[@_itunes_object.songrepeat]
      elsif @_itunes_api == :appscript
        @_itunes_object.song_repeat.get
      else
        @_itunes_object.song_repeat.to_s.to_sym
      end
    end
  
    # Sets the song_repeat / songrepeat of this playlist to the new value.
    # It accepts Symbols, Strings or Fixnum representations of the new state.
    # If the method fails to recognise the new state of the parameter, it
    # will simply toggle through the 3 possible states.
    def song_repeat= (new_repeat_mode)
      # we go a 2 step aproach.
      #   (1) we make sure we know exactly what new mode is desired
      #       a call could give us '0..2' or ':off|:one|:all' or even 'OSA::ITunes::ERPT::ONE' etc.
      #       and a save way to catch the 2 latter variants is by converting to string
      #   (2) we set the new mode, respecting how each native itunes_object wants it set
      repeat_mode_numeric = case new_repeat_mode.to_s.downcase
                              when "off" then 0
                              when "one" then 1
                              when "all" then 2
                              when "0" then 0
                              when "1" then 1
                              when "2" then 2
                              else
                                # Should we raise an exeption here? 
                                # well, let's just toggle to the next repeat_mode!
  			      # It does so like iTunes: :off>:all>:one (repeat)
                                if songrepeat == 0
                                  2
                                else
                                  songrepeat - 1
                                end
                            end
      # good. now we can work with repeat_mode_numeric and set it
      if @_itunes_api == :win32ole
        @_itunes_object.songrepeat= repeat_mode_numeric
      elsif @_itunes_api == :rbosa
        if repeat_mode_numeric == 1 then
          @_itunes_object.song_repeat = OSA::ITunes::ERPT::ONE
        elsif repeat_mode_numeric == 2 then
          @_itunes_object.song_repeat = OSA::ITunes::ERPT::ALL
        else
          @_itunes_object.song_repeat = OSA::ITunes::ERPT::OFF
        end
      elsif @_itunes_api == :appscript
        @_itunes_object.song_repeat.set PLAYLIST_REPEAT_MODES[repeat_mode_numeric]
        @_itunes_object.song_repeat.get
      else
        #for any other platform: set appropriately
      end
    end
  
    # will be used with .to_sym only! Compare to the output of special_kind by using :None, :Music, :"TV Shows" ...
    SPECIAL_KIND = "None,Music,Party Shuffle,Podcasts,Folder,Videos,Music,Movies,TV Shows,Audiobooks".split(',')

    # Returns a Symbol to describe what kind of playlist this is. On the Mac the native API
    # gives us this information. On Win32 we use the SPECIAL_KIND array.
    #
    # TODO: carefully check both appscript and rbosa if the string casing matches
    def special_kind
      if @_itunes_api == :win32ole
        if @_itunes_object.kind == 2 then
          SPECIAL_KIND[@_itunes_object.specialkind].to_sym
        else
          :None
        end
      elsif @_itunes_api == :appscript
        @_itunes_object.special_kind.get
      else
        @_itunes_object.special_kind.to_s.to_sym
      end
    end
  
    # Returns a Fixnum representing what the special_kind of this playlist is.
    # Natively this only exists on Windows. On the Mac we use the index of the
    # SPECIAL_KIND array.
    def specialkind
      if @_itunes_api == :win32ole
        @_itunes_object.specialkind
      elsif @_itunes_api == :appscript
        SPECIAL_KIND.index(@_itunes_object.special_kind.get.to_s.gsub("_"," "))
      else
        SPECIAL_KIND.index(@_itunes_object.special_kind.to_s)
      end
    end

    # Returns an Playlist that is parent folder for this playlist.
    def parent
      if @_itunes_api == :appscript
        Playlist.new @_itunes_object.parent.get, @_itunes_api
      else
        Playlist.new @_itunes_object.parent, @_itunes_api
      end
    end

    alias_method :shuffle?,       :shuffle
    alias_method :songrepeat=,    :song_repeat=
    alias_method :playfirsttrack, :play
    alias_method :playFirstTrack, :play
    alias_method :play_first_track, :play

    #-- **************************************************************************
    # What follows is stuff outside the normal iTunes SDK scope!
    #++

    # Returns and Array of Arrays, one for each track. The items of the inner
    # Array will be the values of the fields you query for, in the order you
    # asked for them.
    #
    # Example: query_fields(:name, :artist, :album)
    #
    # Note that this method is not present in any of the native iTunes APIs.
    # It is implemented in the rb-itunes wrapper only for your convenience.
    # Using appscript on Mac OS X it is flying fast :), while on the others it
    # takes much longer. I have received reports of 20 seconds and much more
    # for one or more fields from a playlist containing 10.000 tracks, like the
    # library playlist.
    def query_track_fields( *arr )    
      return nil if arr.empty?
      if @_itunes_api == :appscript
        # On the rb-appscript object we can call playlist.tracks.field.get - which
        # works very quick, just returns an array. We do this for each field that
        # we want to query on, and then zip them together.
        temp_results = []
        loop_j = 0
        zip_parameter = ""
        arr.each do |field|
          temp_results[loop_j] = eval("@_itunes_object.tracks."+ field.to_s + ".get")
          if loop_j > 0 then
            if zip_parameter.length > 0 then
              zip_parameter += ", "
            end
            zip_parameter += "temp_results[" + loop_j.to_s + "]"
          end
          loop_j += 1
        end
        eval("temp_results[0].zip(" + zip_parameter + ")" )
      else
        # On rbosa AND win32ole we have to go track by track and retrieve the
        # fields. That code is OK for small playlists, but much slower for
        # large ones.
        total_results = []
        tracks.each do |track|
          track_details = []
          loop_i = 0
          arr.each do |field|
            track_details[loop_i] = eval("track." + field.to_s)
            loop_i += 1
          end
          total_results << track_details
        end
        total_results
      end
    end

  end

  #--
  # Represents the iTunes User Playlist. It is currently empty and not used
  # We do everything in the Playlist for now.
  #
  # class UserPlaylist < Playlist
  #
  # end
  #++


  # Represents the iTunes Source
  class Source < Item

    # Returns an PlaylistCollection of its playlists.
    def playlists
      if @_itunes_api == :appscript
        PlaylistCollection.new @_itunes_object.playlists.get, @_itunes_api
      else
        PlaylistCollection.new @_itunes_object.playlists, @_itunes_api
      end
    end 
  
    # Returns the total size of the source if it has a fixed size.
    def capacity 
      if @_itunes_api == :appscript
        PlaylistCollection.new @_itunes_object.capacity.get, @_itunes_api
      else
        PlaylistCollection.new @_itunes_object.capacity, @_itunes_api
      end
    end
  end

  # Represents the iTunes Source Collection
  #
  # All it currently does is inherit from Array, and making sure that
  # the content is Source instances rather than native objects.
  class SourceCollection < Array
    private
    @_itunes_api
  
    public
    def initialize ( itunes_object_collection, itunes_api )
      @_itunes_api = itunes_api
      super []
      itunes_object_collection.each {|itunes_object|
        self << Source.new( itunes_object, itunes_api )
      }
    end
  
     # The windows iTunes SDK defined that - hence we do so, too.
     # It simply returns the size of the array.
    def count
      size
    end

  end

  # Represents the iTunes Playlist Collection
  #
  # All it currently does is inherit from Array, and making sure that
  # the content is Playlist instances rather than native objects.
  class PlaylistCollection < Array
    #
    private
    @_itunes_api
  
    public
    def initialize ( itunes_object_collection, itunes_api )
      @_itunes_api = itunes_api
      super []
      itunes_object_collection.each {|itunes_object|
        # CHANGED: we now follow more closely the Mac version - where all Playlists are equal and .kind is not available.
        #if itunes_object.kind == 2 then
        #  self << UserPlaylist.new (itunes_object,itunes_api)
        #else
          self << Playlist.new( itunes_object, itunes_api )
        #end
      }
    end

  end

  # Represents the iTunes Track Collection
  #
  # All it currently does is inherit from Array, and making sure that
  # the content is Track instances rather than native objects.
  class TrackCollection < Array
    #
    private
    @_itunes_api
  
    public
    def initialize ( itunes_object_collection, itunes_api )
      @_itunes_api = itunes_api
      super []
      itunes_object_collection.each {|itunes_object|
        #if @_itunes_api == :win32ole
        #  if itunes_object.kind === 1..2 then
        #    self << FileOrCDTrack.new (itunes_object, @_itunes_api)
        #  elsif @_itunes.currenttrack.kind == 3 then
        #    self << URLTrack.new (itunes_object, @_itunes_api)
        #  else
        #    self << Track.new (itunes_object, @_itunes_api)
        #  end
        #else
          self << Track.new( itunes_object, itunes_api)
        #end
      }
    end

  end
end
