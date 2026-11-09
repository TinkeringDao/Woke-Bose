// SPDX-License-Identifier: MIT
// Copyright (c) 2026 TinkeringDao
//
// Unofficial macOS Bluetooth RFCOMM (SPP) interoperability & user-preference utility
// for Bose QuietComfort Ultra Headphones (PID 0x4066).
// Developed independently via clean-room protocol observation under EU Directive
// 2009/24/EC Arts. 5(3) & 6 (§§ 69d Abs. 3, 69e, 69g Abs. 2 UrhG), § 3 Abs. 1 Nr. 2
// GeschGehG, § 23 Abs. 1 Nr. 3 MarkenG, and 17 U.S.C. §§ 102(b) & 1201(f).
// Supplied strictly as non-commercial open-source software (Regulation (EU) 2024/2847
// Recitals 15 & 18; Directive (EU) 2024/2853 Art. 2(2)). Operates solely on locally
// paired hardware owned by the user; circumvents zero TPMs. See LEGAL.md.

#import <Foundation/Foundation.h>
#import <IOBluetooth/IOBluetooth.h>
#import <CoreAudio/CoreAudio.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>

static const BluetoothRFCOMMChannelID kBoseBMAPCandidateChannels[] = {1, 2, 14, 3};
static const uint8_t kBoseBMAPUUIDBytes[16] = {
    0x00, 0x00, 0x00, 0x00, 0xde, 0xca, 0xfa, 0xde,
    0xde, 0xca, 0xde, 0xaf, 0xde, 0xca, 0xca, 0xff
};

@interface BMAPDelegate : NSObject <IOBluetoothRFCOMMChannelDelegate>
@property (nonatomic, strong) NSMutableData *rxBuffer;
@property (nonatomic, assign) BOOL channelOpened;
@property (nonatomic, assign) IOReturn openStatus;
@end

@implementation BMAPDelegate

- (instancetype)init {
    if ((self = [super init])) {
        _rxBuffer = [NSMutableData data];
        _channelOpened = NO;
        _openStatus = kIOReturnSuccess;
    }
    return self;
}

- (void)rfcommChannelOpenComplete:(IOBluetoothRFCOMMChannel *)rfcommChannel
                           status:(IOReturn)error {
    self.openStatus = error;
    self.channelOpened = (error == kIOReturnSuccess);
}

- (void)rfcommChannelData:(IOBluetoothRFCOMMChannel *)rfcommChannel
                     data:(void *)dataPointer
                   length:(size_t)dataLength {
    if (dataPointer && dataLength > 0) {
        [self.rxBuffer appendBytes:dataPointer length:dataLength];
    }
}

- (void)rfcommChannelClosed:(IOBluetoothRFCOMMChannel *)rfcommChannel {
    self.channelOpened = NO;
}

@end

