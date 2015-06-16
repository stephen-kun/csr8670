// *****************************************************************************
// Copyright (C) Cambridge Silicon Radio Limited 2005-2014        http://www.csr.com
// Part of ADK 3.5
//
// $Change: 1882869 $  $DateTime: 2014/04/23 13:37:24 $
// *****************************************************************************
.MODULE $M.cbops.iir_resample.48_to_16;
	.DATASEGMENT DM;

.BLOCK/DM1  filter;
   .VAR  fir_offset = 112; 
   .VAR  fir_coef = &$M.cbops.iir_resample.fir.coeffs;
//	.VAR  Input_Scale    = 8;
//	.VAR  Output_Scale   = -8;
	.VAR  Input_Scale    = 0;
	.VAR  Output_Scale   = 0;
	.VAR  R_out          = 1;
	.VAR  frac_ratio     = 0.000000;
	.VAR  iir_inv_ratio  = 0.333333;
	.VAR  int_ratio      = 3;
	.VAR  iir_scale      = 6;
	.VAR  coeffs[10]= 0.0000464916229248,
	 -0.0036212205886841,
	 0.0294842720031738,
	 -0.1138893365859985,
	 0.2731399536132813,
	 -0.4478517770767212,
	 0.5210754871368408,
	 -0.4313560724258423,
	 0.2462109327316284,
	 -0.0886856317520142;
.ENDBLOCK;
// Downsample
// L = 1
// fir_scale	= 7;
// IIR Gain = 2.166885 *(Rout/160)*2^(fir_scale+1) = 3.467016
// FIR Gain = 1.142890
// fp : Nyquyst*(1-0.065000) = 0.155833
// rp : (0.140000)^2 = 0.019600
// -3dB cutoff = 15398.400000 Hz
// intermediate (history)		Q2.21;

// input              Q8.15<<input_scale *(2^-2 iir gain scaled) = Q2.21
// IIR coefficients   Q6.17  :  Q2.21 * Q6.17 = Q8.27 >> iir_scale = Q2.21  
// FIR coefficients   Q-2.25  :  Q2.21 * Q-2.25 = Q0.19 << out_scale = Q8.15  
.ENDMODULE;


.MODULE $M.cbops.iir_resample.UpsampleBy2;
   .DATASEGMENT DM;

.BLOCK/DM1  filter;
   .VAR  fir_offset = 4;
   .VAR  fir_coef = &$M.cbops.iir_resample.firUpBy2.coeffs;
   .VAR  Input_Scale  = 0;         // IIR Scaling (input)
   .VAR  Output_Scale = -1;        // FIR Scaling (output)
   .VAR  R_out = 2;
   .VAR  frac_ratio  = 0.5;
   //.VAR int_ratio = 0;      // (down sample only)
   .VAR  iir_scale = 3;
   .VAR  coeffs[10] =      0.7093918323516846,
      -7.259845733642578e-005,
      -7.283687591552734e-005,
      -7.021427154541016e-005,
      9.775161743164063e-006,
      0.0003409385681152344,
      0.01006042957305908,
      0.07485973834991455,
      0.2210551500320435,
      0.2780615091323853;
.ENDBLOCK;

// Upsample
// L = 2
// fir_scale = 7
// IIR Gain  = 151.154 * (L/160) << fir_scale = 241.8464
// intermediate (history)  Q8.15

// input                   Q8.15<<input_scale = Q8.15
// IIR coefficients        Q3.21          : Q3.21 * Q8.15   = Q11.36  << iir_scale    = Q8.15
// FIR coefficients        Q1.22          : Q1.22 * Q8.15   = Q9.38   << output_scale = Q8.15
.ENDMODULE;


.MODULE $M.cbops.iir_resample.DownsampleBy2;
   .DATASEGMENT DM;

.BLOCK/DM1  filter;
   .VAR  fir_offset = 2;
   .VAR  fir_coef = &$M.cbops.iir_resample.firDownBy2.coeffs;
   .VAR  Input_Scale  = 0;         // IIR Scaling (input)
   .VAR  Output_Scale = -6;        // FIR Scaling (output)
   .VAR  R_out        = 1;
   .VAR  frac_ratio   = 0.0;
   .VAR  iir_inv_ratio = 0.5;
   .VAR  int_ratio    = 2;
   .VAR  iir_scale    = 3;
   .VAR  coeffs[10] =       0.991079330444336,
      -0.00336611270904541,
      0.02549850940704346,
      -0.09843456745147705,
      0.2511321306228638,
      -0.4650629758834839,
      0.6520981788635254,
      -0.6948447227478027,
      0.5659805536270142,
      -0.3137685060501099;
.ENDBLOCK;

// Downsample
// L = 1
// fir_scale = 7
// IIR Gain  = 6.413 * (L/160)  << (fir_scale+1) = 10.2608
// intermediate (history)  Q4.19

// input                   Q8.15<<Input_Scale * 2^4 (x(n) coefficient scaling) = Q4.19
// IIR coefficients        Q3.20          : Q4.19 * Q3.20  = Q7.40  << iir_scale     = Q4.19
// FIR coefficients        Q-2.25         : Q4.19 * Q-2.25 = Q2.45  << output_scale  = Q8.15
.ENDMODULE;

.MODULE $M.cbops.iir_resample.44_1_to_96;
   .DATASEGMENT DM;

   .BLOCK/DM1  filter;
   .VAR  fir_offset = 160;
   .VAR  fir_coef = &$M.cbops.iir_resample.fir.coeffs;
   .VAR  Input_Scale    = 1;
   .VAR  Output_Scale   = -1;
   .VAR  R_out          = 320;
   .VAR  frac_ratio     = 0.459375;
   //.VAR  int_ratio      = 0;   (down sample only)
   .VAR  iir_scale      = 2;
   .VAR  coeffs[10]= 0.7093517780303955,
                   -0.0001451969146729,
                   -0.0001455545425415,
                   -0.0001403093338013,
                   0.0000188350677490,
                   0.0006729364395142,
                   0.0201145410537720,
                   0.1497129201889038,
                   0.4420721530914307,
                   0.5561001300811768;
   .ENDBLOCK;
// Upsample
// L = 320
// fir_scale   = -1;
// IIR Gain = 242.050225 *(Rout/160)<<fir_scale = 121.025112
// FIR Gain = 1.000000
// fp : Nyquyst*(1-0.110000) = 0.001391
// rp : (0.025000)^2 = 0.000625
// -3dB cutoff = 43341.176471 Hz
// intermediate (history)     Q7.16;

// input              Q8.15<<input_scale  = Q7.16
// IIR coefficients   Q2.21  :  Q7.16 * Q2.21 = Q9.18 >> iir_scale = Q7.16
// FIR coefficients   Q2.21  :  Q7.16 * Q2.21 = Q9.18 << out_scale = Q8.15
.ENDMODULE;


.MODULE $M.cbops.iir_resample.8_to_16;
   .DATASEGMENT DM;

   .BLOCK/DM1  filter;
   .VAR  fir_offset = 160;
   .VAR  fir_coef = &$M.cbops.iir_resample.fir.coeffs;
      .VAR  Input_Scale  = 0;          // IIR Scaling (input)
      .VAR  Output_Scale = -1;         // FIR Scaling (output)
      .VAR  R_out = 2;
      .VAR  frac_ratio = 0.5;
      //.VAR int_ratio = 0;            // (down sample only)
      .VAR  iir_scale = 3;
      .VAR  coeffs[10] = 0.7093918323516846,
                        -7.259845733642578e-005,
                        -7.283687591552734e-005,
                        -7.021427154541016e-005,
                        9.775161743164063e-006,
                        0.0003409385681152344,
                        0.01006042957305908,
                        0.07485973834991455,
                        0.2210551500320435,
                        0.2780615091323853;
   .ENDBLOCK;

   // Upsample
   // L = 2
   // fir_scale = 7
   // IIR Gain  = 151.154 * (L/160) << fir_scale = 241.8464
   // intermediate (history)  Q8.15

   // input                   Q8.15<<input_scale = Q8.15
   // IIR coefficients        Q3.21          : Q3.21 * Q8.15   = Q11.36  << iir_scale    = Q8.15
   // FIR coefficients        Q1.22          : Q1.22 * Q8.15   = Q9.38   << output_scale = Q8.15
.ENDMODULE;

.MODULE $M.cbops.iir_resample.8_to_22_05;
   .DATASEGMENT DM;

