/****************************************************************************
Copyright (C) Cambridge Silicon Radio Ltd. 2004-2014

FILE NAME
    sink_tones.c
    
DESCRIPTION
    module responsible for tone generation and playback
    
*/

#include "sink_private.h"
#include "sink_tones.h"
#include "sink_audio_prompts.h"
#include "sink_events.h"
#include "sink_volume.h"
#include "sink_slc.h"
#include "sink_states.h"
#include "sink_statemanager.h"
#include "sink_pio.h"

#include <stddef.h>
#include <csrtypes.h>
#include <audio.h>


#ifdef DEBUG_TONES
    #define TONE_DEBUG(x) DEBUG(x)
#else
    #define TONE_DEBUG(x) 
#endif

/****************************************************************************
VARIABLES      
*/
/***********************************************************************************/

/* Sink tones */

/****************************************************************/
/*
    SIMPLE TONES ( B - Q )
 */
/****************************************************************/

 
 /*Vol Min*/
static const ringtone_note tone_B[] =
{
    RINGTONE_TEMPO(200), RINGTONE_VOLUME(64), RINGTONE_TIMBRE(sine),
    
    RINGTONE_NOTE(G5,   CROTCHET), 
    
    RINGTONE_END
};
 /*Vol 2*/
static const ringtone_note tone_C[] =
{
    RINGTONE_TEMPO(2400), RINGTONE_VOLUME(64), RINGTONE_TIMBRE(sine),
    
    RINGTONE_NOTE(C6, SEMIBREVE), 
    
    RINGTONE_END
};
 /*Vol 3*/
static const ringtone_note tone_D[] =
{
    RINGTONE_TEMPO(2400), RINGTONE_VOLUME(64), RINGTONE_TIMBRE(sine),
    
    RINGTONE_NOTE(E6, SEMIBREVE), 
    
    RINGTONE_END
};
 /*Vol 4*/
static const ringtone_note tone_E[] =
{
    RINGTONE_TEMPO(2400), RINGTONE_VOLUME(64), RINGTONE_TIMBRE(sine),
    
    RINGTONE_NOTE(G6, SEMIBREVE), 
    
    RINGTONE_END
};
 /*Vol 5*/
static const ringtone_note tone_F[] =
{
    RINGTONE_TEMPO(2400), RINGTONE_VOLUME(64), RINGTONE_TIMBRE(sine),
    
    RINGTONE_NOTE(AS6, SEMIBREVE), 
    
    RINGTONE_END
};
 /*Vol 6*/
static const ringtone_note tone_G[] =
{
    RINGTONE_TEMPO(2400), RINGTONE_VOLUME(64), RINGTONE_TIMBRE(sine),
    
    RINGTONE_NOTE(C7, SEMIBREVE), 
    
    RINGTONE_END
};
 /*Vol 7*/
static const ringtone_note tone_H[] =
{
    RINGTONE_TEMPO(2400), RINGTONE_VOLUME(64), RINGTONE_TIMBRE(sine),
    
    RINGTONE_NOTE(D7, SEMIBREVE), 
    
    RINGTONE_END
};
 /*Vol 8*/
static const ringtone_note tone_I[] =
{
    RINGTONE_TEMPO(2400), RINGTONE_VOLUME(64), RINGTONE_TIMBRE(sine),
    
    RINGTONE_NOTE(E7, SEMIBREVE), 
    
    RINGTONE_END
};
 /*Vol 9*/
static const ringtone_note tone_J[] =
{
    RINGTONE_TEMPO(2400), RINGTONE_VOLUME(64), RINGTONE_TIMBRE(sine),
    
    RINGTONE_NOTE(FS7, SEMIBREVE), 
    
    RINGTONE_END
};
 /*Vol 10*/
static const ringtone_note tone_K[] =
{
    RINGTONE_TEMPO(200), RINGTONE_VOLUME(64), RINGTONE_TIMBRE(sine),
    
    RINGTONE_NOTE(GS7, CROTCHET), 
        
    RINGTONE_END
};


/*4 note rising scale*/
static const ringtone_note tone_L[] =
{
    RINGTONE_TEMPO(400), RINGTONE_VOLUME(64), RINGTONE_TIMBRE(sine),
    
    RINGTONE_NOTE(GS4, CROTCHET),
    RINGTONE_NOTE(REST,DEMISEMIQUAVER),
    RINGTONE_NOTE(DS5, CROTCHET),
    RINGTONE_NOTE(REST,DEMISEMIQUAVER),
    RINGTONE_NOTE(GS5, CROTCHET),
    RINGTONE_NOTE(REST,DEMISEMIQUAVER),
    RINGTONE_NOTE(C6, CROTCHET),
    
    RINGTONE_END
};
/*4 note falling scale*/
static const ringtone_note tone_M[] =
{
    RINGTONE_TEMPO(400), RINGTONE_VOLUME(64), RINGTONE_TIMBRE(sine),
    
    RINGTONE_NOTE(C6, CROTCHET),
    RINGTONE_NOTE(REST,DEMISEMIQUAVER),
    RINGTONE_NOTE(GS5, CROTCHET),
    RINGTONE_NOTE(REST,DEMISEMIQUAVER),
    RINGTONE_NOTE(DS5, CROTCHET),
    RINGTONE_NOTE(REST,DEMISEMIQUAVER),
    RINGTONE_NOTE(GS4, CROTCHET),
    
    RINGTONE_END
} ;
/*2 tone rising scale*/    
static const ringtone_note tone_N[] =
{
    RINGTONE_TEMPO(150), RINGTONE_VOLUME(64), RINGTONE_TIMBRE(sine),
    
    RINGTONE_NOTE(E6, QUAVER),
    RINGTONE_NOTE(REST,DEMISEMIQUAVER),
    RINGTONE_NOTE(A6, QUAVER),
    
    RINGTONE_END
};
/*2 tone falling scale*/
static const ringtone_note tone_O[] =
{
    RINGTONE_TEMPO(150), RINGTONE_VOLUME(64), RINGTONE_TIMBRE(sine),
    
    RINGTONE_NOTE(A6, QUAVER),
    RINGTONE_NOTE(REST,DEMISEMIQUAVER),
    RINGTONE_NOTE(E6, QUAVER),
    
    RINGTONE_END
};
/*long low followed by short high*/
static const ringtone_note tone_P[] =
{
    RINGTONE_TEMPO(600), RINGTONE_VOLUME(64), RINGTONE_TIMBRE(sine),
    
    RINGTONE_NOTE(REST, SEMIQUAVER),
    RINGTONE_NOTE(G5, SEMIBREVE),
    RINGTONE_NOTE(REST, SEMIQUAVER),
    RINGTONE_NOTE(G7, CROTCHET),
    
    RINGTONE_END
};
/*connection*/
static const ringtone_note tone_Q[] =
{
    RINGTONE_TEMPO(2400), RINGTONE_VOLUME(64), RINGTONE_TIMBRE(sine),
    
    RINGTONE_NOTE(REST, CROTCHET),
    RINGTONE_NOTE(GS7 , SEMIBREVE),
    
    RINGTONE_END
};

/*power*/
static const ringtone_note tone_R[] =
{
    RINGTONE_TEMPO(120), RINGTONE_VOLUME(64), RINGTONE_TIMBRE(sine),
    
    RINGTONE_NOTE(REST, HEMIDEMISEMIQUAVER),
    RINGTONE_NOTE(GS7 , CROTCHET),

    RINGTONE_END
};


/*error*/
static const ringtone_note tone_S[] =
{
    RINGTONE_TEMPO(120), RINGTONE_VOLUME(64), RINGTONE_TIMBRE(sine),
    
    RINGTONE_NOTE(REST, HEMIDEMISEMIQUAVER),
    RINGTONE_NOTE(G5 , CROTCHET),
    
    RINGTONE_END
};

/*short cfm*/
static const ringtone_note tone_T[] =
{
    RINGTONE_TEMPO(2400), RINGTONE_VOLUME(64), RINGTONE_TIMBRE(sine),
    
    RINGTONE_NOTE(REST, CROTCHET),
    RINGTONE_NOTE(G6 , SEMIBREVE),
    
    RINGTONE_END
};

/*long cfm*/
static const ringtone_note tone_U[] =
{
    RINGTONE_TEMPO(150), RINGTONE_VOLUME(64), RINGTONE_TIMBRE(sine),
    
    RINGTONE_NOTE(REST, HEMIDEMISEMIQUAVER),
    RINGTONE_NOTE(G6 , MINIM),
    
    RINGTONE_END
};


