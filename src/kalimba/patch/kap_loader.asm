// *****************************************************************************
// Copyright (C) Cambridge Silicon Radio Limited 2005-2014        http://www.csr.com
// Part of ADK 3.5
//
// $Change: 1172207 $  $DateTime: 2011/12/09 20:46:31 $
// *****************************************************************************

// *****************************************************************************
// NAME:
//    KAP Loader
//
// DESCRIPTION:
//    This library provides provides a mechanism for loading a KAP file
//    from either the Flash File System or the PsStore.  It include functions 
//    for loading KAP files.  These function will block until the KAP file is 
//    loaded.  Before calling these functions the stack,interrupt,flash,timer, 
//    messaging, and pskey system modules must have been initialized.  Also,
//    interrupts must be enabled and these function can not be called from an
//    interrupt service routine (ISR)
//
//    $KapLoader.LoadandRunApp
//          This function loads an Application KAP file from the Flash File System
//          and jumps to it's "main" function.  This function never returns.
//
//    $KapLoader.Load_Kap_By_File_Path
//          This function loads a KAP file from the Flash File System based on file path
//
//    $KapLoader.LoadPatch
//          This function loads a KAP file from a PsKey.  It will call the "main" function
//          of the patch if specified then return.   The PM cache is reduced durring this
//          operation providing 512 words of transitory program memory that can be used
//          for the "main" function of the patch.
//
//    $KapLoader.LoadPatchFromPatch
//          This function performs the same operation as $KapLoader.LoadPatch.  It is intended
//          to be called from a patches "main" function allowing one patch to load another.
//
//  --------------------------------------------------------------------------------------
//
//    The following utility functions are provided for inserting patches in the code.  These
//    functions should only be called from within the patch's "main" function.
//    
//    $KapLoader.InsertPatchInProgramROM
//      Inserts a patch function into code running from ROM.  The function is inserted as
//      an absolute jump and will overwrite two program word at the specified address  
//
//    $KapLoader.InsertPatchInProgramRAM
//      Inserts a patch function into code running from RAM.  The function is inserted as
//      a relative jump and will overwrite one program word at the specified address       
//
// *****************************************************************************



#include "stack.h"
#include "flash.h"
#include "message.h"
#include "architecture.h"
#include "pskey.h"

// Kap file TAG IDs
.CONST $GO_TAG_ID           0;
.CONST $PM_TAG_ID           1;
.CONST $DM_TAG_ID           2;
.CONST $DATA_TAG_ID         3;
.CONST $END_TAG_ID          5;
.CONST $SIGNATURE_TAG_ID    6;
.CONST $ZERO_RAM_TAG_ID     7;
.CONST $NOP_TAG_ID          8;

// Message IDs
.CONST $M.KAP.VMMSG.FILE_INDEX      0x1020;
.CONST $M.KAP.VMMSG.FILE_NAME       0x1021;
.CONST $M.KAP.VMMSG.CORE_READY      0x1022;

// Useful constants
.CONST $PM_HI_TO_LO    ($PMWIN_LO_START - $PMWIN_HI_START);
.CONST $PM_LO_TO_HI    ($PMWIN_HI_START - $PMWIN_LO_START);

.CONST $KAP_LOADER.WORK_BUFFER_SIZE             128;
.CONST $KAP_LOADER.JUMP_INSTRUCTION_MS          0xDDF0;

// Internal data structure for loader
.CONST  $KAP_LOADER.GET_DATA_FUNC_PTR_FIELD     0;
.CONST  $KAP_LOADER.AMOUNT_DATA_FUNC_PTR_FIELD  1;
.CONST  $KAP_LOADER.DATA_TAG_FUNC_PTR_FIELD     2;
.CONST  $KAP_LOADER.INPUT_ADDRESS_FIELD         3;
.CONST  $KAP_LOADER.WRITE_POINTER_FIELD         4;
.CONST  $KAP_LOADER.BASE_POINTER_FIELD          5;
.CONST  $KAP_LOADER.STRUC_SIZE                  6;