.BLOCK/DM1  filter;
   .VAR  fir_offset = 160;
   .VAR  fir_coef = &$M.cbops.iir_resample.fir.coeffs;
      .VAR  Input_Scale  = 0;         // IIR Scaling (input)
      .VAR  Output_Scale = -1;        // FIR Scaling (output)
      .VAR  R_out = 441;
      .VAR  frac_ratio  = 0.362811791;
      //.VAR int_ratio = 0;      // (down sample only)
      .VAR  iir_scale = 3;
      .VAR  coeffs[10] = 0.7093470096588135,
                        -7.259845733642578e-005,
                        -7.283687591552734e-005,
                        -7.021427154541016e-005,
                        9.417533874511719e-006,
                        0.0003365278244018555,
                        0.01005733013153076,
                        0.07485687732696533,
                        0.2210367918014526,
                        0.2780505418777466;
   .ENDBLOCK;

   // Upsample
   // L = 441
   // IIR Gain  = 175.689 * (L/160) * (2^-1) = 242.212

   // input                   Q8.15<<input_scale = Q8.15
   // intermediate (history)  Q8.15
   // IIR coefficients        Q3.20          : Q8.15 * Q3.20   = Q11.36 << iir_scale    = Q8.15
   // FIR coefficients        Q-1.24         : Q8.15 * Q-1.24  = Q7.40  << output_scale = Q8.15
.ENDMODULE;

.MODULE $M.cbops.iir_resample.8_to_32;
   .DATASEGMENT DM;

.BLOCK/DM1  filter;
   .VAR  fir_offset = 160;
   .VAR  fir_coef = &$M.cbops.iir_resample.fir.coeffs;
   .VAR  Input_Scale  = 0;         // IIR Scaling (input)
      .VAR  Output_Scale = -1;      // FIR Scaling (output)
      .VAR  R_out = 4;
      .VAR  frac_ratio  = 0.25;
      //.VAR int_ratio = 0;         // (down sample only)
      .VAR  iir_scale = 3;
      .VAR coeffs[10] = 0.7093918323516846,
      -7.259845733642578e-005,
      -7.283687591552734e-005,
      -7.021427154541016e-005,
      9.775161743164063e-006,
      0.0003409385681152344,
      0.01006042957305908,
      0.07485973834991455,
      0.2210551500320435,
      0.2780615091323853;
   .ENDBLOCK;

// Upsample
// L = 4
// fir_scale = 6
// IIR Gain  = 151.154 * (L/160) << fir_scale = 241.1664
// intermediate (history)  Q8.15

// input                   Q8.15<<input_scale = Q8.15
// IIR coefficients        Q3.21          : Q3.21 * Q8.15   = Q11.36  << iir_scale    = Q8.15
// FIR coefficients        Q1.22          : Q1.22 * Q8.15   = Q9.38   << output_scale = Q8.15
.ENDMODULE;

.MODULE $M.cbops.iir_resample.8_to_44_1;
   .DATASEGMENT DM;

   .BLOCK/DM1  filter;
   .VAR  fir_offset = 160;
   .VAR  fir_coef = &$M.cbops.iir_resample.fir.coeffs;
      .VAR  Input_Scale  = 1;         // IIR Scaling (input)
      .VAR  Output_Scale = -1;        // FIR Scaling (output)
      .VAR  R_out = 441;
      .VAR  frac_ratio  = 0.18140589569161;
      //.VAR int_ratio = 0;      // (down sample only)
      .VAR  iir_scale = 2;
      .VAR  coeffs[10] =      0.6978193521499634,
      -0.0001451969146728516,
      -0.0001456737518310547,
      -0.0001403093338012695,
      1.966953277587891e-005,
      0.0006818771362304688,
      0.02012085914611816,
      0.1497193574905396,
      0.4421104192733765,
      0.5561230182647705;
   .ENDBLOCK;

// Upsample
// L = 441
// fir_scale = -1
// IIR Gain  = 172.5678 * (L/160) << (fir_scale-1) = 118.91
// intermediate (history)  Q7.16

// input                   Q8.15<<input_scale = Q7.16
// IIR coefficients        Q2.21          : Q3.21 * Q7.16   = Q10.37  << iir_scale    = Q7.16
// FIR coefficients        Q2.21          : Q2.21 * Q7.16   = Q9.38   << output_scale = Q8.15
.ENDMODULE;

.MODULE $M.cbops.iir_resample.8_to_48;
   .DATASEGMENT DM;

   .BLOCK/DM1  filter;
   .VAR  fir_offset = 160;
   .VAR  fir_coef = &$M.cbops.iir_resample.fir.coeffs;
	.VAR  Input_Scale    = 1;
	.VAR  Output_Scale   = -1;
	.VAR  R_out          = 6;
	.VAR  frac_ratio     = 0.166667;
	//.VAR  int_ratio      = 0;   (down sample only)
	.VAR  iir_scale      = 2;
	.VAR  coeffs[10]= 0.7094354629516602,
	 -0.0001451969146729,
	 -0.0001455545425415,
	 -0.0001404285430908,
	 0.0000188350677490,
	 0.0006736516952515,
	 0.0201241970062256,
	 0.1497566699981690,
	 0.4421455860137940,
	 0.5561401844024658;
.ENDBLOCK;
// Upsample
// L = 6
// fir_scale	= 5;
// IIR Gain = 201.839210 *(Rout/160)<<fir_scale = 121.103526
// FIR Gain = 1.200000
// fp : Nyquyst*(1-0.110000) = 0.074167
// rp : (0.025000)^2 = 0.000625
// -3dB cutoff = 7801.440000 Hz
// intermediate (history)		Q7.16;

// input              Q8.15<<input_scale  = Q7.16
// IIR coefficients   Q2.21  :  Q7.16 * Q2.21 = Q9.18 >> iir_scale = Q7.16  
// FIR coefficients   Q2.21  :  Q7.16 * Q2.21 = Q9.18 << out_scale = Q8.15  
.ENDMODULE;

.MODULE $M.cbops.iir_resample.16_to_8;
   .DATASEGMENT DM;

   .BLOCK/DM1  filter;
   .VAR  fir_offset = 112;
   .VAR  fir_coef = &$M.cbops.iir_resample.fir.coeffs;
      .VAR  Input_Scale  = 0;         // IIR Scaling (input)
      .VAR  Output_Scale = -6;        // FIR Scaling (output)
      .VAR  R_out        = 1;
      .VAR  frac_ratio   = 0.0;
      .VAR  iir_inv_ratio = 0.5;
      .VAR  int_ratio    = 2;
      .VAR  iir_scale    = 3;
      .VAR  coeffs[10] =       0.991079330444336,
      -0.00336611270904541,
      0.02549850940704346,
      -0.09843456745147705,
      0.2511321306228638,
      -0.4650629758834839,
      0.6520981788635254,
      -0.6948447227478027,
      0.5659805536270142,
      -0.3137685060501099;
   .ENDBLOCK;

// Downsample
// L = 1
// fir_scale = 7
// IIR Gain  = 6.413 * (L/160)  << (fir_scale+1) = 10.2608
// intermediate (history)  Q4.19

// input                   Q8.15<<Input_Scale * 2^4 (x(n) coefficient scaling) = Q4.19
// IIR coefficients        Q3.20          : Q4.19 * Q3.20  = Q7.40  << iir_scale     = Q4.19
// FIR coefficients        Q-2.25         : Q4.19 * Q-2.25 = Q2.45  << output_scale  = Q8.15
.ENDMODULE;


.MODULE $M.cbops.iir_resample.16_to_22_05;
   .DATASEGMENT DM;

   .BLOCK/DM1  filter;
   .VAR  fir_offset = 160;
   .VAR  fir_coef = &$M.cbops.iir_resample.fir.coeffs;
      .VAR  Input_Scale  = 1;         // IIR Scaling (input)
      .VAR  Output_Scale = -1;        // FIR Scaling (output)
      .VAR  R_out        = 441;
      .VAR  frac_ratio   = 0.72562358276644;
      // .VAR  int_ratio    = 2;
      .VAR  iir_scale    = 2;
      .VAR  coeffs[10] =         0.7093470096588135,
         -0.0001451969146728516,
         -0.0001455545425415039,
         -0.0001403093338012695,
         1.883506774902344e-005,
         0.0006729364395141602,
         0.02011477947235107,
         0.1497137546539307,
         0.4420735836029053,
         0.5561010837554932;
   .ENDBLOCK;

// Upsample
// L = 441
// fir_scale = -1
// IIR Gain  = 175.689 * (L/160) << (fir_scale-1) = 121.061
// intermediate (history)  Q7.16

// input                   Q8.15<<Input_Scale = Q7.16
// IIR coefficients        Q2.21          : Q2.21 * Q7.16  = Q9.38  << iir_scale     = Q7.16
// FIR coefficients        Q5.18          : Q2.21 * Q5.18  = Q7.46  << output_scale  = Q8.15
.ENDMODULE;