/*Batt Low*/
static const ringtone_note tone_V[] =
{
    RINGTONE_TEMPO(120), RINGTONE_VOLUME(64), RINGTONE_TIMBRE(sine),
    
    RINGTONE_NOTE(REST, HEMIDEMISEMIQUAVER),
    RINGTONE_NOTE(G6 , CROTCHET),
    
    RINGTONE_END
};

/*Pair removal*/
static const ringtone_note tone_W[] =
{
    RINGTONE_TEMPO(800), RINGTONE_VOLUME(64), RINGTONE_TIMBRE(sine),
    
    RINGTONE_NOTE(REST, QUAVER_TRIPLET),
    RINGTONE_NOTE(G5 , MINIM_TRIPLET),  
    RINGTONE_NOTE(REST, QUAVER),
    RINGTONE_NOTE(G5 , MINIM_TRIPLET),
    
    RINGTONE_END
};

/*Double*/
static const ringtone_note tone_X[] =
{
    RINGTONE_TEMPO(800), RINGTONE_VOLUME(64), RINGTONE_TIMBRE(sine),
    
    RINGTONE_NOTE(REST, QUAVER_TRIPLET),
    RINGTONE_NOTE(G6 , MINIM_TRIPLET),  
    RINGTONE_NOTE(REST, QUAVER),
    RINGTONE_NOTE(G6 , MINIM_TRIPLET),
    
    RINGTONE_END
};


  
/****************************************************************/
/*
    OTHER TONES
*/
/****************************************************************/


static const ringtone_note battery_low_tone[] =
{
    RINGTONE_TEMPO(240), RINGTONE_VOLUME(64), RINGTONE_TIMBRE(sine),
    
    RINGTONE_NOTE(E6, QUAVER),
    RINGTONE_NOTE(AS6, QUAVER),
    RINGTONE_NOTE(E6, QUAVER),
    RINGTONE_NOTE(AS6, QUAVER),
    RINGTONE_NOTE(E6, QUAVER),

    RINGTONE_END
};

static const ringtone_note low_500ms_tone[] =
{
    RINGTONE_TEMPO(600), RINGTONE_VOLUME(64), RINGTONE_TIMBRE(sine),
    RINGTONE_NOTE(REST, SEMIQUAVER),
    RINGTONE_TEMPO(120), RINGTONE_VOLUME(64), RINGTONE_TIMBRE(sine),
    RINGTONE_NOTE(G5, CROTCHET),
    RINGTONE_END
};

static const ringtone_note mute_reminder_tone[] =
{
    RINGTONE_TEMPO(600), RINGTONE_VOLUME(64), RINGTONE_TIMBRE(sine),
    RINGTONE_NOTE(REST, SEMIQUAVER),
    RINGTONE_TEMPO(120), RINGTONE_VOLUME(64), RINGTONE_TIMBRE(sine),
    RINGTONE_NOTE(G5, CROTCHET),
    RINGTONE_NOTE(REST, CROTCHET),
    RINGTONE_NOTE(G5, CROTCHET),
    RINGTONE_END
};


/****************************************************************/
/*
    RING TONES
*/
/****************************************************************/

static const ringtone_note ring_twilight[] =
{
    RINGTONE_TEMPO(180), RINGTONE_VOLUME(64), RINGTONE_TIMBRE(sine),
    
    RINGTONE_NOTE(E7, QUAVER),
    RINGTONE_NOTE(F7, QUAVER),
    RINGTONE_NOTE(E7, QUAVER),
    RINGTONE_NOTE(C7, QUAVER),
    RINGTONE_NOTE(E7, QUAVER),
    RINGTONE_NOTE(F7, QUAVER),
    RINGTONE_NOTE(E7, QUAVER),
    RINGTONE_NOTE(C7, QUAVER),

    RINGTONE_END
};




static const ringtone_note ring_g_s_t_q[] =
{
    RINGTONE_TEMPO(230), RINGTONE_VOLUME(64), RINGTONE_TIMBRE(sine),

    RINGTONE_NOTE  (G7, CROTCHET), 
    RINGTONE_NOTE  (G7, CROTCHET),
    RINGTONE_NOTE  (A7, CROTCHET),
    RINGTONE_NOTE  (FS7, CROTCHET),
    RINGTONE_NOTE_TIE (FS7, QUAVER),
    RINGTONE_NOTE  (G7, QUAVER),
    RINGTONE_NOTE  (A7, CROTCHET),
    RINGTONE_NOTE  (B7, CROTCHET),
    RINGTONE_NOTE  (B7, CROTCHET),
    RINGTONE_NOTE  (C8, CROTCHET),
    RINGTONE_NOTE  (B7, CROTCHET),
    RINGTONE_NOTE_TIE (B7, QUAVER),
    RINGTONE_NOTE  (A7, QUAVER),
    RINGTONE_NOTE  (G7, CROTCHET),
    RINGTONE_NOTE  (A7, CROTCHET),
    RINGTONE_NOTE  (G7, CROTCHET),
    RINGTONE_NOTE  (FS7, CROTCHET),
    RINGTONE_NOTE  (G7, MINIM),
    RINGTONE_NOTE_TIE (G7, CROTCHET), 

    RINGTONE_END 
};



static const ringtone_note ring_valkyries[] =
{
    RINGTONE_TEMPO(240), RINGTONE_VOLUME(64), RINGTONE_TIMBRE(sine),

    RINGTONE_NOTE(E5,QUAVER),                                    
    RINGTONE_NOTE_TIE(E5,SEMIQUAVER),                                                
    RINGTONE_NOTE(D5,SEMIQUAVER),                                
    RINGTONE_NOTE(E5,QUAVER),                                            
    RINGTONE_NOTE(G5,CROTCHET),                          
    RINGTONE_NOTE_TIE(G5,QUAVER),                                            
    RINGTONE_NOTE(E5,CROTCHET),                          
    RINGTONE_NOTE_TIE(E5,QUAVER),            
    RINGTONE_NOTE(G5,QUAVER),                                    
    RINGTONE_NOTE_TIE(G5,SEMIQUAVER),                                                
    RINGTONE_NOTE(F5,SEMIQUAVER),                                
    RINGTONE_NOTE(G5,QUAVER),                                            
    RINGTONE_NOTE(B5,CROTCHET),                          
    RINGTONE_NOTE_TIE(B5,QUAVER),                                            
    RINGTONE_NOTE(G5,CROTCHET),                          
    RINGTONE_NOTE_TIE(G5,QUAVER),
       
    RINGTONE_END
};


static const ringtone_note ring_greensleeves[] =
{
    RINGTONE_TEMPO(400), RINGTONE_VOLUME(64), RINGTONE_TIMBRE(sine),
              
    RINGTONE_NOTE(F6,CROTCHET),                                  
    RINGTONE_NOTE(AF6,MINIM),                                            
    RINGTONE_NOTE(BF6,CROTCHET),                         
    RINGTONE_NOTE(C7,CROTCHET),                          
    RINGTONE_NOTE_TIE(C7,QUAVER),                                            
    RINGTONE_NOTE(DF7,QUAVER),                           
    RINGTONE_NOTE(C7,CROTCHET),                                          
    RINGTONE_NOTE(BF6,MINIM),                            
    RINGTONE_NOTE(G6,CROTCHET),          
    RINGTONE_NOTE(EF6,CROTCHET), 
    RINGTONE_NOTE_TIE(EF6,QUAVER),
       
    RINGTONE_END
};



static const ringtone_note ring_two_beeps[] =
{
    RINGTONE_TEMPO(300), RINGTONE_VOLUME(64), RINGTONE_TIMBRE(sine),                

    RINGTONE_NOTE(B5,SEMIQUAVER),                                    
    RINGTONE_NOTE(G5,SEMIQUAVER),                                    
    RINGTONE_NOTE(B5,SEMIQUAVER),                                    
    RINGTONE_NOTE(G5,SEMIQUAVER),                                    
    RINGTONE_NOTE(B5,SEMIQUAVER),                                    
    RINGTONE_NOTE(REST,QUAVER),                                    
    RINGTONE_NOTE(B5,SEMIQUAVER),                                    
    RINGTONE_NOTE(G5,SEMIQUAVER),                                    
    RINGTONE_NOTE(B5,SEMIQUAVER),                                    
    RINGTONE_NOTE(G5,SEMIQUAVER),                                    
    RINGTONE_NOTE(B5,SEMIQUAVER),                                    

    RINGTONE_END
};




