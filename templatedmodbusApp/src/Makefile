TOP=../..

include $(TOP)/configure/CONFIG
#----------------------------------------
#  ADD MACRO DEFINITIONS BELOW HERE

# Use typed rset structure (see 3.16.1 release notes)
USR_CPPFLAGS += -DUSE_TYPED_RSET

# Build an IOC support library
# LIBRARY_IOC += templatedmodbusSupport

# Link locally-provided code into the support library,
# rather than directly into the IOC application, that
# causes problems on Windows DLL builds
#templatedmodbusSupport_SRCS += dbSubExample.c
#templatedmodbusSupport_SRCS += devtemplatedmodbusVersion.c
#templatedmodbusSupport_SRCS += templatedmodbusHello.c
#templatedmodbusSupport_SRCS += initTrace.c

templatedmodbusSupport_LIBS += $(EPICS_BASE_IOC_LIBS)

# Auto-generate a header file containing a version string.
# Version comes from the VCS if available, else date+time.
GENVERSION = templatedmodbusVersion.h
# Macro name
GENVERSIONMACRO = templatedmodbusVERSION

# Build the IOC application
PROD_IOC = templatedmodbus

# templatedmodbus.dbd will be created and installed
DBD += templatedmodbus.dbd

# templatedmodbus.dbd will include these files:
templatedmodbus_DBD += base.dbd
templatedmodbus_DBD += modbusSupport.dbd
templatedmodbus_DBD += asyn.dbd
templatedmodbus_DBD += drvAsynIPPort.dbd
templatedmodbus_SRCS += templatedmodbus_registerRecordDeviceDriver.cpp

# Build the main IOC entry point where needed
templatedmodbus_SRCS_DEFAULT += templatedmodbusMain.cpp
templatedmodbus_SRCS_vxWorks += -nil-

# Link in the code from our support library
templatedmodbus_LIBS += asyn
templatedmodbus_LIBS += modbus
# To build SNL programs, SNCSEQ must be defined
# in the <top>/configure/RELEASE file

# Link QSRV (pvAccess Server) if available
ifdef EPICS_QSRV_MAJOR_VERSION
    templatedmodbus_LIBS += qsrv
    templatedmodbus_LIBS += $(EPICS_BASE_PVA_CORE_LIBS)
    templatedmodbus_DBD += PVAServerRegister.dbd
    templatedmodbus_DBD += qsrv.dbd
endif

# Finally link IOC to the EPICS Base libraries
templatedmodbus_LIBS += $(EPICS_BASE_IOC_LIBS)

include $(TOP)/configure/RULES
#----------------------------------------
#  ADD EXTRA GNUMAKE RULES BELOW HERE

# Explicit dependency needed for generated header file
devtemplatedmodbusVersion$(DEP): $(COMMON_DIR)/$(GENVERSION)
