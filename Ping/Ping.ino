const int TrigPin=2;
const int EchoPin=3;
const int TrigPin2=4;
const int EchoPin2=5;

void setup()
{
  Serial1.begin(9600);

  pinMode(TrigPin, OUTPUT);
  pinMode(EchoPin, INPUT);
  
  pinMode(TrigPin2, OUTPUT);
  pinMode(EchoPin2, INPUT);
  
}

float ping1(){ 
  return ping(TrigPin,EchoPin);
}

float ping2(){
  return ping(TrigPin2,EchoPin2);
}

float ping( int tx, int rx ){
  digitalWrite(tx, LOW); //低高低电平发一个短时间脉冲去TrigPin
  delayMicroseconds(2);
  digitalWrite(tx, HIGH);
  delayMicroseconds(10);
  digitalWrite(tx, LOW);
  float resp =   pulseIn(rx, HIGH);
  float cm = resp / 58.0; //将回波时间换算成cm
  cm = (int(cm * 100.0)) / 100.0; //保留两位小数  
  return cm;
}


void loop()
{  
//    Serial1.println("s1_aaaaaaaaa");
  float cm1 =  ping1();
  Serial1.print("s1_");
  Serial1.println(cm1);  
  
  delayMicroseconds(100);
  
  float cm2  =   ping2();
  Serial1.print("s2_");
  Serial1.println(cm2); 
  
  delay(100); 
}


