program maccaferriControl

/*
 * EPICS State Notation Language program for Maccaferri Power Supply
 * Handles automatic polarity switching and current control sequencing
 * Adapted from unimagControl for Maccaferri-specific register/command mapping
 */

option +r;  /* Make reentrant */

/* C declarations */
%% #include <math.h>

/* PV declarations */
double current_sp;
assign current_sp to "{P}:{R}:CURRENT_SP";
monitor current_sp;

double current_rb;
assign current_rb to "{P}:{R}:CURRENT_RB";
monitor current_rb;

double curr_set;
assign curr_set to "{P}:{R}:CURR_SET";

int stat_pola_positive;
assign stat_pola_positive to "{P}:{R}:STAT_POLA_POSITIVE";
monitor stat_pola_positive;

int stat_pola_negative;
assign stat_pola_negative to "{P}:{R}:STAT_POLA_NEGATIVE";
monitor stat_pola_negative;

int stat_standby;
assign stat_standby to "{P}:{R}:STAT_STANDBY";
monitor stat_standby;

int stat_power_on;
assign stat_power_on to "{P}:{R}:STAT_POWER_ON";
monitor stat_power_on;

int stat_faulty;
assign stat_faulty to "{P}:{R}:STAT_FAULTY";
monitor stat_faulty;

int cmd_standby;
assign cmd_standby to "{P}:{R}:CMD_STANDBY";

int cmd_on;
assign cmd_on to "{P}:{R}:CMD_ON";

int cmd_start_ramp;
assign cmd_start_ramp to "{P}:{R}:CMD_START_RAMP";

int cmd_pola_positive;
assign cmd_pola_positive to "{P}:{R}:CMD_POLA_POSITIVE";

int cmd_pola_negative;
assign cmd_pola_negative to "{P}:{R}:CMD_POLA_NEGATIVE";

int cmd_reset;
assign cmd_reset to "{P}:{R}:CMD_RESET";
monitor cmd_reset;

/* Event flags */
evflag current_sp_ef;
sync current_sp current_sp_ef;

evflag cmd_reset_ef;
sync cmd_reset cmd_reset_ef;

/* State variables */
int requested_polarity;      /* 1=positive, 2=negative */
double requested_current;
double abs_current;
int polarity_change_needed;
int timeout_counter;

/* Constants */
#define CURRENT_THRESHOLD 2.0
#define TIMEOUT_TICKS 60      /* 30 seconds with 0.5s delay */
#define POL_POSITIVE 1
#define POL_NEGATIVE 2

