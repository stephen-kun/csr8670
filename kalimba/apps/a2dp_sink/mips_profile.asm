// *****************************************************************************
// %%fullcopyright(2005)        http://www.csr.com
// %%version
//
// $Change: 1882869 $  $DateTime: 2014/04/23 13:37:24 $
// *****************************************************************************

// *****************************************************************************
// MODULE:
//    $M.mips_profile
//
// INPUTS:
//    r8 - mips data block pointer
//
// OUTPUTS:
//    main_cycles : 
//       num cycles used in your main function in a 100ms interval
//    int_cycles  : 
//       num cycles used in your interrupt functions(s) in a 100ms interval
//    tot_cycles  :
//       total cycles used by your application in a 100ms interval
//
// TRASHED:
//    r0,r1
//
// CYCLES
//    $M.mips_profile.mainstart: 6
//    $M.mips_profile.mainend:   16
//    $M.mips_profile.intstart:  3
//    $M.mips_profile.intend:    10
//
//
// DESCRIPTION:
//    profiler. Calculate #cycles used in main and interrupt processes
//
//    MATLAB script to read MIPS:
// 
//    cyc_m = kalreadval('$M.cvc_profile.main_cycles', 'uint', '24');
//    cyc_int = kalreadval('$M.cvc_profile.int_cycles', 'uint', '24');
//    cyc_tot = kalreadval('$M.cvc_profile.tot_cycles', 'uint', '24');
//
//    buf = sprintf('main MIPS\t%.2f\nint MIPS \t%.2f\ntotal MIPS\t%.2f\n',...
//       1e-5*cyc_m,1e-5*cyc_int,1e-5*cyc_tot);
//    disp(buf);
//
// 
//
//
//
//
//
//
// *****************************************************************************

.MODULE $M.mips_profile;
   .CODESEGMENT MIPS_PROFILE_PM;
   .DATASEGMENT DM;

   .VAR evalinterval_us = 100000;

mainstart:
   // start profiling main process

   r0 = M[$NUM_RUN_CLKS_LS];
   M[r8 +$mips_profile.MIPS.TMAIN_OFFSET] = r0;
   
  
   M[r8 + $mips_profile.MIPS.SMAIN_INT_OFFSET] = 0;     // reset smain_int to interrupt cycles
                                                        // can be subtracted out from smain
                        
   r0 = M[r8 + $mips_profile.MIPS.STAT_OFFSET];
   if Z jump init;

   rts;
   

init:
   // get first us timestamp
   r0 = M[$TIMER_TIME];
   M[r8 + $mips_profile.MIPS.TEVAL_OFFSET] = r0;

   r0 = 1;
   M[r8 + $mips_profile.MIPS.STAT_OFFSET] = r0;
   M[r8 + $mips_profile.MIPS.SMAIN_OFFSET] = 0;
   M[r8 + $mips_profile.MIPS.SINT_OFFSET] = 0;
   
   rts;


mainend:
   // stop profiling main process   

   r0 = M[r8 + $mips_profile.MIPS.STAT_OFFSET];         // not initialized yet
   if Z rts;

   r0 = M[$NUM_RUN_CLKS_LS];  // calc deltat
   r1 = M[r8 + $mips_profile.MIPS.TMAIN_OFFSET];
   r0 = r0 - r1;
   
   r1 = M[r8 + $mips_profile.MIPS.SMAIN_INT_OFFSET];    // subtrace out interrupt cycles
   r0 = r0 - r1;
   
   r1 = M[r8 + $mips_profile.MIPS.SMAIN_OFFSET];        // store main cycles
   r0 = r0 + r1;
   M[r8 + $mips_profile.MIPS.SMAIN_OFFSET] = r0;
   

   r0 = M[$TIMER_TIME];
   r1 = M[r8 + $mips_profile.MIPS.TEVAL_OFFSET];
   
   r0 = r0 - r1;
   r1 = M[evalinterval_us];
   Null = r0 - r1;
   
   if NEG rts;
   
   // interval has elapsed. evaluate and reset;
   r0 = M[r8 + $mips_profile.MIPS.SMAIN_OFFSET];
   M[r8 + $mips_profile.MIPS.MAIN_CYCLES_OFFSET] = r0;
   r1 = M[r8 + $mips_profile.MIPS.SINT_OFFSET];
   M[r8 + $mips_profile.MIPS.INT_CYCLES_OFFSET] = r1;
   r0 = r0 + r1;
   M[r8 + $mips_profile.MIPS.TOT_CYCLES_OFFSET] = r0;
   

   M[r8 + $mips_profile.MIPS.STAT_OFFSET] = 0;          // not initislized
   rts;
   
      
intstart:
   r0 = M[$NUM_RUN_CLKS_LS];
   M[r8 + $mips_profile.MIPS.TINT_OFFSET] = r0; 
   rts;


intend:
   r0 = M[$NUM_RUN_CLKS_LS];
   
   r1 = M[r8 + $mips_profile.MIPS.TINT_OFFSET];         // calc deltat
   r0 = r0 - r1;
   
   r1 = M[r8 + $mips_profile.MIPS.SINT_OFFSET];         // store sum(deltat) in sint
   r1 = r0 + r1;
   M[r8 + $mips_profile.MIPS.SINT_OFFSET] = r1;
   
   r1 = M[r8 + $mips_profile.MIPS.SMAIN_INT_OFFSET];    // store sum(deltat) in smain_int
   r1 = r0 + r1;
   M[r8 + $mips_profile.MIPS.SMAIN_INT_OFFSET] = r1;

   rts;
   

.ENDMODULE;