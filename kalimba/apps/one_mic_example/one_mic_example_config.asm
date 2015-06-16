// *****************************************************************************
// %%fullcopyright(2007)        http://www.csr.com
// %%version
//
// $Change: 1894100 $  $DateTime: 2014/05/09 10:06:38 $
// *****************************************************************************



// *****************************************************************************
// DESCRIPTION
//    Static configuration file that includes function references and data
//    objects for the one_mic_example system.
//
//    Developers can use the one_mic_example system as a starting point for
//    development.
//    The functionality of the system can be expanded by adding entries to the
//    funtion table along with corresponding data object declarations.  New
//    modes of operation can be created by addition additional function tables.
//   
//
//    one_mic_example as shipped in the SDK, includes support for pass through
//    and tone mixing. Support for 8 kHz CVSD and 16 kHz mSBC is included in the 
//    main.asm file.  There is a compile time option to select between 8 kHz and 
//    16 kHz builds.
//
//    one_mic_example_cvsd as shipped in the SDK, includes support for pass
//    through and tone mixing.  It only provides support for 8 kHz CVSD.
//
//    Block Diagram of one_mic_example system:
//
//    Firmware ---> ADC --------*--------------------> SCO_OUT ---> Firmware
//    mmu buffer    cbuffer     |                      cbuffer      mmu buffer
//                              |
//                             \ /
//                        SIDE_TONE GAIN 
//                              | 
//                             \ /
//          DAC <------ + <---- + <----SCO_MIX_GAIN <-- SCO_IN <--- Firmware
//          cbuffer             ^                       cbuffer     mmu buffer
//                              |
//                        TONE_MIX_GAIN
//                              ^
//                              |
//                              |
//                          TONE_STREAM
//                          cbuffer
//                             / \
//                              |
//                              |
//                           Firmware
//                           mmu buffer
// 
//
//    INTERUPT DRIVEN PROCESSES:
//    Data is transfered between firmware mmu buffers and dsp cbuffers via
//    operators, which run in the timer interupt driven $audio_copy_handler
//    routine.
//
//    Data streams are synchronized using rate_match operators provided by
//    the frame_sync library.
//
//    The side_tone stream is mixed using an operator provided by frame_sync
//    library.
//
//    MAIN APPLICATION PROCESSES:
//    Data is copied from the ADC to the SCO_OUT and from the SCO_IN to the
//    DAC using the stream_copy function, which is defined in this application.
//    This routine executes when a block size of data is available.
//
//
//    Parameters: The SCO_GAIN and the TONE_GAIN values can be adjusted if 
//    required.  These values are only applied during tone mixing.
// *****************************************************************************
#include "one_mic_example.h"
#include "stream_copy.h"

#include "frame_sync_buffer.h"
#include "cbuffer.h"
#include "frame_sync_tsksched.h"

.MODULE $M.system_config.data;
   .DATASEGMENT DM;
               
// -----------------------------------------------------------------------------
// DATA OBJECTS USED WITH PROCESSING MODULES
//
// This section would be updated if more processing modules with data objects
// were to be added to the system.

// Data object used with $stream_copy.pass_thru function
   .VAR snd_pass_thru_obj[$stream_copy.STRUC_SIZE] =
    &snd_stream_map_adc,                             
    &snd_stream_map_sco_out;                         
      

   .VAR rcv_pass_thru_obj[$stream_copy.STRUC_SIZE] =
    &rcv_stream_map_sco_in,                         
    &rcv_stream_map_dac;                            
 
// -----------------------------------------------------------------------------

// STREAM MAPS
//
// A stream object is created for each stream: ADC, SCO_OUT, SCO_IN, and DAC.
// These objects are used to populate processing module data objects (such as
// aux_mix_dm1 and pass_thru_obj) with input pointers and output pointers so
// that processing modules (such as $stream_copy.pass_thru) know 
// where to get and write their data.
//
// Entries would be added to these objects if more processing modules were to be 
// added to the system.

// adc stream map (signal from ADC):
// The pass_thru_obj uses the adc stream to populate its ADC input fields.
   .VAR snd_stream_map_adc[$framesync_ind.ENTRY_SIZE_FIELD] =
#ifdef USB_DONGLE      
      &$usb_in_rm.cbuffer_struc,                  // $framesync_ind.CBUFFER_PTR_FIELD   
#else
      &$adc_in.cbuffer_struc,                  // $framesync_ind.CBUFFER_PTR_FIELD   
#endif    
      0,                                        // $framesync_ind.FRAME_PTR_FIELD
      0,                                        // $framesync_ind.CUR_FRAME_SIZE_FIELD
      $one_mic_example.NUM_SAMPLES_PER_FRAME,   // $framesync_ind.FRAME_SIZE_FIELD
#ifdef USB_DONGLE  
      $one_mic_example.JITTER,                  // $framesync_ind.JITTER_FIELD
#else
      3,                                        // $framesync_ind.JITTER_FIELD
#endif
      $frame_sync.distribute_input_stream_ind,  // Distribute Function
      $frame_sync.update_input_streams_ind,     // Update Function
      0 ...;
      

// sco_out stream map (outgoing Bluetooth signal):
// The pass_thru_obj uses the sco_out stream to populate its SCO_OUT output
// fields.
 
   .VAR snd_stream_map_sco_out[$framesync_ind.ENTRY_SIZE_FIELD] =
#ifdef uses_16kHz
      &$sco_data.encoder.cbuffer_struc,         // $framesync_ind.CBUFFER_PTR_FIELD 
#else
      &$sco_data.port_out.cbuffer_struc,        // $framesync_ind.CBUFFER_PTR_FIELD 
