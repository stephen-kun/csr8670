// *****************************************************************************
// %%fullcopyright(2007)        http://www.csr.com
// %%version
//
// $Change: 1882869 $  $DateTime: 2014/04/23 13:37:24 $
// *****************************************************************************

#ifndef AUDIO_STEREO_3D_ENHANCMENT_HEADER_INCLUDED
#define AUDIO_STEREO_3D_ENHANCMENT_HEADER_INCLUDED

// stereo_3d_enhancement data object definitions
.CONST   $cbops.stereo_3d_enhancement_op.INPUT_1_START_INDEX_FIELD       0;
.CONST   $cbops.stereo_3d_enhancement_op.INPUT_2_START_INDEX_FIELD       1;
.CONST   $cbops.stereo_3d_enhancement_op.OUTPUT_1_START_INDEX_FIELD      2;
.CONST   $cbops.stereo_3d_enhancement_op.OUTPUT_2_START_INDEX_FIELD      3;
.CONST   $cbops.stereo_3d_enhancement_op.DELAY_1_STRUC_FIELD             4;
.CONST   $cbops.stereo_3d_enhancement_op.DELAY_2_STRUC_FIELD             5;
.CONST   $cbops.stereo_3d_enhancement_op.COEFF_STRUC_FIELD               6;
.CONST   $cbops.stereo_3d_enhancement_op.REFLECTION_DELAY_SAMPLES_FIELD  7;
.CONST   $cbops.stereo_3d_enhancement_op.MIX_FIELD                       8;
.CONST   $cbops.stereo_3d_enhancement_op.STRUC_SIZE                      9;

// A good delay (in samples) for the reflections
.CONST   $cbops.stereo_3d_enhancement_op.REFLECTION_DELAY                618;

// The delay buffer size needs to be at least Max.3D width + NUM_SAMPLES_PER_FRAME samples
// e.g. for a delay buffer size=2048 and NUM_SAMPLES_PER_FRAME=360
// the Max 3D width=1688.
// The UFE/app should restrict the width value accordingly otherwise distortion
// will result.
.CONST   $cbops.stereo_3d_enhancement_op.DELAY_BUFFER_SIZE               2048;

#endif