static const ringtone_note ring_fairground[] =
{
    RINGTONE_TEMPO(300), RINGTONE_VOLUME(64), RINGTONE_TIMBRE(sine),            

    RINGTONE_NOTE(E6,CROTCHET),                                  
    RINGTONE_NOTE(D6,CROTCHET),                                          
    RINGTONE_NOTE(DF6,QUAVER),                           
    RINGTONE_NOTE(D6,QUAVER),                            
    RINGTONE_NOTE(DF6,QUAVER),                                           
    RINGTONE_NOTE(C6,QUAVER),                            
    RINGTONE_NOTE(DF6,CROTCHET),                                         
    RINGTONE_NOTE(C6,CROTCHET),                          
    RINGTONE_NOTE(B5,CROTCHET),          
    RINGTONE_NOTE(C6,CROTCHET),  
      
    RINGTONE_END
};



static const ringtone_note ring_counterpoint[] =
{
    RINGTONE_TEMPO(400), RINGTONE_VOLUME(64), RINGTONE_TIMBRE(sine),

    RINGTONE_NOTE(E6,CROTCHET),                                  
    RINGTONE_NOTE(D6,CROTCHET),                                          
    RINGTONE_NOTE(E6,CROTCHET),                          
    RINGTONE_NOTE(DF6,CROTCHET),                         
    RINGTONE_NOTE(E6,CROTCHET),                                          
    RINGTONE_NOTE(C6,CROTCHET),                          
    RINGTONE_NOTE(E6,CROTCHET),  
    RINGTONE_NOTE(B5,CROTCHET),                                          

    RINGTONE_END
};


static const ringtone_note ring_major_arp[] =
{
    RINGTONE_TEMPO(220), RINGTONE_VOLUME(64), RINGTONE_TIMBRE(sine),

    RINGTONE_NOTE(E5,QUAVER),                                    
    RINGTONE_NOTE(AF5,QUAVER),                                           
    RINGTONE_NOTE(B5,QUAVER),                            
    RINGTONE_NOTE(E6,QUAVER),                            
    RINGTONE_NOTE(GS6,QUAVER),                                           
    RINGTONE_NOTE(B6,QUAVER),                            
    RINGTONE_NOTE(E7,QUAVER),                                            

    RINGTONE_END
};


static const ringtone_note ring_major_scale[] =
{
    RINGTONE_TEMPO(300), RINGTONE_VOLUME(64), RINGTONE_TIMBRE(sine),

    RINGTONE_NOTE(E6,QUAVER),                                    
    RINGTONE_NOTE(FS6,QUAVER),                                           
    RINGTONE_NOTE(GS6,QUAVER),                           
    RINGTONE_NOTE(A6,QUAVER),                            
    RINGTONE_NOTE(B6,QUAVER),                                            
    RINGTONE_NOTE(CS7,QUAVER),                           
    RINGTONE_NOTE(DS7,QUAVER),                                           
    RINGTONE_NOTE(E7,QUAVER),    

    RINGTONE_END
};

static const ringtone_note ring_minor_arp[] =
{
    RINGTONE_TEMPO(220), RINGTONE_VOLUME(64), RINGTONE_TIMBRE(sine),
    
    RINGTONE_NOTE(E5,QUAVER),                                    
    RINGTONE_NOTE(G5,QUAVER),                                            
    RINGTONE_NOTE(B5,QUAVER),                            
    RINGTONE_NOTE(E6,QUAVER),                            
    RINGTONE_NOTE(G6,QUAVER),                                            
    RINGTONE_NOTE(B6,QUAVER),                            
    RINGTONE_NOTE(E7,QUAVER),                                            

    RINGTONE_END
};




static const ringtone_note ring_harmonic_minor_scale[] =
{
    RINGTONE_TEMPO(300), RINGTONE_VOLUME(64), RINGTONE_TIMBRE(sine),

    RINGTONE_NOTE(E5,QUAVER),                                    
    RINGTONE_NOTE(FS5,QUAVER),                                           
    RINGTONE_NOTE(G5,QUAVER),                            
    RINGTONE_NOTE(A5,QUAVER),                            
    RINGTONE_NOTE(B5,QUAVER),                                            
    RINGTONE_NOTE(C6,QUAVER),                            
    RINGTONE_NOTE(DS6,QUAVER),                                           
    RINGTONE_NOTE(E6,QUAVER),                            
    
    RINGTONE_END
};



static const ringtone_note ring_more_than_a_feeling[] =
{
    RINGTONE_TEMPO(200), RINGTONE_VOLUME(64), RINGTONE_TIMBRE(sine),

    RINGTONE_NOTE(D6,QUAVER),                                    
    RINGTONE_NOTE(A6,QUAVER),                                            
    RINGTONE_NOTE(D7,QUAVER),                            
    RINGTONE_NOTE(G7,CROTCHET),                          
    RINGTONE_NOTE(A6,QUAVER),                            
    RINGTONE_NOTE(FS7,CROTCHET),                                         

    RINGTONE_END
};




static const ringtone_note ring_eight_beeps[] =
{
    RINGTONE_TEMPO(200), RINGTONE_VOLUME(64), RINGTONE_TIMBRE(sine),

    RINGTONE_NOTE(B5,QUAVER),                                    
    RINGTONE_NOTE(B5,QUAVER),                    
    RINGTONE_NOTE(B5,QUAVER),
    RINGTONE_NOTE(B5,QUAVER),
    RINGTONE_NOTE(B5,QUAVER),                                    
    RINGTONE_NOTE(B5,QUAVER),                    
    RINGTONE_NOTE(B5,QUAVER),
    RINGTONE_NOTE(B5,QUAVER),

    RINGTONE_END
};



static const ringtone_note ring_four_beeps[] =
{
    RINGTONE_TEMPO(180), RINGTONE_VOLUME(64), RINGTONE_TIMBRE(sine),
           
    RINGTONE_NOTE(B5,QUAVER),                                    
    RINGTONE_NOTE(B5,QUAVER),                    
    RINGTONE_NOTE(B5,QUAVER),
    RINGTONE_NOTE(B5,QUAVER),    

    RINGTONE_END
};




static const ringtone_note ring_bumble_bee[] =
{
    RINGTONE_TEMPO(70), RINGTONE_VOLUME(64), RINGTONE_TIMBRE(sine),

    RINGTONE_NOTE(E7,DEMISEMIQUAVER),                                    

    RINGTONE_NOTE(EF7,DEMISEMIQUAVER),                                           

    RINGTONE_NOTE(D7,DEMISEMIQUAVER),                            

    RINGTONE_NOTE(DF7,DEMISEMIQUAVER),                           

    RINGTONE_NOTE(EF7,DEMISEMIQUAVER),                                           

    RINGTONE_NOTE(D7,DEMISEMIQUAVER),                            

    RINGTONE_NOTE(DF7,DEMISEMIQUAVER),                                           

    RINGTONE_NOTE(C7,DEMISEMIQUAVER),                            

    RINGTONE_NOTE(D7,DEMISEMIQUAVER),            

    RINGTONE_NOTE(DF7,DEMISEMIQUAVER),   

    RINGTONE_NOTE(C7,DEMISEMIQUAVER),

    RINGTONE_NOTE(B6,DEMISEMIQUAVER),                                            

    RINGTONE_NOTE(DF7,DEMISEMIQUAVER),                           

    RINGTONE_NOTE(C7,DEMISEMIQUAVER),            

    RINGTONE_NOTE(B6,DEMISEMIQUAVER),    

    RINGTONE_NOTE(BF6,DEMISEMIQUAVER),  

    RINGTONE_END
};


static const ringtone_note ring_aug_scale[] =
{
    RINGTONE_TEMPO(280), RINGTONE_VOLUME(64), RINGTONE_TIMBRE(sine),

    RINGTONE_NOTE(E6,CROTCHET),                                  
    RINGTONE_NOTE(CS7,CROTCHET),                                         
    RINGTONE_NOTE(F7,CROTCHET),                          
    RINGTONE_NOTE(A7,CROTCHET),                          
    
    RINGTONE_END
};



static const ringtone_note ring_dim_scale[] =
{
    RINGTONE_TEMPO(280), RINGTONE_VOLUME(64), RINGTONE_TIMBRE(sine),

    RINGTONE_NOTE(E6,CROTCHET),                                  
    RINGTONE_NOTE(G6,CROTCHET),                                          
    RINGTONE_NOTE(AS6,CROTCHET),                         
    RINGTONE_NOTE(DF7,CROTCHET),                         
       
    RINGTONE_END
};


