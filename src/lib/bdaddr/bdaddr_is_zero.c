/* Copyright (C) Cambridge Silicon Radio Limited 2005-2014 */
/* Part of ADK 3.5 */

#include <bdaddr.h>

bool BdaddrIsZero(const bdaddr *in)
{ 
    return !in->nap && !in->uap && !in->lap; 
}
