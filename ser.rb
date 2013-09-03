#require 'rubygems'  
require 'serialport'
require File.dirname(__FILE__) + '/ard.rb'
require 'rexml/document'
include REXML

class RangerMonitor

    @@iGotIt = 0

    @portNum
    @targetRang
    @pingTimes
    @adr
    #程序的初始
    def initialize(portNum=4, targetRang=150.00 ,sonarNo,totalSno)
        puts "开始..."
        puts "targetRang = #{targetRang}"
        puts "portNum = #{portNum}"
        @portNum = portNum
        @targetRang = targetRang
        @pingTimes = 10
        @adr = Adr.new
        @rangPipl = []
        @sonarNo = sonarNo
        @totalSno = totalSno
    end
        #"COM5", 9600 , 8,1,SerialPort::NONE
        #ruby j:\GitHub\clay\ser.rb

    #开始执行啦…………
    def start
        @playing = false
        mySp  = SerialPortReader.new 

        mySp.readline do |line|
            if(line.split("_")[0]==@sonarNo)
                origValue = line.split("_")[1]
            else
                next
            end
            #对距离取绝对值，因为有时会出些负值。
            aRange = origValue.to_i.abs
            #后台打印一下 方便程序猿看
            # puts aRange              
            #取距离值
            avgRange = calulateRange(aRange)
            #如果距离不是无效的就执行放视频的函数
            if avgRange != -99
                playVideo(avgRange)
            end
        end
        puts "结束执行啦…………"
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
        puts "#{@sonarNo}  @rangPipl = #{@rangPipl}"
        calulateAvg
        standardsV = Math.sqrt((@rangPipl.inject(0){ |r,x| r + ((x - @avg )**2 )}) / @rangPipl.length)        
        return standardsV
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

    #放视频
    def playVideo(avgRange) 

        if(avgRange > @targetRang && @@iGotIt >0) 
            @@iGotIt = @@iGotIt-1
        elsif(@@iGotIt < @totalSno)
            @@iGotIt = @@iGotIt+1                
        end

        # puts "平均距离#{avgRange}"
        #平均距离小于targetRang就放片
        if avgRange <= @targetRang && !@playing
            playMainVideo
            @playing = true
        #观众离开并且正在播放时，就切换到默认片
        elsif(avgRange > @targetRang && @@iGotIt<=0 && @playing)            
            playSecondVideo
            @playing = false
        end
    end

    #放主视频
    def playMainVideo()
        puts "I got it #{@@iGotIt}"
        xmldoc = REXML::Document.new(File.read("video.xml"))
        videoPath =  XPath.first(xmldoc, "//main").text
        thr = Thread.new { @adr.play(videoPath) }
        puts "有人接近！ 开始放视频"
    end

    #放默认片。
    def playSecondVideo()        
        puts "I got it #{@@iGotIt}"
        xmldoc = REXML::Document.new(File.read("video.xml")) 
        videoPath =  XPath.first(xmldoc, "//second").text
        thr = Thread.new { @adr.play(videoPath) }
        puts "客人走了,放默认片。"
    end


    def testTh(xx)
        puts xx
        while true

            puts xx
            
        end

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
    com = XPath.first(xmldoc, "//com").text    
 
    distance = XPath.first(xmldoc, "//distance").text    
    # 设定 com4口 目标距离150.00厘米    
    monitor1 = RangerMonitor.new(com, distance.to_i ,'s1',2)
    monitor2 = RangerMonitor.new(com, distance.to_i ,'s2',2)
    puts "star1"
    th11 = Thread.new { monitor1.start }.join
    puts "star2"
    th22 = Thread.new { monitor2.start }.join

end