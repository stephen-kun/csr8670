/****************************************************************************
Copyright (C) Cambridge Silicon Radio Ltd. 2010

FILE NAME
    display.h
    
DESCRIPTION
    header file for the display library	
*/

/*!
@file   display.h
@brief  Header file for the display library.
    This defines the Application Programming interface to the display library.
    
    i.e. the interface between the VM application and the display library.
*/

#ifndef _DISPLAY_H_
#define _DISPLAY_H_

#include <message.h>
#include "display_plugin_if.h"

/*!
    @brief Connects initilaises the display plugin params.  Underlying plugin should
		also use this message to do any specific initialisation required.
    
    @param display_plugin The display plugin to use
    @param app_task the application task

	
      
*/
bool DisplayInit(Task display_plugin,
				 Task app_task);


/*!
	@brief 	update the state of the display
	@param 	on/off state of display
	
*/
void DisplaySetState( bool state );					 
				 
/*!
	@brief 	update the text line on the display
	@param 	text 
	
*/
void DisplaySetText( char* text, 
					 uint8 txtlen, 
					 uint8 line,
                     bool  scroll,
					 uint16 scroll_update,
                     uint16 scroll_pause,
                     bool  flash,
                     bool  display_time );				  
				  
/*!
	@brief 	update the volume level on the display
	@param 	volume 
	
*/
void DisplaySetVolume( uint16 volume  );

/*!
	@brief 	update an icon status on the display
	@param 	icon id 
	@param 	icon state	
	
*/
void DisplaySetIcon( uint8 icon, bool state );

/*!
	@brief 	update the battery level on the display
	@param 	battery level 
	
*/
void DisplaySetBatteryLevel( uint8 battery_level );


#endif /*_DISPLAY_H_*/
