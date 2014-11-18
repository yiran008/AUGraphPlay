//
//  AUGraphPlayer.m
//  AUGraphPlayDemo
//
//  Created by liumiao on 11/13/14.
//  Copyright (c) 2014 Chang Ba. All rights reserved.
//

#import "AUGraphPlayer.h"

struct CallbackData {
    AudioUnit               rioUnit;
    CallbackData(): rioUnit(NULL) {}
} cd;

static OSStatus	performRender (void                         *inRefCon,
                               AudioUnitRenderActionFlags 	*ioActionFlags,
                               const AudioTimeStamp 		*inTimeStamp,
                               UInt32 						inBusNumber,
                               UInt32 						inNumberFrames,
                               AudioBufferList              *ioData)
{
    OSStatus err = noErr;
        // we are calling AudioUnitRender on the input bus of AURemoteIO
        // this will store the audio data captured by the microphone in ioData
        err = AudioUnitRender(cd.rioUnit, ioActionFlags, inTimeStamp, 1, inNumberFrames, ioData);
    
    return err;
}
@implementation AUGraphPlayer

{
    CAStreamBasicDescription mClientFormat;
    AudioStreamBasicDescription     stereoStreamFormat;
    AUGraph   mGraph;
    AudioUnit reverbPut;
    AudioUnit playUnit;
}
- (id)init
{
    self = [super init];
    if (self)
    {
        //[self initializeAudioSession];
        [self initializeAUGraph];
    }
    return self;
}
-(void)initializeAudioSession
{
    NSError *error = nil;
    
    // Configure the audio session
    AVAudioSession *sessionInstance = [AVAudioSession sharedInstance];
    
    // our default category -- we change this for conversion and playback appropriately
    [sessionInstance setCategory:AVAudioSessionCategoryPlayback error:&error];
    XThrowIfError(error.code, "couldn't set audio category");
    
    NSTimeInterval bufferDuration = .005;
    [sessionInstance setPreferredIOBufferDuration:bufferDuration error:&error];
    XThrowIfError(error.code, "couldn't set IOBufferDuration");
    
    double hwSampleRate = 44100.0;
    [sessionInstance setPreferredSampleRate:hwSampleRate error:&error];
    XThrowIfError(error.code, "couldn't set preferred sample rate");
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(handleRouteChange:)
                                                 name:AVAudioSessionRouteChangeNotification
                                               object:sessionInstance];
    // activate the audio session
    [sessionInstance setActive:YES error:&error];
    XThrowIfError(error.code, "couldn't set audio session active\n");
    
    // just print out some info
    printf("Current IOBufferDuration: %fms\n", sessionInstance.IOBufferDuration * 1000);
    printf("Hardware Sample Rate: %.1fHz\n", sessionInstance.sampleRate);
    printf("Current Hardware Output Latency: %fms\n", sessionInstance.outputLatency * 1000);

}
- (void)handleRouteChange:(NSNotification *)notification
{
    UInt8 reasonValue = [[notification.userInfo valueForKey:AVAudioSessionRouteChangeReasonKey] intValue];
    AVAudioSessionRouteDescription *routeDescription = [notification.userInfo valueForKey:AVAudioSessionRouteChangePreviousRouteKey];
    
    NSLog(@"Route change:");
    switch (reasonValue) {
        case AVAudioSessionRouteChangeReasonNewDeviceAvailable:
            NSLog(@"     NewDeviceAvailable");
            break;
        case AVAudioSessionRouteChangeReasonOldDeviceUnavailable:
            NSLog(@"     OldDeviceUnavailable");
            break;
        case AVAudioSessionRouteChangeReasonCategoryChange:
            NSLog(@"     CategoryChange");
            NSLog(@" New Category: %@", [[AVAudioSession sharedInstance] category]);
            break;
        case AVAudioSessionRouteChangeReasonOverride:
            NSLog(@"     Override");
            break;
        case AVAudioSessionRouteChangeReasonWakeFromSleep:
            NSLog(@"     WakeFromSleep");
            break;
        case AVAudioSessionRouteChangeReasonNoSuitableRouteForCategory:
            NSLog(@"     NoSuitableRouteForCategory");
            break;
        default:
            NSLog(@"     ReasonUnknown");
    }
    
    NSLog(@"Previous route:\n");
    NSLog(@"%@", routeDescription);
}

