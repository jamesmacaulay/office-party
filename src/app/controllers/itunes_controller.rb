class ItunesController < ApplicationController
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
