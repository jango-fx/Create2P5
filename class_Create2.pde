import processing.serial.*;
import processing.core.*;
import org.apache.commons.logging.impl.SimpleLog;

class Create2 {
  PApplet app;
  SimpleLog LOG;

  Serial serial;
  String serialPort = "/dev/cu.usbserial-DA01NWTC";
  int serialBaudRate = 115200;

  JSONObject config;
  String configPath = sketchPath()+"/config.json";
  LOG = new SimpleLog("CREATE2");

  int sleepTimer = 500;

  JSONObject sensorState;
  SensorPacketDecoder sensorDecoder;

  Create2(PApplet theApp)
  {
    LOG.setLevel(SimpleLog.LOG_LEVEL_ALL);

    this.logInfo("Loading Config", configPath);
    config = loadJSONObject(configPath);

    this.logInfo("Starting Serial Connection", serialPort, serialBaudRate);
    //serial = new Serial(theApp, serialPort, serialBaudRate);
  }

  void serialSend(int theOpCode, int... theData)
  {
    byte[] temp_opcode = new byte[]{byte(theOpCode)};
    byte[] bytes = null;

    if (theData == null || theData.length == 0)
      bytes = temp_opcode;
    else
      bytes = concat(temp_opcode, byte(theData));

    //self.ser.write(struct.pack('B' * len(bytes), *bytes))
    /*
    //>>> import java.io.*;

    ByteArrayOutputStream b = new ByteArrayOutputStream();
     DataOutputStream d = new DataOutputStream(b);
     try {
     d.write(bytes);
     }
     catch(Exception e) {
     logError("Serial Send", e);
     }
     byte[] result = b.toByteArray();
     serial.write(result);
     //*/

    String msgData = "";
    for (int i = 0; i < theData.length; i++)
      msgData += theData[i]+" ";
    String msgBytes = "";
    for (int i = 0; i < bytes.length; i++)
      msgBytes += (hex(bytes[i], 2))+" ";
    logDebug("Serial Send", "OpCode: "+theOpCode, "Data: "+msgData, "Bytes: "+msgBytes);
    serial.write(bytes);
  }

  byte[] serialRead(int theNum)
  {
    /* Read a string of 'num_bytes' bytes from the robot.

     Arguments:
     num_bytes: The number of bytes we expect to read.
     */

    byte[] data = serial.readBytes(theNum);
    logDebug("serialRead", "read "+data.length+" bytes from SCI port.");
    if (data.length == 0)
      logError("Error reading from SCI port. No data.");
    if (data.length != theNum)
      logError("Error reading from SCI port. Wrong data length.");

    return data;
  }

  void start() {
    logInfo("start");
    this.serialSend(config.getJSONObject("opcodes").getInt("start"));
  }
  void reset() {
    logInfo("reset");
    this.serialSend(config.getJSONObject("opcodes").getInt("reset"));
  }
  void stop() {
    logInfo("stop");
    this.serialSend(config.getJSONObject("opcodes").getInt("stop"));
  }
  void baud(int theBaudRate)
  {
    HashMap<Integer, Integer> baud_dict = new HashMap<Integer, Integer>();
    baud_dict.put(300, 0);
    baud_dict.put(600, 1);
    baud_dict.put(1200, 2);
    baud_dict.put(2400, 3);
    baud_dict.put(4800, 4);
    baud_dict.put(9600, 5);
    baud_dict.put(14400, 6);
    baud_dict.put(19200, 7);
    baud_dict.put(28800, 8);
    baud_dict.put(38400, 9);
    baud_dict.put(57600, 10);
    baud_dict.put(115200, 11);

    if (baud_dict.get(theBaudRate) != null)
      this.serialSend(config.getJSONObject("opcodes").getInt("baud"), baud_dict.get(theBaudRate));
    else
      logError("baud: Invalid baud rate", theBaudRate);
  }

  void safe() {
    // Puts the Create 2 into safe mode. Blocks for a short (<.5 sec) amount of time so the bot has time to change modes.
    this.serialSend(config.getJSONObject("opcodes").getInt("safe"));
    delay(sleepTimer);
  }
  void full() {
    // Puts the Create 2 into full mode. Blocks for a short (<.5 sec) amount of time so the bot has time to change modes.
    this.serialSend(config.getJSONObject("opcodes").getInt("full"));
    delay(sleepTimer);
  }
  void clean() {
    this.serialSend(config.getJSONObject("opcodes").getInt("clean"));
  }
  void max() {
    this.serialSend(config.getJSONObject("opcodes").getInt("max"));
  }
  void spot() {
    this.serialSend(config.getJSONObject("opcodes").getInt("spot"));
  }
  void seek_dock() {
    this.serialSend(config.getJSONObject("opcodes").getInt("seek_dock"));
  }
  void power() {
    this.serialSend(config.getJSONObject("opcodes").getInt("power"));
  }