// *****************************************************************************
// MODULE:
//    $KapLoader.ProcessKap
//
// DESCRIPTION:
//    Common KAP loader.   
//
// INPUTS:
//    - r7 = Data Structure for loader
//    - I0 = Input Data Pointer 
//    - r9 = Flash Address for (ROM loader)
//
// OUTPUTS:
//    - none
//
// TRASHED REGISTERS:
//    all
//
// NOTES:
//      This function must be called from the main thread.  It may
//      block waiting for input data.
//
// *****************************************************************************
.MODULE $M.KapLoader_Loader;
   .CODESEGMENT KAP_LOADER_COMMON_PM;
   .DATASEGMENT DM;
  
    // Variable for entrypoint after kap load
    .VAR kap_entry_point=0;
    
$KapLoader.ProcessKap:
    $push_rLink_macro;
    // Clear KAP entry point variable.  Will be set by PM tags
    M[kap_entry_point]=Null;
    // Useful constants in modify registers
    M1 = 1;
    M3 = 3;
 
    // r6 is the read input function
    r6 = M[r7 + $KAP_LOADER.GET_DATA_FUNC_PTR_FIELD];
    call r6;        // Get Input Data Function
    
    // The file is a header (one xap word indicating the DSP revision), followed by a stream of sections. 
    r0 = M[I0,1];

work_through_file:
    call r6;        // Get Input Data Function
        
    r0 = M[I0,1];
    r1 = r0 LSHIFT -8;           // r1 = tag ID for this section
    r10 = r0 LSHIFT 16;
    
    // Check for Spacer NOP(8)
    NULL = r1 - $NOP_TAG_ID;
    if Z jump work_through_file;
    
    r0 = M[I0,1];
    r10 = r10 + r0,   r0 = M[I0,1];
    r2 = r0 LSHIFT 16;

    // SP.  Check for ZERO_RAM.  Should not be here but it is
    NULL = r1 - $ZERO_RAM_TAG_ID;
    if Z jump work_through_file;

    r0 = M[I0,1];
    r0 = r0 OR r2;
    r10 = r10 - 2;               // r10 = number of 16-bit words to process
    I1 = r0;                     // I1 = destination address
    
    // r1    = tag
    // r10   = length
    // r0/I1 = Address

    // Read 4 words.  Check for Signature
    Null = r1 - $SIGNATURE_TAG_ID;
    if Z jump work_through_file;

    // Align data requirements with input window
    r3 = M[r7 + $KAP_LOADER.AMOUNT_DATA_FUNC_PTR_FIELD];
    call r3;
        
    Null = r1 - $PM_TAG_ID;
    if Z jump PM_section;
    Null = r1 - $DM_TAG_ID;
    if Z jump DM_section;
    Null = r1 - $DATA_TAG_ID;
    if Z jump Data_Section;
    
    // should be  GO/END  
    jump $pop_rLink_and_rts;
      
    // -- Handle DATA section in KAP --
Data_Section:
    r3 = M[r7 + $KAP_LOADER.DATA_TAG_FUNC_PTR_FIELD];
    call r3;
    jump work_through_file;
    
    // -- Handle PM section in KAP --
PM_section:
    
    // Remember target address of last PM section
    // Multi-Kap code only has one PM section
    // Patches insert entry point as a PM section before END
    M[kap_entry_point]=r0;
    
    // r2 is XOR'd into r3 to flip M2 between
    // a) the step forward from the HI PM window to the LO PM window
    // b) the step back from LO PM to HI PM, but advancing one word.
    r3 = $PM_HI_TO_LO;
    r2 = ($PM_LO_TO_HI+1) ^ $PM_HI_TO_LO;
    
    I1 = I1 + $PMWIN_HI_START;
    PM_block_loop:
    do copy_pm_loop;
        M2 = r3,
        r0 = M[I0,M1];
        r3 = r3 XOR r2,
        M[I1,M2] = r0;
    copy_pm_loop:
    r10 = r8;
    if LE jump work_through_file;
    call r6;        // Get Input Data Function  
    jump PM_block_loop;
         
    // -- Handle DM section in KAP --
