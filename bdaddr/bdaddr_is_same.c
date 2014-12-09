/* Copyright (C) Cambridge Silicon Radio Limited 2005-2014 */
/* Part of ADK 3.5 */

#include <bdaddr.h>

bool BdaddrIsSame(const bdaddr *first, const bdaddr *second)
{ 
    return  first->nap == second->nap && 
            first->uap == second->uap && 
            first->lap == second->lap; 
}