  void set_day_time(String day, int hour, int minute) {
    /*--- Sets the Create2's clock -----------------/
     day:  A string describing the day.
     hour: A number from 0-23 (24 hour format)
     minute: A number from 0-59
     //--------------------------------------------*/

    int[] data = new int[3];
    boolean noError = true;
    day = day.toLowerCase();

    HashMap<String, Integer> day_dict = new HashMap<String, Integer>();
    day_dict.put("sunday", 0);
    day_dict.put("monday", 1);
    day_dict.put("tuesday", 2);
    day_dict.put("wednesday", 3);
    day_dict.put("thursday", 4);
    day_dict.put("friday", 5);
    day_dict.put("saturday", 6);


    if (day_dict.get(day) != null)
      data[0] = day_dict.get(day);
    else {
      noError = false;
      logError("set_day_time: Invalid day input");
    }
    if (hour >= 0 && hour <= 23)
      data[1] = hour;
    else {
      noError = false;
      logError("set_day_time: Invalid hour input");
    }
    if (minute >= 0 && minute <= 59)
      data[2] = minute;
    else {
      noError = false;
      logError("set_day_time: Invalid minute input");
    }
    if (noError)
      this.serialSend(config.getJSONObject("opcodes").getInt("set_day_time"), data);
    else
      logError("Invalid data, failed to send");
  }


  /////////////////////////////////////////////////////////////////////////////////
  /// MOTOR CONTROL  //////////////////////////////////////////////////////////////
  /////////////////////////////////////////////////////////////////////////////////

  void drive_straight(int velocity) {
    /* Will make the Create2 drive straight at the given velocity

     Arguments:
     velocity: Velocity of the Create2 in mm/s. Positive velocities are forward,
     negative velocities are reverse. Max speeds are still enforced by drive()

     */
    this.drive(velocity, 32767);
  }

  void  turn_clockwise(int velocity) {
    /* Makes the Create2 turn in place clockwise at the given velocity

     Arguments:
     velocity: Velocity of the Create2 in mm/s. Positive velocities are forward,
     negative velocities are reverse. Max speeds are still enforced by drive()
     */
    this.drive(velocity, -1);
  }

  void  turn_counter_clockwise(int velocity) {
    /* Makes the Create2 turn in place counter clockwise at the given velocity

     Arguments:
     velocity: Velocity of the Create2 in mm/s. Positive velocities are forward,
     negative velocities are reverse. Max speeds are still enforced by drive()
     */
    this.drive(velocity, 1);
  }

  void drive(int velocity, int radius) {
    /*"""Controls the Create 2's drive wheels.

     Args:
     velocity: A number between -500 and 500. Units are mm/s.
     radius: A number between -2000 and 2000. Units are mm.
     Drive straight: 32767
     Turn in place clockwise: -1
     Turn in place counterclockwise: 1
     """*/
    boolean noError = true;
    int[] data = new int[4];
    int v=0;
    int r=0;

    // Check to make sure we are getting sent valid velocity/radius.
    if (velocity >= -500 && velocity <= 500)
      v = unhex(hex(velocity, 4)); //Convert 16bit velocity to Hex
    else {
      noError = false;
      logError("Invalid velocity input");
    }
    if (radius == 32767 || radius == -1 || radius == 1)
      // Special case radius
      r = unhex(hex(radius, 4)); // Convert 16bit radius to Hex

    else {
      if (radius >= -2000 && radius <= 2000)
        r = unhex(PApplet.hex(radius, 4)); // Convert 16bit radius to Hex
      else {
        noError = false;
        logError("Invalid radius input");
      }
    }
    if (noError) {
      data = new int[4]; // <- assuming "in" value in 0..65535 range and we can use 2 ints only

      data[0] = (v & 0xFF);
      data[1] = ((v >> 8) & 0xFF);

      data[2] = (r & 0xFF);
      data[3] = ((r >> 8) & 0xFF);

      // data[0] = Velocity high byte
      // data[1] = Velocity low byte
      // data[2] = Radius high byte
      // data[3] = Radius low byte

      this.serialSend(config.getJSONObject("opcodes").getInt("drive"), data);
    } else
      logError("Invalid data, failed to send");
  }

