/****************************************************************************

Copyright (C) Cambridge Silicon Radio Ltd. 2004-2014

FILE NAME
    sink_link_policy.c

DESCRIPTION
    Handles link policy and role switch settings across all devices/profiles
    
NOTES

*/

/****************************************************************************
    Header files
*/
#include "sink_private.h"
#include "sink_link_policy.h"
#include "sink_statemanager.h"
#include "sink_devicemanager.h"
#include "sink_swat.h"

#include <sink.h>
#include <swat.h>

#ifdef ENABLE_PBAP
#include <bdaddr.h>
#endif

#ifdef ENABLE_PEER
/* headers required for sending DM_HCI_QOS_SETUP_REQ */
#include <vm.h>

#include <app/bluestack/types.h>
#include <app/bluestack/bluetooth.h>
#include <app/bluestack/hci.h>
#include <app/bluestack/dm_prim.h>
#endif


/* Lower power table for HFP SLC */
static const lp_power_table lp_powertable_default[2]=
{
    /* mode,        min_interval,   max_interval,   attempt,    timeout,    duration */
    {lp_passive,    0,              0,              0,          0,          30},    /* Passive mode 30 seconds */
    {lp_sniff,      800,            800,            2,          1,          0 }     /* Enter sniff mode (500mS)*/
};

/* Lower power table for HFP when an audio connection is open */
static const lp_power_table lp_powertable_sco[2]=
{
    /* mode,        min_interval,   max_interval,   attempt,    timeout,    duration */
    {lp_passive,    0,              0,              0,          0,          30},    /*Passive mode 30 seconds */
    {lp_sniff,      160,            160,            2,          1,          0}      /* Enter sniff mode (100mS)*/
};

static const lp_power_table lp_powertable_a2dp_default[2]=
{
    /* mode,        min_interval,   max_interval,   attempt,    timeout,    duration */
    {lp_active,     0,              0,              0,          0,          10},    /* Active mode 10 seconds */
    {lp_sniff,      800,            800,            2,          1,          0 }     /* Enter sniff mode (500mS)*/
};

/* Lower power table for A2DP. */
static const lp_power_table lp_powertable_a2dp_stream_sink[]=
{
    /* mode,        min_interval,   max_interval,   attempt,    timeout,    duration */
    {lp_passive,    0,              0,              0,          0,          0}      /* Go into passive mode and stay there */
};

/* Lower power table for A2DP. */
static const lp_power_table lp_powertable_a2dp_stream_source[]=
{
    /* mode,        min_interval,   max_interval,   attempt,    timeout,    duration */
    {lp_active,    0,              0,              0,          0,          0}      /* Go into active mode and stay there */
};

#ifdef ENABLE_PBAP
/* Lower power table for PBAP access. */
static const lp_power_table lp_powertable_pbap_access[]=
{
    /* mode,        min_interval,   max_interval,   attempt,    timeout,    duration */
    {lp_active,    0,              0,              0,          0,          0}      /* Go into active mode and stay there */
};
#endif

#ifdef ENABLE_AVRCP
/* Lower power table for AVRCP  */
static const lp_power_table lp_powertable_avrcp[]=
{
    /* mode,        min_interval,   max_interval,   attempt,    timeout,    duration */
    {lp_active,    0,              0,              0,          0,          AVRCP_ACTIVE_MODE_INTERVAL},      /* Go into active mode for 10 seconds*/
    {lp_sniff,     800,            800,            2,          1,          0 } 
};
#endif

#ifdef ENABLE_SUBWOOFER
static const lp_power_table lp_powertable_subwoofer[2]=
{
    /* mode,        min_interval,   max_interval,   attempt,    timeout,    duration */
    {lp_active,     0,              0,              0,          0,          10},    /* Active mode 10 seconds */
    {lp_sniff,      160,            160,            2,          1,          0}      /* Enter sniff mode (100mS)*/
};
#endif

#ifdef DEBUG_LP
    #define LP_DEBUG(x) DEBUG(x)
#else
    #define LP_DEBUG(x) 
#endif   


