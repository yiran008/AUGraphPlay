//
//  AUGraphPlayer.h
//  AUGraphPlayDemo
//
//  Created by liumiao on 11/13/14.
//  Copyright (c) 2014 Chang Ba. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AudioToolbox/AudioToolbox.h>
#import <AVFoundation/AVFoundation.h>
#import "CAStreamBasicDescription.h"
#import "CAComponentDescription.h"
#import "CAXException.h"
@interface AUGraphPlayer : NSObject
{
    AudioUnit mOutPut;
}
-(void)start;
-(void)stop;
-(AudioUnitParameterValue)getValueForParamId:(AudioUnitParameterID)paramId;
-(void)setValue:(AudioUnitParameterValue)value forParamId:(AudioUnitParameterID)paramId;
@end
