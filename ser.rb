#require 'rubygems'  
require 'serialport'
require File.dirname(__FILE__) + '/ard.rb'

class RangerMonitor

    @portNum
    @targetRang
    @pingTimes
    @adr
    def initialize(portNum=4, targetRang=150.00)
        puts "开始..."
        @portNum = portNum
        @targetRang = targetRang
        @pingTimes = 10
        @adr = Adr.new
        @rangPipl = []
    end


    def start
        @playing = false        
        sp = SerialPort.new @portNum-1, 9600
        while r = sp.readlines            
          if r.length>0        
            tr = r[0].to_i.abs
            puts tr
          end
            #取距离值
            avgRang = calulateRange(tr)
            #如果距离不是无效的就执行放视频的函数
            if avgRang != -99
                playVideo(avgRang)
            end
            sleep 0.1
        end

    end
    
    #计算标准差
    def calculateSavg()        
        Math.sqrt((@rangPipl.inject(0){ |r,x| r + ((x -  (@rangPipl.reduce(:+).to_f / @rangPipl.size) ) ** 2 ) }) / @rangPipl.length)
    end

    #放视频
    def playVideo(avgRang) 
        puts "平均距离#{avgRang}"
        #平均距离小于targetRang就放片
        if avgRang <= @targetRang && !@playing
            playMainVideo
            @playing = true
        #观众离开并且正在播放时，就切换到默认片
        elsif(avgRang > @targetRang && @playing)
            playSecondVideo
            @playing = false
        end
    end

    #计算距离
    def calulateRange(aRang)
        
        @rangPipl.push(aRang)

        #测距稳定了
        if @rangPipl.length >= @pingTimes &&　calculateSavg <= 1            
            #计算平均距离
            avgRang = @rangPipl.reduce(:+).to_f / @rangPipl.size
            @rangPipl.shift
            return avgRang
        end
        @rangPipl.shift
        retrun -99        
    end

    #放主视频
    def playMainVideo(*videoPath)
        thr = Thread.new { @adr.play("j:/[Fullmetal Alchemist The Movie][Conqueror of Shambala].rmvb") }
        puts "有人接近！ 开始放视频"
    end

    #放默认片。
    def playSecondVideo(*videoPath)                
        thr = Thread.new { @adr.play("j:/flower.mkv") }
        puts "客人走了,放默认片。"
    end


end

#启动
if __FILE__ == $0

    # 设定 com4口 目标距离150.00厘米
    monitor = RangerMonitor.new(5, 150)
    monitor.start
end

