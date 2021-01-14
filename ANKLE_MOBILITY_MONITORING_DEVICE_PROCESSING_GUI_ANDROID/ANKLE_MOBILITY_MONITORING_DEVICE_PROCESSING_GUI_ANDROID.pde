// REFERENCES:
//
// Ketai
// https://gist.github.com/0xjac/1da786175f73fc4315daeed04a3d4a12
//
// ControlP5
// http://www.sojamo.de/libraries/controlP5/
//
// BUTTONS (because double tap issue cp5/Android) 
// https://forum.processing.org/two/discussion/comment/58607/#Comment_58607)


/**
 * <p>Ketai Library for Android: http://ketai.org</p>
 *
 * <p>KetaiBluetooth wraps the Android Bluetooth RFCOMM Features:
 * <ul>
 * <li>Enables Bluetooth for sketch through android</li>
 * <li>Provides list of available Devices</li>
 * <li>Enables Discovery</li>
 * <li>Allows writing data to device</li>
 * </ul>
 * <p>Updated: 2012-05-18 Daniel Sauter/j.duran</p>
 */
 
//required for BT enabling on startup
import android.content.Intent;
import android.os.Bundle;

import ketai.net.bluetooth.*;
import ketai.ui.*;
import ketai.net.*;
import ketai.data.*;

import oscP5.*;

import controlP5.*;

// Ketai BT
KetaiBluetooth bt;
String info = "";
KetaiList klist;
PVector remoteMouse = new PVector();

ArrayList<String> devicesDiscovered = new ArrayList();
boolean isConfiguring = true;
String UIText;

// Ketai databsase
KetaiSQLite db;
String db_name = "data7";
String CREATE_DB_SQL = "CREATE TABLE "+ db_name +" ( _id INTEGER PRIMARY KEY AUTOINCREMENT, DATE TEXT, RIGHT_MIN FLOAT NOT NULL, LEFT_MIN FLOAT NOT NULL);";

// cp5 interface stuff
ControlP5 cp5_MAIN;
Chart chart_right_leg;

// BUTTONS
ArrayList <SimpleButton> buttonList; 

// my app
boolean BTconfig = true;
boolean isApp = false;
boolean isCalibrated = false;
color clrbackgrd = color(232, 232, 232);


//********************************************************************
// The following code is required to enable bluetooth at startup.
//********************************************************************
void onCreate(Bundle savedInstanceState) {
  super.onCreate(savedInstanceState);
  bt = new KetaiBluetooth(this);
}

void onActivityResult(int requestCode, int resultCode, Intent data) {
  bt.onActivityResult(requestCode, resultCode, data);
}



// Serial variables
String inBuffer = "";
int i = 0; // loop variable

float[] samples_time = new float[0];

float min_angle_calc_leg_right = 360;
float min_angle_calc_leg_left = 360;

// Data variables
float pitch_IMU1 ;
float roll_IMU1 ;

float pitch_IMU2 ;
float roll_IMU2 ;

float pitch_IMU3 ;
float roll_IMU3 ;

float pitch_IMU4 ;
float roll_IMU4 ;

float pitch_IMU1_raw ;
float roll_IMU1_raw ;

float pitch_IMU2_raw  ;
float roll_IMU2_raw  ;

float pitch_IMU3_raw  ;
float roll_IMU3_raw  ;

float pitch_IMU4_raw  ;
float roll_IMU4_raw  ;

float pitch_IMU1_off = 0;
float roll_IMU1_off  = 0;

float pitch_IMU2_off  = 0;
float roll_IMU2_off  = 0;

float pitch_IMU3_off  = 0;
float roll_IMU3_off  = 0;

float pitch_IMU4_off  = 0;
float roll_IMU4_off  = 0;

// font
PFont pfont = createFont("Arial",40,true); // use true/false for smooth/no-smooth
PFont pfont_big = createFont("Arial",30,true); // use true/false for smooth/no-smooth
  
