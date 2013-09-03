#require 'rubygems'  
require 'thread'

class S1
        
        attr :mu,true
        attr :cv,true 
        attr :count,true

        def initialize
            @mu = Mutex.new
            @count = 0
            @cv = ConditionVariable.new    
        end

        def fun 
            mu.synchronize {
                
                while true
                    @count = @count +1    
                    puts "s1 say #{@count}"

                    if(@count>=10)
                        @cv.signal
                        @cv.wait(mu)                        
                    end
                    sleep 0.2
                end                
            }
        end
end


class C1 
        
        def initialize(s1)
            @s1 = s1
            @mu = s1.mu
            @cv = s1.cv
        end
        
        def fun 
            while true
                @mu.synchronize {
                    puts "C1 say s1 count #{@s1.count}"
                    sleep 1
                    @s1.count = 0
                    @cv.signal
                    @cv.wait(@mu)
                    
                }
            end
        end
end

if __FILE__ == $0
   s1 = S1.new 
   c1 = C1.new(s1)
   Thread.new {s1.fun}
   sleep 1
   Thread.new {c1.fun}

   while true
       
   end



end