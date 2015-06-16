.linefile 1 "mips_profile.asm"
.linefile 1 "<command-line>"
.linefile 1 "mips_profile.asm"
.linefile 55 "mips_profile.asm"
.MODULE $M.mips_profile;
   .CODESEGMENT MIPS_PROFILE_PM;
   .DATASEGMENT DM;

   .VAR evalinterval_us = 100000;

mainstart:


   r0 = M[$NUM_RUN_CLKS_LS];
   M[r8 +$mips_profile.MIPS.TMAIN_OFFSET] = r0;


   M[r8 + $mips_profile.MIPS.SMAIN_INT_OFFSET] = 0;


   r0 = M[r8 + $mips_profile.MIPS.STAT_OFFSET];
   if Z jump init;

   rts;


init:

   r0 = M[$TIMER_TIME];
   M[r8 + $mips_profile.MIPS.TEVAL_OFFSET] = r0;

   r0 = 1;
   M[r8 + $mips_profile.MIPS.STAT_OFFSET] = r0;
   M[r8 + $mips_profile.MIPS.SMAIN_OFFSET] = 0;
   M[r8 + $mips_profile.MIPS.SINT_OFFSET] = 0;

   rts;


mainend:


   r0 = M[r8 + $mips_profile.MIPS.STAT_OFFSET];
   if Z rts;

   r0 = M[$NUM_RUN_CLKS_LS];
   r1 = M[r8 + $mips_profile.MIPS.TMAIN_OFFSET];
   r0 = r0 - r1;

   r1 = M[r8 + $mips_profile.MIPS.SMAIN_INT_OFFSET];
   r0 = r0 - r1;

   r1 = M[r8 + $mips_profile.MIPS.SMAIN_OFFSET];
   r0 = r0 + r1;
   M[r8 + $mips_profile.MIPS.SMAIN_OFFSET] = r0;


   r0 = M[$TIMER_TIME];
   r1 = M[r8 + $mips_profile.MIPS.TEVAL_OFFSET];

   r0 = r0 - r1;
   r1 = M[evalinterval_us];
   Null = r0 - r1;

   if NEG rts;


   r0 = M[r8 + $mips_profile.MIPS.SMAIN_OFFSET];
   M[r8 + $mips_profile.MIPS.MAIN_CYCLES_OFFSET] = r0;
   r1 = M[r8 + $mips_profile.MIPS.SINT_OFFSET];
   M[r8 + $mips_profile.MIPS.INT_CYCLES_OFFSET] = r1;
   r0 = r0 + r1;
   M[r8 + $mips_profile.MIPS.TOT_CYCLES_OFFSET] = r0;


   M[r8 + $mips_profile.MIPS.STAT_OFFSET] = 0;
   rts;


intstart:
   r0 = M[$NUM_RUN_CLKS_LS];
   M[r8 + $mips_profile.MIPS.TINT_OFFSET] = r0;
   rts;


intend:
   r0 = M[$NUM_RUN_CLKS_LS];

   r1 = M[r8 + $mips_profile.MIPS.TINT_OFFSET];
   r0 = r0 - r1;

   r1 = M[r8 + $mips_profile.MIPS.SINT_OFFSET];
   r1 = r0 + r1;
   M[r8 + $mips_profile.MIPS.SINT_OFFSET] = r1;

   r1 = M[r8 + $mips_profile.MIPS.SMAIN_INT_OFFSET];
   r1 = r0 + r1;
   M[r8 + $mips_profile.MIPS.SMAIN_INT_OFFSET] = r1;

   rts;


.ENDMODULE;
