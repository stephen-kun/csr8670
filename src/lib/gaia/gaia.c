/*************************************************************************
Copyright © CSR plc 2010-2014
Part of ADK 3.5

FILE
    gaia.c
    
DESCRIPTION
    Generic Application Interface Architecture
    This library implements the GAIA protocol for a server- or client-side
    SPP connection.
    
    The library exposes a functional downstream API and a message-based upstream API.
*/
#include <connection.h>
#include <stream.h>
#include <sink.h>
#include <source.h>
#include <vm.h>
#include <boot.h>
#include <ps.h>
#include <stdlib.h>
#include <stdio.h>
#include <panic.h>
#include <print.h>
#include <string.h>
#include <power.h>
#include <psu.h>
#include <partition.h>
#include <file.h>
#include <spp_common.h>
#include <audio.h>
#include <loader.h>
#include <kalimba.h>

#include "gaia_private.h"
#include "gaia_transport.h"
#include "gaia_transport_spp.h"

/*  Commands which can be handled by the library but can be supplanted
 *  by an application implementation.
 *  
 *  GAIA_COMMAND_POWER_OFF is at index 0 for the benefit of
 *  GaiaInit(); that's the only one initially handled by the app
 */
static const uint16 lib_commands[] =
{
    GAIA_COMMAND_POWER_OFF,
    GAIA_COMMAND_DEVICE_RESET,
    GAIA_COMMAND_GET_BOOTMODE, 
    GAIA_COMMAND_GET_API_VERSION,    
    
    GAIA_COMMAND_GET_CURRENT_RSSI,
    GAIA_COMMAND_GET_CURRENT_BATTERY_LEVEL,
    GAIA_COMMAND_RETRIEVE_PS_KEY,
    GAIA_COMMAND_RETRIEVE_FULL_PS_KEY,
    
    GAIA_COMMAND_STORE_PS_KEY,
    GAIA_COMMAND_SEND_APPLICATION_MESSAGE,
    GAIA_COMMAND_SEND_KALIMBA_MESSAGE,
    GAIA_COMMAND_DELETE_PDL,
    
    GAIA_COMMAND_REGISTER_NOTIFICATION,
    GAIA_COMMAND_GET_NOTIFICATION,
    GAIA_COMMAND_CANCEL_NOTIFICATION
};

GAIA_T *gaia = NULL;


/*************************************************************************
NAME
    dwunpack
    
DESCRIPTION
    Unpack a uint32 into an array of uint8s
*/
static void dwunpack(uint8 *dest, uint32 src)
{
    *dest++ = src >> 24;
    *dest++ = (src >> 16) & 0xFF;
    *dest++ = (src >> 8) & 0xFF;
    *dest = src & 0xFF;
}


/*************************************************************************
NAME
    wpack
    
DESCRIPTION
    Pack array of uint8s into array of uint16
*/
static void wpack(uint16 *dest, uint8 *src, uint16 length)
{
    while (length--)
    {
        *dest = *src++ << 8;
        *dest++ |= *src++;
    }
}


/*************************************************************************
NAME
    find_locus_bit
    
DESCRIPTION
    Determine if command can be handled by the library
    Return index into lib_commands array or GAIA_INVALID_ID
*/
static uint16 find_locus_bit(uint16 command_id)
{
    uint16 idx;
    
    for (idx = 0; idx < sizeof lib_commands; ++idx)
        if (lib_commands[idx] == command_id)
            return idx;
    
    return GAIA_INVALID_ID;
}


/*************************************************************************
NAME
    read_battery
    
DESCRIPTION
    Read the battery voltage using the appropriate ADC
*/
static void read_battery(void)
{
    if(gaia->no_vdd_sense || !AdcRequest(&gaia->task_data, adcsel_vdd_sense))
    {
        gaia->no_vdd_sense = TRUE;
        AdcRequest(&gaia->task_data, adcsel_vdd_bat);
    }
}


/*************************************************************************
NAME
    app_will_handle_command
    
DESCRIPTION
    Determine if the specified command is to be passed to the onchip app
*/
static bool app_will_handle_command(uint16 command_id)
{
/*  Not a command but an acknowledgement of an event notification  */
    if (command_id == GAIA_ACK_NOTIFICATION)
        return FALSE;
    
/*  Look it up  */
    return GaiaGetAppWillHandleCommand(command_id);
}


/*************************************************************************
NAME
    build_packet
    
DESCRIPTION
    Build a Gaia protocol packet in the given buffer
    uint8 payload variant
    If <status> is other than GAIA_STATUS_NONE it is inserted
    before the first byte of the passed-in payload to simplify
    the building of acknowledgement and notification packets
    
    Returns the length of the packet or 0 on error
*/
static uint16 build_packet(uint8 *buffer, uint8 flags,
                              uint16 vendor_id, uint16 command_id, uint16 status, 
                              uint8 payload_length, uint8 *payload)
{
    uint8 *data = buffer;
    uint16 packet_length = GAIA_OFFS_PAYLOAD + payload_length;

    if (status != GAIA_STATUS_NONE)
        ++packet_length;

    if (flags & GAIA_PROTOCOL_FLAG_CHECK)
        ++packet_length;

    if (packet_length > GAIA_MAX_PACKET)
        return 0;

    /*  Build the header.  It's that diagram again ... 
     *  0 bytes  1        2        3        4        5        6        7        8          9    len+8      len+9
     *  +--------+--------+--------+--------+--------+--------+--------+--------+ +--------+--/ /---+ +--------+
     *  |  SOF   |VERSION | FLAGS  | LENGTH |    VENDOR ID    |   COMMAND ID    | | PAYLOAD   ...   | | CHECK  |
     *  +--------+--------+--------+--------+--------+--------+--------+--------+ +--------+--/ /---+ +--------+
     */
    *data++ = GAIA_SOF;
    *data++ = GAIA_VERSION;
    *data++ = flags;
    *data++ = payload_length;
    *data++ = HIGH(vendor_id);
    *data++ = LOW(vendor_id);
    *data++ = HIGH(command_id);
    *data++ = LOW(command_id);

    if (status != GAIA_STATUS_NONE)
    {
        /*  Insert status-cum-event byte and increment payload length  */
        *data++ = status;
        ++buffer[GAIA_OFFS_PAYLOAD_LENGTH];
    }

    /*  Copy in the payload  */
    while (payload_length--)
        *data++ = *payload++;

    if (flags & GAIA_PROTOCOL_FLAG_CHECK)
    {
    /*  Compute the checksum  */
        uint8 check = 0;
        data = buffer;

        while (--packet_length)
            check ^= *data++;

        *data++ = check;
    }

    return data - buffer;    
}


/*************************************************************************
NAME
    build_packet_16
    
DESCRIPTION
    Build a Gaia protocol packet in the given buffer
    uint16 payload variant
    If <status> is other than GAIA_STATUS_NONE it is inserted
    before the first byte of the passed-in payload to simplify
    the building of acknowledgement and notification packets
    
    payload_length is the number of uint16s in the payload
    Returns the length of the packet or 0 on error
*/
static uint16 build_packet_16(uint8 *buffer, uint8 flags,
                              uint16 vendor_id, uint16 command_id, uint16 status, 
                              uint8 payload_length, uint16 *payload)
{
    uint8 *data = buffer;
    uint16 packet_length = GAIA_OFFS_PAYLOAD + 2 * payload_length;

    if (status != GAIA_STATUS_NONE)
        ++packet_length;

    if (flags & GAIA_PROTOCOL_FLAG_CHECK)
        ++packet_length;

    if (packet_length > GAIA_MAX_PACKET)
        return 0;

    /*  Build the header.  It's that diagram again ... 
     *  0 bytes  1        2        3        4        5        6        7        8          9    len+8      len+9
     *  +--------+--------+--------+--------+--------+--------+--------+--------+ +--------+--/ /---+ +--------+
     *  |  SOF   |VERSION | FLAGS  | LENGTH |    VENDOR ID    |   COMMAND ID    | | PAYLOAD   ...   | | CHECK  |
     *  +--------+--------+--------+--------+--------+--------+--------+--------+ +--------+--/ /---+ +--------+
     */
    *data++ = GAIA_SOF;
    *data++ = GAIA_VERSION;
    *data++ = flags;
    *data++ = 2 * payload_length;
    *data++ = HIGH(vendor_id);
    *data++ = LOW(vendor_id);
    *data++ = HIGH(command_id);
    *data++ = LOW(command_id);

    if (status != GAIA_STATUS_NONE)
    {
        /*  Insert status-cum-event byte and increment payload length  */
        *data++ = status;
        ++buffer[GAIA_OFFS_PAYLOAD_LENGTH];
    }

    /*  Copy in the payload  */
    while (payload_length--)
    {
        *data++ = HIGH(*payload);
        *data++ = LOW(*payload++);
    }

    if (flags & GAIA_PROTOCOL_FLAG_CHECK)
    {
        /*  Compute the checksum  */
        uint8 check = 0;
        data = buffer;

        while (--packet_length)
            check ^= *data++;

        *data++ = check;
    }

    return data - buffer;    
}


/*************************************************************************
NAME
    send_packet
    
DESCRIPTION
    Send a Gaia packet
*/
static void send_packet(Task task, gaia_transport *transport, uint16 packet_length, uint8 *packet)
{
    MESSAGE_PMAKE(m, GAIA_INTERNAL_SEND_REQ_T);
    
    GAIA_DEBUG(("gaia: send_packet: t=%04x s=%d\n", (uint16) task, VmGetAvailableAllocations()));
    
    m->task = task;
    m->transport = transport;
    m->length = packet_length;
    m->data = packet;
    
    MessageSend(&gaia->task_data, GAIA_INTERNAL_SEND_REQ, m);
}


/*************************************************************************
NAME
    send_response
    
DESCRIPTION
    Build and send a Gaia packet
*/
static void send_response(gaia_transport *transport, uint16 vendor_id, uint16 command_id,
                          uint8 status, uint16 payload_length, uint8 *payload)
{
    uint16 packet_length;
    uint8 *packet;
    uint8 flags = transport->flags;

    packet_length = GAIA_OFFS_PAYLOAD + payload_length + 1;
    if (flags & GAIA_PROTOCOL_FLAG_CHECK)
        ++packet_length;
    
    packet = malloc(packet_length);
    
    if (packet)
    {
        packet_length = build_packet(packet, flags, vendor_id, command_id, 
                                     status, payload_length, payload);
        
        send_packet(NULL, transport, packet_length, packet);
    }
}


/*************************************************************************
NAME
    send_ack
    
DESCRIPTION
    Build and send a Gaia acknowledgement packet
*/
#define send_ack(transport, vendor, command, status, length, payload) \
    send_response(transport, vendor, (command) | GAIA_ACK_MASK, status, length, payload)

            
/*************************************************************************
NAME
    send_ack_16
    
DESCRIPTION
    Build and send a Gaia acknowledgement packet from a uint16[] payload
*/
static void send_ack_16(gaia_transport *transport, uint16 vendor_id, uint16 command_id,
                          uint8 status, uint16 payload_length, uint16 *payload)
{
    uint16 packet_length;
    uint8 *packet;
    uint8 flags = transport->flags;
    

    packet_length = GAIA_OFFS_PAYLOAD + 2 * payload_length + 1;
    if (flags & GAIA_PROTOCOL_FLAG_CHECK)
        ++packet_length;
    
    packet = malloc(packet_length);
    
    if (packet)
    {
        packet_length = build_packet_16(packet, flags, vendor_id, command_id | GAIA_ACK_MASK, 
                                     status, payload_length, payload);
        
        send_packet(NULL, transport, packet_length, packet);
    }
}


/*************************************************************************
NAME
    send_simple_response
    
DESCRIPTION
    Build and send a Gaia acknowledgement packet
*/
#define send_simple_response(transport, command, status) \
    send_ack(transport, GAIA_VENDOR_CSR, command, status, 0, NULL)

            
/*************************************************************************
NAME
    send_success
    
DESCRIPTION
    Send a successful response to the given command
*/
#define send_success(transport, command) \
    send_simple_response(transport, command, GAIA_STATUS_SUCCESS)

    
/*************************************************************************
NAME
    send_success_payload
    
DESCRIPTION
    Send a successful response incorporating the given payload
*/
#define send_success_payload(transport, command, length, payload) \
    send_ack(transport, GAIA_VENDOR_CSR, command, GAIA_STATUS_SUCCESS, length, payload)

    
/*************************************************************************
NAME
    send_notification
    
DESCRIPTION
    Send a notification incorporating the given payload
*/
#define send_notification(transport, event, length, payload) \
    send_response(transport, GAIA_VENDOR_CSR, GAIA_EVENT_NOTIFICATION, \
                  event, length, payload)


/*************************************************************************
NAME
    send_insufficient_resources
    
DESCRIPTION
    Send an INSUFFICIENT_RESOURCES response to the given command
*/
#define send_insufficient_resources(transport, command) \
    send_simple_response(transport, command, GAIA_STATUS_INSUFFICIENT_RESOURCES)   


/*************************************************************************
NAME
    send_invalid_parameter
    
DESCRIPTION
    Send an INVALID_PARAMETER response to the given command
*/
#define send_invalid_parameter(transport, command) \
    send_simple_response(transport, command, GAIA_STATUS_INVALID_PARAMETER)