DM_section:
    // Fetch 16-bit words from I0, shifting them bytewise into
    // r2 and writing whenever we've got a full 24-bit word.
    r3 = 3;
    DM_block_loop:
        do copy_dm_loop;
            r0 = M[I0,1];
            r1 = r0 LSHIFT -8;
            r2 = r2 LSHIFT 8;
            r2 = r2 OR r1;
            r3 = r3 - 1;
            if NZ jump skip_1; 
                r3 = M3,
                M[I1,M1] = r2;
            skip_1:
            r1 = r0 AND 0xFF;
            r2 = r2 LSHIFT 8;
            r2 = r2 OR r1;
            r3 = r3 - 1;
            if NZ jump skip_2; 
                r3 = M3,
                M[I1,M1] = r2;
            skip_2:
            nop;
        copy_dm_loop:
        
        r10 = r8;
        if LE jump work_through_file;
        call r6;        // Get Input Data Function
    jump DM_block_loop;
.ENDMODULE;    


// *****************************************************************************
// MODULE:
//    $KapLoader.LoadPatch
//
// DESCRIPTION:
//    Called from application after basic initialization to load a patch
//    from a PsKey
//
// INPUTS:
//    - r1 = First PsKey of Patch
//    - r2 = Pointer to a scratch buffer used during PsKey reads
//
// OUTPUTS:
//    - none
//
// TRASHED REGISTERS:
//    all
//
// NOTES:
//      The function is called in the main thread.  It will block until
//      the KAP is loaded.  The function will request and wait for PsKey
//      as needed to load the complete KAP file.  A portion of the PM Cache 
//      is reserved for a configuration function loaded with the patch. 
//      This function is called after the patch is loaded.  When the function
//      returns the full PM CACHE is restored.
//
// *****************************************************************************

// *****************************************************************************
// MODULE:
//    $KapLoader.LoadPatchFromPatch
//
// DESCRIPTION:
//    Called from a patch configuration function allowing one patch to
//    load another.
//
// INPUTS:
//    - r1 = First PsKey of Patch
//
// OUTPUTS:
//    - none
//
// TRASHED REGISTERS:
//    all
//
// NOTES:
//     When loading multiple patches the portion of the PM CACHE set aside
//     for the configuration function must be split between patches so as
//     one configuration function doesn't over-write another.
//
// *****************************************************************************
.MODULE $M.KapLoader_PsStore;
   .CODESEGMENT KAP_LOADER_PSSTORE_PM;
   .DATASEGMENT DM;

   // Descriptor for PsKey read request
   .VAR ps_key_struc[$pskey.STRUC_SIZE];

   // Descriptor used for loading KAP files from the PsStore
   .VAR ram_loader_struc[$KAP_LOADER.STRUC_SIZE] =
           &setup_ram_windows_adjust,    // GET_DATA_FUNC_PTR_FIELD
           &setup_ram_data_available,    // AMOUNT_DATA_FUNC_PTR_FIELD
           &setup_ram_data_tag,          // DATA_TAG_FUNC_PTR_FIELD    
           0 ...; 
   
// -------------------------------------------------------------------------

$KapLoader.LoadPatchFromPatch:
    r2 = M[&ram_loader_struc + $KAP_LOADER.BASE_POINTER_FIELD];
$KapLoader.LoadPatch:
    // Initialize Buffering and PsKey access
    M[&ram_loader_struc + $KAP_LOADER.INPUT_ADDRESS_FIELD] = r1;
    I0  = r2;
    M[&ram_loader_struc + $KAP_LOADER.WRITE_POINTER_FIELD] = r2;
    M[&ram_loader_struc + $KAP_LOADER.BASE_POINTER_FIELD]  = r2;

    $push_rLink_macro;
    
    // Save State
    r0 = M[$PM_WIN_ENABLE];
    r1 = M[$PM_FLASHWIN_CACHE_SIZE];
    pushm <r0,r1>;
    // Reduce Program Cache from 1K to 512 bytes 
    // This provides temprary code space for conditional patching code
    // Map program RAM into Data Space
    r0 = 1;
    M[$PM_FLASHWIN_CACHE_SIZE]=r0;
    M[$PM_WIN_ENABLE] = r0; 
    
    // Process Patch
    r7 = &ram_loader_struc;
    call $KapLoader.ProcessKap;
    
    r2 = M[$M.KapLoader_Loader.kap_entry_point];
    if NZ call r2;
    
    // Restore Program Cache
    // Restore PM Window in Data Memory mapping
    popm <r0,r1>;
    M[$PM_WIN_ENABLE] = r0;
    M[$PM_FLASHWIN_CACHE_SIZE]=r1;

    // pop rLink from stack
    jump $pop_rLink_and_rts;
    

