require 'tty-prompt'
require 'pry'
require 'rest-client'

class CommandLineInterface
    attr_accessor :user
    UI = TTY::Prompt.new

    def initialize
        puts `clear`
        UI.say("🎵 Welcome to Playlist Generator 🎵")
        user_name_input = UI.ask('What is your name?')
        @user = User.find_by(name: user_name_input)
            if not @user
                puts "Created user #{user_name_input}."
                @user = User.create(name: user_name_input)
            end 
        puts "Lets bump, #{@user.name}!"
    end

    def main_menu
        @user.reload
        user_select = UI.select("What do you want to do #{@user.name}?") do |menu|
            menu.choice "Create Playlist", -> { create_playlist }
            menu.choice "View Playlist",   -> { view_playlist }
            menu.choice "Edit Playlist",   -> { edit_playlist_menu }
            menu.choice "Delete Playlist", -> { delete_playlist }
            menu.choice "Exit",            -> { return_exit }
        end 
    end

    def user_search_term
        user_search_term = UI.ask("Name a Song:")
    end

    def target_song(itunes_hash)
        target_song = itunes_hash["results"].map {|result| result["trackName"]}.uniq
        # target_artist = itunes_hash["results"].map {|result| result["artistName"]}.uniq
    end
        

    def create_playlist
        i = 0
        user_playlist_input = UI.ask('What do you want to name your Playlist?')
        @playlist = Playlist.find_by(playlist_name: user_playlist_input)
        if not @playlist
            puts "Created Playlist #{user_playlist_input} for #{@user.name}."
            @playlist = Playlist.create(user_id: @user.id, playlist_name: user_playlist_input)
            puts @playlist.playlist_name 
            user_search_term = UI.ask("Name a Song:")     
            parseterm = user_search_term.split( ).join("+").downcase
            # binding.pry
            response = RestClient.get "https://itunes.apple.com/search?term=#{parseterm}"
            itunes_hash = JSON.parse(response.body)
            target_song(itunes_hash)

            UI.select('Is this your song?') do |menu| 
                unique_array = itunes_hash["results"].each {|song| song}.uniq
                unique_array.map do |song|
                    menu.choice "#{song["trackName"]} - #{song["artistName"]}", -> do  
                        new_song = Song.find_or_create_by(name: song["trackName"], artist: song["artistName"])
                        add_song_to_playlist(new_song, @playlist)
                        menu.choice "Exit", -> {return_exit}
                    end
                end
                
            end
        else 
            puts "This playlist already exists."
        end 
        main_menu
    end

    def add_song_to_playlist(song, playlist)
        playlist.songs << song
        puts "Added #{song.name} to the #{playlist.playlist_name} playlist."
    end

    def find_a_song(playlist)
        user_search_term = UI.ask("Name a Song:")     
        parseterm = user_search_term.split( ).join("+").downcase
        # binding.pry
        response = RestClient.get "https://itunes.apple.com/search?term=#{parseterm}"
        itunes_hash = JSON.parse(response.body)
        target_song(itunes_hash)
        # binding.pry
        UI.select('Is this your song?') do |menu| 
            unique_array = itunes_hash["results"].each {|song| song}.uniq
            unique_array.map do |song|
                menu.choice "#{song["trackName"]} - #{song["artistName"]}", -> do  
                    new_song = Song.find_or_create_by(name: song["trackName"], artist: song["artistName"])
                    add_song_to_playlist(new_song, playlist)
                end
            end
            menu.choice "<- Back"
        end 
    end 

    def view_playlist
        UI.select('Which Playlist do you want to view?') do |menu|
            Playlist.all.map do |playlist| #qbinding.pry
                 menu.choice playlist.playlist_name, -> {playlist.songs.name}
                #     playlist.playlist_songs.map, -> do
                #         playlist.playlist_songs.map do |playlist_song| 
                #             [playlist_song.song.name, playlist_song.song.artist]
                #         end
                #     end
                # end
            end 
            #  puts playlist.playlist_songs.map {|playlist_song| [playlist_song.song.name, playlist_song.song.artist] }#playlist_song.song}
        end 
        main_menu
    end 

    def edit_playlist_menu
        UI.select('Which Playlist do you want to edit?') do |menu|
            @user.playlists.each do |playlist| 
                menu.choice "#{playlist.playlist_name}", -> { edit_playlist(playlist) }
            end
            menu.choice "<- Back"
        end
        main_menu
    end 

    def edit_playlist(playlist)
        UI.select('What do you want to do?') do |menu|
            menu.choice "Add Song",      -> { find_a_song(playlist) }
            menu.choice "Delete a Song", -> { delete_song(playlist) }
        end
    end 

    def delete_song(playlist)
        if playlist.songs.length > 0
            UI.select("Which song do you want to delete?") do |menu|
                playlist.playlist_songs.each do |playlist_song|
                    menu.choice playlist_song.song.name, -> do 
                        playlist_song.destroy if UI.yes?("Are you sure?")
                    end
                end
            end
        else
            puts "There are no songs in this playlist!"
            puts "Returning to main menu..."
            sleep(2)
        end
    end 


    def delete_playlist
        UI.select("Choose a playlist to delete") do |menu|
           @user.playlists .each do |playlist|
                menu.choice playlist.playlist_name, -> do 
                    playlist.destroy if UI.yes?("Are you sure you want to delete this playlist?")
                end
            end
            menu.choice "<- Back"
        end
        main_menu
    end

    def return_exit
        puts "thanks for using!!!"
        sleep(2)
    end    
end


