//
//  ViewController.m
//  AUGraphPlayDemo
//
//  Created by liumiao on 11/13/14.
//  Copyright (c) 2014 Chang Ba. All rights reserved.
//

#import "ViewController.h"
#import "AUGraphPlayer.h"
@interface ViewController ()
@property (nonatomic, strong)AUGraphPlayer* player;
@property (strong, nonatomic) IBOutlet UISlider *drywetmixSlider;
@property (strong, nonatomic) IBOutlet UISlider *gainSlider;
@property (strong, nonatomic) IBOutlet UISlider *mindelaySlider;
@property (strong, nonatomic) IBOutlet UISlider *maxdelaySlider;
@property (strong, nonatomic) IBOutlet UISlider *decay0hzSlider;
@property (strong, nonatomic) IBOutlet UISlider *decaynyquistSlider;
@property (strong, nonatomic) IBOutlet UISlider *randomizeSlider;
@property (strong, nonatomic) IBOutlet UILabel *drywetLabel;
@property (strong, nonatomic) IBOutlet UILabel *gainLabel;
@property (strong, nonatomic) IBOutlet UILabel *mindelayLabel;
@property (strong, nonatomic) IBOutlet UILabel *maxdelayLabel;
@property (strong, nonatomic) IBOutlet UILabel *decay0hzLabel;
@property (strong, nonatomic) IBOutlet UILabel *decaynyquistLabel;
@property (strong, nonatomic) IBOutlet UILabel *reflectionLabel;
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.player = [[AUGraphPlayer alloc]init];
    [self updateSliderValue];
    [self updateLabels];
    // Do any additional setup after loading the view, typically from a nib.
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}
/*
 enum {
 // Global, CrossFade, 0->100, 100
	kReverb2Param_DryWetMix 						= 0,
 // Global, Decibels, -20->20, 0
	kReverb2Param_Gain								= 1,
 
 // Global, Secs, 0.0001->1.0, 0.008
	kReverb2Param_MinDelayTime						= 2,
 // Global, Secs, 0.0001->1.0, 0.050
	kReverb2Param_MaxDelayTime						= 3,
 // Global, Secs, 0.001->20.0, 1.0
	kReverb2Param_DecayTimeAt0Hz					= 4,
 // Global, Secs, 0.001->20.0, 0.5
	kReverb2Param_DecayTimeAtNyquist				= 5,
 // Global, Integer, 1->1000
	kReverb2Param_RandomizeReflections				= 6,
 };

 */
-(void)updateSliderValue
{
    AudioUnitParameterValue value = [self.player getValueForParamId:kReverb2Param_DryWetMix];
    self.drywetmixSlider.value = value;
    value = [self.player getValueForParamId:kReverb2Param_Gain];
    self.gainSlider.value = value;
    value = [self.player getValueForParamId:kReverb2Param_MinDelayTime];
    self.mindelaySlider.value = value;
    value = [self.player getValueForParamId:kReverb2Param_MaxDelayTime];
    self.maxdelaySlider.value = value;
    value = [self.player getValueForParamId:kReverb2Param_DecayTimeAt0Hz];
    self.decay0hzSlider.value = value;
    value = [self.player getValueForParamId:kReverb2Param_DecayTimeAtNyquist];
    self.decaynyquistSlider.value = value;
    value = [self.player getValueForParamId:kReverb2Param_RandomizeReflections];
    self.randomizeSlider.value = value;
}

-(void)updateLabels
{
    self.drywetLabel.text = [NSString stringWithFormat:@"%.f",self.drywetmixSlider.value];
    self.gainLabel.text = [NSString stringWithFormat:@"%.f",self.gainSlider.value];
    self.mindelayLabel.text = [NSString stringWithFormat:@"%.4f",self.mindelaySlider.value];
    self.maxdelayLabel.text = [NSString stringWithFormat:@"%.4f",self.maxdelaySlider.value];
    self.decay0hzLabel.text = [NSString stringWithFormat:@"%.3f",self.decay0hzSlider.value];
    self.decaynyquistLabel.text = [NSString stringWithFormat:@"%.3f",self.decaynyquistSlider.value];
    self.reflectionLabel.text = [NSString stringWithFormat:@"%.f",self.randomizeSlider.value];
}

- (IBAction)sliderChanged:(id)sender
{
    UISlider *slider = (UISlider*)sender;
    
    AudioUnitParameterID paramId;
    
    if (slider == self.drywetmixSlider) {
        paramId = kReverb2Param_DryWetMix;
    } else if (slider == self.gainSlider) {
        paramId = kReverb2Param_Gain;
    } else if (slider == self.mindelaySlider) {
        paramId = kReverb2Param_MinDelayTime;
    } else if (slider == self.maxdelaySlider){
        paramId = kReverb2Param_MaxDelayTime;
    }
    else if (slider == self.decay0hzSlider){
        paramId = kReverb2Param_DecayTimeAt0Hz;
    }
    else if (slider == self.decaynyquistSlider){
        paramId = kReverb2Param_DecayTimeAtNyquist;
    }else if (slider == self.randomizeSlider){
        paramId = kReverb2Param_RandomizeReflections;
    }
    else {
        return;
    }
    
    AudioUnitParameterValue value = slider.value;
    [self.player setValue:value forParamId:paramId];
    
    [self updateLabels];

}
- (IBAction)reset:(id)sender {
    AudioUnitParameterValue value = 0.f;
    [self.player setValue:value forParamId:kReverb2Param_DryWetMix];
    value = 1.f;
    [self.player setValue:value forParamId:kReverb2Param_Gain];
    value = 0.008f;
    [self.player setValue:value forParamId:kReverb2Param_MinDelayTime];
    value = 0.050f;
    [self.player setValue:value forParamId:kReverb2Param_MaxDelayTime];
    value = 1.0f;
    [self.player setValue:value forParamId:kReverb2Param_DecayTimeAt0Hz];
    value = 0.5f;
    [self.player setValue:value forParamId:kReverb2Param_DecayTimeAtNyquist];
    value = 1.f;
    [self.player setValue:value forParamId:kReverb2Param_RandomizeReflections];
    [self updateSliderValue];
    [self updateLabels];
}

- (IBAction)start:(id)sender {
    [self.player start];
}
- (IBAction)stop:(id)sender {
    [self.player stop];
}

@end
