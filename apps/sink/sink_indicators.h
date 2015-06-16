/****************************************************************************
Copyright (C) Cambridge Silicon Radio Ltd. 2004-2014

FILE NAME
    sink_indicators.h
    
DESCRIPTION
    
*/

#ifndef _SINK_INDICATORS_H_
#define _SINK_INDICATORS_H_


/****************************************************************************
NAME    
    indicatorsHandleServiceInd
    
DESCRIPTION
    Interprets the service Indicator messages and sends the appropriate message 

RETURNS
    void
*/
void indicatorsHandleServiceInd ( const HFP_SERVICE_IND_T *pInd );


#endif /* _SINK_INDICATORS_H_ */

