byte fb_data[5+6+1];
unsigned long time_stamp = 0;
unsigned short X = 0;
unsigned short Y = 0;
unsigned short Z = 0;
unsigned short time_stamp_regulator = 0x7F;
unsigned short data_regulator = 0x3F;
void setup() {
  // put your setup code here, to run once:
  Serial.begin(115200);
  fb_data[11]=255;
  // Special designed terminator.
  // Under no occasions the data value would equal to this one.
  // #FFFF is impossible for data reading and 
}

void loop() {
  time_stamp = micros();
  //if analogRead(A3) < 300 {
  X=analogRead(A0);
  Y=analogRead(A1);
  Z=analogRead(A2);
  fb_data[0]=(time_stamp>>28)&time_stamp_regulator;
  fb_data[1]=(time_stamp>>21)&time_stamp_regulator;
  fb_data[2]=(time_stamp>>14)&time_stamp_regulator;
  fb_data[3]=(time_stamp>>7)&time_stamp_regulator;
  fb_data[4]=(time_stamp)&time_stamp_regulator;
  fb_data[5]=X>>6;
  fb_data[6]=X&data_regulator;
  fb_data[7]=Y>>6;
  fb_data[8]=Y&data_regulator;
  fb_data[9]=Z>>6;
  fb_data[10]=Z&data_regulator;
  fb_data[10]=fb_data[10]|(unsigned short)(0x40*(analogRead(A4) < 300));
  Serial.write(fb_data,12);
  }
}
