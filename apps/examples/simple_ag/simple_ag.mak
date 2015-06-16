######################################################################################################
##### DSP APPS
######################################################################################################

ifneq (, $(findstring -DINCLUDE_DSP,$(DEFS)))

.PHONY : image/cvc_headset/cvc_headset.kap

#the cvc_headset alg comes from the dsp app included as part of the project
image/cvc_headset/cvc_headset.kap : 
	$(mkdir) image/cvc_headset
	$(copyfile) ..\..\..\kalimba\apps\cvc_headset\image\cvc_headset\cvc_headset.kap $@

image.fs : image/cvc_headset/cvc_headset.kap

else

image.fs : | remove_cvc

# Remove any cvc code we might have copied during a previous build
remove_cvc : 
	$(del) image/cvc_headset/cvc_headset.kap  $(del) image/cvc_headset_wb/cvc_headset_wb.kap
endif

