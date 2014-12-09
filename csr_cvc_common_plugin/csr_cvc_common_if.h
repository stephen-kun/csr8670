/****************************************************************************
Copyright (C) Cambridge Silicon Radio Ltd. 2005

FILE NAME
    csr_cvc_common_if.h

DESCRIPTION
    Message definitions for cVc plugins.

*/

/*!
@file csr_cvc_common_if.h

@brief
   Message definitions for cVc plugins.

   @description
      This file provides documentation for the messaging API between the VM
      application and the cVc algorithm running on the kalimba
      DSP.  All cVc systems share a common API, except where noted.

      A high level description of the boot sequence is:\n
      1) VM starts cVc using the KalimbaLoad function.\n
      2) VM receives CVC_READY_MSG and responds by:\n
         - sending CVC_LOADPARAMS_MSG.
         - muting the DAC.
         - sending the SET_SCOTYPE_MSG message.
         - connecting the streams to the DSP.
         - sending the CVC_SETMODE_MSG message.
         - sending the CVC_VOLUME_MSG message.

      Volume is handled with cVc in the following manner:\n
      1) VM sends the CVC_VOLUME_MSG.\n
      2) cVc does internal calculations and sends the CVC_CODEC_MSG.\n
      3) VM receives CVC_CODEC_MSG and sets CODEC gains.\n

      Tone mixing is handled with cVc in the following manner:\n
      1) VM defines the tone.\n
      2) VM sets the digital tone gain value using CVC_VOLUME_MSG.\n
      3) VM connects the tone stream to port 3 on the kalimba.\n

      Note that there are 3 gain values that control the tone volume:\n
      1) the volume used in the VM's definition of the tone.\n
      2) the digital gain value specified in CVC_VOLUME_MSG.\n
      3) the DAC gain that is used while the tone is playing.\n

*/

#ifndef _CSR_CVC_COMMON_INTERFACE_H_
#define _CSR_CVC_COMMON_INTERFACE_H_

