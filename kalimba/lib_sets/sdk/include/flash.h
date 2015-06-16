// *****************************************************************************
// Copyright (C) Cambridge Silicon Radio Limited 2005-2014        http://www.csr.com
// Part of ADK 3.5
//
// $Change: 1882869 $  $DateTime: 2014/04/23 13:37:24 $
// *****************************************************************************


#ifndef FLASH_HEADER_INCLUDED
#define FLASH_HEADER_INCLUDED

   #ifdef DEBUG_ON
      #define FLASH_GET_FILE_ADDRESS_DEBUG_ON
   #endif


   .CONST $PM_FLASHWIN_SIZE_MAX 0x40000;


   // set the maximum possible number of handlers - this is only used to detect
   // corruption in the linked list, and so can be quite large
   .CONST   $flash.get_file_address.MAX_HANDLERS                   10;

   // structure fields
   .CONST   $flash.get_file_address.NEXT_ENTRY_FIELD               0;
   .CONST   $flash.get_file_address.FILE_ID_FIELD                  1;
   .CONST   $flash.get_file_address.HANDLER_ADDR_FIELD             2;
   .CONST   $flash.get_file_address.STRUC_SIZE                     3;

   .CONST   $flash.get_file_address.LAST_ENTRY                     -1;
   .CONST   $flash.get_file_address.REATTEMPT_TIME_PERIOD          10000;

   .CONST   $flash.get_file_address.MESSAGE_HANDLER_UNINITIALISED  -1;

 #endif
