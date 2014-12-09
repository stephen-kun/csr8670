/****************************************************************************
Copyright (C) Cambridge Silicon Radio Ltd. 2005

FILE NAME
    csr_a2dp_decoder_common_plugin.c
DESCRIPTION
    an audio plugin
NOTES
*/
#include <audio.h>
#include <codec.h>
#include <stdlib.h>
#include <print.h>
#include <stream.h> /*for the ringtone_note*/
#include <string.h>
#include <panic.h>

#include "audio_plugin_if.h" /*the messaging interface*/
#include "audio_plugin_common.h"
#include "csr_a2dp_decoder_common_plugin.h"
#include "csr_a2dp_decoder_common.h"
#include "csr_a2dp_decoder_common_if.h"
#include "csr_a2dp_decoder_common_subwoofer.h"
#include "csr_a2dp_decoder_common_sharing.h"


	/*the task message handler*/
static void message_handler (Task task, MessageId id, Message message);

	/*the local message handling functions*/
static void handleAudioMessage ( Task task , MessageId id, Message message );
static void handleInternalMessage ( Task task , MessageId id, Message message );

	/*the plugin task*/
const A2dpPluginTaskdata csr_sbc_decoder_plugin = {{message_handler}, SBC_DECODER};
const A2dpPluginTaskdata csr_mp3_decoder_plugin = {{message_handler}, MP3_DECODER};
const A2dpPluginTaskdata csr_aac_decoder_plugin = {{message_handler}, AAC_DECODER};
const A2dpPluginTaskdata csr_faststream_sink_plugin = {{message_handler}, FASTSTREAM_SINK};
const A2dpPluginTaskdata csr_aptx_decoder_plugin = {{message_handler}, APTX_DECODER};
const A2dpPluginTaskdata csr_aptx_acl_sprint_decoder_plugin = {{message_handler}, APTX_ACL_SPRINT_DECODER};
const A2dpPluginTaskdata csr_tws_sbc_decoder_plugin = {{message_handler}, TWS_SBC_DECODER};
const A2dpPluginTaskdata csr_tws_mp3_decoder_plugin = {{message_handler}, TWS_MP3_DECODER};
const A2dpPluginTaskdata csr_tws_aac_decoder_plugin = {{message_handler}, TWS_AAC_DECODER};
const A2dpPluginTaskdata csr_tws_aptx_decoder_plugin = {{message_handler}, TWS_APTX_DECODER};
const A2dpPluginTaskdata csr_fm_decoder_plugin = {{message_handler}, FM_DECODER};

/*! @name SBC configuration bit fields 
*/
/*@{ */
/*! [Octet 0] Support for 16kHz Sampling frequency */
#define SBC_SAMPLING_FREQ_16000        128
/*! [Octet 0] Support for 32kHz Sampling frequency */
#define SBC_SAMPLING_FREQ_32000         64
/*! [Octet 0] Support for 44.1kHz Sampling frequency */
#define SBC_SAMPLING_FREQ_44100         32
/*! [Octet 0] Support for 48kHz Sampling frequency */
#define SBC_SAMPLING_FREQ_48000         16
/*! [Octet 0] Support for Mono channel mode */
#define SBC_CHANNEL_MODE_MONO            8
/*! [Octet 0] Support for Dualchannel mode */
#define SBC_CHANNEL_MODE_DUAL_CHAN       4
/*! [Octet 0] Support for Stereo channel mode */
#define SBC_CHANNEL_MODE_STEREO          2
/*! [Octet 0] Support for Joint Stereo channel mode */
#define SBC_CHANNEL_MODE_JOINT_STEREO    1

/*! [Octet 1] Support for a block length of 4 */
#define SBC_BLOCK_LENGTH_4             128
/*! [Octet 1] Support for a block length of 8 */
#define SBC_BLOCK_LENGTH_8              64
/*! [Octet 1] Support for a block length of 12 */
#define SBC_BLOCK_LENGTH_12             32
/*! [Octet 1] Support for a block length of 16 */
#define SBC_BLOCK_LENGTH_16             16
/*! [Octet 1] Support for 4 subbands */
#define SBC_SUBBANDS_4                   8
/*! [Octet 1] Support for 8 subbands */
#define SBC_SUBBANDS_8                   4
/*! [Octet 1] Support for SNR allocation */
#define SBC_ALLOCATION_SNR               2
/*! [Octet 1] Support for Loudness allocation */
#define SBC_ALLOCATION_LOUDNESS          1

/*! [Octet 2] Minimum bitpool supported */
#define SBC_BITPOOL_MIN                  2
/*! [Octet 2] Maximum bitpool supported */
#define SBC_BITPOOL_MAX                250
/*! [Octet 2] Maximum bitpool for Medium quality */
#define SBC_BITPOOL_MEDIUM_QUALITY      35
/*! [Octet 2] Maximum bitpool for High quality */
#define SBC_BITPOOL_HIGH_QUALITY        53

/*@} */


/*! @name Default SBC Capabilities
    Default capabilites that an application can pass to the A2DP library during initialisation.
    
    Support all features and full bitpool range. Note that we trust the source
    to choose a bitpool value suitable for the Bluetooth bandwidth.
*/
const uint8 sbc_caps_sink[16] = 
{
    AVDTP_SERVICE_MEDIA_TRANSPORT,
    0,
    AVDTP_SERVICE_MEDIA_CODEC,
    6,
    AVDTP_MEDIA_TYPE_AUDIO<<2,
    AVDTP_MEDIA_CODEC_SBC,

    SBC_SAMPLING_FREQ_16000     | SBC_SAMPLING_FREQ_32000    | SBC_SAMPLING_FREQ_44100    | SBC_SAMPLING_FREQ_48000    |
    SBC_CHANNEL_MODE_MONO       | SBC_CHANNEL_MODE_DUAL_CHAN | SBC_CHANNEL_MODE_STEREO    | SBC_CHANNEL_MODE_JOINT_STEREO,

    SBC_BLOCK_LENGTH_4          | SBC_BLOCK_LENGTH_8         | SBC_BLOCK_LENGTH_12        | SBC_BLOCK_LENGTH_16        |
    SBC_SUBBANDS_4              | SBC_SUBBANDS_8             | SBC_ALLOCATION_SNR         | SBC_ALLOCATION_LOUDNESS,

    SBC_BITPOOL_MIN,
    SBC_BITPOOL_HIGH_QUALITY,

    AVDTP_SERVICE_CONTENT_PROTECTION,
    2,
    AVDTP_CP_TYPE_SCMS_LSB,
    AVDTP_CP_TYPE_SCMS_MSB,
    
    AVDTP_SERVICE_DELAY_REPORTING,
    0
};