// *****************************************************************************
//  FUCTION: 
//  DESCRIPTION: Handler for receiving a PsKey
//  INPUTS:
//    r1 = Key ID
//    r2 = Buffer Length; $pskey.FAILED_READ_LENGTH on failure
//    r3 = Payload.  Key ID Plus data
// *****************************************************************************
PsKeyHandler:
    // error checking - check if read failed
    // if so, DSP default values will be used instead of PsKey values.
    Null = r2 - $pskey.FAILED_READ_LENGTH;
    if Z jump jp_Failure;
    NULL = r2 - 2;
    if LT jump jp_Failure;
   
    // Data Structure for Patch Load
    r4 = 0xFFFF;    // Mask to remove sign extension??
    
    // First two Fields in payload are the PsKeyID just read and
    // The next PsKeyID in the chain (zero for last key)
    r0 = M[r3 + 1];
    r0 = r0 AND r4;     // Remove any sign extension?
    M[&ram_loader_struc + $KAP_LOADER.INPUT_ADDRESS_FIELD] = r0;

    // Get Buffer Pointer
    r0 = M[&ram_loader_struc + $KAP_LOADER.WRITE_POINTER_FIELD];
    r1 = M[&ram_loader_struc + $KAP_LOADER.BASE_POINTER_FIELD];
    I1 = r0;
    L1 = $KAP_LOADER.WORK_BUFFER_SIZE;
    push r1;
    pop  B1;

    // Copy the KAP file section to the working buffer
    r10 = r2 - 2;
    I0  = r3 + 2;
    do lp_copy_loop;
        r0 = M[I0,1];
        r0 = r0 AND r4;     // Remove any sign extension?
        M[I1,1]=r0;
    lp_copy_loop:
    
    // Save Buffer Pointer
    r0 = I1;
    M[&ram_loader_struc + $KAP_LOADER.WRITE_POINTER_FIELD] = r0;
    L1 = Null;
    push Null;
    Pop  B1;    
    rts;
jp_Failure:
    // Signal Failure
    M[&ram_loader_struc + $KAP_LOADER.WRITE_POINTER_FIELD] = Null;
    rts;
    
// --------------------------------------------------------
// ----- Helper Functions -------
setup_ram_data_tag:
    // Error:  Can't download DATA sections
    jump jp_rd_error;
    
setup_ram_windows_adjust:
    // Get Amount of data in Buffer
    r9 = $KAP_LOADER.WORK_BUFFER_SIZE;
    r0 = M[r7 + $KAP_LOADER.WRITE_POINTER_FIELD];
    r0 = r0 - I0;
    if NEG r0 = r0 + r9;
    // If there are at lease four word, continue
    NULL = r0 - 4;
    if GE rts;
    
    // Initialize and wait for PsKey Read
setup_ram_windows:
    r1 = M[r7 + $KAP_LOADER.INPUT_ADDRESS_FIELD]; // KsKey to Read
    if Z jump jp_no_key;
    
    pushm <r2,r3,r6,r10,rLink>;  
    r2 = r1;
    r1 = &ps_key_struc;
    r3 = &PsKeyHandler;
    call $pskey.read_key;     // uses r0-r6, r10, DoLoop
    popm <r2,r3,r6,r10,rLink>;  

    // Wait for Write Pointer to change (if zero then error) - TBD  
    r0 = M[r7 + $KAP_LOADER.WRITE_POINTER_FIELD];
jp_waiting:
    r1 = M[r7 + $KAP_LOADER.WRITE_POINTER_FIELD];
    NULL = r1-r0;
    if Z jump jp_waiting;
    NULL = r1;
    if Z jump jp_rd_error;
    
setup_ram_data_available:
    // Get Amount of data in Buffer
    r9 = $KAP_LOADER.WORK_BUFFER_SIZE;
    r4 = M[r7 + $KAP_LOADER.WRITE_POINTER_FIELD];
    r8 = r4 - I0; 
    if NEG r8 = r8 + r9;
    // Set r8/r10 (r8 is data in section remaining after buffered data is processed)
    r8 = r10 - r8;
    if POS r10 = r10 - r8;
    rts;

