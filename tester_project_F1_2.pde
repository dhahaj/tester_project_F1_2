/*********************************************************
 **********************************************************
 **        Tester Interface Software
 **        Revision History
 **  E3.1 2/7/2014:
 **      1) Relocated EAX-300 Menu
 **      2) Removed '5 Chirp' Verbage from EAX300/500 Test
 **      3) Added new user - EMH
 **       4) Added EAX2545
 **
 **  E3.2 8/14/2014
 **    1) Added EAX2505
 **  E3.3 12/11/2014
 **    1) Modified EAX2500 Testing Sequence 
 **  E3.4 10/22/2015
 **             1) Update V40 firmware version.
 **             2) Added V40 Silent Arming Firmware.
 **  F1.0 10/26/2015
 **             1) Modified V40 test procedure to match the updated software. (see "testing.pde" source code)
 **
 **  F1.2 2/7/2018
 **             1) Fixed the auto logout feature
 **             2) Change background color for EAX300 and V40 silent arming devices
 **             3) Removed EAX3500 device
 **             4) Raised the maximum speed rate
 **  F1.2.2 2/12/2018
 **             1) Increase auto logout time
 **             2) Lowered maximum speed rate / Adjustable by adjusting the registry
 *********************************************************
 *********************************************************/

import com.dhahaj.*;
import java.util.logging.*;
import java.util.prefs.*;
import java.util.*;
import guicomponents.*;
import processing.serial.*;
import cc.arduino.*;
import java.awt.event.*;
import java.awt.*;
import javax.swing.*;
import javax.swing.event.*;
import javax.swing.Timer;
import java.nio.*;
import java.nio.channels.*;
import java.io.*;
import java.nio.channels.FileChannel;
import java.nio.channels.FileLock;
import java.lang.instrument.*;
import java.text.*;

final static boolean DEBUG = false;
final static String VERSION = "Tester Interface - Rev F1.2.2";

public static Device currentDevice = null;
GWSlider sdr1;
Arduino arduino = null;
PFont font, bfont;
Timer testTimer;
public static StringBuffer sBuffer;
PImage detexLogo;
LoginThread user = null;
static Logger log;
static String dpath;

final int QWRelay = 9, LBRelay = 2, testJumper = 6, DCPwr = 10, ACPwr = 7, testLED = 12, heartBeatPin = 13, 
remoteSignal = 8, relayState = 3, V40pad_2500doorSw = 4, V40okc_2500callBtn = 5;
int timeDelay, time = 0, state = 0, comPort;

final int[]
inputs = { 
  relayState
}
, 
outputs = { 
  ACPwr, DCPwr, testJumper, V40pad_2500doorSw, V40okc_2500callBtn, QWRelay, LBRelay, remoteSignal, testLED, heartBeatPin
};

boolean flag = false, running = false;

void DEBUG(Object o) {
  if (DEBUG) println(o);
}

void init() { // To customize the window frame
  frame.removeNotify();
  frame.setTitle(VERSION);
  frame.addNotify();
  super.init();
}

void ChangeWindowListener() {  // Needed for confirming an exit 
  WindowListener[] wls = frame.getWindowListeners();
  frame.removeWindowListener(wls[0]); // Suppose there is only one...
  frame.addWindowListener(
  new WindowAdapter() {
    public void windowClosing(WindowEvent we) {
      println("Should be closing!");
      ConfirmExit();
    }
    public void windowActivated(WindowEvent e) {
      user.restartTimer();
      println("window activated!");
    }
  }
  );
}

void showDialog(String string) { // Runs a swing error dialog
  final String msg = string;
  SwingUtilities.invokeLater( new Runnable() {
    public void run() {
      javax.swing.JOptionPane.showMessageDialog(frame, msg, "Error", javax.swing.JOptionPane.ERROR_MESSAGE );
    }
  }
  );
}

void ConfirmExit() {  // Confirms before closing the software
  SwingUtilities.invokeLater( new Runnable() {
    public void run() {
      int exitChoice = javax.swing.JOptionPane.showConfirmDialog(frame, 
      "Are you sure you want to exit?", "Confirm exit", javax.swing.JOptionPane.YES_NO_OPTION );

      if (exitChoice != javax.swing.JOptionPane.YES_OPTION)
        return;

      final User u = user.getUser();
      if (u!=null)
        log.info("\nUser " + u.getName()
        +" closed software\n\t*devices passed: " + u.getCount(LoginThread.PASSED_CNT)
        +"\n\t*devices failed: " + u.getCount(LoginThread.FAILED_CNT)
        +"\n\t*total devices tested: " + u.getCount(LoginThread.TOTAL_CNT)
        +"\n\t*devices programmed: " + u.getCount(LoginThread.PROG_CNT)
        +"\n\t*" );

      else log.info("Software closed");
      user.quit();
      System.exit(0);
    }
  }
  );
}