/*! @name MP3 configuration bit fields 
*/
/*@{ */
/*! [Octet 0] Support for Layer I (mp1) */
#define MP3_LAYER_I                    128
/*! [Octet 0] Support for Layer II (mp2) */
#define MP3_LAYER_II                    64
/*! [Octet 0] Support for Layer III (mp3) */
#define MP3_LAYER_III                   32
/*! [Octet 0] Support for CRC Protection */
#define MP3_CRC_PROTECTION              16
/*! [Octet 0] Support for Mono channel mode */
#define MP3_CHANNEL_MODE_MONO            8
/*! [Octet 0] Support for Dual channel mode */
#define MP3_CHANNEL_MODE_DUAL_CHAN       4
/*! [Octet 0] Support for Stereo channel mode */
#define MP3_CHANNEL_MODE_STEREO          2
/*! [Octet 0] Support for Joint stereo channel mode */
#define MP3_CHANNEL_MODE_JOINT_STEREO    1

/*! [Octet 1] Support for 16kHz sampling frequency */
#define MP3_SAMPLING_FREQ_16000         32
/*! [Octet 1] Support for 22050Hz sampling frequency */
#define MP3_SAMPLING_FREQ_22050         16
/*! [Octet 1] Support for 24kHz sampling frequency */
#define MP3_SAMPLING_FREQ_24000          8
/*! [Octet 1] Support for 32kHz sampling frequency */
#define MP3_SAMPLING_FREQ_32000          4
/*! [Octet 1] Support for 44.1kHz sampling frequency */
#define MP3_SAMPLING_FREQ_44100          2
/*! [Octet 1] Support for 48kHz sampling frequency */
#define MP3_SAMPLING_FREQ_48000          1

/*! [Octet 2] Support for Variable bit rate */
#define MP3_VBR                        128
/*! [Octet 2] Support for bit rate 1110 */
#define MP3_BITRATE_VALUE_1110          64
/*! [Octet 2] Support for bit rate 1101 */
#define MP3_BITRATE_VALUE_1101          32
/*! [Octet 2] Support for bit rate 1100 */
#define MP3_BITRATE_VALUE_1100          16
/*! [Octet 2] Support for bit rate 1011 */
#define MP3_BITRATE_VALUE_1011           8
/*! [Octet 2] Support for bit rate 1010 */
#define MP3_BITRATE_VALUE_1010           4
/*! [Octet 2] Support for bit rate 1001 */
#define MP3_BITRATE_VALUE_1001           2
/*! [Octet 2] Support for bit rate 1000 */
#define MP3_BITRATE_VALUE_1000           1

/*! [Octet 3] Support for bit rate 0111 */
#define MP3_BITRATE_VALUE_0111         128
/*! [Octet 3] Support for bit rate 0110 */
#define MP3_BITRATE_VALUE_0110          64
/*! [Octet 3] Support for bit rate 0101 */
#define MP3_BITRATE_VALUE_0101          32
/*! [Octet 3] Support for bit rate 0100 */
#define MP3_BITRATE_VALUE_0100          16
/*! [Octet 3] Support for bit rate 0011 */
#define MP3_BITRATE_VALUE_0011           8
/*! [Octet 3] Support for bit rate 0010 */
#define MP3_BITRATE_VALUE_0010           4
/*! [Octet 3] Support for bit rate 0001 */
#define MP3_BITRATE_VALUE_0001           2
/*! [Octet 3] Support for bit rate 0000 */
#define MP3_BITRATE_VALUE_FREE           1



/*@} */


/*! @name Default MP3 Capabilities
    Default capabilites that an application can pass to the A2DP library during initialisation.
    
    Support all features except:
    - MPEG-1 Layer 3
    - MPF-1
    - free rate
*/
const uint8 mp3_caps_sink[16] = 
{
    AVDTP_SERVICE_MEDIA_TRANSPORT,
    0,
    AVDTP_SERVICE_MEDIA_CODEC,
    6,
    AVDTP_MEDIA_TYPE_AUDIO<<2,
    AVDTP_MEDIA_CODEC_MPEG1_2_AUDIO,
    
    MP3_LAYER_III              | MP3_CRC_PROTECTION          |
    MP3_CHANNEL_MODE_MONO      | MP3_CHANNEL_MODE_DUAL_CHAN  | MP3_CHANNEL_MODE_STEREO     | MP3_CHANNEL_MODE_JOINT_STEREO,
    
    MP3_SAMPLING_FREQ_16000 | MP3_SAMPLING_FREQ_22050 | MP3_SAMPLING_FREQ_24000 | MP3_SAMPLING_FREQ_32000 | MP3_SAMPLING_FREQ_44100 | MP3_SAMPLING_FREQ_48000,
    
    MP3_VBR                    | MP3_BITRATE_VALUE_1110      | MP3_BITRATE_VALUE_1101      | MP3_BITRATE_VALUE_1100    |
    MP3_BITRATE_VALUE_1011     | MP3_BITRATE_VALUE_1010      | MP3_BITRATE_VALUE_1001      | MP3_BITRATE_VALUE_1000,
    
    MP3_BITRATE_VALUE_0111     | MP3_BITRATE_VALUE_0110      | MP3_BITRATE_VALUE_0101      | MP3_BITRATE_VALUE_0100    |
    MP3_BITRATE_VALUE_0011     | MP3_BITRATE_VALUE_0010      | MP3_BITRATE_VALUE_0001,    /* All bit rates except 'free' */
    
    AVDTP_SERVICE_CONTENT_PROTECTION,
    2,
    AVDTP_CP_TYPE_SCMS_LSB,
    AVDTP_CP_TYPE_SCMS_MSB,
    
    AVDTP_SERVICE_DELAY_REPORTING,
    0
};