/*************************************************************************
NAME
    send_incorrect_state
    
DESCRIPTION
    Send an INCORRECT_STATE response to the given command
*/
#define send_incorrect_state(transport, command) \
    send_simple_response(transport, command, GAIA_STATUS_INCORRECT_STATE)


/*************************************************************************
NAME
    send_api_version
    
DESCRIPTION
    Send a completed GAIA_COMMAND_GET_API_VERSION response
*/
static void send_api_version(gaia_transport *transport)
{
    uint8 payload[3];
    
    payload[0] = GAIA_VERSION;
    payload[1] = GAIA_API_VERSION_MAJOR;
    payload[2] = gaia->api_minor;
    
    send_success_payload(transport, GAIA_COMMAND_GET_API_VERSION, 3, payload);
}


/*************************************************************************
NAME
    send_rssi
    
DESCRIPTION
    Send a completed GAIA_COMMAND_GET_CURRENT_RSSI response
*/
static void send_rssi(gaia_transport *transport)
{
    int16 rssi = 0;

    if (SinkGetRssi(gaiaTransportGetSink(transport), &rssi))
    {
        uint8 payload = LOW(rssi);
        send_success_payload(transport, GAIA_COMMAND_GET_CURRENT_RSSI, 1, &payload);
    }
    
    else
        send_insufficient_resources(transport, GAIA_COMMAND_GET_CURRENT_RSSI);
}


/*************************************************************************
NAME
    send_battery_level
    
DESCRIPTION
    Send a completed GAIA_COMMAND_GET_CURRENT_BATTERY_LEVEL response
*/
static void send_battery_level(gaia_transport *transport)
{
    if (gaia->battery_voltage == 0)
        send_insufficient_resources(transport, GAIA_COMMAND_GET_CURRENT_BATTERY_LEVEL);
    
    else
    {
        uint8 payload[2];
        
        payload[0] = HIGH(gaia->battery_voltage);
        payload[1] = LOW(gaia->battery_voltage);
        
        send_success_payload(transport, GAIA_COMMAND_GET_CURRENT_BATTERY_LEVEL, 2, payload);
    }
}


/*************************************************************************
NAME
    queue_device_reset
    
DESCRIPTION
    Queue a device reset in the near future.  TATA_TIME should be time
    enough for the host to get our acknowledgement before we go.  Setting
    the 'rebooting' flag inhibits any further commands from the host.
 */
static void queue_device_reset(gaia_transport *transport, uint16 bootmode)
{        
    uint16 *reset_message;
    
    GAIA_CMD_DEBUG(("gaia: queue_device_reset %u\n", bootmode));
    
    reset_message = malloc(sizeof (uint16));
    if (!reset_message)
        send_insufficient_resources(transport, GAIA_COMMAND_DEVICE_RESET);
        
    else
    {
        gaia->rebooting = TRUE;
        *reset_message = bootmode;
        MessageSendLater(&gaia->task_data, GAIA_INTERNAL_REBOOT_REQ, reset_message, TATA_TIME);
        send_success(transport, GAIA_COMMAND_DEVICE_RESET);
    }
}


/*************************************************************************
NAME
    send_bootmode
    
DESCRIPTION
    Handle a GAIA_COMMAND_GET_BOOTMODE by returning the current bootmode
*/
static void send_bootmode(gaia_transport *transport)
{
    uint8 payload = BootGetMode();
    send_success_payload(transport, GAIA_COMMAND_GET_BOOTMODE, 1, &payload);
}


/*************************************************************************
NAME
    queue_power_off
    
DESCRIPTION
    Queue a device power off in the near future.  TATA_TIME should be time
    enough for the host to get our acknowledgement before we go.  We don't
    set 'rebooting' here so we don't get stuck if the power doesn't go off
*/
static void queue_power_off(gaia_transport *transport)
{
    MessageSendLater(&gaia->task_data, GAIA_INTERNAL_POWER_OFF_REQ, NULL, TATA_TIME);
    send_success(transport, GAIA_COMMAND_POWER_OFF);
}


/*! @brief Utility function to start timer for checking battery level thresholds.
 */
static void start_check_battery_threshold_timer(gaia_transport *transport)
{
    MESSAGE_PMAKE(batt_timer, GAIA_INTERNAL_CHECK_BATTERY_THRESHOLD_REQ_T);
    batt_timer->transport = transport;
    MessageSendLater(&gaia->task_data, GAIA_INTERNAL_CHECK_BATTERY_THRESHOLD_REQ, batt_timer, GAIA_CHECK_THRESHOLDS_PERIOD);
}

/*! @brief Utility function to start timer for checking RSSI level thresholds.
 */
static void start_check_rssi_threshold_timer(gaia_transport *transport)
{
    MESSAGE_PMAKE(rssi_timer, GAIA_INTERNAL_CHECK_RSSI_THRESHOLD_REQ_T);
    rssi_timer->transport = transport;
    MessageSendLater(&gaia->task_data, GAIA_INTERNAL_CHECK_RSSI_THRESHOLD_REQ, rssi_timer, GAIA_CHECK_THRESHOLDS_PERIOD);
}

/*************************************************************************
NAME
    register_notification
    
DESCRIPTION
    Registers the host's desire to receive notification of an event
    GAIA_EVENT_DEBUG_MESSAGE requires GAIA_FEATURE_DEBUG feature bit
*/
static void register_notification(gaia_transport *transport, uint16 payload_length, uint8 *payload)
{
    uint16 status = GAIA_STATUS_INVALID_PARAMETER;
    
    GAIA_CMD_DEBUG(("gaia: register_notification %d: %d\n", payload_length, payload[0]));
    
    switch (payload[0])
    {
    case GAIA_EVENT_BATTERY_LOW_THRESHOLD:
        
        /* start the battery threshold check timer if necessary */
        if (!transport->threshold_count_lo_battery && !transport->threshold_count_hi_battery)
        {
            start_check_battery_threshold_timer(transport);
        }

        transport->threshold_count_lo_battery = 0;
        
    /*  Check for 1 or 2 two-byte arguments  */
        switch (payload_length)
        {
        case 5:
            transport->battery_lo_threshold[1] = W16(payload + 3);
            transport->threshold_count_lo_battery = 1;
        /*  drop through  */
        case 3:
            transport->battery_lo_threshold[0] = W16(payload + 1);
            transport->threshold_count_lo_battery++;
            status = GAIA_STATUS_SUCCESS;
            break;
        }
            
        GAIA_DEBUG(("gaia: batt lo %d: %d %d\n",
               transport->threshold_count_lo_battery,
               transport->battery_lo_threshold[0], 
               transport->battery_lo_threshold[1]));
                    
        break;
        
    case GAIA_EVENT_BATTERY_HIGH_THRESHOLD:
        
        /* start the battery threshold check timer if necessary */
        if (!transport->threshold_count_lo_battery && !transport->threshold_count_hi_battery)
        {
            start_check_battery_threshold_timer(transport);
        }

        transport->threshold_count_hi_battery = 0;
        
    /*  Check for 1 or 2 two-byte arguments  */
        switch (payload_length)
        {
        case 5:
            transport->battery_hi_threshold[1] = W16(payload + 3);
            transport->threshold_count_hi_battery = 1;
        /*  drop through  */
        case 3:
            transport->battery_hi_threshold[0] = W16(payload + 1);
            transport->threshold_count_hi_battery++;
            status = GAIA_STATUS_SUCCESS;
            break;
        }
            
        GAIA_DEBUG(("gaia: batt hi %d: %d %d\n", 
               transport->threshold_count_hi_battery,
               transport->battery_hi_threshold[0], 
               transport->battery_hi_threshold[1]));
                    
        break;
        
    case GAIA_EVENT_RSSI_LOW_THRESHOLD:

        /* start the RSSI check timer if necessary */
        if (!transport->threshold_count_lo_rssi && !transport->threshold_count_hi_rssi)
        {
            start_check_rssi_threshold_timer(transport);
        }

        transport->threshold_count_lo_rssi = 0;
        
    /*  Check for 1 or 2 one-byte arguments  */
        switch (payload_length)
        {
        case 3:
            transport->rssi_lo_threshold[1] = SEXT(payload[2]);
            transport->threshold_count_lo_rssi = 1;
        /*  drop through  */
        case 2:
            transport->rssi_lo_threshold[0] = SEXT(payload[1]);
            transport->threshold_count_lo_rssi++;
            status = GAIA_STATUS_SUCCESS;
            break;
        }
        
        GAIA_DEBUG(("gaia: RSSI lo %d: %d %d\n", 
               transport->threshold_count_lo_rssi,
               transport->rssi_lo_threshold[0], 
               transport->rssi_lo_threshold[1]));
        
        break;
        
    case GAIA_EVENT_RSSI_HIGH_THRESHOLD:
        
        /* start the RSSI check timer if necessary */
        if (!transport->threshold_count_lo_rssi && !transport->threshold_count_hi_rssi)
        {
            start_check_rssi_threshold_timer(transport);
        }

        transport->threshold_count_hi_rssi = 0;
        
    /*  Check for 1 or 2 one-byte arguments  */
        switch (payload_length)
        {
        case 3:
            transport->rssi_hi_threshold[1] = SEXT(payload[2]);
            transport->threshold_count_hi_rssi = 1;
        /*  drop through  */
        case 2:
            transport->rssi_hi_threshold[0] = SEXT(payload[1]);
            transport->threshold_count_hi_rssi++;
            status = GAIA_STATUS_SUCCESS;
            break;
        }
        
        GAIA_DEBUG(("gaia: RSSI hi %d: %d %d\n",
               transport->threshold_count_hi_rssi,
               transport->rssi_hi_threshold[0], 
               transport->rssi_hi_threshold[1]));
        
        break;
    }
    
    send_ack(transport, GAIA_VENDOR_CSR, GAIA_COMMAND_REGISTER_NOTIFICATION, status, 1, payload);
}


/*************************************************************************
NAME
    send_notification_setting
    
DESCRIPTION
    Respond to a GAIA_COMMAND_GET_NOTIFICATION command
    The response holds the notification setting for the given event,
    if any, e.g. if two Battery Low Thresholds were configured:

    +--------+--------+--------+--------+--------+--------+--------+
    | STATUS |  TYPE  | COUNT  |   THRESHOLD 1   |   THRESHOLD 2   |
    +--------+--------+--------+--------+--------+--------+--------+

    Status: 0x00, success
    Type:   0x02, Batery Low Threshold
    Count:  2
            
    For events which are simply disabled or enabled the 'count' is 0 or 1
    
NOTE
    payload_length does not include the STATUS byte; GaiaSendResponse()
    adds that later
*/
static void send_notification_setting(gaia_transport *transport, uint8 event)
{
    uint8 payload[6];
    uint8 *p = payload;
    
    *p++ = event;
    
    switch (event)
    {
    case GAIA_EVENT_RSSI_LOW_THRESHOLD:
        *p++ = transport->threshold_count_lo_rssi;
        
        if (transport->threshold_count_lo_rssi > 0)
            *p++ = transport->rssi_lo_threshold[0];
        
        if (transport->threshold_count_lo_rssi > 1)
            *p++ = transport->rssi_lo_threshold[1];
        
        break;
        
    case GAIA_EVENT_RSSI_HIGH_THRESHOLD:
        *p++ = transport->threshold_count_hi_rssi;
        
        if (transport->threshold_count_hi_rssi > 0)
            *p++ = transport->rssi_hi_threshold[0];
        
        if (transport->threshold_count_hi_rssi > 1)
            *p++ = transport->rssi_hi_threshold[1];
        
        break;
        
    case GAIA_EVENT_BATTERY_LOW_THRESHOLD:
        *p++= transport->threshold_count_lo_battery;
        
        if (transport->threshold_count_lo_battery > 0)
        {
            *p++ = HIGH(transport->battery_lo_threshold[0]);
            *p++ = LOW(transport->battery_lo_threshold[0]);
        }
        
        if (transport->threshold_count_lo_battery > 1)
        {
            *p++ = HIGH(transport->battery_lo_threshold[1]);
            *p++ = LOW(transport->battery_lo_threshold[1]);
        }
        
        break;
        
    case GAIA_EVENT_BATTERY_HIGH_THRESHOLD:
        *p++ = transport->threshold_count_hi_battery;
        
        if (transport->threshold_count_hi_battery > 0)
        {
            *p++ = HIGH(transport->battery_hi_threshold[0]);
            *p++ = LOW(transport->battery_hi_threshold[0]);
        }
        
        if (transport->threshold_count_hi_battery > 1)
        {
            *p++ = HIGH(transport->battery_hi_threshold[1]);
            *p++ = LOW(transport->battery_hi_threshold[1]);
        }
        
        break;
        
/*  Dummies for legal but unimplemented events  */
    case GAIA_EVENT_BATTERY_CHARGED:
    case GAIA_EVENT_DEVICE_STATE_CHANGED:
    case GAIA_EVENT_PIO_CHANGED:
        *p++ = GAIA_FEATURE_DISABLED;
        break;        
    }
    
    
    if (p > payload)
        send_success_payload(transport, GAIA_COMMAND_GET_NOTIFICATION, p - payload, payload);
    
    else
        send_invalid_parameter(transport, GAIA_COMMAND_GET_NOTIFICATION);
}

