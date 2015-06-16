

# Set transport make variable
ifneq (,$(findstring -DANALOGUE_INPUT_DEVICE,$(DEFS)))
TRANSPORT=none
else
TRANSPORT=usb_vm
endif

# Check for BlueCore version
ifneq (,$(findstring -DBC5_MULTIMEDIA,$(DEFS)))
EXECUTION_MODE=native
endif

# Include Kalimba algorithms that are built from the DSP applications that are included as part of the project
.PHONY : image/sbc_encoder/sbc_encoder.kap \
        image/usb_dongle_48_to_16k_stereo/usb_dongle_48_to_16k_stereo.kap \
        image/usb_dongle_48_to_8k_stereo/usb_dongle_48_to_8k_stereo.kap \
        image/usb_dongle_16k_mono/usb_dongle_16k_mono.kap \
        image/usb_dongle_8k_mono/usb_dongle_8k_mono.kap \
        image/aptx_encoder/aptx_encoder.kap \
        image/aptx_acl_sprint_encoder/aptx_acl_sprint_encoder.kap

        
# Include SBC encoder
image/sbc_encoder/sbc_encoder.kap : 
	$(mkdir) image/sbc_encoder
	$(copyfile) ..\..\kalimba\apps\a2dp_source\image\sbc_encoder\sbc_encoder.kap $@
	
image.fs : image/sbc_encoder/sbc_encoder.kap
    
# Include 48kHz to 16kHz speech for Wide Band HFP and USB configured at 48kHz sample rate
image/usb_dongle_48_to_16k_stereo/usb_dongle_48_to_16k_stereo.kap : 
	$(mkdir) image/usb_dongle_48_to_16k_stereo
	$(copyfile) ..\..\kalimba\apps\one_mic_example\image\usb_dongle_48_to_16k_stereo\usb_dongle_48_to_16k_stereo.kap $@
	
image.fs : image/usb_dongle_48_to_16k_stereo/usb_dongle_48_to_16k_stereo.kap

# Include 48kHz to 8kHz speech for Narrow Band HFP and USB configured at 48kHz sample rate
image/usb_dongle_48_to_8k_stereo/usb_dongle_48_to_8k_stereo.kap : 
	$(mkdir) image/usb_dongle_48_to_8k_stereo
	$(copyfile) ..\..\kalimba\apps\one_mic_example\image\usb_dongle_48_to_8k_stereo\usb_dongle_48_to_8k_stereo.kap $@
	
image.fs : image/usb_dongle_48_to_8k_stereo/usb_dongle_48_to_8k_stereo.kap

# Include 16kHz speech for Wide Band HFP and USB configured at 16kHz sample rate
image/usb_dongle_16k_mono/usb_dongle_16k_mono.kap : 
	$(mkdir) image/usb_dongle_16k_mono
	$(copyfile) ..\..\kalimba\apps\one_mic_example\image\usb_dongle_16k_mono\usb_dongle_16k_mono.kap $@
	
image.fs : image/usb_dongle_16k_mono/usb_dongle_16k_mono.kap

# Include 8kHz speech for Narrow Band HFP and USB configured at 8kHz sample rate
image/usb_dongle_8k_mono/usb_dongle_8k_mono.kap : 
	$(mkdir) image/usb_dongle_8k_mono
	$(copyfile) ..\..\kalimba\apps\one_mic_example\image\usb_dongle_8k_mono\usb_dongle_8k_mono.kap $@

image.fs : image/usb_dongle_8k_mono/usb_dongle_8k_mono.kap

## Include Classic aptX encoder - uncomment the following lines when enabling Classic aptX
#image/aptx_encoder/aptx_encoder.kap : 
#	$(mkdir) image/aptx_encoder
#	$(copyfile) ..\..\kalimba\apps\a2dp_source\image\aptx_encoder\aptx_encoder.kap $@
#
#image.fs : image/aptx_encoder/aptx_encoder.kap
#
## Include aptX Low Latency encoder - uncomment the following lines when enabling aptX Low Latency
#image/aptx_acl_sprint_encoder/aptx_acl_sprint_encoder.kap : 
#	$(mkdir) image/aptx_acl_sprint_encoder
#	$(copyfile) ..\..\kalimba\apps\a2dp_source\image\aptx_acl_sprint_encoder\aptx_acl_sprint_encoder.kap $@
#
#image.fs : image/aptx_acl_sprint_encoder/aptx_acl_sprint_encoder.kap
