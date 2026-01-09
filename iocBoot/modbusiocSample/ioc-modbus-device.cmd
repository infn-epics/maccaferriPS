#!../../bin/linux-x86_64/templatedmodbus
# https://epics-modbus.readthedocs.io/en/latest/overview.htm

< envPaths

## Register all support components
dbLoadDatabase "../../dbd/templatedmodbus.dbd"
templatedmodbus_registerRecordDeviceDriver(pdbbase)

# Configure Modbus TCP communication
# replace with the actual IP address and port of your Modbus device
drvAsynIPPortConfigure("MODBUS_IP", "192.168.1.100:502", 0, 0, 0)
modbusInterposeConfig("MODBUS_IP", 0, 0, 0)

# Define Modbus ports ASYN ports

## define ASYN MODBUS_AI port to access 10 Read Input Registers (0-9) 
drvModbusAsynConfigure("MODBUS_AI", "MODBUS_IP", 1, 4, 0, 10, 0, 1000, "GenericDevice")

## define ASYN MODBUS_AI2 port to access to read 3 Read Input Registers (0-2) from 350 to 352 
drvModbusAsynConfigure("MODBUS_AI2", "MODBUS_IP", 1, 4, 350, 3, 0, 10000, "ICPDAS7226")
# define ASYN MODBUS_AO to access 2  Single Register (0-1) from 0 to 2
drvModbusAsynConfigure("MODBUS_AO", "MODBUS_IP", 1, 6, 0, 2, 0, 1000, "GenericDevice")

## define ASYN MODBUS_DI read 8 to access  Discrete Inputs from 0 to 7
drvModbusAsynConfigure("MODBUS_DI", "MODBUS_IP", 1, 2, 0, 8, 0, 1000, "GenericDevice")

## define ASYN MODBUS_DO port to access 8 Single Coil              5
drvModbusAsynConfigure("MODBUS_DO", "MODBUS_IP", 1, 5, 0, 8, 0, 1000, "GenericDevice")

# Load database records ## ports name are already define in db
dbLoadRecords("$(TOP)/db/modbusDevice.db", "P=MODBUS,R=Device")

## Modbus Function Codes Documentation
# Access         Function Description           Function Code
# Bit access     Read Coils                     1
# Bit access     Read Discrete Inputs           2
# Bit access     Write Single Coil              5
# Bit access     Write Multiple Coils           15
# 16-bit word    Read Input Registers           4
# 16-bit word    Read Holding Registers         3
# 16-bit word    Write Single Register          6
# 16-bit word    Write Multiple Registers       16
# 16-bit word    Read/Write Multiple Registers  23

iocInit()