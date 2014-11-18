//
//  AUGraphPlayer.m
//  AUGraphPlayDemo
//
//  Created by liumiao on 11/13/14.
//  Copyright (c) 2014 Chang Ba. All rights reserved.
//

#import "AUGraphPlayer.h"
#define Out 0

@implementation AUGraphPlayer

{
    AudioStreamBasicDescription     stereoStreamFormat;
    AUGraph   mGraph;
    AudioUnit reverbPut;
    AudioUnit playUnit;
    AudioUnit mGIO;
    Float64 MaxSampleTime;
}
- (id)init
{
    self = [super init];
    if (self)
    {
        [self initializeAudioSession];
        MaxSampleTime = 0.0;
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
    
    NSTimeInterval bufferDuration = 0.5;
    [sessionInstance setPreferredIOBufferDuration:bufferDuration error:&error];
    NSLog(@"%f",sessionInstance.IOBufferDuration);
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
#if Out
    AUNode ioNode;
#else
    AUNode gioNode;
#endif
    AUNode reverbNode;
    AUNode playNode;
    
    OSStatus result = noErr;
    
    result = NewAUGraph(&mGraph);
#if Out
    CAComponentDescription output_desc(kAudioUnitType_Output, kAudioUnitSubType_RemoteIO, kAudioUnitManufacturer_Apple);
#else
    CAComponentDescription gout_desc(kAudioUnitType_Output, kAudioUnitSubType_GenericOutput, kAudioUnitManufacturer_Apple);
#endif
    CAComponentDescription reverb_desc(kAudioUnitType_Effect, kAudioUnitSubType_Reverb2, kAudioUnitManufacturer_Apple);
    
    CAComponentDescription play_desc(kAudioUnitType_Generator, kAudioUnitSubType_AudioFilePlayer, kAudioUnitManufacturer_Apple);
    
    
#if Out
    result = AUGraphAddNode(mGraph, &output_desc, &ioNode);
#else
    result = AUGraphAddNode(mGraph, &gout_desc, &gioNode);
#endif
    result = AUGraphAddNode(mGraph, &reverb_desc, &reverbNode);
    result = AUGraphAddNode(mGraph, &play_desc, &playNode);
    
    
    result = AUGraphOpen(mGraph);
#if Out
    result = AUGraphNodeInfo(mGraph, ioNode, NULL, &mOutPut);
#else
    result = AUGraphNodeInfo(mGraph, gioNode, NULL, &mGIO);
#endif
    result = AUGraphNodeInfo(mGraph, reverbNode, NULL, &reverbPut);
    result = AUGraphNodeInfo(mGraph, playNode, NULL, &playUnit);
    

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
#if Out
    AUGraphConnectNodeInput(mGraph, reverbNode, 0, ioNode, 0);
#else
    AUGraphConnectNodeInput(mGraph, reverbNode, 0, gioNode, 0);
#endif
    AUGraphConnectNodeInput(mGraph,
                            playNode,
                            0,
                            reverbNode,
                            0);
    
    result = AUGraphInitialize(mGraph);
    CAShow(mGraph);
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
    Boolean isRunning = false;
    OSStatus result = AUGraphIsRunning(mGraph, &isRunning);
    if(!isRunning)
    {
        result = AUGraphStart(mGraph);
    }
    //region
    ExtAudioFileRef _extAudioFile;
    AudioFileID _audioFileID;
    OSStatus err = noErr;
    UInt32 size;
    NSString *songPath = [[NSBundle mainBundle] pathForResource: @"recordedFile" ofType:@"caf"];
    CFURLRef songURL = (__bridge  CFURLRef) [NSURL fileURLWithPath:songPath];
    err = ExtAudioFileOpenURL(songURL, &_extAudioFile);
    
    size = sizeof(_audioFileID);
    ExtAudioFileGetProperty(_extAudioFile, kExtAudioFileProperty_AudioFile, &size, &_audioFileID);
    
    SInt64 fileLengthFrames;
    size = sizeof(SInt64);
    err = ExtAudioFileGetProperty(_extAudioFile, kExtAudioFileProperty_FileLengthFrames, &size, &fileLengthFrames);
    
    err = AudioUnitSetProperty(playUnit, kAudioUnitProperty_ScheduledFileIDs, kAudioUnitScope_Global, 0, &_audioFileID, sizeof(AudioFileID));
    
    
    UInt32 _audioFileFrames = fileLengthFrames;
    ScheduledAudioFileRegion region = {0};
    region.mAudioFile = _audioFileID;
    region.mCompletionProc = NULL;
    region.mCompletionProcUserData = NULL;
    region.mLoopCount = -1;
    region.mStartFrame = 0;
    region.mFramesToPlay = _audioFileFrames - region.mStartFrame;
    region.mTimeStamp.mFlags = kAudioTimeStampSampleTimeValid;
    region.mTimeStamp.mSampleTime = 0;
    if (MaxSampleTime < region.mFramesToPlay)
    {
        MaxSampleTime = region.mFramesToPlay;
    }
    err = AudioUnitSetProperty(playUnit, kAudioUnitProperty_ScheduledFileRegion, kAudioUnitScope_Global, 0, &region, sizeof(ScheduledAudioFileRegion));

    UInt32 defaultVal = 0;
    
    AudioUnitSetProperty(playUnit, kAudioUnitProperty_ScheduledFilePrime,
                                    kAudioUnitScope_Global, 0, &defaultVal, sizeof(defaultVal));
    
    //play
    
    AudioTimeStamp theTimeStamp = {0};
    theTimeStamp.mFlags = kAudioTimeStampSampleTimeValid;
    theTimeStamp.mSampleTime = -1;
    err = AudioUnitSetProperty(playUnit,
                               kAudioUnitProperty_ScheduleStartTimeStamp, kAudioUnitScope_Global, 0,
                               &theTimeStamp, sizeof(theTimeStamp));
#if !Out
    [self startGenerate];
#endif

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

-(void)startGenerate
{
    ExtAudioFileRef extAudioFile;
    AudioStreamBasicDescription destinationFormat;
    memset(&destinationFormat, 0, sizeof(destinationFormat));
    destinationFormat.mChannelsPerFrame = 2;
    destinationFormat.mFormatID = kAudioFormatMPEG4AAC;
    UInt32 size = sizeof(destinationFormat);
    OSStatus result = AudioFormatGetProperty(kAudioFormatProperty_FormatInfo, 0, NULL, &size, &destinationFormat);
    if(result) printf("AudioFormatGetProperty %ld \n", result);
    NSArray  *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
    
    
    
    NSString *destinationFilePath = [[NSString alloc] initWithFormat: @"%@/output.m4a", documentsDirectory];
    CFURLRef destinationURL = CFURLCreateWithFileSystemPath(kCFAllocatorDefault,
                                                            (CFStringRef)destinationFilePath,
                                                            kCFURLPOSIXPathStyle,
                                                            false);
    
    // specify codec Saving the output in .m4a format
    result = ExtAudioFileCreateWithURL(destinationURL,
                                       kAudioFileM4AType,
                                       &destinationFormat,
                                       NULL,
                                       kAudioFileFlags_EraseFile,
                                       &extAudioFile);
    if(result) printf("ExtAudioFileCreateWithURL %ld \n", result);
    CFRelease(destinationURL);
    
    // This is a very important part and easiest way to set the ASBD for the File with correct format.
    AudioStreamBasicDescription clientFormat;
    UInt32 fSize = sizeof (clientFormat);
    memset(&clientFormat, 0, sizeof(clientFormat));
    // get the audio data format from the Output Unit
    AudioUnitGetProperty(mGIO,
                                    kAudioUnitProperty_StreamFormat,
                                    kAudioUnitScope_Output,
                                    0,
                                    &clientFormat,
                                    &fSize);
    
    ExtAudioFileSetProperty(extAudioFile,
                                       kExtAudioFileProperty_ClientDataFormat,
                                       sizeof(clientFormat),
                                       &clientFormat);
    // specify codec
    UInt32 codec = kAppleHardwareAudioCodecManufacturer;
    ExtAudioFileSetProperty(extAudioFile,
                                       kExtAudioFileProperty_CodecManufacturer,
                                       sizeof(codec),
                                       &codec);
    
    //ExtAudioFileWriteAsync(extAudioFile, 0, NULL);
    
    
    AudioUnitRenderActionFlags flags = 0;
    AudioTimeStamp inTimeStamp;
    memset(&inTimeStamp, 0, sizeof(AudioTimeStamp));
    inTimeStamp.mFlags = kAudioTimeStampSampleTimeValid;
    UInt32 busNumber = 0;
    UInt32 numberFrames = 512;
    inTimeStamp.mSampleTime = 0;
    int channelCount = 2;
    
    NSLog(@"Final numberFrames :%li",numberFrames);
    int totFrms = MaxSampleTime;
    while (totFrms > 0)
    {
        if (totFrms < numberFrames)
        {
            numberFrames = totFrms;
            NSLog(@"Final numberFrames :%li",numberFrames);
        }
        else
        {
            totFrms -= numberFrames;
        }
        AudioBufferList *bufferList = (AudioBufferList*)malloc(sizeof(AudioBufferList)+sizeof(AudioBuffer)*(channelCount-1));
        bufferList->mNumberBuffers = channelCount;
        for (int j=0; j<channelCount; j++)
        {
            AudioBuffer buffer = {0};
            buffer.mNumberChannels = 1;
            buffer.mDataByteSize = numberFrames*sizeof(AudioUnitSampleType);
            buffer.mData = calloc(numberFrames, sizeof(AudioUnitSampleType));
            
            bufferList->mBuffers[j] = buffer;
            
        }
        AudioUnitRender(mGIO,&flags,&inTimeStamp,busNumber,numberFrames,bufferList);
        
        
        result = ExtAudioFileWrite(extAudioFile, numberFrames, bufferList);
        for (int j=0; j<channelCount; j++)
        {
            free(bufferList->mBuffers[j].mData);
        }
        free(bufferList);
        
    }
    OSStatus status = ExtAudioFileDispose(extAudioFile);
    printf("OSStatus(ExtAudioFileDispose): %ld\n", status);
    UIAlertView *alert = [[UIAlertView alloc]initWithTitle:@"完成" message:nil delegate:nil cancelButtonTitle:@"OK" otherButtonTitles: nil];
    [alert show];

}
-(void)dealloc
{
    DisposeAUGraph(mGraph);
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:AVAudioSessionRouteChangeNotification
                                                  object:[AVAudioSession sharedInstance]];

}

@end