/******************************/
/*******  Control Code  *******/
/******************************/

/**
 *        Method which configures and runs quickwriter for programming of the devices.
 *        @param p The firmware to program on the device.
 */
void Program () {

  // Do not program the device while testing is active
  if (testTimer.isRunning() || waiting || testing) {
    showDialog("Testing is currently active!");
    return;
  } else if (currentDevice==null) {
    showDialog("Select a device before programming!");
    return;
  }

  // Set the arguments from the stored settings
  final String[] qw_args = new String[4];
  qw_args[0] = (String)Keys.QW_PATH.value; // Path to quickwriter executable
  qw_args[2] = (String)Keys.QW_ARUN.value; // Argument to auto run
  qw_args[3] = (String)Keys.QW_AEXIT.value; // Argument to auto exit after programming

  String location = Keys.FIRMWARE_FOLDER.value + File.separator + currentDevice.getProgram().toString();

  // Add the file extension to the location string
  switch(currentDevice.getDevices()) {
  case EAX300:
    location += Keys.EAX300_EXT.value;
    break;
  case EAX500:
    location += Keys.EAX500_EXT.value;
    break;
  case EAX2500:
    location += Keys.EAX2500_EXT.value;
    break;
    //  case EAX3500:
    //    location += Keys.EAX3500_EXT.value;
    //    break;
  case V40:
    location += Keys.V40_EXT.value;
    break;
  }

  // Make sure the hex file exists
  if (!(miscStuff.dataFileExists(location))) {
    showDialog("File not found:\n" + location);
    return;
  }

  DEBUG("hex file location: " + location);

  // Path to the quickwriter control file
  final String ctrlFilePath = dataPath("qw_control.qwc");

  // Make sure the file exists
  if (!miscStuff.dataFileExists(ctrlFilePath)) {
    showDialog("Could not find QuickWriter control file.");
    return;
  }

  // Load the control file
  final File ctrlFile = new File(ctrlFilePath);
  String[] ctrlStrings = getContents(ctrlFile).split("\n");

  // Make a data code stamp for the EEPROM data
  final SimpleDateFormat sdf = new SimpleDateFormat("MM/dd/yy");
  final String dateCode = sdf.format(Calendar.getInstance().getTime());

  for (int i=0; i<ctrlStrings.length; i++) {

    // Change the hex file location
    if (ctrlStrings[i].contains("HEXFILE")) {
      ctrlStrings[i] = "HEXFILE=" + location;
      continue;
    }

    // Put the date code in the EEPROM data (hex format)
    else if (ctrlStrings[i].startsWith("3=")) {
      final String dateHex = toHex(dateCode);
      DEBUG("datecode = " + dateCode + " (" + dateHex + ')');
      ctrlStrings[i] = replaceChars(ctrlStrings[i], dateHex, ctrlStrings[i].indexOf("3=")+2);
      continue;
    }

    // Put the username in the EEPROM data
    else if (ctrlStrings[i].startsWith("4=")) {
      final String userHex = toHex(user.getUsername());
      DEBUG("username = " + user.getUsername() + " (" + userHex + ')');
      ctrlStrings[i] = replaceChars(ctrlStrings[i], userHex, ctrlStrings[i].indexOf("4=")+2);
      continue;
    }

    // Increment the serial number manually
    else if (ctrlStrings[i].contains("Auto=1")) {
      ctrlStrings[i] = "Auto=0";
      continue;
    }

    // Put in the programmed serial number
    else if (ctrlStrings[i].startsWith("last_a")) {

      // Get the last saved serial number
      final int sn = (Integer)Keys.LAST_SERIAL.value;
      final int new_sn = sn+1;
      // Put the serial number in the control file (hex format)
      ctrlStrings[i] = "last_a=" + hex(new_sn, 4);
      DEBUG("\n\tLast Serial#: " + sn + "(" + hex(sn, 4) + ")");
      DEBUG("\tThis Serial#: " + new_sn + "(" + hex(new_sn, 4) + ")");
    }
  }

  // Save the modified control file
  try {
    setContents(ctrlFile, join(ctrlStrings, "\n"));
  } 
  catch(Exception e) {
    showDialog("Couldn't save the control file!");
    println(e);
    return;
  }

  // Put the arg in qoutes to handle any whitespaces chars
  qw_args[1] = '"' + ctrlFilePath + '"';

  DEBUG("Programming Args:");
  DEBUG(qw_args);

  if (arduino!=null) {
    arduino.digitalWrite(testJumper, Arduino.LOW);  // Remove test jumper from ground
    arduino.digitalWrite(DCPwr, Arduino.LOW);  // Make sure DC power is off before programming!
    arduino.digitalWrite(QWRelay, Arduino.HIGH); // Power the QW interface
  }

  // final int serNum = serialNumber+1;

  // Open the QW Software and wait for an exit code
  // to determine if it programmed correctly
  Runnable runQuickWriter = new Runnable() {
    public void run() {
      String args = join(qw_args, " ");
      Runtime r = Runtime.getRuntime();
      Process p = null;
      try {
        p = r.exec(args);
        p.waitFor();
      } 
      catch(Exception e) {
        println("error programming");
      }

      short exitValue = (short)(p.exitValue());
      DEBUG("QW returned value: " + exitValue);

      if (exitValue != 0) { // Returned with an error
        ByteBuffer b = ByteBuffer.allocate(4);
        b.putInt(exitValue);
        byte lowByte = b.get(3);
        String errMsg = null;
        switch(lowByte) {
        case 1:
          errMsg = "Error communicating with Port";
          break;
        case 2:
          errMsg = "Communication Timeout, Hardware not responding";
          break;
        case 4:
          errMsg = "Communication Error Detected, BAD data received";
          break;
        case 8:
          errMsg = "Current Programming Task Failed";
          break;
        case 10:
          errMsg = "Firmware update Required";
          break;
        case 20:
          errMsg = "Higher Transfer Speed Failed";
          break;
        case 40:
          errMsg = "User Aborted Task in progress";
          break;
        case 80:
          errMsg = "Unknown Error has Occurred";
          break;
        default:
          errMsg = "";
          break;
        }

        byte highByte = b.get(2);
        DEBUG("low byte = "+lowByte);
        DEBUG("high byte = "+highByte);
        // byte[] result = b.array();
        // println(result);

        sBuffer.append("\nError: " + errMsg);
        log.warning("Error programming " + currentDevice.getProgram().toString()
          + ", " + errMsg);
        showDialog(errMsg);
      } else { // Programming was succesful

        int lastSerialNumber = (Integer)Keys.LAST_SERIAL.value;

        // Make a log entry
        log.info("Programming initiated by " + user.getUsername()
          + " -- " + currentDevice.getProgram().toString()
          + " Serial#:" + lastSerialNumber + "(" + hex(lastSerialNumber) + ")" );

        // Increment the user's programming count
        user.getUser().incrementCount(LoginThread.PROG_CNT);

        // Increment the serial number
        Keys.LAST_SERIAL.setPref(lastSerialNumber+1);
        if (DEBUG) println("Saved serial number: " + Keys.LAST_SERIAL.value);
      }

      if (arduino!=null)
        arduino.digitalWrite(QWRelay, Arduino.LOW); // Remove power from QW
    }
  };

  runQuickWriter.run();
}

