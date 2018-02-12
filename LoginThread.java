import java.io.File;
import java.io.FileInputStream;
import java.io.FileNotFoundException;
import java.io.FileOutputStream;
import java.io.IOException;
import java.io.ObjectInputStream;
import java.io.ObjectOutputStream;
import java.io.Serializable;
import java.io.StreamCorruptedException;
import java.text.DecimalFormat;
import java.text.ParseException;
import java.text.SimpleDateFormat;
import java.util.ArrayList;
import java.util.Calendar;
import java.util.Collections;
import java.util.Comparator;
import java.util.Date;
import java.util.HashSet;
import java.util.List;
import java.util.Set;
import javax.swing.*;
import javax.swing.event.*;
import java.awt.event.*;
import java.awt.*;
import com.dhahaj.*;
import java.util.logging.*;

class LoginThread extends Thread implements Serializable {

  private static final long serialVersionUID = 488622392452789817L;
  private boolean running;
  private boolean loggedIn;
  public User thisUser;
  private ArrayList<User> userArrayList = null;
  private final String filename = tester_project_F1_2.dpath + File.separator + "users.dat";
  private String currentUser;
  final static int TOTAL_CNT = 0, FAILED_CNT = 1, PASSED_CNT = 2, PROG_CNT = 3;
  private Timer loginTimer;
  static Frame f = null;

  final String[][] UserList = {
    {
      "ASG", "AG2012"
    }
    , 
    {
      "BTA", "1419"
    }
    , 
    {
      "DEM", "111902"
    }
    , 
    {
      "EMD", "0138"
    }
    , 
    {
      "IGR", "IZZYGLEN"
    }
    , 
    {
      "MA", "0325"
    }
    , 
    {
      "MLL", "LULU"
    }
    , 
    {
      "MVG", "3-27-5-30"
    }
    , 
    {
      "RLP", "1959"
    }
    , 
    {
      "SLT", "1812"
    }
    , 
    {
      "TBS", "1234"
    }
    , 
    {
      "DMH", "D853"
    }
    , 
    {
      "TCM", "PINZ"
    }
    , 
    {
      "GUEST", "GUEST"
    }
  };

  void init() {
    ArrayList<User> al = new ArrayList<User>();
    User u = null;
    for (int i=0; i<UserList.length; i++) {
      if (i==10 || i==11)
        u = new User(UserList[i][0], UserList[i][1], true);
      else
        u = new User(UserList[i][0], UserList[i][1], false);
      al.add(u);
      System.out.println(u);
    }

    Object[] data = al.toArray();
    storeData(filename, data);
  }

  // Constructor
  public LoginThread() {
    // this.log = tester_project_d4.log;
    running = false;
    loggedIn = false;
    // testCount=testFailed=testPassed=progCount=0;
    // userArrayList = new ArrayList<User>();
    // this.init();
  }

  public LoginThread(Logger log) {
    // this.log = log;
    running = false;
    loggedIn = false;
    // testCount=testFailed=testPassed=progCount=0;
    // userArrayList = new ArrayList<User>();
    // this.init();
  }

  public void start() {
    running=true; // Start the run loop
    //     this.init();
    // userArrayList = loadUsers();
    // userArrayList.add( new User("DMH","d853",true));
    super.start();
  }

  private ArrayList<User> loadUsers() {
    Object[] data = readData(filename);
    ArrayList<User> arrayList = new ArrayList<User>();
    for (int i=0; i<data.length; i++) {
      try {
        arrayList.add((User)data[i]);
      } 
      catch(Exception ex) {
        System.err.println("exception");
      }
    }
    return arrayList;
  }

  public ArrayList<String> getUsers() {
    Object[] data = readData(filename);
    ArrayList<String> arrayList = new ArrayList<String>();  
    for (int i=0; i<data.length; i++) {
      try {
        arrayList.add(((User)data[i]).getName());
      } 
      catch(Exception ex) {
        System.err.println("exception");
        ex.printStackTrace();
      }
    }
    return arrayList;
  }

