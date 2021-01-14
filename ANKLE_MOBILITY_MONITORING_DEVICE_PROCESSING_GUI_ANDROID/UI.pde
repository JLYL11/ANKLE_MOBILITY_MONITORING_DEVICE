/*  UI-related functions */


void mousePressed()
{
  //keyboard button -- toggle virtual keyboard
  if (mouseY <= 100 && mouseX > 0 && mouseX < width/3)
    KetaiKeyboard.toggle(this);
  else if (mouseY <= 100 && mouseX > width/3 && mouseX < 2*(width/3)) //config button
  {
    isConfiguring=true;
  }  
  else if (mouseY > (height-100) && mouseY <= height && mouseX > 0 && mouseX < (width/2) )// BT config
  {
    BTconfig = true;
    isConfiguring=true;
    isApp = false;
  }
  
  else if (mouseY > (height-100) && mouseY <= height && mouseX > (width/2) && mouseX < (width) )// App
  {
    isApp = true;
    BTconfig = false;
        if (isConfiguring)
    {
      isConfiguring=false;
    }
  }
 
 int buttonID ; 
 for (int i=0; i<buttonList.size(); i++) 
 {
    SimpleButton button =  buttonList.get(i);
    if (button.over()) {
      buttonID = i;
      //code for each button
      switch(buttonID) {
        case 0: //first button
          min_angle_calc_leg_right = 360;
          break;
        case 1: //second button
          min_angle_calc_leg_left = 360;
          break; 
        case 2:
          calibrate_sensors();
          break;
      }//end switch
    }
  } //end i loop
}

void mouseDragged()
{
  if (isConfiguring)
    return;

  //send data to everyone
  //  we could send to a specific device through
  //   the writeToDevice(String _devName, byte[] data)
  //  method.
  OscMessage m = new OscMessage("/remoteMouse/");
  m.add(mouseX);
  m.add(mouseY);

  bt.broadcast(m.getBytes());
  ellipse(mouseX, mouseY, 20, 20);
}

public void keyPressed() {
  if (key =='c')
  {
    //If we have not discovered any devices, try prior paired devices
    if (bt.getDiscoveredDeviceNames().size() > 0)
      klist = new KetaiList(this, bt.getDiscoveredDeviceNames());
    else if (bt.getPairedDeviceNames().size() > 0)
      klist = new KetaiList(this, bt.getPairedDeviceNames());
  }
  else if (key == 'd')
  {
    bt.discoverDevices();
  }
  else if (key == 'x')
    bt.stop();
  else if (key == 'b')
  {
    bt.makeDiscoverable();
  }
  else if (key == 's')
  {
    bt.start();
  }
}


void drawUI()
{
  //Draw top shelf UI buttons
  if (isConfiguring)
  {
    ArrayList<String> names;
    background(78, 93, 75);

    //based on last key pressed lets display
    //  appropriately
    if (key == 'i')
      info = getBluetoothInformation();
    else
    {
      if (key == 'p')
      {
        info = "Paired Devices:\n";
        names = bt.getPairedDeviceNames();
      }
      else
      {
        info = "Discovered Devices:\n";
        names = bt.getDiscoveredDeviceNames();
      }

      for (int i=0; i < names.size(); i++)
      {
        info += "["+i+"] "+names.get(i).toString() + "\n";
      }
    }
    text(UIText + "\n\n" + info, width/2 - 200, 200);
  }
  else
  {
    background(78, 93, 75);
    pushStyle();
    fill(255);
    ellipse(mouseX, mouseY, 20, 20);
    fill(0, 255, 0);
    stroke(0, 255, 0);
    ellipse(remoteMouse.x, remoteMouse.y, 20, 20);    
    popStyle();
  }
  
  pushStyle();
  fill(0);
  stroke(255);
  rect(0, 0, width/2, 100);

  if (isConfiguring)
  {
    noStroke();
    fill(78, 93, 75);
  }
  else
    fill(0);

  rect(width/2, 0, width, 100);

  

  fill(255);
  text("Keyboard", 5, 60); 
  text("Bluetooth", width/2+5, 60); 

  
  draw_bottom_bar();

  popStyle();
}

void onKetaiListSelection(KetaiList klist)
{
  String selection = klist.getSelection();
  bt.connectToDeviceByName(selection);

  //dispose of list for now
  klist = null;
}

void drawLSDApp()
{
  background(clrbackgrd);
  pushStyle();
  draw_top_bar();
  draw_bottom_bar(); 
  popStyle();
}

void draw_bottom_bar()
{
  // button config BT
  fill(116, 93, 245);
  rect(0, height-100, width/2, 100);
  stroke(255);
  
  // button enter app
  fill(93, 203, 245);
  rect(width/2, height-100, width/2, 100);
  stroke(255);
  
  fill(255);
  textFont(pfont);
  text("BT cfg", width/4 - 20, height-40);
  text("App", 3*width/4 -20, height-40);
}

void draw_top_bar()
{
  fill(0);
  rect(0, 0, width, 100);
  fill(255);
  textFont(pfont);
  text("LEG SENSOR DEVICE", width/2-200, 60); 
}


class SimpleButton 
{
 
  //Variables
  float x, y, w, h; //position, width and height of button
  String label;
  boolean activeState=false;
  color fillColour = color(156,45,47) ; //grey
  color borderColour = color(0) ; //black  
 