void setup()
{   
  
  // database
  db = new KetaiSQLite( this);  // open database file

  if ( db.connect() )
  {
    // for initial app launch there are no tables so we make one
    if (!db.tableExists(db_name)){
      db.execute(CREATE_DB_SQL);
      if (!db.execute("INSERT into "+db_name+" (`DATE` , `RIGHT_MIN` ,`LEFT_MIN`) VALUES ( date('now'), '360', '360' )"))
        println("error w/sql insert");
      
    }
    println("data count for data table: "+db.getRecordCount(db_name));

    // check entries
    db.query( "SELECT * FROM "+db_name+"" );
    while (db.next ())
    {
      println("----------------");
      print( "DATE: " + db.getString("DATE") );
      print( "    RIGHT_MIN:  "+db.getFloat("RIGHT_MIN") );
      print("     LEFT_MIN: "+db.getFloat("LEFT_MIN"));   
      println("----------------");
    }
    
  }
  
  // UI
  ControlFont font = new ControlFont(pfont,30);
  ControlFont font_big = new ControlFont(pfont_big,40);
  
  orientation(PORTRAIT);
  background(78, 93, 75);
  stroke(255);
  textSize(24);
  
  cp5_MAIN  = new ControlP5(this);

  //start listening for BT connections
  bt.start();

  UIText =  "d - discover devices\n" +
    "b - make this device discoverable\n" +
    "c - connect to device\n     from discovered list.\n" +
    "p - list paired devices\n" +
    "i - Bluetooth info";
    
  // Buttons
  float buttonWidth = width/5; // or whatever ...
  float buttonHeight = width/10 ; // buttons will be square
  buttonList = new ArrayList<SimpleButton>(); 
  
  
  
    /********************************* MAIN ************************************/
  int x=250;
  int y=200;
  int y_inc = 100;
  int x_inc = 200;
  int y_inc_big = 150;
  int imu_raw_width = 100;
  
  // pos angle data label
  int x_data = width/4 + 50;
  int x_data_label = x_data - 300;
  int x_data_inc = 150;
  int y_data = 500;
  int y_data_label = y_data + 50;
  
  // PITCH ROLL LABELS
  cp5_MAIN.addTextlabel("MAIN_tl_PITCH").setText("PITCH").setPosition(x-180, y+20).setColor(0).setFont(font);
  cp5_MAIN.addTextlabel("MAIN_tl_ROLL").setText("ROLL").setPosition(x-180, y+20 + y_inc).setColor(0).setFont(font);
  
  // IMU LABELS
  cp5_MAIN.addTextlabel("MAIN_tl_IMU1").setText("IMU1").setPosition(x+5, y-40).setColor(0).setFont(font);
  cp5_MAIN.addTextlabel("MAIN_tl_IMU2").setText("IMU2").setPosition(x+5 + x_inc, y-40).setColor(0).setFont(font);
  cp5_MAIN.addTextlabel("MAIN_tl_IMU3").setText("IMU3").setPosition(x+5 + x_inc + x_inc, y-40).setColor(0).setFont(font);
  cp5_MAIN.addTextlabel("MAIN_tl_IMU4").setText("IMU4").setPosition(x+5 + x_inc + x_inc + x_inc, y-40).setColor(0).setFont(font);
  
  // PITCH IMUs
  cp5_MAIN.addNumberbox("MAIN_nb_PITCH_IMU1").setPosition(x, y).setSize(imu_raw_width,60).setLock(true).setValue(10).setDecimalPrecision(0).setCaptionLabel("").setFont(font);
  cp5_MAIN.addNumberbox("MAIN_nb_PITCH_IMU2").setPosition(x + x_inc, y).setSize(imu_raw_width,60).setLock(true).setValue(10).setDecimalPrecision(0).setCaptionLabel("").setFont(font);
  cp5_MAIN.addNumberbox("MAIN_nb_PITCH_IMU3").setPosition(x + x_inc + x_inc, y).setSize(imu_raw_width,60).setLock(true).setValue(10).setDecimalPrecision(0).setCaptionLabel("").setFont(font);
  cp5_MAIN.addNumberbox("MAIN_nb_PITCH_IMU4").setPosition(x + x_inc + x_inc + x_inc, y).setSize(imu_raw_width,60).setLock(true).setValue(10).setDecimalPrecision(0).setCaptionLabel("").setFont(font);
  
  // ROLL IMUs
  cp5_MAIN.addNumberbox("MAIN_nb_ROLL_IMU1").setPosition(x, y + y_inc).setSize(imu_raw_width,60).setLock(true).setValue(10).setDecimalPrecision(0).setCaptionLabel("").setFont(font);
  cp5_MAIN.addNumberbox("MAIN_nb_ROLL_IMU2").setPosition(x + x_inc, y + y_inc).setSize(imu_raw_width,60).setLock(true).setValue(10).setDecimalPrecision(0).setCaptionLabel("").setFont(font);
  cp5_MAIN.addNumberbox("MAIN_nb_ROLL_IMU3").setPosition(x + x_inc + x_inc, y + y_inc).setSize(imu_raw_width,60).setLock(true).setValue(10).setDecimalPrecision(0).setCaptionLabel("").setFont(font);
  cp5_MAIN.addNumberbox("MAIN_nb_ROLL_IMU4").setPosition(x + x_inc + x_inc + x_inc, y + y_inc).setSize(imu_raw_width,60).setLock(true).setValue(10).setDecimalPrecision(0).setCaptionLabel("").setFont(font);
  
  // ANGLE DATA LABELS
  cp5_MAIN.addTextlabel("MAIN_tl_ANGLE_LEG_RIGHT").setText("ANGLE RIGHT").setPosition(x_data_label, y_data_label).setColor(0).setFont(font_big);
  cp5_MAIN.addTextlabel("MAIN_tl_ANGLE_LEG_LEFT").setText("ANGLE LEFT").setPosition(x_data_label, y_data_label + y_inc_big).setColor(0).setFont(font_big);
  cp5_MAIN.addTextlabel("MAIN_tl_MIN_ANGLE_CURRENT").setText("CUR.").setPosition(x_data + x_data_inc , y_data - 50).setColor(0).setFont(font_big);
  cp5_MAIN.addTextlabel("MAIN_tl_MIN_ANGLE_DAILY").setText("DAY").setPosition(x_data + x_data_inc + x_data_inc, y_data - 50).setColor(0).setFont(font_big);
  
  // RIGHT
  cp5_MAIN.addNumberbox("MAIN_nb_ANGLE_LEG_RIGHT").setPosition(x_data, y_data).setSize(100,100).setLock(true).setValue(0).setDecimalPrecision(0).setCaptionLabel("").setFont(font_big);
  cp5_MAIN.addNumberbox("MAIN_nb_CURRENT_MIN_ANGLE_LEG_RIGHT").setPosition(x_data + x_data_inc, y_data).setSize(100,100).setLock(true).setValue(360).setDecimalPrecision(0).setCaptionLabel("").setFont(font_big);
  cp5_MAIN.addNumberbox("MAIN_nb_DAILY_MIN_ANGLE_LEG_RIGHT").setPosition(x_data + x_data_inc + x_data_inc, y_data).setSize(100,100).setLock(true).setValue(0).setDecimalPrecision(0).setCaptionLabel("").setFont(font_big);

  // LEFT
  cp5_MAIN.addNumberbox("MAIN_nb_ANGLE_LEG_LEFT").setPosition(x_data, y_data + y_inc_big).setSize(100,100).setLock(true).setValue(0).setDecimalPrecision(0).setCaptionLabel("").setFont(font_big);
  cp5_MAIN.addNumberbox("MAIN_nb_CURRENT_MIN_ANGLE_LEG_LEFT").setPosition(x_data + x_data_inc, y_data + y_inc_big).setSize(100,100).setLock(true).setValue(360).setDecimalPrecision(0).setCaptionLabel("").setFont(font_big);
  cp5_MAIN.addNumberbox("MAIN_nb_DAILY_MIN_ANGLE_LEG_LEFT").setPosition(x_data + x_data_inc + x_data_inc, y_data + y_inc_big).setSize(100,100).setLock(true).setValue(0).setDecimalPrecision(0).setCaptionLabel("").setFont(font_big);
  
  // BUTTONS
  buttonList.add(new SimpleButton(x_data + x_data_inc + x_data_inc + x_data_inc, y_data, buttonWidth, buttonHeight, "RESET CURRENT MIN"));
  buttonList.add(new SimpleButton(x_data + x_data_inc + x_data_inc + x_data_inc, y_data + y_inc_big, buttonWidth, buttonHeight, "RESET CURRENT MIN"));
  buttonList.add(new SimpleButton(x_data + x_data_inc , y_data + y_inc_big + y_inc_big, buttonWidth, buttonHeight, "CALIBRATE"));
  
  
  
  // Chart to display sensor value
  chart_right_leg = cp5_MAIN.addChart("chart_right_leg")
             .setPosition(width * 0.1, y_data + y_inc_big + y_inc_big *2)
             .setSize(int(width * 0.8), int(height * 0.4))
             .setRange(0, 190) // accurate repr of the sensor value
             .setView(Chart.LINE)
             .setStrokeWeight(20)
             .setColorBackground(color(0));
  chart_right_leg.addDataSet("incoming");
  chart_right_leg.addDataSet("incoming_left");
  chart_right_leg.setData("incoming", new float[100]);
  chart_right_leg.setData("incoming_left", new float[100]);
  
  getDailyMin("RIGHT_MIN");
  getDailyMin("LEFT_MIN");  
}