/*************************************************************************
NAME
    cancel_notification
    
DESCRIPTION
    The host desires to receive no further notification of an event   
*/
static void cancel_notification(gaia_transport *transport, uint8 event_id)
{
/*  uint16 old_flags = gaia->threshold_poll_flags;  */
    uint16 status = GAIA_STATUS_INVALID_PARAMETER;
    
    switch(event_id)
    {
    case GAIA_EVENT_BATTERY_LOW_THRESHOLD:
        transport->threshold_count_lo_battery = 0;
        transport->sent_notification_lo_battery_0 = FALSE;
        transport->sent_notification_lo_battery_1 = FALSE;
        status = GAIA_STATUS_SUCCESS;
        break;
           
    case GAIA_EVENT_BATTERY_HIGH_THRESHOLD:
        transport->threshold_count_hi_battery = 0;
        transport->sent_notification_hi_battery_0 = FALSE;
        transport->sent_notification_hi_battery_1 = FALSE;
        status = GAIA_STATUS_SUCCESS;
        break;
           
    case GAIA_EVENT_RSSI_LOW_THRESHOLD:
        transport->threshold_count_lo_rssi = 0;
        transport->sent_notification_lo_rssi_0 = FALSE;
        transport->sent_notification_lo_rssi_1 = FALSE;
        status = GAIA_STATUS_SUCCESS;
        break;
        
    case GAIA_EVENT_RSSI_HIGH_THRESHOLD:
        transport->threshold_count_hi_rssi = 0;
        transport->sent_notification_hi_rssi_0 = FALSE;
        transport->sent_notification_hi_rssi_1 = FALSE;
        status = GAIA_STATUS_SUCCESS;
        break;
    }

    
    send_ack(transport, GAIA_VENDOR_CSR, GAIA_COMMAND_CANCEL_NOTIFICATION, status, 1, &event_id);
}


/*************************************************************************
NAME
    send_module_id
    
DESCRIPTION
    Respond to a GAIA_COMMAND_GET_MODULE_ID command
    
    The response holds the chip id, design id and module id proper.
    For Flash devices, chip id will be zero and module id information
    is read from persistent store if present.
*/
static void send_module_id(gaia_transport *transport)
{
    uint16 module_id[4];
    memset(module_id, 0, sizeof module_id);
    
    PsFullRetrieve(PSKEY_MODULE_DESIGN, module_id + 1, 1);
    PsFullRetrieve(PSKEY_MODULE_ID, module_id + 2, 2);
    
    send_ack_16(transport, GAIA_VENDOR_CSR, GAIA_COMMAND_GET_MODULE_ID, 
        GAIA_STATUS_SUCCESS, sizeof module_id, module_id);
}


/*************************************************************************
NAME
    gaia_handle_control_command
    
DESCRIPTION
    Handle a control command or return FALSE if we can't
*/
static bool gaia_handle_control_command(gaia_transport *transport, uint16 command_id,
                                        uint8 payload_length, uint8 *payload)
{
    switch (command_id)
    {
    case GAIA_COMMAND_DEVICE_RESET:
        if (payload_length == 0)
            queue_device_reset(transport, BootGetMode());
         
        else if ((payload_length == 1) && (payload[0] <= PS_MAX_BOOTMODE))
            queue_device_reset(transport, payload[0]);
    
        else
            send_invalid_parameter(transport, GAIA_COMMAND_DEVICE_RESET);
    
        return TRUE;
                    
        
    case GAIA_COMMAND_GET_BOOTMODE:
        send_bootmode(transport);
        return TRUE;
        
        
    case GAIA_COMMAND_POWER_OFF:
        queue_power_off(transport);
        return TRUE;
    }
    
    return FALSE;
}


/*************************************************************************
NAME
    gaia_handle_status_command
    
DESCRIPTION
    Handle a Polled Status command or return FALSE if we can't
*/
static bool gaia_handle_status_command(gaia_transport *transport, uint16 command_id, 
                                       uint8 payload_length, uint8 *payload)
{
    switch (command_id)
    {
    case GAIA_COMMAND_GET_API_VERSION:
        send_api_version(transport);
        return TRUE;
        
    case GAIA_COMMAND_GET_CURRENT_RSSI:
        send_rssi(transport);
        return TRUE;
        
    case GAIA_COMMAND_GET_CURRENT_BATTERY_LEVEL:
    /*  If we're checking thresholds use its averaged reading, else fire off an ADC request  */
        if (transport->threshold_count_lo_battery || transport->threshold_count_hi_battery)
            send_battery_level(transport);
        
        else if (gaia->outstanding_request == NULL)
        {
            gaia->outstanding_request = transport;
            read_battery();
        }

        return TRUE;
        
    case GAIA_COMMAND_GET_MODULE_ID:
        send_module_id(transport);
        return TRUE;
    }
    
    return FALSE;
}
                
      
/*************************************************************************
NAME
    gaia_handle_feature_command
    
DESCRIPTION
    Handle a Feature Control command or return FALSE if we can't
*/
static bool gaia_handle_feature_command(gaia_transport *transport, uint16 command_id, 
                                        uint8 payload_length, uint8 *payload)
{
    switch (command_id)
    {
    case GAIA_COMMAND_SET_SESSION_ENABLE:
        if ((payload_length > 0) && (payload[0] < 2))
        {
            transport->enabled = payload[0];
            send_success(transport, command_id);
        }
        
        else
            send_invalid_parameter(transport, command_id);
        
        return TRUE;
        
    case GAIA_COMMAND_GET_SESSION_ENABLE:
        {
           uint8 response;
           response = transport->enabled;
           send_success_payload(transport, command_id, 1, &response);
           return TRUE;
        }
    }
    return FALSE;
}

/*************************************************************************
NAME
    dfu_reset_timeout
    
DESCRIPTION
    Reset the DFU start / transfer timeout
    
*/
static void dfu_reset_timeout(uint16 period)
{
    GAIA_DFU_DEBUG(("gaia: dfu tmo=%u\n", period));

    MessageCancelAll(&gaia->task_data, GAIA_INTERNAL_DFU_TIMEOUT);
    
    if (period)
    {
        MessageSendLater(&gaia->task_data, GAIA_INTERNAL_DFU_TIMEOUT, NULL, D_SEC(period));
    }
}


/*************************************************************************
NAME
    dfu_confirm
    
DESCRIPTION
    Send a GAIA_DFU_CFM response to the application task
 
*/
static void dfu_confirm(gaia_transport *transport, bool success)
{
    MESSAGE_PMAKE(cfm, GAIA_DFU_CFM_T);
    cfm->transport = (GAIA_TRANSPORT *) transport;
    cfm->success = success;
    MessageSend(gaia->app_task, GAIA_DFU_CFM, cfm);
}

/*************************************************************************
NAME
    dfu_indicate
    
DESCRIPTION
    Send a GAIA_DFU_IND to the application task
 
*/
static void dfu_indicate(uint8 state)
{
    MESSAGE_PMAKE(ind, GAIA_DFU_IND_T);
    ind->transport = (GAIA_TRANSPORT *) gaia->outstanding_request;
    ind->state = state;
    MessageSend(gaia->app_task, GAIA_DFU_IND, ind);
}


/*************************************************************************
NAME
    dfu_send_state
    
DESCRIPTION
    Send a DFU State Change notification


*/
static void dfu_send_state(uint8 state)
{
    if (gaia->outstanding_request)
        send_notification(gaia->outstanding_request, GAIA_EVENT_DFU_STATE, 1, &state);

    dfu_indicate(state);
}

#ifdef HAVE_PARTITION_FILESYSTEM

/*************************************************************************
NAME
    pfs_status
    
DESCRIPTION
    Return status of given storage partition
 
*/
static partition_state pfs_status(uint8 device, uint8 partition)
{
    uint32 value = 0;
    bool ok;

    ok = PartitionGetInfo(device, partition, PARTITION_INFO_TYPE, &value) && 
            (value == PARTITION_TYPE_FILESYSTEM);
    
    GAIA_DEBUG(("gaia: pfs %u %u sts %u %lu\n", device, partition, ok, value));
    
    if (!ok)
        return PARTITION_INVALID;
        
    ok = PartitionGetInfo(device, partition, PARTITION_INFO_IS_MOUNTED, &value);
     
    GAIA_DEBUG(("gaia: pfs %u %u mnt %u %lu\n", device, partition, ok, value));
   
    if (!ok)
        return PARTITION_INVALID;
       
    if (value)
        return PARTITION_MOUNTED;
    
    return PARTITION_UNMOUNTED;
}


/*************************************************************************
NAME
    send_pfs_status
    
DESCRIPTION
    Respond to a GAIA_COMMAND_GET_STORAGE_PARTITION_STATUS command with
    details for given partition

    +--------+--------+--------+-----------------------------------+--------+
    | DEVICE |PARTIT'N|  TYPE  |                SIZE               |MOUNTED |
    +--------+--------+--------+--------+--------+--------+--------+--------+
        0        1        2        3        4        5        6        7
*/
static void send_pfs_status(gaia_transport *transport, uint8 device, uint8 partition)
{
    uint32 value;
    bool ok;
    uint8 response[8];

    ok = PartitionGetInfo(device, partition, PARTITION_INFO_TYPE, &value);

    if (ok)
    {
        response[0] = device;
        response[1] = partition;
        response[2] = value;
        
        ok = PartitionGetInfo(device, partition, PARTITION_INFO_SIZE, &value);
    }

    if (ok)
    {
        dwunpack(response + 3, value);
        ok = PartitionGetInfo(device, partition, PARTITION_INFO_IS_MOUNTED, &value);
    }

    if (ok)
    {
        response[7] = value;

        send_success_payload(transport, GAIA_COMMAND_GET_STORAGE_PARTITION_STATUS,
            sizeof response, response);
    }

    else
        send_invalid_parameter(transport, GAIA_COMMAND_GET_STORAGE_PARTITION_STATUS);
}


/*************************************************************************
NAME
    open_storage_partition
    
DESCRIPTION
    Prepare a storage partition for writing
 
*/
static void open_storage_partition(gaia_transport *transport, uint8 *payload, uint8 payload_length)
{
    uint8 status;

    if (IsAudioBusy())
    {
        GAIA_DEBUG(("gaia: open_storage_partition - audio busy error 0x%x (0x%x)\n",(uint16)IsAudioBusy(), (uint16)&gaia->task_data ));
        status = GAIA_STATUS_INCORRECT_STATE;
    }
    else if ((payload_length != 3) && (payload_length != 7))
    /*  may or may not have 32-bit CRC  */
        status = GAIA_STATUS_INVALID_PARAMETER;

    else if ((payload[0] != PARTITION_SERIAL_FLASH) || (payload[2] != GAIA_PFS_MODE_OVERWRITE))
    /*  Currently we can only overwrite, and it has to be ext flash  */
        status = GAIA_STATUS_INVALID_PARAMETER;
    
    else if ((gaia->pfs_state != PFS_NONE) || (gaia->outstanding_request != NULL))
    /*  We support only one stream  */
        status = GAIA_STATUS_INSUFFICIENT_RESOURCES;

    else if (pfs_status(payload[0], payload[1]) != PARTITION_UNMOUNTED)
    /*  The partition must be a filesystem and must be unmounted  */
        status = GAIA_STATUS_INCORRECT_STATE;
        
    else
    {               
        bool ok; 
        
        GAIA_DEBUG(("gaia: open_storage_partition - set audio busy\n"));
        SetAudioBusy(&gaia->task_data);
       
        GAIA_DEBUG(("gaia: start overwrite sink %lu\n", VmGetClock()));
        gaia->pfs.sink = StreamPartitionOverwriteSink(payload[0], payload[1]);
        GAIA_DEBUG(("gaia: finish overwrite sink %lu\n", VmGetClock()));

        if (payload_length == 3)
            ok = PartitionSetMessageDigest(gaia->pfs.sink, PARTITION_MESSAGE_DIGEST_SKIP, NULL, 0);
        
        else
        {
            uint32 crc;
            crc = payload[3];
            crc = (crc << 8) | payload[4];
            crc = (crc << 8) | payload[5];
            crc = (crc << 8) | payload[6];
         
            GAIA_DEBUG(("gaia: write pfs crc %lu\n", crc));
                 
            ok = PartitionSetMessageDigest(gaia->pfs.sink, PARTITION_MESSAGE_DIGEST_CRC, (uint16 *) &crc, sizeof crc);
        }
        
        if (ok)
        {
            uint8 payload;
            
            gaia->outstanding_request = transport;
            MessageSinkTask(gaia->pfs.sink, &gaia->task_data);
            
            gaia->pfs_sequence = 0;
            gaia->pfs_state = PFS_PARTITION;
            payload = ++gaia->pfs_open_stream;            
            
            GAIA_DEBUG(("gaia: pfs slack=%u\n", SinkSlack(gaia->pfs.sink)));
            status = GAIA_STATUS_SUCCESS;
            send_success_payload(transport, GAIA_COMMAND_OPEN_STORAGE_PARTITION, 1, &payload);
        }
        
        else
        {
            SetAudioBusy(NULL);
            status = GAIA_STATUS_INSUFFICIENT_RESOURCES;
        }
    }
    
    if (status != GAIA_STATUS_SUCCESS)
    {
        send_simple_response(transport, GAIA_COMMAND_OPEN_STORAGE_PARTITION, status);
    }
}


