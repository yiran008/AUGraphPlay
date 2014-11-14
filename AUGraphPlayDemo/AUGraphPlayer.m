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
    AUNode outputNode;
    
    OSStatus result = noErr;
    
    result = NewAUGraph(&mGraph);
    
    CAComponentDescription output_desc(kAudioUnitType_Output, kAudioUnitSubType_RemoteIO, kAudioUnitManufacturer_Apple);
    
    result = AUGraphAddNode(mGraph, &output_desc, &outputNode);
    result = AUGraphOpen(mGraph);
    result = AUGraphNodeInfo(mGraph, outputNode, NULL, &mOutPut);

    UInt32 one = 1;
    result = AudioUnitSetProperty(mOutPut, kAudioOutputUnitProperty_EnableIO, kAudioUnitScope_Output, 0, &one, sizeof(one));
    result = AudioUnitSetProperty(mOutPut, kAudioOutputUnitProperty_EnableIO, kAudioUnitScope_Input, 1, &one, sizeof(one));
    
    CAStreamBasicDescription ioFormat = CAStreamBasicDescription(44100, 1, CAStreamBasicDescription::kPCMFormatFloat32, false);
    result = AudioUnitSetProperty(mOutPut, kAudioUnitProperty_StreamFormat, kAudioUnitScope_Output, 1, &ioFormat, sizeof(ioFormat));
    result = AudioUnitSetProperty(mOutPut, kAudioUnitProperty_StreamFormat, kAudioUnitScope_Input, 0, &ioFormat, sizeof(ioFormat));
    UInt32 maxFramesPerSlice = 4096;
    XThrowIfError(AudioUnitSetProperty(mOutPut, kAudioUnitProperty_MaximumFramesPerSlice, kAudioUnitScope_Global, 0, &maxFramesPerSlice, sizeof(UInt32)), "couldn't set max frames per slice on AURemoteIO");
    
    // Get the property value back from AURemoteIO. We are going to use this value to allocate buffers accordingly
    UInt32 propSize = sizeof(UInt32);
    XThrowIfError(AudioUnitGetProperty(mOutPut, kAudioUnitProperty_MaximumFramesPerSlice, kAudioUnitScope_Global, 0, &maxFramesPerSlice, &propSize), "couldn't get max frames per slice on AURemoteIO");
//    cd.rioUnit = mOutPut;
//    AURenderCallbackStruct renderCallback;
//    renderCallback.inputProc = performRender;
//    renderCallback.inputProcRefCon = NULL;
//    //AudioUnitSetProperty(mOutPut, kAudioUnitProperty_SetRenderCallback, kAudioUnitScope_Input, 0, &renderCallback, sizeof(renderCallback));
//    AUGraphSetNodeInputCallback(mGraph, outputNode, 0, &renderCallback);
    AUGraphConnectNodeInput(mGraph,
                            outputNode,
                            1,
                            outputNode,
                            0);
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

@end
