const int TrigPin=2;
const int EchoPin=3;
float cm;
void setup()
{
  Serial1.begin(9600);
  pinMode(TrigPin, OUTPUT);
  pinMode(EchoPin, INPUT);
}
void loop()
{  
  digitalWrite(TrigPin, LOW); //低高低电平发一个短时间脉冲去TrigPin
  delayMicroseconds(2);
  digitalWrite(TrigPin, HIGH);
  delayMicroseconds(10);
  digitalWrite(TrigPin, LOW);
  float resp =   pulseIn(EchoPin, HIGH);
  cm = resp / 58.0; //将回波时间换算成cm
//  cm = (int(cm * 100.0)) / 100.0; //保留两位小数
  Serial1.println(cm);
  delay(100);
}