-(void)initializeAUGraph
{
    AUNode ioNode;
    AUNode reverbNode;
    AUNode playNode;
    
    OSStatus result = noErr;
    
    result = NewAUGraph(&mGraph);
    
    CAComponentDescription output_desc(kAudioUnitType_Output, kAudioUnitSubType_RemoteIO, kAudioUnitManufacturer_Apple);
    
    CAComponentDescription reverb_desc(kAudioUnitType_Effect, kAudioUnitSubType_Reverb2, kAudioUnitManufacturer_Apple);
    
    CAComponentDescription play_desc(kAudioUnitType_Generator, kAudioUnitSubType_AudioFilePlayer, kAudioUnitManufacturer_Apple);
    
    result = AUGraphAddNode(mGraph, &output_desc, &ioNode);
    result = AUGraphAddNode(mGraph, &reverb_desc, &reverbNode);
    result = AUGraphAddNode(mGraph, &play_desc, &playNode);
    
    result = AUGraphOpen(mGraph);
    result = AUGraphNodeInfo(mGraph, ioNode, NULL, &mOutPut);
    result = AUGraphNodeInfo(mGraph, reverbNode, NULL, &reverbPut);
    result = AUGraphNodeInfo(mGraph, playNode, NULL, &playUnit);

//    UInt32 one = 1;
//    result = AudioUnitSetProperty(mOutPut, kAudioOutputUnitProperty_EnableIO, kAudioUnitScope_Output, 0, &one, sizeof(one));
//    result = AudioUnitSetProperty(mOutPut, kAudioOutputUnitProperty_EnableIO, kAudioUnitScope_Input, 1, &one, sizeof(one));
    

    //CAStreamBasicDescription ioFormat = CAStreamBasicDescription(44100, 1, CAStreamBasicDescription::kPCMFormatFloat32, false);
    size_t bytesPerSample = sizeof (AudioUnitSampleType);
    // Fill the application audio format struct's fields to define a linear PCM,
    //        stereo, noninterleaved stream at the hardware sample rate.
    stereoStreamFormat.mFormatID          = kAudioFormatLinearPCM;
    stereoStreamFormat.mFormatFlags       = kAudioFormatFlagsNativeFloatPacked | kAudioFormatFlagIsNonInterleaved;
    stereoStreamFormat.mBytesPerPacket    = bytesPerSample;
    stereoStreamFormat.mFramesPerPacket   = 1;
    stereoStreamFormat.mBytesPerFrame     = bytesPerSample;
    stereoStreamFormat.mChannelsPerFrame  = 2;                    // 2 indicates stereo
    stereoStreamFormat.mBitsPerChannel    = 8 * bytesPerSample;
    stereoStreamFormat.mSampleRate        = 44100.0;
    result = AudioUnitSetProperty(
                                   reverbPut,
                                   kAudioUnitProperty_StreamFormat,
                                   kAudioUnitScope_Output,
                                   0,
                                   &stereoStreamFormat,
                                   sizeof (stereoStreamFormat)
                                   );
    result = AudioUnitSetProperty(
                                  playUnit,
                                  kAudioUnitProperty_StreamFormat,
                                  kAudioUnitScope_Output,
                                  0,
                                  &stereoStreamFormat,
                                  sizeof (stereoStreamFormat)
                                  );
    //result = AudioUnitSetProperty(mOutPut, kAudioUnitProperty_StreamFormat, kAudioUnitScope_Input, 0, &stereoStreamFormat, sizeof(stereoStreamFormat));
    //result = AudioUnitSetProperty(mOutPut, kAudioUnitProperty_StreamFormat, kAudioUnitScope_Output, 1, &stereoStreamFormat, sizeof(stereoStreamFormat));
    AUGraphConnectNodeInput(mGraph, reverbNode, 0, ioNode, 0);
    AUGraphConnectNodeInput(mGraph,
                            playNode,
                            0,
                            reverbNode,
                            0);
    cd.rioUnit = reverbPut;
    
//    AURenderCallbackStruct renderCallback;
//    renderCallback.inputProc = &performRender;
//    renderCallback.inputProcRefCon = NULL;
//    
//    AUGraphSetNodeInputCallback(mGraph, reverbNode, 0, &renderCallback);
    result = AUGraphInitialize(mGraph);
    CAShow(mGraph);
    AUGraphStart (mGraph);
}
-(AudioUnitParameterValue)getValueForParamId:(AudioUnitParameterID)paramId
{
    AudioUnitParameterValue value = 0;
    
    AudioUnitGetParameter(reverbPut, paramId, kAudioUnitScope_Global, 0, &value);
    
    return value;
}

