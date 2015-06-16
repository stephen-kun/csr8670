/* Copyright (C) Cambridge Silicon Radio Limited 2011-2014 */
/* Part of ADK 3.5 */
/*!
  \file bdaddr.h
  
  \brief Helper routines for Bluetooth addresses
*/

#ifndef BDADDR_H_
#define BDADDR_H_

#include <bdaddr_.h>
#include <app/bluestack/types.h>
#include <app/bluestack/bluetooth.h>

#include <string.h>

/*!
    \brief Convert the Bluestack BD_ADDR_T Bluetooth address to the VM bdaddr 
    type.

    \param out Pointer to the bdaddr struct to hold the address after 
    conversion.
    \param in Pointer to the BD_ADDR_T struct holding the address to be
    converted.
*/
void BdaddrConvertBluestackToVm(bdaddr *out, const BD_ADDR_T *in);

/*!
    \brief Convert the VM bdaddr Bluetooth address to the Bluestack BD_ADDR_T 
    type. 

    \param out Pointer to the BD_ADDR_T struct to hold the address after 
    conversion.
    \param in Pointer to the BD_ADDR_T struct holding the address to be
    converted.
*/

void BdaddrConvertVmToBluestack(BD_ADDR_T *out, const bdaddr *in);

/*!
    \brief Convert the Bluestack TYPED BD_ADDR_T Bluetooth address to the VM 
    typed_bdaddr type.

    \param out Pointer to the typed_bdaddr struct to hold the address after 
    conversion.
    \param in Pointer to the TYPED_BD_ADDR_T struct holding the address to be
    converted.
*/
void BdaddrConvertTypedBluestackToVm(
        typed_bdaddr            *out, 
        const TYPED_BD_ADDR_T   *in
        );

/*!
    \brief Convert the VM typed_bdaddr Bluetooth address to the Bluestack 
    TYPED_BD_ADDR_T type.

    \param out Pointer to the TYPED_BD_ADDR_T struct to hold the address after 
    conversion.
    \param in Pointer to the typed_bdaddr struct holding the address to be
    converted.
*/
void BdaddrConvertTypedVmToBluestack(
        TYPED_BD_ADDR_T         *out,
        const typed_bdaddr      *in
        );
/*!
	\brief Sets the Bluetooth address passed to zero.

    \param in Pointer to the Bluetooth address.
*/
#define BdaddrSetZero(in) memset((in), 0, sizeof(bdaddr))

/*!
	\brief Compares two Bluetooth addresses and returns TRUE if
	they are the same, else returns FALSE.

    \param first Pointer to the first Bluetooth address.
    \param second pointer to the second Bluetooth address.
*/
bool BdaddrIsSame(const bdaddr *first, const bdaddr *second);

/*!
	\brief Returns TRUE if the Bluetooth address passed is zero, else
	returns FALSE.

    \param in Pointer to the Bluetooth address.
*/
bool BdaddrIsZero(const bdaddr *in);

/*!
	\brief Sets the Typed Bluetooth address passed to empty. That is, the 
    address is set to 0 and the type is set to INVALID.

    \param in Pointer to the Typed Bluetooth address.
*/
void BdaddrTypedSetEmpty(typed_bdaddr *in);

/*!
	\brief Compares two Typed Bluetooth addresses and returns TRUE if
	they are the same, else returns FALSE.

    \param first Pointer to the first Typed Bluetooth address.
    \param second pointer to the second Typed Bluetooth address.
*/
bool BdaddrTypedIsSame(const typed_bdaddr *first, const typed_bdaddr *second);

/*!
	\brief Returns TRUE if the Typed Bluetooth address passed has the address
    part set to zero and the type set to INVALID.

    \param in Pointer to the Typed Bluetooth address.
*/
bool BdaddrTypedIsEmpty(const typed_bdaddr *in);


#endif /* BDADDR_H_ */

