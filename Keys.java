import java.io.File;
import java.util.prefs.Preferences;

public enum Keys {
  QW_PATH("/pictools/qw.exe"), 
  QW_ARGS("/D16F627 /A /X"), 
  QW_ARUN("/A"), 
  QW_AEXIT("/X"), 
  QW_CHIP("/D16F627"), 

  FIRMWARE_FOLDER("C:\\Firmware"), 
  LAST_SERIAL(0), // The last serial number used

  EAX300_PATH("C:\\EAX_300_5.9\\EAX300_5.9.OBJ"), 
  EAX300_FILE("EAX300_5.9.OBJ"), 
  EAX300_EXT("_5.9.OBJ"), 

  EAX500_PATH("C:\\EAX_500_v5.9.1\\EAX500_591.OBJ"), 
  EAX500_FILE("EAX500_591.OBJ"), 
  EAX500_EXT("_591.OBJ"), 

  EAX2500_PATH("C:\\EAX_2500_V73\\EAX2500_73.OBJ"), 
  EAX2500_FILE("EAX2500_73.OBJ"), 
  EAX2500_EXT("_73.OBJ"), 

  // EAX3500_PATH("C:\\EAX_3500_A0\\EAX3500_A0.OBJ"),
  //  EAX3500_FILE("EAX3500_A0.OBJ"),
  //  EAX3500_EXT("_A0.OBJ"),

  V40_PATH("C:\\v40_ver4_0\\V40xx00_40.OBJ"), 
  V40_FILE("V40xx00_54.OBJ"), 
  V40_EXT("_54.OBJ"), 

  WIDTH_SCALER(65), 
  HEIGHT_SCALER(75), 
  LAST_USER(10), 
  LAST_DELAY(594), 
  COM_PORT("COM 1"), 
  COM(1), 
  MAX_SPEED(1000);

  Object value;
  Object defaultValue;
  Preferences prefs = Preferences.userNodeForPackage(this.getClass());

  // Constructors:
  Keys(String defVal) {
    this.defaultValue = defVal;
    this.value = (String)prefs.get(this.name(), defVal);
    System.out.println("Loaded " + this.name() + ": " + this.value);
  }

  Keys(int defVal) {
    this.defaultValue = defVal;
    this.value = ((Integer)(prefs.getInt(this.name(), defVal))).intValue();
    System.out.println("Loaded " + this.name() + ": " + this.value);
  }

  Keys(boolean defVal) {
    this.defaultValue = defVal;
    this.value = ((Boolean)(prefs.getBoolean(this.name(), defVal))).booleanValue();
    System.out.println("Loaded " + this.name() + ": " + this.value);
  }

  public Preferences getPrefs() {
    return prefs;
  }

  public void setPref(String value) {
    this.prefs.put(this.name(), (String) value);
    this.value = value;
  }

  public void setPref(int value) {
    this.prefs.putInt(this.name(), value);
    this.value = value;
  }

  public void clearPref() {
    this.value = defaultValue;
    if ( defaultValue instanceof Integer) {
      this.setPref((Integer) defaultValue);
    } else if ( defaultValue instanceof String )
      this.setPref((String) defaultValue);
  }

  static void clearAllPrefs() {
    for (Keys key : Keys.values ()) {
      key.clearPref();
    }
  }

  public String toString() {
    return this.name() + ": " + this.value;
  }
}

