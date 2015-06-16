// *****************************************************************************
// Copyright (C) Cambridge Silicon Radio Limited 2007-2014        http://www.csr.com
// Part of ADK 3.5
//
// $Change$  $DateTime$
// *****************************************************************************


#ifndef FRAME_SYNC_BUFFER_INCLUDED
#define FRAME_SYNC_BUFFER_INCLUDED

#include "stack.h"
#include "frame_sync_buffer.h"
#include "cbuffer.h"

#ifdef FRAME_SYNC_DEBUG // SP.  cbuffer debug
#include "frame_sync_stream_macros.h"
#endif

// Called at start of frame.   Should be fixed at frame period (7.5 msec)
// Check for available data/space
//  Zero Pad or Overlap

.MODULE $M.frame_sync.distribute_streams_ind;
   .CODESEGMENT   FRAME_SYNC_IND_PM;

$frame_sync.distribute_streams_ind:
   $push_rLink_macro;
   call $block_interrupts;
   
   M1 = 1;
jp_next_stream:
   // Get Stream Ptr.  Table is NULL Terminated
   r9 = M[r7];      
   if Z jump jp_stream_done;
       
   // Get Stream Distribute Function and Data Ptr
   r3 = M[r9+$framesync_ind.DISTRIBUTE_FUNCPTR_FIELD];
   // Get CBuffer for Stream
   r0 = M[r9 + $framesync_ind.CBUFFER_PTR_FIELD];
   r1 = M[r0 + $cbuffer.SIZE_FIELD];
   r6 = M[r0 + $cbuffer.READ_ADDR_FIELD];
   r8 = M[r0 + $cbuffer.WRITE_ADDR_FIELD];
   // Get Frame Size and set buffer size
#ifdef BASE_REGISTER_MODE
   r4 = M[r0 + $cbuffer.START_ADDR_FIELD];
   push r4;
   pop B1;
#endif
   L1 = r1;
   r4 = M[r9+$framesync_ind.FRAME_SIZE_FIELD];
   // SP. Reset Current Frame Size from master frame size
   M[r9 + $framesync_ind.CUR_FRAME_SIZE_FIELD]=r4;
   // Call stream's Distribution Functions
   call r3;
   // Returns stream buffer pointer in (r6).  Save in data struct
   M[r9 + $framesync_ind.FRAME_PTR_FIELD]=r6;    
  
   // Increment Stream Table Ptr
   r7 = r7 + 1; 
   jump jp_next_stream;

jp_stream_done:
   call $unblock_interrupts;
   L1 = NULL;
#ifdef BASE_REGISTER_MODE
   push NULL;
   pop B1;
#endif   
   jump $pop_rLink_and_rts;
.ENDMODULE;   

// *****************************************************************************
// MODULE:
//    $M.frame_sync.distribute_input_stream_ind
//
// DESCRIPTION:
//    This function is used for input stream by the distribute function.  It calls
//    the analyze function to monitor the buffer state and drops/inserts samples
//    as required.
//
// INPUTS:
//    r0    = Pointer to the associated CBuffer structure
//    r1,L1 = CBuffer Size
//    M1 = 1                                    (reserved)
//    r4 = frame size for the stream
//    r9 = pointer to stream Buffer             (reserved)
//    r6 = CBuffer read pointer
//    r8 = CBuffer write pointer
//    r7 = reserved by calling function         (reserved)
//
// OUTPUTS:
//    r6 = Adjusted CBuffer read pointer   
//    r1 = CBuffer Size
//
// TRASHED REGISTERS:
//    
//
// *****************************************************************************
.MODULE $M.frame_sync.distribute_input_stream_ind;
   .CODESEGMENT   FRAME_SYNC_IND_PM;
   .DATASEGMENT   DM;

$frame_sync.distribute_input_stream_ind:

   $push_rLink_macro;
   
   // Calculate data in buffer
   r8 = r8 - r6;
   if NEG r8 = r8 + r1;

   // Check for data insertion (Subtract Frame)
   r10 = r8 - r4;
   if NEG call $frame_sync.distribute_read_insert_ind;

   // r6 is adjusted Buffer Pointer, r1 is Buffer Size
   // r8 is amount of data in buffer
   // r10 is amount of data in buffer (after frame)