.MODULE $M.cbops.iir_resample.16_to_32;
   .DATASEGMENT DM;

   .BLOCK/DM1  filter;
   .VAR  fir_offset = 160;
   .VAR  fir_coef = &$M.cbops.iir_resample.fir.coeffs;
      .VAR  Input_Scale  = 1;         // IIR Scaling (input)
      .VAR  Output_Scale = -1;        // FIR Scaling (output)
      .VAR  R_out        = 2;
      .VAR  frac_ratio   = 0.5;
      // .VAR  int_ratio    = 2;
      .VAR  iir_scale    = 2;
      .VAR  coeffs[10] =  0.7093918323516846,
         -0.0001451969146728516,
         -0.0001456737518310547,
         -0.0001403093338012695,
         1.966953277587891e-005,
         0.0006818771362304688,
         0.02012085914611816,
         0.1497193574905396,
         0.4421104192733765,
         0.5561230182647705;
   .ENDBLOCK;

// Upsample
// L = 2
// fir_scale = 7
// IIR Gain  = 151.154 * (L/160) << (fir_scale-1) = 120.9232
// intermediate (history)  Q7.16

// input                   Q8.15<<Input_Scale = Q7.16
// IIR coefficients        Q2.21          : Q2.21 * Q7.16  = Q9.38  << iir_scale     = Q7.16
// FIR coefficients        Q5.18          : Q2.21 * Q5.18  = Q7.40  << output_scale  = Q8.15
.ENDMODULE;

.MODULE $M.cbops.iir_resample.16_to_44_1;
   .DATASEGMENT DM;

   .BLOCK/DM1  filter;
   .VAR  fir_offset = 160;
   .VAR  fir_coef = &$M.cbops.iir_resample.fir.coeffs;
      .VAR  Input_Scale  = 1;         // IIR Scaling (input)
      .VAR  Output_Scale = -1;        // FIR Scaling (output)
      .VAR  R_out        = 441;
      .VAR  frac_ratio   = 0.36281179138322;
      // .VAR  int_ratio    = 2;
      .VAR  iir_scale    = 2;
      .VAR  coeffs[10] =         0.7093470096588135,
         -0.0001451969146728516,
         -0.0001455545425415039,
         -0.0001403093338012695,
         1.883506774902344e-005,
         0.0006729364395141602,
         0.02011477947235107,
         0.1497137546539307,
         0.4420735836029053,
         0.5561010837554932;
   .ENDBLOCK;

// Upsample
// L = 441
// fir_scale = -1
// IIR Gain  = 175.689 * (L/160) << (fir_scale-1) = 121.061
// intermediate (history)  Q7.16

// input                   Q8.15<<Input_Scale = Q7.16
// IIR coefficients        Q2.21          : Q2.21 * Q7.16  = Q9.38  << iir_scale     = Q7.16
// FIR coefficients        Q5.18          : Q2.21 * Q5.18  = Q7.46  << output_scale  = Q8.15
.ENDMODULE;

.MODULE $M.cbops.iir_resample.16_to_48;
   .DATASEGMENT DM;

   .BLOCK/DM1  filter;
   .VAR  fir_offset = 160;
   .VAR  fir_coef = &$M.cbops.iir_resample.fir.coeffs;
      .VAR  Input_Scale  = 1;         // IIR Scaling (input)
      .VAR  Output_Scale = -1;        // FIR Scaling (output)
      .VAR  R_out        = 3;
      .VAR  frac_ratio   = 0.3333333333333333;
      // .VAR  int_ratio    = 2;
      .VAR  iir_scale    = 2;
      .VAR  coeffs[10] =    0.7093510627746582,
      -0.0001451969146728516,
      -0.0001455545425415039,
      -0.0001403093338012695,
      1.9073486328125e-005,
      0.000674128532409668,
      0.02011466026306152,
      0.1497077941894531,
      0.4420629739761353,
      0.55609130859375;
   .ENDBLOCK;

// Upsample
// L = 3
// fir_scale = 6
// IIR Gain  = 201.636 * (L/160) << (fir_scale-1) = 120.9816
// intermediate (history)  Q7.16

// input                   Q8.15<<Input_Scale = Q7.16
// IIR coefficients        Q2.21          : Q2.21 * Q7.16  = Q9.38  << iir_scale     = Q7.16
// FIR coefficients        Q5.18          : Q2.21 * Q5.18  = Q7.40  << output_scale  = Q8.15
.ENDMODULE;

.MODULE $M.cbops.iir_resample.22_05_to_8;
   .DATASEGMENT DM;

   .BLOCK/DM1  filter;
   .VAR  fir_offset = 112;
   .VAR  fir_coef = &$M.cbops.iir_resample.fir.coeffs;
      .VAR  Input_Scale  = 0;          // IIR Scaling (input)
      .VAR  Output_Scale = -7;         // FIR Scaling (output)
      .VAR  R_out        = 160;
      .VAR  frac_ratio   = 0.75625;
      .VAR  iir_inv_ratio = 0.36281179138322;
      .VAR  int_ratio    = 2;
      .VAR  iir_scale    = 5;
      .VAR  coeffs[10] =     0.041690826416015616,
      -0.002242922782897949,
      0.02030301094055176,
      -0.08720040321350098,
      0.2330422401428223,
      -0.4275084733963013,
      0.559887170791626,
      -0.5262176990509033,
      0.3453081846237183,
      -0.1456907987594605;
   .ENDBLOCK;

// Downsample
// L = 160
// fscale=0
// IIR Gain  = 1.873 * (L/160) << (fscale+1) = 3.746

// input                   Q8.15<<input_scale = Q2.21  ( x(n) IIR coefficient scaled 2^5)
// intermediate (history)  Q3.20
// IIR coefficients        Q5.18          : Q3.20 * Q5.18   = Q8.39 << iir_scale    = Q3.20
// FIR coefficients        Q-2.24         : Q3.20 * Q-2.24  = Q1.46 << output_scale = Q8.15
.ENDMODULE;


.MODULE $M.cbops.iir_resample.22_05_to_16;
   .DATASEGMENT DM;

   .BLOCK/DM1  filter;
   .VAR  fir_offset = 112;
   .VAR  fir_coef = &$M.cbops.iir_resample.fir.coeffs;
      .VAR  Input_Scale  = 0;          // IIR Scaling (input)
      .VAR  Output_Scale = -1;         // FIR Scaling (output)
      .VAR  R_out        = 320;
      .VAR  frac_ratio   = 0.378125;
      .VAR  iir_inv_ratio = 0.72562358276643991;
      .VAR  int_ratio    = 1;
      .VAR  iir_scale    = 3;
      .VAR  coeffs[10] =      0.6550488471984863,
      -0.000586390495300293,
      0.001714587211608887,
      -0.003713488578796387,
      0.01488256454467773,
      0.01887798309326172,
      0.1195379495620728,
      0.1744985580444336,
      0.2882602214813232,
      0.1970182657241821;
   .ENDBLOCK;

// Downsample
// L = 320
// fir_scale = -2
// IIR Gain  = 159.998 * (L/160) (fir_scale+1) = 159.998
// intermediate (history)  Q8.15

// input                   Q8.15<<input_scale = Q5.18
// IIR coefficients        Q3.20          : Q8.15 * Q3.20   = Q11.36 << iir_scale    = Q8.15
// FIR coefficients        Q-1.24         : Q8.15 * Q-1.24  = Q7.40 << output_scale  = Q8.15
.ENDMODULE;


.MODULE $M.cbops.iir_resample.22_05_to_32;
   .DATASEGMENT DM;

   .BLOCK/DM1  filter;
   .VAR  fir_offset = 160;
   .VAR  fir_coef = &$M.cbops.iir_resample.fir.coeffs;
      .VAR  Input_Scale  = 1;         // IIR Scaling (input)
      .VAR  Output_Scale = -1;        // FIR Scaling (output)
      .VAR  R_out        = 640;
      .VAR  frac_ratio   = 0.6890625;
      // .VAR  int_ratio    = 2;
      .VAR  iir_scale    = 2;
      .VAR  coeffs[10] =           0.7093428373336792,
         -0.0001451969146728516,
         -0.0001455545425415039,
         -0.0001403093338012695,
         1.883506774902344e-005,
         0.0006729364395141602,
         0.02011477947235107,
         0.1497137546539307,
         0.4420735836029053,
         0.5561010837554932;
   .ENDBLOCK;

// Upsample
// L = 640
// fir_scale = -2
// IIR Gain  = 242.051 * (L/160) << (fir_scale-1) = 121.0255
// intermediate (history)  Q7.16

// input                   Q8.15<<Input_Scale = Q7.16
// IIR coefficients        Q2.21          : Q2.21 * Q7.16  = Q9.38  << iir_scale     = Q7.16
// FIR coefficients        Q5.18          : Q2.21 * Q5.18  = Q7.46  << output_scale  = Q8.15
.ENDMODULE;


