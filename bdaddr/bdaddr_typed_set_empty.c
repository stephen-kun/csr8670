/* Copyright (C) Cambridge Silicon Radio Limited 2005-2014 */
/* Part of ADK 3.5 */

#include <bdaddr.h>

void BdaddrTypedSetEmpty(typed_bdaddr *in)
{
    in->type = TYPED_BDADDR_INVALID;
    BdaddrSetZero(&in->addr);
}
