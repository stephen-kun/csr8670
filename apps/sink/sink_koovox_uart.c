/****************************************************************************
Copyright (C) JoySoft . 2015-2025
Part of KOOVOX 1.0.1

FILE NAME
    sink_koovox_uart.h

*/


#include "sink_koovox_uart.h"


UARTStreamTaskData theUARTStreamTask;

static void UARTStreamMessageHandler (Task pTask, MessageId pId, Message pMessage);


/****************************************************************************
NAME 
  	uart_data_stream_init

DESCRIPTION
 	init the uart_stream_task
 
RETURNS
  	void
*/ 
void uart_data_stream_init(void)
{
	/* Assign task message handler */
	theUARTStreamTask.task.handler = UARTStreamMessageHandler;
	
	/* Configure uart settings */
	StreamUartConfigure(VM_UART_RATE_38K4, VM_UART_STOP_ONE, VM_UART_PARITY_NONE);
	
	/* Get the sink for the uart */
	theUARTStreamTask.uart_sink = StreamUartSink();
	PanicNull(theUARTStreamTask.uart_sink);
	
	/* Get the source for the uart */
	theUARTStreamTask.uart_source = StreamUartSource();
	PanicNull(theUARTStreamTask.uart_source);
	
	/* Register uart source with task */
	MessageSinkTask(StreamSinkFromSource(theUARTStreamTask.uart_source), &theUARTStreamTask.task);
}


/****************************************************************************
NAME 
  	uart_data_stream_tx_data

DESCRIPTION
 	send data to uart
 
RETURNS
  	void
*/ 
void uart_data_stream_tx_data(const uint8 *data, uint16 length)
{
	uint16 offset = 0;
	uint8 *dest = NULL;
	
	/* Claim space in the sink, getting the offset to it */
	offset = SinkClaim(theUARTStreamTask.uart_sink, length);
	if(offset == 0xFFFF)
		Panic();
	
	/* Map the sink into memory space */
	dest = SinkMap(theUARTStreamTask.uart_sink);
	PanicNull(dest);
	
	/* Copy data into the claimed space */
	memcpy(dest+offset, data, length);
	
	/* Flush the data out to the uart */
	PanicZero(SinkFlush(theUARTStreamTask.uart_sink, length));
}


/****************************************************************************
NAME 
  	uart_data_stream_rx_data

DESCRIPTION
 	receive data from uart
 
RETURNS
  	void
*/ 
void uart_data_stream_rx_data(Source src)
{
	uint16 length = 0;
	const uint8 *data = NULL;
	
	/* Get the number of bytes in the specified source before the next packetboundary */
	if(!(length = SourceBoundary(src)))
		return;
	
	/* Maps the specified source into the address map */
	data = SourceMap(src);
	PanicNull((void*)data);
	
	/* Transmit the received data */
	uart_data_stream_tx_data(data, length);
	
	/* Discards the specified amount of bytes from the front of the specifiedsource */
	SourceDrop(src, length);
}

/****************************************************************************
NAME 
  	configManagerKeyLengths

DESCRIPTION
 	Read the lengths of other ps key configs
 
RETURNS
  	void
*/ 
void UARTStreamMessageHandler (Task pTask, MessageId pId, Message pMessage)
{
	switch (pId)
	{
	case MESSAGE_MORE_DATA:
	uart_data_stream_rx_data(((MessageMoreData *)pMessage)->source);
	break;
	default:
	break;
	}
}


