require 'pry'
require'tty-prompt'

class User < ActiveRecord::Base
    has_many :playlists

    $prompt = TTY::Prompt.new

    def user_playlist
        user.playlists
    end

end 