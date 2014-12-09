/****************************************************************************
Copyright (C) Cambridge Silicon Radio Ltd. 2012

FILE NAME
    csr_subwoofer_plugin.h

DESCRIPTION
    An audio plugin for the subwoofer device
*/

#ifndef _CSR_SUBWOOFER_PLUGIN_H_
#define _CSR_SUBWOOFER_PLUGIN_H_

#include <message.h>

/*!  CSR_SUBWOOFER plugin

    This is an audio plugin that can be used with the DSP library specifically for the
    Subwoofer application.
*/

/* Describes the input ports for the subwoofer DSP application */
typedef enum
{
    SUBWOOFER_INPUT_ADC = 0x0,
    SUBWOOFER_INPUT_ESCO,
    SUBWOOFER_INPUT_L2CAP
} csrSubwooferInput;

/* Describes the output ports for the subwoofer DSP application */
typedef enum
{
    SUBWOOFER_OUTPUT_DAC = 0x0,
    SUBWOOFER_OUTPUT_I2S
} csrSubwooferOutput;

/* Describes the parameters required when connecting up the plugin */
typedef struct
{
    csrSubwooferInput   input;      /* Required for plugging correct Kalimba port */
    csrSubwooferOutput  output;     /* Required for plugging correct Kalimba port */
    
    uint16  swat_system_volume_db;  /* The soundbar system volume */
    uint16  swat_trim_gain_db;      /* The trim gain from the soundbar */
    uint16  adc_volume;             /* Default ADC volume */
    uint16  sample_rate;            /* Sample rate received from Soundbar */
    uint16  adc_sample_rate;        /* Sample rate of the ADC when in Analog mode */
    
} subwooferPluginConnectParams;

/* Describes the parameters required when setting the DSP mode */
typedef struct
{
    unsigned    unused:11;
    unsigned    eq_bank:4;   /* Specify an absolute EQ bank to use (1,2,3) */
    unsigned    cycle_eq:1;  /* Set this to just cycle to next EQ bank; if not set, uses eq_bank value to select the EQ bank to use */
    uint16      sample_rate; /* Sample rate received from Soundbar */
 
} subwooferPluginModeParams;

/* The subwoofer plugin task */
extern const TaskData csr_subwoofer_plugin;


/* Messages sent by the subwoofer plugin to the application */
typedef enum
{
    SUB_PLUGIN_NUM_VOL_GAINS,       /* When DSP sends app the number of ADC gains configured using the UFE */
    SUB_PLUGIN_ADC_SIGNAL_ACTIVE,   /* When an input signal has been detected in ADC wired mode */
    SUB_PLUGIN_ADC_SIGNAL_IDLE,     /* When an input signal goes silent in ADC wired mode */
    SUB_PLUGIN_FATAL_ERROR          /* When an audio connection request results in a fatal error (i.e. requested sink is invalid) */
} subPluginMessages_t;

#endif /* _CSR_SUBWOOFER_PLUGIN_H_ */
