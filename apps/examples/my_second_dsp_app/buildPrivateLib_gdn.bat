@echo on
@echo IMPORTANT! "ADKDIR" with your ADK installer directory.
@echo For example, change the line
@echo 	SET ADKDIR=C:\ADK_installer_dir
@echo to
@echo 	SET ADKDIR=C:\ADK3.5
@echo off

pause

IF not exist dsp_demo_app_2_fir_gdn (mkdir dsp_demo_app_2_fir_gdn)

SET ADKDIR=C:\CSR\ADK3.5.RC1.1
%ADKDIR%\tools\bin\kas.exe fir_filter.asm  -o dsp_demo_app_2_fir_gdn\fir_gdn.o -DBLD_PRIVATE -DGORDON -DKAL_ARCH3 -DKALASM3 -g -mchip=gordon -I%ADKDIR%\kalimba -I%ADKDIR%\kalimba\architecture -I%ADKDIR%\kalimba\lib_sets\sdk\include -I%ADKDIR%\kalimba\external_includes\vm -I%ADKDIR%\kalimba\external_includes\firmware
%ADKDIR%\tools\bin\kar.exe cr dsp_demo_app_2_fir_gdn\fir_gdn.a dsp_demo_app_2_fir_gdn\fir_gdn.o
%ADKDIR%\tools\bin\kalscramble.exe dsp_demo_app_2_fir_gdn\fir_gdn.a -o dsp_demo_app_2_fir_gdn\fir_gdn.pa

copy dsp_demo_app_2_fir_gdn\fir_gdn.pa %ADKDIR%\kalimba\lib_sets\sdk\gordon
copy fir_gdn.link %ADKDIR%\kalimba\lib_sets\sdk\gordon
