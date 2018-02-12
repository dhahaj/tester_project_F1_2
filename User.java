import java.io.Serializable;

/**
 *    Class that holds the data for users thier passwords
 */
public class User implements Serializable
{
  private static final long serialVersionUID = -7641865726502498527L;
  static final int PASSED_CNT = 0;
  static final int FAILED_CNT = 1;
  static final int PROG_CNT = 2;
  static final int TOTAL_CNT = 3;
  private String username = null;
  private String password = null;
  private boolean admin = false;
  private int passed_count = 0;
  private int failed_count = 0;
  private int pgm_count = 0;
  private int total_count = 0;

  User(String username, String password) {
    this.username = username;
    this.password = password;
    this.admin = false;
  }

  User(String username, String password, boolean admin) {
    this.username = username;
    this.password = password;
    this.admin = admin;
  }

  public void incrementCount(int which) {
    switch(which) {
    case PASSED_CNT:
      this.passed_count++;
      break;
    case FAILED_CNT:
      this.failed_count++;
      break;
    case PROG_CNT:
      this.pgm_count++;
      break;
    case TOTAL_CNT:
      this.total_count++;
      break;
    }
  }

  public int getCount(int which) {
    switch(which) {
    case PASSED_CNT:
      return this.passed_count;
    case FAILED_CNT:
      return this.failed_count;
    case PROG_CNT:
      return this.pgm_count;
    case TOTAL_CNT:
      return this.total_count;
    }
    return 0;
  }

  public String toString() {
    return this.username + " " + this.password;
  }

  public boolean isAdmin() {
    return this.admin;
  }

  public String getName() {
    return this.username;
  }

  /**
   *    Verifys the password for a given user.
   *    @param p The password to check (ignores case).
   *    @return True if the password matches this users password.
   */
  public boolean checkPassword(String p) {
    return p.equalsIgnoreCase(this.password);
  }
}

