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
GENVERSION = maccaferriPSVersion.h
# Macro name
GENVERSIONMACRO = maccaferriPSVERSION

# Build the IOC application
PROD_IOC = maccaferriPS

# maccaferriPS.dbd will be created and installed
DBD += maccaferriPS.dbd

# maccaferriPS.dbd will include these files:
maccaferriPS_DBD += base.dbd
maccaferriPS_DBD += modbusSupport.dbd
maccaferriPS_DBD += asyn.dbd
maccaferriPS_DBD += drvAsynIPPort.dbd
maccaferriPS_DBD += drvAsynSerialPort.dbd
maccaferriPS_SRCS += maccaferriPS_registerRecordDeviceDriver.cpp

# Build the main IOC entry point where needed
maccaferriPS_SRCS_DEFAULT += maccaferriPSMain.cpp
maccaferriPS_SRCS_vxWorks += -nil-

# Link in the code from our support library
maccaferriPS_LIBS += asyn
maccaferriPS_LIBS += modbus
# To build SNL programs, SNCSEQ must be defined
# in the <top>/configure/RELEASE file

# Link QSRV (pvAccess Server) if available
ifdef EPICS_QSRV_MAJOR_VERSION
    maccaferriPS_LIBS += qsrv
    maccaferriPS_LIBS += $(EPICS_BASE_PVA_CORE_LIBS)
    maccaferriPS_DBD += PVAServerRegister.dbd
    maccaferriPS_DBD += qsrv.dbd
endif

# Finally link IOC to the EPICS Base libraries
maccaferriPS_LIBS += $(EPICS_BASE_IOC_LIBS)

include $(TOP)/configure/RULES
#----------------------------------------
#  ADD EXTRA GNUMAKE RULES BELOW HERE

# Explicit dependency needed for generated header file
devmaccaferriPSVersion$(DEP): $(COMMON_DIR)/$(GENVERSION)