static const ringtone_note CustomRingTone[] =
{
    /* A sample custom ring tone */
    RINGTONE_TEMPO(280), RINGTONE_VOLUME(64), RINGTONE_TIMBRE(sine),
    RINGTONE_NOTE(E6,CROTCHET),                                  
    RINGTONE_NOTE(G6,CROTCHET),                                          
    RINGTONE_NOTE(AS6,CROTCHET),                         
    RINGTONE_NOTE(DF7,CROTCHET),                         
    RINGTONE_END
};

/**********************************************************************/

/*4 low to high 38ms*/
static const ringtone_note tone_A1[] =
{
    RINGTONE_TEMPO(1600), RINGTONE_VOLUME(64), RINGTONE_TIMBRE(sine),
    
    RINGTONE_NOTE(G5 , CROTCHET),
    RINGTONE_NOTE(D6 , CROTCHET),
    RINGTONE_NOTE(G6 , CROTCHET),
    RINGTONE_NOTE(B5 , CROTCHET),

    RINGTONE_END
};
/*4 high to low 38ms*/
static const ringtone_note tone_A2[] =
{
    RINGTONE_TEMPO(1600), RINGTONE_VOLUME(64), RINGTONE_TIMBRE(sine),
    
    RINGTONE_NOTE(B5 , CROTCHET),
    RINGTONE_NOTE(G6 , CROTCHET),
    RINGTONE_NOTE(D6 , CROTCHET),
    RINGTONE_NOTE(G5 , CROTCHET),

    RINGTONE_END
};

/*short high low 25ms**/
/*no-network-service tone - 880 Hz for 100ms*/
static const ringtone_note tone_A3[] =
{
    RINGTONE_TEMPO(600), RINGTONE_VOLUME(64), RINGTONE_TIMBRE(sine),
    RINGTONE_NOTE(B5, CROTCHET),

    RINGTONE_END
};

/*series of 5 high tones 94 ms*/
static const ringtone_note tone_A4[] =
{
    RINGTONE_TEMPO(640), RINGTONE_VOLUME(64), RINGTONE_TIMBRE(sine),
    
    RINGTONE_NOTE(B6 , CROTCHET),
    RINGTONE_NOTE(B6 , CROTCHET),
    RINGTONE_NOTE(B6 , CROTCHET),
    RINGTONE_NOTE(B6 , CROTCHET),
    RINGTONE_NOTE(B6 , CROTCHET),
    
    RINGTONE_END
};

/*low to high 100ms tones 50ms pause*/
static const ringtone_note tone_A5[] =
{
    RINGTONE_TEMPO(600), RINGTONE_VOLUME(64), RINGTONE_TIMBRE(sine),
    
    RINGTONE_NOTE(DS7  , CROTCHET),
    RINGTONE_NOTE(REST , QUAVER),
    RINGTONE_NOTE(G7   , CROTCHET),
    
    RINGTONE_END
};

/*high to low 100ms tones 50ms pause*/
static const ringtone_note tone_A6[] =
{
    RINGTONE_TEMPO(600), RINGTONE_VOLUME(64), RINGTONE_TIMBRE(sine),
    
    RINGTONE_NOTE(G7   , CROTCHET),
    RINGTONE_NOTE(REST , QUAVER),
    RINGTONE_NOTE(DS7  , CROTCHET),
    
    RINGTONE_END
};

/***************************************************************************/
/*S-Tones*/
    /*short v high 2400hz*/
static const ringtone_note tone_S1[] =
{
    RINGTONE_TEMPO(1200), RINGTONE_VOLUME(64), RINGTONE_TIMBRE(sine),
    
    RINGTONE_NOTE(DS8   , CROTCHET),
    
    RINGTONE_END
};

/*series(12) of high / higher beeps*/
static const ringtone_note tone_S2[] =
{
    RINGTONE_TEMPO(1200), RINGTONE_VOLUME(64), RINGTONE_TIMBRE(sine),
    
    RINGTONE_NOTE(B6   , CROTCHET),
    RINGTONE_NOTE(G8   , CROTCHET),    
    RINGTONE_NOTE(B6   , CROTCHET),
    RINGTONE_NOTE(G8   , CROTCHET),
    RINGTONE_NOTE(B6   , CROTCHET),
    RINGTONE_NOTE(G8   , CROTCHET),
    RINGTONE_NOTE(B6   , CROTCHET),
    RINGTONE_NOTE(G8   , CROTCHET),
    RINGTONE_NOTE(B6   , CROTCHET),
    RINGTONE_NOTE(G8   , CROTCHET),
    RINGTONE_NOTE(B6   , CROTCHET),
    RINGTONE_NOTE(G8   , CROTCHET),
        
    RINGTONE_END
};
    /*short middle (987)  */
static const ringtone_note tone_S3[] =
{
    RINGTONE_TEMPO(1200), RINGTONE_VOLUME(64), RINGTONE_TIMBRE(sine),
    
    RINGTONE_NOTE(B6  , CROTCHET),
    
    RINGTONE_END
};

    /*series of 5 high beeps with pause*/
static const ringtone_note tone_S4[] =
{
    RINGTONE_TEMPO(1200), RINGTONE_VOLUME(64), RINGTONE_TIMBRE(sine),
    
    RINGTONE_NOTE(C6  , CROTCHET),
    RINGTONE_NOTE(REST  , CROTCHET),

    RINGTONE_NOTE(C6  , CROTCHET),
    RINGTONE_NOTE(REST  , CROTCHET),

    RINGTONE_NOTE(C6  , CROTCHET),
    RINGTONE_NOTE(REST  , CROTCHET),

    RINGTONE_NOTE(C6  , CROTCHET),
    RINGTONE_NOTE(REST  , CROTCHET),

    RINGTONE_NOTE(C6  , CROTCHET),
    RINGTONE_NOTE(REST  , CROTCHET),
    
    
    RINGTONE_END
};

    /*Low / High beep  */
static const ringtone_note tone_S5[] =
{
    RINGTONE_TEMPO(1200), RINGTONE_VOLUME(64), RINGTONE_TIMBRE(sine),
    
    RINGTONE_NOTE(B6  , CROTCHET),
    RINGTONE_NOTE(REST  , CROTCHET),
    RINGTONE_NOTE(DS8  , CROTCHET),
    
    RINGTONE_END
};
    /* High / Low beep  */
static const ringtone_note tone_S6[] =
{
    RINGTONE_TEMPO(1200), RINGTONE_VOLUME(64), RINGTONE_TIMBRE(sine),
    
    RINGTONE_NOTE(DS8  , CROTCHET),
    RINGTONE_NOTE(REST  , CROTCHET),
    RINGTONE_NOTE(B6  , CROTCHET),
    
    RINGTONE_END
};
/***************************************************************/
/*New tones for Q2 2007*/

/*Short Middle Tone, 100ms D6*/	
static const ringtone_note tone_Q21[] =
{
    RINGTONE_TEMPO(400), RINGTONE_VOLUME(64), RINGTONE_TIMBRE(sine),
    
    RINGTONE_NOTE(REST  , SEMIQUAVER_TRIPLET),
    RINGTONE_NOTE(D6  , MINIM),
    
    RINGTONE_END
};
/*4 Low to High Long at Top, 100ms G5 D6 G6 300ms B6 */
static const ringtone_note tone_Q22[] =
{
    RINGTONE_TEMPO(400), RINGTONE_VOLUME(64), RINGTONE_TIMBRE(sine),
    
    RINGTONE_NOTE(REST  , SEMIQUAVER_TRIPLET),
    RINGTONE_NOTE(G5  , CROTCHET_TRIPLET),
	RINGTONE_NOTE(REST  , SEMIQUAVER_TRIPLET),
	RINGTONE_NOTE(D6  , CROTCHET_TRIPLET),
	RINGTONE_NOTE(REST  , SEMIQUAVER_TRIPLET),
	RINGTONE_NOTE(G6  , CROTCHET_TRIPLET),
	RINGTONE_NOTE(REST  , SEMIQUAVER_TRIPLET),
	RINGTONE_NOTE(B6  , MINIM),
    
    RINGTONE_END
};

/*4 High to Low Long at Bottom, 100ms B6 G6 D6 300ms G5 */ 		
static const ringtone_note tone_Q23[] =
{
    RINGTONE_TEMPO(400), RINGTONE_VOLUME(64), RINGTONE_TIMBRE(sine),
    
    RINGTONE_NOTE(REST  , SEMIQUAVER_TRIPLET),
    RINGTONE_NOTE(B6  , CROTCHET_TRIPLET),
	RINGTONE_NOTE(REST  , SEMIQUAVER_TRIPLET),
	RINGTONE_NOTE(G6  , CROTCHET_TRIPLET),
	RINGTONE_NOTE(REST  , SEMIQUAVER_TRIPLET),
	RINGTONE_NOTE(D6  , CROTCHET_TRIPLET),
	RINGTONE_NOTE(REST  , SEMIQUAVER_TRIPLET),
	RINGTONE_NOTE(G5  , MINIM),
    
    RINGTONE_END
};

