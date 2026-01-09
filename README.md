## Overview

This project is a generic EPICS template for controlling Modbus devices. It includes:
- **Database Templates:** Define EPICS records for various Modbus devices.
- **Substitution Files:** Provide device-specific configurations for the templates.
- **Source Code:** Implements the IOC logic and initialization.
- **Startup Scripts:** Configure and start the IOC.

For detailed Modbus documentation, refer to the [EPICS Modbus Documentation](https://epics-modbus.readthedocs.io/en/latest/).

---

## Features

- Support for Modbus TCP communication.
- Predefined templates for analog inputs/outputs, digital inputs/outputs, and relays.
- Easily customizable for any Modbus device.
- Includes example startup scripts and substitution files.

---

## Database Files

This repository now focuses on the `maccaferriPS` IOC implementation.

- **`maccaferriPS.db`**: Database implementing the Modbus register mapping and EPICS PVs for the maccaferriPS power supply (commands, current setpoint, fast readbacks, faults and states).

For configuration details, example startup scripts and a small simulator for testing, see `templatedmodbusApp/README.maccaferriPS.md` and `tools/sim_maccaferri_rtu.py`.

---

## Source Code

### `initTrace.c`
Implements tracing and debugging utilities for the IOC.

---

## Startup Script

See `iocBoot/modbusiocSample/ioc-modbus-device.cmd` for an example configuration that sets up a serial Modbus RTU connection and the required ports for the `maccaferriPS` database.

---

## Prerequisites

1. **EPICS Base:** Ensure EPICS Base is installed and configured.
2. **AsynDriver:** Install the EPICS AsynDriver module.
3. **Modbus Support:** Install the EPICS Modbus support module.

---

## Getting Started

1. Clone this repository:
   ```bash
   git clone https://github.com/yourusername/modbus-template.git
   cd modbus-template