/*! @name AAC/AAC+ configuration bit fields 
*/
/*@{ */
/*! [Octet 0] Support for MPEG-2 AAC LC */
#define AAC_MPEG2_AAC_LC        (1<<7)
/*! [Octet 0] Support for MPEG-4 AAC LC */
#define AAC_MPEG4_AAC_LC        (1<<6)
/*! [Octet 0] Support for MPEG-4 AAC LTP */
#define AAC_MPEG4_AAC_LTP       (1<<5)
/*! [Octet 0] Support for MPEG-4 AAC Scalable */
#define AAC_MPEG4_AAC_SCALE     (1<<4)

/*! [Octet 1] Support for 8kHz sampling frequency */
#define AAC_SAMPLE_8000         (1<<7)
/*! [Octet 1] Support for 11025Hz sampling frequency */
#define AAC_SAMPLE_11025        (1<<6)
/*! [Octet 1] Support for 12kHz sampling frequency */
#define AAC_SAMPLE_12000        (1<<5)
/*! [Octet 1] Support for 16kHz sampling frequency */
#define AAC_SAMPLE_16000        (1<<4)
/*! [Octet 1] Support for 22050Hz sampling frequency */
#define AAC_SAMPLE_22050        (1<<3)
/*! [Octet 1] Support for 24kHz sampling frequency */
#define AAC_SAMPLE_24000        (1<<2)
/*! [Octet 1] Support for 32kHz sampling frequency */
#define AAC_SAMPLE_32000        (1<<1)
/*! [Octet 1] Support for 44.1kHz sampling frequency */
#define AAC_SAMPLE_44100        (1<<0)
/*! [Octet 2] Support for 48kHz sampling frequency */
#define AAC_SAMPLE_48000        (1<<7)
/*! [Octet 2] Support for 64kHz sampling frequency */
#define AAC_SAMPLE_64000        (1<<6)
/*! [Octet 2] Support for 88.2kHz sampling frequency */
#define AAC_SAMPLE_88200        (1<<5)
/*! [Octet 2] Support for 96kHz sampling frequency */
#define AAC_SAMPLE_96000        (1<<4)
/*! [Octet 2] Support for using 1 channel */
#define AAC_CHANNEL_1           (1<<3)
/*! [Octet 2] Support for using 2 channels */
#define AAC_CHANNEL_2           (1<<2)

/*! [Octet 3] Support for Variable Bit Rate */
#define AAC_VBR                 (1<<7)
/*! [Octet 3] Support for 320kbps (320000bps) = 0x04E200 */
#define AAC_BITRATE_256_3       (0x04)

/*! [Octet 4] Support for 320kbps (320000bps) */
#define AAC_BITRATE_256_4       (0xE2)

/*! [Octet 5] Support for 320kbps (320000bps) */
#define AAC_BITRATE_256_5       (0x00)

/*@} */

/*! @name Default AAC/AAC+ Capabilities
    Default capabilites that an application can pass to the A2DP library during initialisation.
    
    Support all features.
*/
const uint8 aac_caps_sink[18] = 
{
    AVDTP_SERVICE_MEDIA_TRANSPORT,
    0,
    AVDTP_SERVICE_MEDIA_CODEC,
    8,
    AVDTP_MEDIA_TYPE_AUDIO<<2,
    AVDTP_MEDIA_CODEC_MPEG2_4_AAC,

    AAC_MPEG2_AAC_LC | AAC_MPEG4_AAC_LC,
    AAC_SAMPLE_8000 | AAC_SAMPLE_11025 | AAC_SAMPLE_12000 | AAC_SAMPLE_16000 | AAC_SAMPLE_22050 | AAC_SAMPLE_24000 | AAC_SAMPLE_32000 | AAC_SAMPLE_44100,
    AAC_SAMPLE_48000 | AAC_CHANNEL_1 | AAC_CHANNEL_2,
    AAC_VBR | AAC_BITRATE_256_3,
    AAC_BITRATE_256_4,
    AAC_BITRATE_256_5,

    AVDTP_SERVICE_CONTENT_PROTECTION,
    2,
    AVDTP_CP_TYPE_SCMS_LSB,
    AVDTP_CP_TYPE_SCMS_MSB,
    
    AVDTP_SERVICE_DELAY_REPORTING,
    0
};


/*! @name SBC configuration bit fields 
*/
/*@{ */
/*! [Octet 0] CSR Vendor ID Octet 0 */
#define FASTSTREAM_VENDOR_ID0         0x0A
/*! [Octet 1] CSR Vendor ID Octet 1 */
#define FASTSTREAM_VENDOR_ID1         0x00
/*! [Octet 2] CSR Vendor ID Octet 2 */
#define FASTSTREAM_VENDOR_ID2         0x00
/*! [Octet 3] CSR Vendor ID Octet 3 */
#define FASTSTREAM_VENDOR_ID3         0x00
/*! [Octet 4] Fastream Codec ID Octet 0 */
#define FASTSTREAM_CODEC_ID0          0x01
/*! [Octet 5] Fastream Codec ID Octet 1 */
#define FASTSTREAM_CODEC_ID1          0x00
/*! [Octet 6] Support for music */
#define FASTSTREAM_MUSIC              0x01
/*! [Octet 6] Support for voice */
#define FASTSTREAM_VOICE              0x02
/*! [Octet 7] Support for 48.0kHz sampling frequency */
#define FASTSTREAM_MUSIC_SAMP_48000   0x01
/*! [Octet 7] Support for 44.1kHz sampling frequency */
#define FASTSTREAM_MUSIC_SAMP_44100   0x02
/*! [Octet 7] Support for 16kHz sampling frequency */
#define FASTSTREAM_VOICE_SAMP_16000   0x20

