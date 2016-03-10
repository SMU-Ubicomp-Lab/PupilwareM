//
//  TargetTestViewController.m
//  CogSense
//
//  Created by Sohail Rafiqi on 11/5/15.
//  Copyright (c) 2015 SMU. All rights reserved.
//

#import "TargetTestViewController.h"
#import <AVFoundation/AVAudioPlayer.h>

@interface TargetTestViewController ()
@property (weak, nonatomic) IBOutlet UIWebView *targetTestUIView;
@property (weak, nonatomic) IBOutlet UIButton *startTargetTest;
@property (weak, nonatomic) IBOutlet UIButton *outOfSequenceButton;
@property (weak, nonatomic) IBOutlet UIButton *endIteration;

@end

@implementation TargetTestViewController


AVAudioPlayer *audioPlayer;
NSInteger iteration = 0;

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    self.targetTestUIView.opaque = NO;
    self.targetTestUIView.backgroundColor = [UIColor blackColor];
    self.view.backgroundColor = [UIColor blackColor];
    self.outOfSequenceButton.hidden = true;
    self.iterationLabel.hidden = true;
    // self.backButton.hidden = true;

}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}
- (IBAction)startTargetTest:(UIButton *)sender {
    NSLog(@"Inside start Target Test");
    self.outOfSequenceButton.hidden = false;
    self.startTargetTest.hidden = true;
    iteration++;
    self.iterationText.hidden = false;
    self.iterationText.text = [NSString stringWithFormat:@"%d", iteration];
    
    self.iterationLabel.hidden = false;

    
    self.iterationText.textColor = [UIColor whiteColor];
    
    NSString *audioFile;
    audioFile = [NSString stringWithFormat:@"%@%@%@", @"Digit5", @"_", @"Iter1"];
    NSLog(@"File aaaa name %s", [audioFile UTF8String]);
    
    NSString *soundFile=[[NSBundle mainBundle] pathForResource:audioFile ofType:@"mp3"];
    
    NSError *error = nil;
    
    audioPlayer = [[ AVAudioPlayer alloc] initWithContentsOfURL:[ NSURL fileURLWithPath: soundFile] error:&error];
    
    if (error)
    {
        NSLog(@"Error in audioPlayer: %@",[error localizedDescription]);
    }
    else
    {
        [audioPlayer play];
        
    }
    
}
- (IBAction)outOfSequenceNumberDetected:(UIButton *)sender {
    NSLog(@"Hit out of sequence");
    
}
- (IBAction)endTargetTestIteration:(UIButton *)sender {
    if (iteration == 4)
    {
        NSLog(@"Exit now");
    
        self.startTargetTest.hidden = true;
        self.outOfSequenceButton.hidden = true;
        self.iterationLabel.hidden = true;
        self.iterationText.hidden = true;
        self.endIteration.hidden = true;
       // self.backButton.hidden = false;
        [audioPlayer stop];
    }

    else
    {
        self.startTargetTest.hidden = false;
        self.outOfSequenceButton.hidden = true;
        self.iterationLabel.hidden = true;
        self.iterationText.hidden = true;
        [audioPlayer stop];
    }
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