#ifdef FRAME_SYNC_DEBUG
   M[r0 + $frame_sync.DBG_MAX_OUT_LEV]=r8;  
#endif



    // r6 is adjusted Buffer Pointer, r1 is Buffer Size 
    // Calculate MIN data, save amount of data after Frame (r10) 
   call $frame_sync.analyze_stream_ind;
   
   jump $pop_rLink_and_rts;
.ENDMODULE;

// *****************************************************************************
// MODULE:
//    $M.frame_sync.distribute_sync_stream_ind
//
// DESCRIPTION:
//    This function is used for sync stream by the distribute function.  
//
// INPUTS:
//    r0    = Pointer to the associated CBuffer structure
//    r1,L1 = CBuffer Size
//    M1 = 1                                    (reserved)
//    r4 = frame size for the stream
//    r9 = pointer to stream Buffer             (reserved)
//    r6 = CBuffer read pointer
//    r8 = CBuffer write pointer
//    r7 = reserved by calling function         (reserved)
//
// OUTPUTS:
//    r6 = Adjusted CBuffer read pointer   
//    r1 = CBuffer Size
//
// TRASHED REGISTERS:
//    
//   
// *****************************************************************************
.MODULE $M.frame_sync.distribute_sync_stream_ind;
   .CODESEGMENT   FRAME_SYNC_IND_PM;
   .DATASEGMENT   DM;

$frame_sync.distribute_sync_stream_ind:
   $push_rLink_macro;
  
   // Calculate data in buffer
   r8 = r8 - r6;
   if NEG r8 = r8 + r1;

   // Check for data insertion (Subtract Frame)
   r10 = r8 - r4;
   if NEG call $frame_sync.distribute_read_insert_ind;

   // r6 is adjusted Buffer Pointer, r1 is Buffer Size
   // r8 is amount of data in buffer
   // r10 is amount of data in buffer (after frame)

   M[r9 + $framesync_ind.SYNC_AMOUNT_DATA_FIELD]=r10;

#ifdef FRAME_SYNC_DEBUG
   M[r0 + $frame_sync.DBG_MAX_OUT_LEV]=r8;  
   M[r0 + $frame_sync.DBG_MIN_OUT_LEV]=r10;  
   M[r0 + $frame_sync.DBG_PACKET_SIZE_FIELD]=r4;
   M[r0 + $frame_sync.DBG_MIN_IN_LEV]=NULL;
   M[r0 + $frame_sync.DBG_MAX_IN_LEV]=NULL;   
#endif

   jump $pop_rLink_and_rts;
.ENDMODULE;


// *****************************************************************************
// MODULE:
//    $M.frame_sync.distribute_output_stream_ind
//
// DESCRIPTION:
//    This function is used for output stream by the distribute function.  It
//    drops/inserts samples as required.
//
//
// INPUTS:
//    r0    = Pointer to the associated CBuffer structure
//    r1,L1 = CBuffer Size
//    M1 = 1                                    (reserved)
//    r4 = frame size for the stream
//    r9 = pointer to stream Buffer             (reserved)
//    r6 = CBuffer read pointer
//    r8 = CBuffer write pointer
//    r7 = reserved by calling function         (reserved)
//
// OUTPUTS:
//    r6 = Adjusted CBuffer read pointer   
//    r1 = CBuffer Size
//
//
// TRASHED REGISTERS:
//    
//
// *****************************************************************************
.MODULE $M.frame_sync.distribute_output_stream_ind;
   .CODESEGMENT   FRAME_SYNC_IND_PM;
   .DATASEGMENT   DM;

$frame_sync.distribute_output_stream_ind:

   // Set buffer pointer and Sample Per Frame
   I1 = r8;

   // calculate the amount of space
   r6 = r6 - r8;
   if LE r6 = r6 + r1;
   // always say it's 1 less so that buffer never gets totally filled up
   r6 = r6 - M1;
   
#ifdef FRAME_SYNC_DEBUG
   M[r0 + $frame_sync.DBG_MAX_OUT_LEV]=r6;  
#endif

   // Check space for frame
   M2 = r6 - r4;
   if POS jump done;
   
#ifdef FRAME_SYNC_DEBUG 
   r2 = M[r0 + $frame_sync.DBG_DROP_SAMPLES_COUNTER_FIELD];
   r2 = r2 - M2;
   M[r0 + $frame_sync.DBG_DROP_SAMPLES_COUNTER_FIELD] = r2;