jp_no_key:
    // No key to load.  Should only be End Tag remaining
    NULL = r0 - 2;
    if NEG jump jp_rd_error;
    r4 = M[I0,0];
    NULL = r4 - 0x0500;
    if Z rts;

jp_rd_error:
    // Clear the post-load function pointer  
    M[$M.KapLoader_Loader.kap_entry_point]=Null;
    // We are in a call, one level down from $KapLoader.ProcessKap
    // Fake the rts and terminate
    jump $pop_rLink_and_rts;
   
.ENDMODULE;



// *****************************************************************************
// MODULE:
//    $KapLoader.LoadandRunApp
//
// DESCRIPTION:
//    Called in Multi-kap systems from core layer to load the application
//    KAP file from the Flash file system 
//
// INPUTS:
//    - none
//
// OUTPUTS:
//    - none
//
// TRASHED REGISTERS:
//    all
//
// NOTES:
//      The function is called in the main thread.  It waits for the file handle
//      for the kap file and sends a message to the Firmware to get the Flash 
//      address of the file.  It then load the KAP file.  Finally it jumps
//      to the applications "main" function.  
//
//  Register Message handler RCV_FILE_INDEX     <-- VM
//  Register Message handler RCV_FLASH_ADDRESS  <-- FW
//  Send Message short (GET_FLASH_ADDRESS)      --> FW
//
// *****************************************************************************
    
// *****************************************************************************
// MODULE:
//    $KapLoader.Load_Kap_By_File_Path
//
// DESCRIPTION:
//    Called in Multi-kap systems from application layer to load the 
//    KAP file for a middle layer from the Flash file system 
//
// INPUTS:
//    - r5 - pointer to array containing the file path to the KAP file
//    - r4 = Length of text string
//
// OUTPUTS:
//    - none
//
// TRASHED REGISTERS:
//    all
//
// NOTES:
//      The function is called in the main thread.  It sends the file path to 
//      the VM.  It waits for the file handle for the kap file and sends a 
//      message to the Firmware to get the Flash address of the file.  
//      It then load the KAP file.    
//
//  Send Message long (GET_FILE_INDEX)          --> VM
//
// *****************************************************************************

.MODULE $M.KapLoader_FlashFileSystem;
   .CODESEGMENT KAP_LOADER_FLASH_FS_PM;
   .DATASEGMENT DM;

    // Descriptors for Message Handles
    .VAR get_file_index_message_struc[$message.STRUC_SIZE];
    .VAR get_flash_address_message_struc[$message.STRUC_SIZE];
    
    // Descriptor used for loading KAP files from the Flash File System
    .VAR rom_loader_struc[$KAP_LOADER.STRUC_SIZE] =
           &setup_flash_windows_adjust,    // GET_DATA_FUNC_PTR_FIELD
           &setup_flash_data_available,    // AMOUNT_DATA_FUNC_PTR_FIELD
           &setup_flash_data_tag,          // DATA_TAG_FUNC_PTR_FIELD    
           0 ...; 
           
// -------------------------------------------------------------------
$KapLoader.LoadandRunApp:
    // SP.  Function never returns so do not need to protect rLink  
    // Flash Address Handler
    r1 = &get_flash_address_message_struc;
    r2 = $MESSAGE_FILE_ADDRESS;
    r3 = &ReceiveFlashAddress;
    call $message.register_handler;
    // File Index Handler
    r1 = &get_file_index_message_struc;
    r2 = $M.KAP.VMMSG.FILE_INDEX;
    r3 = &ReceiveFileID;
    call $message.register_handler;
 
    // Clear flag holding Flash Address of KAP file
    M[&rom_loader_struc + $KAP_LOADER.INPUT_ADDRESS_FIELD]=NULL;

    // Signal VM we are ready to receive the handle
    // of the application KAP file
    r2 = $M.KAP.VMMSG.CORE_READY;
    call $message.send_short;
    
    // Load application KAP file
    call WaitForKapFile;
   
    // Jump to Application's main function
    r0 = M[$M.KapLoader_Loader.kap_entry_point];
    jump r0;
    