/* Messages between Kalimba and VM */
typedef enum
{
/*!
   MESSAGE:  cVc is ready to recieve messages (KALIMBA --> VM APPLICATION)

   @brief
   Indicates that cVc has powered up and is ready to receive messages from
   the VM application. This is the first message that cVc sends after the
   VM application has loaded cVc using the KalimbaLoad function.  The VM
   application should respond by sending the CVC_LOADPARAMS_MSG message and
   by connecting the SCO, DAC, and ADC streams to the DSP ports.

   @param AlgID (0), Algorithm ID (4 digit hexidecimal)
   @param BuildNumber (1), Software Build Number (4 digit hexidecimal)\n
*/
    CVC_READY_MSG       = 0x1000 ,

   /*!
  MESSAGE:  VM sets cVc's mode of operation (VM APPLICATION --> KALIMBA)

   @brief
   The VM controls the mode of the cVc software using this message.  The VM
   must do this after it sends the CVC_LOADPARAMS_MSG because the
   CVC_LOADPARAMS_MSG will put cVc into SYSMODE_STANDBY.  The VM can also
   send this message anytime a mode change is necessary.

   @param Mode (0), SYSMODE_HFK, SYSMODE_NS, SYSMODE_PSTHRGH, SYSMODE_LPBACK
        or SYSMODE_STANDBY
   @param NotUsed (1), This parameter is not used.
   @param CallState (2), CALLST_CONNECTING, CALLST_CONNECTED, or CALLST_MUTE\n
*/
    CVC_SETMODE_MSG     = 0x1001 ,

   /*!
   MESSAGE:  VM requests DAC gain change from cVc
             (VM APPLICATION --> KALIMBA)

   @brief
   The VM application needs to send this message to cVc to change the DAC
   gain.  cVc uses the DAC gain for internal calculations and then sends the
   gain back to the VM application using the CVC_CODEC_MSG.

   @param NotUsed (0), This parameter is not used.
   @param AuxGain (1), Q5.19 gain value applied to the Auxiliary Stream.
   @param DacGain (2), valid range is 0 through 0xf.\n
*/
    CVC_VOLUME_MSG      = 0x1002 ,

   /*!
   MESSAGE:  VM changes one cVc parameter (VM APPLICATION --> KALIMBA)

   @brief
   This message is generally unused, but it is available if needed.
   Not supported in cvc_headset_276.

   @param ParameterID (0), Index into cVc Parameters Array.
   @param MSW (1), MSW of the value.  (would be  0x0012, for 0x123456)
   @param LSW (2), LSW of the value.  (would be  0x3456, for 0x123456)
   @param Status (3), should be zero if the VM is immediately sending more
                      parameters, which will put the system into
                      SYSMODE_STANDBY.  Should be 1 if the VM is done sending
                      parameters.  The VM will then need to send a
                      CVC_SETMODE_MSG to restore the mode.\n
*/
    CVC_SETPARAM_MSG    = 0x1004 ,

   /*!
   MESSAGE:  cVc tells VM to set the DAC gain (KALIMBA  --> VM APPLICATION)

   @brief
   This message tells the VM application which CODEC gain values to use with
   the internal CODEC.

   @param DacGain (0), should be used as argument to CodecSetOuputGainNow
                       function.
   @param AdcGain (1), if bit 15 is high the mic preamp should be enabled,
                       otherwise it should be disabled.  Bits 0 through 3
                       should be masked and used as the argument to
                       CodecSetInputGainNow.\n
*/
    CVC_CODEC_MSG       = 0x1006 ,

/*!
   MESSAGE:  VM asks cVc if it is processing data (VM APPLICATION --> KALIMBA)

   @brief
   This message requests the frame counter value from cVc.
   This message does not have any parameters.\n
   Not supported in cvc_headset_276.
*/
    CVC_PING_MSG        = 0x1008 ,

/*!
   MESSAGE:  cVc tells VM that it is processing data (KALIMBA  --> VM APPLICATION)

   @brief
   This message sends a counter value to the VM, which is incremented each
   time cVc processes a block of data.  It is sent in response to
   CVC_PING_MSG.
   Not supported in cvc_headset_276.
   @param FrameCounter (0), counter value.\n
*/
    CVC_PINGRESP_MSG    = 0x1009 ,

/*!
   MESSAGE:  VM tells DSP application framework to set buffer copy limits
             according to the link_type   (KALIMBA  --> VM APPLICATION)

   @brief
   This message sends the connection type to the DSP so that the DSP can set
   the appropriate buffer copy limits.

   @param ConnectionType (0), WIRED_LINK_TYPE, SCO_LINK_TYPE, ESCO_LINK_TYPE.\n
*/

    SET_SCOTYPE_MSG     = 0x100d ,

/*!
   MESSAGE:  cVc tells VM that the cVc security key is valid
            (KALIMBA  --> VM APPLICATION)

   @brief
   cVc sends this message during start up to indicate that the security key
   stored in PS_USER_KEY 28 is consistent with the Bluetooth address.

   This message does not have any parameters.\n
*/

    CVC_SECPASSED_MSG   = 0x100c ,

/*!
   MESSAGE:  VM requests a parameter value from cVc (VM APPLICATION --> KALIMBA)

   @brief
   This message is used to retrieve the value of the parameter specified by P0.
   Not supported in cvc_headset_276.
   @param ParameterId (0), index into cVc parameters arrary\n
*/

    CVC_GETPARAM        = 0x1010 ,

/*!
   MESSAGE:  cVc tells VM a parameter value from cVc (KALIMBA --> VM APPLICATION)

   @brief
   cVc sends this message as a response to CVC_GETPARAM.
   Not supported in cvc_headset_276.
   @param ParameterId (0), index of parameter being requested.
   @param ReturnedId (1), index of parameter being returned.
   @param ParameterId (2), MSW of value being returned.
   @param ReturnedId (3), LSW of value being returned.\n
*/
    CVC_GETPARAM_RESP   = 0x1011 ,

    /*!
   MESSAGE:  VM tells cVc the primary Pskey that contains the cVc parameters.
             (VM APPLICATION --> KALIMBA)

   @brief
   The VM application tells cVc the primary Pskey that contains the
   cVc parameters so that the DSP can retrieve values from PS directly.
   In addition to containing cVc parameters, this key contains the USER IDs
   of any other Pskeys containing cVc parameters.

   Each cVc system has a corresponding Windows Parameter Manager that must be
   used to create parameters that are stored in PS.  Only values that are tuned
   to be different from their defaults are stored.  Each key can hold up to 40
   cVc parameter values.  The Parameter Manager allows the user to specify which
   USER KEYS the cVc parameters get stored in.

   @param PrimaryKey (0), contains cVc parameters and a list of sub-keys
                          containing cVc parameters\n
*/
    CVC_LOADPARAMS_MSG  = 0x1012,

/*!
   MESSAGE:  cVc tells VM that the cVc security key is invalid
            (KALIMBA  --> VM APPLICATION)

   @brief
   cVc sends this message during start up to indicate that the security key
   stored in PS_USER_KEY 48 is not consistent with the Bluetooth address.

   This message does not have any parameters.\n
*/
    CVC_SECFAILED_MSG   = 0x1013,


/*!
   MESSAGE:  cVc requests a block of persistence data
            (KALIMBA  --> VM APPLICATION)

   @brief
   cVc sends this message to request a block of persistence data
   @param ParameterId (0), start-address of required persistence block
   @param ParameterId (1), length of persistence block

*/
    CVC_LOADPERSIST_MSG   = 0x1014,

/*!
   MESSAGE:  response to persistence request
            (VM APPLICATION --> KALIMBA)

   @brief
   The VM application responds with a long message containing the requested
   persistence block and a status code.
   @param addr(0), status: 0=ok, nonzero=error code

*/
    CVC_LOADPERSIST_RESP   = 0x1015,

/*!
   MESSAGE:  dsp sends with persistance block
            ( KALIMBA --> VM APPLICATION)

   @brief
   cVc sends a long message containing the persistence block.
   @param addr(0), key
   @param addr(1)-..., data

*/
    CVC_STOREPERSIST_MSG   = 0x1016,

#ifdef CVC_MULTI_KAP
/*!
   MESSAGE:  Tell DSP Core application to load a file
            (VM APPLICATION --> KALIMBA)

   @brief
   The VM application tells the DSP Core to load a given file index
   @param ParameterId(0), File Index

*/
    CVC_LOAD_INDEX         = 0x1020,

/*!
   MESSAGE:  DSP Core application requests index for a given file name
             ( KALIMBA --> VM APPLICATION)

   @brief
   The DSP Core requests the file index for a given file name. VM
   must respond with CVC_LOAD_INDEX
   @param addr(0), file name

*/
    CVC_FILE_NAME          = 0x1021,

/*!
   MESSAGE:  DSP Core application notifies VM it has loaded
             ( KALIMBA --> VM APPLICATION)

   @brief
   DSP Core has loaded successfully. VM must respond with
   CVC_LOAD_INDEX indicating the CVC application file to load

*/
    CVC_CORE_READY         = 0x1022,
#endif

/*!
   MESSAGE:  VM issues ASR start to DSP
             ( VM APPLICATION --> KALIMBA)

   @brief
   Message sent from VM to tell ASR engine to start listening
*/
    ASR_START               = 0x1020,

/*!
   MESSAGE:  VM issues message to configure ASR engine
             ( VM APPLICATION --> KALIMBA )

   @brief
   VM sends message to ASR dsp app to configure thresholds

*/
    SET_CONFI_THRESH_MSG    = 0x1021,

/*!
   MESSAGE:  response to persistence request
            (VM APPLICATION --> KALIMBA)

   @brief
   The VM application sets the way data is encoded
   @param ParameterId(0), Encoding mode (0=cvsd, 1=reserved, 2=wbs, 3=usb_wired)
   @param ParameterId(1), Reserved

*/
    CVC_AUDIO_CONFIG_MSG   = 0x2000,

/*!
   MESSAGE:  DSP Core application sets ADC/DAC sampling rate
             and sets S/W & H/W rate match options
             ( KALIMBA --> VM APPLICATION)

   @brief
   DSP Core application sets ADC/DAC sampling rate (rate/10 is sent)
   @param ParameterId(0), ADC/DAC sampling rate/10
   @param ParameterId(1), rate match enable mask (bit1==1 enables S/W RM, bit0==1 enables H/W RM
   @param PArameterId(2), interface mode (0:ADC+DAC, 1:I2S, 2:tbd

*/
    MESSAGE_SET_ADCDAC_SAMPLE_RATE_MESSAGE_ID = 0x1070

} CVC_MESSAGE_T ;