/*************************************************************************
NAME
    mount_storage_partition
    
DESCRIPTION
    Mount a storage partition
 
    The payload holds three octets corresponding to the three word arguments
    of PartitionMountFilesystem()
    
    +--------+--------+--------+
    | DEVICE |PARTIT'N|PRIORITY|
    +--------+--------+--------+
        0        1        2     
*/
static void mount_storage_partition(gaia_transport *transport, uint8 *payload, uint8 payload_length)
{
    uint8 status = GAIA_STATUS_INVALID_PARAMETER;
    
    if (payload_length == 3)
    {
        switch (pfs_status(payload[0], payload[1]))
        {
        case PARTITION_UNMOUNTED:
            if (PartitionMountFilesystem(payload[0], payload[1], payload[2]))
            {
                send_success_payload(transport, GAIA_COMMAND_MOUNT_STORAGE_PARTITION, 3, payload);
                status = GAIA_STATUS_SUCCESS;
            }
            
            else
                status = GAIA_STATUS_INSUFFICIENT_RESOURCES;
            
            break;
            
        case PARTITION_MOUNTED:
            status = GAIA_STATUS_INCORRECT_STATE;
            break;
            
        case PARTITION_INVALID:
            break;
       }
    }
    
    if (status != GAIA_STATUS_SUCCESS)
        send_simple_response(transport, GAIA_COMMAND_MOUNT_STORAGE_PARTITION, status);
}


/*************************************************************************
NAME
    write_partition_data
    
DESCRIPTION
    Write data to partition
 
*/
static void write_partition_data(gaia_transport *transport, uint8 *payload, uint8 length)
{
    uint8 response[5];
    uint8 status = GAIA_STATUS_SUCCESS;

    if ((length < 5) || (payload[0] != gaia->pfs_open_stream))
        status = GAIA_STATUS_INVALID_PARAMETER;

    else if (gaia->pfs_state != PFS_PARTITION)
        status = GAIA_STATUS_INCORRECT_STATE;

    else
    {
        uint32 sequence;

        sequence = payload[1];
        sequence = (sequence << 8) | payload[2];
        sequence = (sequence << 8) | payload[3];
        sequence = (sequence << 8) | payload[4];

        GAIA_DEBUG(("gaia: write pfs %lu\n", sequence));

        if (sequence != gaia->pfs_sequence)
            status = GAIA_STATUS_INVALID_PARAMETER;

        else
        {
            uint16 data_length = length - 5;
            
            response[0] = gaia->pfs_open_stream;
            dwunpack(response + 1, sequence);

            if (data_length)
            {
                if (SinkClaim(gaia->pfs.sink, data_length) == BAD_SINK_CLAIM)
                    status = GAIA_STATUS_INSUFFICIENT_RESOURCES;

                else
                {
                    memcpy(SinkMap(gaia->pfs.sink), payload + 5, data_length);
                    SinkFlush(gaia->pfs.sink, data_length);
                }
            }
        }
    }

    if (status == GAIA_STATUS_SUCCESS)
    {
        send_success_payload(transport, GAIA_COMMAND_WRITE_STORAGE_PARTITION, 5, response);
        ++gaia->pfs_sequence;
    }

    else
    {
        if (IsAudioBusy() == &gaia->task_data)
        {
            GAIA_DEBUG(("gaia: write_partition_data - clear audio busy\n"));
            SetAudioBusy(NULL);
        }
        send_simple_response(transport, GAIA_COMMAND_WRITE_STORAGE_PARTITION, status);
    }
}


/*************************************************************************
NAME
    close_storage_partition
    
DESCRIPTION
    Close the open storage partition
 
*/
static void close_storage_partition(gaia_transport *transport)
{
    uint8 status;
   
    GAIA_DEBUG(("gaia: close pfs\n"));
    
    if (gaia->pfs_state == PFS_PARTITION)
    {
        if (SinkClose(gaia->pfs.sink))
            status = GAIA_STATUS_SUCCESS;
        
        else
            status = GAIA_STATUS_INSUFFICIENT_RESOURCES;
    }    
    else
        status = GAIA_STATUS_INCORRECT_STATE;
        
    if (IsAudioBusy() == &gaia->task_data)
    {
        GAIA_DEBUG(("gaia: close_storage_partition - clear audio busy\n"));
        SetAudioBusy(NULL);
    }
    
    if (status != GAIA_STATUS_SUCCESS)
    {
        uint8 response = gaia->pfs_open_stream;
        send_ack(transport, GAIA_VENDOR_CSR, GAIA_COMMAND_CLOSE_STORAGE_PARTITION, 
             status, 1, &response);
    }
    
    
}

#ifdef HAVE_DFU_FROM_SQIF
/*************************************************************************
NAME
    dfu_begin
    
DESCRIPTION
    Prepare a storage partition for DFU
 
*/
static void dfu_begin(gaia_transport *transport, uint8 *payload, uint8 payload_length)
{        
    uint8 status;
    bool ok = FALSE; 


    if (gaia->dfu_state != DFU_READY)
    {
        GAIA_DEBUG(("gaia: dfu_begin: not ready\n"));
        status = GAIA_STATUS_INCORRECT_STATE;
    }

    else
    {
        dfu_reset_timeout(0);

        if (IsAudioBusy())
        {
            GAIA_DEBUG(("gaia: dfu_begin: audio busy\n"));
            status = GAIA_STATUS_INCORRECT_STATE;
        }
    
        else if (payload_length != 8)
            status = GAIA_STATUS_INVALID_PARAMETER;
    
        else if ((gaia->pfs_state != PFS_NONE) || (gaia->outstanding_request != NULL))
        /*  We support only one stream  */
            status = GAIA_STATUS_INSUFFICIENT_RESOURCES;
    
        else
        {
            uint32 crc;
            uint32 size;
            uint32 space;
                        
            size = payload[0];
            size = (size << 8) | payload[1];
            size = (size << 8) | payload[2];
            size = (size << 8) | payload[3];
     
            if (PartitionGetInfo(PARTITION_SERIAL_FLASH, gaia->pfs_open_stream, PARTITION_INFO_SIZE, &space))
            {
            /*  Partition size is in words, image size is in bytes */
                space = 2 * (space - DFU_PARTITION_OVERHEAD);
            }
            
            else
            {
                space = 0;
            }
            
            
            if (size > space)
            {
                GAIA_DEBUG(("gaia: dfu_begin: size %lu > space %lu\n", size, space));
                ok = FALSE;
            }
            
            else
            {
                SetAudioBusy(&gaia->task_data);
               
                crc = VmGetClock(); /* stack is precious */
                gaia->pfs.sink = StreamPartitionOverwriteSink(PARTITION_SERIAL_FLASH, gaia->pfs_open_stream);
                GAIA_DEBUG(("gaia: dfu_begin %lu\n", VmGetClock() - crc));
        
                ok = gaia->pfs.sink != NULL;
            }
            
            if (ok)
            {
                GAIA_DEBUG(("gaia: dfu_begin overwrite %u OK\n", gaia->pfs_open_stream));

                crc = payload[4];
                crc = (crc << 8) | payload[5];
                crc = (crc << 8) | payload[6];
                crc = (crc << 8) | payload[7];
                   
                gaia->pfs_raw_size = size;
    
                GAIA_DEBUG(("gaia: dfu_begin: size=%lu space=%lu CRC=0x%08lX\n", size, space, crc));
                     
                ok = PartitionSetMessageDigest(gaia->pfs.sink, PARTITION_MESSAGE_DIGEST_CRC, (uint16 *) &crc, sizeof crc);
            }

            if (ok)
            {
                gaia->outstanding_request = transport;
                
                MessageSinkTask(gaia->pfs.sink, &gaia->task_data);
                
                gaia->pfs_state = PFS_DFU;
                dfu_reset_timeout(DFU_PACKET_TIMEOUT);
                
                GAIA_DEBUG(("gaia: pfs slack=%u\n", SinkSlack(gaia->pfs.sink)));
                status = GAIA_STATUS_SUCCESS;
            }
            
            else
            {
                GAIA_DEBUG(("gaia: dfu_begin FAIL\n"));
                SetAudioBusy(NULL);
                status = GAIA_STATUS_INSUFFICIENT_RESOURCES;
            }
        }
    }  
    
    send_simple_response(transport, GAIA_COMMAND_DFU_BEGIN, status);

    if (ok)
    {
        gaia->dfu_state = DFU_DOWNLOAD;
        dfu_send_state(GAIA_DFU_STATE_DOWNLOAD);
    }

    else
    {
        gaia->dfu_state = DFU_IDLE;
        dfu_indicate(GAIA_DFU_STATE_DOWNLOAD_FAILURE);
    }
}
#endif /* def HAVE_DFU_FROM_SQIF */
#endif /* def HAVE_PARTITION_FILESYSTEM */

/*************************************************************************
NAME
    open_file
    
DESCRIPTION
    Prepare a file for reading
 
*/
static void open_file(gaia_transport *transport, uint8 *payload, uint8 payload_length)
{
    uint8 status;

    if ((payload_length < 2) || (payload[0] != GAIA_PFS_MODE_READ))
        status = GAIA_STATUS_INVALID_PARAMETER;
    
    else if (gaia->pfs_state != PFS_NONE)
    /*  We support only one stream  */
        status = GAIA_STATUS_INSUFFICIENT_RESOURCES;

    else
    {               
        FILE_INDEX file = FileFind(FILE_ROOT, (char *) (payload + 1), payload_length - 1);
        
        if (file == FILE_NONE)
            status = GAIA_STATUS_INVALID_PARAMETER;
        
        else
        {
            gaia->pfs.source = StreamFileSource(file);
            if (gaia->pfs.source == NULL)
                status = GAIA_STATUS_INSUFFICIENT_RESOURCES;
            
            else
            {
                uint8 payload;
                
                gaia->pfs_sequence = 0;
                gaia->pfs_state = PFS_FILE;
                payload = ++gaia->pfs_open_stream;            
                
                send_success_payload(transport, GAIA_COMMAND_OPEN_FILE, 1, &payload);
                
                status = GAIA_STATUS_SUCCESS;
            }
        }
    }
    
    if (status != GAIA_STATUS_SUCCESS)
        send_simple_response(transport, GAIA_COMMAND_OPEN_FILE, status);
}


/*************************************************************************
NAME
    read_file
    
DESCRIPTION
    Read and send a packetful of data from the open file

    |<----------- File packet header ----------->| <- File data -->|
    +--------+--------+--------+--------+--------+--------+--/ /---+
    | STREAM |              SEQUENCE             |  DATA     ...   |
    +--------+--------+--------+--------+--------+--------+--/ /---+
         0        1        2        3        4        5      ...
*/
static void read_file(gaia_transport *transport, uint8 *payload, uint8 payload_length)
{
    uint8 status;

    if ((payload_length != 5) || (payload[0] != gaia->pfs_open_stream))
        status = GAIA_STATUS_INVALID_PARAMETER;

    else if (gaia->pfs_state != PFS_FILE)
        status = GAIA_STATUS_INCORRECT_STATE;

    else 
    {
        uint32 sequence;
        uint8 *response;

        sequence = payload[1];
        sequence = (sequence << 8) | payload[2];
        sequence = (sequence << 8) | payload[3];
        sequence = (sequence << 8) | payload[4];

        GAIA_DEBUG(("gaia: read file %lu\n", sequence));

        if (sequence != gaia->pfs_sequence)
            status = GAIA_STATUS_INVALID_PARAMETER;

        else
        {
            response = malloc(FILE_PACKET_HEADER_SIZE + FILE_BUFFER_SIZE);
            
            if (response == NULL)
                status = GAIA_STATUS_INSUFFICIENT_RESOURCES;
            
            else
            {
                uint16 length = SourceSize(gaia->pfs.source);
                
                if (length)                
                {
                    const uint8 *data = SourceMap(gaia->pfs.source);
                    
                    if (length > FILE_BUFFER_SIZE)
                        length = FILE_BUFFER_SIZE;
                    
                    memcpy(response + FILE_PACKET_HEADER_SIZE, data, length);
                    SourceDrop(gaia->pfs.source, length);
                }

                response[0] = gaia->pfs_open_stream;
                dwunpack(response + 1, sequence);
                send_success_payload(transport, GAIA_COMMAND_READ_FILE, FILE_PACKET_HEADER_SIZE + length, response);
                
                free(response);
                ++gaia->pfs_sequence;
                    
                status = GAIA_STATUS_SUCCESS;
            }
        }
    }
    
    if (status != GAIA_STATUS_SUCCESS)
        send_simple_response(transport, GAIA_COMMAND_READ_FILE, status);
}


/*************************************************************************
NAME
    close_file
    
DESCRIPTION
    Close the open data file
 
*/
static void close_file(gaia_transport *transport)
{
    uint8 response = gaia->pfs_open_stream;
    uint8 status = GAIA_STATUS_SUCCESS;
   
    GAIA_DEBUG(("gaia: close file\n"));
    
    if (gaia->pfs_state == PFS_FILE)
    {
        if (SourceClose(gaia->pfs.source))
            gaia->pfs_state = PFS_NONE;
            
        else
            status = GAIA_STATUS_INSUFFICIENT_RESOURCES;
    }
    
    else
        status = GAIA_STATUS_INCORRECT_STATE;
    
    send_ack(transport, GAIA_VENDOR_CSR, GAIA_COMMAND_CLOSE_FILE, 
             status, 1, &response);
}


