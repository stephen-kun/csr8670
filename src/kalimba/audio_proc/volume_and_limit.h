#ifndef AUDIO_PROC_VOLUME_AND_LIMIT_HEADER_INCLUDED
#define AUDIO_PROC_VOLUME_AND_LIMIT_HEADER_INCLUDED

   // ----------------------------------------------------------------------------------
   // Defining structure fields for multi channel volume and limit operation,
   // the structure is a contiguous block of memory consists of one common
   // $volume_and_limit structure followed by N $volume_and_limit.channel
   // structures where N is the number of channels. common structure includes
   // all setting and state variables that are share for all channels, while
   // channel structures only include channel-specific data.
   // more information about the structure fields is in the main function's header
   // -----------------------------------------------------------------------------------

   // -- defining volume and limit input structure fields
   .CONST   $volume_and_limit.OFFSET_CONTROL_WORD_FIELD                 0;  // control word
   .CONST   $volume_and_limit.OFFSET_BYPASS_BIT_FIELD                   1;  // bitmask
   .CONST   $volume_and_limit.NROF_CHANNELS_FIELD                       2;  // number of channels
   .CONST   $volume_and_limit.SAMPLE_RATE_PTR_FIELD                     3;  // sample rate
   .CONST   $volume_and_limit.MASTER_VOLUME_FIELD                       4;  // Master volume value (Q4.19)
   .CONST   $volume_and_limit.LIMIT_THRESHOLD_FIELD                     5;  // threshold field for limiter (dB)
   .CONST   $volume_and_limit.LIMIT_THRESHOLD_LINEAR_FIELD              6;  // threshold field for limiter (linear)
   .CONST   $volume_and_limit.LIMIT_RATIO_FIELD_FIELD                   7;  // ratio field for limiter
   .CONST   $volume_and_limit.LIMITER_GAIN_FIELD                        8;  // limiter gain applies to all channels
   .CONST   $volume_and_limit.LIMITER_GAIN_LINEAR_FIELD                 9;  // limiter gain applies to all channels (linear)
   .CONST   $volume_and_limit.STRUC_SIZE                                10;

   .CONST   $volume_and_limit.CHANNELS_STRUCTURES_OFFSET_FIELD          $volume_and_limit.STRUC_SIZE;

   // -- defining channel structure
   .CONST   $volume_and_limit.channel.INPUT_PTR_FIELD                   0;  // input frame buffer
   .CONST   $volume_and_limit.channel.OUTPUT_PTR_FIELD                  1;  // output frame buffer
   .CONST   $volume_and_limit.channel.TRIM_VOLUME_FIELD                 2;  // trim volume set by the application
   .CONST   $volume_and_limit.channel.CURRENT_VOLUME_FIELD              3;  // current volume used by this module
   .CONST   $volume_and_limit.channel.LAST_VOLUME_APPLIED_FIELD         4;  // last applied volume including limiter gain
   .CONST   $volume_and_limit.channel.STRUC_SIZE                        5;

   // some useful macros can be used for populating input structures in application
   #define $volume_and_limit.dB2VOL(dB)                                 ((10.0**(dB/20.0))/16.0)
   #define $volume_and_limit.LIMIT_THRESHOLD(dB)                        (log2(((10.0**(dB/20.0))/16.0))/128.0)
   #define $volume_and_limit.LIMIT_RATIO(R)                             (1.0 - (1.0/R))

  .CONST $volume_and_limit.MIN_POSITIVE_VOLUME                          0x080000;      // 0dB volume
  .CONST $volume_and_limit.VOLUME_RAMP_OFFSET_CONST                     (0.0001/16.0);  // offset used for ramping up/down the volume

#endif // AUDIO_PROC_VOLUME_AND_LIMIT_HEADER_INCLUDED