/*3 Note Descending, 300ms G6 D6 G5*/	
static const ringtone_note tone_Q24[] =
{
    RINGTONE_TEMPO(400), RINGTONE_VOLUME(64), RINGTONE_TIMBRE(sine),
    
    RINGTONE_NOTE(REST  , SEMIQUAVER_TRIPLET),
    RINGTONE_NOTE(G6  , MINIM),
	RINGTONE_NOTE(REST  , SEMIQUAVER_TRIPLET),
	RINGTONE_NOTE(D6  , MINIM),
	RINGTONE_NOTE(REST  , SEMIQUAVER_TRIPLET),
	RINGTONE_NOTE(G5  , MINIM),
	
    
    RINGTONE_END
};

/*5th Down Medium-Long, 300ms D6 500ms G5*/
static const ringtone_note tone_Q25[] =
{
    RINGTONE_TEMPO(200), RINGTONE_VOLUME(64), RINGTONE_TIMBRE(sine),
    
    RINGTONE_NOTE(REST  , DEMISEMIQUAVER_TRIPLET),
    RINGTONE_NOTE(D6  , CROTCHET),
	RINGTONE_NOTE(REST  , DEMISEMIQUAVER_TRIPLET),
	RINGTONE_NOTE(G5  , MINIM_TRIPLET),
	RINGTONE_NOTE_TIE(G5  , QUAVER_TRIPLET),
    
    RINGTONE_END
};

/*5th Down Short-Short, 100ms D6 G5*/	
static const ringtone_note tone_Q26[] =
{
    RINGTONE_TEMPO(2400), RINGTONE_VOLUME(64), RINGTONE_TIMBRE(sine),
    
    RINGTONE_NOTE(REST  , CROTCHET),
    RINGTONE_NOTE(D6  , SEMIBREVE),
	RINGTONE_NOTE(REST  , CROTCHET),
	RINGTONE_NOTE(G5  , SEMIBREVE),
    
    RINGTONE_END
};

/*5th Up Short-Short, 100ms G5 D6*/
static const ringtone_note tone_Q27[] =
{
    RINGTONE_TEMPO(2400), RINGTONE_VOLUME(64), RINGTONE_TIMBRE(sine),
    
    RINGTONE_NOTE(REST  , CROTCHET),
    RINGTONE_NOTE(G5  , SEMIBREVE),
	RINGTONE_NOTE(REST  , CROTCHET),
	RINGTONE_NOTE(D6  , SEMIBREVE),
    
    RINGTONE_END
};

/*2 Half Second Low Tones, 500ms G5 REST G5*/
static const ringtone_note tone_Q28[] =
{
    RINGTONE_TEMPO(480), RINGTONE_VOLUME(64), RINGTONE_TIMBRE(sine),
    
    RINGTONE_NOTE(REST  , SEMIQUAVER_TRIPLET),
    RINGTONE_NOTE(G5  , SEMIBREVE),
	RINGTONE_NOTE(REST  , QUAVER_TRIPLET),
	RINGTONE_NOTE(G5  , SEMIBREVE),
    
    RINGTONE_END
};

/*Short High Tone, 100ms G7*/
static const ringtone_note tone_Q29[] =
{
    RINGTONE_TEMPO(2400), RINGTONE_VOLUME(64), RINGTONE_TIMBRE(sine),
    
    RINGTONE_NOTE(REST  , CROTCHET),
    RINGTONE_NOTE(G7  , SEMIBREVE),
    
    RINGTONE_END
};

/*Long Low Tone, 400ms G5*/
static const ringtone_note tone_Q2A[] =
{
    RINGTONE_TEMPO(600), RINGTONE_VOLUME(64), RINGTONE_TIMBRE(sine),
    
    RINGTONE_NOTE(REST  , SEMIQUAVER),
    RINGTONE_NOTE(G5  , SEMIBREVE),
    
    RINGTONE_END
};

/*Double Low Tones, 200ms G5 REST G5*/
static const ringtone_note tone_Q2B[] =
{
    RINGTONE_TEMPO(600), RINGTONE_VOLUME(64), RINGTONE_TIMBRE(sine),
    
    RINGTONE_NOTE(REST  , SEMIQUAVER),
    RINGTONE_NOTE(G5  , MINIM),
	RINGTONE_NOTE(REST  , CROTCHET),
    RINGTONE_NOTE(G5  , MINIM),
    
    RINGTONE_END
};

/*G Major Arp Up, 125ms G6 B6 D7 G7*/	

static const ringtone_note tone_Q2C[] =
{
    RINGTONE_TEMPO(600), RINGTONE_VOLUME(64), RINGTONE_TIMBRE(sine),
    
    RINGTONE_NOTE(REST  , SEMIQUAVER),
    RINGTONE_NOTE(G6  , MINIM_TRIPLET),
    RINGTONE_NOTE(B6  , MINIM_TRIPLET),
	RINGTONE_NOTE(D7  , MINIM_TRIPLET),
	RINGTONE_NOTE(G7  , MINIM_TRIPLET),
    
    RINGTONE_END
};

/*G Major Arp Down, 125ms G7 D7 B6 G6*/	

static const ringtone_note tone_Q2D[] =
{
    RINGTONE_TEMPO(600), RINGTONE_VOLUME(64), RINGTONE_TIMBRE(sine),
    
    RINGTONE_NOTE(REST  , SEMIQUAVER),
    RINGTONE_NOTE(G7  , MINIM_TRIPLET),
    RINGTONE_NOTE(D7  , MINIM_TRIPLET),
	RINGTONE_NOTE(B6  , MINIM_TRIPLET),
	RINGTONE_NOTE(G6  , MINIM_TRIPLET),
    
    RINGTONE_END
};

/*Fairly Short High Tone, 150ms G7*/
static const ringtone_note tone_Q2E[] =
{
    RINGTONE_TEMPO(800), RINGTONE_VOLUME(64), RINGTONE_TIMBRE(sine),
    
    RINGTONE_NOTE(REST  , QUAVER_TRIPLET),
    RINGTONE_NOTE(G7  , MINIM),
    
    RINGTONE_END
};

/*Fairly Short Low Tone, 150ms G5*/
static const ringtone_note tone_Q2F[] =
{
    RINGTONE_TEMPO(800), RINGTONE_VOLUME(64), RINGTONE_TIMBRE(sine),
    
    RINGTONE_NOTE(REST  , QUAVER_TRIPLET),
    RINGTONE_NOTE(G5  , MINIM),
    
    RINGTONE_END
};

/*Medium Length Low Tone, 200ms G5*/	
static const ringtone_note tone_Q210[] =
{
    RINGTONE_TEMPO(300), RINGTONE_VOLUME(64), RINGTONE_TIMBRE(sine),
    
    RINGTONE_NOTE(REST  , DEMISEMIQUAVER),
    RINGTONE_NOTE(G5  , CROTCHET),
    
    RINGTONE_END
};


  /*Short Low-High, 80ms G5 G7*/		
static const ringtone_note tone_Q211[] =
{
    RINGTONE_TEMPO(300), RINGTONE_VOLUME(64), RINGTONE_TIMBRE(sine),
    
    RINGTONE_NOTE(REST  , MINIM_TRIPLET),
    RINGTONE_NOTE(G5  , SEMIBREVE),
	RINGTONE_NOTE(REST  , SEMIBREVE),
    RINGTONE_NOTE(G7  , SEMIBREVE),
	
    RINGTONE_END
};