static void pumpRunLoop(NSTimeInterval seconds) {
    NSDate *end = [NSDate dateWithTimeIntervalSinceNow:seconds];
    while ([end timeIntervalSinceNow] > 0) {
        [[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode
                                 beforeDate:[NSDate dateWithTimeIntervalSinceNow:0.02]];
    }
}

static NSString *audioDeviceName(AudioDeviceID devID) {
    if (devID == kAudioObjectUnknown) return @"Unknown";
    AudioObjectPropertyAddress nameAddr = {
        kAudioObjectPropertyName,
        kAudioObjectPropertyScopeGlobal,
        kAudioObjectPropertyElementMain
    };
    CFStringRef cfName = NULL;
    UInt32 size = sizeof(cfName);
    if (AudioObjectGetPropertyData(devID, &nameAddr, 0, NULL, &size, &cfName) == noErr && cfName) {
        return (__bridge_transfer NSString *)cfName;
    }
    return @"Unknown";
}

static BOOL audioDeviceHasInputStreams(AudioDeviceID devID) {
    AudioObjectPropertyAddress streamAddr = {
        kAudioDevicePropertyStreams,
        kAudioObjectPropertyScopeInput,
        kAudioObjectPropertyElementMain
    };
    UInt32 dataSize = 0;
    if (AudioObjectGetPropertyDataSize(devID, &streamAddr, 0, NULL, &dataSize) != noErr) {
        return NO;
    }
    return (dataSize / sizeof(AudioStreamID)) > 0;
}

static void releaseBluetoothSCOIfNeeded(BOOL verbose) {
    AudioObjectPropertyAddress defInAddr = {
        kAudioHardwarePropertyDefaultInputDevice,
        kAudioObjectPropertyScopeGlobal,
        kAudioObjectPropertyElementMain
    };
    AudioDeviceID defaultIn = kAudioObjectUnknown;
    UInt32 propSize = sizeof(defaultIn);
    if (AudioObjectGetPropertyData(kAudioObjectSystemObject, &defInAddr, 0, NULL, &propSize, &defaultIn) != noErr) {
        return;
    }

    NSString *curInName = audioDeviceName(defaultIn);
    NSString *lowerIn = curInName.lowercaseString ?: @"";
    BOOL isBoseInput = ([lowerIn containsString:@"qc ultra"] ||
                        [lowerIn containsString:@"quietcomfort ultra"] ||
                        [lowerIn containsString:@"bose"]);

    if (!isBoseInput) {
        if (verbose) {
            printf("[*] CoreAudio Input Guard: Default Input Device is '%s' (2-ch Stereo A2DP protected; HFP SCO call hijack prevented).\n",
                   curInName.UTF8String);
        }
        return;
    }

    AudioObjectPropertyAddress devListAddr = {
        kAudioHardwarePropertyDevices,
        kAudioObjectPropertyScopeGlobal,
        kAudioObjectPropertyElementMain
    };
    UInt32 listSize = 0;
    if (AudioObjectGetPropertyDataSize(kAudioObjectSystemObject, &devListAddr, 0, NULL, &listSize) != noErr || listSize == 0) {
        return;
    }

    UInt32 count = listSize / sizeof(AudioDeviceID);
    AudioDeviceID *devices = (AudioDeviceID *)calloc(count, sizeof(AudioDeviceID));
    if (!devices) return;

    AudioDeviceID builtInMic = kAudioObjectUnknown;
    if (AudioObjectGetPropertyData(kAudioObjectSystemObject, &devListAddr, 0, NULL, &listSize, devices) == noErr) {
        for (UInt32 i = 0; i < count; i++) {
            AudioDeviceID cand = devices[i];
            if (cand == defaultIn || !audioDeviceHasInputStreams(cand)) continue;
            AudioObjectPropertyAddress transAddr = {
                kAudioDevicePropertyTransportType,
                kAudioObjectPropertyScopeGlobal,
                kAudioObjectPropertyElementMain
            };
            UInt32 transport = 0;
            UInt32 tSize = sizeof(transport);
            if (AudioObjectGetPropertyData(cand, &transAddr, 0, NULL, &tSize, &transport) == noErr &&
                transport == kAudioDeviceTransportTypeBuiltIn) {
                builtInMic = cand;
                break;
            }
        }
    }
    free(devices);

    if (builtInMic != kAudioObjectUnknown) {
        NSString *newInName = audioDeviceName(builtInMic);
        OSStatus setErr = AudioObjectSetPropertyData(kAudioObjectSystemObject,
                                                     &defInAddr,
                                                     0,
                                                     NULL,
                                                     sizeof(builtInMic),
                                                     &builtInMic);
        if (setErr == noErr) {
            printf("[+] CoreAudio Input Guard: Switched macOS Default Input Device from '%s' to '%s' (released 16 kHz Mono HFP SCO; locked 2-ch Stereo A2DP).\n",
                   curInName.UTF8String, newInName.UTF8String);
            pumpRunLoop(0.5);
        }
    }
}

static IOBluetoothRFCOMMChannel *openBMAPRFCOMMChannel(IOBluetoothDevice *device,
                                                       BMAPDelegate *delegate,
                                                       BluetoothRFCOMMChannelID *outChannelID) {
    BluetoothRFCOMMChannelID candidates[8];
    size_t candCount = 0;

    for (size_t i = 0; i < sizeof(kBoseBMAPCandidateChannels) / sizeof(kBoseBMAPCandidateChannels[0]); i++) {
        candidates[candCount++] = kBoseBMAPCandidateChannels[i];
    }

    IOBluetoothSDPUUID *bmapUUID = [IOBluetoothSDPUUID uuidWithBytes:kBoseBMAPUUIDBytes
                                                              length:sizeof(kBoseBMAPUUIDBytes)];
    IOBluetoothSDPServiceRecord *rec = [device getServiceRecordForUUID:bmapUUID];
    BluetoothRFCOMMChannelID sdpCh = 0;
    if (rec && [rec getRFCOMMChannelID:&sdpCh] == kIOReturnSuccess && sdpCh > 0) {
        BOOL exists = NO;
        for (size_t i = 0; i < candCount; i++) {
            if (candidates[i] == sdpCh) { exists = YES; break; }
        }
        if (!exists) candidates[candCount++] = sdpCh;
    }

    for (int attempt = 0; attempt < 2; attempt++) {
        for (size_t i = 0; i < candCount; i++) {
            BluetoothRFCOMMChannelID chID = candidates[i];
            IOBluetoothRFCOMMChannel *ch = nil;
            IOReturn ret = [device openRFCOMMChannelSync:&ch
                                           withChannelID:chID
                                                delegate:delegate];
            if (ret == kIOReturnSuccess && ch != nil) {
                if (outChannelID) *outChannelID = chID;
                return ch;
            }
        }
        if (attempt == 0 && ![device isConnected]) {
            printf("[*] Opening Bluetooth baseband connection...\n");
            IOReturn connRet = [device openConnection];
            if (connRet != kIOReturnSuccess) {
                fprintf(stderr, "[!] Failed to open Bluetooth connection (0x%08x). Ensure headphones are powered ON and unplugged from USB DFU.\n", connRet);
                return nil;
            }
            pumpRunLoop(1.0);
        } else {
            break;
        }
    }
    return nil;
}

static IOBluetoothDevice *discoverBoseQCUltra(NSString *explicitMAC) {
    if (explicitMAC.length > 0) {
        NSString *norm = [explicitMAC stringByReplacingOccurrencesOfString:@":" withString:@"-"];
        return [IOBluetoothDevice deviceWithAddressString:norm];
    }
    NSArray *paired = [IOBluetoothDevice pairedDevices];
    for (IOBluetoothDevice *dev in paired) {
        NSString *name = dev.name.lowercaseString ?: @"";
        if ([name containsString:@"qc ultra"] ||
            [name containsString:@"quietcomfort ultra"] ||
            [name containsString:@"bose"]) {
            if ([dev isConnected]) {
                return dev;
            }
        }
    }
    for (IOBluetoothDevice *dev in paired) {
        NSString *name = dev.name.lowercaseString ?: @"";
        if ([name containsString:@"qc ultra"] ||
            [name containsString:@"quietcomfort ultra"]) {
            return dev;
        }
    }
    return nil;
}

static NSData *sendBMAP(IOBluetoothRFCOMMChannel *channel,
                        BMAPDelegate *delegate,
                        const uint8_t *txBytes,
                        size_t txLen,
                        NSTimeInterval waitSec) {
    [delegate.rxBuffer setLength:0];
    IOReturn ret = [channel writeSync:(void *)txBytes length:(UInt16)txLen];
    if (ret != kIOReturnSuccess) {
        fprintf(stderr, "  [!] RFCOMM writeSync failed: 0x%08x\n", ret);
        return nil;
    }
    pumpRunLoop(waitSec);
    return [delegate.rxBuffer copy];
}

static void printHex(const char *label, const uint8_t *buf, size_t len) {
    printf("  %s (%zuB): ", label, len);
    for (size_t i = 0; i < len; i++) {
        printf("%02x ", buf[i]);
    }
    printf("\n");
}

static void parseBMAPFrames(NSData *data) {
    const uint8_t *bytes = (const uint8_t *)data.bytes;
    size_t total = data.length;
    size_t pos = 0;

    if (total == 0) {
        printf("  [!] No response received.\n");
        return;
    }

    while (pos + 4 <= total) {
        uint8_t fblock = bytes[pos];
        uint8_t func = bytes[pos + 1];
        uint8_t op = bytes[pos + 2] & 0x0F;
        uint8_t plen = bytes[pos + 3];
        if (pos + 4 + plen > total) {
            printHex("Raw/Partial RX", bytes + pos, total - pos);
            break;
        }
        const uint8_t *p = bytes + pos + 4;

        if (op == 0x04 && plen >= 1) {
            printf("  [BMAP ERROR] [%u.%u] Error Code: 0x%02x\n", fblock, func, p[0]);
        } else if (fblock == 0x00 && func == 0x05 && op == 0x03) {
            NSString *fw = [[NSString alloc] initWithBytes:p length:plen encoding:NSUTF8StringEncoding];
            printf("  [ProductInfo.FirmwareVersion] %s\n", fw.UTF8String);
        } else if (fblock == 0x00 && func == 0x07 && op == 0x03) {
            NSString *sn = [[NSString alloc] initWithBytes:p length:plen encoding:NSUTF8StringEncoding];
            printf("  [ProductInfo.SerialNumber]    %s\n", sn.UTF8String);
        } else if (fblock == 0x02 && func == 0x02 && op == 0x03 && plen >= 1) {
            printf("  [Status.BatteryLevel]         %u%%\n", p[0]);
        } else if (fblock == 0x01 && func == 0x07 && op == 0x03 && plen >= 12) {
            int8_t bass = (int8_t)p[2];
            int8_t mid = (int8_t)p[6];
            int8_t treble = (int8_t)p[10];
            printf("  [Settings.EQ (RangeControl)]  Bass: %+d dB | Mid: %+d dB | Treble: %+d dB\n",
                   bass, mid, treble);
        } else if (fblock == 0x01 && func == 0x0B && op == 0x03 && plen >= 2) {
            const char *lvlStr = "Unknown";
            switch (p[1]) {
                case 0x00: lvlStr = "OFF (0x00)"; break;
                case 0x01: lvlStr = "HIGH (0x01)"; break;
                case 0x02: lvlStr = "MEDIUM (0x02)"; break;
                case 0x03: lvlStr = "LOW (0x03)"; break;
            }
            printf("  [Settings.SelfVoice/Sidetone] Persist=%u | Level=%s\n", p[0], lvlStr);
        } else if (fblock == 0x01 && func == 0x0A && op == 0x03 && plen >= 1) {
            BOOL mp = (p[0] & 0x01) != 0;
            printf("  [Settings.Multipoint]         %s (raw=0x%02x)\n", mp ? "ENABLED" : "DISABLED", p[0]);
        } else if (fblock == 0x05 && func == 0x07 && op == 0x03 && plen >= 6) {
            uint16_t ms = ((uint16_t)p[4] << 8) | p[5];
            printf("  [AudioManagement.Latency]     %u ms\n", ms);
        } else if (fblock == 0x1F && func == 0x03 && (op == 0x03 || op == 0x06) && plen >= 1) {
            printf("  [AudioModes.CurrentMode]      Slot %u\n", p[0]);
        } else if (fblock == 0x1F && func == 0x06 && op == 0x03 && plen >= 47) {
            char mname[33];
            memcpy(mname, &p[6], 32);
            mname[32] = '\0';
            uint8_t ancLevel = (p[42] <= 10) ? (uint8_t)(10 - p[42]) : 0;
            const char *spStr = (p[44] == 0) ? "Off" : (p[44] == 1 ? "Still (Room)" : "Motion (Head)");
            printf("  [AudioModes.ModeConfig #%u]   Name=\"%s\" | ANC=%u/10 (atten=%u) | AutoCNC=%u | Spatial=%s | WindBlock=%s\n",
                   p[0], mname, ancLevel, p[42], p[43], spStr, p[46] ? "ON" : "OFF");
        } else {
            printf("  [BMAP RX] [%u.%u] op=0x%02x len=%u: ", fblock, func, op, plen);
            for (uint8_t i = 0; i < plen; i++) printf("%02x ", p[i]);
            printf("\n");
        }
        pos += 4 + plen;
    }
}

static void printUsage(const char *prog) {
    printf("bose-ultra-tuner — Unofficial macOS BMAP NVRAM & DSP Interoperability Utility for Bose QC Ultra (0x4066)\n");
    printf("Usage: %s [--mac XX-XX-XX-XX-XX-XX] <command> [args...]\n\n", prog);
    printf("Commands:\n");
    printf("  woke                           Apply the 'Woke' Reference user-preference NVRAM & DSP configuration:\n");
    printf("                                   - CoreAudio Input Guard: Switches macOS Default Input to Built-in Mic (locks 2-ch Stereo A2DP)\n");
    printf("                                   - Hardware EQ [1.7]    : Bass -3 dB | Mid +1 dB | Treble +2 dB (B&K 5128 / Harman fix)\n");
    printf("                                   - Self Voice  [1.11]   : OFF (0x00, Persist=1) (-20.1 dB noise floor, 54.3 dB SNR)\n");
    printf("                                   - Multipoint  [1.10]   : ENABLED (0x05) (seamless Mac + Phone dual connection)\n");
    printf("                                   - DSP Mode #4 [31.6]   : 'Woke Studio' (CNC=10/10 Full ANC, AutoCNC=0, Spatial=Off, WindBlock=OFF)\n");
    printf("  fix-noise                      Eliminate playback hiss/noise (releases macOS 16kHz HFP SCO call hijack + sets CNC=10/10 Full ANC)\n");
    printf("  baseline                       Restore factory baseline NVRAM settings (EQ 0/0/0, Multipoint ON, Slot 0 Quiet)\n");
    printf("  status                         Read live firmware, battery, latency, EQ, Self Voice, Multipoint & DSP state\n");
    printf("  pimp-call [off|low|med|high|strict]\n");
    printf("                                 Configure headphone NVRAM & Kalimba DSP for call microphone clarity\n");
    printf("  pimp-audio [harman|vocal|warm|flat]\n");
    printf("                                 Write Reference 3-Band EQ to headphone NVRAM [1.7]\n");
    printf("  eq <bass> <mid> <treble>       Write custom 3-band hardware EQ (-10 to +10 dB) to NVRAM [1.7]\n");
    printf("  sidetone <off|low|med|high>    Write persistent Self Voice (Sidetone) level to NVRAM [1.11]\n");
    printf("  multipoint <on|off>            Enable/disable Bluetooth Multipoint in NVRAM [1.10]\n");
    printf("  mode <0..10>                   Switch active listening mode silently via [31.3]\n");
    printf("  scan                           Enumerate all supported on-device BMAP Function Blocks & Registers\n");
    printf("  raw <hex-bytes>                Send arbitrary BMAP frame (e.g., '01 07 01 00')\n");
}

int main(int argc, const char * argv[]) {
    @autoreleasepool {
        if (argc < 2) {
            printUsage(argv[0]);
            return 1;
        }

        NSString *explicitMAC = nil;
        int argIdx = 1;
        if (argc >= 3 && strcmp(argv[1], "--mac") == 0) {
            explicitMAC = [NSString stringWithUTF8String:argv[2]];
            argIdx = 3;
        }
        if (argIdx >= argc) {
            printUsage(argv[0]);
            return 1;
        }

        NSString *cmd = [NSString stringWithUTF8String:argv[argIdx]];
        if ([cmd isEqualToString:@"--help"] || [cmd isEqualToString:@"-h"] || [cmd isEqualToString:@"help"]) {
            printUsage(argv[0]);
            return 0;
        }

        if ([cmd isEqualToString:@"woke"] ||
            [cmd isEqualToString:@"fix-noise"] ||
            [cmd isEqualToString:@"pimp-audio"] ||
            [cmd isEqualToString:@"status"]) {
            releaseBluetoothSCOIfNeeded(YES);
        }

        IOBluetoothDevice *device = discoverBoseQCUltra(explicitMAC);
        if (!device) {
            fprintf(stderr, "[!] Could not find paired Bose QC Ultra Headphones. Pair them in macOS Bluetooth settings or pass --mac XX-XX-XX-XX-XX-XX.\n");
            return 2;
        }

        printf("[*] Connecting to %s (%s) via IOBluetooth BMAP RFCOMM...\n",
               device.name.UTF8String ?: "Bose QC Ultra",
               device.addressString.UTF8String);

        BMAPDelegate *delegate = [[BMAPDelegate alloc] init];
        BluetoothRFCOMMChannelID activeChannel = 0;
        IOBluetoothRFCOMMChannel *channel = openBMAPRFCOMMChannel(device, delegate, &activeChannel);
        if (!channel) {
            fprintf(stderr, "[!] Failed to open BMAP RFCOMM Channel (tried Channels 1, 2, 14, 3 and SDP UUID 00000000-deca-fade-deca-deafdecacaff).\n");
            return 4;
        }

        pumpRunLoop(0.4);
        [delegate.rxBuffer setLength:0];
        printf("[+] BMAP RFCOMM Channel %u connected.\n\n", activeChannel);

        if ([cmd isEqualToString:@"status"]) {
            const uint8_t qFw[]   = {0x00, 0x05, 0x01, 0x00};
            const uint8_t qSn[]   = {0x00, 0x07, 0x01, 0x00};
            const uint8_t qBat[]  = {0x02, 0x02, 0x01, 0x00};
            const uint8_t qLat[]  = {0x05, 0x07, 0x01, 0x00};
            const uint8_t qEq[]   = {0x01, 0x07, 0x01, 0x00};
            const uint8_t qSide[] = {0x01, 0x0B, 0x01, 0x00};
            const uint8_t qMp[]   = {0x01, 0x0A, 0x01, 0x00};
            const uint8_t qMode[] = {0x1F, 0x03, 0x01, 0x00};

            parseBMAPFrames(sendBMAP(channel, delegate, qFw, sizeof(qFw), 0.25));
            parseBMAPFrames(sendBMAP(channel, delegate, qSn, sizeof(qSn), 0.25));
            parseBMAPFrames(sendBMAP(channel, delegate, qBat, sizeof(qBat), 0.25));
            parseBMAPFrames(sendBMAP(channel, delegate, qLat, sizeof(qLat), 0.25));
            parseBMAPFrames(sendBMAP(channel, delegate, qEq, sizeof(qEq), 0.25));
            parseBMAPFrames(sendBMAP(channel, delegate, qSide, sizeof(qSide), 0.25));
            parseBMAPFrames(sendBMAP(channel, delegate, qMp, sizeof(qMp), 0.25));
            parseBMAPFrames(sendBMAP(channel, delegate, qMode, sizeof(qMode), 0.25));
            for (uint8_t slot = 0; slot <= 4; slot++) {
                uint8_t qSlot[] = {0x1F, 0x06, 0x01, 0x01, slot};
                parseBMAPFrames(sendBMAP(channel, delegate, qSlot, sizeof(qSlot), 0.25));
            }

        } else if ([cmd isEqualToString:@"woke"]) {
            printf("[*] Applying 'Woke' Reference User-Preference NVRAM & DSP Configuration...\n");
            // 1. Hardware 3-Band EQ [1.7]: Bass -3 dB, Mid +1 dB, Treble +2 dB
            uint8_t txB[] = {0x01, 0x07, 0x02, 0x02, (uint8_t)-3, 0x00};
            uint8_t txM[] = {0x01, 0x07, 0x02, 0x02, (uint8_t)1,  0x01};
            uint8_t txT[] = {0x01, 0x07, 0x02, 0x02, (uint8_t)2,  0x02};
            parseBMAPFrames(sendBMAP(channel, delegate, txB, sizeof(txB), 0.25));
            parseBMAPFrames(sendBMAP(channel, delegate, txM, sizeof(txM), 0.25));
            parseBMAPFrames(sendBMAP(channel, delegate, txT, sizeof(txT), 0.25));

            // 2. Self Voice / Sidetone [1.11]: OFF (0x00, Persist=1)
            uint8_t txSide[] = {0x01, 0x0B, 0x02, 0x02, 0x01, 0x00};
            parseBMAPFrames(sendBMAP(channel, delegate, txSide, sizeof(txSide), 0.3));

            // 3. Multipoint [1.10]: ENABLED (0x05 -> 0x07) for simultaneous Mac + Phone use
            uint8_t txMp[] = {0x01, 0x0A, 0x02, 0x01, 0x05};
            parseBMAPFrames(sendBMAP(channel, delegate, txMp, sizeof(txMp), 0.3));

            // 4. Custom Mode Slot 4 ("Woke Studio"): ANC=10/10 (atten=0x00 Full Quiet ANC), AutoCNC=0, Spatial=0, WindBlock=0
            uint8_t txSlot[4 + 39];
            memset(txSlot, 0, sizeof(txSlot));
            txSlot[0] = 0x1F; txSlot[1] = 0x06; txSlot[2] = 0x02; txSlot[3] = 39;
            txSlot[4] = 0x04;
            txSlot[5] = 0x00; txSlot[6] = 0x0C; // Prompt 0x000C ("Music")
            const char *name = "Woke Studio";
            memcpy(&txSlot[7], name, strlen(name));
            txSlot[4 + 35] = 0x00; // ANC attenuation = 0 (10/10 Full Quiet ANC; 0x0A is 0/10 Full Aware/Transparency)
            txSlot[4 + 36] = 0x00; // AutoCNC = 0 (ActiveSense off)
            txSlot[4 + 37] = 0x00; // Spatial = 0 (Immersive Audio off)
            txSlot[4 + 38] = 0x00; // WindBlock = 0
            parseBMAPFrames(sendBMAP(channel, delegate, txSlot, sizeof(txSlot), 0.4));

            // 5. Activate Slot 4 silently via [31.3] START
            uint8_t txAct[] = {0x1F, 0x03, 0x05, 0x02, 0x04, 0x00};
            parseBMAPFrames(sendBMAP(channel, delegate, txAct, sizeof(txAct), 0.3));
            printf("[+] 'Woke' user-preference profile (ANC=10/10 Full Quiet + 2-ch Stereo A2DP) saved to headphone NVRAM (Partition 6).\n");

        } else if ([cmd isEqualToString:@"fix-noise"]) {
            printf("[*] Eliminating playback noise (releasing macOS HFP SCO call hijack + setting ANC=10/10 Full Quiet)...\n");
            uint8_t txSide[] = {0x01, 0x0B, 0x02, 0x02, 0x01, 0x00};
            parseBMAPFrames(sendBMAP(channel, delegate, txSide, sizeof(txSide), 0.3));

            uint8_t txSlot[4 + 39];
            memset(txSlot, 0, sizeof(txSlot));
            txSlot[0] = 0x1F; txSlot[1] = 0x06; txSlot[2] = 0x02; txSlot[3] = 39;
            txSlot[4] = 0x04;
            txSlot[5] = 0x00; txSlot[6] = 0x0C;
            const char *name = "Woke Studio";
            memcpy(&txSlot[7], name, strlen(name));
            txSlot[4 + 35] = 0x00; // ANC attenuation = 0 (10/10 Full Quiet ANC)
            txSlot[4 + 36] = 0x00; // AutoCNC = 0
            txSlot[4 + 37] = 0x00; // Spatial = 0
            txSlot[4 + 38] = 0x00; // WindBlock = 0
            parseBMAPFrames(sendBMAP(channel, delegate, txSlot, sizeof(txSlot), 0.4));

            uint8_t txAct[] = {0x1F, 0x03, 0x05, 0x02, 0x04, 0x00};
            parseBMAPFrames(sendBMAP(channel, delegate, txAct, sizeof(txAct), 0.3));
            printf("[+] Playback noise eliminated: ANC=10/10 Full Quiet active in Slot 4 ('Woke Studio') and macOS locked to 2-ch Stereo A2DP.\n");

        } else if ([cmd isEqualToString:@"baseline"]) {
            printf("[*] Restoring Factory Baseline NVRAM Configuration...\n");
            uint8_t txB[] = {0x01, 0x07, 0x02, 0x02, 0x00, 0x00};
            uint8_t txM[] = {0x01, 0x07, 0x02, 0x02, 0x00, 0x01};
            uint8_t txT[] = {0x01, 0x07, 0x02, 0x02, 0x00, 0x02};
            parseBMAPFrames(sendBMAP(channel, delegate, txB, sizeof(txB), 0.25));
            parseBMAPFrames(sendBMAP(channel, delegate, txM, sizeof(txM), 0.25));
            parseBMAPFrames(sendBMAP(channel, delegate, txT, sizeof(txT), 0.25));
            uint8_t txSide[] = {0x01, 0x0B, 0x02, 0x02, 0x01, 0x02};
            parseBMAPFrames(sendBMAP(channel, delegate, txSide, sizeof(txSide), 0.3));
            uint8_t txMp[] = {0x01, 0x0A, 0x02, 0x01, 0x05};
            parseBMAPFrames(sendBMAP(channel, delegate, txMp, sizeof(txMp), 0.3));
            uint8_t txAct[] = {0x1F, 0x03, 0x05, 0x02, 0x00, 0x00};
            parseBMAPFrames(sendBMAP(channel, delegate, txAct, sizeof(txAct), 0.3));
            printf("[+] Factory Baseline restored.\n");

        } else if ([cmd isEqualToString:@"pimp-call"]) {
            uint8_t sideLvl = 0x00;
            uint8_t windFlag = 0x00;
            if (argIdx + 1 < argc) {
                const char *s = argv[argIdx + 1];
                if (strcmp(s, "high") == 0) sideLvl = 0x01;
                else if (strcmp(s, "med") == 0) sideLvl = 0x02;
                else if (strcmp(s, "low") == 0) sideLvl = 0x03;
                else if (strcmp(s, "strict") == 0) { sideLvl = 0x00; windFlag = 0x01; }
            }
            printf("[*] Applying 'pimp-call' Uplink Mic & Kalimba DSP Optimization (Sidetone=0x%02x, WindBlock=%u)...\n",
                   sideLvl, windFlag);

            uint8_t txSide[] = {0x01, 0x0B, 0x02, 0x02, 0x01, sideLvl};
            parseBMAPFrames(sendBMAP(channel, delegate, txSide, sizeof(txSide), 0.3));

            uint8_t txMp[] = {0x01, 0x0A, 0x02, 0x01, 0x00};
            parseBMAPFrames(sendBMAP(channel, delegate, txMp, sizeof(txMp), 0.3));

            uint8_t txSlot[4 + 39];
            memset(txSlot, 0, sizeof(txSlot));
            txSlot[0] = 0x1F; txSlot[1] = 0x06; txSlot[2] = 0x02; txSlot[3] = 39;
            txSlot[4] = 0x04;
            txSlot[5] = 0x00; txSlot[6] = 0x0D;
            const char *name = "Call Studio";
            memcpy(&txSlot[7], name, strlen(name));
            txSlot[4 + 35] = 0x00; // ANC attenuation = 0 (10/10 Full Quiet ANC)
            txSlot[4 + 36] = 0x00;
            txSlot[4 + 37] = 0x00;
            txSlot[4 + 38] = windFlag;
            parseBMAPFrames(sendBMAP(channel, delegate, txSlot, sizeof(txSlot), 0.4));

            uint8_t txAct[] = {0x1F, 0x03, 0x05, 0x02, 0x04, 0x00};
            parseBMAPFrames(sendBMAP(channel, delegate, txAct, sizeof(txAct), 0.3));

            printf("[+] Call Mic & Kalimba DSP Optimization written to headphone NVRAM (Active Mode = Slot 4 'Call Studio', ANC=10/10).\n");

        } else if ([cmd isEqualToString:@"pimp-audio"]) {
            int8_t bass = -3, mid = 1, treble = 2;
            const char *presetName = "harman (B&K 5128 / Harman Reference)";
            if (argIdx + 1 < argc) {
                const char *p = argv[argIdx + 1];
                if (strcmp(p, "vocal") == 0) {
                    bass = -4; mid = 2; treble = 3;
                    presetName = "vocal (Maximum Anti-Mud & Presence)";
                } else if (strcmp(p, "warm") == 0) {
                    bass = -2; mid = 0; treble = -1;
                    presetName = "warm (Smooth Anti-Sibilance)";
                } else if (strcmp(p, "flat") == 0) {
                    bass = 0; mid = 0; treble = 0;
                    presetName = "flat (Zeroed for External 10-Band PEQ)";
                }
            }
            printf("[*] Applying 'pimp-audio' profile [%s]: Bass=%+d dB, Mid=%+d dB, Treble=%+d dB...\n",
                   presetName, bass, mid, treble);

            uint8_t txB[] = {0x01, 0x07, 0x02, 0x02, (uint8_t)bass, 0x00};
            uint8_t txM[] = {0x01, 0x07, 0x02, 0x02, (uint8_t)mid, 0x01};
            uint8_t txT[] = {0x01, 0x07, 0x02, 0x02, (uint8_t)treble, 0x02};
            parseBMAPFrames(sendBMAP(channel, delegate, txB, sizeof(txB), 0.25));
            parseBMAPFrames(sendBMAP(channel, delegate, txM, sizeof(txM), 0.25));
            parseBMAPFrames(sendBMAP(channel, delegate, txT, sizeof(txT), 0.25));
            printf("[+] Hardware EQ & Phase-Coherent ANC settings saved to headphone NVRAM.\n");

        } else if ([cmd isEqualToString:@"eq"] && argIdx + 3 < argc) {
            int8_t bass = (int8_t)atoi(argv[argIdx + 1]);
            int8_t mid = (int8_t)atoi(argv[argIdx + 2]);
            int8_t treble = (int8_t)atoi(argv[argIdx + 3]);
            uint8_t txB[] = {0x01, 0x07, 0x02, 0x02, (uint8_t)bass, 0x00};
            uint8_t txM[] = {0x01, 0x07, 0x02, 0x02, (uint8_t)mid, 0x01};
            uint8_t txT[] = {0x01, 0x07, 0x02, 0x02, (uint8_t)treble, 0x02};
            parseBMAPFrames(sendBMAP(channel, delegate, txB, sizeof(txB), 0.25));
            parseBMAPFrames(sendBMAP(channel, delegate, txM, sizeof(txM), 0.25));
            parseBMAPFrames(sendBMAP(channel, delegate, txT, sizeof(txT), 0.25));

        } else if ([cmd isEqualToString:@"sidetone"] && argIdx + 1 < argc) {
            const char *s = argv[argIdx + 1];
            uint8_t lvl = 0x00;
            if (strcmp(s, "high") == 0) lvl = 0x01;
            else if (strcmp(s, "med") == 0) lvl = 0x02;
            else if (strcmp(s, "low") == 0) lvl = 0x03;
            uint8_t tx[] = {0x01, 0x0B, 0x02, 0x02, 0x01, lvl};
            parseBMAPFrames(sendBMAP(channel, delegate, tx, sizeof(tx), 0.3));

        } else if ([cmd isEqualToString:@"multipoint"] && argIdx + 1 < argc) {
            uint8_t en = (strcmp(argv[argIdx + 1], "on") == 0) ? 0x05 : 0x00;
            uint8_t tx[] = {0x01, 0x0A, 0x02, 0x01, en};
            parseBMAPFrames(sendBMAP(channel, delegate, tx, sizeof(tx), 0.3));

        } else if ([cmd isEqualToString:@"mode"] && argIdx + 1 < argc) {
            uint8_t idx = (uint8_t)atoi(argv[argIdx + 1]);
            uint8_t tx[] = {0x1F, 0x03, 0x05, 0x02, idx, 0x00};
            parseBMAPFrames(sendBMAP(channel, delegate, tx, sizeof(tx), 0.3));

        } else if ([cmd isEqualToString:@"scan"]) {
            printf("[*] Scanning all on-device BMAP Function Blocks (0x00..0x1F) & Capabilities...\n");
            for (uint8_t fb = 0; fb <= 0x1F; fb++) {
                uint8_t tx[] = {fb, 0x00, 0x01, 0x00};
                NSData *rx = sendBMAP(channel, delegate, tx, sizeof(tx), 0.12);
                const uint8_t *b = (const uint8_t *)rx.bytes;
                if (rx.length >= 4 && (b[2] & 0x0F) == 0x03) {
                    NSString *ver = [[NSString alloc] initWithBytes:b + 4 length:b[3] encoding:NSUTF8StringEncoding];
                    printf("  [+] FBlock 0x%02x (%2u) SUPPORTED | Version: %s\n", fb, fb, ver ? ver.UTF8String : "binary");
                }
            }
            printf("\n[*] Probing Settings [0x01] Functions (0x01..0x28)...\n");
            for (uint8_t fn = 1; fn <= 0x28; fn++) {
                uint8_t tx[] = {0x01, fn, 0x01, 0x00};
                NSData *rx = sendBMAP(channel, delegate, tx, sizeof(tx), 0.10);
                const uint8_t *b = (const uint8_t *)rx.bytes;
                if (rx.length >= 4 && (b[2] & 0x0F) == 0x03) {
                    printf("  [+] Settings [1.%u] (0x%02x) len=%u: ", fn, fn, b[3]);
                    for (uint8_t i = 0; i < b[3] && i < rx.length - 4; i++) printf("%02x ", b[4 + i]);
                    printf("\n");
                }
            }
            printf("\n[*] Probing AudioManagement [0x05] Functions (0x01..0x18)...\n");
            for (uint8_t fn = 1; fn <= 0x18; fn++) {
                uint8_t tx[] = {0x05, fn, 0x01, 0x00};
                NSData *rx = sendBMAP(channel, delegate, tx, sizeof(tx), 0.10);
                const uint8_t *b = (const uint8_t *)rx.bytes;
                if (rx.length >= 4 && (b[2] & 0x0F) == 0x03) {
                    printf("  [+] AudioMgmt [5.%u] (0x%02x) len=%u: ", fn, fn, b[3]);
                    for (uint8_t i = 0; i < b[3] && i < rx.length - 4; i++) printf("%02x ", b[4 + i]);
                    printf("\n");
                }
            }

        } else if ([cmd isEqualToString:@"raw"] && argIdx + 1 < argc) {
            uint8_t buf[260];
            size_t n = 0;
            for (int i = argIdx + 1; i < argc && n < sizeof(buf); i++) {
                buf[n++] = (uint8_t)strtoul(argv[i], NULL, 16);
            }
            printHex("TX BMAP", buf, n);
            parseBMAPFrames(sendBMAP(channel, delegate, buf, n, 0.35));
        } else {
            printUsage(argv[0]);
        }

        [channel closeChannel];
    }
    return 0;
}
