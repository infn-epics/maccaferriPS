/* maccaferriFrame.c - pack the Maccaferri command area into one frame
 *
 * The PS overwrites the whole command area on every write, so the command
 * word (0x0000) and the current reference (0x0001) must always be written
 * together in a single FC16 frame.
 *
 * aSub inputs:  A command word (LONG), B current reference raw (LONG)
 * aSub output:  VALA LONG[2] = { A, B }
 */
#include <aSubRecord.h>
#include <registryFunction.h>
#include <epicsExport.h>
#include <epicsTypes.h>

static long maccaferriFrame(aSubRecord *prec)
{
    epicsInt32 *out = (epicsInt32 *)prec->vala;

    out[0] = *(epicsInt32 *)prec->a & 0xFFFF;
    out[1] = *(epicsInt32 *)prec->b & 0xFFFF;
    prec->neva = 2;
    return 0;
}

epicsRegisterFunction(maccaferriFrame);