/*************************************************************************
NAME
    gaia_handle_data_transfer_command
    
DESCRIPTION
    Handle a Data Transfer command or return FALSE if we can't
 
*/
static bool gaia_handle_data_transfer_command(gaia_transport *transport,
    uint16 command_id, uint8 payload_length, uint8 *payload)
{
#ifdef HAVE_PARTITION_FILESYSTEM

    GAIA_DEBUG(("gaia: PFS %u\n", gaia->have_pfs));

    if(gaia->have_pfs)
    {
        switch (command_id)
        {
        case GAIA_COMMAND_GET_STORAGE_PARTITION_STATUS:
            if (payload_length == 2)
                send_pfs_status(transport, payload[0], payload[1]);

            else
                send_invalid_parameter(transport, command_id);

            return TRUE;


        case GAIA_COMMAND_OPEN_STORAGE_PARTITION:
            open_storage_partition(transport, payload, payload_length);
            return TRUE;


        case GAIA_COMMAND_MOUNT_STORAGE_PARTITION:
            mount_storage_partition(transport, payload, payload_length);
            return TRUE;
        

        case GAIA_COMMAND_WRITE_STORAGE_PARTITION:
            write_partition_data(transport, payload, payload_length);
            return TRUE;


        case GAIA_COMMAND_CLOSE_STORAGE_PARTITION:
            if ((payload_length == 1) && (payload[0] == gaia->pfs_open_stream))
                close_storage_partition(transport);
        
            else
                send_invalid_parameter(transport, command_id);
            
            return TRUE;


        case GAIA_COMMAND_DFU_REQUEST | GAIA_ACK_MASK:
            if (gaia->dfu_state == DFU_WAITING)
            {
                bool ok = (payload_length == 1) && (payload[0] == GAIA_STATUS_SUCCESS);
                
                if (ok)
                    gaia->dfu_state = DFU_READY;
                    
                else
                {
                    dfu_reset_timeout(0);
                    gaia->dfu_state = DFU_IDLE;
                }

                    
                dfu_confirm(transport, ok);
            }
            return TRUE;

#ifdef HAVE_DFU_FROM_SQIF
        case GAIA_COMMAND_DFU_BEGIN:
            dfu_begin(transport, payload, payload_length);
            return TRUE;
#endif
        }
    } 
#endif /* def HAVE_PARTITION_FILESYSTEM */
    
    switch (command_id)
    {
    case GAIA_COMMAND_OPEN_FILE:
        open_file(transport, payload, payload_length);
        return TRUE;
    
        
    case GAIA_COMMAND_READ_FILE:
        read_file(transport, payload, payload_length);
        return TRUE;

    
    case GAIA_COMMAND_CLOSE_FILE:
        if ((payload_length == 1) && (payload[0] == gaia->pfs_open_stream))
            close_file(transport);
        
        else
            send_invalid_parameter(transport, command_id);

		return TRUE;
    }

    return FALSE;
}

/*************************************************************************
NAME
    validate_payload_length
    
DESCRIPTION
    Check that the Gaia command payload is within the expected range.
    Returns TRUE if so, otherwise responds immediately with
    GAIA_STATUS_INVALID_PARAMETER and returns FALSE
*/
static bool validate_payload_length(gaia_transport *transport, uint16 command_id, uint8 length, uint8 min, uint8 max)
{
    if ((length < min) || (length > max))
    {
        send_invalid_parameter(transport, command_id);
        return FALSE;
    }
    
    return TRUE;
}
    

/*************************************************************************
NAME
    ps_retrieve
    
DESCRIPTION
    Process Gaia Debugging Commands GAIA_COMMAND_RETRIEVE_PS_KEY and
    GAIA_COMMAND_RETRIEVE_FULL_PS_KEY
*/
static void ps_retrieve(gaia_transport *transport, uint16 command_id, uint16 key)
{
    uint16 key_length;
    
    if (command_id == GAIA_COMMAND_RETRIEVE_FULL_PS_KEY)    
        key_length = PsFullRetrieve(key, NULL, 0);
    
    else
        key_length = PsRetrieve(key, NULL, 0);
    
    if (key_length == 0)
        send_invalid_parameter(transport, command_id);

    else
    {
        uint16 *key_data = malloc(key_length + 1);
        
        if (key_data)
        {
            if (command_id == GAIA_COMMAND_RETRIEVE_FULL_PS_KEY)    
                PsFullRetrieve(key, key_data + 1, key_length);
    
            else
                PsRetrieve(key, key_data + 1, key_length);
           
            *key_data = key;
                
            send_ack_16(transport, GAIA_VENDOR_CSR, command_id, GAIA_STATUS_SUCCESS,
                                 key_length + 1, key_data);
            free(key_data);
        }

        else
            send_insufficient_resources(transport, command_id);
    }    
}


/*************************************************************************
NAME
    store_ps_key
    
DESCRIPTION
    Process Gaia Debugging Command GAIA_COMMAND_STORE_PS_KEY
*/
static void store_ps_key(gaia_transport *transport, uint16 payload_length, uint8 *payload)
{
    uint16 status;
    
    if (((payload_length & 1) != 0) || (payload_length < 2))
        status = GAIA_STATUS_INVALID_PARAMETER;
    
    else
    {
        uint16 key_index = W16(payload);
        uint16 *packed_key = malloc(payload_length / 2);
                   
        if (!packed_key)
            status = GAIA_STATUS_INSUFFICIENT_RESOURCES;
        
        else
        {
            uint16 key_length = (payload_length - 2) / 2;
            uint16 ps_length;
            
            wpack(packed_key, payload + 2, key_length);
            
            ps_length = PsStore(key_index, packed_key, key_length);
            free(packed_key);
            
            if (key_length && !ps_length)
                status = GAIA_STATUS_INSUFFICIENT_RESOURCES;
            
            else
                status = GAIA_STATUS_SUCCESS;
        }    
    }
    
    send_simple_response(transport, GAIA_COMMAND_STORE_PS_KEY, status);
}


/*************************************************************************
NAME
    get_memory_slots
    
DESCRIPTION
    Process Gaia Debugging Command GAIA_COMMAND_GET_MEMORY_SLOTS
    Responds with the number of malloc() slots and the amount of
    writable storage available for PS keys
*/
static void get_memory_slots(gaia_transport *transport)
{
    uint16 malloc_slots = VmGetAvailableAllocations();
    uint16 ps_space = PsFreeCount(0);
    uint8 payload[4];
    
    payload[0] = HIGH(malloc_slots);
    payload[1] = LOW(malloc_slots);
    
    payload[2] = HIGH(ps_space);
    payload[3] = LOW(ps_space);
    
    send_success_payload(transport, GAIA_COMMAND_GET_MEMORY_SLOTS, 4, payload);
}


/*************************************************************************
NAME
    send_kalimba_message
    
DESCRIPTION
    Send an arbitrary (short) message to the Kalimba DSP
*/
static void send_kalimba_message(gaia_transport *transport, uint8 *payload)
{
    if (KalimbaSendMessage(
        (payload[0] << 8) | payload[1],
        (payload[2] << 8) | payload[3],
        (payload[4] << 8) | payload[5],
        (payload[6] << 8) | payload[7],
        (payload[8] << 8) | payload[9]))
    {
    /*  Respond immediately -- we don't handle MESSAGE_FROM_KALIMBA here (yet)  */
        send_success(transport, GAIA_COMMAND_SEND_KALIMBA_MESSAGE);
    }

    else
    {
        send_insufficient_resources(transport, GAIA_COMMAND_SEND_KALIMBA_MESSAGE);
    }
}


/*************************************************************************
NAME
    gaia_handle_debug_command
    
DESCRIPTION
    Handle a debugging command or return FALSE if we can't
*/
static bool gaia_handle_debug_command(gaia_transport *transport, uint16 command_id, 
                                      uint8 payload_length, uint8 *payload)
{
    switch (command_id)
    {
    case GAIA_COMMAND_NO_OPERATION:
        send_success(transport, GAIA_COMMAND_NO_OPERATION);
        return TRUE;
                        
    case GAIA_COMMAND_RETRIEVE_PS_KEY:
    case GAIA_COMMAND_RETRIEVE_FULL_PS_KEY:
        if (validate_payload_length(transport, command_id, payload_length, 2, 2))
            ps_retrieve(transport, command_id, W16(payload));
            
        return TRUE;
                
    case GAIA_COMMAND_STORE_PS_KEY:
        store_ps_key(transport, payload_length, payload);
        return TRUE;
                
    case GAIA_COMMAND_FLOOD_PS:
        PsFlood();
        send_success(transport, GAIA_COMMAND_FLOOD_PS);
        return TRUE;
        
    case GAIA_COMMAND_GET_MEMORY_SLOTS:
        get_memory_slots(transport);
        return TRUE;
     
    case GAIA_COMMAND_DELETE_PDL:
        ConnectionSmDeleteAllAuthDevices(0);
        send_success(transport, GAIA_COMMAND_DELETE_PDL);
        return TRUE;

    case GAIA_COMMAND_SEND_APPLICATION_MESSAGE:
        if (validate_payload_length(transport, command_id, payload_length, 2, 2))
            MessageSend(gaia->app_task, W16(payload), NULL);
            
        return TRUE;
        
    case GAIA_COMMAND_SEND_KALIMBA_MESSAGE:
        if (validate_payload_length(transport, command_id, payload_length, 10, 10))
            send_kalimba_message(transport, payload);

        return TRUE;
    }
    
    return FALSE;
}


/*************************************************************************
NAME
    gaia_handle_notification_command
    
DESCRIPTION
    Handle a debugging command or return FALSE if we can't
*/
static bool gaia_handle_notification_command(gaia_transport *transport, uint16 command_id, 
                                             uint8 payload_length, uint8 *payload)
{
    switch (command_id)
    {
    case GAIA_COMMAND_REGISTER_NOTIFICATION:
        if (payload_length == 0)
            send_invalid_parameter(transport, GAIA_COMMAND_REGISTER_NOTIFICATION);
        
        else if (GaiaGetAppWillHandleNotification(payload[0]))
            return FALSE;
            
        else 
            register_notification(transport, payload_length, payload);
        
        return TRUE;
       
    case GAIA_COMMAND_GET_NOTIFICATION:
        if (payload_length != 1)
            send_invalid_parameter(transport, GAIA_COMMAND_GET_NOTIFICATION);
        
        else if (GaiaGetAppWillHandleNotification(payload[0]))
            return FALSE;
            
        else 
            send_notification_setting(transport, payload[0]);
        
        return TRUE;

    case GAIA_COMMAND_CANCEL_NOTIFICATION:
        if (payload_length != 1)
            send_invalid_parameter(transport, GAIA_COMMAND_CANCEL_NOTIFICATION);
        
        else if (GaiaGetAppWillHandleNotification(payload[0]))
            return FALSE;
            
        else 
            cancel_notification(transport, payload[0]);
        
        return TRUE;
                
    case GAIA_ACK_NOTIFICATION:
        if ((payload_length > 0) && GaiaGetAppWillHandleNotification(payload[0]))
            return FALSE;
                   
        return TRUE;
    }
    
    return FALSE;
}


/*************************************************************************
NAME
    check_enable
    
DESCRIPTION
    Validate SESSION_ENABLE credentials
*/
static bool check_enable(gaia_transport *transport, uint16 vendor_id, uint16 command_id, uint8 payload_length, uint8 *payload)
{
    uint16 usb_vid;
    bool ok;
    
    if (command_id & GAIA_ACK_MASK)
        ok = TRUE;
        
    else if (vendor_id != GAIA_VENDOR_CSR) 
        ok = FALSE;
        
    else if (command_id == GAIA_COMMAND_GET_SESSION_ENABLE)
        ok = TRUE;
        
    else if ((command_id != GAIA_COMMAND_SET_SESSION_ENABLE) ||
        (payload_length != 3))
        ok = FALSE;
        
    else if (PsFullRetrieve(PSKEY_USB_VENDOR_ID, &usb_vid, 1) == 0)
        ok = FALSE;
    
    else if (W16(payload + 1) != usb_vid)
        ok = FALSE;
              
    else
        ok = TRUE;
    
    GAIA_DEBUG(("gaia: %04X:%04X en %u\n", vendor_id, command_id, ok));
    return ok;
}