#endif

   // Save number of samples dropped (negative)
   r2 = M2;
   M[r9 + $framesync_ind.DROP_INSERT_FIELD] = r2;
      
   // Throw away output to make room for frame
   r2 = M[I1,M2];    // Adjust Pointer

done:
   // Update buffer write pointer
   r6 = I1;
   M[r0 + $cbuffer.WRITE_ADDR_FIELD] = r6;
   rts;

.ENDMODULE;



// Called at end of frame processing. 
// Advance stream pointers
// Note.  Period will vary

.MODULE $M.frame_sync.update_streams_ind;
   .CODESEGMENT   FRAME_SYNC_IND_PM;
   .DATASEGMENT   DM;

$frame_sync.update_streams_ind:
   $push_rLink_macro;
   M1 = 1;
   call $block_interrupts;
   
   
jp_next_stream:
    // Get Stream Ptr.  Table is NULL Terminated
    r9 = M[r7];      
    if Z jump jp_stream_done;   
    
    // Get Update Function
    r2 = M[r9+$framesync_ind.UPDATE_FUNCPTR_FIELD];
    
    // Get CBuffer and Frame
    r0 = M[r9 + $framesync_ind.CBUFFER_PTR_FIELD];
#ifdef BASE_REGISTER_MODE
    r1 = M[r0 + $cbuffer.START_ADDR_FIELD];
    push r1;
    pop B1;
#endif    
    r1 = M[r0+$cbuffer.SIZE_FIELD];
    r4 = M[r9+$framesync_ind.FRAME_SIZE_FIELD];
    L1 = r1;
    
    // Call Updtae Function
    call r2;
    
    // Dummy read to advance pointer, r0=CBuffer Ptr to advance, r4 is amount to advance
    M0 = r4;
    r2 = M[r0];
    I1 = r2;
    r1 = M[I1,M0];
    r2 = I1;
    M[r0]=r2;
      
    r7 = r7 + 1;
    jump jp_next_stream;
      
jp_stream_done:
   call $unblock_interrupts;
   L1 = NULL;
#ifdef BASE_REGISTER_MODE
   push Null;
   pop B1;
#endif   
   jump $pop_rLink_and_rts;

.ENDMODULE;

// *****************************************************************************
// MODULE:
//    $M.frame_sync.update_input_streams_ind
//
// DESCRIPTION:
//    This function is used for input stream by the update function.  It
//    drops/inserts samples as required.
//
// INPUTS:
//    r0 = Pointer to the associated CBuffer structure
//    r1,L1,B1 = CBuffer Size                      (L1 reserved)
//    r4 = frame size for the stream
//    r9 = pointer to stream Buffer             
//    r7 = reserved by calling function         (reserved)
//
// OUTPUTS:
//    r0 = Pointer to CBuffer read pointer
//    r4 = Amount to adjust CBuffer read pointer
//
// TRASHED REGISTERS:
//  
//
// *****************************************************************************
.MODULE $M.frame_sync.update_input_streams_ind;
   .CODESEGMENT   FRAME_SYNC_IND_PM;

$frame_sync.update_input_streams_ind:

    // SPTBD - may need to add in some histeresis on the drop
    //          to prevent the threshold from being constantely hit
    
    // Drop data above threshold (data to drop)
    r3 = M[r9 + $framesync_ind.AMOUNT_DATA_FIELD];    // Amount of data minus one frame
    r2 = M[r9 + $framesync_ind.THRESHOLD_FIELD];
    r3 = r3 - r2;       
    if NEG jump done;
    
	// increase drop amount to include 1/2 of jitter value
    r2 = M[r9 + $framesync_ind.JITTER_FIELD];
    r2 = r2 ASHIFT -1;
    r3 = r3 + r2;

    // Save number of samples dropped (negative)
    r2 = M[r9 + $framesync_ind.DROP_INSERT_FIELD];
    r2 = r2 - r3;
    M[r9 + $framesync_ind.DROP_INSERT_FIELD] = r2;
   

#ifdef FRAME_SYNC_DEBUG
      r2 = M[r0 + $frame_sync.DBG_DROP_SAMPLES_COUNTER_FIELD];
      r2 = r2 + r3;
      M[r0 + $frame_sync.DBG_DROP_SAMPLES_COUNTER_FIELD] = r2;
