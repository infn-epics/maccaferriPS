# Maccaferri Power Supply EPICS IOC

This EPICS IOC provides control and monitoring of Maccaferri Power Supplies through Modbus RTU/TCP communication. It features both low-level register access and a high-level UNIMAG interface with automatic polarity switching and current control sequencing.

## Architecture

The IOC consists of three main layers:

### 1. Low-Level Modbus Interface (`maccaferriPS_main.template`)
Direct access to power supply registers via Modbus protocol:
- **Commands**: Individual bit-level control (standby, power on, reset, etc.)
- **Setpoints**: Current reference, ramp rate, cycle patterns
- **Readbacks**: Status words, current/voltage measurements, fault diagnostics
- **Raw Access**: Direct register manipulation for debugging

### 2. High-Level UNIMAG Interface (`maccaferriPS_unimag.template`)
User-friendly interface with automatic control:
- **Signed Current Control**: Set current in Amperes (positive/negative)
- **Automatic Polarity Switching**: Seamlessly handles polarity changes
- **State Management**: Power on/off/standby/reset commands
- **Status Monitoring**: Overall state and interlock status

### 3. Control Logic (`maccaferriControl.st`)
State Notation Language (SNL) program that implements:
- **Polarity Management**: Automatic switching between positive/negative polarity
- **Current Ramping**: Controlled ramping to prevent damage
- **Fault Handling**: Safe shutdown on fault conditions
- **Sequencing**: Proper command ordering for safe operation

## PV Naming Convention

All PVs use the format: `$(P):NAME`

Where `$(P)` is the IOC prefix (e.g., `MACCA:`)

### UNIMAG Interface PVs

| PV Name | Type | Description |
|---------|------|-------------|
| `CURRENT_SP` | ao | Current setpoint (signed, A) |
| `CURRENT_RB` | calcout | Current readback (signed, A) |
| `STATE_SP` | mbbo | State control (OFF/STANDBY/ON/RESET) |
| `STATE_RB` | mbbi | Current state (STANDBY/ON/FAULT) |
| `STATE_DECODE` | calcout | State decoding calculation |
| `STATE_PROCESS` | seq | State change processing sequencer |
| `INTERLOCKED` | calc | Interlock status |

### Main Interface PVs

| PV Name | Type | Description |
|---------|------|-------------|
| `CMD_STANDBY` | bo | Standby command |
| `CMD_ON` | bo | Power on command |
| `CMD_RESET` | bo | Reset command |
| `CMD_START_RAMP` | bo | Start ramp command |
| `CMD_POLA_POSITIVE` | bo | Positive polarity command |
| `CMD_POLA_NEGATIVE` | bo | Negative polarity command |
| `CURR_SET` | ao | Current setpoint (absolute, A) |
| `CURR_RB` | ai | Current readback (absolute, A) |
| `VOLT_RB` | ai | Voltage readback (V) |
| `STAT_STANDBY` | bi | Standby status |
| `STAT_POWER_ON` | bi | Power on status |
| `STAT_FAULTY` | bi | Fault status |
| `STAT_POLA_POSITIVE` | bi | Positive polarity status |
| `STAT_POLA_NEGATIVE` | bi | Negative polarity status |

## State Machine Operation

The SNL program (`maccaferriControl.st`) implements a finite state machine that handles:

### Normal Operation Flow
1. **IDLE**: Waits for current setpoint changes
2. **CHECK_STATE**: Determines if polarity change is needed
3. **SET_CURRENT_DIRECT**: Direct current setting (no polarity change)
4. **RAMP_DIRECT**: Issues start ramp command

### Polarity Change Flow
1. **IDLE** → **CHECK_STATE** → **RAMP_TO_ZERO** (if current > threshold)
2. **GO_STANDBY** → **WAIT_STANDBY**
3. **CHANGE_POLARITY** → **WAIT_POLARITY**
4. **GO_POWERON** → **WAIT_POWERON**
5. **SET_CURRENT** → **IDLE**

