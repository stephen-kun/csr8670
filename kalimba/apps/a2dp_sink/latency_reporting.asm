// *****************************************************************************
// %%fullcopyright(2008)        http://www.csr.com
// %%version
//
// $Change: $  $DateTime: $
// *****************************************************************************

#ifndef MEDIA_PACKET_BOUNDARY_DETECTION_INCLUDED
#define MEDIA_PACKET_BOUNDARY_DETECTION_INCLUDED

#include "core_library.h"

#define $encoded_latency.CODEC_PACKETS_INFO_CBUFFER_SIZE      50
#define $encoded_latency.CODEC_PACKETS_INFO_WRITES_PER_ENTRY   2
 
.CONST $VMMSG.CONFIGURE_LATENCY_REPORTING                 0x1027;

// *****************************************************************************
// MODULE:
//    $M.$media_packet_boundary_detection
//
// DESCRIPTION:
//    Calculate over-the-air media packet boundaries and writes
//    boundary information to circular buffer.
//
// INPUTS:
//    - none
//
//
// OUTPUTS:
//    - none
//
// TRASHED REGISTERS:
//    r0, r1, r2, r3, r4
//
// *****************************************************************************

.MODULE $M.media_packet_boundary_detection;
   .CODESEGMENT MEDIA_PACKET_BOUNDARY_DETECTION_PM;
   .DATASEGMENT DM;

   .VAR/DMCIRC $codec_packets_info[$encoded_latency.CODEC_PACKETS_INFO_CBUFFER_SIZE];
   
   .VAR $codec_packets_info_cbuffer_struc[$cbuffer.STRUC_SIZE] =
         LENGTH($codec_packets_info),              // size
         &$codec_packets_info,                     // read pointer
         &$codec_packets_info;                     // write pointer

   .VAR $codec_packets_info_last_write_address = &$codec_in;
   .VAR $codec_packets_info_last_timer_time = 0;
   .VAR $codec_packets_info_timer_gap = 5000; // 5 ms - Could consider using a counter instead of time.  Also could consider using more logic to determine packet boundaries - empirical observation required.
   .VAR $first_packet_received;
   .VAR $first_packet_time;
   .VAR $target_latency_from_vm;

$media_packet_boundary_detection:

   // push rLink onto stack
   $push_rLink_macro;
    
 
   r0 = $codec_packets_info_cbuffer_struc;
   call $cbuffer.calc_amount_data;
   Null = r0 - ($encoded_latency.CODEC_PACKETS_INFO_CBUFFER_SIZE - $encoded_latency.CODEC_PACKETS_INFO_WRITES_PER_ENTRY);
   if Z jump done_with_latency_reporting;  // no room to store info

      r0 = $codec_in_cbuffer_struc;
      call $cbuffer.calc_amount_space;
      Null = r0;
      if Z jump done_with_latency_reporting; // don't do anything if codec buffer is too full to receive new packets

      r0 = &$codec_in_cbuffer_struc;
      call $cbuffer.get_write_address_and_size;
      r4 = M[$codec_packets_info_last_write_address];

      //    - r0 = write address
      //    - r1 = buffer size
      //    - r4 = write address before copy handler ran      
      
      Null = r0 - r4;
      if Z jump done_with_latency_reporting; 
         // New data has been written to the input cbuffer
         // Is this the start of a new packet?
         // If very little time has passed this is probably a continuation of the last packet.
         // Else, it's probably a new packet.
         r2 = M[$TIMER_TIME];
         r3 = r2 - M[$codec_packets_info_last_timer_time];
         Null = r3 - M[$codec_packets_info_timer_gap];
         if LS jump done_with_latency_reporting;
            //  large enough gap in time that we think this is a new packet
            M[$codec_packets_info_last_timer_time] = r2;
            r0 = &$codec_in_cbuffer_struc;
            call $cbuffer.get_write_address_and_size;
            I0 = r4;
            L0 = r1;
            r4 = M[I0, 1];
            r4 = I0; // start of new packet

            r0 = $codec_packets_info_cbuffer_struc;
            call $cbuffer.get_write_address_and_size;
            I0 = r0;
            L0 = r1;
            M[I0, 1] = r4; // $Write pointer position of codec input buffer
            M[I0, 1] = r2; // $TIMER_TIME
            // Reset for linear addressing
            L0 = 0;

            // Update output buffer
            r0 = $codec_packets_info_cbuffer_struc;
            r1 = I0;
            call $cbuffer.set_write_address;
