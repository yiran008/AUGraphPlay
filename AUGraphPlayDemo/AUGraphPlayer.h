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
#import <UIKit/UIKit.h>
#import "CAStreamBasicDescription.h"
#import "CAComponentDescription.h"
#import "CAXException.h"
@interface AUGraphPlayer : NSObject
{
    AudioUnit mOutPut;
}
@property (nonatomic, strong)NSURL *outputPath;
-(void)start;
-(void)stop;
-(void)play;
-(AudioUnitParameterValue)getValueForParamId:(AudioUnitParameterID)paramId;
-(void)setValue:(AudioUnitParameterValue)value forParamId:(AudioUnitParameterID)paramId;
@end
