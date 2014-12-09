/* Copyright (C) Cambridge Silicon Radio Limited 2011-2014 */
/* Part of ADK 3.5 */

#include <bdaddr.h>

bool BdaddrTypedIsSame(const typed_bdaddr *first, const typed_bdaddr *second)
{
    return  first->type == second->type && 
            BdaddrIsSame(&first->addr, &second->addr);
}