done_with_latency_reporting:

   jump $pop_rLink_and_rts;

.ENDMODULE;

// *****************************************************************************
// MODULE:
//    $M.report_latency_to_vm
//
// DESCRIPTION: Sends latency to VM.
//
// INPUTS:
//    - none
//
//
// OUTPUTS:
//    - none
//
// *****************************************************************************
.MODULE $M.report_latency_to_vm;
   .CODESEGMENT REPORT_LATENCY_TO_VM_PM;
   .DATASEGMENT DM;
   .VAR $alpha = 0.05;
   .VAR timer_struc[$timer.STRUC_SIZE];
   .VAR reported_latency = 0;
   
init:
   $push_rLink_macro;
   r2 =  M[$M.configure_latency_reporting.report_period];
   r3 = &$report_latency_to_vm;
   call $timer.schedule_event_in;
   jump $pop_rLink_and_rts;

$report_latency_to_vm:
   $push_rLink_macro;
   r2 = $music_example.VMMSG.LATENCY_REPORTING;
   r0 = &$encoded_latency_struct;
   r3 = M[r0 + $encoded_latency.TOTAL_LATENCY_US_FIELD];
   // averaging routine: alpha * instantaneous average + (1 - alpha) * average latency
   r0 = M[$M.configure_latency_reporting.average_latency];

   r8 = M[$alpha];
   r1 = 1.0 - r8;
   rMAC = r8 * r3;
   rMAC = rMAC + r1 * r0;
   r3 = rMAC;
   M[$M.configure_latency_reporting.average_latency] = r3;
   
   r4 = M[reported_latency];	
   r4 = r3 - r4; // difference between current avg. latency and last reported latency
   if NEG r4 = -r4;
   Null = r4 - M[$M.configure_latency_reporting.min_change];
   if NEG jump do_not_send_msg;
   
   M[reported_latency] = r3;	//Save reported latency for next iteration	
   r3 = r3 * 0.01 (frac);       // convert to 0.1ms unit before sending to VM
   r0 = r3 - 0x7FFF;            // limit to 15-bit in case of false measurment
   if POS r3 = r3 - r0;
   call $message.send_short;
do_not_send_msg:
   // Post another timer event
   r1 = &timer_struc;
   r2 =  M[$M.configure_latency_reporting.report_period];
   r3 = &$report_latency_to_vm;
   call $timer.schedule_event_in_period;
   // pop rLink from stack
   jump $pop_rLink_and_rts;
.ENDMODULE;

// *****************************************************************************
// MODULE:
//    $M.configure_latency_reporting
//
// DESCRIPTION:
//       Handles message from VM to configure latency reporting
//
//  INPUTS:
//     r1 = enable/disable (0 = disable / 1 = enable)
//     r2 = report period in ms (how often the VM would like to receive the
//          delay value from the DSP)
//     r3 = minimum change to report (the DSP will only send the latency if it
//          has changed by this amount).
//     r4 = the last known latency (This value will be used to seed the DSP’s
//          averaging routine.)
//
// *****************************************************************************
.MODULE $M.configure_latency_reporting;
   .CODESEGMENT CONFIGURE_LATENCY_REPORTING_PM;
   .DATASEGMENT DM;

   .VAR message_struct[$message.STRUC_SIZE];
   .VAR enabled = 0;
   .VAR report_period = 0;
   .VAR min_change = 0;
   .VAR average_latency = -1;

func:
   $push_rLink_macro;

   // Convert values to microseconds
   r2 = r2 * 1000 (int);
   r3 = r3 * 1000 (int);
   r4 = r4 * 1000 (int);   

   M[enabled] = r1;
   if Z r4 = -1; // Tells UFE not to display data
   M[report_period] = r2;
   M[min_change] = r3;
   M[average_latency] = r4;
   
   Null = r1;
   if NZ jump no_cancel_needed;
   //Cancel timer
   r1 = &$M.report_latency_to_vm.timer_struc;
   r2 = M[r1 + $timer.ID_FIELD];
   if NZ call $timer.cancel_event;
   jump done;

no_cancel_needed:   
   // start timer that reports latency to VM
   r1 = &$M.report_latency_to_vm.timer_struc;
   call $M.report_latency_to_vm.init;

done:
   jump $pop_rLink_and_rts;
   
.ENDMODULE;

#endif