/*Double Octave Toggle Ring Tone, 50ms G7 G5 G7 G5 G7 G5 Repeat after 250ms*/
static const ringtone_note tone_Q212[] =
{
    RINGTONE_TEMPO(100), RINGTONE_VOLUME(64), RINGTONE_TIMBRE(sine),
    
    RINGTONE_NOTE(REST  , HEMIDEMISEMIQUAVER_TRIPLET),
	RINGTONE_NOTE(G7  , DEMISEMIQUAVER_TRIPLET  ),
	RINGTONE_NOTE(G5  , DEMISEMIQUAVER_TRIPLET  ),
    RINGTONE_NOTE(G7  , DEMISEMIQUAVER_TRIPLET  ),
	RINGTONE_NOTE(G5  , DEMISEMIQUAVER_TRIPLET  ),
    RINGTONE_NOTE(G7  , DEMISEMIQUAVER_TRIPLET  ),
	RINGTONE_NOTE(G5  , DEMISEMIQUAVER_TRIPLET  ),
	RINGTONE_NOTE(REST  , SEMIQUAVER  ),
	RINGTONE_NOTE_TIE(REST , SEMIQUAVER_TRIPLET),
	RINGTONE_NOTE(G7  , DEMISEMIQUAVER_TRIPLET  ),
	RINGTONE_NOTE(G5  , DEMISEMIQUAVER_TRIPLET  ),
    RINGTONE_NOTE(G7  , DEMISEMIQUAVER_TRIPLET  ),
	RINGTONE_NOTE(G5  , DEMISEMIQUAVER_TRIPLET  ),
    RINGTONE_NOTE(G7  , DEMISEMIQUAVER_TRIPLET  ),
	RINGTONE_NOTE(G5  , DEMISEMIQUAVER_TRIPLET  ),
	
    RINGTONE_END
};


/*Low Low High, 100ms G5 G5 G7*/	
static const ringtone_note tone_Q213[] =
{
    RINGTONE_TEMPO(2400), RINGTONE_VOLUME(64), RINGTONE_TIMBRE(sine),
    
    RINGTONE_NOTE(REST  , CROTCHET),
    RINGTONE_NOTE(G5  , SEMIBREVE),
	RINGTONE_NOTE(G5  , SEMIBREVE),
    RINGTONE_NOTE(G7  , SEMIBREVE),
	
    RINGTONE_END
};

/*Double Low Tones (long), 300ms G5 G5*/	
static const ringtone_note tone_Q214[] =
{
    RINGTONE_TEMPO(800), RINGTONE_VOLUME(64), RINGTONE_TIMBRE(sine),
    
    RINGTONE_NOTE(REST, CROTCHET),
    RINGTONE_NOTE(G6 , SEMIBREVE),  
    RINGTONE_NOTE(REST, MINIM_TRIPLET),
    RINGTONE_NOTE(G6 , SEMIBREVE),
    
    RINGTONE_END
};

/*Connected 48mS C6 D6 A6 */		
static const ringtone_note tone_Q31[] =
{
    RINGTONE_TEMPO(1200), RINGTONE_VOLUME(64), RINGTONE_TIMBRE(sine),
    
    RINGTONE_NOTE(C6, CROTCHET),
    RINGTONE_NOTE(D6, CROTCHET),  
    RINGTONE_NOTE(A6, CROTCHET),
    
    RINGTONE_END
};

/*Connected 48mS A6 D6 C6 */		
static const ringtone_note tone_Q32[] =
{
    RINGTONE_TEMPO(1200), RINGTONE_VOLUME(64), RINGTONE_TIMBRE(sine),
    
    RINGTONE_NOTE(A6, CROTCHET),
    RINGTONE_NOTE(D6, CROTCHET),  
    RINGTONE_NOTE(C6, CROTCHET),
    
    RINGTONE_END
};

/*confirmation tone 68mS C5 E5  */		
static const ringtone_note tone_Q33[] =
{
    RINGTONE_TEMPO(800), RINGTONE_VOLUME(64), RINGTONE_TIMBRE(sine),
    
    RINGTONE_NOTE(C5, CROTCHET),
    RINGTONE_NOTE(E5, CROTCHET),  
    
    RINGTONE_END
};

/*error tone 2 68mS A5 REST A5 */		
static const ringtone_note tone_Q34[] =
{
    RINGTONE_TEMPO(800), RINGTONE_VOLUME(64), RINGTONE_TIMBRE(sine),
    
    RINGTONE_NOTE(A5, CROTCHET),
    RINGTONE_NOTE(REST, CROTCHET),  
    RINGTONE_NOTE(A5, CROTCHET),  
    
    RINGTONE_END
};

/*low batt 2 125mS E6 F5 */		
static const ringtone_note tone_Q35[] =
{
    RINGTONE_TEMPO(480), RINGTONE_VOLUME(64), RINGTONE_TIMBRE(sine),
    
    RINGTONE_NOTE(E6, CROTCHET),
    RINGTONE_NOTE(F5, CROTCHET),  
    
    RINGTONE_END
};

/*mute off 2 48mS A5 A4 */		
static const ringtone_note tone_Q36[] =
{
    RINGTONE_TEMPO(1200), RINGTONE_VOLUME(64), RINGTONE_TIMBRE(sine),
    
    RINGTONE_NOTE(A5, CROTCHET),
    RINGTONE_NOTE(A4, CROTCHET),  
    
    RINGTONE_END
};
         
/*mute on 2 48mS A4 A5 */		
static const ringtone_note tone_Q37[] =
{
    RINGTONE_TEMPO(1200), RINGTONE_VOLUME(64), RINGTONE_TIMBRE(sine),
    
    RINGTONE_NOTE(A4, CROTCHET),
    RINGTONE_NOTE(A5, CROTCHET),  
    
    RINGTONE_END
};

/*single tone 2 48mS A5 */		
static const ringtone_note tone_Q38[] =
{
    RINGTONE_TEMPO(1200), RINGTONE_VOLUME(64), RINGTONE_TIMBRE(sine),
    
    RINGTONE_NOTE(A5, CROTCHET),  
    
    RINGTONE_END
};

/*shutdown tone 2 408mS A5, 136mS A4  */		
static const ringtone_note tone_Q39[] =
{
    RINGTONE_TEMPO(300), RINGTONE_VOLUME(64), RINGTONE_TIMBRE(sine),
    
    RINGTONE_NOTE(A5, MINIM),  
    RINGTONE_NOTE(A4, CROTCHET),  
    
    RINGTONE_END
};

/*phone ring 48mS C6 E6 C6 E6 C6 E6 C6 E6 C6 E6 C6 REST C6 E6 C6 E6 C6 E6 C6 E6 C6 E6 C6 */		
static const ringtone_note tone_Q3A[] =
{
    RINGTONE_TEMPO(1200), RINGTONE_VOLUME(64), RINGTONE_TIMBRE(sine),
    
    RINGTONE_NOTE(C6, CROTCHET),  
    RINGTONE_NOTE(E6, CROTCHET),  
    RINGTONE_NOTE(C6, CROTCHET),  
    RINGTONE_NOTE(E6, CROTCHET),  
    RINGTONE_NOTE(C6, CROTCHET),  
    RINGTONE_NOTE(E6, CROTCHET),  
    RINGTONE_NOTE(C6, CROTCHET),  
    RINGTONE_NOTE(E6, CROTCHET),  
    RINGTONE_NOTE(C6, CROTCHET),  
    RINGTONE_NOTE(E6, CROTCHET),  
    RINGTONE_NOTE(C6, CROTCHET),  
    RINGTONE_NOTE(REST, CROTCHET),  
    RINGTONE_NOTE(C6, CROTCHET),  
    RINGTONE_NOTE(E6, CROTCHET),  
    RINGTONE_NOTE(C6, CROTCHET),  
    RINGTONE_NOTE(E6, CROTCHET),  
    RINGTONE_NOTE(C6, CROTCHET),  
    RINGTONE_NOTE(E6, CROTCHET),  
    RINGTONE_NOTE(C6, CROTCHET),  
    RINGTONE_NOTE(E6, CROTCHET),  
    RINGTONE_NOTE(C6, CROTCHET),  
    RINGTONE_NOTE(E6, CROTCHET),  
    RINGTONE_NOTE(C6, CROTCHET),  

    RINGTONE_END
};
         
/*power up tone 83mS C5 10mS REST 83mS E5 10mS REST 83mS G5 10mS REST 124mS B5 498mS REST 372mS C6 */   
static const ringtone_note tone_Q3B[] =
{
    RINGTONE_TEMPO(400), RINGTONE_VOLUME(64), RINGTONE_TIMBRE(sine),
    
    RINGTONE_NOTE(C5   , QUAVER),  
    RINGTONE_NOTE(REST , DEMISEMIQUAVER),  
    RINGTONE_NOTE(E5   , QUAVER),  
    RINGTONE_NOTE(REST , DEMISEMIQUAVER),  
    RINGTONE_NOTE(G5   , QUAVER),  
    RINGTONE_NOTE(REST , DEMISEMIQUAVER),  
    RINGTONE_NOTE(B5   , CROTCHET),  
    RINGTONE_NOTE(REST , SEMIBREVE),  
    RINGTONE_NOTE(C6   , MINIM),  
    RINGTONE_NOTE_TIE(C6, QUAVER),  

    RINGTONE_END
};