#endif  
      0,                                        // $framesync_ind.FRAME_PTR_FIELD
      0,                                        // $framesync_ind.CUR_FRAME_SIZE_FIELD
      $one_mic_example.NUM_SAMPLES_PER_FRAME,   // $framesync_ind.FRAME_SIZE_FIELD
      0,                                        // $framesync_ind.JITTER_FIELD
      $frame_sync.distribute_output_stream_ind, // Distribute Function
      $frame_sync.update_output_streams_ind,    // Update Function
      0 ...;
      

// sco_in stream map (incoming Bluetooth signal):
// The pass_thru_obj uses the sco_in stream to populate its SCO_IN input fields.
// The aux_mix_dm1 uses the sco_in stream to populate its input and output
// fields.
   .VAR rcv_stream_map_sco_in[$framesync_ind.ENTRY_SIZE_FIELD] =
      &$sco_data.sco_in.cbuffer_struc,          // $framesync_ind.CBUFFER_PTR_FIELD     
      0,                                        // $framesync_ind.FRAME_PTR_FIELD
      0,                                        // $framesync_ind.CUR_FRAME_SIZE_FIELD
      $one_mic_example.NUM_SAMPLES_PER_FRAME,   // $framesync_ind.FRAME_SIZE_FIELD
      0,                                        // $framesync_ind.JITTER_FIELD
      $frame_sync.distribute_input_stream_ind,  // Distribute Function
      $frame_sync.update_input_streams_ind,     // Update Function
      0 ...;
      
// dac stream map (signal to loudspeaker):
// The pass_thru_obj uses the dac stream to populate its DAC output fields.

   .VAR rcv_stream_map_dac[$framesync_ind.ENTRY_SIZE_FIELD] =
#ifdef USB_DONGLE
      &$usb_out_rm.cbuffer_struc,                  // $framesync_ind.CBUFFER_PTR_FIELD 
#else
      &$dac_out.cbuffer_struc,                  // $framesync_ind.CBUFFER_PTR_FIELD 
#endif   
      0,                                        // $framesync_ind.FRAME_PTR_FIELD
      0,                                        // $framesync_ind.CUR_FRAME_SIZE_FIELD
      $one_mic_example.NUM_SAMPLES_PER_FRAME,   // $framesync_ind.FRAME_SIZE_FIELD
#ifdef USB_DONGLE
      $one_mic_example.JITTER,                  // $framesync_ind.JITTER_FIELD
#else
      3,
#endif
      $frame_sync.distribute_output_stream_ind,  // Distribute Function
      $frame_sync.update_output_streams_ind,     // Update Function
      0 ...;
      
// ----------------------------------------------------------------------------
// STREAM TABLES
// These tables is used with $frame_sync.distribute_streams and $frame_sync.update_streams.
//  They identify the streams used in the processing

// Stream List for Receive Processing
.VAR    rcv_process_streams[] = 
   &rcv_stream_map_sco_in, 
   &rcv_stream_map_dac,
   0;
      
// Stream List for Send Processing
.VAR    snd_process_streams[] = 
   &snd_stream_map_adc, 
   &snd_stream_map_sco_out,
   0;
      
// -----------------------------------------------------------------------------
// REINITIALIZATION FUNCTION TABLE
// Reinitialization functions and corresponding data objects can be placed
// in this table.  Functions in this table all called every time a frame of data
// is ready to be processed and the reinitialization flag is set.
   .VAR reinitialize_table[] =
    // Function                          r7                         r8
    $frame_sync.sco_initialize,          &$sco_data.object,      0,
    0;

// -----------------------------------------------------------------------------

// MODE FUNCTION TABLE
// This table contains all of the modes in this system.  The VM plugin sends a
// message that contains a mode value, which is used as a pointer into this
// table.  As shipped, this file only contains one
// mode, which corresponds to pass_thru operation.  Developers can expand this
// table if they add additional processing modes to the system.  This table must
// be null terminated.
// 
// Every time a frame of data is ready to process, the functions from the
// corresponding mode table are called.
   .VAR send_mode_table[] =
    &snd_funcs, // mode 0, send function
    // more entries can be added here
    0;
    
    .VAR receive_mode_table[] =
    &rcv_funcs, // mode 0, receive function
    // more entries can be added here
    0;
    
// ----------------------------------------------------------------------------
// MODE TABLES (aka FUNCTION TABLES)
// Modes are defined as tables that contain a list of functions with
// corresponding
// data objects.  The functions are called in the order that they appear.
//
// $frame_sync.distribute_stream should always be first as it tells the processing
// modules where to get and write data.
//
// $frame_sync.update_streams should always be last as it advances cbuffer pointers
// to the correct positions after the processing modules have read and written
// data.
//
// The processing modules are called by the function $frame_sync.run_function_table,
// which is defined in the frame_sync library.
//
// Processing modules must be written to take input from r7 and r8.  A zero
// should be used if the module does not require input.
//
// Mode tables must be null terminated.
//
// Additional modes can be created by adding new tables.
   .VAR snd_funcs[] =
    // Function                        r7                     r8
       $frame_sync.distribute_streams_ind,   &snd_process_streams,      0,
       $stream_copy,                         &snd_pass_thru_obj,    0,
       $frame_sync.update_streams_ind,       &snd_process_streams,      0,
       0;

   .VAR rcv_funcs[] =
    // Function                        r7                    r8
       $frame_sync.distribute_streams_ind,   &rcv_process_streams,     0,
       $stream_copy,                        &rcv_pass_thru_obj,   0,
       $frame_sync.update_streams_ind,       &rcv_process_streams,     0,
       0;
.ENDMODULE;