  void motors_pwm(int main_pwm, int side_pwm, int vacuum_pwm) {
    /* Serial sequence: [144] [Main Brush PWM] [Side Brush PWM] [Vacuum PWM]

     main_pwm: Duty cycle for Main Brush. Value from -127 to 127. Positive speeds spin inward.
     side_pwm: Duty cycle for Side Brush. Value from -127 to 127. Positive speeds spin counterclockwise.
     vacuum_pwm: Duty cycle for Vacuum. Value from 0-127. No negative speeds allowed.
     */
    boolean noError = true;
    int[] data = new int[3];

    // First check that our data is within bounds
    if (main_pwm >= -127 && main_pwm <= 127)
      data[0] = main_pwm;
    else {
      noError = false;
      logError("Invalid Main Brush input");
    }
    if (side_pwm >= -127 && side_pwm <= 127)
      data[1] = side_pwm;
    else {
      noError = false;
      logError("Invalid Side Brush input");
    }
    if (vacuum_pwm >= 0 && vacuum_pwm <= 127)
      data[2] = vacuum_pwm;
    else {
      noError = false;
      logError("Invalid Vacuum input");
    }
    // Send it off if there were no errors.
    if (noError)
      this.serialSend(config.getJSONObject("opcodes").getInt("motors_pwm"), data);
    else
      logError("Invalid data, failed to send");
  }


  /////////////////////////////////////////////////////////////////////////////////
  /// SENSORS  ////////////////////////////////////////////////////////////////////
  /////////////////////////////////////////////////////////////////////////////////

  void sensors(int thePacketID) {
    /* Requests the OI to send a packet of sensor data bytes.

     Arguments:
     packet_id: Identifies which of the 58 sensor data packets should be sent back by the OI.
     */

    // Check to make sure that the packet ID is valid.
    String packet_id = String.valueOf(thePacketID);
    if (config.getJSONObject("sensor group packet lengths").get(packet_id) != null) {
      // Valid packet, send request (But convert it back to an int in a list first)
      this.serialSend(config.getJSONObject("opcodes").getInt("sensors"), int(packet_id));
    } else
      logError("Invalid packet id, failed to send");
  }

  boolean getPacket(int thePacketID) {
    /* Requests and reads a packet from the Create 2

     Arguments:
     packet_id: The id of the packet you wish to collect.

     Returns: False if there was an error, True if the packet successfully came through.
     */
    String packet_id = String.valueOf(thePacketID);
    int packet_size;
    byte[] packet_byte_data;
    if (config.getJSONObject("sensor group packet lengths").get(packet_id) != null) {
      // If a packet is in this dict, that means it is valid
      packet_size = config.getJSONObject("sensor group packet lengths").getInt(packet_id);
      // Let the robot know that we want some sensor data!
      this.sensors(thePacketID);
      // Read the data
      packet_byte_data = this.serialRead(packet_size);
      // Once we have the byte data, we need to decode the packet and save the new sensor state
      this.sensorState = this.sensorDecoder.decodePacket(thePacketID, packet_byte_data, this.sensorState);
      return true;
    } else {
      // The packet was invalid, raise an error
      logError("Invalid packet ID");
      return false;
    }
  }

  /////////////////////////////////////////////////////////////////////////////////
  /// LED DISPLAY  ////////////////////////////////////////////////////////////////
  /////////////////////////////////////////////////////////////////////////////////

  void digit_led_ascii(String display_string) {
    /*"""This command controls the four 7 segment displays using ASCII character codes.

     Arguments:
     display_string: A four character string to be displayed. This must be four
     characters. Any blank characters should be represented with a space: ' '
     Due to the limited display, there is no control over upper or lowercase
     letters. create2api will automatically convert all chars to uppercase, but
     some letters (Such as 'B' and 'D') will still display as lowercase on the
     Create 2's display. C'est la vie.
     """*/
    boolean noError = true;
    int[]       display_list = new int[4];
    display_string = display_string.toUpperCase();
    // print display_string
    if (display_string.length() != 4) {
      // Too many or too few characters!
      noError = false;
      logError("Invalid ASCII input (Must be EXACTLY four characters)");
    }
    if (noError) {
      // Need to map ascii to numbers from the dict.
      for (int i=0; i<4; i++) {
        // Check that the character is in the list, if it is, add it.
        if (config.getJSONObject("ascii table").get(String.valueOf(display_string.charAt(i))) != null)
          //if (display_string[i] in self.config.data['ascii table'])
          display_list = append(display_list, config.getJSONObject("ascii table").getInt(String.valueOf(display_string.charAt(i))));
        else {
          // Char was not available. Just print a blank space
          // Raise an error so the software knows that the input was bad
          display_list = append(display_list, config.getJSONObject("ascii table").getInt(" "));
          logInfo("digit_led_ascii: Warning", "Char '" + String.valueOf(display_string.charAt(i)) + "' was not found in ascii table");
        }
      }
      this.serialSend(config.getJSONObject("opcodes").getInt("digit_led_ascii"), display_list);
    } else
      logError("Invalid data, failed to send");
  }


