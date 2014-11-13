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
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.player = [[AUGraphPlayer alloc]init];
    // Do any additional setup after loading the view, typically from a nib.
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}
- (IBAction)start:(id)sender {
    [self.player start];
}
- (IBAction)stop:(id)sender {
    [self.player stop];
}

@end