ss maccaferri_control {
    state IDLE {
        when (efTestAndClear(current_sp_ef)) {
            /* New current setpoint received */
            requested_current = current_sp;
            abs_current = fabs(requested_current);
            
            /* Determine requested polarity */
            if (requested_current >= 0) {
                requested_polarity = POL_POSITIVE;
            } else {
                requested_polarity = POL_NEGATIVE;
            }
            
            /* Check if polarity change is needed */
            pvGet(stat_pola_positive);
            pvGet(stat_pola_negative);
            
            if ((requested_polarity == POL_POSITIVE && !stat_pola_positive) ||
                (requested_polarity == POL_NEGATIVE && !stat_pola_negative)) {
                polarity_change_needed = 1;
                timeout_counter = 0;
            } else {
                polarity_change_needed = 0;
            }
        } state CHECK_STATE
        
        when (efTestAndClear(cmd_reset_ef)) {
            /* Reset command cancels all operations */
            polarity_change_needed = 0;
            timeout_counter = 0;
        } state IDLE
    }
    
    state CHECK_STATE {
        entry {
            /* Get current status */
            pvGet(stat_power_on);
            pvGet(current_rb);
            pvGet(stat_faulty);
        }
        
        when (stat_faulty) {
            /* Fault detected - abort operation */
            polarity_change_needed = 0;
        } state IDLE
        
        when (!polarity_change_needed) {
            /* No polarity change needed, just set current directly */
        } state SET_CURRENT_DIRECT
        
        when (polarity_change_needed && stat_power_on && fabs(current_rb) > CURRENT_THRESHOLD) {
            /* Need to ramp to zero first */
        } state RAMP_TO_ZERO
        
        when (polarity_change_needed && stat_power_on && fabs(current_rb) <= CURRENT_THRESHOLD) {
            /* Can go directly to standby */
        } state GO_STANDBY
        
        when (polarity_change_needed && !stat_power_on) {
            /* Already in standby or off, can change polarity */
        } state CHANGE_POLARITY
    }
    
    state RAMP_TO_ZERO {
        entry {
            /* Set current to zero and start ramp */
            curr_set = 0.0;
            pvPut(curr_set);
            cmd_start_ramp = 1;
            pvPut(cmd_start_ramp);
            timeout_counter = 0;
        }
        
        when (fabs(current_rb) < CURRENT_THRESHOLD) {
            /* Current reached zero */
        } state GO_STANDBY
        
        when (timeout_counter++ >= TIMEOUT_TICKS) {
            /* Timeout - cancel operation */
            polarity_change_needed = 0;
            printf("maccaferriControl: Timeout waiting for zero current\n");
        } state IDLE
        
        when (efTestAndClear(cmd_reset_ef)) {
            polarity_change_needed = 0;
        } state IDLE
        
        when (delay(0.5)) {
            /* Keep checking */
        } state RAMP_TO_ZERO
    }
    
    state GO_STANDBY {
        entry {
            cmd_standby = 1;
            pvPut(cmd_standby);
            timeout_counter = 0;
        }
        
        when (delay(0.5)) {
        } state WAIT_STANDBY
    }
    
    state WAIT_STANDBY {
        when (stat_standby) {
            /* Standby confirmed */
        } state CHANGE_POLARITY
        
        when (timeout_counter++ >= TIMEOUT_TICKS) {
            /* Timeout - cancel operation */
            polarity_change_needed = 0;
            printf("maccaferriControl: Timeout waiting for standby\n");
        } state IDLE
        
        when (efTestAndClear(cmd_reset_ef)) {
            polarity_change_needed = 0;
        } state IDLE
        
        when (delay(0.5)) {
            /* Keep checking */
        } state WAIT_STANDBY
    }
    
    state CHANGE_POLARITY {
        entry {
            /* Issue polarity change command */
            if (requested_polarity == POL_POSITIVE) {
                cmd_pola_positive = 1;
                pvPut(cmd_pola_positive);
            } else {
                cmd_pola_negative = 1;
                pvPut(cmd_pola_negative);
            }
            timeout_counter = 0;
        }
        
        when (delay(1.0)) {
        } state WAIT_POLARITY
    }
    
    state WAIT_POLARITY {
        entry {
            pvGet(stat_pola_positive);
            pvGet(stat_pola_negative);
        }
        
        when ((requested_polarity == POL_POSITIVE && stat_pola_positive) ||
              (requested_polarity == POL_NEGATIVE && stat_pola_negative)) {
            /* Polarity confirmed */
            polarity_change_needed = 0;
        } state GO_POWERON
        
        when (timeout_counter++ >= TIMEOUT_TICKS) {
            /* Timeout - cancel operation */
            polarity_change_needed = 0;
            printf("maccaferriControl: Timeout waiting for polarity change\n");
        } state IDLE
        
        when (efTestAndClear(cmd_reset_ef)) {
            polarity_change_needed = 0;
        } state IDLE
        
        when (delay(0.5)) {
            /* Keep checking */
            pvGet(stat_pola_positive);
            pvGet(stat_pola_negative);
        } state WAIT_POLARITY
    }
    
    state GO_POWERON {
        entry {
            cmd_on = 1;
            pvPut(cmd_on);
            timeout_counter = 0;
        }
        
        when (delay(0.5)) {
        } state WAIT_POWERON
    }
    
    state WAIT_POWERON {
        when (stat_power_on) {
            /* Power on confirmed */
        } state SET_CURRENT
        
        when (timeout_counter++ >= TIMEOUT_TICKS) {
            /* Timeout - cancel operation */
            printf("maccaferriControl: Timeout waiting for power on\n");
        } state IDLE
        
        when (efTestAndClear(cmd_reset_ef)) {
        } state IDLE
        
        when (delay(0.5)) {
            /* Keep checking */
        } state WAIT_POWERON
    }
    
    state SET_CURRENT {
        entry {
            /* Set the absolute current value */
            curr_set = abs_current;
            pvPut(curr_set);
        }
        
        when (delay(0.5)) {
        } state START_RAMP
    }
    
    state START_RAMP {
        entry {
            cmd_start_ramp = 1;
            pvPut(cmd_start_ramp);
        }
        
        when (delay(0.2)) {
        } state IDLE
    }
    
    state SET_CURRENT_DIRECT {
        entry {
            /* No polarity change needed, check if we need to power on */
            pvGet(stat_power_on);
        }
        
        when (!stat_power_on) {
            /* Need to power on first */
            cmd_on = 1;
            pvPut(cmd_on);
        } state WAIT_POWERON_DIRECT
        
        when (stat_power_on) {
            /* Already powered on */
            curr_set = abs_current;
            pvPut(curr_set);
        } state RAMP_DIRECT
    }
    
    state WAIT_POWERON_DIRECT {
        when (stat_power_on) {
            curr_set = abs_current;
            pvPut(curr_set);
        } state RAMP_DIRECT
        
        when (delay(0.5)) {
            /* Keep checking */
        } state WAIT_POWERON_DIRECT
    }
    
    state RAMP_DIRECT {
        when (delay(0.5)) {
            cmd_start_ramp = 1;
            pvPut(cmd_start_ramp);
        } state IDLE_DIRECT
    }
    
    state IDLE_DIRECT {
        when (delay(0.2)) {
        } state IDLE
    }
}