/*@} */


/*! @name Default Fastream Capabilities
    Default capabilites that an application can pass to the A2DP library during initialisation.
*/
const uint8 faststream_caps_sink[16] = 
{
    AVDTP_SERVICE_MEDIA_TRANSPORT,
    0,
    AVDTP_SERVICE_MEDIA_CODEC,
    10,
    AVDTP_MEDIA_TYPE_AUDIO<<2,
    AVDTP_MEDIA_CODEC_NONA2DP,

    FASTSTREAM_VENDOR_ID0,
    FASTSTREAM_VENDOR_ID1,
    FASTSTREAM_VENDOR_ID2,
    FASTSTREAM_VENDOR_ID3,
    FASTSTREAM_CODEC_ID0,
    FASTSTREAM_CODEC_ID1,
    FASTSTREAM_MUSIC | FASTSTREAM_VOICE,
    FASTSTREAM_MUSIC_SAMP_48000 | FASTSTREAM_MUSIC_SAMP_44100 | FASTSTREAM_VOICE_SAMP_16000,
    
    AVDTP_SERVICE_DELAY_REPORTING,
    0
};


/*! @name Common APTX configuration bit fields 
*/
/*@{ */
#define APTX_SAMPLING_FREQ_44100         32
#define APTX_SAMPLING_FREQ_48000         16
#define APTX_CHANNEL_MODE_STEREO          2
/*@} */

/*! @name APTX vendor and codec identifiers
*/
/*@{ */
#define APTX_VENDOR_ID0                0x4F   /* APT codec ID 79 */
#define APTX_VENDOR_ID1                 0x0   /* Needed for backwards */
#define APTX_VENDOR_ID2                 0x0   /* compatibility.*/
#define APTX_VENDOR_ID3                 0x0
#define APTX_CODEC_ID0                  0x1
#define APTX_CODEC_ID1                  0x0
/*@} */

/*! @name Default apt-X Capabilities
    Default capabilites that an application can pass to the A2DP library during initialisation.
*/
const uint8 aptx_caps_sink[19] = 
{
    AVDTP_SERVICE_MEDIA_TRANSPORT,
    0,
    AVDTP_SERVICE_MEDIA_CODEC,
    9,
    AVDTP_MEDIA_TYPE_AUDIO<<2,
    AVDTP_MEDIA_CODEC_NONA2DP,
    
    APTX_VENDOR_ID0,
    APTX_VENDOR_ID1,
    APTX_VENDOR_ID2,
    APTX_VENDOR_ID3,
    APTX_CODEC_ID0,
    APTX_CODEC_ID1,
    
    APTX_SAMPLING_FREQ_44100    + APTX_SAMPLING_FREQ_48000    +
    APTX_CHANNEL_MODE_STEREO,

    AVDTP_SERVICE_CONTENT_PROTECTION,
    2,
    AVDTP_CP_TYPE_SCMS_LSB,
    AVDTP_CP_TYPE_SCMS_MSB,
    
    AVDTP_SERVICE_DELAY_REPORTING,
    0
};


/*! @name APTX Sprint vendor and codec identifiers
*/
/*@{ */
#define APTX_ACL_SPRINT_VENDOR_ID0     0x0A    /* CSR codec ID 10 */
#define APTX_ACL_SPRINT_VENDOR_ID1      0x0
#define APTX_ACL_SPRINT_VENDOR_ID2      0x0
#define APTX_ACL_SPRINT_VENDOR_ID3      0x0
#define APTX_ACL_SPRINT_CODEC_ID0       0x2
#define APTX_ACL_SPRINT_CODEC_ID1       0x0
#define APTX_ACL_SPRINT_SBC_BIDIR       0x1
#define APTX_ACL_SPRINT_NEW_CAPS        0x2
#define APTX_ACL_SPRINT_RESERVED        0x0
/*@} */

/*! @name Default apt-X Sprint Capabilities
    Default capabilites that an application can pass to the A2DP library during initialisation.
*/
const uint8 aptx_acl_sprint_caps_sink[29] = 
{
    AVDTP_SERVICE_MEDIA_TRANSPORT,
    0,
    AVDTP_SERVICE_MEDIA_CODEC,
    19,
    AVDTP_MEDIA_TYPE_AUDIO<<2,
    AVDTP_MEDIA_CODEC_NONA2DP,
    
    APTX_ACL_SPRINT_VENDOR_ID0,
    APTX_ACL_SPRINT_VENDOR_ID1,
    APTX_ACL_SPRINT_VENDOR_ID2,
    APTX_ACL_SPRINT_VENDOR_ID3,
    APTX_ACL_SPRINT_CODEC_ID0,
    APTX_ACL_SPRINT_CODEC_ID1,
    
    APTX_SAMPLING_FREQ_44100    + APTX_SAMPLING_FREQ_48000    +
    APTX_CHANNEL_MODE_STEREO,
    
#ifdef CVC_BACK_CHANNEL
    APTX_ACL_SPRINT_SBC_BIDIR + APTX_ACL_SPRINT_NEW_CAPS,
#else
    APTX_ACL_SPRINT_RESERVED + APTX_ACL_SPRINT_NEW_CAPS,
#endif
    APTX_ACL_SPRINT_RESERVED, /* Decoder doesn't store any values */
    APTX_ACL_SPRINT_RESERVED, /* These are just sent from the encoder */
    APTX_ACL_SPRINT_RESERVED, /* during caps exchange */
    APTX_ACL_SPRINT_RESERVED,
    APTX_ACL_SPRINT_RESERVED,
    APTX_ACL_SPRINT_RESERVED,
    APTX_ACL_SPRINT_RESERVED,
    APTX_ACL_SPRINT_RESERVED,
    APTX_ACL_SPRINT_RESERVED,

    AVDTP_SERVICE_CONTENT_PROTECTION,
    2,
    AVDTP_CP_TYPE_SCMS_LSB,
    AVDTP_CP_TYPE_SCMS_MSB,
    
    AVDTP_SERVICE_DELAY_REPORTING,
    0
};


