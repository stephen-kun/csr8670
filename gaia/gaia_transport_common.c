/*****************************************************************
Copyright (C) Cambridge Silicon Radio Ltd. 2011-2014
*/

#include <panic.h>
#include "gaia_private.h"
#include "gaia_transport_common.h"

/*! @brief Utility function to send a GAIA_CONNECT_CFM message to client task.
 *
 *  @param transport The gaia transport on which the event occurred.
 *  @param success Boolean indicating success (TRUE) or failure (FALSE) of connection attempt.
 */
void gaiaTransportCommonSendGaiaConnectCfm(gaia_transport *transport, bool success)
{
    MESSAGE_PMAKE(gcc, GAIA_CONNECT_CFM_T);
    gcc->transport = (GAIA_TRANSPORT*)transport;
    gcc->success = success;
    MessageSend(gaia->app_task, GAIA_CONNECT_CFM, gcc);
}

/*! @brief Utility function to send a GAIA_CONNECT_IND message to client task.
 *
 *  @param transport The gaia transport on which the event occurred.
 *  @param success Boolean indicating success (TRUE) or failure (FALSE) of connection attempt.
 */
void gaiaTransportCommonSendGaiaConnectInd(gaia_transport *transport, bool success)
{
    MESSAGE_PMAKE(gci, GAIA_CONNECT_IND_T);
    gci->transport = (GAIA_TRANSPORT*)transport;
    gci->success = success;
    MessageSend(gaia->app_task, GAIA_CONNECT_IND, gci);
}

/*! @brief Utility function to send a GAIA_DISCONNECT_IND message to client task.
 *
 *  @param transport The gaia transport on which the event occurred.
 */
void gaiaTransportCommonSendGaiaDisconnectInd(gaia_transport *transport)
{
    MESSAGE_PMAKE(gdi, GAIA_DISCONNECT_IND_T);
    gdi->transport = (GAIA_TRANSPORT*)transport;
    MessageSend(gaia->app_task, GAIA_DISCONNECT_IND, gdi);
}

/*! @brief Utility function to send a GAIA_DISCONNECT_CFM message to client task.
 *
 *  @param transport The gaia transport on which the event occurred.
 */
void gaiaTransportCommonSendGaiaDisconnectCfm(gaia_transport *transport)
{
    MESSAGE_PMAKE(gdc, GAIA_DISCONNECT_CFM_T);
    gdc->transport = (GAIA_TRANSPORT*)transport;
    MessageSend(gaia->app_task, GAIA_DISCONNECT_CFM, gdc);
}

/*! @brief Utility function to send a GAIA_SEND_PACKET_CFM message to client task.
 *
 *  @param transport The gaia transport on which the event occurred.
 *  @param packet Pointer to the packet data that was transmitted.
 *  @param success Boolean indicating success or failure of Gaia command transmission.
 */
void gaiaTransportCommonSendGaiaSendPacketCfm(gaia_transport *transport, uint8 *packet, bool success)
{
    MESSAGE_PMAKE(gspc, GAIA_SEND_PACKET_CFM_T);
    gspc->transport = (GAIA_TRANSPORT*)transport;
    gspc->packet = packet;
    gspc->success = success;
    MessageSend(gaia->app_task, GAIA_SEND_PACKET_CFM, gspc);
}


/*! @brief Utility function to send a GAIA_START_SERVICE_CFM message to client task.
 *
 *  @param transport The gaia transport on which the service runs
 *  @param success Boolean indicating success or failure of the GaiaStartService request
 */
void gaiaTransportCommonSendGaiaStartServiceCfm(gaia_transport_type transport_type, gaia_transport* transport, bool success)
{
    MESSAGE_PMAKE(gssc, GAIA_START_SERVICE_CFM_T);
    gssc->transport_type = transport_type;
    gssc->transport = (GAIA_TRANSPORT*)transport;
    gssc->success = success;
    MessageSend(gaia->app_task, GAIA_START_SERVICE_CFM, gssc);
}


/*! @brief Cleanup battery and RSSI threshold state for a given transport.
 
    Used once a Gaia transport has closed, as we no longer need to perform the
    checking or resend the timer messages.
*/
void gaiaTransportCommonCleanupThresholdState(gaia_transport *transport)
{
    /* reset battery threshold state */
    transport->threshold_count_lo_battery = 0;
    transport->sent_notification_lo_battery_0 = FALSE;
    transport->sent_notification_lo_battery_1 = FALSE;
    transport->threshold_count_hi_battery = 0;
    transport->sent_notification_hi_battery_0 = FALSE;
    transport->sent_notification_hi_battery_1 = FALSE;

    /* reset RSSI threshold state */
    transport->threshold_count_lo_rssi = 0;
    transport->sent_notification_lo_rssi_0 = FALSE;
    transport->sent_notification_lo_rssi_1 = FALSE;
    transport->threshold_count_hi_rssi = 0;
    transport->sent_notification_hi_rssi_0 = FALSE;
    transport->sent_notification_hi_rssi_1 = FALSE;
}
