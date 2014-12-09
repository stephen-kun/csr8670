/****************************************************************************
Copyright (C) Cambridge Silicon Radio Limited 2011-2014
Part of ADK 3.5

FILE NAME
    dm_ble_scanning.c      

DESCRIPTION
    This file contains the implementation of Low Energy scan configuration.

NOTES

*/

#ifndef DISABLE_BLE

#include "connection.h"
#include "connection_private.h"
#include "bdaddr.h"

#include <vm.h>

/****************************************************************************
NAME    
    ConnectionDmBleSetAdvertisingDataReq

DESCRIPTION
    Sets BLE Advertising data (0..31 octets).

RETURNS
   void
*/
void ConnectionDmBleSetAdvertisingDataReq(uint8 size_ad_data, const uint8 *ad_data)
{
    
#ifdef CONNECTION_DEBUG_LIB
        /* Check parameters. */
    if (size_ad_data == 0 || size_ad_data > BLE_AD_PDU_SIZE)
    {
        CL_DEBUG(("Pattern length is zero\n"));
    }
    if (ad_data == 0)
    {
        CL_DEBUG(("Pattern is null\n"));
    }
#endif
    if (connectionGetBtVersion() < bluetooth4_0)
    {
        CL_DEBUG(("Bluestack does not support low energy (BT 4.0)\n"));
    }
    else
    {
        MAKE_PRIM_C(DM_HCI_ULP_SET_ADVERTISING_DATA_REQ);
        prim->advertising_data_len = size_ad_data;
        memmove(prim->advertising_data, ad_data, size_ad_data);
        VmSendDmPrim(prim);
    }
}

/****************************************************************************
NAME    
    ConnectionDmBleSetAdvertiseEnable

DESCRIPTION
    Enable or Disable BLE Advertising.

RETURNS
   void
*/

void ConnectionDmBleSetAdvertiseEnable(bool enable)
{
    if (connectionGetBtVersion() < bluetooth4_0)
    {
        CL_DEBUG(("Bluestack does not support low energy (BT 4.0)\n"));
    }
    else
    {
        MAKE_PRIM_C(DM_HCI_ULP_SET_ADVERTISE_ENABLE_REQ);

        prim->advertising_enable = (enable) ? 1 : 0;

        VmSendDmPrim(prim);
    }
}

/****************************************************************************
NAME    
    ConnectionDmBleSetAdvertisingParametersReq

DESCRIPTION
    Sets BLE Advertising parameters

RETURNS
   void
*/
void ConnectionDmBleSetAdvertisingParamsReq( 
        ble_adv_type adv_type,
        bool random_own_address,
        uint8  channel_map,
        const ble_adv_params_t *adv_params 
        )
{
    if (connectionGetBtVersion() < bluetooth4_0)
    {
        CL_DEBUG(("Bluestack does not support low energy (BT 4.0)\n"));
    }
    else
    {
        MAKE_PRIM_C(DM_HCI_ULP_SET_ADVERTISING_PARAMETERS_REQ);

        /* Set defaults to avoid HCI validation failures */
        prim->direct_address_type = HCI_ULP_ADDRESS_PUBLIC;
        prim->adv_interval_max = 0x0800; /* 1.28s */
        prim->adv_interval_min = 0x0800;
        prim->advertising_filter_policy = HCI_ULP_ADV_FP_ALLOW_ANY;

        switch(adv_type)
        {
            case ble_adv_ind:
                prim->advertising_type =
                    HCI_ULP_ADVERT_CONNECTABLE_UNDIRECTED;
                break;
            case ble_adv_direct_ind:
                prim->advertising_type = 
                    HCI_ULP_ADVERT_CONNECTABLE_DIRECTED;
                break;
            case ble_adv_scan_ind:
                prim->advertising_type = 
                    HCI_ULP_ADVERT_DISCOVERABLE;
                break;
            case ble_adv_nonconn_ind:
                prim->advertising_type = 
                    HCI_ULP_ADVERT_NON_CONNECTABLE;
                break;
        } 

        prim->own_address_type = 
            (random_own_address) ? 
                HCI_ULP_ADDRESS_RANDOM : HCI_ULP_ADDRESS_PUBLIC;
        
        channel_map &= BLE_ADV_CHANNEL_ALL;

        prim->advertising_channel_map = channel_map & BLE_ADV_CHANNEL_ALL; 

        if (adv_type ==  ble_adv_direct_ind)
        {
            /* Without an address, this cannot proceed. */
            if (
                    !adv_params || 
                    BdaddrIsZero(&adv_params->direct_adv.direct_addr)
               )
                Panic();

            prim->direct_address_type = 
                (adv_params->direct_adv.random_direct_address) ?
                    HCI_ULP_ADDRESS_RANDOM : HCI_ULP_ADDRESS_PUBLIC;

            BdaddrConvertVmToBluestack( 
                    &prim->direct_address,
                    &adv_params->direct_adv.direct_addr
                    ); 
        }
        else
        {
            if (adv_params)
            {
                /* These params are validated by HCI. */
                prim->adv_interval_min 
                    = adv_params->undirect_adv.adv_interval_min;
                prim->adv_interval_max
                    = adv_params->undirect_adv.adv_interval_max;

                switch (adv_params->undirect_adv.filter_policy)
                {
                    case ble_filter_none:
                        prim->advertising_filter_policy =
                            HCI_ULP_ADV_FP_ALLOW_ANY;
                        break;
                    case ble_filter_scan_only:
                        prim->advertising_filter_policy = 
                            HCI_ULP_ADV_FP_ALLOW_CONNECTIONS;
                        break;
                    case ble_filter_connect_only:
                        prim->advertising_filter_policy = 
                            HCI_ULP_ADV_FP_ALLOW_SCANNING;
                        break;
                    case ble_filter_both:
                        prim->advertising_filter_policy = 
                            HCI_ULP_ADV_FP_ALLOW_WHITELIST;
                        break;    
                }
            }
            /* otherwise, if 'adv_params' is null, defaults are used. */
        }

        VmSendDmPrim(prim);
    }
}

#else

static const int dummy;

#endif /* DISABLE_BLE */