/*!
	@brief The CSR True Wireless Stereo Codec ID for SBC.
*/
const uint8 tws_sbc_caps[26] =
{
    AVDTP_SERVICE_MEDIA_TRANSPORT,
    0,
    AVDTP_SERVICE_MEDIA_CODEC,
    16,	/* Length */
    AVDTP_MEDIA_TYPE_AUDIO << 2,
    AVDTP_MEDIA_CODEC_NONA2DP,

    (A2DP_CSR_VENDOR_ID >> 24) & 0xFF,
    (A2DP_CSR_VENDOR_ID >> 16) & 0xFF,
    (A2DP_CSR_VENDOR_ID >>  8) & 0xFF,
    (A2DP_CSR_VENDOR_ID >>  0) & 0xFF,

    (A2DP_CSR_TWS_SBC_CODEC_ID >> 8) & 0xFF,
    (A2DP_CSR_TWS_SBC_CODEC_ID >> 0) & 0xFF,
    
    /* Embed SBC capabilities */
    AVDTP_SERVICE_MEDIA_CODEC,
    6,	/* Length */
    AVDTP_MEDIA_TYPE_AUDIO << 2,
    AVDTP_MEDIA_CODEC_SBC,
    SBC_SAMPLING_FREQ_16000     | SBC_SAMPLING_FREQ_32000    | SBC_SAMPLING_FREQ_44100    | SBC_SAMPLING_FREQ_48000    |
    SBC_CHANNEL_MODE_MONO       | SBC_CHANNEL_MODE_DUAL_CHAN | SBC_CHANNEL_MODE_STEREO    | SBC_CHANNEL_MODE_JOINT_STEREO,

    SBC_BLOCK_LENGTH_4          | SBC_BLOCK_LENGTH_8         | SBC_BLOCK_LENGTH_12        | SBC_BLOCK_LENGTH_16        |
    SBC_SUBBANDS_4              | SBC_SUBBANDS_8             | SBC_ALLOCATION_SNR         | SBC_ALLOCATION_LOUDNESS,

    SBC_BITPOOL_MIN,
    SBC_BITPOOL_HIGH_QUALITY,

    AVDTP_SERVICE_CONTENT_PROTECTION,
    2,
    AVDTP_CP_TYPE_SCMS_LSB,
    AVDTP_CP_TYPE_SCMS_MSB,
	
    AVDTP_SERVICE_DELAY_REPORTING,
    0
};


/*!
	@brief The CSR True Wireless Stereo Codec ID for MP3.
*/
const uint8 tws_mp3_caps[26] =
{
    AVDTP_SERVICE_MEDIA_TRANSPORT,
    0,
    AVDTP_SERVICE_MEDIA_CODEC,
    16,	/* Length */
    AVDTP_MEDIA_TYPE_AUDIO << 2,
    AVDTP_MEDIA_CODEC_NONA2DP,

    (A2DP_CSR_VENDOR_ID >> 24) & 0xFF,
    (A2DP_CSR_VENDOR_ID >> 16) & 0xFF,
    (A2DP_CSR_VENDOR_ID >>  8) & 0xFF,
    (A2DP_CSR_VENDOR_ID >>  0) & 0xFF,

    (A2DP_CSR_TWS_MP3_CODEC_ID >> 8) & 0xFF,
    (A2DP_CSR_TWS_MP3_CODEC_ID >> 0) & 0xFF,
    
    /* Embed MP3 capabilities */
    AVDTP_SERVICE_MEDIA_CODEC,
    6,	/* Length */
    AVDTP_MEDIA_TYPE_AUDIO << 2,
    AVDTP_MEDIA_CODEC_MPEG1_2_AUDIO,
    
    MP3_LAYER_III              | MP3_CRC_PROTECTION          |
    MP3_CHANNEL_MODE_MONO      | MP3_CHANNEL_MODE_DUAL_CHAN  | MP3_CHANNEL_MODE_STEREO     | MP3_CHANNEL_MODE_JOINT_STEREO,
	
    MP3_SAMPLING_FREQ_32000    | MP3_SAMPLING_FREQ_44100     | MP3_SAMPLING_FREQ_48000,
	
    MP3_VBR                    | MP3_BITRATE_VALUE_1110      | MP3_BITRATE_VALUE_1101      | MP3_BITRATE_VALUE_1100    |
    MP3_BITRATE_VALUE_1011     | MP3_BITRATE_VALUE_1010      | MP3_BITRATE_VALUE_1001      | MP3_BITRATE_VALUE_1000,
	
    MP3_BITRATE_VALUE_0111     | MP3_BITRATE_VALUE_0110      | MP3_BITRATE_VALUE_0101      | MP3_BITRATE_VALUE_0100    |
    MP3_BITRATE_VALUE_0011     | MP3_BITRATE_VALUE_0010      | MP3_BITRATE_VALUE_0001,    /* All bit rates except 'free' */
    
    AVDTP_SERVICE_CONTENT_PROTECTION,
    2,
    AVDTP_CP_TYPE_SCMS_LSB,
    AVDTP_CP_TYPE_SCMS_MSB,
	
    AVDTP_SERVICE_DELAY_REPORTING,
    0
};


