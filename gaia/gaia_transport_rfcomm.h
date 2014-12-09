/*****************************************************************
Copyright (C) Cambridge Silicon Radio Ltd. 2011-2014
*/

#ifndef _GAIA_TRANSPORT_RFCOMM_H
#define _GAIA_TRANSPORT_RFCOMM_H

#ifdef GAIA_TRANSPORT_RFCOMM

/*! @brief
 */
void gaiaTransportRfcommInit(gaia_transport *transport);

/*! @brief
 */
void gaiaTransportRfcommConnectReq(gaia_transport *transport, bdaddr *address);

/*! @brief
 */
void gaiaTransportRfcommConnectRes(gaia_transport *transport);

/*! @brief
 */
void gaiaTransportRfcommDisconnectReq(gaia_transport *transport);

/*! @brief
 */
void gaiaTransportRfcommDisconnectRes(gaia_transport *transport);

/*! @brief
 */
void gaiaTransportRfcommDropState(gaia_transport *transport);

/*! @brief
 */
void gaiaTransportRfcommStartService(void);

/*! @brief
 */
void gaiaTransportRfcommSendPacket(Task task, gaia_transport *transport, uint16 length, uint8 *data);

/*! @brief
 */
Sink gaiaTransportRfcommGetSink(gaia_transport *transport);

/*! @brief
 */
bool gaiaTransportRfcommHandleMessage(Task task, MessageId id, Message message);

#endif /* GAIA_TRANSPORT_RFCOMM */

#endif /* _GAIA_TRANSPORT_RFCOMM_H */