.MODULE $M.cbops.iir_resample.22_05_to_44_1;
   .DATASEGMENT DM;

   .BLOCK/DM1  filter;
   .VAR  fir_offset = 160;
   .VAR  fir_coef = &$M.cbops.iir_resample.fir.coeffs;
      .VAR  Input_Scale  = 1;         // IIR Scaling (input)
      .VAR  Output_Scale = -1;        // FIR Scaling (output)
      .VAR  R_out        = 2;
      .VAR  frac_ratio   = 0.5;
      // .VAR  int_ratio    = 2;
      .VAR  iir_scale    = 2;
      .VAR  coeffs[10] =           0.7093918323516846,
      -0.0001451969146728516,
      -0.0001456737518310547,
      -0.0001403093338012695,
      1.966953277587891e-005,
      0.0006818771362304688,
      0.02012085914611816,
      0.1497193574905396,
      0.4421104192733765,
      0.5561230182647705;
   .ENDBLOCK;

// Upsample
// L = 2
// fir_scale = 7
// IIR Gain  = 151.154 * (L/160) << (fir_scale-1) = 120.9232
// intermediate (history)  Q7.16

// input                   Q8.15<<Input_Scale = Q7.16
// IIR coefficients        Q2.21          : Q2.21 * Q7.16  = Q9.38  << iir_scale     = Q7.16
// FIR coefficients        Q5.18          : Q2.21 * Q5.18  = Q7.46  << output_scale  = Q8.15
.ENDMODULE;

.MODULE $M.cbops.iir_resample.22_05_to_48;
   .DATASEGMENT DM;

   .BLOCK/DM1  filter;
   .VAR  fir_offset = 160;
   .VAR  fir_coef = &$M.cbops.iir_resample.fir.coeffs;
      .VAR  Input_Scale  = 1;         // IIR Scaling (input)
      .VAR  Output_Scale = -1;        // FIR Scaling (output)
      .VAR  R_out        = 320;
      .VAR  frac_ratio   = 0.459375;
      // .VAR  int_ratio    = 2;
      .VAR  iir_scale    = 2;
      .VAR  coeffs[10] =             0.7093415260314941,
      -0.0001451969146728516,
      -0.0001455545425415039,
      -0.0001403093338012695,
      1.883506774902344e-005,
      0.0006729364395141602,
      0.02011454105377197,
      0.149713397026062,
      0.4420732259750366,
      0.5561009645462036;
   .ENDBLOCK;

// Upsample
// L = 320
// fir_scale = -1
// IIR Gain  = 242.05 * (L/160) << (fir_scale-1) = 121.025
// intermediate (history)  Q7.16

// input                   Q8.15<<Input_Scale = Q7.16
// IIR coefficients        Q2.21          : Q2.21 * Q7.16  = Q9.38  << iir_scale     = Q7.16
// FIR coefficients        Q5.18          : Q2.21 * Q5.18  = Q7.46  << output_scale  = Q8.15
.ENDMODULE;


.MODULE $M.cbops.iir_resample.48_to_44_1;
   .DATASEGMENT DM;
   .BLOCK/DM1  filter;
            .VAR  fir_offset = 112;
   .VAR  fir_coef = &$M.cbops.iir_resample.fir.coeffs;
      .VAR  Input_Scale    = 0;
      .VAR  Output_Scale   = -1;
      .VAR  R_out          = 147;
      .VAR  frac_ratio     = 0.088435;
      .VAR  iir_inv_ratio  = 0.918750;
      .VAR  int_ratio      = 1;
      .VAR  iir_scale      = 3;
      .VAR  coeffs[10] = 0.7058161497116089,
             -0.0012841224670410,
             0.0024286508560181,
             -0.0053575038909912,
             0.0176601409912109,
             0.0214846134185791,
             0.1328840255737305,
             0.1949465274810791,
             0.3087363243103027,
             0.2104618549346924;
   .ENDBLOCK;
// Downsample
// L = 147
// fir_scale         = -1;
// IIR Gain = 262.455086 *(Rout/160)*2^(fir_scale+1) = 241.130610
// FIR Gain = 1.312500
// fp : Nyquyst*(1-0.263000) = 0.002303
// rp : (0.050000)^2 = 0.002500
// -3dB cutoff = 33586.560000 Hz
// intermediate (history)               Q8.15;

// input              Q8.15<<input_scale  = Q8.15
// IIR coefficients   Q3.20  :  Q8.15 * Q3.20 = Q11.18 >> iir_scale = Q8.15
// FIR coefficients   Q-1.24  :  Q8.15 * Q-1.24 = Q7.14 << out_scale = Q8.15
.ENDMODULE;


.MODULE $M.cbops.iir_resample.48_to_22_05;
   .DATASEGMENT DM;

   .BLOCK/DM1  filter;
            .VAR  fir_offset = 112;
   .VAR  fir_coef = &$M.cbops.iir_resample.fir.coeffs;
      .VAR  Input_Scale    = 8;
      .VAR  Output_Scale   = -7;
      .VAR  R_out          = 147;
      .VAR  frac_ratio     = 0.176871;
      .VAR  iir_inv_ratio  = 0.459375;
      .VAR  int_ratio      = 2;
      .VAR  iir_scale      = 3;
      .VAR  coeffs[10] = 0.0048333406448364,
             -0.0041681528091431,
             0.0332163572311401,
             -0.1322683095932007,
             0.3427609205245972,
             -0.6361154317855835,
             0.8806785345077515,
             -0.9161189794540405,
             0.7085224390029907,
             -0.3738992214202881;
   .ENDBLOCK;
// Downsample
// L = 147
// fir_scale         = -1;
// IIR Gain = 4.311005 *(Rout/160)*2^(fir_scale+1) = 3.960736
// FIR Gain = 1.312500
// fp : Nyquyst*(1-0.110000) = 0.001391
// rp : (0.025000)^2 = 0.000625
// -3dB cutoff = 21450.240000 Hz
// intermediate (history)               Q2.21;

// input              Q8.15<<input_scale *(2^-2 iir gain scaled) = Q2.21
// IIR coefficients   Q3.20  :  Q2.21 * Q3.20 = Q5.24 >> iir_scale = Q2.21
// FIR coefficients   Q-1.24  :  Q2.21 * Q-1.24 = Q1.20 << out_scale = Q8.15
.ENDMODULE;

.MODULE $M.cbops.iir_resample.48_to_8;
   .DATASEGMENT DM;

   .BLOCK/DM1  filter;
   .VAR  fir_offset = 112;
   .VAR  fir_coef = &$M.cbops.iir_resample.fir.coeffs;
	.VAR  Input_Scale    = 0; // 8;
	.VAR  Output_Scale   = -1; // -9;
	.VAR  R_out          = 1;
	.VAR  frac_ratio     = 0.000000;
	.VAR  iir_inv_ratio  = 0.166667;
	.VAR  int_ratio      = 6;
	.VAR  iir_scale      = 6;
	.VAR  coeffs[10]= 0.0000021457672119,
	 -0.0021433830261230,
	 0.0226991176605225,
	 -0.1082055568695068,
	 0.3048974275588989,
	 -0.5600293874740601,
	 0.6959298849105835,
	 -0.5856585502624512,
	 0.3222411870956421,
	 -0.1053528785705566;
.ENDBLOCK;
// Downsample
// L = 1
// fir_scale	= 7;
// IIR Gain = 1.046477 *(Rout/160)*2^(fir_scale+1) = 1.674364
// FIR Gain = 1.142890
// fp : Nyquyst*(1-0.263000) = 0.061417
// rp : (0.001000)^2 = 0.000001
// -3dB cutoff = 7861.440000 Hz
// intermediate (history)		Q1.22;

// input              Q8.15<<input_scale *(2^-1 iir gain scaled) = Q1.22
// IIR coefficients   Q6.17  :  Q1.22 * Q6.17 = Q7.28 >> iir_scale = Q1.22  
// FIR coefficients   Q-2.25  :  Q1.22 * Q-2.25 = Q-1.20 << out_scale = Q8.15 
.ENDMODULE;

.MODULE $M.cbops.iir_resample.32_to_8;
   .DATASEGMENT DM;

   .BLOCK/DM1  filter;
   .VAR  fir_offset = 112;
   .VAR  fir_coef = &$M.cbops.iir_resample.fir.coeffs;
      .VAR  Input_Scale  = 0;          // IIR Scaling (input)
      .VAR  Output_Scale = -8;         // FIR Scaling (output)
      .VAR  R_out        = 1;
      .VAR  frac_ratio   = 0.0;
      .VAR  iir_inv_ratio = 0.25;
      .VAR  int_ratio    = 4;
      .VAR  iir_scale    = 6;
      .VAR coeffs[10] =      0.00252532958984375,
      -0.002428889274597168,
      0.02336633205413818,
      -0.1031614542007446,
      0.2744510173797607,
      -0.4852931499481201,
      0.5922797918319702,
      -0.4999321699142456,
      0.2822444438934326,
      -0.09712278842926025;
   .ENDBLOCK;