/*!
	@brief The CSR True Wireless Stereo Codec ID for AAC.
*/
const uint8 tws_aac_caps[28] = 
{
    AVDTP_SERVICE_MEDIA_TRANSPORT,
    0,
    AVDTP_SERVICE_MEDIA_CODEC,
    18,	/* Length */
    AVDTP_MEDIA_TYPE_AUDIO << 2,
    AVDTP_MEDIA_CODEC_NONA2DP,

    (A2DP_CSR_VENDOR_ID >> 24) & 0xFF,
    (A2DP_CSR_VENDOR_ID >> 16) & 0xFF,
    (A2DP_CSR_VENDOR_ID >>  8) & 0xFF,
    (A2DP_CSR_VENDOR_ID >>  0) & 0xFF,

    (A2DP_CSR_TWS_AAC_CODEC_ID >> 8) & 0xFF,
    (A2DP_CSR_TWS_AAC_CODEC_ID >> 0) & 0xFF,
    
    /* Embed AAC capabilities */
    AVDTP_SERVICE_MEDIA_CODEC,
    8,
    AVDTP_MEDIA_TYPE_AUDIO<<2,
    AVDTP_MEDIA_CODEC_MPEG2_4_AAC,

    AAC_MPEG2_AAC_LC | AAC_MPEG4_AAC_LC,
    AAC_SAMPLE_8000 | AAC_SAMPLE_11025 | AAC_SAMPLE_12000 | AAC_SAMPLE_16000 | AAC_SAMPLE_22050 | AAC_SAMPLE_24000 | AAC_SAMPLE_32000 | AAC_SAMPLE_44100,
    AAC_SAMPLE_48000 | AAC_CHANNEL_1 | AAC_CHANNEL_2,
    AAC_VBR | AAC_BITRATE_256_3,
    AAC_BITRATE_256_4,
    AAC_BITRATE_256_5,

    AVDTP_SERVICE_CONTENT_PROTECTION,
    2,
    AVDTP_CP_TYPE_SCMS_LSB,
    AVDTP_CP_TYPE_SCMS_MSB,
	
    AVDTP_SERVICE_DELAY_REPORTING,
    0
};


/*!
	@brief The CSR True Wireless Stereo Codec ID for AptX.
*/

/*! @name Common APTX configuration bit fields 
*/
/*@{ */
#define APTX_SAMPLING_FREQ_44100         32
#define APTX_SAMPLING_FREQ_48000         16
#define APTX_CHANNEL_MODE_STEREO          2
/*@} */

const uint8 tws_aptx_caps[29] =
{
    AVDTP_SERVICE_MEDIA_TRANSPORT,
    0,
    AVDTP_SERVICE_MEDIA_CODEC,
    19,	/* Length */
    AVDTP_MEDIA_TYPE_AUDIO << 2,
    AVDTP_MEDIA_CODEC_NONA2DP,

    (A2DP_CSR_VENDOR_ID >> 24) & 0xFF,
    (A2DP_CSR_VENDOR_ID >> 16) & 0xFF,
    (A2DP_CSR_VENDOR_ID >>  8) & 0xFF,
    (A2DP_CSR_VENDOR_ID >>  0) & 0xFF,

    (A2DP_CSR_TWS_APTX_CODEC_ID >> 8) & 0xFF,
    (A2DP_CSR_TWS_APTX_CODEC_ID >> 0) & 0xFF,
    
    /* Embed AptX capabilities */
    AVDTP_SERVICE_MEDIA_CODEC,
    9,
    AVDTP_MEDIA_TYPE_AUDIO<<2,
    AVDTP_MEDIA_CODEC_NONA2DP,
    
    (A2DP_APT_VENDOR_ID >> 24) & 0xFF,
    (A2DP_APT_VENDOR_ID >> 16) & 0xFF,
    (A2DP_APT_VENDOR_ID >>  8) & 0xFF,
    (A2DP_APT_VENDOR_ID >>  0) & 0xFF,

    (A2DP_CSR_APTX_CODEC_ID >> 8) & 0xFF,
    (A2DP_CSR_APTX_CODEC_ID >> 0) & 0xFF,
    
    APTX_SAMPLING_FREQ_44100 + APTX_SAMPLING_FREQ_48000 +
    APTX_CHANNEL_MODE_STEREO,

    AVDTP_SERVICE_CONTENT_PROTECTION,
    2,
    AVDTP_CP_TYPE_SCMS_LSB,
    AVDTP_CP_TYPE_SCMS_MSB,
	
    AVDTP_SERVICE_DELAY_REPORTING,
    0
};


/****************************************************************************
DESCRIPTION
	The main task message handler
*/
static void message_handler ( Task task, MessageId id, Message message ) 
{
	if ( (id >= AUDIO_DOWNSTREAM_MESSAGE_BASE ) && (id <= AUDIO_DOWNSTREAM_MESSAGE_TOP) )
	{
		handleAudioMessage (task , id, message ) ;
	}
	else
	{
		handleInternalMessage (task , id , message ) ;
	}
}	