/*vol 7/0 68mS A5 REST A5*/   
static const ringtone_note tone_Q3C[] =
{
    RINGTONE_TEMPO(800), RINGTONE_VOLUME(64), RINGTONE_TIMBRE(sine),
    
    RINGTONE_NOTE(A5   , CROTCHET),  
    RINGTONE_NOTE(REST   , CROTCHET),  
    RINGTONE_NOTE(A5   , CROTCHET),  

    RINGTONE_END
};

/*vol 6 68mS DS6*/   
static const ringtone_note tone_Q3D[] =
{
    RINGTONE_TEMPO(800), RINGTONE_VOLUME(64), RINGTONE_TIMBRE(sine),
    
    RINGTONE_NOTE(DS6   , CROTCHET),  

    RINGTONE_END
};

/*vol 5 68mS D6*/   
static const ringtone_note tone_Q3E[] =
{
    RINGTONE_TEMPO(800), RINGTONE_VOLUME(64), RINGTONE_TIMBRE(sine),
    
    RINGTONE_NOTE(D6   , CROTCHET),  

    RINGTONE_END
};

/*vol 4 68mS CS6*/   
static const ringtone_note tone_Q3F[] =
{
    RINGTONE_TEMPO(800), RINGTONE_VOLUME(64), RINGTONE_TIMBRE(sine),
    
    RINGTONE_NOTE(CS6   , CROTCHET),  

    RINGTONE_END
};

/*vol 3 68mS C6 */   
static const ringtone_note tone_Q40[] =
{
    RINGTONE_TEMPO(800), RINGTONE_VOLUME(64), RINGTONE_TIMBRE(sine),
    
    RINGTONE_NOTE(C6   , CROTCHET),  

    RINGTONE_END
};

/*vol 2 68mS B5*/   
static const ringtone_note tone_Q41[] =
{
    RINGTONE_TEMPO(800), RINGTONE_VOLUME(64), RINGTONE_TIMBRE(sine),
    
    RINGTONE_NOTE(B5   , CROTCHET),  

    RINGTONE_END
};

/*vol 1 68mS AS5*/   
static const ringtone_note tone_Q42[] =
{
    RINGTONE_TEMPO(800), RINGTONE_VOLUME(64), RINGTONE_TIMBRE(sine),
    
    RINGTONE_NOTE(AS5   , CROTCHET),  

    RINGTONE_END
};

/***************************************************************************/
/*
    The Tone Array
*/
/*************************************************************************/

/* This must make use of all of the defined tones - requires the extra space first */
static const ringtone_note * const gFixedTones [ NUM_FIXED_TONES ] = 
{
/*1*/    tone_B  ,  /*Vol 0*/
/*2*/    tone_C  ,  /*Vol 1*/
/*3*/    tone_D  ,  /*Vol 2*/
/*4*/    tone_E  ,  /*Vol 3*/
    
/*5*/    tone_F  ,  /*Vol 4*/
/*6*/    tone_G  ,  /*Vol 5*/
/*7*/    tone_H  ,  /*Vol 6*/
/*8*/    tone_I  ,  /*Vol 7*/
    
/*9*/    tone_J  ,  /*Vol 8*/
/*A*/    tone_K  ,  /*Vol 9*/
/*b*/    tone_L  ,  /*Vol 10*/
/*c*/    tone_M  ,  /*4 note rise*/
    
/*d*/    tone_N  ,  /*2 note ris*/
/*e*/    tone_O  ,  /*2 note fall*/
/*f*/    tone_P  ,  /*long low short high*/
/*10*/   tone_Q  ,  /*conn  */
    
/*11*/   tone_R  ,  /*power*/
/*12*/   tone_S  ,  /*error*/
/*13*/   tone_T  ,  /*short cfm*/
/*14*/   tone_U  ,  /*long CFM*/
    
/*15*/   tone_V  ,  /*Low Batt*/
/*16*/   tone_W  ,  /*pair removal*/
/*17*/   tone_X  ,  /*double*/  
/*18*/   battery_low_tone    ,

/*19*/   low_500ms_tone      ,
/*1a*/   mute_reminder_tone  ,
/*1b*/   ring_twilight       ,
/*1c*/   ring_g_s_t_q        ,

/*1d*/   ring_valkyries      ,
/*1e*/   ring_greensleeves   ,  
/*1f*/   ring_two_beeps      ,
/*20*/   ring_fairground     ,
    
/*21*/   ring_counterpoint   ,
/*22*/   ring_major_arp      ,
/*23*/   ring_major_scale    ,
/*24*/   ring_minor_arp      ,

/*25*/   ring_harmonic_minor_scale,
/*26*/   ring_more_than_a_feeling ,
/*27*/   ring_eight_beeps         ,
/*28*/   ring_four_beeps          ,

/*29*/   ring_bumble_bee ,
/*2a*/   ring_aug_scale  ,
/*2b*/   ring_dim_scale  , 
           
/*2c*/   CustomRingTone  , /*this is a custom ring tone that can be defined if required.*/
/*2d*/   tone_A1         ,   /*4 low to high 38ms*/  
/*2e*/   tone_A2         ,   /*4 high to low 38ms*/
/*2f*/   tone_A3         ,   /*880 Hz for 100ms*/

/*30*/   tone_A4         ,   /*series of 5 high tones 94 ms*/
/*31*/   tone_A5         ,   /*low to high 100ms tones 50ms pause*/
/*32*/   tone_A6         ,   /*high to low 100ms tones 50ms pause*/
/*33*/   tone_S1         ,   /*short v high 2400hz*/

/*34*/   tone_S2         ,   /*series(12) of high / higher beeps*/
/*35*/   tone_S3         ,   /*short middle (987) **/
/*36*/   tone_S4         ,   /*series of 5 high beeps with pause*/
/*37*/   tone_S5         ,   /*Low High*/

/*38*/   tone_S6         ,   /*High Low*/
/*39*/	 tone_Q21		 ,   /*Short Middle Tone, 100ms D6*/	
/*3a*/	 tone_Q22		 ,   /*4 Low to High Long at Top, 100ms G5 D6 G6 300ms B6 */	
/*3b*/	 tone_Q23		 ,   /*4 High to Low Long at Bottom, 100ms B6 G6 D6 300ms G5 */ 	
		 
/*3c*/   tone_Q24		 ,	 /*3 Note Descending, 300ms G6 D6 G5*/
/*3d*/	 tone_Q25		 ,	 /*5th Down Medium-Long, 300ms D6 500ms G5*/	
/*3e*/	 tone_Q26	     ,	 /*5th Down Short-Short, 100ms D6 G5*/	
/*3f*/	 tone_Q27		 , 	 /*5th Up Short-Short, 100ms G5 D6*/
		 
/*40*/   tone_Q28		 ,   /*2 Half Second Low Tones, 500ms G5 REST G5*/
/*41*/   tone_Q29		 ,   /*Short High Tone, 100ms G7*/
/*42*/	 tone_Q2A		 ,   /*Long Low Tone, 400ms G5*/
/*43*/   tone_Q2B        ,   /*Double Low Tones, 200ms G5 REST G5*/
		 
/*44*/   tone_Q2C        ,   /*G Major Arp Up, 125ms G6 B6 D7 G7*/	
/*45*/   tone_Q2D        ,   /*G Major Arp Down, 125ms G7 D7 B6 G6*/
/*46*/   tone_Q2E        ,   /*Fairly Short High Tone, 150ms G7*/
/*47*/   tone_Q2F		 ,   /*Fairly Short Low Tone, 150ms G5*/
		 
/*48*/   tone_Q210       ,   /*Medium Length Low Tone, 200ms G5*/	
/*49*/   tone_Q211       ,   /*Short Low-High, 80ms G5 G7*/		
/*4A*/   tone_Q212       ,   /*Double Octave Toggle Ring Tone, 50ms G7 G5 G7 G5 G7 G5 Repeat after 250ms*/
/*4B*/   tone_Q213		 ,	 /*Low Low High, 100ms G5 G5 G7*/	
		 
/*4c*/	 tone_Q214		 ,   /*Double Low Tones (long), 300ms G5 G5*/
/*4d*/	 tone_Q31		 ,   /*Connected 48mS C6 D6 A6 */		
/*4e*/	 tone_Q32		 ,   /*Disconnected 48mS A6 D6 C6 */		
/*4f*/	 tone_Q33		 ,   /*confirmation tone 68mS C5 E5 */		
         
/*50*/	 tone_Q34		 ,   /*error tone 2 68mS A5 REST A5 */		 
/*51*/	 tone_Q35		 ,   /*low batt 2 125mS E6 F5 */		
/*52*/	 tone_Q36		 ,   /*mute off 2 48mS A5 A4 */		
/*53*/	 tone_Q37		 ,   /*mute on 2 48mS A4 A5 */		
         
/*54*/	 tone_Q38		 ,   /*single tone 48mS A5*/       
/*55*/	 tone_Q39		 ,   /*shutdown tone 408mS A5 136mS A4 */
/*56*/	 tone_Q3A		 ,   /*phone ring 48mS C6 E6 C6 E6 C6 E6 C6 E6 C6 E6 C6 REST C6 E6 C6 E6 C6 E6 C6 E6 C6 E6 C6*/
/*57*/   tone_Q3B        ,   /*power up tone 83mS C5 10mS REST 83mS E5 10mS REST 83mS G5 10mS REST 124mS B5 498mS REST 372mS C6 */          
         
/*58*/   tone_Q3C        ,   /*vol lev 0/7 */                 
/*59*/   tone_Q3D        ,   /*vol lev 6 */         
/*5a*/   tone_Q3E        ,   /*vol lev 5 */         
/*5b*/   tone_Q3F        ,   /*vol lev 4 */         
         
/*5c*/   tone_Q40        ,   /*vol lev 3 */                
/*5d*/   tone_Q41        ,   /*vol lev 2 */         
/*5e*/   tone_Q42        ,    /*vol lev 1 */
                 
     } ;

