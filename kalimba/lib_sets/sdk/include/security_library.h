// *****************************************************************************
// %%fullcopyright(2007)        http://www.csr.com
// %%version
//
// $Change: 1882869 $  $DateTime: 2014/04/23 13:37:24 $
// *****************************************************************************
// *****************************************************************************
// NAME:
//    CSR Licensing Library
//
// DESCRIPTION:
//    This library provides CSR's implementation for handling feature licensing
//
//    The library provides the following routines:
//      Security.Initialize
//      Security.Test
//      Security.Request
//      Security.PsKeyReadHandler (Internal)
//      
// *****************************************************************************

#ifndef security_LIB_H
#define security_LIB_H

.PUBLIC  $Security.Initialize;
.PUBLIC  $Security.Test;
.PUBLIC  $Security.Request;

.CONST $BT_ADDR_PS_KEY           1;
.CONST $CLARITYMASK              0x1234;

// Pass/Fail Message IDs
.CONST $SECURITY_PASSED_MSG      0x100c;
.CONST $SECURITY_FAILED_MSG      0x1013;

// Request Structure
.CONST $M.LICENSE_REQUEST.NEXT_REQ_FIELD        0;
.CONST $M.LICENSE_REQUEST.RESULT_FIELD          1;
.CONST $M.LICENSE_REQUEST.PSKEY_FIELD           2;
.CONST $M.LICENSE_REQUEST.PRODUCT_ID_FIELD      3;
.CONST $M.LICENSE_REQUEST.OPERATOR_ID_FIELD     4;
.CONST $M.LICENSE_REQUEST.STRUC_SIZE            5;

#endif