void keyPressed() {  // Handles key press events

  if (key == ESC) {
    key=0;
    if (!user.loggedin())
      return;
    // If not testing, then confirm exiting the software
    ConfirmExit();
  } else if (key == 'a') {
    Calendar cal = Calendar.getInstance();
    int year = cal.get(Calendar.YEAR);
    println(year+"");
    println((year-1900)+"");
    // ArrayList<String> al = user.getUsers();
    // println( al.toArray(new String[al.size()]));
    // println("freeMem: " + Runtime.getRuntime().freeMemory());
    // println("totalMem: " +Runtime.getRuntime().totalMemory());
    // println("After GC...");
    // Runtime.getRuntime().gc();Runtime.getRuntime().gc();
    // println("freeMem: " + Runtime.getRuntime().freeMemory());
    // println("totalMem: " +Runtime.getRuntime().totalMemory());
    // println("proc: " + Runtime.getRuntime().availableProcessors());
    // getSize(sBuffer);
  } else if (key=='p' || key=='P') {
    Program();
  } else if (key=='t' || key=='T') {
    if (!testTimer.isRunning() && !waiting) {
      testTimer.setDelay(sdr1.getValue()); // Restore the delay time
      testTimer.start();
    } else if (testing) {
      showDialog("Finish current test before starting a new one!");
    }
  }

  // "+" keys increase the slider value
  else if (keyCode==107 || keyCode==61) {
    sdr1.setValue(sdr1.getValue() + 300);
  }

  // "-" keys decrease the slider value
  else if (keyCode==109 || keyCode==45) {
    sdr1.setValue(sdr1.getValue() - 300);
  }

  // Increment the testing process manually via the space bar
  // else if ( keyCode == java.awt.event.KeyEvent.VK_SPACE && manualTest.getState() ) {
  // try {
  // if (waiting)
  // state++;
  // testProcess();
  // } 
  // catch (Exception e) {
  // }
  // }

  // Finish testing by pressing the space bar
  else if ( keyCode == java.awt.event.KeyEvent.VK_SPACE && /* testTimer.isRunning() && */ waiting) {
    testTimer.start();
    waiting=false;
    // state++;
  }

  /*   else {
   println( keyCode );
   } */
}

