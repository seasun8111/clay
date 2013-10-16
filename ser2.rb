#require 'rubygems'  
require 'thread'
require 'serialport'
require File.dirname(__FILE__) + '/ard.rb'
require 'rexml/document'
include REXML

class SerialPortReader
  def readline
    xmldoc = REXML::Document.new(File.read("video.xml")) 
    portName = XPath.first(xmldoc, "//com").text
    puts "portName  is #{portName}"
    sp = SerialPort.open(portName, 9600 , 8,1,SerialPort::NONE) do |sp|
      line =""
          while true    
                c = sp.read(1)    
                line = line + c.to_s
                if c=="\n"
                  #处理
                  yield line

                  line = ""
                end
          end  
    end
  end
end


class ReadDistThread
    attr :distHash,true
    attr :threadHash,true
    attr :cvHash,true
    @cv = ConditionVariable.new    
    @arraySize = 0
 

    def initialize(arraySize) 
        @distHash = {}
        @threadHash = {}
        @cvHash = {}
        @cv = ConditionVariable.new

        
        @arraySize = arraySize
    end

    # 读距离的线程,并添加到指定的数组内
    def readDistinance
        mySp  = SerialPortReader.new 
        mySp.readline do |distinance|
            # s1=> [距离1, 距离2, 距离3, 距离n...]
            # s2=> [距离1, 距离2, 距离3, 距离n...]
            # s3=> [距离1, 距离2, 距离3, 距离n...]
            #根据前缀来创建距离数组,并push新的距离
            # puts "distinance #{distinance}"
            xx = distinance.split("_")
            prefix = xx[0]
            value = xx[1].to_i


            if ( @distHash.key?(prefix) )
                arr = @distHash[prefix]
                # @threadHash[prefix].synchronize {
                    arr.push(value) 
                    arr.shift if arr.size>@arraySize
                    
                    puts "#{prefix} size =  #{arr.size} #{arr} "                    
                    if(arr.size>=@arraySize)
                        # puts "#{prefix} #{arr}"
                        @cvHash[prefix].signal
                        # @cvHash[prefix].wait(@threadHash[prefix])                        
                    end
                # }

            else
                @threadHash[prefix] = Mutex.new
                # @threadHash[prefix].synchronize {
                    puts "new #{prefix}"
                    @distHash[prefix] = []
                    @distHash[prefix].push(value)
                    @cvHash[prefix] =[]
                    @cvHash[prefix] = ConditionVariable.new
                # }
                
            end
        end
    end
end

################################################################
################################################################
################################################################

class Monitors
    @@iGotIt = 0
    @@playing = false
    @rangPipl
    @lock
    @sno

    def initialize(readDistThread, sno , targetRang)
        @readDistThread = readDistThread
        @sno = sno
        @rangPipl = readDistThread.distHash[sno]
        @rangPiplClone = @rangPipl
        @lock = readDistThread.threadHash[sno]
        @cv = readDistThread.cvHash[sno]
        @targetRang = targetRang
        @adr = Adr.new


    end

    def x1        
        while true
            @lock.synchronize {
                #如果距离不是无效的就执行放视频的函数       
                # puts "#{@sno} calulateRange"                
                avgRange = calulateRange
                # puts "if avgRange != -99"
                if avgRange != -99
                    # puts "playVideo(avgRange)"
                    playVideo(avgRange)
                end
                # puts "@cv.wait(@lock)"
                @cv.wait(@lock)
            }
        end
    end


    #计算距离
    def calulateRange()
        @rangPipl = @readDistThread.distHash[@sno][0,10].clone
        # puts "@rangPipl #{@rangPipl}"
        #标准差小于1
        if calculateSavg <= 1
            return @avg
        end
        return -99
    end


    #消除异常值
    def removeDiffV()
        
        @avg = (@rangPipl.reduce(:+).to_f / @rangPipl.size)
        
        # puts "@avg  #{@avg}"
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
        # puts "#{@sno}  @rangPipl = #{@rangPipl}"
        calulateAvg

        standardsV = Math.sqrt((@rangPipl.inject(0){ |r,x| r + ((x - @avg )**2 )}) / @rangPipl.length)        
        return standardsV
    end

    #放视频
    def playVideo(avgRange) 
        # puts "1111"
        if(avgRange > @targetRang && @@iGotIt >0) 
            @@iGotIt = @@iGotIt-1
        elsif(@@iGotIt < @readDistThread.distHash.size)
            @@iGotIt = @@iGotIt+1                
        end

        puts "#{@sno}  平均距离#{avgRange}"
        #平均距离小于targetRang就放片
        if avgRange <= @targetRang && !@@playing
            playMainVideo
            @@playing = true
        #观众离开并且正在播放时，就切换到默认片
        elsif(avgRange > @targetRang && @@iGotIt<=0 && @@playing)            
            playSecondVideo
            @@playing = false
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

end



#启动
if __FILE__ == $0

    # xmldoc = REXML::Document.new(File.read("video.xml"))
    # com = XPath.first(xmldoc, "//com").text    
 
    # distance = XPath.first(xmldoc, "//distance").text    

    # Thread.new{ReadDistThread.new}

    # # 设定 com4口 目标距离150.00厘米    
    # monitor1 = RangerMonitor.new(com, distance.to_i ,'s1',2)
    # monitor2 = RangerMonitor.new(com, distance.to_i ,'s2',2)
    # puts "star1"
    # th11 = Thread.new { monitor1.start }.join
    # puts "star2"
    # th22 = Thread.new { monitor2.start }.join


    xmldoc = REXML::Document.new(File.read("video.xml"))
    com = XPath.first(xmldoc, "//com").text    
    puts "Reading #{com} ...."
    distance = XPath.first(xmldoc, "//distance").text    
    puts "Destance is #{distance}."
    rt = ReadDistThread.new(10)        
    Thread.new { rt.readDistinance }
    

    sleep 3
 
    
    mo1 = Monitors.new(rt,'s1',distance.to_f)
    Thread.new {mo1.x1}
    mo2 = Monitors.new(rt,'s2',distance.to_f)
    Thread.new {mo2.x1}.join



    # mo2 = Monitors.new(rt,'s2')
    # Thread.new {mo2.x1}

    # while true
        
    # end
end