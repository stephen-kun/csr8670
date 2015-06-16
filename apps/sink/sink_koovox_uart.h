/****************************************************************************
Copyright (C) JoySoft . 2015-2025
Part of KOOVOX 1.0.1

FILE NAME
    sink_koovox_uart.h

*/

#ifndef __SINK_KOOVOX_UART_H
#define __SINK_KOOVOX_UART_H

#include <stream.h>
#include <sink.h>
#include <source.h>
#include <string.h>
#include <panic.h>
#include <message.h>
#include <uart_if.h>


typedef struct
{
	TaskData task;
	Sink uart_sink;
	Source uart_source;
} UARTStreamTaskData;


void uart_data_stream_init(void);
void uart_data_stream_rx_data(Source src);
void uart_data_stream_tx_data(const uint8 *data, uint16 length);


#endif


