
import java.util.ArrayList;

/**
 * An enumeration of all the available firmwares for a device, categorized
 * by device and indexed by order.
 */
enum Programs {
  EAX300(Devices.EAX300, 1), // 1
  EAX500(Devices.EAX500, 2), EAX503(Devices.EAX500, 3), EAX504(Devices.EAX500, 4), EAX505(Devices.EAX500, 5), EAX510(Devices.EAX500, 6), EAX513(Devices.EAX500, 7), EAX514(Devices.EAX500, 8), EAX515(Devices.EAX500, 9), EAX520(Devices.EAX500, 10), EAX523(Devices.EAX500, 11), EAX524(Devices.EAX500, 12), EAX525(Devices.EAX500, 13), // 13
  EAX2500(Devices.EAX2500, 14), EAX2503(Devices.EAX2500, 15), EAX2504(Devices.EAX2500, 16), EAX2505(Devices.EAX2500, 17), EAX2510(Devices.EAX2500, 18), EAX2513(Devices.EAX2500, 19), EAX2514(Devices.EAX2500, 20), EAX2520(Devices.EAX2500, 21), EAX2523(Devices.EAX2500, 22), EAX2524(Devices.EAX2500, 23), EAX2545(Devices.EAX2500, 24), //22
  V40xx00(Devices.V40, 25, "15sec delay/2min rearm"), 
  V40xx03(Devices.V40, 26, "15sec delay/10min rearm"), 
  V40xx04(Devices.V40, 27, "15sec delay/20min rearm"), 
  V40xx10(Devices.V40, 28, "1sec delay/2min rearm"), 
  V40xx13(Devices.V40, 29, "1sec delay/10min rearm"), 
  V40xx14(Devices.V40, 30, "1sec delay/20min rearm"), 
  V40xx20(Devices.V40, 31, "5sec delay/2min rearm"), 
  V40xx23(Devices.V40, 32, "5sec delay/10min rearm"), 
  V40xx24(Devices.V40, 33, "5sec delay/20min rearm"), //33
  V40sa00(Devices.V40, 34, "15sec delay/2min rearm/Silent Arming");//, //34
  //  EAX3500(Devices.EAX3500, 35); //35

  /**
   * The device category of this program. 
   */
  final Devices device;

  /**
   * The index of the program within all the programs. 
   */
  final int index;

  String timing = null;

  /**
   * Available firmwares for all the devices.
   * @param d The device to categorize the program with.
   * @param index The index of the program within all the programs.
   */
  Programs(Devices d, int index) {
    this.device = d;
    this.index = index;
  }

  /**
   * Constructor for the V40 Family.
   * @param d V40 Device.
   * @param i Index within the program enumeration.
   * @param timing The timing associated with this software.
   */
  Programs(Devices d, int i, String timing) {
    this.device=d;
    this.index=i;
    this.timing = timing;
  }

  boolean isStandard() {
    switch(this) {
    case EAX300:
    case EAX500:
    case EAX2500:
      // case EAX3500:
    case V40xx00:
      return true;
    default:
      break;
    }
    return false;
  }


  /**
   * Retrieves a list containing all the programs for a device.
   * @param d The device family.
   * @return String[] containing the list of programs.
   */
  static String[] getProgramList(Devices d) {
    final ArrayList<String> strings = new ArrayList<String>();
    for ( Programs  pgm : Programs.values () ) {
      if (pgm.device.equals(d)) {
        strings.add(pgm.name());
      }
    }
    return strings.toArray(new String[strings.size()]);
  }

  /**
   * Retrieves a list containing all the programs in this device family.
   * @param p The program to get the device family from.
   * @return String[] containing the list of programs.
   */
  static String[] getProgramList(Programs p) {
    return getProgramList(p.device);
  }
}