### Key Features
- **Safe Sequencing**: Ensures proper command ordering
- **Timeout Protection**: Prevents hanging operations
- **Fault Detection**: Aborts operations on fault conditions
- **Reset Handling**: Allows cancellation of ongoing operations

## Configuration

### IOC Startup
The IOC is configured via `iocBoot/modbusiocSample/ioc-modbus-device.cmd`:

```bash
# Load database files
dbLoadTemplate("db/maccaferriPS_main.template", "P=MACCA:,PORT=PS_PORT")
dbLoadTemplate("db/maccaferriPS_unimag.template", "P=MACCA:")

# Start IOC
iocInit()
```

### Modbus Configuration
Configure the Modbus port in the startup script:
```bash
# RTU example
drvAsynSerialPortConfigure("PS_PORT", "/dev/ttyUSB0", 0, 0, 0)
asynSetOption("PS_PORT", 0, "baud", "9600")
asynSetOption("PS_PORT", 0, "parity", "none")
asynSetOption("PS_PORT", 0, "stop", "1")
asynSetOption("PS_PORT", 0, "data", "8")

# TCP example
drvAsynIPPortConfigure("PS_PORT", "192.168.1.100:502", 0, 0, 100)
```

## Usage Examples

### Basic Operation
```bash
# Power on the supply
caput MACCA:STATE_SP 1  # ON

# Set current to 50A
caput MACCA:CURRENT_SP 50

# Check current readback
caget MACCA:CURRENT_RB

# Power off
caput MACCA:STATE_SP 0  # OFF
```

### Polarity Switching
```bash
# Set negative current (automatic polarity switch)
caput MACCA:CURRENT_SP -25

# The state machine will:
# 1. Ramp current to zero
# 2. Go to standby
# 3. Switch to negative polarity
# 4. Power back on
# 5. Ramp to -25A
```

### Direct Register Access
```bash
# Set current directly (absolute value)
caput MACCA:CURR_SET 100

# Start ramp
caput MACCA:CMD_START_RAMP 1

# Check status
caget MACCA:STAT_POWER_ON
caget MACCA:STAT_POLA_POSITIVE
```

## Safety Features

- **Interlock Monitoring**: Fault conditions prevent operation
- **Timeout Protection**: Operations abort if they take too long
- **Safe Sequencing**: Commands issued in proper order
- **Current Limiting**: Setpoint limits prevent damage
- **Polarity Verification**: Confirms polarity before applying current

## Troubleshooting

### Common Issues

1. **Communication Errors**
   - Check Modbus configuration
   - Verify cable connections
   - Check power supply Modbus settings

2. **Timeout Errors**
   - Increase timeout values in templates
   - Check power supply response time
   - Verify command sequencing

3. **Polarity Switching Failures**
   - Check contactor status
   - Verify power supply polarity commands
   - Check for interlocks

### Debug Mode
Enable debug output by setting:
```bash
# In startup script
asynSetTraceMask("PS_PORT", 0, 0x9)
asynSetTraceIOMask("PS_PORT", 0, 0x2)
```

## File Structure

```
maccaferriPS/
├── configure/           # EPICS build configuration
├── templatedmodbusApp/
│   ├── Db/             # Database templates
│   │   ├── maccaferriPS_main.template    # Low-level interface
│   │   └── maccaferriPS_unimag.template  # High-level interface
│   └── src/
│       ├── maccaferriControl.st          # State machine logic
│       └── maccaferriPSMain.cpp          # IOC main
├── iocBoot/            # IOC startup scripts
├── db/                 # Installed databases
├── bin/                # Built executables
└── lib/                # Built libraries
```

## Dependencies

- EPICS Base
- asyn module
- modbus module
- sequencer module (for SNL)

## Building

```bash
# From IOC-DEVEL directory
cd maccaferriPS
make
```

## References

- EPICS Documentation: https://epics-controls.org/
- Modbus Protocol: https://modbus.org/
- State Notation Language: https://www-csr.bessy.de/control/SoftComp/sequencer/

---

## Getting Started

1. Clone this repository:
   ```bash
   git clone https://github.com/yourusername/modbus-template.git
   cd modbus-template