/*!
   @brief PSKEY base for narrowband cVc applications is PSKEY_DSP40 for Handsfree and
   cvc-2mic, PSKEY_DSP11 for 1-mic and SSR.\n
*/
#define CVC_1MIC_PS_BASE 0x2263 /* DSP_11 */
#define CVC_2MIC_PS_BASE 0x2280 /* DSP_40 */

/*!
   @brief PSKEY base for wideband cVc applications is PSKEY_DSP44 for handsfree
   and cvc-smic, PSKEY_DSP15 for 1-mic and SSR.\n
*/
#define CVC_1MIC_PS_BASE_WBS 0x2267 /* DSP_15 */
#define CVC_2MIC_PS_BASE_WBS 0x2284 /* DSP_44 */

/* for external mic use */
#define CVC_1MIC_PS_BASE_EXT_MIC_NOT_FITTED 0x2263  /* DSP_11 */
#define CVC_1MIC_PS_BASE_EXT_MIC_FITTED 0x2267      /* DSP_15 */

#define CVC_1MIC_PS_BASE_WBS_EXT_MIC_NOT_FITTED 0x2280 /* DSP_40 */
#define CVC_1MIC_PS_BASE_WBS_EXT_MIC_FITTED 0x2284     /* DSP_44 */

/* cVc mode values */
typedef enum
{
/*!
   @brief Parameter value for CVC_SETMODE_MSG.\n
   All cVc processing modules enabled.\n
*/
    SYSMODE_HFK         = 1,
/*!
   @brief Parameter value for CVC_SETMODE_MSG.\n
   Acoustic echo canceller and sidetone are disabled.\n
*/
    SYSMODE_ASR         = 2,
/*!
   @brief Parameter value for CVC_SETMODE_MSG.\n
   All processing is disabled\n
   ADC is routed to BT-TX and BT-RX is routed to DAC.\n
   Sidetone is disabled.\n
*/
    SYSMODE_PSTHRGH     = 3,
/*!
   @brief Parameter value for CVC_SETMODE_MSG.\n
   All processing is disabled.\n
   ADC is routed to DAC and BT-RX is routed to BT-TX.\n
   Sidetone is disabled.\n
*/
    SYSMODE_LPBACK      = 5,

/*!
   @brief Parameter value for CVC_SETMODE_MSG.\n
   All processing is disabled and all audio is muted.\n
*/
    SYSMODE_STANDBY     = 6

} CVC_MODES_T ;

