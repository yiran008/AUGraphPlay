//
//  AUGraphPlayer.m
//  AUGraphPlayDemo
//
//  Created by liumiao on 11/13/14.
//  Copyright (c) 2014 Chang Ba. All rights reserved.
//

#import "AUGraphPlayer.h"
#import <AudioToolbox/AudioToolbox.h>
#import <AVFoundation/AVFoundation.h>
#import "CAStreamBasicDescription.h"
#import "CAComponentDescription.h"
#import "CAXException.h"
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
    AUGraph   mGraph;
    AudioUnit mOutPut;
    AudioUnit reverbPut;
}
- (id)init
{
    self = [super init];
    if (self)
    {
        [self initializeAUGraph];
    }
    return self;
}

-(void)initializeAUGraph
{
    AUNode ioNode;
    AUNode reverbNode;
    
    OSStatus result = noErr;
    
    result = NewAUGraph(&mGraph);
    
    CAComponentDescription output_desc(kAudioUnitType_Output, kAudioUnitSubType_RemoteIO, kAudioUnitManufacturer_Apple);
    
    CAComponentDescription reverb_desc(kAudioUnitType_Effect, kAudioUnitSubType_Reverb2, kAudioUnitManufacturer_Apple);
    
    result = AUGraphAddNode(mGraph, &output_desc, &ioNode);
    result = AUGraphAddNode(mGraph, &reverb_desc, &reverbNode);
    
    result = AUGraphOpen(mGraph);
    result = AUGraphNodeInfo(mGraph, ioNode, NULL, &mOutPut);
    result = AUGraphNodeInfo(mGraph, reverbNode, NULL, &reverbPut);

    UInt32 one = 1;
    result = AudioUnitSetProperty(mOutPut, kAudioOutputUnitProperty_EnableIO, kAudioUnitScope_Output, 0, &one, sizeof(one));
    result = AudioUnitSetProperty(mOutPut, kAudioOutputUnitProperty_EnableIO, kAudioUnitScope_Input, 1, &one, sizeof(one));
    

    //CAStreamBasicDescription ioFormat = CAStreamBasicDescription(44100, 1, CAStreamBasicDescription::kPCMFormatFloat32, false);
    size_t bytesPerSample = sizeof (AudioUnitSampleType);
    AudioStreamBasicDescription     stereoStreamFormat;
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
    result = AudioUnitSetProperty(mOutPut, kAudioUnitProperty_StreamFormat, kAudioUnitScope_Input, 0, &stereoStreamFormat, sizeof(stereoStreamFormat));
    result = AudioUnitSetProperty(mOutPut, kAudioUnitProperty_StreamFormat, kAudioUnitScope_Output, 1, &stereoStreamFormat, sizeof(stereoStreamFormat));
    AUGraphConnectNodeInput(mGraph, reverbNode, 0, ioNode, 0);
    AUGraphConnectNodeInput(mGraph,
                            ioNode,
                            1,
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
}

-(void)start
{
    Boolean isRunning = false;
    OSStatus result = AUGraphIsRunning(mGraph, &isRunning);
    if(!isRunning)
    {
        result = AUGraphStart(mGraph);
    }
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
}

@end
