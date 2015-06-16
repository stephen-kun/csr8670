/* *****************************************************************************
   Copyright (C) Cambridge Silicon Radio Limited 2011-2014        http://www.csr.com
   Part of ADK 3.5

   *****************************************************************************

   *****************************************************************************
   NAME:
      kalimba_xap_to_copy.h

   DESCRIPTION:
      Register information between BlueCore firmware and the Kalimba DSP.

   NOTES:
   *****************************************************************************
*/
#ifndef KALIMBA_XAP_TO_COPY_H
#define KALIMBA_XAP_TO_COPY_H

/* Following typedef's will make code more readable and also,
   helps in defining readable function prototypes.
   typedef for the register access codes
   Variables with xap_rac type will contain register access codes
 */
typedef uint16 xap_rac;

/* typedef for the register access module
   Variables with xap_rac_module type will contain KAL_RAC_XX_MODULE value
 */
typedef uint16 xap_rac_module;

/* typedef for the register access id
   Variables with xap_rac_reg_id type will contain KAL_RAC_XX_REG &
   KAL_RAC_XAP_REG_MASK value
 */
typedef uint16 xap_rac_reg_id;

/* typedef for the register access status
   Variables with xap_rac_status type will contain KAL_RAC_STATUS_XXXX value
 */
typedef uint16 xap_rac_status;

/* typedef for the register access alert
   Variables with xap_rac_alert type will contain KAL_RAC_ALERT_XXXX value
 */
typedef uint16 xap_rac_alert;

/* Alert Message values */
#define KAL_RAC_ALERT_IGNORE 0

/* All register values are now invalid and there is no point in monitoring
   for change
 */
#define KAL_RAC_ALERT_INVALID 1

/* One or more registers are now being updated  */
#define KAL_RAC_ALERT_BEING_UPDATED 2

/* Status block */
/* State field */
#define KAL_RAC_STATUS_STATE_SHIFT  14
#define KAL_RAC_STATUS_STATE_MASK   (0x0003U << KAL_RAC_STATUS_STATE_SHIFT)

/* Values */
/* KAL_RAC_STATUS_VALID represents that the register contents are valid */
#define KAL_RAC_STATUS_VALID (0U << KAL_RAC_STATUS_STATE_SHIFT)

/* KAL_RAC_STATUS_INVALID represents that the register contents will
   not be updated periodically and register contents may be old.
 */
#define KAL_RAC_STATUS_INVALID (1U << KAL_RAC_STATUS_STATE_SHIFT)

/* KAL_RAC_STATUS_BEING_UPDATED represents that the register contents
   are being updated and so might not be consistent
 */
#define KAL_RAC_STATUS_BEING_UPDATED (2U << KAL_RAC_STATUS_STATE_SHIFT)

/* Counter field */
#define KAL_RAC_STATUS_COUNT_SHIFT 0
#define KAL_RAC_STATUS_COUNT_MASK  (0x00FFU << KAL_RAC_STATUS_COUNT_SHIFT)

/* Register Access Error codes */
/* The module is not present or updates cannot be provided. */
#define KAL_RAEC_MOD_NOT_SUPPORTED 1

/* The register is not present or updates cannot be provided */
#define KAL_RAEC_REG_NOT_SUPPORTED 2

/* The module is unable to provide the periodic update due to there is
   already a periodic update happening with differnt interval for
   other registers than currently requested.
 */
#define KAL_RAEC_TOO_COMPLICATED 3

/* Start of the Register Access codes */
/* NOTE: RAC code cannot exceed a value KAL_RAC_XX_MODULE + 15 due
   to the restriction in the existing implementation.
*/
#define KAL_RAC_XAP_MOD_MASK 0xFF00
#define KAL_RAC_XAP_REG_MASK 0x00FF

/* NOTE: RAC cannot start from 0x0000 since 0x0000 is used as padding in
   short messages.
*/
#define KAL_RAC_XAP_PADDING 0x0000

/* Start of FM specific registers */
#define KAL_RAC_FM_MODULE 0x0100

#define KAL_RAC_FM_DEMOD_SNR_LOG    (KAL_RAC_FM_MODULE + 0)
#define KAL_RAC_FM_DEMOD_IF_COUNTER (KAL_RAC_FM_MODULE + 1)

#define KAL_RAC_FM_REG_COUNT 2
/* End of FM specific registers*/


#endif