// -------------------------------------------------------------------
$KapLoader.Load_Kap_By_File_Path:
    $push_rLink_macro;
    // Clear flag
    M[&rom_loader_struc + $KAP_LOADER.INPUT_ADDRESS_FIELD]=NULL;
    // Send file path to VM
    r3 = $M.KAP.VMMSG.FILE_NAME;
    call $message.send_long;
    $pop_rLink_macro;
    // SP.  Fall-through to load operation
    
// -------------------------------------------------------------------
WaitForKapFile:
    r9 = M[&rom_loader_struc + $KAP_LOADER.INPUT_ADDRESS_FIELD];
    if Z jump WaitForKapFile;
        
    // Save State and disbale interupts
    $push_rLink_macro;
    call $block_interrupts;
    r0 = M[$PM_WIN_ENABLE];
    r1 = M[$FLASHWIN1_CONFIG];
    r2 = M[$FLASH_WINDOW1_START_ADDR];
    pushm <r0,r1,r2>;
    // Configure Flash/ROM window (No Sign Extension)
    // Map program RAM into Data Space
    r0 = 1;
    M[$FLASHWIN1_CONFIG] = r0;       
    M[$PM_WIN_ENABLE]    = r0; 
        
    // Map Window to flash address (r9)
    call $setup_flash_windows;           // ROM loader code
    // I0 points into Flash Window in data space
    // r9 advanced by window size
    
    r7 = &rom_loader_struc;
    call $KapLoader.ProcessKap;
    
    // Rstore State and re-enable interupts  
    popm <r0, r1,r2>;
    M[$PM_WIN_ENABLE] = r0;
    M[$FLASHWIN1_CONFIG] = r1;
    M[$FLASH_WINDOW1_START_ADDR] = r2;
    call $unblock_interrupts;
    jump $pop_rLink_and_rts;
   
// *****************************************************************************
//  FUNCTION: ReceiveFileID
//  DESCRIPTION:
//     Message Handler.  Recieve file handle for a KAP file
//  INPUTS:
//      - r0 = message ID     ($M.KAP.VMMSG.FILE_INDEX)
//      - r1 = message Data 0 (VM file handle)
// *****************************************************************************
ReceiveFileID:
    // Request Flash Addess of file
    r2 = $MESSAGE_FILE_ADDRESS;     //    - r2 = message ID
    r3 = r1;                        //    - r3 = message Data 0 = File Index
    jump $message.send_short;
   
// *****************************************************************************
//  FUNCTION: ReceiveFlashAddress
//  DESCRIPTION:
//     Message Handler.  Recieve address in Flash for a KAP file
//  INPUTS:
//      - r0 = message ID     ($MESSAGE_FILE_ADDRESS)
//      - r1 = message Data 0 (VM file handle)
//      - r2 = message Data 1 (lower 16bits of address)
//      - r3 = message Data 2 (upper 16bits of address) 
// *****************************************************************************
ReceiveFlashAddress:
    // convert from MS and LS words to a 24bit word
    r3 = r3 LSHIFT 16;
    r2 = r2 AND 0xFFFF;
    r2 = r2 + r3;
    // r2 holds the address in flash/ROM of the DATA section of the kap file we're reading     
    // On KAL_ARCH 3 chips the fw fills in the memory location above with an address in units of 32-bits
    // for this code though we keep M[kap_flash_address] holding the address in units of 16-bits.
    r2 = r2 LSHIFT 1;
    M[&rom_loader_struc + $KAP_LOADER.INPUT_ADDRESS_FIELD]=r2;
    rts;
    
// -----------------------------------------------------------------------
// --- Helper functions ---
setup_flash_data_tag:
   // reset r9 to current FLASH address 
    r0 = ($FLASHWIN1_START + $FLASHWIN1_SIZE) - I0;
    // SP.  window is on even boundry adjust r9
    r9 = r9 AND 0xFFFFFE;
    r9 = r9 - r0;
    // Save FLASH Address data RAM (I1) and advance r9 over data
    // r9 is in units of 16-bits, whereas $FLASH_WINDOW1_START_ADDR is in units of 32-bits 
    r1 = r9 LSHIFT -1;
    r9 = r9 + r10, M[I1,M1]=r1;
    // re-align window to next tag after data
    jump $setup_flash_windows;          // ROM loader Code 
