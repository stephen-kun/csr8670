/*************************************************************************
 Copyright (C) Cambridge Silicon Radio Ltd. 2005-2014
 Part of ADK 3.5

FILE : 
    pio_common.h

CONTAINS:
    Common PIO opperations used by libraries and applications

**************************************************************************/

#ifndef PIO_COMMON_H_
#define PIO_COMMON_H_

#define PIN_INVALID 0xFF

/*!
    @brief Define the types for the upstream messages sent from the Power
    library to the application.
*/
typedef enum
{
    pio_pull, 
    pio_drive
} pio_common_dir;


/****************************************************************************
NAME
    PioCommonSetPin
    
DESCRIPTION
    This function will drive/pull a PIO to the specified level
    
RETURNS
    TRUE if successful, FALSE otherwise
*/
bool PioCommonSetPin(uint8 pin, pio_common_dir dir, bool level);


/****************************************************************************
NAME
    PioCommonGetPin
    
DESCRIPTION
    This function will configure a pin as input and attempt to read it. This
    will return TRUE if the pin is high, FALSE if the pin is low or could
    not be configured.
*/
bool PioCommonGetPin(uint8 pin);


/****************************************************************************
NAME
    PioCommonGetPin
    
DESCRIPTION
    This function will configure a pin as input and attempt to debounce it. 
    This will return TRUE if successful, FALSE otherwise.
*/
bool PioCommonDebounce(uint32 pins, uint16 count, uint16 period);


#endif /*PIO_COMMON_H_*/
