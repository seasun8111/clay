#!/usr/bin/env ruby
#>gem i -r serialport
class Adr 

    attr_accessor :media, :player

    def initialize(media="j:\\DN-33.mkv")

        
        @player = "D:\\PotPlayer_1.5.34115\\PotPlayerMini"
    end

    def play(videoPath)
        `cmd /c start #{@player} #{videoPath}`
        rescue Exception => e        
    end
end

#启动
if __FILE__ == $0
 adr = Adr.new
 adr.play    
end