/****************************************************************************
NAME 
 TonesPlayEvent

DESCRIPTION
 function to indaicate an event by playing its associated tone uses underlying
    tones playback

RETURNS
 void
    
*/
void TonesPlayEvent ( sinkEvents_t pEvent )
{    
    uint16 lEvent = pEvent;
	int i = 0 ;
	
    /* Don't play tone for Mute Toggle, this event is auto-converted to either EventUsrMuteOn or EventUsrMuteOff */
    if (pEvent == EventUsrMuteToggle)
        return;
    
#ifdef ENABLE_SOUNDBAR
	/* In Limbo for sound bar build, playing tones may cause panic if I2S amplifier is powered down by PIO */
    if(stateManagerGetState() == deviceLimbo)
    {
        /* If sound bar I2S amplifier shut down is managed by PIO, first check the logic state of amplifier power pin */
        if((theSink.conf2->audio_routing_data.PluginFeatures.audio_output_type == OUTPUT_INTERFACE_TYPE_I2S)
            &&(theSink.features.AmplifierShutDownByPIO))
        {
            /* Check configuration for AMP pio drive */
            if(theSink.conf1->PIOIO.pio_outputs.PowerOnPIO != NO_PIO)
            {
				/* Do not attempt to play tones through I2S if amplifier is shut down already,
				otherwise, I2C comms will fail and cause panic */
                if(theSink.audioAmpPowerPin != TRUE)
                
                    return;
            }
        }
    }
#endif
    
    /* ensure sink is not in muted state or trying to play the mute reminder */
    if((theSink.sink_mute_status != TRUE)||(pEvent == EventSysMuteReminder)||(pEvent == EventUsrMuteOn))
    {
        /* If Audio Prompts are disabled go straight to tones. Otherwise if Audio Prompt is assigned to this 
           event tone playback would be skipped.*/
        if(theSink.audio_prompts_enabled)
        { 
            /* If there's a valid Audio Prompt event to play don't play any tones */
            if(AudioPromptPlayEvent( pEvent ))
                return;
        }
    
        /* scan available tones list, list end is signified by NOT_DEFINED */
     while ( theSink.conf2->gEventTones [i].tone != TONE_NOT_DEFINED )
     {
            /* if an event matche is found then play tone */
      if (theSink.conf2->gEventTones [i].event == lEvent )
      {
                /* turn on audio amp */
                PioSetPio ( theSink.conf1->PIOIO.pio_outputs.DeviceAudioActivePIO , pio_drive, TRUE) ;
                /* start check to turn amp off again if required */ 
                MessageSendLater(&theSink.task , EventSysCheckAudioAmpDrive, 0, 1000);    
    
       /* check event as tone queueing not allowed on mute and ring tones */					   
       switch(pEvent)
                {
                    case EventSysMuteReminder:
                    case EventSysRingtone1:
                    case EventSysRingtone2:
                    
             /* check whether to play mute reminder tone at default volume level, never queue mute reminders to 
                   protect against the case that the tone is longer than the mute reminder timer */
                        TonesPlayTone (theSink.conf2->gEventTones [ i ].tone ,FALSE, (theSink.features.MuteToneFixedVolume)) ;			
                        break;
                       
                    /* for all other events use the QueueEventTones feature bit setting */
                    default:
                        
            /* play tone */
                     TonesPlayTone (theSink.conf2->gEventTones [ i ].tone ,theSink.features.QueueEventTones, FALSE ) ;			
                        break;    
                }
            }
      i++ ;
     }
   }
} 

/****************************************************************************
NAME    
    TonesPlayTone
    
DESCRIPTION
  	Works out the correct volume to play tones or Audio Prompts at
    
RETURNS
    void
*/
uint16 TonesGetToneVolume(bool PlayToneAtDefaultLevel)
{           
    uint16 lToneVolume;
    
    /* if play at fixed volume selected */
    if (theSink.features.PlayTonesAtFixedVolume)
    {      
        /* volume level is already in raw gain units, no need to use volume mapping table */
        lToneVolume = theSink.features.FixedToneVolumeLevel ;
    }
    /* check for play tone at default level */
    else 
    {    
        /* default volume level unless changed by other options */
        uint8 index = theSink.features.DefaultVolume ;            
        
        /* is tone not being played at default volume? */
        if(!PlayToneAtDefaultLevel)
        {
            /* use primary hfp volume */            
            index = theSink.profile_data[PROFILE_INDEX(hfp_primary_link)].audio.gSMVolumeLevel;  			
        }
        /* get volume gain from volume mapped table */     
        lToneVolume = theSink.conf1->volume_config.gVolMaps[index].VolGain;
    }
    
    TONE_DEBUG(("TONE Volume [%d]\n", lToneVolume));
    
    return lToneVolume;
}

/****************************************************************************
NAME    
    TonesPlayTone
    
DESCRIPTION
  	Plays back the tone given by the ringtone_note index
    
RETURNS
    void
*/
void TonesPlayTone ( uint16 pTone , bool pCanQueue , bool PlayToneAtDefaultLevel)
{
    uint16 lToneVolume = TonesGetToneVolume(PlayToneAtDefaultLevel);
    TONE_DEBUG(("TONE Play sinth [%x]\n", pTone));

    /* ensure tone is valid (non zero) before playing */
    if(pTone > 0 && pTone <= NUM_FIXED_TONES)
    {
       AudioPlayTone ( gFixedTones [ pTone  - 1 ],
                       pCanQueue,
                       theSink.codec_task,
                       lToneVolume,
                       theSink.conf2->audio_routing_data.PluginFeatures ) ;   
    }
    /* if the tone index is beyond that of the fixed tones, check for the prescence of
       a user defined tone, there are 8 user defineable tones available at the end of the
       fixed tones list */
    else
    {
        TONE_DEBUG(("TONE Play sinth which is larger than 5e is [%x] - [%d]\n", pTone, pTone-1-NUM_FIXED_TONES));
            
         /* check to see if there are any configured user defined tones and then check to see
            if there is a tone available at the index (0 to 7) requested */
        if(&theSink.gConfigTones.gVariableTones[0] && 
           theSink.gConfigTones.gVariableTones[pTone-1-NUM_FIXED_TONES])
        {

            /* audio tone is located at 'start of data + an offset' into the array of data,
               the first 8 words of data in gVariableTones are offsets into the data array
               for user tones 0 to 7 */
            AudioPlayTone ( (const ringtone_note *)(&theSink.gConfigTones.gVariableTones[0] + 
                                                 (uint16)theSink.gConfigTones.gVariableTones[pTone-1-NUM_FIXED_TONES]),
                            pCanQueue,
                            theSink.codec_task,
                            lToneVolume,
                            theSink.conf2->audio_routing_data.PluginFeatures ) ;  
                              
        }
    }
}

/****************************************************************************
NAME    
    ToneTerminate
    
DESCRIPTION
  	function to terminate a ring tone prematurely.
    
RETURNS
    
*/
void ToneTerminate ( void )
{
    AudioStopTone();
    AudioPromptTerminate();
}  