/*************************************************************************
NAME
    process_packet
    
DESCRIPTION
    Analyse an inbound command packet and either do something based on
    the vendor and command identifiers or pass it up as unhandled
*/
void process_packet(gaia_transport *transport, uint8 *packet)
{
/*  0 bytes  1        2        3        4        5        6        7        8      len+8      len+9
 *  +--------+--------+--------+--------+--------+--------+--------+--------+ +--------+--/ /---+ +--------+
 *  |  SOF   |VERSION | FLAGS  | LENGTH |    VENDOR ID    |   COMMAND ID    | | PAYLOAD   ...   | | CHECK  |
 *  +--------+--------+--------+--------+--------+--------+--------+--------+ +--------+--/ /---+ +--------+
 */
    uint8 protocol_version = packet[GAIA_OFFS_VERSION];
    uint8 payload_length = packet[GAIA_OFFS_PAYLOAD_LENGTH];
    uint16 vendor_id = W16(packet + GAIA_OFFS_VENDOR_ID);
    uint16 command_id = W16(packet + GAIA_OFFS_COMMAND_ID);
    uint8 *payload = packet + GAIA_OFFS_PAYLOAD;
    
    if (gaia->rebooting)
        send_ack(transport, vendor_id, command_id, GAIA_STATUS_INCORRECT_STATE, 0, NULL);

    else if (protocol_version == GAIA_VERSION)
    {
        bool handled;
        
        if (!transport->enabled)
        {
            if (!check_enable(transport, vendor_id, command_id, payload_length, payload))
            {
                send_incorrect_state(transport, command_id);
                return;
            }
        }

        if (vendor_id == GAIA_VENDOR_CSR)
            handled = !app_will_handle_command(command_id);
        
        else
            handled = FALSE;
        
        GAIA_CMD_DEBUG(("gaia: <- %04x:%04x %c\n", vendor_id, command_id, handled ? 'L' : 'A'));
    
        if (handled)
        {
            switch (command_id & GAIA_COMMAND_TYPE_MASK)
            {
            case GAIA_COMMAND_TYPE_CONTROL:
                handled = gaia_handle_control_command(transport, command_id, payload_length, payload);
                break;
                
            case GAIA_COMMAND_TYPE_STATUS:
                handled = gaia_handle_status_command(transport, command_id, payload_length, payload);
                break;
                
            case GAIA_COMMAND_TYPE_FEATURE:
                handled = gaia_handle_feature_command(transport, command_id, payload_length, payload);
                break;
                
            case GAIA_COMMAND_TYPE_DATA_TRANSFER:
                handled = gaia_handle_data_transfer_command(transport, command_id, payload_length, payload);
                break;
                
            case GAIA_COMMAND_TYPE_DEBUG:
                handled = gaia_handle_debug_command(transport, command_id, payload_length, payload);
                break;

            case GAIA_COMMAND_TYPE_NOTIFICATION:
                handled = gaia_handle_notification_command(transport, command_id, payload_length, payload);
                break;
                
            default:
                handled = FALSE;
                break;
            }   
        }
        
        if (!handled)
        {
        /*  Pass it on sans the start-of-frame and checksum bytes  */
            GAIA_UNHANDLED_COMMAND_IND_T *gunk = malloc(sizeof (GAIA_UNHANDLED_COMMAND_IND_T) + payload_length);
            
            GAIA_CMD_DEBUG(("gaia: unhandled command\n"));
            
            if (gunk)
            {
                gunk->transport = (GAIA_TRANSPORT *) transport;
                gunk->protocol_version = protocol_version;
                gunk->size_payload = payload_length;
                gunk->vendor_id = vendor_id;
                gunk->command_id = command_id;
                
                if (payload_length > 0)
                    memcpy(gunk->payload, payload, payload_length);
                
                MessageSend(gaia->app_task, GAIA_UNHANDLED_COMMAND_IND, gunk);
            }
            
            else
                send_ack(transport, vendor_id, command_id, GAIA_STATUS_INSUFFICIENT_RESOURCES, 0, NULL);
        }
    }
}


/*************************************************************************
NAME
    update_battery_voltage
    
DESCRIPTION
    Calculate the battery voltage from the ADC readings.  Use double
    exponential smoothing to keep the noise down
*/
static void update_battery_voltage(uint16 reading)
{
    if (gaia->battery_reference != 0)
    {
#ifdef GAIA_BATTERY_NO_SMOOTHING
        gaia->battery_voltage = (((uint32) VmReadVrefConstant()) * reading) / gaia->battery_reference;
        GAIA_THRES_DEBUG(("gaia: vbat %d\n", gaia->battery_voltage));
#else
        uint16 voltage = (((uint32) VmReadVrefConstant()) * reading) / gaia->battery_reference;
        
        if (gaia->battery_voltage == 0)
        {
            gaia->battery_voltage = voltage;
            gaia->battery_trend = 0;
        }
        
        else
        {
            int16 old = gaia->battery_voltage;
            gaia->battery_voltage = (9L * old + gaia->battery_trend + voltage + 5) / 10;
            gaia->battery_trend = (gaia->battery_trend + gaia->battery_voltage - old) / 2;
        }
            
        GAIA_THRES_DEBUG(("gaia: vbat %d trend %d ave %d\n", 
            voltage, gaia->battery_trend, gaia->battery_voltage));
#endif
    }
}



/*************************************************************************
NAME
    check_battery_thresholds
    
DESCRIPTION
    Called periodically to see if the battery voltage has reached one of
    the notification thresholds
*/
static void check_battery_thresholds(gaia_transport *transport)
{
    if (gaia->battery_voltage != 0)
    {
        bool notify = FALSE;            
        
    /*  Check low thresholds  */
        if ((transport->threshold_count_lo_battery > 0) 
            && (gaia->battery_voltage <= transport->battery_lo_threshold[0]) 
            && !transport->sent_notification_lo_battery_0)
        {
            notify = TRUE;
            transport->sent_notification_lo_battery_0 = TRUE;
        }
    
        else if (transport->sent_notification_lo_battery_0 
            && (gaia->battery_voltage > transport->battery_lo_threshold[0] + GAIA_BATT_HYSTERESIS))
            transport->sent_notification_lo_battery_0 = FALSE;
                                                 
        if ((transport->threshold_count_lo_battery > 1) 
            && (gaia->battery_voltage <= transport->battery_lo_threshold[1]) 
            && !transport->sent_notification_lo_battery_1)
        {
            notify = TRUE;
            transport->sent_notification_lo_battery_1 = TRUE;
        }
        
        else if (transport->sent_notification_lo_battery_1
            && (gaia->battery_voltage > transport->battery_lo_threshold[1] + GAIA_BATT_HYSTERESIS))
            transport->sent_notification_lo_battery_1 = FALSE;
        
        GAIA_THRES_DEBUG(("gaia: chk bat lo %d (%d %d) %d\n", 
               gaia->battery_voltage, 
               transport->battery_lo_threshold[0], 
               transport->battery_lo_threshold[1], 
               notify));
        
        if (notify)
        {
            uint8 payload[2];
            
            payload[0] = HIGH(gaia->battery_voltage);
            payload[1] = LOW(gaia->battery_voltage);
            
            send_notification(transport, GAIA_EVENT_BATTERY_LOW_THRESHOLD, 2, payload);
        }
        
    /*  Check high thresholds  */
        notify = FALSE;
        
        if ((transport->threshold_count_hi_battery > 0) 
            && (gaia->battery_voltage >= transport->battery_hi_threshold[0]) 
            && !transport->sent_notification_hi_battery_0)
        {
            notify = TRUE;
            transport->sent_notification_hi_battery_0 = TRUE;
        }
    
        else if (transport->sent_notification_hi_battery_0 
            && (gaia->battery_voltage < transport->battery_hi_threshold[0] - GAIA_BATT_HYSTERESIS))
            transport->sent_notification_hi_battery_0 = FALSE;
                                                 
        if ((transport->threshold_count_hi_battery > 1) 
            && (gaia->battery_voltage >= transport->battery_hi_threshold[1]) 
            && !transport->sent_notification_hi_battery_1)
        {
            notify = TRUE;
            transport->sent_notification_hi_battery_1 = TRUE;
        }
        
        else if (transport->sent_notification_hi_battery_1 
            && (gaia->battery_voltage < transport->battery_hi_threshold[1] - GAIA_BATT_HYSTERESIS))
            transport->sent_notification_hi_battery_1 = FALSE;
        
        GAIA_THRES_DEBUG(("gaia: chk batt hi %d (%d %d) %d\n", 
               gaia->battery_voltage, 
               transport->battery_hi_threshold[0], 
               transport->battery_hi_threshold[1], 
               notify));
        
        if (notify)
        {
            uint8 payload[2];
            
            payload[0] = HIGH(gaia->battery_voltage);
            payload[1] = LOW(gaia->battery_voltage);
            
            send_notification(transport, GAIA_EVENT_BATTERY_HIGH_THRESHOLD, 2, payload);
        }
    }
}
                

/*************************************************************************
NAME
    check_rssi_thresholds
    
DESCRIPTION
    Called periodically to see if the RSSI has reached one of the
    notification thresholds
*/
static void check_rssi_thresholds(gaia_transport *transport)
{
    bool notify = FALSE;
    int16 rssi = 0;
    
    /* get the current RSSI */
    SinkGetRssi(gaiaTransportGetSink(transport), &rssi);
    
    /*  Check low thresholds  */
    if ((transport->threshold_count_lo_rssi > 0) 
        && (rssi <= transport->rssi_lo_threshold[0]) 
        && !transport->sent_notification_lo_rssi_0)
    {
        notify = TRUE;
        transport->sent_notification_lo_rssi_0 = TRUE;
    }

    else if (transport->sent_notification_lo_rssi_0 && (rssi > (transport->rssi_lo_threshold[0] + GAIA_RSSI_HYSTERESIS)))
        transport->sent_notification_lo_rssi_0 = FALSE;
                                             
    if ((transport->threshold_count_lo_rssi > 1) 
        && (rssi <= transport->rssi_lo_threshold[1]) 
        && !transport->sent_notification_lo_rssi_1)
    {
        notify = TRUE;
        transport->sent_notification_lo_rssi_1 = TRUE;
    }
    
    else if (transport->sent_notification_lo_rssi_1 && (rssi > (transport->rssi_lo_threshold[1] + GAIA_RSSI_HYSTERESIS)))
        transport->sent_notification_lo_rssi_1 = FALSE;
    
    GAIA_THRES_DEBUG(("gaia: chk RSSI lo %d (%d %d) %d\n", 
           rssi, 
           transport->rssi_lo_threshold[0], 
           transport->rssi_lo_threshold[1], 
           notify));
    
    if (notify)
    {
        uint8 payload = LOW(rssi);
        send_notification(transport, GAIA_EVENT_RSSI_LOW_THRESHOLD, 1, &payload);
    }
    
    /*  Check high thresholds  */
    notify = FALSE;
    
    if ((transport->threshold_count_hi_rssi > 0) 
        && (rssi >= transport->rssi_hi_threshold[0]) 
        && !transport->sent_notification_hi_rssi_0)
    {
        notify = TRUE;
        transport->sent_notification_hi_rssi_0 = TRUE;
    }

    else if (transport->sent_notification_hi_rssi_0 && ((rssi < transport->rssi_hi_threshold[0] - GAIA_RSSI_HYSTERESIS)))
        transport->sent_notification_hi_rssi_0 = FALSE;
                                             
    if ((transport->threshold_count_hi_rssi > 1) 
        && (rssi >= transport->rssi_hi_threshold[1]) 
        && !transport->sent_notification_hi_rssi_1)
    {
        notify = TRUE;
        transport->sent_notification_hi_rssi_1 = TRUE;
    }
    
    else if (transport->sent_notification_hi_rssi_1 && (rssi < (transport->rssi_hi_threshold[1] - GAIA_RSSI_HYSTERESIS)))
        transport->sent_notification_hi_rssi_1 = FALSE;
    
    GAIA_THRES_DEBUG(("gaia: chk RSSI hi %d (%d %d) %d\n", 
           rssi, 
           transport->rssi_hi_threshold[0], 
           transport->rssi_hi_threshold[1], 
           notify));
    
    if (notify)
    {
        uint8 payload = LOW(rssi);
        send_notification(transport, GAIA_EVENT_RSSI_HIGH_THRESHOLD, 1, &payload);
    }
}


/*************************************************************************
NAME
    register_custom_sdp
    
DESCRIPTION
    Register a custom SDP record retrieved from PS
    
    The first word in the PS data is the length after unpacking.  This
    allows us to retrieve an odd number of bytes and allows some sanity
    checking.
*/
static void register_custom_sdp(uint16 pskey)
{
    uint16 ps_length;
    
    ps_length = PsFullRetrieve(pskey, NULL, 0);
    GAIA_DEBUG(("gaia: m %04x sdp %d\n", pskey, ps_length));
    
    if (ps_length > 1)
    {
        uint16 sr_length = 2 * (ps_length - 1);
        uint16 *sr = malloc(sr_length);
                
        if (sr && PsFullRetrieve(pskey, sr, ps_length) && (sr_length - sr[0] < 2))
        {
        /*  Unpack into uint8s, preserving overlapping word  */
            uint16 idx;
            uint16 tmp = sr[1];

            sr_length = sr[0];
            for (idx = ps_length; idx > 1; )
            {
                --idx;
                sr[2 * idx - 1] = sr[idx] & 0xFF;
                sr[2 * idx - 2] = sr[idx] >> 8;
            }
            
            sr[0] = tmp >> 8;
            
            gaia->custom_sdp = TRUE;
            ConnectionRegisterServiceRecord(&gaia->task_data, sr_length, (uint8 *) sr);
        /*  NOTE: firmware will free the slot  */
        }
        
        else
        {
            free(sr);
            GAIA_DEBUG(("gaia: bad sr\n"));
        }
    }
}


