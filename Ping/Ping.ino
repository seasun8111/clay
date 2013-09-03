const int TrigPin=2;
const int EchoPin=3;
const int TrigPin2=4;
const int EchoPin2=5;

float cm;
float cm2;
void setup()
{
  Serial.begin(9600);

  pinMode(TrigPin, OUTPUT);
  pinMode(EchoPin, INPUT);
  
  pinMode(TrigPin2, OUTPUT);
  pinMode(EchoPin2, INPUT);
  
}
void loop()
{  
  digitalWrite(TrigPin, LOW); //低高低电平发一个短时间脉冲去TrigPin
  delayMicroseconds(2);
  digitalWrite(TrigPin, HIGH);
  delayMicroseconds(10);
  digitalWrite(TrigPin, LOW);
  float resp =   pulseIn(EchoPin, HIGH);
  
//  delayMicroseconds(20);
//  
//  digitalWrite(TrigPin2, LOW); //低高低电平发一个短时间脉冲去TrigPin
//  delayMicroseconds(2);
//  digitalWrite(TrigPin2, HIGH);
//  delayMicroseconds(10);
//  digitalWrite(TrigPin2, LOW);
//  float resp2 =   pulseIn(EchoPin2, HIGH);
  
  cm = resp / 58.0; //将回波时间换算成cm
//  cm2 = resp2 / 58.0; //将回波时间换算成cm
//  cm = (int(cm * 100.0)) / 100.0; //保留两位小数
  Serial.print("s1_");
  Serial.println(cm);  
    delay(45);
  Serial.print("s2_");
  Serial.println(cm); 
    delay(45);
  

//  Serial.println(cm2);
//  delay(100);
}


