maccaferriPS IOC — Serial (Modbus RTU) configuration

Overview
--------
This IOC is adapted from the original `templatedmodbus` example and renamed to **maccaferriPS**.
It provides a Modbus RTU interface (serial) implementing the command and readback register map described in the supplied specification (command area 0x0000..0x001F and readback area 0x0020..0x003F).

What was changed
-----------------
- IOC product name updated to `maccaferriPS` (see `src/Makefile`).
- A serial RTU example startup is in `iocBoot/modbusiocSample/ioc-modbus-device.cmd`.
- Database `Db/maccaferriPS.db` implements commands (PV names), current setpoint, fast readbacks (current/voltage), faults and state bits.
- Fast readbacks are polled at 40 ms by default (>=20 Hz requirement).

Quick start (build & run)
-------------------------
1. Build the IOC (from the app/src directory):

   cd templatedmodbusApp/src
   make

2. Start IOC using the example startup (adjust the serial device and substitutions in the `.cmd`):

   cd ../iocBoot/modbusiocSample
   # Edit ioc-modbus-device.cmd to set /dev/ttyXXX and slave id before running
   ../../bin/linux-x86_64/maccaferriPS ioc-modbus-device.cmd

Notes on configuration
----------------------
- Serial port name and settings are configured in the startup script using:

  drvAsynSerialPortConfigure("MACCF_ASYN", "/dev/ttyUSB0", 0, 0, 0)
  asynSetOption("MACCF_ASYN", -1, "baud", "19200")
  asynSetOption("MACCF_ASYN", -1, "parity", "none")
  ...

- `modbusInterposeConfig("MACCF_ASYN", 1, 2000, 10)` sets the link type to RTU (1), with a 2s timeout and small write delay.

- The DB is loaded with substitution parameters. Example load in the `.cmd`:

  dbLoadRecords("$(TOP)/db/maccaferriPS.db", "P=MACCF,R=PS01,PORTFAST=MACCF_FAST_AI,PORTSLOW=MACCF_SLOW_AI,PORTCMD=MACCF_CMD_RO,WPORT=MACCF_CMD_WO,COIL_W=MACCF_COIL_W,SLAVE=1,TIMEOUT=2000,WPOLL=0,RPOLL=40")

PV mapping highlights
---------------------
- Commands (coils):
  - $(P):$(R):CMD_STANDBY  (bit 0)
  - $(P):$(R):CMD_ON       (bit 1)
  - $(P):$(R):CMD_OFF      (bit 2)
  - $(P):$(R):CMD_RESET    (bit 3)
  - $(P):$(R):CMD_STARTRAMP(bit 4)
  - $(P):$(R):CMD_MODE_DC  (bit 5)
  - $(P):$(R):CMD_MODE_PULSED(bit 6)
  - $(P):$(R):CMD_POLA_POSITIVE(bit 7)
  - $(P):$(R):CMD_POLA_NEGATIVE(bit 8)

- Current setpoint (holding register 0x0001):
  - $(P):$(R):CURR_SET  (ao, writes 0x0001)

- Fast readbacks (registers 0x0023..0x0026) polled at 40 ms:
  - $(P):$(R):CURR_RB
  - $(P):$(R):OUTPUT_CURRENT_RB
  - $(P):$(R):OUTPUT_VOLTAGE_RB
  - $(P):$(R):GROUND_CURRENT_RB

- Faults & states are split across 0x0020..0x0022 and exposed as binary inputs in the DB.

Testing with virtual serial ports
---------------------------------
You can simulate the device locally using a pair of virtual serial ports created by `socat` and a Modbus simulator (e.g., pymodbus `mbserver` or `mbserver`-like tools).

1. Create paired PTYs:
   socat -d -d pty,raw,echo=0 pty,raw,echo=0

   This prints two device paths — use one for the IOC (`/dev/pts/X`) and the other for your simulator.

2. Run a Modbus slave simulator bound to the simulator PTY and configure registers according to the spec (especially 0x0023..0x0026 to verify fast updates).

3. Start the IOC after editing `ioc-modbus-device.cmd` to point to the IOC PTY and proper baud.

4. Verify PVs:
   - Use `caget`/`caput` to write `$(P):$(R):CURR_SET` and check `$(P):$(R):CURR_RB` and `OUTPUT_CURRENT_RB` update.
   - Measure update frequency for `OUTPUT_CURRENT_RB` to confirm >= 20 Hz.

Notes and next steps
--------------------
- This initial implementation assumes raw 16-bit register values (INT16) for analog values; add scaling or conversions if your device uses different units.
- If your device exposes commands as holding-register bits (rather than coils), adjust the DB to write to the holding register (write ports already included in the startup script).

If you'd like, I can:
- Add example simulation script (pymodbus server) to emulate the PS behavior, including auto-clearing command coils and providing ramp behavior.
- Add unit/integration test scripts for continuous verification of the 20 Hz requirement.
