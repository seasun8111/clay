#require 'rubygems'  
require 'serialport'
require File.dirname(__FILE__) + '/ard.rb'
require 'rexml/document'
include REXML


    xmldoc = REXML::Document.new(File.read("video.xml")) 
    portName = XPath.first(xmldoc, "//com").text
    puts portName
    sp = SerialPort.open(portName, 9600 , 8,1,SerialPort::NONE) do |sp|
      line =""
      while true    
        c = sp.read(1)    
        line = line + c
        if c=="\n"
          #处理
          puts line

          line = ""
        end
      end  
    end
  
