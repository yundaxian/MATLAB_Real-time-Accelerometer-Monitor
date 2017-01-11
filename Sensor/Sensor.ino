/* 
  Structural Health Monitoring Device

  Reads accelerometer data and upload it
  to a remote server/cloud for it to be
  retrieved anywhere via MATLAB.
  
  To do:
    - Fix the resolution
    - Make the device upload data for IOT purposes
  
  CREDITS:
    * ADXL Accelerometer Code Sample 
        by e-Gizmo Mechatronix Central (http://www.e-gizmo.com)
    * 
      
*/



// Pin usage, change assignment if you want to
const byte  spiclk=17;    // connect to ADXL CLK
const byte  spimiso=16;  // connect to ADXL DO
const byte spimosi=15;  // connect to ADXL DI
const byte spics=14;    // connect to ADXL CS
// Don't forget, connect ADXL VDD-GND to gizDuino/Arduino +3.3V-GND


byte  xyz[8];  // raw data storage
int x,y,z;    // x, y, z accelerometer data

byte spiread;

void setup(void){
  Serial.begin(9600);      // serial i/o for test output
  init_adxl();            // initialize ADXL345
  
}

void loop(void){

  read_xyz();            // read ADXL345 accelerometer

  Serial.print(x);
  Serial.print(",");
  Serial.print(y);
  Serial.print(",");
  Serial.println(z);
  
  delay(20);
}

/*   
    Bit bang SPI function 
    
  All SPI interface pins of the ADXL345 must be provided
  with pull-up resistors (to 3.3V, 3.3Kto 10K ohm) in order
  to work using this code.e-Gizmo ADXL345 breakout board
  already has these parts on board, hence is ready for use
  without any modifications.
  Principle of operation:
  A 3.3V logic 1 output is effected by configuring
  the driving pin as input, letting the pull up resistor
  take the logic level up to 3.3V only. A logic 0 output
  is generated by configuring the driving pin to output.
*/

void spi_out(byte spidat){
  byte bitnum=8;

    spiread=0;
    // start spi bit bang
    while(bitnum>0){
       
      pinMode(spiclk,OUTPUT);    // SPI CLK =0
      if((spidat & 0x80)!=0)
        pinMode(spimosi,INPUT);  // MOSI = 1 if MSB =1
        else
        pinMode(spimosi,OUTPUT);  // else MOSI = 0
      
      spidat=spidat<<1; 
      pinMode(spiclk,INPUT);  // SPI CLK = 1
      
      // read spi data
      spiread=spiread<<1;
      
      if(digitalRead(spimiso)==HIGH) spiread |= 0x01; // shift in a 1 if MISO is 1

      pinMode(spimosi,INPUT);  // reset MOSI to 1
      bitnum--; 
    }

  
}

/*  Initialize ADXL345 */

void  init_adxl(void){
  delay(250);
  pinMode(spics,OUTPUT);  // CS=0   
  //Write to register 0x31, DATA FORMAT
  spi_out(0x31);
  // uncomment your desired range
  //spi_out(0x0B); //full resolution, +/- 16g range
  //spi_out(0x0A); //full resolution, +/- 8g range
  //spi_out(0x09); //full resolution, +/- 4g range
  spi_out(0x08); //full resolution, +/- 2g range
  
  pinMode(spics,INPUT);  //CS HIGH
  delay(1);
    pinMode(spics,OUTPUT);  // CS=0   
  
  // Write to register 0x2d, POWER_CTL
  spi_out(0x2d);
  //set to measure mode
  spi_out(0x08);
  pinMode(spics,INPUT);  //CS HIGH
  delay(1);
}

/*
   Read all 3 axis x,y,z
*/

void read_xyz(void){
  int i;
    pinMode(spics,OUTPUT);  // CS=0   
  //Set start address to 0x32
  //D7= 1 for read and D6=1 for sequential read
  spi_out(0xF2);
  // dump xyz content to array
  for(i=0;i<6;i++){
    spi_out(0x00);
    xyz[i]=spiread;
  }
  
  // merge to convert to 16 bits
  x=((int)xyz[1]<<8) + xyz[0];
  y=((int)xyz[3]<<8) + xyz[2];
  z=((int)xyz[5]<<8) + xyz[4];
  
  pinMode(spics,INPUT);  //CS HIGH
}