/*************************************************************************
NAME
    gaia_init
    
DESCRIPTION
    Initialise the library
*/
static void gaia_init(void)
{
    MESSAGE_PMAKE(status, GAIA_INIT_CFM_T);

    /*  See lib_commands[] above; GAIA_COMMAND_POWER_OFF (index 0) handled by app  */
    gaia->command_locus_bits = 0x00000001;
    
    /*  Default API minor version (may be overridden by GaiaSetApiMinorVersion())  */
    gaia->api_minor = GAIA_API_VERSION_MINOR;

    /*  App initially responsible for all but RSSI and Battery events  */
    gaia->event_locus_bits = ~((1 << GAIA_EVENT_RSSI_LOW_THRESHOLD)
            | (1 << GAIA_EVENT_RSSI_HIGH_THRESHOLD)
            | (1 << GAIA_EVENT_BATTERY_LOW_THRESHOLD)
            | (1 << GAIA_EVENT_BATTERY_HIGH_THRESHOLD));
             
    /*  So we can use AUDIO_BUSY interlocking  */
    AudioLibraryInit();

    /*  Perform custom SDP registration */
    register_custom_sdp(PSKEY_MOD_MANUF0);
        
    /*  initialise battery voltage reference */
    AdcRequest(&gaia->task_data, adcsel_vref);

    /*  start battery monitoring */
    MessageSendLater(&gaia->task_data, GAIA_INTERNAL_BATTERY_MONITOR_TIMER, NULL, GAIA_CHECK_THRESHOLDS_PERIOD);

#ifdef HAVE_PARTITION_FILESYSTEM
    {
        uint32 pfs_type;

    /*  Probe partition 0.  We don't really care about the type, just its existence  */
        gaia->have_pfs = PartitionGetInfo(PARTITION_SERIAL_FLASH, 0, PARTITION_INFO_TYPE, &pfs_type);
    }
#endif /* def HAVE_PARTITION_FILESYSTEM */
    
    status->success = TRUE;
    MessageSend(gaia->app_task, GAIA_INIT_CFM, status);
}


/*************************************************************************
NAME
    dfu_finish
    
DESCRIPTION
    Clean up after a DFU transfer
*/
static void dfu_finish(bool success)
{
    dfu_reset_timeout(0);

    gaia->pfs_raw_size = 0;
    SinkClose(gaia->pfs.sink);
    SetAudioBusy(NULL);

    if (success)
    {
        dfu_send_state(GAIA_DFU_STATE_VERIFICATION);
    }

    else
    {
        gaia->pfs_state = PFS_NONE;
        dfu_send_state(GAIA_DFU_STATE_DOWNLOAD_FAILURE);
    }
}


/*************************************************************************
NAME
    message_handler
    
DESCRIPTION
    Handles internal messages and anything from the underlying SPP
*/
static void message_handler(Task task, MessageId id, Message message)
{
/*  If SDP registration confirmation is caused by a custom record,
    don't bother the transport handlers with it
*/
    if ((id == CL_SDP_REGISTER_CFM) && gaia->custom_sdp)
    {
        GAIA_DEBUG(("gaia: CL_SDP_REGISTER_CFM (C): %d\n", 
                    ((CL_SDP_REGISTER_CFM_T *) message)->status));
        
        gaia->custom_sdp = FALSE;
        return;
    }
    
	if (id == MESSAGE_MORE_DATA && gaia->pfs_raw_size)
	{
    /*  Data is to be copied directly to the PFS sink  */
		MessageMoreData *m = (MessageMoreData *) message;
		uint16 size = SourceSize(m->source);

		GAIA_DFU_DEBUG(("gaia: raw %u of %lu\n", size, gaia->pfs_raw_size));

        if (size)
        {
            dfu_reset_timeout(DFU_PACKET_TIMEOUT);
            
		    if (size > gaia->pfs_raw_size)
            {
		        GAIA_DEBUG(("gaia: DFU: too much data\n"));

                SourceDrop(m->source, size);
                dfu_finish(FALSE);
                return;
            }

            else
            {
                while (size)                
                {
                    uint16 chunk = (size > GAIA_RAW_CHUNK_SIZE) ? GAIA_RAW_CHUNK_SIZE : size;
                    
                    if (SinkClaim(gaia->pfs.sink, chunk) == BAD_SINK_CLAIM)
                    {
		                GAIA_DEBUG(("gaia: DFU: bad sink %u\n", chunk));
                        SourceDrop(m->source, size);
                        dfu_finish(FALSE);
                        return;
                    }

                    else
                    {
                        memcpy(SinkMap(gaia->pfs.sink), SourceMap(m->source), chunk);
                        SinkFlush(gaia->pfs.sink, chunk);
                        SourceDrop(m->source, chunk);
                    }
    
                    size -= chunk;
                    gaia->pfs_raw_size -= chunk;
                }

                if (gaia->pfs_raw_size == 0)
                {
		            GAIA_DEBUG(("gaia: DFU: transfer complete\n"));
                    dfu_finish(TRUE);
                }
            }
        }
        
		return;
	}

    /* see if a transport can handle this message */
    /* TODO handle multipoint case, loop through all transports? */
    if (gaiaTransportHandleMessage(task, id, message))
        return;

    switch (id)
    {
    case MESSAGE_ADC_RESULT:
        {
            MessageAdcResult *m = (MessageAdcResult *) message;
            GAIA_THRES_DEBUG(("gaia: adc %d = %d\n", m->adc_source, m->reading));
            switch (m->adc_source)
            {
            case adcsel_vref:
                gaia->battery_reference = m->reading;
                GAIA_THRES_DEBUG(("gaia: vref %d\n", VmReadVrefConstant()));
                break;
                
            case adcsel_vdd_sense:
            case adcsel_vdd_bat:
            /*  gaia->battery_voltage = ((uint32) VmReadVrefConstant() * m->reading) / gaia->battery_reference;  */
                update_battery_voltage(m->reading);
                
                if (gaia->outstanding_request && (gaia->pfs_state == PFS_NONE))
                {
                    send_battery_level(gaia->outstanding_request);
                    gaia->outstanding_request = NULL;
                }
                break;
                
            default:
                break;
            }
        }
        break;
        
        
    case MESSAGE_STREAM_PARTITION_VERIFY:
        {
        /*  We have finished processing a GAIA_COMMAND_CLOSE_STORAGE_PARTITION or DFU  */
            MessageStreamPartitionVerify *m = (MessageStreamPartitionVerify *) message;
            GAIA_DEBUG(("gaia: pfs %u verify %u\n", m->partition, m->verify_result));
                       
            if (gaia->outstanding_request)
            {
                if ((gaia->pfs_state == PFS_PARTITION) || (gaia->pfs_state == PFS_FILE))
                {
                    uint8 status;
                    uint8 response = gaia->pfs_open_stream;

                    if (m->verify_result == PARTITION_VERIFY_PASS)
                        status = GAIA_STATUS_SUCCESS;
                
                    else
                        status = GAIA_STATUS_INVALID_PARAMETER;
                
                    send_ack(gaia->outstanding_request, GAIA_VENDOR_CSR, GAIA_COMMAND_CLOSE_STORAGE_PARTITION,
                         status, 1, &response);
                }

                else if (gaia->pfs_state == PFS_DFU)
                {
                    if (m->verify_result == PARTITION_VERIFY_PASS)
                    {
                        gaia->rebooting = TRUE;
                        dfu_send_state(GAIA_DFU_STATE_VERIFICATION_SUCCESS);
                        MessageSendLater(&gaia->task_data, GAIA_INTERNAL_DFU_REQ, NULL, TATA_TIME);
                    }
                    
                    else
                    {
                        gaia->dfu_state = DFU_IDLE;
                        dfu_send_state(GAIA_DFU_STATE_VERIFICATION_FAILURE);
                    }
                }

                gaia->outstanding_request = NULL;
            }
            
            gaia->pfs_state = PFS_NONE; 
        }
        break;
        
#ifdef GAIA_TRANSPORT_SPP
    case SPP_CLIENT_CONNECT_CFM:
    case SPP_DISCONNECT_IND:
    case SPP_MESSAGE_MORE_DATA:
        gaiaTransportSppHandleMessage(task, id, message);
        break;

    case SPP_MESSAGE_MORE_SPACE:
        break;
#endif
        
    case GAIA_SEND_PACKET_CFM:
        {
            GAIA_SEND_PACKET_CFM_T *m = (GAIA_SEND_PACKET_CFM_T *) message;
            PRINT(("gaia: GAIA_SEND_PACKET_CFM: s=%d\n", VmGetAvailableAllocations()));
            free(m->packet);
        }
        break;
        

    case GAIA_INTERNAL_INIT:
        gaia_init();
        break;
        
        
    case GAIA_INTERNAL_SEND_REQ:
        {
            GAIA_INTERNAL_SEND_REQ_T *m = (GAIA_INTERNAL_SEND_REQ_T *) message;
            gaiaTransportSendPacket(m->task, m->transport, m->length, m->data);
        }
        break;
          
    case GAIA_INTERNAL_BATTERY_MONITOR_TIMER:
        {
            if (gaia->battery_reference == 0)  /*  vref read failed; try again  */
                AdcRequest(&gaia->task_data, adcsel_vref);
            
            else
                read_battery();
            
            MessageSendLater(&gaia->task_data, GAIA_INTERNAL_BATTERY_MONITOR_TIMER, NULL, GAIA_CHECK_THRESHOLDS_PERIOD);
        }
        break;

    case GAIA_INTERNAL_CHECK_BATTERY_THRESHOLD_REQ:
        {
            GAIA_INTERNAL_CHECK_BATTERY_THRESHOLD_REQ_T *req = (GAIA_INTERNAL_CHECK_BATTERY_THRESHOLD_REQ_T *)message;
            
            if (req->transport->connected)
            {
                /* if we have any battery thresholds set for this transport */
                if (req->transport->threshold_count_lo_battery || req->transport->threshold_count_hi_battery)
                {
                    /* check if a threshold has been reached, inform host, and restart the timer */
                    check_battery_thresholds(req->transport);
                    start_check_battery_threshold_timer(req->transport);
                }
            }
        }
        break;
        
    case GAIA_INTERNAL_CHECK_RSSI_THRESHOLD_REQ:
        {
            GAIA_INTERNAL_CHECK_RSSI_THRESHOLD_REQ_T *req = (GAIA_INTERNAL_CHECK_RSSI_THRESHOLD_REQ_T *)message;
            if (req->transport->connected)
            {
                /* if we have any RSSI thresholds set for this transport */
                if (req->transport->threshold_count_lo_rssi || req->transport->threshold_count_hi_rssi)
                {
                    /* check if a threshold has been reached, inform host, and restart the timer */
                    check_rssi_thresholds(req->transport);
                    start_check_rssi_threshold_timer(req->transport);
                }
            }
        }
        break;
        
        
    case GAIA_INTERNAL_REBOOT_REQ:
        BootSetMode(* (uint16 *) message);
        break;

        
    case GAIA_INTERNAL_DFU_REQ:
        GAIA_DEBUG(("gaia: LoaderPerformDfuFromSqif(%u)\n", gaia->pfs_open_stream));
#ifdef HAVE_DFU_FROM_SQIF
        LoaderPerformDfuFromSqif(gaia->pfs_open_stream);
#endif
        break;


    case GAIA_INTERNAL_DISCONNECT_REQ:
        {
            GAIA_INTERNAL_DISCONNECT_REQ_T *m = (GAIA_INTERNAL_DISCONNECT_REQ_T *) message;
            gaiaTransportDisconnectReq(m->transport);
        }
        break;
              
        
    case GAIA_INTERNAL_POWER_OFF_REQ:
    /*  Try ALL for BC7, just SMPS0 for BC5  */
        if (!PsuConfigure(PSU_ALL, PSU_ENABLE, FALSE))
            PsuConfigure(PSU_SMPS0, PSU_ENABLE, FALSE);

        break;
        

    case GAIA_INTERNAL_DFU_TIMEOUT:
        GAIA_DFU_DEBUG(("gaia: dfu tmo in state %d\n", gaia->dfu_state));

        if (gaia->dfu_state == DFU_DOWNLOAD)
            dfu_finish(FALSE);
            	
        if (gaia->dfu_state == DFU_WAITING)
            dfu_confirm(gaia->outstanding_request, FALSE);
            
        else
            dfu_indicate(GAIA_DFU_STATE_DOWNLOAD_FAILURE);
        
        gaia->dfu_state = DFU_IDLE;

        break;


    case CL_SM_ENCRYPTION_CHANGE_IND:
        break;


    default:
        GAIA_DEBUG(("gaia: unh 0x%04X\n", id));
        break;
    }
}


/*************************************************************************
 *                                                                       *
 *  Public interface functions                                           *
 *                                                                       *
 *************************************************************************/

/*************************************************************************
NAME
    GaiaInit
    
DESCRIPTION
    Initialise the Gaia protocol handler library
*/
void GaiaInit(Task task, uint16 max_connections)
{ 
    /* size of buffer required for GAIA_T + transport data */
    uint16 buf_size = sizeof (GAIA_T) + (max_connections - 1) * sizeof (gaia_transport);   
    
    GAIA_DEBUG(("gaia: GaiaInit n=%d s=%d\n", max_connections, buf_size));
    
    if ((gaia == NULL) && 
    (max_connections > 0) && 
    (max_connections <= MAX_SUPPORTED_GAIA_TRANSPORTS) &&
    (gaia = PanicUnlessMalloc(buf_size)))
    {
        /* initialise message handler */
        memset(gaia, 0, buf_size);
        gaia->task_data.handler = message_handler;
        gaia->app_task = task;
        
        gaia->transport_count = max_connections;
        
        MessageSend(&gaia->task_data, GAIA_INTERNAL_INIT, NULL);
    }
    
    else
    {
        MESSAGE_PMAKE(status, GAIA_INIT_CFM_T);
        status->success = FALSE;
        MessageSend(task, GAIA_INIT_CFM, status);
    }
}