void draw()
{
  if (BTconfig)
  {
    drawUI();
    hideCP5(); 
  }
  if (isApp)
  {
    drawLSDApp();
    showCP5();
    // draw buttons
    for (int i=0; i<3; i++) {
      SimpleButton button =  buttonList.get(i);
      button.display();
    }
  }
}


//Call back method to manage data received
void onBluetoothDataEvent(String who, byte[] data)
{
  String myString = "";
  
  if (isConfiguring)
    return;
  
  //https://gist.github.com/0xjac/1da786175f73fc4315daeed04a3d4a12
  for(int i=0; i<data.length; i++) { // process each byte 
    char c = (char) data[i];
    if (c == '\r'){
      myString = inBuffer;
      inBuffer = "";
    }else{
      inBuffer += c;
    }
  }
  
  //print(myString);
  String[] nums = split(myString, ' ');
  
  pitch_IMU1_raw = float(nums[2]);
  roll_IMU1_raw = float(nums[3]);
  
  pitch_IMU2_raw = float(nums[4]);
  roll_IMU2_raw = float(nums[5]) ;
  
  pitch_IMU3_raw = float(nums[6])   ;
  roll_IMU3_raw= float(nums[7])   ;
  
  pitch_IMU4_raw = float(nums[8])  ;
  roll_IMU4_raw  = float(nums[9]) ; 
  
  pitch_IMU1 = pitch_IMU1_raw + pitch_IMU1_off;
  roll_IMU1 = roll_IMU1_raw + roll_IMU1_off;
  
  pitch_IMU2 = pitch_IMU2_raw + pitch_IMU2_off;
  roll_IMU2 = roll_IMU2_raw + roll_IMU2_off;
  
  pitch_IMU3 = (-pitch_IMU3_raw) + pitch_IMU3_off;
  roll_IMU3 = roll_IMU3_raw + roll_IMU3_off;
  
  pitch_IMU4 = pitch_IMU4_raw + pitch_IMU4_off;
  roll_IMU4 = roll_IMU4_raw + roll_IMU4_off;
  
  cp5_MAIN.get("MAIN_nb_PITCH_IMU1").setValue(pitch_IMU1);
  cp5_MAIN.get("MAIN_nb_ROLL_IMU1").setValue(roll_IMU1);
  
  cp5_MAIN.get("MAIN_nb_PITCH_IMU2").setValue(pitch_IMU2);
  cp5_MAIN.get("MAIN_nb_ROLL_IMU2").setValue(roll_IMU2);
  
  cp5_MAIN.get("MAIN_nb_PITCH_IMU3").setValue(pitch_IMU3);
  cp5_MAIN.get("MAIN_nb_ROLL_IMU3").setValue(roll_IMU3);
  
  cp5_MAIN.get("MAIN_nb_PITCH_IMU4").setValue(pitch_IMU4);
  cp5_MAIN.get("MAIN_nb_ROLL_IMU4").setValue(roll_IMU4);
  
  // calc angle leg right
  float angle_calc_leg_right = ( - pitch_IMU1) + (180 - roll_IMU2) ;
  
  cp5_MAIN.get("MAIN_nb_ANGLE_LEG_RIGHT").setValue(angle_calc_leg_right);
  chart_right_leg.push("incoming", angle_calc_leg_right); 
  
  if ( angle_calc_leg_right < min_angle_calc_leg_right && isCalibrated) 
  {
    min_angle_calc_leg_right = angle_calc_leg_right;
    InsertDBMin("RIGHT_MIN", min_angle_calc_leg_right);
    getDailyMin("RIGHT_MIN");
    cp5_MAIN.get("MAIN_nb_CURRENT_MIN_ANGLE_LEG_RIGHT").setValue(min_angle_calc_leg_right);
  }
  
  // calc angle leg left
  float angle_calc_leg_left = (- pitch_IMU3) + (180 - roll_IMU4);
  
  cp5_MAIN.get("MAIN_nb_ANGLE_LEG_LEFT").setValue(angle_calc_leg_left);
  chart_right_leg.push("incoming_left", angle_calc_leg_left); 
  
  if ( angle_calc_leg_left < min_angle_calc_leg_left && isCalibrated) 
  {
    min_angle_calc_leg_left = angle_calc_leg_left;
    InsertDBMin("LEFT_MIN", min_angle_calc_leg_left); 
    getDailyMin("LEFT_MIN");
    cp5_MAIN.get("MAIN_nb_CURRENT_MIN_ANGLE_LEG_LEFT").setValue(min_angle_calc_leg_left);
  }
}