  /////////////////////////////////////////////////////////////////////////////////
  /// SOUND  //////////////////////////////////////////////////////////////////////
  /////////////////////////////////////////////////////////////////////////////////

  void play_test_sound() {
    /*written to figure out how to play sounds. creates a song with a playlist of notes and durations and then plays it through the speaker using a hilariously messy spread of concatenated lists
     */
    boolean noError = true;
    // sets lengths of notes
    int short_note = 8;
    int medium_note = 16;
    int long_note = 20;

    // stores a 4 note song in song 3
    int current_song = 3;
    int song_length = 4;
    int[] song_setup = new int[]{current_song, song_length};
    int[] play_list = new int[0];

    // writes the song note commands to play_list
    // change these to change notes
    play_list = concat(play_list, new int[]{config.getJSONObject("midi table").getInt("C#4"), medium_note});
    play_list = concat(play_list, new int[]{config.getJSONObject("midi table").getInt("G4"), long_note});
    play_list = concat(play_list, new int[]{config.getJSONObject("midi table").getInt("A#3"), short_note});
    play_list = concat(play_list, new int[]{config.getJSONObject("midi table").getInt("A3"), short_note});

    // adds up the various commands and arrays
    int[] song_play = new int[]{ config.getJSONObject("opcodes").getInt("play"), current_song};
    int[] play_sequence = concat(song_setup, play_list);
    play_sequence = concat(play_sequence, song_play);

    if (noError)
      this.serialSend(config.getJSONObject("opcodes").getInt("song"), play_sequence);
    else
      logError("Invalid data, failed to send");
  }
  void create_song(int song_number, int[] play_list) {
    logError("create_song: METHOD NOT YET IMPLEMENTED");
  }
  void play(int song_number) {
    /* Plays a stored song */
    boolean noError = true;
    if (noError)
      this.serialSend(config.getJSONObject("opcodes").getInt("play"), song_number);
    else
      logError("Invalid data, failed to send");
  }
  void play_note(int note_name, int note_duration) {
    /* Plays a single note by creating a 1 note song in song 0 */
    int current_song = 0;
    int[] play_list;
    boolean noError = true;
    if (noError)
      // Need to map ascii to numbers from the dict.
      if (config.getJSONObject("midi table").get("note_name") != null) {
        play_list = append(play_list, config.getJSONObject("midi table").getInt("note_name"));
        play_list = append(play_list, note_duration);
      } else {
        // That note doesn't exist. Plays nothing
        // Raise an error so the software knows that the input was bad
        play_list = append(play_list, config.getJSONObject("midi table").getInt("rest"));
        logInfo("play_note: Warning", "Note '" + note_name + "' was not found in midi table");
      }
    // create a song from play_list and play it
    this.create_song(current_song, play_list);
    this.play(current_song);
  }
  void play_song(int song_number, int note_string) {
    logError("METHOD NOT YET IMPLEMENTED");
  }

  /////////////////////////////////////////////////////////////////////////////////


  void logInfo(String title, Object... msgList)
  {
    title = title.toUpperCase();
    String divider = "  ";
    for (int i = 0; i < PApplet.max(50-title.length(), 0); i++)
      divider += "–";

    String msg = "";
    for (int i = 0; i < msgList.length; i++)
      msg += msgList[i].toString()+"\n  ";

    LOG.info(title+divider+"\n  "+msg);
  }

  void logDebug(String title, Object... msgList)
  {
    title = title.toUpperCase();
    String divider = "  ";
    for (int i = 0; i < PApplet.max(49-title.length(), 0); i++)
      divider += "–";

    String msg = "";
    for (int i = 0; i < msgList.length; i++)
      msg += msgList[i].toString()+"\n  ";

    LOG.debug(title+divider+"\n  "+msg);
  }

  void logError(String title, Object... msgList)
  {
    title = title.toUpperCase();
    String divider = " ";
    for (int i = 0; i < PApplet.max(50-title.length(), 0); i++)
      divider += "/";

    String msg = "";
    for (int i = 0; i < msgList.length; i++)
      msg += msgList[i].toString()+"\n  ";

    LOG.error(title+divider+"\n  "+msg);
  }
}
