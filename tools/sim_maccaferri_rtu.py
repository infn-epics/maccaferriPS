#!/usr/bin/env python3
"""
Simple Modbus RTU slave simulator for maccaferriPS registers.

Usage:
  python3 sim_maccaferri_rtu.py --port /dev/pts/X --baud 19200

This is a minimal helper for local testing with socat-created PTYs.
It does not fully implement all spec behaviors, but:
 - exposes Holding Registers (0x0000..0x003F)
 - exposes Input Registers (0x0020..0x003F) and updates registers 0x0023..0x0026 (CURRENT REF, IOUT, VOUT, GND)
 - reacts to writes on holding registers 0x0000 (commands) and 0x0001 (current set)
 - when StartRamp command is set, it ramps IOUT toward the setpoint
"""

import argparse
import logging
import threading
import time

try:
    from pymodbus.server.sync import StartSerialServer
    from pymodbus.datastore import ModbusSlaveContext, ModbusServerContext
    from pymodbus.datastore import ModbusSequentialDataBlock
    from pymodbus.transaction import ModbusRtuFramer
except Exception as e:
    raise RuntimeError("pymodbus is required for the simulator. Install with 'pip install pymodbus' (py3).")

logging.basicConfig()
log = logging.getLogger()
log.setLevel(logging.INFO)

# Register addresses
HOLDING_LEN = 0x40  # 64 words
INPUT_LEN = 0x40

# Register indices (decimal)
CMD_REG = 0       # 0x0000
CURR_SET_REG = 1  # 0x0001

# Readback / input addresses (as per spec)
RB_START = 0x0023  # decimal 35 -> input reg offset 35
RB_CURRREF = 35    # 0x0023
RB_IOUT = 36       # 0x0024
RB_VOUT = 37       # 0x0025
RB_GND = 38        # 0x0026

class MaccaferriSim:
    def __init__(self):
        # Datastores - initialize with zeros
        hr = [0] * HOLDING_LEN
        ir = [0] * INPUT_LEN
        self.store = ModbusSlaveContext(
            hr=ModbusSequentialDataBlock(0, hr),
            ir=ModbusSequentialDataBlock(0, ir),
            co=ModbusSequentialDataBlock(0, [0] * 256),
            di=ModbusSequentialDataBlock(0, [0] * 256),
        )
        self.context = ModbusServerContext(slaves=self.store, single=True)
        self._stop = threading.Event()
        # Simulation state
        self.iout = 0
        self.curr_ref = 0
        self.mode_pulsed = False
        self.state_on = False
        self.ramp_active = False
        self.ramp_lock = threading.Lock()

    def _read_holding(self, addr, count=1):
        return self.store.getValues(3, addr, count)

    def _write_holding(self, addr, values):
        return self.store.setValues(3, addr, values)

    def _set_input(self, addr, values):
        return self.store.setValues(4, addr, values)

    def _get_input(self, addr, count=1):
        return self.store.getValues(4, addr, count)

    def ramp_thread(self):
        # Very simple ramp: approach curr_ref by +- delta each tick, tick every 40ms
        delta = 1  # units per tick
        period = 0.04
        while not self._stop.is_set():
            with self.ramp_lock:
                target = self.curr_ref
                if self.ramp_active and self.state_on:
                    if self.iout < target:
                        self.iout += delta
                        if self.iout > target:
                            self.iout = target
                    elif self.iout > target:
                        self.iout -= delta
                        if self.iout < target:
                            self.iout = target
                else:
                    # if not in ramp_active or not on, slowly decay to 0
                    if self.iout > 0:
                        self.iout = max(0, self.iout - delta)
            # update input registers (simulate ADCs)
            # CurrRef readback in input reg 0x0023
            self.store.setValues(4, RB_CURRREF, [int(self.curr_ref)])
            self.store.setValues(4, RB_IOUT, [int(self.iout)])
            # Vout and GND set to simple functions
            self.store.setValues(4, RB_VOUT, [int(self.iout * 2)])
            self.store.setValues(4, RB_GND, [0])

            time.sleep(period)

    def monitor_thread(self):
        # Poll holding registers for commands and current set changes
        prev_cmd = 0
        prev_curr_set = 0
        while not self._stop.is_set():
            hr_cmd = self._read_holding(CMD_REG, 1)[0]
            hr_cur = self._read_holding(CURR_SET_REG, 1)[0]
            if hr_cur != prev_curr_set:
                prev_curr_set = hr_cur
                self.curr_ref = hr_cur
                log.info(f"Curr set updated -> {self.curr_ref}")
            if hr_cmd != prev_cmd:
                log.info(f"Command register changed: {hr_cmd}")
                # If StartRamp bit (4) set -> start ramp
                if hr_cmd & (1 << 4):
                    self.ramp_active = True
                    log.info("StartRamp detected -> ramp_active=True")
                # Standby (bit 0) request -> ramp to 0
                if hr_cmd & (1 << 0):
                    # ramp to 0 and set state_on false when reached
                    self.curr_ref = 0
                    self.ramp_active = True
                    log.info("Standby requested -> set curr_ref=0 and start ramp")
                # On (bit 1)
                if hr_cmd & (1 << 1):
                    self.state_on = True
                    log.info("On command -> state_on=True")
                # Off (bit 2)
                if hr_cmd & (1 << 2):
                    self.state_on = False
                    self.curr_ref = 0
                    self.ramp_active = False
                    self.iout = 0
                    log.info("Off command -> state_on=False, outputs off")
                # Reset (bit 3) - clear fault bits (not implemented here)
                # Mode selection bits (5/6), polarity bits (7/8)
                prev_cmd = hr_cmd
            time.sleep(0.05)

    def start(self, serial_port, baud=19200):
        t1 = threading.Thread(target=self.ramp_thread, daemon=True)
        t2 = threading.Thread(target=self.monitor_thread, daemon=True)
        t1.start()
        t2.start()

        log.info(f"Starting Modbus RTU server on {serial_port} @ {baud}")
        StartSerialServer(context=self.context, framer=ModbusRtuFramer, port=serial_port, timeout=1, baudrate=baud)

    def stop(self):
        self._stop.set()

if __name__ == '__main__':
    parser = argparse.ArgumentParser()
    parser.add_argument('--port', required=True, help='Serial device path for the server (e.g., /dev/pts/4)')
    parser.add_argument('--baud', type=int, default=19200)
    args = parser.parse_args()

    sim = MaccaferriSim()
    try:
        sim.start(args.port, args.baud)
    except KeyboardInterrupt:
        sim.stop()
        log.info('Simulator stopped')