  /** MAIN LOOP **/
  public void run() {

    loginTimer = new Timer(300000, new ActionListener() {
      public void actionPerformed(ActionEvent evt) {
        tester_project_F1_2.log.info("\nUser "+getUsername()+" auto log off\t");
        logout();
        tester_project_F1_2.currentDevice = null;
        tester_project_F1_2.sBuffer = new StringBuffer("User auto logged out..");
      }
    }
    );

    // Outer Loop
    while (running) {

      // Inner Loop
      while (!loggedIn) {

        ArrayList<String> usernames = new ArrayList<String>();
        userArrayList = loadUsers();

        for ( User u : userArrayList)
          usernames.add(u.getName());

        final JComboBox userid = new  JComboBox(usernames.toArray(new String[usernames.size()]));
        int previousIndex = (Integer)Keys.LAST_USER.value;

        try { // try incase the index is out of bounds
          userid.setSelectedIndex( (Integer)Keys.LAST_USER.value );
        } 
        catch(Exception e) {
          e.printStackTrace();
        }

        final JPasswordField pwd = new JPasswordField(10);
        pwd.addAncestorListener( new RequestFocusListener() );
        final JPanel panel = new JPanel(new GridLayout(2, 2));
        panel.add( new JLabel( "UserID:") );
        panel.add( userid );
        panel.add( new JLabel( "Password:") );
        panel.add( pwd );

        int action = JOptionPane.showConfirmDialog(f, panel, "LOGIN", JOptionPane.OK_CANCEL_OPTION);

        if (action==JOptionPane.OK_OPTION) { // OK button pressed, verify the password

          // Get the user selected from the list
          final User selectedUser = userArrayList.get(userid.getSelectedIndex());

          // Store selected user
          Keys.LAST_USER.setPref(userid.getSelectedIndex());

          // Check the password
          final String pass = new String(pwd.getPassword());
          if (selectedUser.checkPassword(pass)) { // Password Accepted!
            thisUser = selectedUser;
            MyLogger.User = thisUser.getName();
            loggedIn = true;
            loginTimer.start();
            enableMenu(thisUser.isAdmin());
            tester_project_F1_2.cleanGarbage();
            break;
          } else { // Display a bad password notification
            try {
              SwingUtilities.invokeAndWait(new Runnable() {
                public void run() {
                  JOptionPane.showMessageDialog(f, "Incorrect Password!", "Error", JOptionPane.ERROR_MESSAGE );
                }
              }
              );
            } 
            catch(Exception e) { 
              e.printStackTrace();
            }
          }
        } else { // Cancel or escape was pressed. Prompt to either login or close software.
          try {
            SwingUtilities.invokeAndWait( new Runnable() {
              public void run() {
                int exitChoice = JOptionPane.showConfirmDialog(f, "Are you sure you want to exit?", "Confirm exit", JOptionPane.YES_NO_OPTION );
                if (exitChoice != JOptionPane.YES_OPTION)
                  return;
                tester_project_F1_2.log.info("Software closed");
                quit();
                System.exit(0);
              }
            }
            );
          } 
          catch(Exception e) {
            e.printStackTrace();
          }
        }
      } // END_INNER_LOOP
    } // END_OUTER_LOOP
  }

  boolean loggedin() {
    return loggedIn;
  }

  void logout() {
    tester_project_F1_2.cleanGarbage();
    if (loggedIn) {
      synchronized(this) {
        tester_project_F1_2.log.info("\nUser " + thisUser.getName()
          + " logged off\n\t*devices passed: "  + thisUser.getCount(PASSED_CNT)
          + "\n\t*devices failed: "              + thisUser.getCount(FAILED_CNT)
          + "\n\t*total devices tested: "        + thisUser.getCount(TOTAL_CNT)
          + "\n\t*devices programmed: "         + thisUser.getCount(PROG_CNT)
          + "\n\t*" );
      }
      MyLogger.User = getUsername();
      loggedIn = false;
    }

    // Stop the timer if running
    if (loginTimer.isRunning())
      loginTimer.stop();
  }

  void restartTimer() {
    if (loggedIn)
      loginTimer.restart();
  }

  String getUsername() {
    if (loggedIn && thisUser.getName()!=null)
      return thisUser.getName();
    else
      return null;
  }

  User getUser() {
    return this.thisUser;
  }

  // Our method that quits the thread
  void quit() {
    // Stop the timer
    try {
      if (loginTimer.isRunning())
        loginTimer.stop();
    }
    catch(Exception t) {
      t.printStackTrace();
    }
    loggedIn = false;
    running = false;  // Setting running to false ends the loop in run()
    System.out.println("LoginThread is stopping."); 
    // In case the thread is waiting. . .
    // interrupt();
  }

  public void addNewUser(String name, String pass, boolean admin) {
    User newUser = new User(name, pass, admin);
    userArrayList.add(newUser);
    storeData(filename, userArrayList.toArray());
  }

  public String removeUser(int index) {
    // Remove the user from the list
    User removedUser = userArrayList.remove(index);

    // Save the modified list
    storeData(this.filename, userArrayList.toArray());

    // Return the name of the removed user
    return removedUser.getName();
  }

  public boolean isAdmin() {
    return thisUser.isAdmin();
  }

  private synchronized boolean storeData(String filename, Object[] data) {
    try {
      ObjectOutputStream outStream = new ObjectOutputStream(new FileOutputStream(filename));
      outStream.writeObject(data);
      outStream.close();
      System.out.println("Users Stored");
      return true;
    } 
    catch (FileNotFoundException e) {
      e.printStackTrace();
    } 
    catch (IOException e) {
      e.printStackTrace();
    }
    System.err.println("Users Not Stored");
    return false;
  }

  private Object[] readData(String filename) {
    Object[] entries = null;
    try {
      ObjectInputStream inStream =
        new ObjectInputStream(new FileInputStream(filename));
      entries = (Object[]) inStream.readObject();
      inStream.close();
    } 
    catch (StreamCorruptedException e) {
      e.printStackTrace();
    } 
    catch (FileNotFoundException e) {
      e.printStackTrace();
    } 
    catch (IOException e) {
      e.printStackTrace();
    } 
    catch (ClassNotFoundException e) {
      e.printStackTrace();
    }
    return entries;
  }

  boolean running() {
    return running;
  }


  public class RequestFocusListener implements AncestorListener {
    private boolean removeListener;
    public RequestFocusListener() {
      this(true);
    }
    public RequestFocusListener(boolean removeListener) {
      this.removeListener = removeListener;
    }
    public void ancestorAdded(AncestorEvent e) {
      JComponent component = e.getComponent();
      component.requestFocusInWindow();
      if (removeListener)
        component.removeAncestorListener( this );
    }
    public void ancestorMoved(AncestorEvent e) {
    }
    public void ancestorRemoved(AncestorEvent e) {
    }
  }


  public void enableMenu(boolean enable) {
    MenuBar mb = f.getMenuBar();
    Menu config = mb.getMenu(3);
    // println(config.getLabel());
    MenuItem adminMenu = config.getItem(config.getItemCount()-1);
    adminMenu.setEnabled(enable);
  }
}











