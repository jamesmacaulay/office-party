class ItunesController < ApplicationController
  
  def index
    @current_track = itunes.current_track
    @upcoming_tracks = itunes.current_playlist.tracks[1..-1]
  end
  
  def play
    itunes.play
    head :ok
  end
  
  def pause
    itunes.pause
    head :ok
  end
  
  def playpause
    itunes.playpause
    head :ok
  end
  
  def previous
    itunes.previous_track
    head :ok
  end
  
  def next
    itunes.next_track
    head :ok
  end
end
