/*****************************************************************
Copyright (C) Cambridge Silicon Radio Ltd. 2011-2014
*/

#ifndef _GAIA_TRANSPORT_H
#define _GAIA_TRANSPORT_H

/*! @brief Initialise a Gaia transport.
 */
void gaiaTransportInit(gaia_transport *transport);

/*! @brief Attempt to connect Gaia to a device over a given transport.
 */
void gaiaTransportConnectReq(gaia_transport *transport, bdaddr *address);

/*! @brief Respond to an incoming Gaia connection indication over a given transport.
 */
void gaiaTransportConnectRes(gaia_transport *transport);

/*! @brief Attempt to disconnect Gaia over a given transport.
 */
void gaiaTransportDisconnectReq(gaia_transport *transport);

/*! @brief Respond to a Gaia disconnection indication over a given transport.
 */
void gaiaTransportDisconnectRes(gaia_transport *transport);

/*! @brief Clear down state of given transport.
 */
void gaiaTransportDropState(gaia_transport *transport);

/*! @brief Attempt to find a free transport slot
 */
gaia_transport *gaiaTransportFindFree(void);

/*! @brief Attempt to find the tranport associated with an RFCOMM channel
 */
gaia_transport *gaiaTransportFromRfcommChannel(uint16 channel);
        
/*! @brief Attempt to find the tranport associated with a sink
 */
gaia_transport *gaiaTransportFromSink(Sink sink);

/*! @brief Start Gaia as a server on a given transport.
 *
 * NOTE - only applicable to the SPP transport.
 */
void gaiaTransportStartService(gaia_transport_type transport_type);

/*! @brief Transmit a Gaia packet over a given transport.
 */
void gaiaTransportSendPacket(Task task, gaia_transport *transport, uint16 length, uint8 *data);

/*! @brief Get the stream source for a given transport.
 *
 * NOTE - only applicable to the SPP transport.
 */
Source gaiaTransportGetSource(gaia_transport *transport);

/*! @brief Get the stream sink for a given transport.
 */
Sink gaiaTransportGetSink(gaia_transport *transport);

/*! @brief Pass incoming message for handling by a given transport.
 */
bool gaiaTransportHandleMessage(Task task, MessageId id, Message message);

#endif /* _GAIA_TRANSPORT_H */