static uint16 linkPolicyNumberPhysicalConnections (void)
{
    uint16 connections = 0;
    Sink sink_pri, sink_sec, sink_a2dp_pri, sink_a2dp_sec;

    /* obtain any hfp link sinks */
    HfpLinkGetSlcSink(hfp_primary_link, &sink_pri);
    HfpLinkGetSlcSink(hfp_secondary_link, &sink_sec);
    
    /* obtain sinks for any a2dp links */
    sink_a2dp_pri = A2dpSignallingGetSink(theSink.a2dp_link_data->device_id[a2dp_primary]);
    sink_a2dp_sec = A2dpSignallingGetSink(theSink.a2dp_link_data->device_id[a2dp_secondary]);
    
    /* if primary hfp exists then check its role */
    if (sink_pri)
    {
        connections++;
    }
        
    /* if secondary hfp connection then check its role */    
    if (sink_sec)
    {
        connections++;
    }
    
    /* if primary a2dp exists and it is not the same device as pri or sec hfp connections */
    if (sink_a2dp_pri && !deviceManagerIsSameDevice(a2dp_primary, hfp_primary_link) && !deviceManagerIsSameDevice(a2dp_primary, hfp_secondary_link))
    {
        connections++;
    }
    
    /* if secondary a2dp exists and it is not the same device as pri or sec hfp connections */
    if (sink_a2dp_sec && !deviceManagerIsSameDevice(a2dp_secondary, hfp_primary_link) && !deviceManagerIsSameDevice(a2dp_secondary, hfp_secondary_link))
    {
        connections++;
    }
        
    LP_DEBUG(("LP: Number of physical connections = %u\n", connections ));    
    return connections;
}

/****************************************************************************
NAME    
    linkPolicyUseDefaultSettings

DESCRIPTION
    set the link policy based on no a2dp streaming or sco 
    
RETURNS
    void
*/
static void linkPolicyUseDefaultSettings(Sink sink)
{
    /* Set up our sniff sub rate params for SLC */
    ssr_params* slc_params = &theSink.conf2->ssr_data.slc_params;
    ConnectionSetSniffSubRatePolicy(sink, slc_params->max_remote_latency, slc_params->min_remote_timeout, slc_params->min_local_timeout);
    
    /* audio not active, normal role, check for user defined power table */
    if((theSink.user_power_table)&&(theSink.user_power_table->normalEntries))
    {                  
        LP_DEBUG(("LP: SetLinkP - norm user table \n" ));    
        /* User supplied power table */
        ConnectionSetLinkPolicy(sink, theSink.user_power_table->normalEntries ,&theSink.user_power_table->powertable[0]);               
    }
    /* no user defined power table so use default normal power table */       
    else
    {    
        LP_DEBUG(("LP: SetLinkP - norm default table \n" ));    
        ConnectionSetLinkPolicy(sink, 2 ,lp_powertable_default);
    }              
}


