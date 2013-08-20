#require 'rubygems'  
require 'serialport'
require File.dirname(__FILE__) + '/ard.rb'
require 'rexml/document'
include REXML

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
#"COM5", 9600 , 8,1,SerialPort::NONE
#ruby j:\GitHub\clay\ser.rb
    #开始执行啦…………
    def start
       puts "sdsdsdsd"
    end
    
    #消除异常值
    def removeDiffV()
        @avg = (@rangPipl.reduce(:+).to_f / @rangPipl.size)
        #取中间值
        midIndex = (@rangPipl.length/2).to_i

        
        mid = @rangPipl.length >= 5 ? (@rangPipl[midIndex]) : @rangPipl.first
        # puts "midIndex  = #{midIndex}"
        #判断样本中间，可能会去除一个不稳定值
        if( mid/@avg > 2 || @avg/mid > 2)
            if(@rangPipl.length>=5)
                @rangPipl[midIndex] = (@rangPipl[midIndex-1] +  @rangPipl[midIndex+1] )/2
            end

            if(@rangPipl.length<5)
                @rangPipl[0] = (@rangPipl[1] + @rangPipl[2])/2
                
            end
        end
    end

    #计算平均值
    def calulateAvg()        
        #消除异常值
        removeDiffV
        #取平均值
        @avg = (@rangPipl.reduce(:+).to_f / @rangPipl.size)
    end

    #计算标准差
    def calculateSavg()
        puts "@rangPipl = #{@rangPipl}"
        calulateAvg
        standardsV = Math.sqrt((@rangPipl.inject(0){ |r,x| r + ((x - @avg )**2 )}) / @rangPipl.length)        
        return standardsV
    end

    #放视频
    def playVideo(avgRange) 
        # puts "平均距离#{avgRange}"
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
        # puts @rangPipl.length
        if @rangPipl.length >= @pingTimes && calculateSavg <= 1
            @rangPipl.shift            
            return @avg
        end
        
        if @rangPipl.length >= @pingTimes
            @rangPipl.shift            
        end
        return -99        
    end

    #放主视频
    def playMainVideo()
        xmldoc = REXML::Document.new(File.read("video.xml"))     
        videoPath =  XPath.first(xmldoc, "//main").text
        thr = Thread.new { @adr.play(videoPath) }
        puts "有人接近！ 开始放视频"
    end

    #放默认片。
    def playSecondVideo()
        xmldoc = REXML::Document.new(File.read("video.xml")) 
        videoPath =  XPath.first(xmldoc, "//second").text
        thr = Thread.new { @adr.play(videoPath) }
        puts "客人走了,放默认片。"
    end


end

class SerialPortReader

  def readline
    xmldoc = REXML::Document.new(File.read("video.xml")) 
    portName = XPath.first(xmldoc, "//com").text
    sp = SerialPort.open(portName, 9600 , 8,1,SerialPort::NONE) do |sp|
      line =""
      while true    
        c = sp.read(1)    
        line = line + c
        if c=="\n"
          #处理
          yield line

          line = ""
        end
      end  
    end
  end
end

#启动
if __FILE__ == $0

    xmldoc = REXML::Document.new(File.read("video.xml")) 
    distance = XPath.first(xmldoc, "//distance").text    
    # 设定 com4口 目标距离150.00厘米    
    monitor = RangerMonitor.new(4, distance.to_i)
    monitor.start
end