/* cVc call state values */
typedef enum
{
/*!
   @brief Parameter value for CVC_SETMODE_MSG.\n
   Puts the AEC into a full-duplex operational
   state.  This call state is used once a call is answered and is maintained
   throughout a conversation. This call state only affects the algorithm while
   running in the SYSMODE_HFK mode.\n
*/
    CALLST_CONNECTED    = 1,

/*!
   @brief Parameter value for CVC_SETMODE_MSG.\n
   Puts the AEC into a half-duplex operational
   state.  It is used during an incoming ring-tone and blocks any acoustic
   ring-tone energy that might be picked up by the microphone from entering the
   phone network.  This call state only affects the algorithm while running in the
   SYSMODE_HFK mode.\n
*/
    CALLST_CONNECTING    = 2,

/*!
   @brief Parameter value for CVC_SETMODE_MSG.\n
   Mutes the send-out output of cVc
   (i.e. output on the far-side).  It is essential that the VM programmer
   sends this mute message to mute the audio instead of muting the microphone
   input (ADC gain).  This call state affects the algorithm in SYSMODE_HFK
   and SYSMODE_ASR processing modes.\n
*/
    CALLST_MUTE           = 3

 } CVC_CALL_STATES_T ;

/* cVc framework values */
typedef enum
{
/*!
   @brief Parameter value for SET_SCOTYPE_MSG.\n
   Sets the copy limits according to the link_type.\n
*/
    DEFAULT_LINK_TYPE     = 0,
/*!
   @brief Parameter value for SET_SCOTYPE_MSG.\n
   Sets the copy limits according to the link_type.\n
*/
    SCO_LINK_TYPE         = 1,
/*!
   @brief Parameter value for SET_SCOTYPE_MSG.\n
   Sets the copy limits according to the link_type.\n
*/
    ESCO_LINK_TYPE        = 2

 } CVC_LINK_TYPE_T ;

