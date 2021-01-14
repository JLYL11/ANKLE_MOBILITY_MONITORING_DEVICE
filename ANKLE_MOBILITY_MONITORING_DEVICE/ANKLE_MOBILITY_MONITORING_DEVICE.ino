// REFERENCES:
//
// Complementary filter
// https://forum.arduino.cc/index.php?topic=58048.0
// https://github.com/TKJElectronics/Example-Sketch-for-IMU-including-Kalman-filter/blob/master/IMU/MPU6050/MPU6050.ino
//
// Low pass butterworth filter
// http://www.schwietering.com/jayduino/filtuino/index.php
//
// LSM9DS1 Library
// https://github.com/sparkfun/SparkFun_LSM9DS1_Arduino_Library/blob/master/examples/LSM9DS1_Basic_I2C/LSM9DS1_Basic_I2C.ino

#include <Wire.h>
#include <SPI.h>
#include <SparkFunLSM9DS1.h>


//////////////////////////
// LSM9DS1 Library Init //
//////////////////////////

LSM9DS1 imu1;
LSM9DS1 imu2;
LSM9DS1 imu3;
LSM9DS1 imu4;

////////////////////////////
// Sketch Output Settings //
////////////////////////////

#define PRINT_SPEED 100 // 100 ms between prints = 10Hz
static unsigned long lastPrint = 0; // Keep track of print time

////////////////////////////
//  BLUETOOTH             //
////////////////////////////  

Stream *mySerial; //https://forum.pjrc.com/threads/57732-Trouble-passing-Serial-Serial1-Serial2-as-a-reference
static bool BT_ON = true;

/////////////////////////////
//  Complementary Filter   //
///////////////////////////// 

uint32_t timer;
int sampling_rate = 952; // hz

double imu1_gyroXangle, imu1_gyroYangle; // Angle calculate using the gyro only
double imu1_compAngleX, imu1_compAngleY; // Calculated angle using a complementary filter

double imu1_gyroXangle_filtered, imu1_gyroYangle_filtered; // Angle calculate using the gyro only
double imu1_compAngleX_filtered, imu1_compAngleY_filtered; // Calculated angle using a complementary filter

double imu2_gyroXangle_filtered, imu2_gyroYangle_filtered; // Angle calculate using the gyro only
double imu2_compAngleX_filtered, imu2_compAngleY_filtered; // Calculated angle using a complementary filter

double imu3_gyroXangle_filtered, imu3_gyroYangle_filtered; // Angle calculate using the gyro only
double imu3_compAngleX_filtered, imu3_compAngleY_filtered; // Calculated angle using a complementary filter

double imu4_gyroXangle_filtered, imu4_gyroYangle_filtered; // Angle calculate using the gyro only
double imu4_compAngleX_filtered, imu4_compAngleY_filtered; // Calculated angle using a complementary filter

////////////////////////////
// Low Pass Filter Class  //
////////////////////////////

class  FilterBuLp4 //Low pass butterworth filter order=4 alpha1=0.010504201680672 cutoff = 10hz
{
  public:
    FilterBuLp4()
    {
      for(int i=0; i <= 4; i++)
        v[i]=0.0;
    }
  private:
    float v[5];
  public:
    float step(float x) //class II 
    {
      v[0] = v[1];
      v[1] = v[2];
      v[2] = v[3];
      v[3] = v[4];
      v[4] = (1.089491853255297737e-6 * x)
         + (-0.84155610321383489403 * v[0])
         + (3.51135138957648562652 * v[1])
         + (-5.49736197349180422123 * v[2])
         + (3.82754925525950140397 * v[3]);
      return 
         (v[0] + v[4])
        +4 * (v[1] + v[3])
        +6 * v[2];
    }
};

FilterBuLp4 f_gyro_x_imu1;
FilterBuLp4 f_gyro_y_imu1;
FilterBuLp4 f_gyro_z_imu1;

FilterBuLp4 f_gyro_x_imu2;
FilterBuLp4 f_gyro_y_imu2;
FilterBuLp4 f_gyro_z_imu2;

FilterBuLp4 f_gyro_x_imu3;
FilterBuLp4 f_gyro_y_imu3;
FilterBuLp4 f_gyro_z_imu3;

