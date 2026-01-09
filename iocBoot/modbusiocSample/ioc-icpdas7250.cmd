#!../../bin/linux-x86_64/modbustemplated

< envPaths

## Register all support components
dbLoadDatabase "../../dbd/icpdas.dbd"
modbustemplated_registerRecordDeviceDriver(pdbbase)

drvAsynIPPortConfigure("ICPDAS_IP", "192.168.104.49:502", 0, 0, 0)
modbusInterposeConfig("ICPDAS_IP",0,0,0)

drvModbusAsynConfigure("ICP_DI", "ICPDAS_IP", 1, 2, 0, 12,   0,1000, "ICPDAS7250")
drvModbusAsynConfigure("ICP_DICNT", "ICPDAS_IP", 1, 4, 16,24, 5,1000, "ICPDAS7250")
drvModbusAsynConfigure("ICP_DO", "ICPDAS_IP", 1, 5, 0, 6, 0, 1000, "ICPDAS7250")

drvModbusAsynConfigure ("ICP_info_port", "ICPDAS_IP", 1, 4, 150, 4, 0, 1000, "ICPDAS7250")



dbLoadRecords("$(TOP)/db/icp7250.db","P=ICPDAS,R=Test7250,DIPORT=ICP_DI,CNTPORT=ICP_DICNT,DOPORT=ICP_DO, PORTINFO=ICP_info_port")


iocInit()