/****************************************************************************
NAME    
    linkPolicyUseA2dpSettings

DESCRIPTION
    set the link policy requirements based on current device audio state 
    
RETURNS
    void
*/
void linkPolicyUseA2dpSettings(uint16 DeviceId, uint16 StreamId, Sink sink )
{
    Sink sinkAG1,sinkAG2 = NULL;
    bool faster_poll = FALSE;
    
    /* obtain any sco sinks */
    HfpLinkGetAudioSink(hfp_primary_link, &sinkAG1);
    HfpLinkGetAudioSink(hfp_secondary_link, &sinkAG2);
    
    /* determine if the connection is currently streaming and there are no scos currently open */    
    if ((!sinkAG1 && !sinkAG2) && (A2dpMediaGetState(DeviceId, StreamId) == a2dp_stream_streaming))
                                
    {
        /* is there a user power table available from ps ? */
        if((theSink.user_power_table) && (theSink.user_power_table->A2DPStreamEntries))
        {                
            LP_DEBUG(("LP: SetLinkP - A2dp user table \n"))

            /* User supplied power table for A2DP role */
            ConnectionSetLinkPolicy(sink, 
                                    theSink.user_power_table->A2DPStreamEntries ,
                                    &theSink.user_power_table->powertable[ theSink.user_power_table->normalEntries + theSink.user_power_table->SCOEntries  ]
                                    );  
        }
        /* no user power table so use default A2DP table */
        else
        {    
            if (A2dpMediaGetRole(DeviceId, StreamId) == a2dp_source)
            {
                LP_DEBUG(("LP: SetLinkP - A2dp stream source table \n" ));    
                ConnectionSetLinkPolicy(sink, 1 ,lp_powertable_a2dp_stream_source);
                faster_poll = TRUE;
            }
            else
            {
                LP_DEBUG(("LP: SetLinkP - A2dp stream sink table \n" ));    
                ConnectionSetLinkPolicy(sink, 1 ,lp_powertable_a2dp_stream_sink);
            }
        }                         
    }
    /* if not streaming a2dp check for the prescence of sco data and if none found go to normal settings */
    else if ((!sinkAG1 && !sinkAG2) && (A2dpMediaGetState(DeviceId, StreamId) != a2dp_stream_streaming))
    {
        uint16 priority;
        
        if (getA2dpIndex(DeviceId, &priority) && (theSink.a2dp_link_data->peer_device[priority] == remote_device_peer))
        {
            LP_DEBUG(("LP: SetLinkP - a2dp default table \n" ));    
            ConnectionSetLinkPolicy(sink, 2 ,lp_powertable_a2dp_default);
        }
        else
        {
            /* set normal link policy settings */
            linkPolicyUseDefaultSettings(sink);
        }
    }
    /* default to passive to prevent any stream distortion issues should the current
       operating mode be incorrectly identified */ 
    else
    {
           LP_DEBUG(("LP: SetLinkP - default A2dp stream sink table \n" ));    
           ConnectionSetLinkPolicy(sink, 1 ,lp_powertable_a2dp_stream_sink);
    }
    
#ifdef ENABLE_PEER
    {   /* Set a reasonable poll interval for the relay link to help if we ever get into a */
        /* scatternet situation due to an AV SRC refusing to be slave.                     */
#if 0
        typed_bdaddr tbdaddr;

        if (A2dpDeviceGetBdaddr(DeviceId, &tbdaddr.addr))
        {
            MESSAGE_MAKE(prim, DM_HCI_QOS_SETUP_REQ_T);
            prim->common.op_code = DM_HCI_QOS_SETUP_REQ;
            prim->common.length = sizeof(DM_HCI_QOS_SETUP_REQ_T);
            prim->bd_addr.lap = tbdaddr.addr.lap;
            prim->bd_addr.uap = tbdaddr.addr.uap;
            prim->bd_addr.nap = tbdaddr.addr.nap;

            /* latency is the only thing used in the request and sets the poll interval */
            prim->service_type = HCI_QOS_GUARANTEED;
            prim->token_rate = 0xffffffff;
            prim->peak_bandwidth = 0x0000aaaa;
            prim->latency = faster_poll ? 10000 : 25000;
            prim->delay_variation = 0xffffffff;

            DEBUG(("LP: SetLinkP - Set QoS %lums\n",prim->latency));
            VmSendDmPrim(prim);
        }
#endif

        /* Check connection role is suitable too */
        linkPolicyGetRole(&sink);
    }
#endif
}


/****************************************************************************
NAME    
    HfpSetLinkPolicy

DESCRIPTION
    set the link policy requirements based on current device audio state 
    
RETURNS
    void
*/
void linkPolicyUseHfpSettings(hfp_link_priority priority, Sink slcSink)
{
    Sink audioSink;
    
    /* determine if there are any sco sinks */
    if(HfpLinkGetAudioSink(priority, &audioSink)&&(audioSink))
    {
        /* Set up our sniff sub rate params for SCO */
        ssr_params* sco_params = &theSink.conf2->ssr_data.sco_params;
        ConnectionSetSniffSubRatePolicy(slcSink, sco_params->max_remote_latency, sco_params->min_remote_timeout, sco_params->min_local_timeout);
       
        /* is there a user power table available from ps ? */
        if((theSink.user_power_table) && (theSink.user_power_table->SCOEntries))
        {                
            LP_DEBUG(("LP: SetLinkP - sco user table \n" ));    
            /* User supplied power table for SCO role */
            ConnectionSetLinkPolicy(slcSink, 
                                    theSink.user_power_table->SCOEntries ,
                                    &theSink.user_power_table->powertable[ theSink.user_power_table->normalEntries ]
                                    );               
        }
        /* no user power table so use default SCO table */
        else
        {    
            LP_DEBUG(("LP: SetLinkP - sco default table \n" ));    
            ConnectionSetLinkPolicy(slcSink, 2 ,lp_powertable_sco);
        }              
    }
    /* default of no a2dp streaming and no sco link */
    else
    {
        /* set normal link policy settings */
        linkPolicyUseDefaultSettings(slcSink);
    }           
}