/*!
   @brief Parameter value for CVC_VOLUME_MSG.\n
   This is 24 dB of gain in Q5.19 format.\n
*/
#define TWENTY_FOUR_dB     0x7fff

/*!
   @brief Parameter value for CVC_VOLUME_MSG.\n
   This is a 5.19 digital gain value applied to the auxiliary audio stream.
*/
#define TONE_DSP_GAIN      TWENTY_FOUR_dB

/*!
   @brief This define is used to set the DAC gain to minus 45 dB.\n
*/
#define MINUS_45dB         0x0         /* value used with SetOutputGainNow VM trap */

/*!
   @brief This define is used to set the DAC gain to minus 45 dB.\n
*/
#define DAC_MUTE           MINUS_45dB

/*!
   @brief CVC Port Numbers.\n
*/
#define CVC_LEFT_PORT   0
#define CVC_RIGHT_PORT  2
#define CVC_SCO_PORT    1

/* cVc plugin types */
/* Values for the selecting the plugin variant in the CvcPluginTaskdata structure  */
typedef enum
{
   CVSD_CVC_1_MIC_HEADSET        =  0,
   CVSD_CVC_1_MIC_HEADSET_BEX    =  1,
   WBS_CVC_1_MIC_HEADSET         =  2,

   CVSD_CVC_2_MIC_HEADSET        =  3,
   CVSD_CVC_2_MIC_HEADSET_BEX    =  4,
   WBS_CVC_2_MIC_HEADSET         =  5,

   CVSD_CVC_1_MIC_HANDSFREE      =  6,
   CVSD_CVC_1_MIC_HANDSFREE_BEX  =  7,
   WBS_CVC_1_MIC_HANDSFREE       =  8,

   CVSD_CVC_2_MIC_HANDSFREE      =  9,
   CVSD_CVC_2_MIC_HANDSFREE_BEX  =  10,
   WBS_CVC_2_MIC_HANDSFREE       =  11,

   CVSD_NO_DSP                   =  12,
   
   CVSD_CVC_1_MIC_HEADSET_ASR    =  13,
   CVSD_CVC_2_MIC_HEADSET_ASR    =  14,

   CVSD_CVC_1_MIC_HANDSFREE_ASR  =  15,
   CVSD_CVC_2_MIC_HANDSFREE_ASR  =  16
}CVC_PLUGIN_TYPE_T;

/* Different types of stream data encoders  */
typedef enum
{
    LINK_ENCODING_CVSD  =  0,
    LINK_ENCODING_RESVD =  1,
    LINK_ENCODING_SBC   =  2,
    LINK_ENCODING_USB   =  3
}LINK_ENCODING_TYPE_T;

/* The CODEC type selected from VM  application */
typedef enum
{
   AUDIO_CODEC_CVSD     =  1

}CODEC_TYPE_T;

typedef enum
{
    CSR_CVC_HFK_ENABLE ,
    CSR_CVC_PSTHRU_ENABLE
} cvc_extended_parameters_t ;

typedef struct tag_mic_type
{
   unsigned preamp_enable:1; /* high bit */
   unsigned unused:6;
   unsigned digital_gain:4;
   unsigned analogue_gain:5;   /* low bits */
} T_mic_gain;

/* Select CVC sample rate for run-time selectable CVC kap files  */
typedef enum
{
    CVC_SR_NB    =  0,
    CVC_SR_RESVD =  1,
    CVC_SR_BEX   =  2,
    CVC_SR_WB    =  3
}CVC_SR_TYPE_T;

typedef struct
{
    uint16 padding1;
    uint16 padding2;
    unsigned unused:13;
    unsigned external_mic_settings:2;
    unsigned mic_mute:1;
}CVCPluginModeParams;

/* Enumeration for audio i/f selection */
#define CVC_INTERFACE_ANALOG          0
#define CVC_INTERFACE_I2S             1


static const T_mic_gain MIC_MUTE = {0,0,8,0};  /* -45db, -24db, preamp=off */
static const T_mic_gain MIC_DEFAULT_GAIN = {1,0,0x1,0xa}; /* +3db for digital and analog, preamp=in */

#endif

