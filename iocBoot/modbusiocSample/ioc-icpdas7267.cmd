#!../../bin/linux-x86_64/modbustemplated

< envPaths

## Register all support components
dbLoadDatabase "../../dbd/modbustemplated.dbd"
modbustemplated_registerRecordDeviceDriver(pdbbase)

#drvAsynIPPortConfigure ("MOXA1","192.168.190.55:4002",0,0,0)
drvAsynIPPortConfigure("ICPDAS_IP", "192.168.104.63:502", 0, 0, 0)
modbusInterposeConfig("ICPDAS_IP",0,0,0)

drvModbusAsynConfigure ("ICP_get_port", "ICPDAS_IP", 1, 1, 0,  8, 0, 1000, "ICPDAS")
drvModbusAsynConfigure ("ICP_set_port", "ICPDAS_IP", 1, 5, 0,  8, 0, 1000, "ICPDAS")
drvModbusAsynConfigure ("ICP_info_port", "ICPDAS_IP", 1, 4, 350, 4, 0, 1000, "ICPDAS")



dbLoadRecords("$(TOP)/db/icp7267.db","P=ICPDAS,R=Test7267,get_port=ICP_get_port,set_port=ICP_set_port,  PORT=ICP_info_port")

#dbLoadRecords("$(TOP)/db/agilentXgs600Img.template","device=LEL-VAC-GAUG10:CC, port=MOXA1, sensor=I1,tcauto=T3")


iocInit()

