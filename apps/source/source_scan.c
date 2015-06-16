/*****************************************************************
Copyright (C) Cambridge Silicon Radio Ltd. 2011-2014

PROJECT
    source
    
FILE NAME
    source_scan.c

DESCRIPTION
    Sets scan modes - connectability / discoverability    

*/


/* header for this file */
#include "source_scan.h"
/* application header files */
#include "source_a2dp.h"
#include "source_debug.h"
#include "source_states.h"
/* profile/library headers */
#include <connection.h>


#ifdef DEBUG_SCAN
    #define SCAN_DEBUG(x) DEBUG(x)
#else
    #define SCAN_DEBUG(x)
#endif


/***************************************************************************
Functions
****************************************************************************
*/

/****************************************************************************
NAME    
    scan_set_unconnectable - Not connectable or discoverable
*/
void scan_set_unconnectable(void)
{
    SCAN_DEBUG(("SCAN: unconnectable\n"));
    ConnectionWriteScanEnable(hci_scan_enable_off);
}


/****************************************************************************
NAME    
    scan_set_connectable_only - Connectable only
*/
void scan_set_connectable_only(void)
{
    SCAN_DEBUG(("SCAN: connectable\n"));
    ConnectionWriteScanEnable(hci_scan_enable_page);
}


/****************************************************************************
NAME    
    scan_set_discoverable_only - Discoverable only
*/
void scan_set_discoverable_only(void)
{
    SCAN_DEBUG(("SCAN: discoverable\n"));
    ConnectionWriteScanEnable(hci_scan_enable_inq);
}


/****************************************************************************
NAME    
    scan_set_connectable_discoverable - Connectable and Discoverable
*/
void scan_set_connectable_discoverable(void)
{
    SCAN_DEBUG(("SCAN: connectable/discoverable\n"));
    ConnectionWriteScanEnable(hci_scan_enable_inq_and_page);
}


/****************************************************************************
NAME    
    scan_check_connection_state - Check connection state and update scan
*/
void scan_check_connection_state(void)
{
    SCAN_DEBUG(("SCAN: scan_check_connection_state\n"));
    
    switch (states_get_state())
    {
        case SOURCE_STATE_CONNECTED:
        {
            if (a2dp_allow_more_connections())
            {
                scan_set_connectable_only();
            }
            else
            {
                scan_set_unconnectable();
            }
        }
        break;
        
        default:
        {
        }
        break;
    }
}
