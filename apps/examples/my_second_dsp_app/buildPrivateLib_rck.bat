@echo on
@echo IMPORTANT! "ADKDIR" with your ADK installer directory.
@echo For example, change the line
@echo 	SET ADKDIR=C:\ADK_installer_dir
@echo to
@echo 	SET ADKDIR=C:\ADK3.5
@echo off

pause

IF not exist dsp_demo_app_2_fir_rck (mkdir dsp_demo_app_2_fir_rck)

SET ADKDIR=C:\CSR\ADK3.5.RC1.1
%ADKDIR%\tools\bin\kas.exe fir_filter.asm  -o dsp_demo_app_2_fir_rck\fir_rck.o -DBLD_PRIVATE -DRICK -DKAL_ARCH5 -DKALASM3 -g -mchip=rick -I%ADKDIR%\kalimba -I%ADKDIR%\kalimba\architecture -I%ADKDIR%\kalimba\lib_sets\sdk\include -I%ADKDIR%\kalimba\external_includes\vm -I%ADKDIR%\kalimba\external_includes\firmware
%ADKDIR%\tools\bin\kar.exe cr dsp_demo_app_2_fir_rck\fir_rck.a dsp_demo_app_2_fir_rck\fir_rck.o
%ADKDIR%\tools\bin\kalscramble.exe dsp_demo_app_2_fir_rck\fir_rck.a -o dsp_demo_app_2_fir_rck\fir_rck.pa

copy dsp_demo_app_2_fir_rck\fir_rck.pa %ADKDIR%\kalimba\lib_sets\sdk\rick
copy fir_rck.link %ADKDIR%\kalimba\lib_sets\sdk\rick
