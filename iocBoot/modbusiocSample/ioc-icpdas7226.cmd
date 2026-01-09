#!../../bin/linux-x86_64/modbustemplated

< envPaths

## Register all support components
dbLoadDatabase "../../dbd/modbustemplated.dbd"
modbustemplated_registerRecordDeviceDriver(pdbbase)

drvAsynIPPortConfigure("ICPDAS001_ASYN", "ddsparcicphv001.lnf.infn.it:502", 0, 0, 0)
modbusInterposeConfig("ICPDAS001_ASYN",0,2000,0)
# https://www.icpdas.com/web/product/download/io_and_unit/ethernet/et7000_et7200/document/manual/pet_et7x00_register_table.pdf
drvModbusAsynConfigure("ICPDAS001_AI", "ICPDAS001_ASYN", 1,    4, 0, 6, 0, 1000, "ICPDAS7226")
drvModbusAsynConfigure("ICPDAS001_DICNT", "ICPDAS001_ASYN", 1, 4, 32, 4, 0, 1000, "ICPDAS7226")
drvModbusAsynConfigure("ICPDAS001_AIMAX", "ICPDAS001_ASYN", 1, 4, 236, 6, 0, 1000, "ICPDAS7226")
drvModbusAsynConfigure("ICPDAS001_AIMIN", "ICPDAS001_ASYN", 1, 4, 268, 6, 0, 1000, "ICPDAS7226")
## 2 write holding registers
drvModbusAsynConfigure("ICPDAS001_WAO", "ICPDAS001_ASYN", 1,    6, 0, 2, 0, 1000, "ICPDAS7226")
## 2 read holding registers
drvModbusAsynConfigure("ICPDAS001_RAO", "ICPDAS001_ASYN", 1,    3, 0, 2, 0, 1000, "ICPDAS7226")

## 2 coil registers
drvModbusAsynConfigure("ICPDAS001_DO", "ICPDAS001_ASYN", 1,    5, 0, 2, 0, 1000, "ICPDAS7226")
## 2 discrete input registers
drvModbusAsynConfigure("ICPDAS001_DI", "ICPDAS001_ASYN", 1,    2, 0, 2, 0, 1000, "ICPDAS7226")
#read once or epics events
drvModbusAsynConfigure("ICPDAS001_INFO", "ICPDAS001_ASYN", 1, 4, 350, 3, 0, 10000, "ICPDAS7226")

dbLoadRecords("$(TOP)/db/icp7226.db","P=SPARC:HV,R=ICP,AIPORT=ICPDAS001_AI,PORTMIN=ICPDAS001_AIMIN,PORTMAX=ICPDAS001_AIMAX,  WAOPORT=ICPDAS001_WAO,RAOPORT=ICPDAS001_RAO,DIPORT=ICPDAS001_DI,CNTPORT=ICPDAS001_DICNT,DOPORT=ICPDAS001_DO,PORTINFO=ICPDAS001_INFO")



iocInit()