#endif
   
   // Adjust buffer advancement
   r4 = r4 + r3;
done:
   r0 = r0+$cbuffer.READ_ADDR_FIELD;
   rts;

.ENDMODULE;

// *****************************************************************************
// MODULE:
//    $M.frame_sync.update_sync_streams_ind
//
// DESCRIPTION:
//    This function is used for sync stream by the update function.  It
//    drops/inserts samples as required.
//
// INPUTS:
//    r0 = Pointer to the associated CBuffer structure
//    r1,L1,B1 = CBuffer Size                      (L1 reserved)
//    r4 = frame size for the stream
//    r9 = pointer to stream Buffer             
//    r7 = reserved by calling function         (reserved)
//
// OUTPUTS:
//    r0 = Pointer to CBuffer read pointer
//    r4 = Amount to adjust CBuffer read pointer
//
// TRASHED REGISTERS:
//  
//
// *****************************************************************************
.MODULE $M.frame_sync.update_sync_streams_ind;
   .CODESEGMENT   FRAME_SYNC_IND_PM;

$frame_sync.update_sync_streams_ind:

    // Current Drop/Inserts
    r6 = M[r9 + $framesync_ind.DROP_INSERT_FIELD];

    // Buffer Threshold
    r2 = M[r9 + $framesync_ind.JITTER_FIELD];
#ifdef FRAME_SYNC_DEBUG
    M[r0 + $frame_sync.DBG_CBUFFER_COPY_THRESHOLD_FIELD]=r2;
#endif
    // Amount of data in buffer minus one frame
    r3 = M[r9 + $framesync_ind.SYNC_AMOUNT_DATA_FIELD];    
   
    // Drop data above threshold (data to drop)
    r3 = r3 - r2;       
    if NEG jump jp_drop_done;
	   // increase drop amount to include 1/2 of jitter value
      r2 = r2 ASHIFT -1;
      r3 = r3 + r2;
      // Save number of samples dropped (negative)
      r6 = r6 - r3;
#ifdef FRAME_SYNC_DEBUG
      r2 = M[r0 + $frame_sync.DBG_DROP_SAMPLES_COUNTER_FIELD];
      r2 = r2 + r3;
      M[r0 + $frame_sync.DBG_DROP_SAMPLES_COUNTER_FIELD] = r2;
#endif
      // Adjust buffer advancement
      r4 = r4 + r3;
jp_drop_done:

   // Get Drop/Insertion from Sync stream
   r5 = M[r9 + $framesync_ind.SYNC_POINTER_FIELD];
   r3 = M[r5 + $framesync_ind.DROP_INSERT_FIELD];       // (+) for insertion, (-) for drops
   if Z jump jp_done;
      // Clear Drop/Insert and scale
      M[r5 + $framesync_ind.DROP_INSERT_FIELD]=NULL;
      r2 = M[r9 + $framesync_ind.SYNC_MULTIPLIER_FIELD];
      r3 = r3 * r2 (int);
      // r6 = Current Drop(-)/Insert(+) for this stream
      // r3 = Drop(-)/Insert(+) for Sync stream

      // Combine Drop/Inserts between streams
      r3 = r3 - r6;
      // Clear Drop/Insert for stream
      r6 = NULL;
      // If Combined Drop/Insert exceeds Jitter the skip
      r2 = M[r9 + $framesync_ind.JITTER_FIELD];
      NULL = r3 - r2;
      if GT jump jp_done;
      NULL = r3 + r2;
      if NEG jump jp_done;

         // Apply Combined (-)Drop/(+)Insert to maintain sync
         r4 = r4 - r3;      

#ifdef FRAME_SYNC_DEBUG
         r2 = M[r0 + $frame_sync.DBG_INSERT_SAMPLES_COUNTER_FIELD];
         NULL = r3;
         if POS r2 = r2 + r3;
         M[r0 + $frame_sync.DBG_INSERT_SAMPLES_COUNTER_FIELD] = r2;

         r2 = M[r0 + $frame_sync.DBG_DROP_SAMPLES_COUNTER_FIELD];
         NULL = r3;
         if NEG r2 = r2 - r3;
         M[r0 + $frame_sync.DBG_DROP_SAMPLES_COUNTER_FIELD] = r2;
