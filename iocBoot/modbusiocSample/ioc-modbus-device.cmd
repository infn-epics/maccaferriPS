#!../../bin/linux-x86_64/maccaferriPS
# https://epics-modbus.readthedocs.io/en/latest/overview.htm

< envPaths

## Register all support components
# Use the maccaferriPS DBD and register the driver
dbLoadDatabase "../../dbd/maccaferriPS.dbd"
maccaferriPS_registerRecordDeviceDriver(pdbbase)

# -------- Modbus TCP Configuration --------
# Configure an Asyn IP port for the Modbus TCP gateway
# Adjust the IP address and port as needed for your Modbus TCP gateway
drvAsynIPPortConfigure("MACCF_ASYN", "127.0.0.1:502", 0, 0, 1)

# Configure Modbus interposer for RTU over TCP (linkType = 1)
# modbusInterposeConfig(portName, linkType, timeoutMsec, writeDelayMsec)
modbusInterposeConfig("MACCF_ASYN", 1, 2000, 10)

# -------- Define Modbus ports (slave id = 1 by default) --------
# Read Holding Registers for COMMAND AREA (0x0000..0x0001)
drvModbusAsynConfigure("MACCF_CMD_RO", "MACCF_ASYN", 1, 3, 0, 2, 0, 1000, "MACCAFERRIPS")
# Write Holding Registers for COMMAND AREA (on demand writes)
drvModbusAsynConfigure("MACCF_CMD_WO", "MACCF_ASYN", 1, 16, 0, 2, 0, 0, "MACCAFERRIPS")

# FAST readback for Current/Voltage/Reference (holding registers 0x0023..0x0026)
# start address 35 (0x0023), count 4, poll every 40 ms to meet >=20 Hz requirement
drvModbusAsynConfigure("MACCF_FAST_AI", "MACCF_ASYN", 1, 3, 35, 4, 0, 40, "MACCAFERRIPS")

# SLOW readback for Faults/States (holding registers 0x0020..0x0022)
# start address 32 (0x0020), count 3, poll at 1000 ms
drvModbusAsynConfigure("MACCF_SLOW_AI", "MACCF_ASYN", 1, 3, 32, 3, 0, 1000, "MACCAFERRIPS")

# Load DB records: pass port substitution names and common parameters
# Usage: P=prefix, R=DeviceName, PORTFAST, PORTSLOW, PORTCMD_WO, TIMEOUT
# Main template (commands, states, readbacks)
dbLoadRecords("$(TOP)/db/maccaferriPS_main.template", "P=MACCF,R=PS01,PORT_CMD_RO=MACCF_CMD_RO,PORT_CMD_WO=MACCF_CMD_WO,PORTFAST=MACCF_FAST_AI,PORTSLOW=MACCF_SLOW_AI,TIMEOUT=2000")

# UNIMAG interface template (signed current control with auto polarity)
dbLoadRecords("$(TOP)/db/maccaferriPS_unimag.template", "P=MACCF,R=PS01")

# Initialize IOC
iocInit()

## Modbus Function Codes Documentation
# This Maccaferri Power Supply uses only function codes 3 and 16
#
# Access         Function Description           Function Code  Used
# Bit access     Read Coils                     1
# Bit access     Read Discrete Inputs           2
# Bit access     Write Single Coil              5
# Bit access     Write Multiple Coils           15
# 16-bit word    Read Input Registers           4
# 16-bit word    Read Holding Registers         3             ✓
# 16-bit word    Write Single Register          6
# 16-bit word    Write Multiple Registers       16            ✓
# 16-bit word    Read/Write Multiple Registers  23