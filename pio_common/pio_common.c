/****************************************************************************
Copyright (C) Cambridge Silicon Radio Ltd. 2005

FILE NAME
    pio_common.c

DESCRIPTION
    Common PIO opperations used by libraries and applications

NOTES

*/


/****************************************************************************
    Header files
*/
#include <pio.h>
#include <print.h>
#include "pio_common.h"

/* Input/Pull are the same */
#define pio_input   pio_pull

/* PIO bounds checking macros */
#define PIN_MAX         (31)
#define PIN_IS_VALID(x) ((x <= PIN_MAX) && (x != PIN_INVALID))

#define PIO_NONE        (0UL)
#define PIO_MASK(x)     (PIN_IS_VALID(x) ? ((uint32)1 << x) : PIO_NONE)


/****************************************************************************
NAME
    pioCommonPreparePin
    
DESCRIPTION
    This function converts from a pin to a PIO pins
*/
static uint32 pioCommonGetMask(uint8 pin, pio_common_dir dir)
{
    uint32 pins = PIO_MASK(pin);
    if(PioSetDir32(pins, (dir ? pins : 0)) != PIO_NONE)
        return PIO_NONE;
    return pins;
}


/****************************************************************************
NAME
    PioCommonSetPin
    
DESCRIPTION
    This function will drive/pull a PIO to the specified level
*/
bool PioCommonSetPin(uint8 pin, pio_common_dir dir, bool level)
{
    uint32 pins = pioCommonGetMask(pin, dir);
    PRINT(("PIO: %s %d (0x%lX) ", (dir ? "Drive" : "Pull"), pin, pins));
    if((pins != PIO_NONE) && (PioSet32(pins, (level ? pins : 0)) == PIO_NONE))
    {
        PRINT(("%s\n", level ? "High" : "Low"));
        return TRUE;
    }
    PRINT(("Failed\n"));
    return FALSE;
}


/****************************************************************************
NAME
    PioCommonGetPin
    
DESCRIPTION
    This function will configure a pin as input and attempt to read it. This
    will return TRUE if the pin is high, FALSE if the pin is low or could
    not be configured.
*/
bool PioCommonGetPin(uint8 pin)
{
    uint32 pins = pioCommonGetMask(pin, pio_input);
    PRINT(("PIO: Get %d (0x%lX) ", pin, pins));
    pins &= PioGet32();
    PRINT(("%s\n", pins ? "High" : "Low"));
    return ((pins != PIO_NONE) ? TRUE : FALSE);
}


/****************************************************************************
NAME
    PioCommonGetPin
    
DESCRIPTION
    This function will configure a pins as inputs and attempt to debounce 
    them. If not successful on all pins this function will debounce all 
    possible PIOs and return FALSE, otherwise it will return TRUE.
*/
bool PioCommonDebounce(uint32 pins, uint16 count, uint16 period)
{
    uint32 result;
    
    PRINT(("PIO: Debounce 0x%lX\n", pins));
    PioSetDir32(pins, pio_input);
    result = PioDebounce32(pins, count, period);
    
    if(result != PIO_NONE)
    {
        PRINT(("PIO: Debounce retry 0x%lX\n", (pins & ~result)));
        PioDebounce32((pins & ~result), count, period);
        return FALSE;
    }
    return TRUE;
}
