#require 'rubygems'  
require 'serialport'
require File.dirname(__FILE__) + '/ard.rb'

class RangerMonitor

    @portNum
    @targetRang
    @pingTimes
    @adr
    #程序的初始
    def initialize(portNum=4, targetRang=150.00)
        puts "开始..."
        @portNum = portNum
        @targetRang = targetRang
        @pingTimes = 10
        @adr = Adr.new
        @rangPipl = []
    end

    #开始执行啦…………
    def start
        @playing = false        
        #连上指定的端口号，9600波特率
        sp = SerialPort.new @portNum-1, 9600
        # 从端口里一行行读距离值，不停地读
        while r = sp.readlines
          #如果成功读到
          if r.length>0
                #把距离取下绝对值，因为有时会出些负值。
                aRange = r[0].to_i.abs
                #后台打印一下 方便程序猿看
                puts aRange
              
                #取距离值
                avgRange = calulateRange(aRange)
                #如果距离不是无效的就执行放视频的函数
                if avgRange != -99
                    playVideo(avgRange)
                end
           end
          #等0.1秒再读一次
          sleep 0.1
        end
    end
    
    #计算标准差
    def calculateSavg()        
        Math.sqrt((@rangPipl.inject(0){ |r,x| r + ((x -  (@rangPipl.reduce(:+).to_f / @rangPipl.size) ) ** 2 ) }) / @rangPipl.length)
    end

    #放视频
    def playVideo(avgRange) 
        puts "平均距离#{avgRange}"
        #平均距离小于targetRang就放片
        if avgRange <= @targetRang && !@playing
            playMainVideo
            @playing = true
        #观众离开并且正在播放时，就切换到默认片
        elsif(avgRange > @targetRang && @playing)
            playSecondVideo
            @playing = false
        end
    end

    #计算距离
    def calulateRange(aRange)
        #  [距离1, 距离2, 距离3, 距离n...]
        @rangPipl.push(aRange)

        #测距稳定了(样本数够了，并且标准差小于1)
        if @rangPipl.length >= @pingTimes &&　calculateSavg <= 1
            #计算平均距离
            avgRange = @rangPipl.reduce(:+).to_f / @rangPipl.size
            @rangPipl.shift
            return avgRange
        end
        @rangPipl.shift
        reaRangun -99        
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