// Downsample
// L = 4
// fir_scale = 7
// IIR Gain  = 1.339 * (L/160) (fir_scale+1) = 2.1424
// intermediate (history)  Q2.21

// input                   Q8.15<<input_scale = Q3.20 (x(n) coefficient scaled 2^6)
// IIR coefficients        Q6.17          : Q2.21 * Q6.17   = Q7.40 << iir_scale    = Q2.21
// FIR coefficients        Q-2.25         : Q2.21 * Q-2.25  = Q0.47 << output_scale = Q8.15
.ENDMODULE;

.MODULE $M.cbops.iir_resample.32_to_16;
   .DATASEGMENT DM;

   .BLOCK/DM1  filter;
   .VAR  fir_offset = 112;
   .VAR  fir_coef = &$M.cbops.iir_resample.fir.coeffs;
      .VAR  Input_Scale  = 0;         // IIR Scaling (input)
      .VAR  Output_Scale = -6;        // FIR Scaling (output)
      .VAR  R_out        = 1;
      .VAR  frac_ratio   = 0.0;
      .VAR  iir_inv_ratio = 0.5;
      .VAR  int_ratio    = 2;
      .VAR  iir_scale    = 3;
      .VAR  coeffs[10] =       0.991079330444336,
      -0.00336611270904541,
      0.02549850940704346,
      -0.09843456745147705,
      0.2511321306228638,
      -0.4650629758834839,
      0.6520981788635254,
      -0.6948447227478027,
      0.5659805536270142,
      -0.3137685060501099;
   .ENDBLOCK;

// Downsample
// L = 1
// fir_scale = 7
// IIR Gain  = 6.413 * (L/160)  << (fir_scale+1) = 10.2608
// intermediate (history)  Q4.19

// input                   Q8.15<<Input_Scale * 2^4 (x(n) coefficient scaling) = Q4.19
// IIR coefficients        Q3.20          : Q4.19 * Q3.20  = Q7.40  << iir_scale     = Q4.19
// FIR coefficients        Q-2.25         : Q4.19 * Q-2.25 = Q2.45  << output_scale  = Q8.15
.ENDMODULE;

.MODULE $M.cbops.iir_resample.32_to_22_05;
   .DATASEGMENT DM;

   .BLOCK/DM1  filter;
   .VAR  fir_offset = 112;
   .VAR  fir_coef = &$M.cbops.iir_resample.fir.coeffs;
      .VAR  Input_Scale  = 0;          // IIR Scaling (input)
      .VAR  Output_Scale = -2;         // FIR Scaling (output)
      .VAR  R_out        = 441;
      .VAR  frac_ratio   = 0.45124716553287981859410430839;
      .VAR  iir_inv_ratio = 0.6890625;
      .VAR  int_ratio    = 1;
      .VAR  iir_scale    = 3;
      .VAR  coeffs[10] =         0.8120154142379761,
         -0.0008020401000976563,
         0.003151059150695801,
         -0.008447170257568359,
         0.02080965042114258,
         -0.01646935939788818,
         0.09208464622497559,
         0.05059432983398438,
         0.2112957239151001,
         0.1026145219802856;
   .ENDBLOCK;

// Downsample
// L = 441
// fir_scale = -2
// IIR Gain  = 97.365 * (L/160) (fir_scale+1) = 132.1811
// intermediate (history)  Q8.15

// input                   Q8.15<<input_scale = Q5.18
// IIR coefficients        Q3.20          : Q8.15 * Q3.20   = Q11.36 << iir_scale    = Q8.15
// FIR coefficients        Q-2.25         : Q8.15 * Q-2.25  = Q3.45 << output_scale = Q8.15
.ENDMODULE;

.MODULE $M.cbops.iir_resample.32_to_44_1;
   .DATASEGMENT DM;

   .BLOCK/DM1  filter;
   .VAR  fir_offset = 160;
   .VAR  fir_coef = &$M.cbops.iir_resample.fir.coeffs;
      .VAR  Input_Scale  = 1;         // IIR Scaling (input)
      .VAR  Output_Scale = -1;        // FIR Scaling (output)
      .VAR  R_out        = 441;
      .VAR  frac_ratio   = 0.72562358276643991;
      // .VAR  int_ratio    = 2;
      .VAR  iir_scale    = 2;
      .VAR coeffs[10] =  0.7093470096588135,
      -0.0001451969146728516,
      -0.0001455545425415039,
      -0.0001403093338012695,
      1.883506774902344e-005,
      0.0006729364395141602,
      0.02011477947235107,
      0.1497137546539307,
      0.4420735836029053,
      0.5561010837554932;
   .ENDBLOCK;

// Upsample
// L = 441
// fir_scale = -1
// IIR Gain  = 175.689 * (L/160) << (fir_scale-1) = 121.061
// intermediate (history)  Q7.16

// input                   Q8.15<<Input_Scale = Q7.16
// IIR coefficients        Q2.21          : Q2.21 * Q7.16  = Q9.38  << iir_scale     = Q7.16
// FIR coefficients        Q5.18          : Q2.21 * Q5.18  = Q7.46  << output_scale  = Q8.15
.ENDMODULE;

.MODULE $M.cbops.iir_resample.32_to_48;
   .DATASEGMENT DM;

   .BLOCK/DM1  filter;
   .VAR  fir_offset = 160;
   .VAR  fir_coef = &$M.cbops.iir_resample.fir.coeffs;
      .VAR  Input_Scale  = 1;         // IIR Scaling (input)
      .VAR  Output_Scale = -1;        // FIR Scaling (output)
      .VAR  R_out        = 3;
      .VAR  frac_ratio   = 0.66666666666666667;
      // .VAR  int_ratio    = 2;
      .VAR  iir_scale    = 2;
      .VAR coeffs[10] =    0.7093510627746582,
      -0.0001451969146728516,
      -0.0001455545425415039,
      -0.0001403093338012695,
      1.9073486328125e-005,
      0.000674128532409668,
      0.02011466026306152,
      0.1497077941894531,
      0.4420629739761353,
      0.55609130859375;
   .ENDBLOCK;

// Upsample
// L = 3
// fir_scale = 6
// IIR Gain  = 201.636 * (L/160) << (fir_scale-1) = 120.9816
// intermediate (history)  Q7.16

// input                   Q8.15<<Input_Scale = Q7.16
// IIR coefficients        Q2.21          : Q2.21 * Q7.16  = Q9.38  << iir_scale     = Q7.16
// FIR coefficients        Q5.18          : Q2.21 * Q5.18  = Q7.46  << output_scale  = Q8.15
.ENDMODULE;

.MODULE $M.cbops.iir_resample.44_1_to_8;
   .DATASEGMENT DM;

   .BLOCK/DM1  filter;
   .VAR  fir_offset = 112;
   .VAR  fir_coef = &$M.cbops.iir_resample.fir.coeffs;
      .VAR  Input_Scale  = 0;          // IIR Scaling (input)
      .VAR  Output_Scale = -9;         // FIR Scaling (output)
      .VAR  R_out        = 80;
      .VAR  frac_ratio   = 0.5125;
      .VAR  iir_inv_ratio = 0.18140589569161;
      .VAR  int_ratio    = 5;
      .VAR  iir_scale    = 6;
      .VAR coeffs[10] =          0.000350952148437500032,
      -0.004041552543640137,
      0.03926873207092285,
      -0.1725020408630371,
      0.4498000144958496,
      -0.7675679922103882,
      0.8894984722137451,
      -0.7005689144134522,
      0.3619838953018189,
      -0.111493706703186;
   .ENDBLOCK;

// Downsample
// L = 80
// fir_scale = 1
// IIR Gain  = 0.89 * (L/160) (fir_scale+1) = 1.78
// intermediate (history)  Q1.22

// input                   Q8.15<<input_scale * (2^7 x(n) iir coefficient scaled) = Q1.22
// IIR coefficients        Q6.17          : Q1.22 * Q6.17   = Q7.40 << iir_scale    = Q1.22
// FIR coefficients        Q-2.25         : Q1.22 * Q-2.25  = Q-1.48 << output_scale = Q8.15
.ENDMODULE;

.MODULE $M.cbops.iir_resample.44_1_to_16;
   .DATASEGMENT DM;

   .BLOCK/DM1  filter;
   .VAR  fir_offset = 112;
   .VAR  fir_coef = &$M.cbops.iir_resample.fir.coeffs;
      .VAR  Input_Scale  = 0;          // IIR Scaling (input)
      .VAR  Output_Scale = -8;         // FIR Scaling (output)
      .VAR  R_out        = 160;
      .VAR  frac_ratio   = 0.75625;
      .VAR  iir_inv_ratio = 0.36281179138322;
      .VAR  int_ratio    = 2;
      .VAR  iir_scale    = 5;
      .VAR  coeffs[10] =     0.083381652832031232,
      -0.002242922782897949,
      0.02030301094055176,
      -0.08720040321350098,
      0.2330422401428223,
      -0.4275084733963013,
      0.559887170791626,
      -0.5262176990509033,
      0.3453081846237183,
      -0.1456907987594605;
   .ENDBLOCK;