/*************************************************************************
NAME
    GaiaBtConnectRequest
    
DESCRIPTION
    Request a connection to the given address
*/
void GaiaBtConnectRequest(GAIA_TRANSPORT *transport, bdaddr *address)
{
    GAIA_DEBUG(("GaiaBtConnectRequest\n"));
    
    if (gaia != NULL)
        gaiaTransportConnectReq((gaia_transport *) transport, address);
}


/*************************************************************************
NAME
    GaiaDisconnectRequest
    
DESCRIPTION
    Disconnect from host
*/
void GaiaDisconnectRequest(GAIA_TRANSPORT *transport)
{    
    if (gaia != NULL)
        gaiaTransportDisconnectReq((gaia_transport *) transport);
}


/*************************************************************************
NAME
    GaiaDisconnectResponse
    
DESCRIPTION
    Indicates that the client has processed a GAIA_DISCONNECT_IND message
*/
void GaiaDisconnectResponse(GAIA_TRANSPORT *transport)
{
    gaiaTransportDropState((gaia_transport *) transport);
}


/*************************************************************************
NAME
    GaiaStartService
    
DESCRIPTION
    Start a service of the given type
*/
void GaiaStartService(gaia_transport_type transport_type)
{
    if (gaia != NULL)
        gaiaTransportStartService(transport_type);
}


/*************************************************************************
NAME
    GaiaSendPacket
    
DESCRIPTION
    Send a Gaia packet over the indicated connection
*/
void GaiaSendPacket(GAIA_TRANSPORT *transport, uint16 packet_length, uint8 *packet)
{
    if (gaia != NULL)
        send_packet(gaia->app_task, (gaia_transport *) transport, packet_length, packet);
}


/*************************************************************************
NAME
    GaiaGetAppWillHandleCommand
    
DESCRIPTION
    Return TRUE if the given command is to be passed to application code
    rather than being handled by the library
*/
bool GaiaGetAppWillHandleCommand(uint16 command_id)
{
    uint16 idx = find_locus_bit(command_id);
    
    if ((idx == GAIA_INVALID_ID) || (gaia == NULL))
        return FALSE;
    
    return (gaia->command_locus_bits & (1UL << idx)) != 0;
}


/*************************************************************************
NAME
    GaiaSetApiMinorVersion
    
DESCRIPTION
    Changes the API Minor Version reported by GAIA_COMMAND_GET_API_VERSION
    Returns TRUE on success, FALSE if the value is out of range (0..15) or
    the GAIA storage is not allocated
*/
bool GaiaSetApiMinorVersion(uint8 version)
{
    if (gaia == NULL || version > GAIA_API_VERSION_MINOR_MAX)
        return FALSE;
    
    gaia->api_minor = version;
    return TRUE;
}


/*************************************************************************
NAME
    GaiaSetAppWillHandleCommand
    
DESCRIPTION
    Request that the given command be passed to application code
    rather than being handled by the library.  Returns TRUE on success.
*/
bool GaiaSetAppWillHandleCommand(uint16 command_id, bool value)
{
    uint16 idx;
    
    if (gaia == NULL)
        return TRUE;
    
    idx = find_locus_bit(command_id);
    
    if (idx != GAIA_INVALID_ID)
    {
        if (value)
            gaia->command_locus_bits |= (1UL << idx);
        
        else
            gaia->command_locus_bits &= ~(1UL << idx);
            
        return TRUE;
    }

    return FALSE;
}


/*************************************************************************
NAME
    GaiaGetAppWillHandleNotification
    
DESCRIPTION
    Return TRUE if the given event is to be notified by application code
    rather than being handled by the library.
*/
bool GaiaGetAppWillHandleNotification(uint8 event_id)
{
    if ((event_id > GAIA_IMP_MAX_EVENT_BIT) || (gaia == NULL))
        return FALSE;
    
    return (gaia->event_locus_bits & (1 << event_id)) != 0;
}


/*************************************************************************
NAME
    GaiaSetAppWillHandleNotification
    
DESCRIPTION
    Request that the given event be raised by application code
    rather than by the library.  Returns TRUE on success.
*/
bool GaiaSetAppWillHandleNotification(uint8 event_id, bool value)
{
    if ((event_id > GAIA_IMP_MAX_EVENT_BIT) || (gaia == NULL))
        return FALSE;
    
    
    if (value)
        gaia->event_locus_bits |= (1 << event_id);
    
    else
        gaia->event_locus_bits &= ~(1 << event_id);
        
    return TRUE;
}


/*************************************************************************
NAME
    GaiaBuildPacket
    
DESCRIPTION
    Build an arbitrary Gaia packet into the supplied buffer
*/
uint16 GaiaBuildPacket(uint8 *buffer, uint8 flags,
                            uint16 vendor_id, uint16 command_id, 
                            uint8 size_payload, uint8 *payload)
{
    return build_packet(buffer, flags, vendor_id, command_id, 
                        GAIA_STATUS_NONE, size_payload, payload);
}


/*************************************************************************
NAME
    GaiaBuildPacket16
    
DESCRIPTION
    Build an arbitrary Gaia packet into the supplied buffer from a
    uint16[] payload
*/
uint16 GaiaBuildPacket16(uint8 *buffer, uint8 flags, uint16 vendor_id, uint16 command_id, 
                         uint8 size_payload, uint16 *payload)
{
    return build_packet_16(buffer, flags, vendor_id, command_id, 
                        GAIA_STATUS_NONE, size_payload, payload);
}


/*************************************************************************
NAME
    GaiaBuildResponse
    
DESCRIPTION
    Build a Gaia acknowledgement packet into the supplied buffer
*/
uint16 GaiaBuildResponse(uint8 *buffer, uint8 flags, 
                         uint16 vendor_id, uint16 command_id, 
                         uint8 status, uint8 size_payload, uint8 *payload)
{
    return build_packet(buffer, flags, vendor_id, command_id,
                        status, size_payload, payload);
}


/*************************************************************************
NAME
    GaiaBuildResponse16
    
DESCRIPTION
    Build a Gaia acknowledgement packet into the supplied buffer from a
    uint16 payload
*/
uint16 GaiaBuildResponse16(uint8 *buffer, uint8 flags, 
                            uint16 vendor_id, uint16 command_id, 
                            uint8 status, uint8 size_payload, uint16 *payload)
{
    return build_packet_16(buffer, flags, vendor_id, command_id,
                        status, size_payload, payload);
}


/*************************************************************************
NAME
    GaiaBuildAndSendSynch
    
DESCRIPTION
    Build a Gaia packet in the transport sink and flush it
    The payload is an array of uint8s; contrast GaiaBuildAndSendSynch16()
    The function completes synchronously and no confirmation message is
    sent to the calling task
*/
void GaiaBuildAndSendSynch(GAIA_TRANSPORT *transport, 
                           uint16 vendor_id, uint16 command_id, uint8 status, 
                           uint8 size_payload, uint8 *payload)
{
    Sink sink = gaiaTransportGetSink((gaia_transport *) transport);
    uint16 packet_length = GAIA_OFFS_PAYLOAD + size_payload;
    uint8 flags = ((gaia_transport *)transport)->flags;
    
    if (gaia == NULL || sink == NULL)
        return;

    if (status != GAIA_STATUS_NONE)
        ++packet_length;

    if (flags & GAIA_PROTOCOL_FLAG_CHECK)
        ++packet_length;

    if (packet_length > GAIA_MAX_PACKET)
        return;

    GAIA_TRANS_DEBUG(("gaia: bss %d\n", packet_length));

    if (SinkClaim(sink, packet_length) == BAD_SINK_CLAIM)
    {
        GAIA_TRANS_DEBUG(("gaia: no sink\n"));
        return;
    }
    
    build_packet(SinkMap(sink), flags, vendor_id, command_id,
                        status, size_payload, payload);
    
#ifdef DEBUG_GAIA_TRANSPORT
    {
        uint16 idx;
        uint8 *data = SinkMap(sink);
        GAIA_DEBUG(("gaia: put"));
        for (idx = 0; idx < packet_length; ++idx)
            GAIA_DEBUG((" %02x", data[idx]));
        GAIA_DEBUG(("\n"));
    }
#endif

    SinkFlush(sink, packet_length);
}


/*************************************************************************
NAME
    GaiaBuildAndSendSynch16
    
DESCRIPTION
    Build a Gaia packet in the transport sink and flush it
    The payload is an array of uint16s; contrast GaiaBuildAndSendSynch()
    The function completes synchronously and no confirmation message is
    sent to the calling task
*/
void GaiaBuildAndSendSynch16(GAIA_TRANSPORT *transport, 
                             uint16 vendor_id, uint16 command_id, uint8 status, 
                             uint16 size_payload, uint16 *payload)
{
    Sink sink = gaiaTransportGetSink((gaia_transport *) transport);
    uint16 packet_length = GAIA_OFFS_PAYLOAD + 2 * size_payload;
    uint8 flags = ((gaia_transport *)transport)->flags;

    if (gaia == NULL || sink == NULL)
        return;

    if (status != GAIA_STATUS_NONE)
        ++packet_length;

    if (flags & GAIA_PROTOCOL_FLAG_CHECK)
        ++packet_length;

    GAIA_TRANS_DEBUG(("gaia: bss16 %d\n", packet_length));
    
    if (packet_length > GAIA_MAX_PACKET)
        return;

    if (SinkClaim(sink, packet_length) == BAD_SINK_CLAIM)
    {
        GAIA_TRANS_DEBUG(("gaia: no sink\n"));
        return;
    }
    
    build_packet_16(SinkMap(sink), flags, vendor_id, command_id,
                        status, size_payload, payload);
    
    SinkFlush(sink, packet_length);
}


/*************************************************************************
NAME
    GaiaTransportGetFlags
    
DESCRIPTION
    Returns the control flags for the given transport instance
*/
uint8 GaiaTransportGetFlags(GAIA_TRANSPORT *transport)
{
    if (transport)
        return ((gaia_transport *) transport)->flags;

    return 0;
}


/*************************************************************************
NAME
    GaiaTransportGetType
    
DESCRIPTION
    Returns the transport type for the given transport instance
*/
gaia_transport_type GaiaTransportGetType(GAIA_TRANSPORT *transport)
{
   if (transport)
       return ((gaia_transport *) transport)->type;

   return gaia_transport_none;
}


/*************************************************************************
NAME
    GaiaTransportSetFlags
    
DESCRIPTION
    Sets the control flags for the given transport instance
*/
void GaiaTransportSetFlags(GAIA_TRANSPORT *transport, uint8 flags)
{
    ((gaia_transport *) transport)->flags = flags;
}


/*************************************************************************
NAME
    GaiaGetSessionEnable
    
DESCRIPTION
    Returns TRUE if GAIA session is enabled for the given transport instance
*/
bool GaiaGetSessionEnable(GAIA_TRANSPORT *transport)
{
    return ((gaia_transport *) transport)->enabled;
}


/*************************************************************************
NAME
    GaiaSetSessionEnable
    
DESCRIPTION
    Enables or disables GAIA session for the given transport instance
*/
void GaiaSetSessionEnable(GAIA_TRANSPORT *transport, bool enable)
{
    ((gaia_transport *) transport)->enabled = enable;
}


/*************************************************************************
NAME
    GaiaDfuRequest
    
DESCRIPTION
    Enables and Requests Device Firmware Upgrade

    Does some sanity checks:
    o The <partition> is of the correct type
    o The <period> is reasonable
    o Gaia is initialised
    o A DFU is not already pending or in progress
    o No other Partition Filesystem operation is in progress
    o Exactly one transport is connected

*/
void GaiaDfuRequest(GAIA_TRANSPORT *transport, uint16 partition, uint16 period)
{
#ifdef HAVE_PARTITION_FILESYSTEM
    uint32 pfs_type = 0xFF;
    uint16 idx;
    bool ok = TRUE;
   
    ok = PartitionGetInfo(PARTITION_SERIAL_FLASH, partition, PARTITION_INFO_TYPE, &pfs_type);
	
    GAIA_DEBUG(("gaia: dfu request p=%u s=%u t=%lu\n", partition, ok, pfs_type));
	
    if ((gaia == NULL) ||
        (transport == NULL) ||
        (gaia->dfu_state != DFU_IDLE) || 
        (gaia->pfs_state != PFS_NONE) ||
        (partition > PFS_MAX_PARTITION) ||
        (period < 1) || 
        (period > DFU_MAX_ENABLE_PERIOD) ||
        (pfs_type != PARTITION_TYPE_RAW_SERIAL))
        ok = FALSE;
	
    if (ok)
    {
    /*  Make sure there is only one transport  */
        for (idx = 0; ok && idx < gaia->transport_count; ++idx)
        {
            if ((gaia->transport[idx].type != gaia_transport_none) &&
                ((GAIA_TRANSPORT *) &gaia->transport[idx] != transport))
                ok = FALSE;
        }
    }

    if (ok)
    {
        gaia->dfu_state = DFU_WAITING;
        gaia->pfs_open_stream = partition;
        GaiaBuildAndSendSynch(transport, GAIA_VENDOR_CSR, GAIA_COMMAND_DFU_REQUEST, GAIA_STATUS_NONE, 0, NULL);
        dfu_reset_timeout(period);
    }

    else
#endif
       dfu_confirm((gaia_transport *) transport, FALSE);
}