#ifdef ENABLE_AVRCP
/****************************************************************************
NAME
    linkPolicyUseAvrcpSettings

DESCRIPTION
    set the link policy requirements for AVRCP alone active connections

RETURNS
    void
*/
void linkPolicyUseAvrcpSettings( Sink slcSink )
{
    if(slcSink)
    {
        ConnectionSetLinkPolicy(slcSink, 2 ,lp_powertable_avrcp); 
    }
}
#endif /*ENABLE_AVRCP*/

#ifdef ENABLE_PBAP
/****************************************************************************
NAME	
	linkPolicyPhonebookAccessComplete

DESCRIPTION
	set the link policy requirements back after phonebook access, based on current device audio state 
	
RETURNS
	void
*/
void linkPolicyPhonebookAccessComplete(Sink sink)
{
    typed_bdaddr taddr;
    uint16 DeviceId;
    uint16 StreamId;
    uint8 i;
    bool  a2dpSetting = FALSE;
        
    /* If device is in the stream a2dp state, use a2dp link policy */
    for_all_a2dp(i)
    {
        DeviceId = theSink.a2dp_link_data->device_id[i];
        StreamId = theSink.a2dp_link_data->stream_id[i];
           
        if( SinkGetBdAddr(sink, &taddr) &&
            BdaddrIsSame(&theSink.a2dp_link_data->bd_addr[i], &taddr.addr) )
        {
            a2dpSetting = TRUE;
            if(A2dpMediaGetState(DeviceId, StreamId)== a2dp_stream_streaming)
                linkPolicyUseA2dpSettings(DeviceId, StreamId, A2dpMediaGetSink(DeviceId, StreamId));
            else
                linkPolicyUseHfpSettings(hfp_primary_link, sink);
        }
    }
        
    /* Otherwise, use hfp link policy */
    if(!a2dpSetting)
    {
        linkPolicyUseHfpSettings(hfp_primary_link, sink); 
    }
}

/****************************************************************************
NAME	
	linkPolicySetLinkinActiveMode

DESCRIPTION
	set the link as active mode for phonebook access 
	
RETURNS
	void
*/
void linkPolicySetLinkinActiveMode(Sink sink)
{
    LP_DEBUG(("LP: Set Link in Active Mode for Pbapc Access\n"));

    if(SinkIsValid(sink))
    {
        ConnectionSetLinkPolicy(sink, 1 , lp_powertable_pbap_access);
    } 
}

#endif


/****************************************************************************
NAME    
    linkPolicyGetRole
    
DESCRIPTION
    Request CL to get the role for a specific sink if one passed, or all
    connected HFP sinks if NULL passed.

RETURNS
    void
*/
void linkPolicyGetRole(Sink* sink_passed)
{
    /* no specific sink to check, check all available - happens on the back of each hfp connect cfm 
     * and handleA2DPSignallingConnected
     */
    LP_DEBUG(("LP: linkPolicyGetRole - sink = %x\n",(uint16)*sink_passed));
    if (sink_passed)
    {
        if (SinkIsValid(*sink_passed) )
        {
            /*only attempt to switch the sink that has failed to switch*/
            ConnectionGetRole(&theSink.task , *sink_passed) ;
            LP_DEBUG(("LP: GET 1 role[%x]\n", (int)*sink_passed));
        }
    }
}