// Downsample
// L = 160
// fscale=0
// IIR Gain  = 1.873 * (L/160) << (fscale+1) = 3.746

// input                   Q8.15<<input_scale = Q2.21  ( x(n) IIR coefficient scaled 2^6)
// intermediate (history)  Q2.21
// IIR coefficients        Q5.18          : Q2.21 * Q5.18   = Q7.40 << iir_scale    = Q2.21
// FIR coefficients        Q-2.24         : Q2.21 * Q-2.24  = Q0.47 << output_scale = Q8.15
.ENDMODULE;

.MODULE $M.cbops.iir_resample.44_1_to_22_05;
   .DATASEGMENT DM;

   .BLOCK/DM1  filter;
   .VAR  fir_offset = 112;
   .VAR  fir_coef = &$M.cbops.iir_resample.fir.coeffs;
      .VAR  Input_Scale  = 0;         // IIR Scaling (input)
      .VAR  Output_Scale = -6;        // FIR Scaling (output)
      .VAR  R_out        = 1;
      .VAR  frac_ratio   = 0.0;
      .VAR  iir_inv_ratio = 0.5;
      .VAR  int_ratio    = 2;
      .VAR  iir_scale    = 3;
      .VAR  coeffs[10] =       0.991079330444336,
      -0.00336611270904541,
      0.02549850940704346,
      -0.09843456745147705,
      0.2511321306228638,
      -0.4650629758834839,
      0.6520981788635254,
      -0.6948447227478027,
      0.5659805536270142,
      -0.3137685060501099;
   .ENDBLOCK;

// Downsample
// L = 1
// fir_scale = 7
// IIR Gain  = 6.413 * (L/160)  << (fir_scale+1) = 10.2608
// intermediate (history)  Q4.19

// input                   Q8.15<<Input_Scale * 2^4 (x(n) coefficient scaling) = Q4.19
// IIR coefficients        Q3.20          : Q4.19 * Q3.20  = Q7.40  << iir_scale     = Q4.19
// FIR coefficients        Q-2.25         : Q4.19 * Q-2.25 = Q2.45  << output_scale  = Q8.15
.ENDMODULE;

.MODULE $M.cbops.iir_resample.44_1_to_32;
   .DATASEGMENT DM;

   .BLOCK/DM1  filter;
   .VAR  fir_offset = 112;
   .VAR  fir_coef = &$M.cbops.iir_resample.fir.coeffs;
      .VAR  Input_Scale  = 0;          // IIR Scaling (input)
      .VAR  Output_Scale = -1;         // FIR Scaling (output)
      .VAR  R_out        = 320;
      .VAR  frac_ratio   = 0.378125;
      .VAR  iir_inv_ratio = 0.72562358276643991;
      .VAR  int_ratio    = 1;
      .VAR  iir_scale    = 3;
      .VAR  coeffs[10] =      0.6550488471984863,
      -0.000586390495300293,
      0.001714587211608887,
      -0.003713488578796387,
      0.01488256454467773,
      0.01887798309326172,
      0.1195379495620728,
      0.1744985580444336,
      0.2882602214813232,
      0.1970182657241821;
   .ENDBLOCK;

// Downsample
// L = 320
// fir_scale = -2
// IIR Gain  = 159.998 * (L/160) (fir_scale+1) = 159.998
// intermediate (history)  Q8.15

// input                   Q8.15<<input_scale = Q5.18
// IIR coefficients        Q3.20          : Q8.15 * Q3.20   = Q11.36 << iir_scale    = Q8.15
// FIR coefficients        Q-1.24         : Q8.15 * Q-1.24  = Q7.40 << output_scale  = Q8.15
.ENDMODULE;

.MODULE $M.cbops.iir_resample.44_1_to_48;
   .DATASEGMENT DM;

   .BLOCK/DM1  filter;
   .VAR  fir_offset = 160;
   .VAR  fir_coef = &$M.cbops.iir_resample.fir.coeffs;
      .VAR  Input_Scale  = 1;          // IIR Scaling (input)
      .VAR  Output_Scale = -1;         // FIR Scaling (output)
      .VAR  R_out        = 160;
      .VAR  frac_ratio   = 0.91875;
      // .VAR int_ratio = 0;      // (down sample only)
      .VAR  iir_scale    = 2;
      .VAR  coeffs[10] = 0.7093384273566018,
         -0.0001452220855041119,
         -0.00014555820486317846,
         -0.00014036133922584346,
         0.000018866970104738922,
         0.0006728890598081896,
         0.02011422481034978,
         0.14971188240789008,
         0.4420709931752078,
         0.5560998701072062;
   .ENDBLOCK;

// Upsample
// L = 160
// IIR Gain  = 242.117 * (L/160) = 242.117

// input                   Q8.15<<input_scale = Q8.15 (x(n) coefficient scaling 2^-1)
// intermediate (history)  Q8.15
// IIR coefficients        Q2.20          : Q8.15 * Q2.20   = Q11.36 << iir_scale    = Q8.15
// FIR coefficients        Q-1.24         : Q8.15 * Q-1.24  = Q7.40  << output_scale = Q8.15
.ENDMODULE;



// Note:  The FIR coefficients have been scaled by 2^1 to provide
//  optimum resolution (Q.16).  This scaling must be removed from
//  the final output.

//      Also a scale of 160 due to the decimation (L) of the prototype filter was
//      applied to the FIR coefficients.
//      Filters with different (L) must scale the IIR and FIR coefficients accordingly
//      to provide zero dB in the pass band


// Reduced Fir Coefficients for up/down sample By a factor or 2
.MODULE  $M.cbops.iir_resample.firDownBy2;
   .DATASEGMENT   DM;

.VAR/DM2 coeffs[10] = 0,//6.316919684089581e-019,   //   $M.iir_resample.fir.coeffs[0*112]
 0.005484158159210061,                          //   $M.iir_resample.fir.coeffs[1*112 -1]
 0.005671692263320743,                          //   $M.iir_resample.fir.coeffs[1*112]
 0.07344768883832342,                           //   $M.iir_resample.fir.coeffs[2*112 -1]
 0.0746604606865319,                            //   $M.iir_resample.fir.coeffs[2*112]
 0.300510492609979,                             //   $M.iir_resample.fir.coeffs[3*112 -1]
 0.3033185607677786,                            //   $M.iir_resample.fir.coeffs[3*112]
 0.6390642336318084,                            //   $M.iir_resample.fir.coeffs[4*112 -1]
 0.641827492495866,                             //   $M.iir_resample.fir.coeffs[4*112]
 0.8132390721581306;                            //   $M.iir_resample.fir.coeffs[5*112 -1]

.ENDMODULE;

.MODULE  $M.cbops.iir_resample.firUpBy2;
   .DATASEGMENT   DM;

.VAR/DM2 coeffs[15] = 0,//6.316919684089581e-019,   // $M.iir_resample.fir.coeffs[0*160]
 0.001500816345121228,                          // $M.iir_resample.fir.coeffs[0*160 + 79]
 0.001576295656900794,                          // $M.iir_resample.fir.coeffs[0*160 + 80]
 0.0209712922137875,                            // $M.iir_resample.fir.coeffs[1*160 -1]
 0.02146677566281566,                           // $M.iir_resample.fir.coeffs[1*160]
 0.09453599476277745,                           // $M.iir_resample.fir.coeffs[1*160 + 79]
 0.0959758210869249,                            // $M.iir_resample.fir.coeffs[1*160 + 80]
 0.2571576392618858,                            // $M.iir_resample.fir.coeffs[2*160 -1]
 0.2597754325858392,                            // $M.iir_resample.fir.coeffs[2*160]
 0.494923669007769,                             // $M.iir_resample.fir.coeffs[2*160 + 79]
 0.498060732106223,                             // $M.iir_resample.fir.coeffs[2*160 + 80]
 0.7193254569349034,                            // $M.iir_resample.fir.coeffs[3*160 -1]
 0.7215207600430634,                            // $M.iir_resample.fir.coeffs[3*160]
 0.8132390721581306,                            // $M.iir_resample.fir.coeffs[3*160 + 79]
 0.8132390721581306;                            // $M.iir_resample.fir.coeffs[3*160 + 80]

.ENDMODULE;

// Fir Coefficients for General Up/Down resample

.MODULE $M.cbops.iir_resample.fir;
   .DATASEGMENT DM;

   .VAR/DM2 coeffs[640] =   0, // 6.316919684089581e-019 will underflow to 0