-(void)setValue:(AudioUnitParameterValue)value forParamId:(AudioUnitParameterID)paramId
{
    AudioUnitSetParameter(reverbPut, paramId, kAudioUnitScope_Global, 0, value, 0);
}

-(void)start
{
//    Boolean isRunning = false;
//    OSStatus result = AUGraphIsRunning(mGraph, &isRunning);
//    if(!isRunning)
//    {
//        result = AUGraphStart(mGraph);
//    }
    //region
    ExtAudioFileRef _extAudioFile;
    AudioFileID _audioFileID;
    OSStatus err = noErr;
    UInt32 size;
    NSString *songPath = [[NSBundle mainBundle] pathForResource: @"MiAmor" ofType:@"mp3"];
    CFURLRef songURL = (__bridge  CFURLRef) [NSURL fileURLWithPath:songPath];
    err = ExtAudioFileOpenURL(songURL, &_extAudioFile);
    
    size = sizeof(_audioFileID);
    ExtAudioFileGetProperty(_extAudioFile, kExtAudioFileProperty_AudioFile, &size, &_audioFileID);
    
    size = sizeof(AudioStreamBasicDescription);
    err = AudioFileGetProperty(_audioFileID, kAudioFilePropertyDataFormat, &size, &stereoStreamFormat);
    
    SInt64 fileLengthFrames;
    size = sizeof(SInt64);
    err = ExtAudioFileGetProperty(_extAudioFile, kExtAudioFileProperty_FileLengthFrames, &size, &fileLengthFrames);
    
    err = AudioUnitSetProperty(playUnit, kAudioUnitProperty_ScheduledFileIDs, kAudioUnitScope_Global, 0, &_audioFileID, sizeof(AudioFileID));
    UInt32 _audioFileFrames = fileLengthFrames;
    ScheduledAudioFileRegion region = {0};
    region.mAudioFile = _audioFileID;
    region.mCompletionProc = NULL;
    region.mCompletionProcUserData = NULL;
    region.mLoopCount = 0;
    region.mStartFrame = 0;
    region.mFramesToPlay = _audioFileFrames - region.mStartFrame;
    region.mTimeStamp.mFlags = kAudioTimeStampSampleTimeValid;
    region.mTimeStamp.mSampleTime = 0;
    
    err = AudioUnitSetProperty(playUnit, kAudioUnitProperty_ScheduledFileRegion, kAudioUnitScope_Global, 0, &region, sizeof(ScheduledAudioFileRegion));

    
    
    //play
    
    AudioTimeStamp theTimeStamp = {0};
    theTimeStamp.mFlags = kAudioTimeStampHostTimeValid;
    theTimeStamp.mHostTime = 0;
    err = AudioUnitSetProperty(playUnit,
                               kAudioUnitProperty_ScheduleStartTimeStamp, kAudioUnitScope_Global, 0,
                               &theTimeStamp, sizeof(theTimeStamp));

}

-(void)stop
{
    Boolean isRunning = false;
    
    OSStatus result = AUGraphIsRunning(mGraph, &isRunning);
    if (isRunning)
    {
        result = AUGraphStop(mGraph);
    }
}


-(void)dealloc
{
    DisposeAUGraph(mGraph);
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:AVAudioSessionRouteChangeNotification
                                                  object:[AVAudioSession sharedInstance]];

}

@end