String getBluetoothInformation()
{
  String btInfo = "Server Running: ";
  btInfo += bt.isStarted() + "\n";
  btInfo += "Discovering: " + bt.isDiscovering() + "\n";
  btInfo += "Device Discoverable: "+bt.isDiscoverable() + "\n";
  btInfo += "\nConnected Devices: \n";

  ArrayList<String> devices = bt.getConnectedDeviceNames();
  for (String device: devices)
  {
    btInfo+= device+"\n";
  }

  return btInfo;
}



void InsertDBMin(String TheColum, float TheValue)
{
  if(isCalibrated) {
      if(db.query("SELECT * from "+ db_name + " WHERE (DATE = date('now'))"))
      {
        int i=0;
        while (db.next ())
        {
          println("----------------");
          print( "DATE: " + db.getString("DATE") );
          print( "    RIGHT_MIN:  "+db.getFloat("RIGHT_MIN") );
          print("     LEFT_MIN: "+db.getFloat("LEFT_MIN"));   
          println("----------------");
          print("QUERY ON " + TheColum + " : " + db.getFloat(TheColum));
          
          if (db.getFloat(TheColum) > TheValue)
          {
            println("new min to insert in DB");
            if (db.execute("UPDATE "+ db_name + " SET "+ TheColum +" = '" + TheValue + "'  WHERE (DATE = date('now'))"))
            {
              db.query("SELECT * from "+ db_name + " WHERE (DATE = date('now'))");  
              println("min updated");
            }
            else
            {
              println("error w/sql insert");
            }
            
            
          }          
          i++; // increment through query results
        }
        if(i<1) // if no result
        {
          println("No data recorded today");
          if (!db.execute("INSERT into "+ db_name +" (`DATE` , `RIGHT_MIN` ,`LEFT_MIN`) VALUES ( date('now'), '360', '360' )"))
            println("error w/sql insert");
        }
    }
    else 
    {
    println("err accesing db...");
    }
  }
}