void mouseMoved() {  // Resets the auto-logout timer while the user is active
  // logoutTimer.reset();
  user.restartTimer();
}

/***************************/
/******  Main Code  ********/
/***************************/

int appWidth, appHeight, 
consoleScreenWidth, 
consoleScreenHeight ;

void setup() {

  final SingleInstance sis = new SingleInstance(this);
  sis.start();

  // Allow only a single instance to run
  if (sis.isLocked()) {
    DEBUG("Program locked.");
    JOptionPane.showMessageDialog(frame, "Program already running!", "Error", JOptionPane.ERROR_MESSAGE );
    System.exit(1);
  }

  Device.instructionPath = dataPath("");

  sBuffer = new StringBuffer();
  dpath = dataPath("");

  // Initialize the Keys Enum
  final Keys keys = Keys.LAST_USER;

  // Display the software version
  sBuffer.append(VERSION);

  // Init the logger
  MyLogger.FilePath = dataPath("Log");
  log = Logger.getLogger(this.getClass().toString());
  try {
    MyLogger.setup();
  } 
  catch (IOException e) {
    e.printStackTrace();
    throw new RuntimeException("Problems with creating the log files");
  } 
  finally {
    log.info("Program started");
  }

  // Set the Look & Feel of the Swing Components
  try {
    javax.swing.UIManager.LookAndFeelInfo[] lafs = UIManager.getInstalledLookAndFeels();
    for (javax.swing.UIManager.LookAndFeelInfo lafi : lafs) {
      String name = lafi.getClassName();
      if (name.contains("Nimbus")) {
        UIManager.setLookAndFeel(name);
        DEBUG("Set LookAndFeel - " + name);
        break;
      }
    }
  }
  //  try { 
  //    UIManager.setLookAndFeel(UIManager.getSystemLookAndFeelClassName());
  //  } 
  catch (Exception e) {
  }

  // Set the default firmware folder
  //Keys.FIRMWARE_FOLDER.setPref( dataPath("") + "\\firmware");

  cleanGarbage();
  int displayWidth=1280, displayHeight=1024;
  // Apply the stored display configuration
  appWidth =  (int)(displayWidth * ((Integer)Keys.WIDTH_SCALER.value)/100);
  appHeight = (int)(displayHeight * ((Integer)Keys.HEIGHT_SCALER.value)/100);
  size(appWidth, appHeight);
  frameRate(45);

  // Start the login thread
  user = new LoginThread(this.log);

  consoleScreenWidth = (int)(appWidth-40);
  consoleScreenHeight = (int)(appHeight-90);

  if (miscStuff.dataFileExists(dataPath("detex.jpg"))) {
    println("found detex logo");
    detexLogo = loadImage("detex.jpg");
    detexLogo.resize(0, 50);
    tint(85, 200);
  } 

  // Customize the program icon
  if (miscStuff.dataFileExists(dataPath("pde.png"))) {
    PImage iconImg = loadImage( dataPath("pde.png") );
    PGraphics icon = createGraphics(iconImg.width, iconImg.height, JAVA2D);

    for (int i=0; i < iconImg.height; i++) {
      for (int j=0; j < iconImg.width; j++) { 
        color c = iconImg.get(i, j);
        icon.set(i, j, c);
      }
    }
    frame.setIconImage(icon.image);
  }

  // Load fonts
  font = loadFont("cambria.vlw"); 
  bfont = loadFont("Cambria-Bold.vlw");

  //  Create the timing slider
  sdr1 = new GWSlider(this, appWidth-390, appHeight-30, 200);
  sdr1.setRenderMaxMinLabel(false);
  // Keys.MAX_SPEED.setPref(1000);
  int maxSpeed = (Integer)Keys.MAX_SPEED.value;
  sdr1.setLimits(1, maxSpeed, 5000);
  sdr1.setInertia(2);
  sdr1.setTickCount(16);
  sdr1.setStickToTicks(false);
  sdr1.setValue((Integer)Keys.LAST_DELAY.value, true);

  // Create timer for the testing process
  testTimer = new Timer(sdr1.getValue(), new ActionListener() {
    public void actionPerformed(ActionEvent evt) {
      if ( manualTest.getState() ) {
        testTimer.stop();
        return;
      }
      try {
        testProcess();
      } 
      catch (Exception e) {
        sBuffer.append("\n Error: Cannot communicate with device.");
        showDialog("Cannot communicate with device!");
        testing=false;
        testTimer.stop();
      }
    }
  }
  );
  testTimer.setActionCommand("testing timer");
  testTimer.setInitialDelay(10);

  // Create the menus
  createMenus();
  setupArduino();

  // Change the window listener and start the login
  // service after the window has been created.
  SwingUtilities.invokeLater(new Runnable() {
    public void run() {
      while (frame.getWindowListeners ().length == 0); // wait for it
      ChangeWindowListener(); // Change the window listener

        // Start the login
      LoginThread.f = frame;
      user.start();
    }
  }
  );

  // Add shutdown hook to perform actions upon closing the software
  Runtime.getRuntime().addShutdownHook(new Thread(new Runnable() {
    //@Override
    public void run() {
      // sis.unlockFile();
      // Save the delay settings
      Keys.LAST_DELAY.setPref(sdr1.getValue());

      try {
        if (arduino!=null)
          arduino.digitalWrite(heartBeatPin, Arduino.LOW);
      } 
      catch (Exception e) {
      } 
      finally {
        DEBUG("closing");
      }
    }
  }
  ));

  cleanGarbage();
}