/****************************************************************************
DESCRIPTION

	messages from the audio library are received here. 
	and converted into function calls to be implemented in the 
	plugin module
*/ 
static void handleAudioMessage ( Task task , MessageId id, Message message ) 	
{
	switch (id)
	{
		case (AUDIO_PLUGIN_CONNECT_MSG ):
		{
			AUDIO_PLUGIN_CONNECT_MSG_T * connect_message = (AUDIO_PLUGIN_CONNECT_MSG_T *)message ;

            /* ensure dsp is available for use before connecting */
			if (IsAudioBusy() )
			{ 		/*Queue the connect message until the audio task is available*/
				MAKE_AUDIO_MESSAGE( AUDIO_PLUGIN_CONNECT_MSG ) ; 
				
				message->audio_sink = connect_message->audio_sink ;
				message->sink_type  = connect_message->sink_type ;
				message->codec_task = connect_message->codec_task ;
				message->volume     = connect_message->volume ;
				message->rate       = connect_message->rate ;
				message->mode 		= connect_message->mode ;
                message->route 	    = connect_message->route ;				
				message->features   = connect_message->features ;
				message->params     = connect_message->params ;
                message->app_task	= connect_message->app_task ;
				
                MessageSendConditionally ( task, AUDIO_PLUGIN_CONNECT_MSG , message , (const uint16 *)AudioBusyPtr()) ;
			} 
			else
			{		/*connect the audio*/
				CsrA2dpDecoderPluginConnect(  (A2dpPluginTaskdata*)task,
                                               connect_message->audio_sink , 
                                               connect_message->sink_type ,
                                               connect_message->codec_task ,
                                               connect_message->volume , 
                                               connect_message->rate , 
                                               connect_message->features ,
                                               connect_message->mode   ,
                                               connect_message->params ,
                                               connect_message->app_task ) ;            
			}			
		}	
		break ;
		
        /* start the disconnect procedure, issue mute then unload dsp */
		case (AUDIO_PLUGIN_DISCONNECT_MSG ):
		{
			if (IsAudioBusy())
			{
				MessageSendConditionally ( task, AUDIO_PLUGIN_DISCONNECT_MSG , 0 ,(const uint16 *)AudioBusyPtr() ) ;
    		}
			else
			{
                /* begin muting the output to disconnect the audio */
                CsrA2dpDecoderPluginStartDisconnect(task);
			}
		}	
		break ;
        
        /* disconnect the streams and unload kalimba once muted */
        case AUDIO_PLUGIN_DISCONNECT_DELAYED_MSG:
		{
    		CsrA2dpDecoderPluginDisconnect((A2dpPluginTaskdata*)task) ;
		}	
        break;
		
		case (AUDIO_PLUGIN_SET_MODE_MSG ):
		{
            AUDIO_PLUGIN_SET_MODE_MSG_T * mode_message = (AUDIO_PLUGIN_SET_MODE_MSG_T *)message ;			
			
            if (IsAudioBusy())
            {
                MAKE_AUDIO_MESSAGE ( AUDIO_PLUGIN_SET_MODE_MSG) ;
                /* check message is valid */                
                if(mode_message)                
                {
                    message->mode   = mode_message->mode ;
                    message->params = mode_message->params ;
                }
                /* default to connected mode */
                else
                {
                    message->mode   = AUDIO_MODE_CONNECTED ;
                    message->params = NULL;
                }
        
        		MessageSendConditionally ( task, AUDIO_PLUGIN_SET_MODE_MSG , message ,(const uint16 *)AudioBusyPtr() ) ;
    	    }
            else
            {
                CsrA2dpDecoderPluginSetMode(mode_message->mode , (A2dpPluginTaskdata*)task , mode_message->params) ;
            }
		}
		break ;        
		
        /* message from VM application via audio lib to configure the sub woofer, this could be
           an enable or disable indication along with sub woofer link type, esco or l2cap */
        case (AUDIO_PLUGIN_SET_SUB_WOOFER_MSG ):
		{
            AUDIO_PLUGIN_SET_SUB_WOOFER_MSG_T * sub_message = (AUDIO_PLUGIN_SET_SUB_WOOFER_MSG_T *)message ;			
			
            if ((IsAudioBusy())||(IsTonePlaying()))
            {
                MAKE_AUDIO_MESSAGE ( AUDIO_PLUGIN_SET_SUB_WOOFER_MSG ) ;
                message->sub_woofer_type   = sub_message->sub_woofer_type ;
                message->sub_sink = sub_message->sub_sink ;
        
        		MessageSendConditionally ( task, AUDIO_PLUGIN_SET_SUB_WOOFER_MSG , message ,(const uint16 *)AudioBusyPtr() ) ;
    	    }
            else
            {
                CsrA2dpDecoderPluginSetSubWoofer(sub_message->sub_woofer_type , sub_message->sub_sink) ;
            }
		}
		break ;    
        
        /* Message from VM application via audio lib to configure the mute state of the sink, this could be to either:
            mute the sink output but not subwoofer
            mute the subwoofer output but not subwoofer
            mute both sink and subwoofer
            unmute both sink and subwoofer */
        case (AUDIO_PLUGIN_SET_SOFT_MUTE_MSG ):
        {
            AUDIO_PLUGIN_SET_SOFT_MUTE_MSG_T * mute_message = (AUDIO_PLUGIN_SET_SOFT_MUTE_MSG_T *)message ;
            
            if (IsAudioBusy())
            {
                MAKE_AUDIO_MESSAGE ( AUDIO_PLUGIN_SET_SOFT_MUTE_MSG ) ;
                message->mute_mode_type = mute_message->mute_mode_type ;
        
        		MessageSendConditionally ( task, AUDIO_PLUGIN_SET_SOFT_MUTE_MSG , message ,(const uint16 *)AudioBusyPtr() ) ;
            }
            else
            {
                CsrA2dpDecoderPluginSetSoftMute(mute_message->mute_mode_type);
            }
        }
        break ;

        /* allow volume messages to be processed by releasing the audio busy flag lock */
        case (AUDIO_PLUGIN_ALLOW_VOLUME_CHANGES_MSG) :
        {
            /* release the lock on setting volume changes to allow smooth volume ramping */
            CsrA2dpDecoderPluginAllowVolChanges();
        }
        break;

        /* should the subwoofer fail to open a media channel within a timeout period begin the unmuting
           procedure anyway to prevent stalled audio connection */
        case (AUDIO_PLUGIN_SUBWOOFER_CONNECTION_TIMEOUT_MSG):
        {
            /* check if sub connected port within timeout period */
            CsrA2dpDecoderPluginSubCheckForConnectionFailure();
        }
        break;
        
        case (AUDIO_PLUGIN_SET_VOLUME_A2DP_MSG ): 
		{
            /* Handling plug-in set volume message */
    		AUDIO_PLUGIN_SET_VOLUME_A2DP_MSG_T * volume_message = (AUDIO_PLUGIN_SET_VOLUME_A2DP_MSG_T *)message ;

			PRINT(("A2DP: Set A2DP volume\n"));	
			
			if (IsAudioBusy())
			{
				MAKE_AUDIO_MESSAGE (AUDIO_PLUGIN_SET_VOLUME_A2DP_MSG ) ;
                
                /* create message containing passed in volume information stucture */
                memcpy(message, volume_message, sizeof(AUDIO_PLUGIN_SET_VOLUME_A2DP_MSG_T));       
                
                MessageSendConditionally ( task, AUDIO_PLUGIN_SET_VOLUME_A2DP_MSG , message ,(const uint16 *)AudioBusyPtr() ) ;
			}
			else
			{
				CsrA2dpDecoderPluginSetVolume (volume_message) ;
			}
		}
		break ;
        
		case (AUDIO_PLUGIN_RESET_VOLUME_MSG ): 
		{
			if (IsAudioBusy())
			{
		         MessageSendConditionally ( task, AUDIO_PLUGIN_RESET_VOLUME_MSG , 0 ,(const uint16 *)AudioBusyPtr() ) ;    	
            }
            else
            {
                CsrA2dpDecoderPluginResetVolume () ;
            }			
		}		
		break ;
        
		
        case (AUDIO_PLUGIN_SET_ROUTE_MSG ):
			/* Routing is fixed in this plugin - ignore */				
		break ;
        
		case (AUDIO_PLUGIN_START_FORWARDING_MSG ):
		{
			AUDIO_PLUGIN_START_FORWARDING_MSG_T * fwd_msg = (AUDIO_PLUGIN_START_FORWARDING_MSG_T *)message ;
            
			if (IsAudioBusy())
            {
                MAKE_AUDIO_MESSAGE( AUDIO_PLUGIN_START_FORWARDING_MSG ); 
                message->forwarding_sink = fwd_msg->forwarding_sink;
                message->content_protection = fwd_msg->content_protection;
                MessageSendConditionally ( task, AUDIO_PLUGIN_START_FORWARDING_MSG, message , (const uint16 *)AudioBusyPtr());
            }
            else
			{
				CsrA2dpDecoderPluginForwardUndecoded((A2dpPluginTaskdata *)task, TRUE, fwd_msg->forwarding_sink, fwd_msg->content_protection) ;
			}
		}
		break ;		
		
		case (AUDIO_PLUGIN_STOP_FORWARDING_MSG ):
		{
			if (IsAudioBusy())
            {
                MessageSendConditionally ( task, AUDIO_PLUGIN_STOP_FORWARDING_MSG, 0, (const uint16 *)AudioBusyPtr());
            }
            else
			{
				CsrA2dpDecoderPluginForwardUndecoded((A2dpPluginTaskdata *)task, FALSE, NULL, 0) ;
			}
		}
		break ;		
		
		case (AUDIO_PLUGIN_PLAY_TONE_MSG ):
		{
			AUDIO_PLUGIN_PLAY_TONE_MSG_T * tone_message = (AUDIO_PLUGIN_PLAY_TONE_MSG_T *)message ;
			
			if (IsAudioBusy()) 
			{	
				if ( tone_message->can_queue) /*then re-queue the tone*/
				{				
					MAKE_AUDIO_MESSAGE( AUDIO_PLUGIN_PLAY_TONE_MSG ) ; 
					
					message->tone        = tone_message->tone       ;
					message->can_queue   = tone_message->can_queue  ;
					message->codec_task  = tone_message->codec_task ;
					message->tone_volume = tone_message->tone_volume;
					message->features    = tone_message->features   ;
	
					PRINT(("TONE:Q\n"));
					
					MessageSendConditionally ( task , AUDIO_PLUGIN_PLAY_TONE_MSG, message ,(const uint16 *)AudioBusyPtr() ) ;			
				}
			}
			else
			{
				PRINT(("TONE A2DP:start\n"));				
                SetAudioBusy((TaskData*) task);    
        		CsrA2dpDecoderPluginPlayTone ((A2dpPluginTaskdata*)task, tone_message->tone, tone_message->codec_task, tone_message->tone_volume, tone_message->features.stereo) ;		     				
			}						     
		}
		break ;
		
		case (AUDIO_PLUGIN_STOP_TONE_MSG ):
		{
			if (IsAudioBusy())
			{
				CsrA2dpDecoderPluginStopTone() ;
			}
		}
		break ;		
		
        case (AUDIO_PLUGIN_DELAY_VOLUME_SET_MSG):
        {
    		AUDIO_PLUGIN_SET_VOLUME_A2DP_MSG_T * volume_message = (AUDIO_PLUGIN_SET_VOLUME_A2DP_MSG_T *)message ;
                       
            CsrA2dpDecoderPluginSetDspLevels(volume_message);            
        }
        break;
		
		case (AUDIO_PLUGIN_SET_VOLUME_MSG ): 
		{
			PRINT(("A2DP: Set volume not used in this plugin\n"));	
		}
		break;
        
		default:
		{
		}
		break ;
	}
}