/****************************************************************************
NAME    
    linkPolicyHandleRoleInd
    
DESCRIPTION
    this is a function handles notification of a role change by a remote device

RETURNS
    void
*/
void linkPolicyHandleRoleInd (CL_DM_ROLE_IND_T *ind)
{
    LP_DEBUG(("RoleInd, status=%u  role=%s\n", ind->status,  (ind->role == hci_role_master) ? "master" : "slave"));
    
    if (ind->status == hci_success)
    {
        uint16 num_sinks;
        Sink sink;
        typed_bdaddr t_bd_addr;

        t_bd_addr.type = TYPED_BDADDR_PUBLIC;
        t_bd_addr.addr = ind->bd_addr;
        
        num_sinks = 1;
        sink = NULL;
        
        if (StreamSinksFromBdAddr(&num_sinks, &sink, &t_bd_addr))
        {
            sinkA2dpSetLinkRole(sink, ind->role);
        }
    }
}


/****************************************************************************
NAME    
    linkPolicyHandleRoleCfm
    
DESCRIPTION
    this is a function checks the returned role of the device and makes the decision of
    whether to change it or not, if it  needs changing it sends a role change reuest

RETURNS
    void
*/
void linkPolicyHandleRoleCfm(CL_DM_ROLE_CFM_T *cfm)
{
    hci_role requiredRole = hci_role_dont_care;
    
    LP_DEBUG(("RoleConfirm, status=%u  sink=0x%X  role=%s\n", cfm->status, (unsigned int)cfm->sink, (cfm->role == hci_role_master) ? "master" : "slave"));
   
    /* ensure role read successfully */
    if ((cfm->status == hci_success)&&(!theSink.features.DisableRoleSwitching))
    {
        /* when multipoint enabled connect as master, this can be switched to slave
        later on if required when only 1 ag is connected */
        if((theSink.MultipointEnable) && (linkPolicyNumberPhysicalConnections() > 1))
        {
#if defined ENABLE_PEER
            uint16 priority;
            
            if (getA2dpIndexFromSink(cfm->sink, &priority) && (theSink.a2dp_link_data->peer_device[priority] == remote_device_peer))
            {
                if (A2dpMediaGetRole(theSink.a2dp_link_data->device_id[priority], theSink.a2dp_link_data->stream_id[priority]) == a2dp_source)
                {
                    LP_DEBUG(("LP: Multipoint: Peer (relaying), require Master role\n")) ;
                    requiredRole = hci_role_master;
                    /* Set the link supervision timeout as the role switch will have reset it back
                       to firmware defaults */
                    ConnectionSetLinkSupervisionTimeout(cfm->sink, SINK_LINK_SUPERVISION_TIMEOUT);
                }
                else
                {
                    LP_DEBUG(("LP: Multipoint: Peer, don't change role\n")) ;
                    requiredRole = hci_role_dont_care;
                }
            }
            else
#endif
            {
#if defined ENABLE_PEER && defined PEER_SCATTERNET_DEBUG   /* Scatternet debugging only */
                if (getA2dpIndexFromSink(cfm->sink, &priority) && theSink.a2dp_link_data->invert_ag_role[priority])
                {
                    LP_DEBUG(("LP: Multipoint: Non-peer, require Slave role (inverted)\n")) ;
                    requiredRole = hci_role_slave;
                }
                else
#endif
                {
                    LP_DEBUG(("LP: Multipoint: Non-peer, require Master role\n")) ;
                    requiredRole = hci_role_master;
                    /* Set the link supervision timeout as the role switch will have reset it back
                       to firmware defaults */
                    ConnectionSetLinkSupervisionTimeout(cfm->sink, SINK_LINK_SUPERVISION_TIMEOUT);
                }
            }
        }
#ifdef ENABLE_SUBWOOFER
        /* when a sub woofer is in use the sink app needs to be master of all links
           to maintain stable connections */
        else if((cfm->status == hci_success)&&(SwatGetSignallingSink(theSink.rundata->subwoofer.dev_id)))
        {
            LP_DEBUG(("LP: Subwoofer, require Master role\n")) ;
            requiredRole = hci_role_master;

            /* Restore the Set link supervision timeout to 1 second as this is reset after a role change */
            ConnectionSetLinkSupervisionTimeout(SwatGetSignallingSink(theSink.rundata->subwoofer.dev_id), SUBWOOFER_LINK_SUPERVISION_TIMEOUT);
        }        
#endif        
        /* non multipoint case, device needs to be slave */
        else
        {
            /* Set required role to slave as only one AG connected */
            if((theSink.user_power_table)&&(theSink.user_power_table->normalEntries))
            {   /* if user supplied role request then use that */
                LP_DEBUG(("LP: Singlepoint, require Master role\n")) ;
                requiredRole = theSink.user_power_table->normalRole;
            }
            else 
            {
#if defined ENABLE_PEER
                uint16 priority;
            
                if (getA2dpIndexFromSink(cfm->sink, &priority) && (theSink.a2dp_link_data->peer_device[priority] == remote_device_peer))
                {
                    if (A2dpMediaGetRole(theSink.a2dp_link_data->device_id[priority], theSink.a2dp_link_data->stream_id[priority]) == a2dp_source)
                    {
                        LP_DEBUG(("LP: Singlepoint: Peer (relaying), require Master role\n")) ;
                        requiredRole = hci_role_master;
                        /* Set the link supervision timeout as the role switch will have reset it back
                           to firmware defaults */
                        ConnectionSetLinkSupervisionTimeout(cfm->sink, SINK_LINK_SUPERVISION_TIMEOUT);
                    }
                    else
                    {
                        LP_DEBUG(("LP: Singlepoint: Peer, don't change role\n")) ;
                        requiredRole = hci_role_dont_care;
                    }
                }
                else
#endif
                {   /* otherwise default to slave */
                    LP_DEBUG(("LP: Singlepoint, require Slave role\n")) ;
                    requiredRole = hci_role_slave;
                }
            }
        }
    }
    /* check for failure of role switch due to AG having a sco open, if this is the case then
    reschedule the role switch until it is successfull or fails completely */
    else if((cfm->status == hci_error_role_change_not_allowed)&&(!theSink.features.DisableRoleSwitching))
    {
        LP_DEBUG(("LP: hci_error_role_change_not_allowed on sink = %x\n",(uint16)cfm->sink));    
    }
    /* automatic role switching is disabled, use the hfp_power_table pskey role requirements
       instead */
    else if(cfm->status == hci_success)
    {
        LP_DEBUG(("LP: Bypass Automatic role sw, use hfp_power_table role requirements\n")) ;

        /* check for the prescence of a user configured role requirement */
        if(theSink.user_power_table)
        {
            /* determine device state, if stream a2dp check for power table entry and use that role
               if available */
            if((stateManagerGetState() == deviceA2DPStreaming)&&(theSink.user_power_table->A2DPStreamEntries))
            {
                LP_DEBUG(("LP: Bypass: use A2dp role\n")) ;
                requiredRole = theSink.user_power_table->A2DPStreamRole;
            }
            /* or if in call and sco is present check for sco power table entry and use role from that */
            else if((stateManagerGetState() > deviceConnected)&&(theSink.routed_audio)&&(theSink.user_power_table->SCOEntries))
            {
                LP_DEBUG(("LP: Bypass: use SCO role\n")) ;
                requiredRole = theSink.user_power_table->SCORole;
            }
            /* or default to normal role power table entry and use role from that */
            else if(theSink.user_power_table->normalEntries)
            {                    
                LP_DEBUG(("LP: Bypass: use Normal role\n")) ;
                requiredRole = theSink.user_power_table->normalRole;
            }
            /* if no suitable power table entries available then default to slave role */
            else
            {
                LP_DEBUG(("LP: Bypass: use default slave role\n")) ;
                requiredRole = hci_role_slave;
            }
        }
    }        
    
    /* Request a role change if required */
    if (requiredRole != hci_role_dont_care) 
    {
        if (cfm->role != requiredRole)
        {
            LP_DEBUG(("LP: Set dev as %s %x\n",(requiredRole == hci_role_master) ? "master" : "slave", (unsigned int)cfm->sink)) ;

            /* Set role for this connection */
            ConnectionSetRole(&theSink.task, cfm->sink, requiredRole);             
        }
        else
        {
            LP_DEBUG(("LP: role not set, already %s\n",(requiredRole == hci_role_master) ? "master" : "slave")) ;
            
            sinkA2dpSetLinkRole(cfm->sink, cfm->role);
        }
    }
    else
    {
        if (cfm->status == hci_success)
        {
            sinkA2dpSetLinkRole(cfm->sink, cfm->role);
        }
        
        LP_DEBUG(("LP: role change not required\n")) ;
    }
}


