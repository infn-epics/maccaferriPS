#!../../bin/linux-x86_64/modbustemplated

< envPaths

## Register all support components
dbLoadDatabase "../../dbd/modbustemplated.dbd"
modbustemplated_registerRecordDeviceDriver(pdbbase)

drvAsynIPPortConfigure("ICPDAS_IP", "10.16.4.33:502", 0, 0, 0)
modbusInterposeConfig("ICPDAS_IP",0,0,0)

drvModbusAsynConfigure ("ICP_get_port", "ICPDAS_IP", 1, 1, 0,  6, 0, 1000, "ICPDAS7060")
drvModbusAsynConfigure ("ICP_set_port", "ICPDAS_IP", 1, 5, 0,  6, 0, 1000, "ICPDAS7060")

drvModbusAsynConfigure("ICP_DI", "ICPDAS_IP",    1, 2,  0, 6,   0,1000, "ICPDAS7060")
#drvModbusAsynConfigure("ICP_DISet", "ICPDAS_IP", 1, 5,  151, 6,   0,1000, "ICPDAS7060")
drvModbusAsynConfigure("ICP_DICNT", "ICPDAS_IP", 1, 4,  16,12, 5, 1000, "ICPDAS7060")



drvModbusAsynConfigure ("ICP_info_port", "ICPDAS_IP", 1, 4, 150, 4, 0, 1000, "ICPDAS")



dbLoadRecords("$(TOP)/db/icp7060.db","P=ICPDAS,R=Test7060,get_port=ICP_get_port,set_port=ICP_set_port, CNTPORT=ICP_DICNT,DIPORT=ICP_DI, PORT=ICP_info_port")


iocInit()

