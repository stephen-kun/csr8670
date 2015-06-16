// *****************************************************************************
// %%fullcopyright(2007)        http://www.csr.com
// %%version
//
// $Change: 1882869 $  $DateTime: 2014/04/23 13:37:24 $
// *****************************************************************************

#ifndef one_mic_example_LIB_H
#define one_mic_example_LIB_H


.CONST $one_mic_example.REINITIALIZE           1;
.CONST $one_mic_example.VMMSG.SETMODE          4;
.CONST $one_mic_example.VMMSG.READY            5;
.CONST $one_mic_example.MESSAGE_REM_BT_ADDRESS 0x2001;

// System Modes
.CONST $one_mic_example.SYSMODE.PASSTHRU       0;

// Data block size
#ifdef uses_16kHz
// Decoded WBS frames are 120 samples
.CONST $one_mic_example.NUM_SAMPLES_PER_FRAME  120;
.CONST $one_mic_example.JITTER                 32;
#else
.CONST $one_mic_example.NUM_SAMPLES_PER_FRAME  60;
.CONST $one_mic_example.JITTER                 16;
#endif
        


#endif