FilterBuLp4 f_gyro_x_imu4;
FilterBuLp4 f_gyro_y_imu4;
FilterBuLp4 f_gyro_z_imu4;

FilterBuLp4 f_acc_x_imu1;
FilterBuLp4 f_acc_y_imu1;
FilterBuLp4 f_acc_z_imu1;

FilterBuLp4 f_acc_x_imu2;
FilterBuLp4 f_acc_y_imu2;
FilterBuLp4 f_acc_z_imu2;

FilterBuLp4 f_acc_x_imu3;
FilterBuLp4 f_acc_y_imu3;
FilterBuLp4 f_acc_z_imu3;

FilterBuLp4 f_acc_x_imu4;
FilterBuLp4 f_acc_y_imu4;
FilterBuLp4 f_acc_z_imu4;



void setup()
{
    //SERIAL COMMS //
    if(BT_ON){
        mySerial = &Serial4; // Bluetooth
    }
    else{
        mySerial = &Serial;  // USB
    }
    Serial.begin(115200);
    //while (!Serial); // important otherwise signal lost if BT OFF
    Serial4.begin(9600);  // BT module baud rate is 9600

    Wire.begin();
    Wire1.begin();
    
    // CONFIG IMU //
    imu1.settings.accel.scale = 16; // Set accel range to +/-16g
    imu1.settings.gyro.scale = 2000; // Set gyro range to +/-2000dps
    imu1.settings.mag.enabled = false;
    imu1.settings.gyro.sampleRate = 6; // 6 = 952 Hz
    imu1.settings.accel.sampleRate = 6;  // 6 = 952 Hz

    imu2.settings.accel.scale = 16; // Set accel range to +/-16g
    imu2.settings.gyro.scale = 2000; // Set gyro range to +/-2000dps
    imu3.settings.accel.scale = 16; // Set accel range to +/-16g
    imu3.settings.gyro.scale = 2000; // Set gyro range to +/-2000dps
    imu4.settings.accel.scale = 16; // Set accel range to +/-16g
    imu4.settings.gyro.scale = 2000; // Set gyro range to +/-2000dps

    if (imu1.begin(0x6B, 0x1E) == false) // with no arguments, this uses default addresses (AG:0x6B, M:0x1E) and i2c port (Wire).
    {
    mySerial->print("Failed to communicate with LSM9DS1 n1.");
    mySerial->print("Double-check wiring.");
    mySerial->print("Default settings in this sketch will " \
                    "work for an out of the box LSM9DS1 " \
                    "Breakout, but may need to be modified " \
                    "if the board jumpers are.");
    while (1);
    }

    if (imu2.begin(0x6A, 0x1C) == false) // with no arguments, this uses default addresses (AG:0x6B, M:0x1E) and i2c port (Wire).
    {
    mySerial->print("Failed to communicate with LSM9DS1 n2.");
    mySerial->print("Double-check wiring.");
    mySerial->print("Default settings in this sketch will " \
                    "work for an out of the box LSM9DS1 " \
                    "Breakout, but may need to be modified " \
                    "if the board jumpers are.");
    while (1);
    }

    // WIRE1
    if (imu3.begin(0x6B, 0x1E, Wire1) == false) // with no arguments, this uses default addresses (AG:0x6B, M:0x1E) and i2c port (Wire).
    {
    mySerial->print("Failed to communicate with LSM9DS1 n3.");
    mySerial->print("Double-check wiring.");
    mySerial->print("Default settings in this sketch will " \
                    "work for an out of the box LSM9DS1 " \
                    "Breakout, but may need to be modified " \
                    "if the board jumpers are.");
    while (1);
    }

    if (imu4.begin(0x6A, 0x1C, Wire1) == false) // with no arguments, this uses default addresses (AG:0x6B, M:0x1E) and i2c port (Wire).
    {
    mySerial->print("Failed to communicate with LSM9DS1 n4.");
    mySerial->print("Double-check wiring.");
    mySerial->print("Default settings in this sketch will " \
                    "work for an out of the box LSM9DS1 " \
                    "Breakout, but may need to be modified " \
                    "if the board jumpers are.");
    while (1);
    }

    delay(100); // Wait for sensor to stabilize

}