#endif

jp_done:
   M[r9 + $framesync_ind.DROP_INSERT_FIELD]=r6;
   r0 = r0+$cbuffer.READ_ADDR_FIELD;
   rts;

.ENDMODULE;

// *****************************************************************************
// MODULE:
//    $M.frame_sync.update_output_streams_ind
//
// DESCRIPTION:
//    This function is used for output stream by the update function.  It calls
//    the analyze function to monitor the buffer state and drops/inserts samples
//    as required.
//
// INPUTS:
//    r0 = Pointer to the associated CBuffer structure
//    r1,L1,B1 = CBuffer Size                      (L1 reserved)
//    r4 = frame size for the stream
//    r9 = pointer to stream Buffer
//    r7 = reserved by calling function         (reserved)
//
// OUTPUTS:
//    r0 = Pointer to CBuffer read pointer
//    r4 = Amount to adjust CBuffer read pointer
//
// TRASHED REGISTERS:
//    rMAC,r0,r2,r3,r4,r6,r8
//
// *****************************************************************************
.MODULE $M.frame_sync.update_output_streams_ind;
   .CODESEGMENT   FRAME_SYNC_IND_PM;

$frame_sync.update_output_streams_ind:

   $push_rLink_macro;
   // Get Buffer Pointers
   r6 = M[r0 + $cbuffer.WRITE_ADDR_FIELD];
   r8 = M[r0 + $cbuffer.READ_ADDR_FIELD];

   // Calculate data in buffer (before frame is added)
   r10 = r6 - r8;
   if NEG r10 = r10 + r1;
      
   call $frame_sync.analyze_stream_ind;

    // Drop data above threshold
    r3 = M[r9 + $framesync_ind.AMOUNT_DATA_FIELD]; 
    r2 = M[r9 + $framesync_ind.THRESHOLD_FIELD];
    r3 = r3 - r2;       
    if NEG jump done;
	
	// increase drop amount to include 1/2 of jitter value
    r2 = M[r9 + $framesync_ind.JITTER_FIELD];
    r2 = r2 ASHIFT -1;
    r3 = r3 + r2;

    // Can't drop more than a frame
    NULL = r4 - r3;
    if NEG r3=r4;
   
    // Save number of samples dropped (negative)
    r2 = M[r9 + $framesync_ind.DROP_INSERT_FIELD];
    r2 = r2 - r3;
    M[r9 + $framesync_ind.DROP_INSERT_FIELD] = r2;
    
#ifdef FRAME_SYNC_DEBUG
      r2 = M[r0 + $frame_sync.DBG_DROP_SAMPLES_COUNTER_FIELD];
      r2 = r2 + r3;
      M[r0 + $frame_sync.DBG_DROP_SAMPLES_COUNTER_FIELD] = r2;
#endif

   // Reduce insertion (i.e. drop samples)
   r4 = r4 - r3;   
done:
   r0 = r0+$cbuffer.WRITE_ADDR_FIELD;
   jump $pop_rLink_and_rts;
.ENDMODULE;


// *****************************************************************************
// MODULE:
//    $M.frame_sync.analyze_stream_ind
//
// DESCRIPTION:
//    This function calculates the bufferring thresholds
//
// INPUTS:
//    M1 = 1    (reserved)
//    r0 = Pointer to the associated CBuffer structure  (reserved)
//    r1,L1,B1 = CBuffer Size                              (reserved)
//    r4 = frame size for the stream                    (reserved)
//    r10 = amount of data in the buffer
//    r7,r9,r6 = reserved by calling function           (reserved)
//
// OUTPUTS:
//
// TRASHED REGISTERS:
//    r2,r3,r10
//
// *****************************************************************************

.MODULE $M.frame_sync.analyze_stream_ind;
   .CODESEGMENT   FRAME_SYNC_IND_PM;

$frame_sync.analyze_stream_ind:

    // Save the amount of data
    M[r9 + $framesync_ind.AMOUNT_DATA_FIELD]=r10;
  
#ifdef FRAME_SYNC_DEBUG
   M[r0 + $frame_sync.DBG_MIN_OUT_LEV]=r10;  