int color1 = #00761A;
int color2 = #021AAF;

void draw() {
  background(85, 400.0);
  strokeWeight(5);

  // Info display
  if (currentDevice!=null) {
    Devices d = currentDevice.getDevices();
    if ( d == Devices.EAX300 || currentDevice.getProgram().toString().equals("V40sa00")) {
      fill(color1);
    } else
      fill(color2);
  } else
    fill(color2);

  rect(20, 20, consoleScreenWidth, consoleScreenHeight);


  // Check the vertical height of the console text
  // and verify that it fits within the console display
  fill(color(255));
  textFont(font, 20);
  text((sBuffer = trim(sBuffer)).toString(), 35, 45);

  fill(85);
  noStroke();
  rect(0, consoleScreenHeight+25, appWidth, appHeight-consoleScreenHeight-15);
  stroke(0);

  image(detexLogo, appWidth-168, appHeight-55);

  fill(color(255));
  if (user.loggedin()) { // If logged in, display the current user on the window
    textFont(bfont, 18);
    text("Logged in as: " + user.getUsername(), 15, appHeight-32);
    // text("User Total Count: " + user.getUser().getCount(User.TOTAL_CNT), appWidth-500, 16);
  }

  // Display the date and time
  final Date date = Calendar.getInstance().getTime();
  final String todaysDate = DateFormat.getDateInstance(DateFormat.LONG).format(date);
  final String time = DateFormat.getTimeInstance(DateFormat.LONG).format(date);

  textFont(bfont, 20);
  text(todaysDate+"    "+time, 15, appHeight-7);

  text("+", appWidth-405, appHeight-20);
  text("-", appWidth-185, appHeight-20);

  // Display the selected firmware
  if (currentDevice!=null) {

    // Change the text color for non-standard programs
    if (!currentDevice.getProgram().isStandard()) {
      fill(#FF4629);
      if (frameCount%20==0)
        deviceDisplay.setEnabled(!deviceDisplay.isEnabled());
    } else if (!deviceDisplay.isEnabled()) {
      deviceDisplay.setEnabled(true);
    }

    // Include the firmware timing if device is a V40
    if (currentDevice.getDevices() == Devices.V40) {
      text("Selected device: " + currentDevice.getProgram().toString() + ", " + currentDevice.getTiming(), appWidth-500, 16);
      // deviceDisplay.setLabel(" :::  " + currentDevice.getProgram().toString() + ", " + currentDevice.getTiming());
    } else {
      text("Selected device: " + currentDevice.getProgram().toString(), appWidth-250, 16);
      // deviceDisplay.setLabel(" :::  " + currentDevice.getProgram().toString());
    }
  } else {
    text("Select a device to begin", appWidth-240, 16);
  }
}


// Class which allows only a single instance to run
public class SingleInstance {

  private File f;
  private FileChannel channel;
  private FileLock lock;
  private boolean locked;
  private PApplet parent;

  public SingleInstance(PApplet parent) {
    this.parent = parent;
    locked=false;
  }

  public void start() {
    locked=false;
    try {
      f = new File(dataPath("RingOnRequest.lock"));

      // Check if the lock exist
      if (f.exists())
        f.delete(); // if exist try to delete it
      // Try to get the lock
      channel = new RandomAccessFile(f, "rw").getChannel();
      lock = channel.tryLock();

      if (lock == null)
      {
        // File is locked by other application
        channel.close();
        locked=true;
        // throw new RuntimeException("Only 1 instance of MyApp can run.");
      }
      // Add shutdown hook to release lock when application shutdown
      // ShutdownHook shutdownHook = new ShutdownHook();
      // Runtime.getRuntime().addShutdownHook(shutdownHook);

      //Your application tasks here..
      System.out.println("Running");
    } 
    catch(IOException e) {
      //throw new RuntimeException("Could not start process.", e);
    }
  }

  public boolean isLocked() {
    return locked;
  }

  public void unlockFile() {
    // release and delete file lock
    try {
      if (lock != null) {
        lock.release();
        channel.close();
        f.delete();
        System.out.println("File Unlocked");
      }
    } 
    catch(IOException e) {
      e.printStackTrace();
    }
  }
}

public int getSize(StringBuffer sb) {
  final char[] chars = new char[sb.length()];
  sb.getChars(0, sb.length(), chars, 0);
  int size = 0;
  for (int i=0; i<chars.length; i++) {
    if (chars[i] == '\n')
      size++;
  }
  return size;
}

private StringBuffer trim(StringBuffer sb) {
  // Split the string by newline chars
  String[] string = split(sb.toString(), '\n');

  // Check the size of the array (for font size 20, there are 33 pix/line)
  if ( string.length > (int)(consoleScreenHeight/33) ) {
    StringBuffer buf = new StringBuffer();
    for (int i=1; i<string.length; i++)
      buf.append(string[i] + ((i==string.length-1) ? "" : "\n"));
    return buf;
  }

  return sb;
}

// Method which attempts to initialize the tester
public void setupArduino() {
  // Setup the Arduino:
  // Get an ArrayList of the available COM Ports
  final ArrayList<String> al = new ArrayList<String>();
  for (int i = 0; i < Arduino.list ().length; i++)
    al.add(Arduino.list()[i]);

  // Look for the configured COM Port in the ArrayList
  final String com_port = (String)Keys.COM_PORT.value;
  int index = al.indexOf(com_port);
  DEBUG("COM index = " + index);

  if (index>=0) {    // COM Port was found
    sBuffer.append("\nSERIAL PORT: " + com_port);
    try {
      arduino = new Arduino(this, Arduino.list()[index], 57600);
      for (int i=0; i<inputs.length; i++)
        arduino.pinMode(inputs[i], Arduino.INPUT);
      for (int i=0; i<outputs.length; i++)
        arduino.pinMode(outputs[i], Arduino.OUTPUT);
      arduino.digitalWrite(heartBeatPin, Arduino.HIGH); // turn on the heartBeat LED
    } 
    catch(IllegalAccessError iae) {
      iae.printStackTrace();
      arduino = null;
      log.warning("Exception while attempting to connect to COM Port!");
      showDialog("Error Connecting to COM Port!\nPlease check connections.");
      sBuffer.append("\n" + com_port + " not found");
    }
  } else { // COM Port was not found
    log.warning("COM Port was not found!");
    showDialog("Error Connecting to COM Port: " + com_port + " not found!");
    arduino = null;
    sBuffer.append('\n' + com_port + " not found");
  }
}