/****************************************************************************
NAME    
    linkPolicyCheckRoles
    
DESCRIPTION
    this function obtains the sinks of any connection and performs a role check
    on them
RETURNS
    void
*/
void linkPolicyCheckRoles(void)
{
    Sink sink_pri, sink_sec, sink_a2dp_pri, sink_a2dp_sec;

    /* obtain any hfp link sinks */
    HfpLinkGetSlcSink(hfp_primary_link, &sink_pri);
    HfpLinkGetSlcSink(hfp_secondary_link, &sink_sec);
    
    /* obtain sinks for any a2dp links */
    sink_a2dp_pri = A2dpSignallingGetSink(theSink.a2dp_link_data->device_id[a2dp_primary]);
    sink_a2dp_sec = A2dpSignallingGetSink(theSink.a2dp_link_data->device_id[a2dp_secondary]);
    
    LP_DEBUG(("LP: linkPolicyCheckRoles: Hfp pri = %x, sec = %x, A2dp pri = %x, sec = %x\n",(uint16)sink_pri
                                                                                           ,(uint16)sink_sec
                                                                                           ,(uint16)sink_a2dp_pri
                                                                                           ,(uint16)sink_a2dp_sec)) ;

    /* if primary hfp exists then check its role */
    if(sink_pri)        
        linkPolicyGetRole(&sink_pri);
        
    /* if secondary hfp connection then check its role */    
    if(sink_sec)        
        linkPolicyGetRole(&sink_sec);

    /* if primary a2dp exists and it is not the same device as pri or sec hfp connections */
    if((sink_a2dp_pri)&&(!deviceManagerIsSameDevice(a2dp_primary, hfp_primary_link))&&(!deviceManagerIsSameDevice(a2dp_primary, hfp_secondary_link)))
        linkPolicyGetRole(&sink_a2dp_pri);
    
    /* if secondary a2dp exists and it is not the same device as pri or sec hfp connections */
    if((sink_a2dp_sec)&&(!deviceManagerIsSameDevice(a2dp_secondary, hfp_primary_link))&&(!deviceManagerIsSameDevice(a2dp_secondary, hfp_secondary_link)))
        linkPolicyGetRole(&sink_a2dp_sec);    

#ifdef ENABLE_SUBWOOFER
    /* check the subwoofer signalling sink if connected, this will have an impact of the role required for AG connections to prevent
       a scatternet scenario */
    if(SwatGetSignallingSink(theSink.rundata->subwoofer.dev_id))
    {
        Sink sink = SwatGetSignallingSink(theSink.rundata->subwoofer.dev_id);
        linkPolicyGetRole(&sink);
    }
#endif        
}

/****************************************************************************
NAME    
    linkPolicyUpdateSwatLink
    
DESCRIPTION
    this function checks the current swat connection state and updates
    the link policy of the link
RETURNS
    void
*/
void linkPolicyUpdateSwatLink(void)
{
#ifdef ENABLE_SUBWOOFER
    /* attempt to get subwoofer signalling sink */
    Sink sink = SwatGetSignallingSink(theSink.rundata->subwoofer.dev_id);

    /* determine if subwoofer is available */
    if(sink)
    {
        LP_DEBUG(("LP: SetLinkPolicy Swat\n" ));                 
        ConnectionSetLinkPolicy(sink, 2 , lp_powertable_subwoofer);
    }   
    else
    {
        /* no swat link */
        LP_DEBUG(("LP: SetLinkPolicy Swat - no link\n" ));                 
    }   
#endif      
}