#endif

    // Update MIN(r2) / MAX(r3)   
    r2 = M[r9 + $framesync_ind.MIN_FIELD];
    NULL = r2 - r10;
    if POS r2=r10;
    r3 = M[r9 + $framesync_ind.MAX_FIELD];
    NULL = r3 - r10;
    if NEG r3=r10;
    
#ifdef FRAME_SYNC_DEBUG
   M[r0 + $frame_sync.DBG_PACKET_SIZE_FIELD]=r4;
#endif
    
    // Check timer
    r10 = M[r9 + $framesync_ind.COUNTER_FIELD];
    r10 = r10 - M1;
    if LE jump jp_threshold_reset;
        M[r9 + $framesync_ind.MIN_FIELD]=r2;
        M[r9 + $framesync_ind.MAX_FIELD]=r3;
        M[r9 + $framesync_ind.COUNTER_FIELD] = r10;    
        rts;
 jp_threshold_reset:
 
#ifdef FRAME_SYNC_DEBUG
   M[r0 + $frame_sync.DBG_MIN_IN_LEV]=r2;
   M[r0 + $frame_sync.DBG_MAX_IN_LEV]=r3;   
#endif

    // Reset MIN/MAX
    M[r9 + $framesync_ind.MAX_FIELD] = NULL;
    M[r9 + $framesync_ind.MIN_FIELD] = r4;
   
    // Threshold = MAX(r3) - MIN(r2) + Jitter(r10)
    r10 = M[r9 + $framesync_ind.JITTER_FIELD];
    r3 = r3 - r2;
    r3 = r3 + r10;
    if NEG r3 = NULL;
    M[r9 + $framesync_ind.THRESHOLD_FIELD] = r3;
 
#ifdef FRAME_SYNC_DEBUG
   M[r0 + $frame_sync.DBG_CBUFFER_COPY_THRESHOLD_FIELD]=r3;
#endif

    r10 = 120;	// SP.  one second update of Threshold
    M[r9 + $framesync_ind.COUNTER_FIELD] = r10; 
    rts;
    
.ENDMODULE;

// *****************************************************************************
// MODULE:
//    $M.frame_sync.distribute_read_insert_ind
//
// DESCRIPTION:
//    Insert samples into buffer
//
// INPUTS:
//    r0    = Pointer to the associated CBuffer structure
//    r1,L1 = CBuffer Size
//    M1 = 1                                    (reserved)
//    r4 = frame size for the stream
//    r9 = pointer to stream Buffer             (reserved)
//    r6 = CBuffer read pointer
//    r7 = reserved by calling function         (reserved)
//    r8  = amount of data in buffer            (reserved)
//    r10 = Number of samples to insert (negative)
// OUTPUTS:
//    r6 = Adjusted CBuffer read pointer   
//    r1 = CBuffer Size
//
// TRASHED REGISTERS: 
//    r2,do_loop
//
// *****************************************************************************
.MODULE $M.frame_sync.distribute_read_insert_ind;
   .CODESEGMENT   FRAME_SYNC_IND_PM;

$frame_sync.distribute_read_insert_ind:

   // Number of samples to insert
      r10 = NULL - r10;

	  // increase insertion amount to include 1/2 of jitter value
      r2 = M[r9 + $framesync_ind.JITTER_FIELD];
      r2 = r2 ASHIFT -1;
      r10 = r10 + r2;

      // Update Debug statistics (Samples Inserted)
#ifdef FRAME_SYNC_DEBUG
      r2 = M[r0 + $frame_sync.DBG_INSERT_SAMPLES_COUNTER_FIELD];
      r2 = r2 + r10;
   M[r0 + $frame_sync.DBG_INSERT_SAMPLES_COUNTER_FIELD] = r2;
#endif

   // Save number of samples inserted (positive)
   r2 = M[r9 + $framesync_ind.DROP_INSERT_FIELD];
   r2 = r2 + r10;
   M[r9 + $framesync_ind.DROP_INSERT_FIELD] = r2;

   // Insert repeated samples to make frame
   I1 = r6;
   r2 = M[I1,-1];
   do lp_repeat;
      M[I1,-1]=r2;
   lp_repeat:
   // Set Start of Frame and Update buffer pointer
   r2 = M[I1,1];    
   r6  = I1;
   M[r0 + $cbuffer.READ_ADDR_FIELD] = r6;
   rts;

.ENDMODULE;


#endif
