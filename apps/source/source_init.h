/*****************************************************************
Copyright (C) Cambridge Silicon Radio Ltd. 2011-2014

PROJECT
    source
    
FILE NAME
    source_init.h

DESCRIPTION
    Initialisation of application.
    
*/


#ifndef _SOURCE_INIT_H_
#define _SOURCE_INIT_H_


/* VM headers */
#include <stdlib.h>


typedef enum
{
    REGISTERED_PROFILE_NONE,
    REGISTERED_PROFILE_CL,
    REGISTERED_PROFILE_CODEC,
    REGISTERED_PROFILE_A2DP,
    REGISTERED_PROFILE_AVRCP,
    REGISTERED_PROFILE_AGHFP    
} REGISTERED_PROFILE_T;


/***************************************************************************
Function definitions
****************************************************************************
*/


/****************************************************************************
NAME    
    init_register_profiles

DESCRIPTION
    Called when a profile has been initialised, to kick off the next initialisation step.
    
*/
void init_register_profiles(REGISTERED_PROFILE_T registered_profile);


/****************************************************************************
NAME    
    init_profile_memory

DESCRIPTION
    Initialise memory to hold profile data.
    
RETURNS
    TRUE - memory could be initialised
    FALSE - memory could not be initialised
    
*/
bool init_profile_memory(void);


#endif /* _SOURCE_INIT_H_ */