void loop()
{
    // READ SENSOR VALUES //

    // Update the sensor values whenever new data is available
    // IMU1
    if ( imu1.gyroAvailable() )
    {
        imu1.readGyro();
    }
    if ( imu1.accelAvailable() )
    {
        imu1.readAccel();
    }
    // IMU2
    if ( imu2.gyroAvailable() )
    {
        imu2.readGyro();
    }
    if ( imu2.accelAvailable() )
    {
        imu2.readAccel();
    }
    // IMU3
    if ( imu3.gyroAvailable() )
    {
        imu3.readGyro();
    }
    if ( imu3.accelAvailable() )
    {
        imu3.readAccel();
    }
    // IMU4
    if ( imu4.gyroAvailable() )
    {
        imu4.readGyro();
    }
    if ( imu4.accelAvailable() )
    {
        imu4.readAccel();
    }

    // LOW PASS FILTER ON RAW DATA
    float gx_imu1_filtered = f_gyro_x_imu1.step(imu1.gx);
    float gy_imu1_filtered = f_gyro_y_imu1.step(imu1.gy);
    float gz_imu1_filtered = f_gyro_z_imu1.step(imu1.gz);

    float gx_imu2_filtered = f_gyro_x_imu2.step(imu2.gx);
    float gy_imu2_filtered = f_gyro_y_imu2.step(imu2.gy);
    float gz_imu2_filtered = f_gyro_z_imu2.step(imu2.gz);

    float gx_imu3_filtered = f_gyro_x_imu3.step(imu3.gx);
    float gy_imu3_filtered = f_gyro_y_imu3.step(imu3.gy);
    float gz_imu3_filtered = f_gyro_z_imu3.step(imu3.gz);

    float gx_imu4_filtered = f_gyro_x_imu4.step(imu4.gx);
    float gy_imu4_filtered = f_gyro_y_imu4.step(imu4.gy);
    float gz_imu4_filtered = f_gyro_z_imu4.step(imu4.gz);

    float ax_imu1_filtered = f_acc_x_imu1.step(imu1.ax);
    float ay_imu1_filtered = f_acc_y_imu1.step(imu1.ay);
    float az_imu1_filtered = f_acc_z_imu1.step(imu1.az);
    
    float ax_imu2_filtered = f_acc_x_imu2.step(imu2.ax);
    float ay_imu2_filtered = f_acc_y_imu2.step(imu2.ay);
    float az_imu2_filtered = f_acc_z_imu2.step(imu2.az);

    float ax_imu3_filtered = f_acc_x_imu3.step(imu3.ax);
    float ay_imu3_filtered = f_acc_y_imu3.step(imu3.ay);
    float az_imu3_filtered = f_acc_z_imu3.step(imu3.az);

    float ax_imu4_filtered = f_acc_x_imu4.step(imu4.ax);
    float ay_imu4_filtered = f_acc_y_imu4.step(imu4.ay);
    float az_imu4_filtered = f_acc_z_imu4.step(imu4.az);

    double dt = (double)(micros() - timer) / 1000000; // Calculate delta time
    timer = micros();


// RAW Complimentary filter
/*
    double imu1_gyroXrate = imu1.calcGyro(imu1.gx); // Convert to deg/s
    double imu1_gyroYrate = imu1.calcGyro(imu1.gy); // Convert to deg/s


    imu1_compAngleX = roll(imu1);
    imu1_compAngleY = pitch(imu1);
    
    imu1_gyroXangle += imu1_gyroXrate * dt; // Calculate gyro angle without any filter
    imu1_gyroYangle += imu1_gyroYrate * dt;

    imu1_compAngleX = 0.93 * (imu1_compAngleX + imu1_gyroXrate * dt) + 0.07 * roll(imu1); // Calculate the angle using a Complimentary filter
    imu1_compAngleY = 0.93 * (imu1_compAngleY + imu1_gyroYrate * dt) + 0.07 * pitch(imu1);
*/

// FILTERED RAW with Complementary filter

    // IMU1
    double imu1_gyroXrate_filtered = imu1.calcGyro(gx_imu1_filtered); // Convert to deg/s
    double imu1_gyroYrate_filtered = imu1.calcGyro(gy_imu1_filtered); // Convert to deg/s

    imu1_compAngleX_filtered = atan2(ay_imu1_filtered, az_imu1_filtered) * 180.0 / PI;; // roll
    imu1_compAngleY_filtered = atan2(-ax_imu1_filtered, sqrt(ay_imu1_filtered * ay_imu1_filtered + az_imu1_filtered * az_imu1_filtered)) * 180.0 / PI;; // pitch
    
    imu1_gyroXangle_filtered += imu1_gyroXrate_filtered * dt; // Calculate gyro angle without any filter
    imu1_gyroYangle_filtered += imu1_gyroYrate_filtered * dt;

    imu1_compAngleX_filtered = 0.93 * (imu1_compAngleX_filtered + imu1_gyroXrate_filtered * dt) + 0.07 * imu1_compAngleX_filtered; // Calculate the angle using a Complimentary filter
    imu1_compAngleY_filtered = 0.93 * (imu1_compAngleY_filtered + imu1_gyroYrate_filtered * dt) + 0.07 * imu1_compAngleY_filtered;

    // IMU2
    double imu2_gyroXrate_filtered = imu2.calcGyro(gx_imu2_filtered); // Convert to deg/s
    double imu2_gyroYrate_filtered = imu2.calcGyro(gy_imu2_filtered); // Convert to deg/s

    imu2_compAngleX_filtered = atan2(ay_imu2_filtered, az_imu2_filtered) * 180.0 / PI;; // roll
    imu2_compAngleY_filtered = atan2(-ax_imu2_filtered, sqrt(ay_imu2_filtered * ay_imu2_filtered + az_imu2_filtered * az_imu2_filtered)) * 180.0 / PI;; // pitch
    
    imu2_gyroXangle_filtered += imu2_gyroXrate_filtered * dt; // Calculate gyro angle without any filter
    imu2_gyroYangle_filtered += imu2_gyroYrate_filtered * dt;

    imu2_compAngleX_filtered = 0.93 * (imu2_compAngleX_filtered + imu2_gyroXrate_filtered * dt) + 0.07 * imu2_compAngleX_filtered; // Calculate the angle using a Complimentary filter
    imu2_compAngleY_filtered = 0.93 * (imu2_compAngleY_filtered + imu2_gyroYrate_filtered * dt) + 0.07 * imu2_compAngleY_filtered;

    // IMU3
    double imu3_gyroXrate_filtered = imu3.calcGyro(gx_imu3_filtered); // Convert to deg/s
    double imu3_gyroYrate_filtered = imu3.calcGyro(gy_imu3_filtered); // Convert to deg/s

    imu3_compAngleX_filtered = atan2(ay_imu3_filtered, az_imu3_filtered) * 180.0 / PI;; // roll
    imu3_compAngleY_filtered = atan2(-ax_imu3_filtered, sqrt(ay_imu3_filtered * ay_imu3_filtered + az_imu3_filtered * az_imu3_filtered)) * 180.0 / PI;; // pitch
    
    imu3_gyroXangle_filtered += imu3_gyroXrate_filtered * dt; // Calculate gyro angle without any filter
    imu3_gyroYangle_filtered += imu3_gyroYrate_filtered * dt;

    imu3_compAngleX_filtered = 0.93 * (imu3_compAngleX_filtered + imu3_gyroXrate_filtered * dt) + 0.07 * imu3_compAngleX_filtered; // Calculate the angle using a Complimentary filter
    imu3_compAngleY_filtered = 0.93 * (imu3_compAngleY_filtered + imu3_gyroYrate_filtered * dt) + 0.07 * imu3_compAngleY_filtered;

    // IMU4
    double imu4_gyroXrate_filtered = imu4.calcGyro(gx_imu4_filtered); // Convert to deg/s
    double imu4_gyroYrate_filtered = imu4.calcGyro(gy_imu4_filtered); // Convert to deg/s

    imu4_compAngleX_filtered = atan2(ay_imu4_filtered, az_imu4_filtered) * 180.0 / PI;; // roll
    imu4_compAngleY_filtered = atan2(-ax_imu4_filtered, sqrt(ay_imu4_filtered * ay_imu4_filtered + az_imu4_filtered * az_imu4_filtered)) * 180.0 / PI;; // pitch
    
    imu4_gyroXangle_filtered += imu4_gyroXrate_filtered * dt; // Calculate gyro angle without any filter
    imu4_gyroYangle_filtered += imu4_gyroYrate_filtered * dt;

    imu4_compAngleX_filtered = 0.93 * (imu4_compAngleX_filtered + imu4_gyroXrate_filtered * dt) + 0.07 * imu4_compAngleX_filtered; // Calculate the angle using a Complimentary filter
    imu4_compAngleY_filtered = 0.93 * (imu4_compAngleY_filtered + imu4_gyroYrate_filtered * dt) + 0.07 * imu4_compAngleY_filtered;

/*  // SOME PLOTS //
    Serial.print(ax_imu1_filtered); Serial.print("\t");
    Serial.print(ay_imu1_filtered); Serial.print("\t");
    Serial.print(az_imu1_filtered); Serial.print("\t");

    Serial.print(gx_imu1_filtered); Serial.print("\t");
    Serial.print(gy_imu1_filtered); Serial.print("\t");
    Serial.print(gz_imu1_filtered); Serial.print("\t");

    Serial.print(imu1.ax); Serial.print("\t");
    Serial.print(imu1.ay); Serial.print("\t");
    Serial.print(imu1.az); Serial.print("\t");

    Serial.print(imu1.calcGyro(imu1.gx)); Serial.print("\t");
    Serial.print(imu1.calcGyro(imu1.gy)); Serial.print("\t");
    Serial.print(imu1.calcGyro(imu1.gz)); Serial.print("\t");

    Serial.print(roll(imu1)); Serial.print("\t");
    Serial.print(imu1_compAngleX + 20); Serial.print("\t");
    Serial.print(imu1_compAngleX_filtered); Serial.print("\t");

    Serial.print("\t");

    Serial.print(pitch(imu1)); Serial.print("\t");
    Serial.print(imu1_compAngleY); Serial.print("\t");
    Serial.print(imu1_compAngleY_filtered); Serial.print("\t");

    Serial.print("\r\n");
*/


    while((micros()- timer < ( (1*1000*1000)/sampling_rate))){} // pause 1050us diff (sampling rate 952 hz)
 

    // PRINT SENSOR VALUES //
    unsigned long currentMillis = millis();
    if ((lastPrint + PRINT_SPEED) < currentMillis)
    {
        for (uint8_t i = 0; i<10; i++) 
        {
            switch (i) {
                case 0:
                    if(BT_ON){
                    mySerial->print("0edBT");
                    }
                    else{
                    mySerial->print("0edUSB");
                    }
                    break;
                case 1:
                    mySerial->print(currentMillis);
                    break;
                case 2:
                    mySerial->print(imu1_compAngleY_filtered, 2);  // PITCH IMU1
                    break;
                case 3:
                    mySerial->print(imu1_compAngleX_filtered, 2);  // ROLL IMU1
                    break;
                case 4:
                    mySerial->print(imu2_compAngleY_filtered, 2);  // PITCH IMU2
                    break;
                case 5:
                    mySerial->print(imu2_compAngleX_filtered, 2);  // ROLL IMU2
                    break;
                case 6:
                    mySerial->print(imu3_compAngleY_filtered, 2);  // PITCH IMU3
                    break;
                case 7:
                    mySerial->print(imu3_compAngleX_filtered, 2);  // ROLL IMU3
                    break;
                case 8:
                    mySerial->print(imu4_compAngleY_filtered, 2);  // PITCH IMU4
                    break;
                case 9:
                    mySerial->print(imu4_compAngleX_filtered, 2);  // ROLL IMU4
                    break;
            }
            if (i < 10)
            mySerial->print(" ");
        }
        mySerial->print("\r");
        lastPrint = millis(); // Update lastPrint time
    } // end serial send
    

} // end main loop


float pitch(LSM9DS1 &imu) 
{
    float pitch = atan2(-imu.ax, sqrt(imu.ay * imu.ay + imu.az * imu.az));
    // Convert everything from radians to degrees:
    pitch *= 180.0 / PI;
    return pitch;
}

float roll(LSM9DS1 &imu) 
{
    float roll = atan2(imu.ay, imu.az);
    // Convert everything from radians to degrees:
    roll  *= 180.0 / PI;
    return roll;
}