/****************************************************************************
DESCRIPTION
	Internal messages to the task are handled here
*/ 
static void handleInternalMessage ( Task task , MessageId id, Message message ) 	
{   
   switch (id)
	{
      case MESSAGE_STREAM_DISCONNECT:
      {
      }
      break;
      
      default:
	  {
		    /*route the dsp messages to the relavent handler*/
			CsrA2dpDecoderPluginInternalMessage( (A2dpPluginTaskdata*)task , id , message ) ;        
	  }
	  break ;
	}	
      
}

/****************************************************************************
DESCRIPTION
	get the current sample rate if available
*/ 
uint32 AudioGetA2DPSampleRate(void)
{
    return CsrA2DPGetDecoderSampleRate();
}

/****************************************************************************
DESCRIPTION
	get the current subwoofer sample rate if available
*/ 
uint32 AudioGetA2DPSubwooferSampleRate(void)
{
    return CsrA2DPGetDecoderSubwooferSampleRate();
}     
        
/****************************************************************************
DESCRIPTION
	Get current/estimated latency measurement for specified plugin
*/ 
bool AudioGetLatency (Task audio_plugin, bool *estimated, uint16 *latency)
{
	return CsrA2dpDecoderPluginGetLatency((A2dpPluginTaskdata *)audio_plugin, estimated, latency);
}
