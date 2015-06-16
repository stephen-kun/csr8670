/*****************************************************************
Copyright (C) Cambridge Silicon Radio Ltd. 2011-2014
*/

#ifndef _GAIA_TRANSPORT_MFI_H
#define _GAIA_TRANSPORT_MFI_H

#ifdef GAIA_TRANSPORT_MFI

/*! @brief Initialise MFi transport.
 */
void gaiaTransportMfiInit(gaia_transport *transport);

/*! @brief Handle a request from client task to create a Gaia connection.
 */
void gaiaTransportMfiConnectReq(gaia_transport *transport, bdaddr *address);

/*! @brief Handle client task response to an incoming connection indication.
 */
void gaiaTransportMfiConnectRes(gaia_transport *transport);

/*! @brief Handle client task request to disconnect an MFi transport.
 */
void gaiaTransportMfiDisconnectReq(gaia_transport *transport);

/*! @brief Handle client task response to an incoming disconnection indication.
 */
void gaiaTransportMfiDisconnectRes(gaia_transport *transport);

/*! @brief Handle client task data transmission request.
 */
void gaiaTransportMfiSendPacket(Task task, gaia_transport *transport, uint16 length, uint8 *data);

/*! @brief Return the sink being used by our underlying MFi transport.
 */
Sink gaiaTransportMfiGetSink(gaia_transport *transport);

/*! @brief Initialise IAP library.
 */
void gaiaTransportMfiStartService(void);

/*! @brief MFi transport message handler.
 */
bool gaiaTransportMfiHandleMessage(Task task, MessageId id, Message message);

#endif /* GAIA_TRANSPORT_MFI */

#endif /* _GAIA_TRANSPORT_MFI_H */
