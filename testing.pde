
/****** TESTING CODE *******/

private boolean failed=false;
private volatile boolean waiting=false, testing=false;

// Handles the testing procedures
synchronized void testProcess() {

  // Make sure a device has been selected
  if (currentDevice==null) {
    testTimer.stop();
    showDialog("Select a device before testing!");
    return;
  }

  // Make sure arduino has been initalized
  else if (arduino == null) {
    testTimer.stop();
    showDialog("Cannot communicate with tester!");
    return;
  }

  boolean done=false;
  testing=true;

  arduino.digitalWrite(QWRelay, Arduino.LOW);
  cleanGarbage();

  Devices device = currentDevice.getDevices();

  /**===========  EAX-300/500 Testing  ============= */

  if (device==Devices.EAX300 || device==Devices.EAX500) {
    switch (state)
    {
    case 0:
      arduino.digitalWrite(testJumper, Arduino.HIGH);
      arduino.digitalWrite(DCPwr, Arduino.HIGH);
      arduino.digitalWrite(testLED, Arduino.HIGH);
      final String s = (currentDevice.getDevices() == Devices.EAX300 ? "****Starting EAX-300 test****" : "****Starting EAX-500 test****" );
      sBuffer = new StringBuffer(s);
      break;
    case 1:
      newLine(" - DC Power ON");
      break;
    case 2:
      state++;
    case 3:
      newLine(" - Starting Low Battery Test    LED's should blink alternately");
      arduino.digitalWrite(DCPwr, Arduino.HIGH);
      arduino.digitalWrite(LBRelay, Arduino.HIGH);
      break;
    case 4:
      newLine("    Stopping Low Battery Test    LED's turn OFF");
      arduino.digitalWrite(LBRelay, Arduino.LOW);
      break;
    case 5:
      newLine("\nDo the following and press space bar when done:"
        + "\n - Press the key switch    both LED's should blink"
        + "\n - Release the key switch    both LED's should turn OFF"
        + "\n - Press the OKC switch    the siren should sound"
        + "\n - Release the OKC switch    the siren should silence"
        + "\n - Position a magnet to the right side reed switch\n       the green LED turns ON"
        + "\n - Position a magnet to the left side reed switch\n       the red LED turns ON");
      state++;
    case 6:
      // Stay here until space is pressed
      waiting=true;
      testTimer.setDelay(50); // Speed up the delay time
      testTimer.stop();
      break;
    case 7:
      testTimer.setDelay(1700); // Wait for the chirps
      newLine("\n ** Clearing magnet handing memory ** ");
      arduino.digitalWrite(DCPwr, Arduino.LOW);
      break;
    case 8:
      newLine("     LED's Flash and Siren chirps");
      arduino.digitalWrite(DCPwr, Arduino.HIGH);
      arduino.digitalWrite(testJumper, Arduino.LOW);
      testTimer.setDelay(50);
      break;
    case 9:
      newLine("\n   Testing completed!");
      break;
    case 11:
      done=true;
      testTimer.setDelay(sdr1.getValue()); // Restore the delay time
      log.info((currentDevice.getDevices() == Devices.EAX300 ? "EAX-300 tested \t" : "EAX-500 tested \t" ));
      break;
    default:
      break;
    }
  }


  /**=============  EAX-2500 Testing  =============== */

  else if (currentDevice.getDevices()==Devices.EAX2500) {
    switch (state)
    {
    case 0:
      // consoleText = "****Starting EAX-2500 test****";
      sBuffer = new StringBuffer("****Starting EAX-2500 test****");
      arduino.digitalWrite(testLED, Arduino.HIGH);
      state++;
    case 1:
      // consoleText += "\n - DC Power ON    Red & Green LEDs turn ON";
      newLine(" - DC Power ON    Red & Green LEDs turn ON");
      arduino.digitalWrite(testJumper, Arduino.HIGH);
      arduino.digitalWrite(DCPwr, Arduino.HIGH);
      break;
    case 2:
      state++;
    case 3:
      state++;
    case 4:
      arduino.digitalWrite(V40pad_2500doorSw, Arduino.HIGH);
      arduino.digitalWrite(LBRelay, Arduino.HIGH);
      // consoleText += "\n - Starting Low Battery Test    Red & Green LED's blink alternately";
      newLine(" - Starting Low Battery Test    Red & Green LED's blink alternately");
      break;
    case 5:
      state++;
    case 6:
      state++;
    case 7:
      // consoleText += "\n - AC Power ON";
      newLine(" - AC Power ON");
      arduino.digitalWrite(ACPwr, Arduino.HIGH);
      state++;
    case 8:
      arduino.digitalWrite(LBRelay, Arduino.LOW);
      arduino.digitalWrite(V40okc_2500callBtn, Arduino.HIGH);
      // consoleText += "\n - Sending the call signal    Red & Green LED's blink in unison";
      newLine(" - Sending the call signal    Red & Green LED's blink in unison");
      break;
    case 9:
      state++;
    case 10:
      state++;
    case 11:
      state++;
    case 12:
      arduino.digitalWrite(V40okc_2500callBtn, Arduino.LOW);
      arduino.digitalWrite(V40pad_2500doorSw, Arduino.LOW);
      // consoleText += "\n - Turning ON Door switch signal    Red LED turns ON";
      newLine(" - Turning ON Door switch signal    Red LED turns ON");
      testTimer.setDelay(400);
      break;
    case 13:
      state++;
    case 14:
      state++;
    case 15:
      // Verify that the relay state is low
      if ( arduino.digitalRead(relayState) == Arduino.HIGH ) {
        // consoleText += "\n   Relay output is already active! Testing Failed.";
        newLine("   Relay output is already active! Testing Failed.");
        done=true;
        failed=true;
        break;
      }
      arduino.digitalWrite(V40pad_2500doorSw, Arduino.HIGH);
      // consoleText += "\n - Press the key switch    The siren sounds...\n    waiting for relay to change states...";
      newLine(" - Press the key switch    The siren sounds...\n    waiting for relay to change states...");
      break;
    case 16:
      boolean relayOK = false;
      long startTime = millis();
      while (millis () - startTime < 4000 ) {        
        if (arduino.digitalRead(relayState) == Arduino.HIGH) {
          // consoleText += " relay OK.";
          line(" relay OK.");
          relayOK=true;
          break;
        }
      }
      // Restore the delay time
      testTimer.setDelay(sdr1.getValue());

      // Fail if relay did not change states
      if (!relayOK) {
        // consoleText += "\n   Relay failed. \n Stopping test!";
        newLine("   Relay failed. \n Stopping test!");
        failed=true;
      }
      break;
    case 17:
      if (failed)
        break;
      state++;
    case 18:  
      if (failed) {
        done=true;
        break;
      }
      state++;
    case 19:
      // consoleText += "\n\n Perform the following:";
      newLine("\n Perform the following:");
      state++;
    case 20:
      arduino.digitalWrite(V40pad_2500doorSw, Arduino.HIGH);
      // consoleText += "\n - Push the slide tab in"
      // +  "\n       Red & Green LED's turn ON";
      newLine(" - Push the slide tab in" +  "\n       Red & Green LED's turn ON");
      state++;
    case 21:
      // consoleText += "\n - Pull the slide tab out"
      // +  "\n       Red & Green LED's continue to blink";
      newLine(" - Pull the slide tab out"
        +  "\n       Red & Green LED's continue to blink");
      state++;
    case 22:
      arduino.digitalWrite(LBRelay, Arduino.HIGH);
      // consoleText += "\n - Flip the Low Battery Slide Switch to ON\n       Red & Green LED's turn OFF";
      newLine(" - Flip the Low Battery Slide Switch to ON\n       Red & Green LED's turn OFF");
      state++;
      // break;
    case 23:
      // consoleText += "\n - Flip the Low Battery Slide Switch to OFF\n       Red & Green LED's blink alternately"
      // + "\n\n Press space bar when finished...";
      newLine(" - Flip the Low Battery Slide Switch to OFF\n       Red & Green LED's blink alternately"
        + "\n\n Press space bar when finished...");
      testTimer.setDelay(200);  // Speed up the delay to improve the responsivness
      break;
    case 24:
      // Wait here for the space bar to be pressed
      waiting=true;
      testTimer.stop();
      break;
      // return;
    case 25:
      // consoleText += "\n   Testing completed!";
      newLine("   Testing completed!");
      // Thread th = Thread.currentThread();
      try { 
        Thread.currentThread().sleep(1000);
      } 
      catch(InterruptedException ie) { 
        println("delay error");
      }
      state++;
      // break;
    case 26:
      // Complete the testing some short time later
      // LogFile("EAX-2500 tested \t"); // Log the testing
      log.info("EAX-2500 tested \t"); // Log the testing
      testTimer.setDelay(sdr1.getValue()); // Restore the original delay
      done=true;
      break;
    default:
      break;
    }
  }


  /**==============  V40 Testing  ================= */

  else if (currentDevice.getDevices()==Devices.V40) {

    switch (state)
    {
    case 0:
      sBuffer = new StringBuffer("****Starting V40 " + currentDevice.getModelName() + " test****");
      arduino.digitalWrite(testLED, Arduino.HIGH);
      arduino.digitalWrite(testJumper, Arduino.HIGH);
      state++;

    case 1:
      // Power on DC Power if applicable
      if (currentDevice.getModel().hasDC) {
        arduino.digitalWrite(DCPwr, Arduino.HIGH);
        newLine(" - DC Power ON     LEDs flash once");
        break;
      }
      state++;

    case 2:
      // Check Low Battery if applicable
      if (currentDevice.getModel().hasDC) {
        arduino.digitalWrite(LBRelay, Arduino.HIGH);
        newLine(" - Testing Low Battery Mode     LEDs blinks alternately");
        break;
      }
      state++;

    case 3:
      // Turn Off Low Battery if applicable
      if (currentDevice.getModel().hasDC) {
        arduino.digitalWrite(LBRelay, Arduino.LOW);
        newLine("      Low Battery OFF - LEDs turn OFF");
      }
      // Switch over to AC Power if applicable
      if (currentDevice.getModel().hasAC) {
        arduino.digitalWrite(ACPwr, Arduino.HIGH);
        arduino.digitalWrite(LBRelay, Arduino.LOW);
        newLine(" - AC Power ON / Low Battery OFF - LEDs turn OFF");
      }
      break;

    case 4:
      // Check the on-board pad connection
      arduino.digitalWrite(V40pad_2500doorSw, Arduino.HIGH);
      newLine(" - Sending Pad Signal     Red & Green LEDs are ON");
      break;

    case 5:
      arduino.digitalWrite(V40pad_2500doorSw, Arduino.LOW);
      newLine(" - Pad Signal OFF     Red & Green LEDs are OFF");
      break;

    case 6:
      // Check the on-board OKC connection
      arduino.digitalWrite(V40okc_2500callBtn, Arduino.HIGH);
      newLine(" - Sending OKC Signal     Red & Green LEDs blink in unison");
      break;

    case 7:
      arduino.digitalWrite(V40okc_2500callBtn, Arduino.LOW);
      newLine(" - OKC Signal OFF     Red & Green LEDs turn OFF");
      break;

    case 8:
      if (currentDevice.getModel().hasWires) {
        // Check the remote connection on wire leads
        arduino.digitalWrite(remoteSignal, Arduino.HIGH);
        newLine(" - Remote Signal ON     Red & Green LEDs blink in unison");
        break;
      }
      state++; // No wire leads continue on

    case 9:
      if (currentDevice.getModel().hasWires) {
        arduino.digitalWrite(remoteSignal, Arduino.LOW);
        newLine(" - Remote Signal OFF     Red & Green LEDs turn OFF");
        break;
      }
      state++; 

    case 10:
      // Turn off DC power to ensure that the AC power is working
      if (currentDevice.getModel().hasAC) {
        arduino.digitalWrite(DCPwr, Arduino.LOW);
        newLine(" - DC Power OFF     LEDs will flash");
        break;
      }
      state++;

    case 11:
      // Check the relay if applicable
      testTimer.setDelay(100);
      if (currentDevice.getModel().hasRelay && !currentDevice.getModel().hasWires) {
        newLine("Press the key switch (white wires)     Siren sounds and relay activates\nChecking relay now...\n");
      }
      // state++;
      break;

    case 12:
      if (currentDevice.getModel().hasRelay && !currentDevice.getModel().hasWires) {
        long startTime = millis();
        while (millis () - startTime < 5000) {
          if (arduino.digitalRead(relayState) == Arduino.HIGH) {
            line("   Relay OK. Release the key switch");
            state++;
            return;
          }
        }
        newLine("   relay failed. \n Stopping test!");
        failed = true;
        break;
      } else { // No relay, check the key switch anyways
        newLine("   Press the key switch (white wires) now - Siren sounds.");
        state++;
      }

    case 13:
      if (failed) { // Means the relay check has failed!
        done = true;
        break;
      }
      state++;

    case 14:
      newLine("Press the Pad switch (Blue Wires) - Both LEDs turn ON");
      state++;

    case 15:
      newLine(" **Press the space bar when finished");
      state++;

    case 16:
      testTimer.stop(); // Wait here for spacebar
      waiting = true;
      break;

    case 17:
      testTimer.setDelay(sdr1.getValue());
      newLine("   Testing Completed!");
      log.info("V40 tested \t");
      done = true;
      break;

    default:
      break;
    }
  } else {
    newLine("\nError running test");
    testTimer.stop();
  }

  if ( done ) { // Testing Finished

    testTimer.stop(); // Stop the timer

    if (!failed)
      ConfirmPass();
    else
      user.getUser().incrementCount(LoginThread.FAILED_CNT);

    // Turn off all outputs
    for (int i=0; i<outputs.length; i++) {
      if (outputs[i] == heartBeatPin) // Skip the COM LED
        continue;
      arduino.digitalWrite(outputs[i], Arduino.LOW);
    }

    arduino.pinMode(inputs[0], Arduino.INPUT);
    state=0;
    try { 
      Thread.currentThread().sleep(750);
    } 
    catch(Exception ie) { 
      ie.printStackTrace(); 
      println("delay error");
    }

    sBuffer = new StringBuffer(currentDevice.getTestingSetup());
    testing=false;
    failed=false;
    waiting=false;
    return;
  }

  state++;
}

void ConfirmPass() {  // Confirms a pass or fail upon testing

  Runnable doConfirmPass = new Runnable() {
    public void run() {
      Object[] options = { 
        "PASSED", "FAILED", "Cancel"
      };
      int exitChoice = javax.swing.JOptionPane.showOptionDialog(frame, "Please select an option below", "Confirm", 
      javax.swing.JOptionPane.YES_NO_OPTION, javax.swing.JOptionPane.PLAIN_MESSAGE, 
      null, options, options[0]);

      switch(exitChoice) {
      case javax.swing.JOptionPane.YES_OPTION:
        user.getUser().incrementCount(LoginThread.PASSED_CNT);
        user.getUser().incrementCount(LoginThread.TOTAL_CNT);
        break;
      case javax.swing.JOptionPane.NO_OPTION:
        user.getUser().incrementCount(LoginThread.FAILED_CNT);
        user.getUser().incrementCount(LoginThread.TOTAL_CNT);
        break;
      default:
        break;
      }
    }
  };

  SwingUtilities.invokeLater(doConfirmPass);
}

void newLine(String string) {
  sBuffer.append("\n" + string);
}

void line(String string) {
  sBuffer.append(string);
}