-1.253307290185089e-007,
-4.859448124414579e-007,
-1.058633555265514e-006,
-1.819996010898487e-006,
-2.746434513662754e-006,
-3.814150150084586e-006,
-4.999138170923597e-006,
-6.277183345823095e-006,
-7.62385526257913e-006,
-9.014503572986269e-006,
-1.042425318731558e-005,
-1.182799941946081e-005,
-1.320040308484185e-005,
-1.451588555320235e-005,
-1.574862375841519e-005,
-1.687254516750326e-005,
-1.786132271107349e-005,
-1.868836967737045e-005,
-1.932683457226034e-005,
-1.974959594738573e-005,
-1.99292571988294e-005,
-1.983814133862054e-005,
-1.944828574144934e-005,
-1.873143686897118e-005,
-1.765904497412046e-005,
-1.62022587878635e-005,
-1.433192019084592e-005,
-1.201855887242111e-005,
-9.232386979542548e-006,
-5.943293758056358e-006,
-2.120840188919976e-006,
 2.265746378093417e-006,
 7.247577590627661e-006,
 1.285610945732596e-005,
 1.912314770615302e-005,
 2.60808531348335e-005,
 3.37617469507711e-005,
 4.219871609779252e-005,
 5.142501856705575e-005,
 6.147428868943956e-005,
 7.238054240672924e-005,
 8.417818251889656e-005,
 9.690200390476239e-005,
 0.0001105871987133255,
 0.0001252693615230252,
 0.0001409844944662119,
 0.000157769012316063,
 0.0001756597475332216,
 0.0001946939552693863,
 0.0002149093183250972,
 0.0002363439520589642,
 0.0002590364092455653,
 0.0002830256848792549,
 0.0003083512209211117,
 0.0003350529109862586,
 0.0003631711049687956,
 0.0003927466136015802,
 0.0004238207129480771,
 0.0004564351488235401,
 0.0004906321411427744,
 0.0005264543881916896,
 0.0005639450708199718,
 0.0006031478565520498,
 0.000644106903613721,
 0.0006868668648716304,
 0.0007314728916829507,
 0.0007779706376525421,
 0.0008264062622948996,
 0.0008768264345982147,
 0.0009292783364878891,
 0.0009838096661868435,
 0.001040468641470002,
 0.001099304002810297,
 0.001160365016413641,
 0.001223701477140203,
 0.001289363711309542,
 0.001357402579386879,
 0.001427869478548157,
 0.001500816345121228,
 0.001576295656900794,
 0.001654360435334526,
 0.001735064247578055,
 0.001818461208416258,
 0.001904605982048575,
 0.00199355378373592,
 0.002085360381306882,
 0.002180082096520839,
 0.002277775806285789,
 0.002378498943728554,
 0.002482309499115197,
 0.002589266020619381,
 0.002699427614936587,
 0.002812853947741991,
 0.002929605243989928,
 0.003049742288052878,
  0.0031733264236979,
 0.003300419553898583,
 0.003431084140480471,
 0.003565383203598147,
 0.00370338032104193,
 0.00384513962737248,
 0.003990725812881424,
 0.004140204122376276,
 0.004293640353787795,
 0.004451100856598323,
 0.004612652530089187,
 0.004778362821405729,
 0.004948299723438413,
 0.005122531772518307,
 0.005301128045925667,
 0.005484158159210061,
 0.005671692263320743,
 0.005863801041545824,
 0.006060555706259021,
 0.006262027995472723,
 0.00646829016919616,
 0.006679415005597568,
 0.006895475796969143,
 0.00711654634549386,
 0.007342700958813085,
 0.007574014445393987,
 0.007810562109695962,
  0.0080524197471351,
 0.008299663638845991,
 0.008552370546240078,
 0.008810617705359817,
 0.009074482821028134,
 0.009344044060792468,
 0.009619380048662925,
 0.009900569858644067,
 0.01018769300805994,
 0.01048082945067179,
 0.01078005956958853,
 0.01108546416996936,
 0.01139712447151837,
 0.01171512210077126,
 0.01203953908317381,
 0.01237045783495213,
 0.01270796115477491,
 0.01305213221520743,
 0.01340305455395774,
 0.01376081206491524,
 0.01412548898898155,
 0.01449716990469458,
 0.01487593971864558,
 0.01526188365569005,
 0.01565508724895289,
 0.01605563632962803,
 0.01646361701657384,
 0.01687911570570432,
 0.01730221905917709,
 0.01773301399437919,
  0.0181715876727111,
 0.01861802748817019,
 0.01907242105573464,
  0.0195348561995486,
 0.02000542094090993,
 0.02048420348606151,
  0.0209712922137875,
 0.02146677566281566,
 0.02197074251902723,
 0.02248328160247563,
 0.02300448185421547,
 0.02353443232294358,
 0.02407322215145324,
 0.02462094056290365,
 0.02517767684690603,
  0.0257435203454285,
  0.0263185604385209,
 0.02690288652986212,
  0.0274965880321315,
 0.02809975435220625,
 0.02871247487618717,
  0.0293348389542546,
 0.02996693588535671,
 0.03060885490173262,
 0.03126068515327231,
 0.03192251569171586,
 0.03259443545469434,
 0.03327653324961466,
 0.03396889773739136,
 0.03467161741602707,
 0.03538478060404512,
 0.03610847542377626,
 0.03684278978450278,
 0.03758781136546243,
 0.03834362759871494,
 0.03911032565187418,
 0.03988799241070912,
 0.04067671446161581,
  0.0414765780739642,
 0.04228766918232259,
 0.04311007336856256,
   0.043943875843848,
  0.0447891614305112,
 0.04564601454381933,
 0.04651451917363465,
 0.04739475886597181,
 0.04828681670445546,
 0.04919077529168224,
 0.05010671673048973,
 0.05103472260513664,
 0.05197487396239757,
  0.0529272512925759,
 0.05389193451043853,
 0.05486900293607638,
 0.05585853527569408,
  0.0568606096023327,
 0.05787530333652983,
 0.05890269322691981,
 0.05994285533077946,
 0.06099586499452202,
 0.06206179683414377,
 0.06314072471562726,
 0.06423272173530567,
 0.06533786020019133,
  0.0664562116082735,
  0.0675878466287891,
 0.06873283508247066,
 0.06989124592177552,
 0.07106314721110089,
 0.07224860610698841,
 0.07344768883832342,
  0.0746604606865319,
 0.07588698596578115,
 0.07712732800318678,
 0.07838154911903145,
 0.07964971060700007,
 0.08093187271443426,
 0.08222809462261296,
  0.0835384344270606,
 0.08486294911789059,
 0.08620169456018592,
   0.087554725474423,
 0.08892209541694231,
 0.09030385676047115,
 0.09170006067470253,
 0.09311075710693491,
 0.09453599476277745,
  0.0959758210869249,
 0.09743028224400764,
 0.09889942309952048,
  0.1003832872008354,
  0.1018819167583025,
  0.1033953526264441,
  0.1049236342852463,
  0.1064667998215528,
  0.1080248859105654,
  0.1095979277974566,
  0.1111859592790965,
  0.1127890126859028,
  0.1144071188638135,
  0.1160403071563917,
  0.1176886053870628,
  0.1193520398414924,
  0.1210306352501064,
  0.1227244147707605,
  0.1244333999715609,
   0.126157610813844,
  0.1278970656353161,
  0.1296517811333607,
  0.1314217723485162,
  0.1332070526481279,
  0.1350076337101816,
  0.1368235255073198,
  0.1386547362910469,
  0.1405012725761277,
  0.1423631391251831,
  0.1442403389334878,
  0.1461328732139733,
  0.1480407413824422,
  0.1499639410429968,
  0.1519024679736866,
  0.1538563161123789,
   0.155825477542857,
  0.1578099424811502,
  0.1598096992620985,
  0.1618247343261576,
  0.1638550322064487,
  0.1659005755160545,
  0.1679613449355681,
  0.1700373192008975,
  0.1721284750913302,
  0.1742347874178606,
  0.1763562290117858,
  0.1784927707135721,
   0.180644381361997,
  0.1828110277835693,
  0.1849926747822328,
  0.1871892851293545,
  0.1894008195540035,
  0.1916272367335233,
  0.1938684932843996,
  0.1961245437534294,
  0.1983953406091928,
  0.2006808342338317,
  0.2029809729151392,
  0.2052957028389615,
  0.2076249680819164,
  0.2099687106044323,
  0.2123268702441087,
  0.2146993847094028,
   0.217086189573645,
  0.2194872182693855,
  0.2219024020830755,
  0.2243316701500856,
  0.2267749494500632,
  0.2292321648026335,
  0.2317032388634448,
  0.2341880921205613,
  0.2366866428912069,
  0.2391988073188595,
  0.2417244993707021,
    0.24426363083543,
  0.2468161113214162,
  0.2493818482552397,
   0.251960746880577,
   0.254552710257457,
  0.2571576392618858,
  0.2597754325858392,
  0.2624059867376254,
  0.2650491960426216,
   0.267704952644385,
  0.2703731465061378,
  0.2730536654126307,
  0.2757463949723853,
  0.2784512186203159,
  0.2811680176207316,
  0.2838966710707238,
  0.2866370559039334,
  0.2893890468947057,
  0.2921525166626289,
  0.2949273356774597,
  0.2977133722644364,
   0.300510492609979,
  0.3033185607677786,
  0.3061374386652753,
  0.3089669861105269,
  0.3118070607994651,
  0.3146575183235456,
  0.3175182121777844,
  0.3203889937691895,
  0.3232697124255789,
   0.326160215404793,
  0.3290603479042953,
  0.3319699530711638,
  0.3348888720124762,
  0.3378169438060777,
  0.3407540055117475,
  0.3436998921827462,
  0.3466544368777568,
  0.3496174706732109,
  0.3525888226760042,
  0.3555683200365949,
  0.3585557879624918,
  0.3615510497321232,
  0.3645539267090887,
  0.3675642383567978,
  0.3705818022534838,
  0.3736064341076013,
  0.3766379477735984,
  0.3796761552680698,
  0.3827208667862794,
  0.3857718907190633,
  0.3888290336700979,
  0.3918921004735418,
  0.3949608942120448,
  0.3980352162351222,
  0.4011148661778954,
  0.4041996419801898,
  0.4072893399059974,
  0.4103837545632938,
  0.4134826789242109,
  0.4165859043455613,
  0.4196932205897139,
  0.4228044158458172,
  0.4259192767513635,
  0.4290375884141018,
  0.4321591344342813,
  0.4352836969272387,
  0.4384110565463126,
  0.4415409925060931,
  0.4446732826059933,
  0.4478077032541484,
   0.450944029491632,
  0.4540820350169914,
  0.4572214922110954,
  0.4603621721622925,
  0.4635038446918755,
   0.466646278379847,
  0.4697892405909875,
   0.472932497501214,
  0.4760758141242329,
  0.4792189543384806,
   0.482361680914345,
  0.4855037555416653,
  0.4886449388575127,
  0.4917849904742339,
   0.494923669007769,
   0.498060732106223,
  0.5011959364787034,
  0.5043290379244041,
  0.5074597913619424,
  0.5105879508589395,
  0.5137132696618372,
  0.5168355002259526,
  0.5199543942457638,
  0.5230697026854134,
  0.5261811758094428,
  0.5292885632137322,
  0.5323916138566567,
  0.5354900760904442,
   0.538583697692737,
  0.5416722258983424,
  0.5447554074311789,
  0.5478329885364032,
  0.5509047150127178,
  0.5539703322448522,
  0.5570295852362089,
    0.56008221864168,
  0.5631279768006116,
  0.5661666037699283,
  0.5691978433573972,
  0.5722214391550374,
  0.5752371345726608,
  0.5782446728715462,
  0.5812437971982297,
  0.5842342506184234,
  0.5872157761510326,
  0.5901881168022924,
  0.5931510155999943,
  0.5961042156278111,
  0.5990474600597117,
  0.6019804921944532,
  0.6049030554901529,
  0.6078148935989315,
   0.610715750401615,
  0.6136053700425012,
  0.6164834969641722,
  0.6193498759423581,
  0.6222042521208369,
  0.6250463710463681,
  0.6278759787036535,
  0.6306928215503228,
  0.6334966465519274,
  0.6362872012169495,
  0.6390642336318084,
   0.641827492495866,
  0.6445767271564211,
  0.6473116876436877,
  0.6500321247057501,
  0.6527377898434881,
  0.6554284353454694,
  0.6581038143227984,
  0.6607636807439188,
  0.6634077894693574,
  0.6660358962864157,
  0.6686477579437843,
  0.6712431321860947,
  0.6738217777883839,
  0.6763834545904766,
  0.6789279235312733,
  0.6814549466829466,
  0.6839642872850205,
   0.686455709778353,
  0.6889289798389917,
   0.691383864411911,
  0.6938201317446173,
  0.6962375514206201,
  0.6986358943927613,
  0.7010149330163933,
  0.7033744410824103,
   0.705714193850111,
  0.7080339680798979,
  0.7103335420658096,
  0.7126126956678625,
  0.7148712103442227,
  0.7171088691831751,
  0.7193254569349034,
  0.7215207600430634,
   0.723694566676152,
  0.7258466667586593,
  0.7279768520019987,
  0.7300849159352183,
  0.7321706539354727,
  0.7342338632582643,
  0.7362743430674358,
  0.7382918944649175,
  0.7402863205202217,
  0.7422574262996733,
  0.7442050188953779,
  0.7461289074539188,
   0.748028903204778,
  0.7499048194884761,
  0.7517564717844225,
  0.7535836777384775,
  0.7553862571902147,
  0.7571640321998832,
  0.7589168270750573,
  0.7606444683969795,
  0.7623467850465833,
  0.7640236082301923,
  0.7656747715048926,
  0.7673001108035744,
  0.7688994644596356,
  0.7704726732313421,
  0.7720195803258435,
  0.7735400314228378,
  0.7750338746978797,
  0.7765009608453302,
  0.7779411431009395,
  0.7793542772640644,
  0.7807402217195107,
  0.7820988374589981,
  0.7834299881022483,
  0.7847335399176787,
  0.7860093618427197,
  0.7872573255037242,
   0.788477305235496,
  0.7896691781004028,
  0.7908328239070966,
  0.7919681252288175,
  0.7930749674212918,
   0.794153238640214,
  0.7952028298583069,
  0.7962236348819661,
  0.7972155503674755,
  0.7981784758367978,
  0.7991123136929292,
  0.8000169692348291,
  0.8008923506719028,
  0.8017383691380529,
  0.8025549387052851,
  0.8033419763968672,
  0.8040994022000457,
  0.8048271390783097,
  0.8055251129832007,
  0.8061932528656729,
  0.8068314906869923,
  0.8074397614291797,
  0.8080180031049926,
  0.8085661567674423,
  0.8090841665188499,
  0.8095719795194345,
  0.8100295459954316,
  0.8104568192467443,
  0.8108537556541249,
  0.8112203146858781,
  0.8115564589041002,
  0.8118621539704317,
  0.8121373686513456,
  0.8123820748229491,
  0.8125962474753143,
  0.8127798647163251,
  0.8129329077750482,
  0.8130553610046223,
  0.8131472118846672,
  0.8132084510232094,
  0.8132390721581306,
  0.8132390721581306,
  0.8132084510232094,
  0.8131472118846672,
  0.8130553610046223,
  0.8129329077750482,
  0.8127798647163251,
  0.8125962474753143,
  0.8123820748229491,
  0.8121373686513456,
  0.8118621539704317,
  0.8115564589041002,
  0.8112203146858781,
  0.8108537556541249,
  0.8104568192467443,
  0.8100295459954316,
  0.8095719795194345,
  0.8090841665188499,
  0.8085661567674423,
  0.8080180031049926,
  0.8074397614291797,
  0.8068314906869923,
  0.8061932528656729,
  0.8055251129832007,
  0.8048271390783097,
  0.8040994022000457,
  0.8033419763968672,
  0.8025549387052851,
  0.8017383691380529,
  0.8008923506719028,
  0.8000169692348291,
  0.7991123136929292,
  0.7981784758367978,
  0.7972155503674755,
  0.7962236348819661,
  0.7952028298583069,
   0.794153238640214,
  0.7930749674212918,
  0.7919681252288175,
  0.7908328239070966,
  0.7896691781004028,
   0.788477305235496,
  0.7872573255037242,
  0.7860093618427197,
  0.7847335399176787,
  0.7834299881022483,
  0.7820988374589981,
  0.7807402217195107,
  0.7793542772640644,
  0.7779411431009395,
  0.7765009608453302,
  0.7750338746978797,
  0.7735400314228378,
  0.7720195803258435,
  0.7704726732313421,
  0.7688994644596356,
  0.7673001108035744,
  0.7656747715048926,
  0.7640236082301923,
  0.7623467850465833,
  0.7606444683969795,
  0.7589168270750573,
  0.7571640321998832,
  0.7553862571902147,
  0.7535836777384775,
  0.7517564717844225,
  0.7499048194884761,
   0.748028903204778,
  0.7461289074539188,
  0.7442050188953779,
  0.7422574262996733,
  0.7402863205202217,
  0.7382918944649175,
  0.7362743430674358,
  0.7342338632582643,
  0.7321706539354727,
  0.7300849159352183,
  0.7279768520019987,
  0.7258466667586593,
   0.723694566676152,
  0.7215207600430634;


.ENDMODULE;