void getDailyMin(String TheColum)
{
  if(db.query("SELECT * from "+ db_name + " WHERE (DATE = date('now'))"))
    {
      while (db.next ())
      {
        switch(TheColum)
          {
            case "RIGHT_MIN":
              cp5_MAIN.get("MAIN_nb_DAILY_MIN_ANGLE_LEG_RIGHT").setValue(db.getFloat(TheColum));
              break;
              
             case "LEFT_MIN":
              cp5_MAIN.get("MAIN_nb_DAILY_MIN_ANGLE_LEG_LEFT").setValue(db.getFloat(TheColum));
              break; 
          }
      }
    }
}

void calibrate_sensors() 
{
  isConfiguring = true; 
  
  pitch_IMU1_off =  (- pitch_IMU1_raw);
  roll_IMU1_off = (- roll_IMU1_raw) ;
  
  pitch_IMU2_off = (- pitch_IMU2_raw) ;
  roll_IMU2_off = ( 90 - roll_IMU2_raw); // angle sole axis - leg axis = 90 degres for calibration standing up
  
  pitch_IMU3_off =  pitch_IMU3_raw;
  roll_IMU3_off = (- roll_IMU3_raw);
  
  pitch_IMU4_off = (- pitch_IMU4_raw);
  roll_IMU4_off = (90 - roll_IMU4_raw);   // angle sole axis - leg axis = 90 degres for calibration standing up
  
  isCalibrated = true;
  isConfiguring = false;
}
