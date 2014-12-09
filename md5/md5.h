/*
  Copyright (C) Cambridge Silicon Radio Ltd. 2005-2014 
  Part of ADK 3.5 

  MD5C - implementation of the MD5 message-digest

  JBS, 23 Nov 2005 based on the RSA reference implementation in RFC-1321
*/

/*!
    @file   md5.h  

    @brief Implements the MD5 message digest algorithm.

    Provides the functions needed to compute the MD5 digest of
    messages. This is a utility library and provided as a number of
    functions. It is provided for use by the PBAP library during
    authentication; performance is not adequate for processing large
    volumes of data.

    A typical application will call MD5Init, make a number of calls to
    MD5Update to supply the data, and finally call MD5Final to extract
    the data. 

    This library uses the same API as the MD5 reference implementation
    in RFC-1321, but has been optimised to reduce the code size and
    memory consumption on BlueCore.
*/
#ifndef MD5_H_
#define MD5_H_

#include <csrtypes.h>

typedef struct
{
    uint32 buffer[16];
    uint32 state[4];
    uint32 bytes;
} MD5_CTX;

/*!
  @brief Initialise an MD5_CTX.

  MD5 initialization. Begins an MD5 operation, writing a new context. 
*/
void MD5Init(MD5_CTX *);

/*!
   @brief Update an MD5_CTX with the next block of data.

   Continues an MD5 message-digest operation, processing another
   message block, and updating the context.
*/
void MD5Update(MD5_CTX *, const uint8 *bytes, uint16 len);

/*! 
   @brief Extract the digest from the MD5_CTX.

   Ends an MD5 message-digest operation, extracting the digest.
*/
void MD5Final(uint8 digest[16], MD5_CTX *);

#endif /* MD5_H_ */
