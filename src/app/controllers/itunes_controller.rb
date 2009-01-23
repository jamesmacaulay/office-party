class ItunesController < ApplicationController
  
  def index
    @current_track = itunes.current_track
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