  //Constructor
  SimpleButton (float _x, float _y, float _w, float _h, String _label) {
    x=_x; 
    y=_y; 
    w=_w; 
    h=_h;
    label=_label ;
  }
 
  //Methods
 
  void display() {
    fill(fillColour);
    rect(x, y, w, h);
    fill(255);
    text(label, x+5, y + h/3, w, h);
  }//end
 
  boolean over() {
    if (mouseX>x && mouseX<x+w && mouseY>y && mouseY<y+h) {
      return true;
    } else {
      return false;
    }
  } //end over()
 
  void setActiveState(boolean _state){
    activeState = _state ;
    if(activeState) {
      fillColour = color(255,0,0); //red
    }
    else {
      fillColour = color(125); //grey
    }
  }
 
}//END SimpleButton


void showCP5()
{
  cp5_MAIN.get("MAIN_tl_PITCH").show();
  cp5_MAIN.get("MAIN_tl_ROLL").show();
  cp5_MAIN.get("MAIN_tl_IMU1").show();
  cp5_MAIN.get("MAIN_tl_IMU2").show();
  cp5_MAIN.get("MAIN_tl_IMU3").show();
  cp5_MAIN.get("MAIN_tl_IMU4").show();
  
  cp5_MAIN.get("MAIN_nb_PITCH_IMU1").show();
  cp5_MAIN.get("MAIN_nb_PITCH_IMU2").show();
  cp5_MAIN.get("MAIN_nb_PITCH_IMU3").show();
  cp5_MAIN.get("MAIN_nb_PITCH_IMU4").show();
  
  cp5_MAIN.get("MAIN_nb_ROLL_IMU1").show();
  cp5_MAIN.get("MAIN_nb_ROLL_IMU2").show();
  cp5_MAIN.get("MAIN_nb_ROLL_IMU3").show();
  cp5_MAIN.get("MAIN_nb_ROLL_IMU4").show();
  
  cp5_MAIN.get("MAIN_tl_ANGLE_LEG_RIGHT").show();
  cp5_MAIN.get("MAIN_tl_ANGLE_LEG_LEFT").show();
  cp5_MAIN.get("MAIN_tl_MIN_ANGLE_CURRENT").show();
  cp5_MAIN.get("MAIN_tl_MIN_ANGLE_DAILY").show();
  
  cp5_MAIN.get("MAIN_nb_ANGLE_LEG_RIGHT").show();
  cp5_MAIN.get("MAIN_nb_CURRENT_MIN_ANGLE_LEG_RIGHT").show();
  cp5_MAIN.get("MAIN_nb_DAILY_MIN_ANGLE_LEG_RIGHT").show();
  
  cp5_MAIN.get("MAIN_nb_ANGLE_LEG_LEFT").show();
  cp5_MAIN.get("MAIN_nb_CURRENT_MIN_ANGLE_LEG_LEFT").show();
  cp5_MAIN.get("MAIN_nb_DAILY_MIN_ANGLE_LEG_LEFT").show();
  
  chart_right_leg.show();
  
}

void hideCP5()
{
  cp5_MAIN.get("MAIN_tl_PITCH").hide();
  cp5_MAIN.get("MAIN_tl_ROLL").hide();
  cp5_MAIN.get("MAIN_tl_IMU1").hide();
  cp5_MAIN.get("MAIN_tl_IMU2").hide();
  cp5_MAIN.get("MAIN_tl_IMU3").hide();
  cp5_MAIN.get("MAIN_tl_IMU4").hide();
  
  cp5_MAIN.get("MAIN_nb_PITCH_IMU1").hide();
  cp5_MAIN.get("MAIN_nb_PITCH_IMU2").hide();
  cp5_MAIN.get("MAIN_nb_PITCH_IMU3").hide();
  cp5_MAIN.get("MAIN_nb_PITCH_IMU4").hide();
  
  cp5_MAIN.get("MAIN_nb_ROLL_IMU1").hide();
  cp5_MAIN.get("MAIN_nb_ROLL_IMU2").hide();
  cp5_MAIN.get("MAIN_nb_ROLL_IMU3").hide();
  cp5_MAIN.get("MAIN_nb_ROLL_IMU4").hide();
  
  cp5_MAIN.get("MAIN_tl_ANGLE_LEG_RIGHT").hide();
  cp5_MAIN.get("MAIN_tl_ANGLE_LEG_LEFT").hide();
  cp5_MAIN.get("MAIN_tl_MIN_ANGLE_CURRENT").hide();
  cp5_MAIN.get("MAIN_tl_MIN_ANGLE_DAILY").hide();
  
  cp5_MAIN.get("MAIN_nb_ANGLE_LEG_RIGHT").hide();
  cp5_MAIN.get("MAIN_nb_CURRENT_MIN_ANGLE_LEG_RIGHT").hide();
  cp5_MAIN.get("MAIN_nb_DAILY_MIN_ANGLE_LEG_RIGHT").hide();
  
  cp5_MAIN.get("MAIN_nb_ANGLE_LEG_LEFT").hide();
  cp5_MAIN.get("MAIN_nb_CURRENT_MIN_ANGLE_LEG_LEFT").hide();
  cp5_MAIN.get("MAIN_nb_DAILY_MIN_ANGLE_LEG_LEFT").hide();
  
  chart_right_leg.hide();
  
}