setup_flash_windows_adjust:
   // Make sure it's safe to fetch 4 words from I0 before we do so
   Null = I0 - ($FLASHWIN1_START + $FLASHWIN1_SIZE - 4);
   if LT rts;
   // Advance DATA Window into FLASH
   // Realign flash window so I0 is at the start     
   r0 = ($FLASHWIN1_START + $FLASHWIN1_SIZE) - I0;
   r9 = r9 - r0;
   // Move flash window to address given by r9 and advance r9
setup_flash_windows:
   // r9 is in units of 16-bits, whereas $FLASH_WINDOW1_START_ADDR is in units of 32-bits
   // do the conversion and take into acount the LSB to offset I0 accordingly
   r0 = r9 LSHIFT -1;
   M[$FLASH_WINDOW1_START_ADDR] = r0;
   r0 = r9 AND 1;
   I0 = $FLASHWIN1_START + r0;
   r9 = r9 + $FLASHWIN1_SIZE;
   // Clip r10 to the amount of data available starting from I0 in the flash window
   // Set r8 to the amount of data beyond the flash window (<=0 if none.)
setup_flash_data_available:
   r8 = ($FLASHWIN1_START + $FLASHWIN1_SIZE) - I0;
   r8 = r10 - r8;
   if POS r10 = r10 - r8;
   rts;
   

.ENDMODULE;


// *****************************************************************************
// MODULE:
//    $KapLoader.InsertPatchInProgramRAM
//
// DESCRIPTION:
//    Overwrites the specifed address in Program RAM with a relative jump
//    to the specified function in Program RAM.
//
// INPUTS:
//    - r1 = address in Program RAM of Patch Point
//    - r2 = address in Program RAM of patch function
//
// OUTPUTS:
//    - none
//
// TRASHED REGISTERS:
//    r0, r1, r2
//
// NOTES:
//    Should be called from the Patch non stay-resident function.  It assumes
//    the window in the Data memory space into Program RAM is enabled.
//
// *****************************************************************************

// *****************************************************************************
// MODULE:
//    $KapLoader.InsertPatchInProgramROM
//
// DESCRIPTION:
//    Sets up an entry in the hardware patch table allowing ROM code to 
//    be patched.  This effectively inserts an Absolute jump at the address 
//    in ROM (plus the next address) to the specified function in Program 
//    RAM.
//
// INPUTS:
//    - r1 = address in ROM of Patch Point
//    - r2 = address in Program RAM of patch function
//    - r3 = zero based index into the hardware patch table
//
// OUTPUTS:
//    - none
//
// TRASHED REGISTERS:
//    r0, r1, r2, r3
//
// NOTES:
//
// *****************************************************************************
.MODULE $M.KapLoader_Utility_Functions;
   .CODESEGMENT KAP_LOADER_PATCH_UTILS_PM;
   .DATASEGMENT DM;
   
$KapLoader.InsertPatchInProgramRAM:
    $push_rLink_macro;
    call $block_interrupts;
    r2 = r2 - r1;               // Relative Jump
    M[r1 + $PMWIN_LO_START]=r2;     
    r2 = $KAP_LOADER.JUMP_INSTRUCTION_MS;                // Jump instruction MS word
    M[r1 + $PMWIN_HI_START]=r2;   
    call $unblock_interrupts;
    jump $pop_rLink_and_rts;
    
#ifdef ROM
$KapLoader.InsertPatchInProgramROM:
    $push_rLink_macro;
    call $block_interrupts;
    // patch_address = pm_addr - PMWIN_SIZE + $PM_FLASHWIN_START_ADDR ???
    r4 = M[$PM_FLASHWIN_START_ADDR];
    r1 = r1 + r4;
    r1 = r1 - $PMWIN_SIZE;
    // writing to PM_FLASHWIN_START_ADDR clears the cache so that the patch will take effect immediately.
    M[$PM_FLASHWIN_START_ADDR] = r4;
    // Set entry in HW patch table
    M[$DSP_ROM_PATCH0_ADDR + r3] = r1;
    M[$DSP_ROM_PATCH0_BRANCH + r3] = r2;      
    call $unblock_interrupts;
    jump $pop_rLink_and_rts;
#endif    
    
.ENDMODULE;

