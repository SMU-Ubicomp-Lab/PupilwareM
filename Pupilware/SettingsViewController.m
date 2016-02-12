//
//  SettingsViewController.m
//  CogSense
//
//  Created by Sohail Rafiqi on 2/5/15.
//  Copyright (c) 2015 SMU. All rights reserved.
//

#import "SettingsViewController.h"
#import "constants.h"

@interface SettingsViewController ()


@end

@implementation SettingsViewController


- (void)viewDidLoad {
    
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    
    float eyeDistance_l           = [defaults floatForKey:kEyeDistance];
    NSInteger windowSize_l        = [defaults integerForKey:kWindowSize];
    NSInteger mbWindowSize_l      = [defaults integerForKey:kMbWindowSize];
    NSInteger baselineStart_l     = [defaults integerForKey:kBaselineStart];
    NSInteger baselineEnd_l       = [defaults integerForKey:kBaselineEnd];
    NSInteger threshold_l         = [defaults integerForKey:kThreshold];
    NSInteger makeCost_l          = [defaults integerForKey:kMarkCost];
    float baseline_l              = [defaults floatForKey:kBaseline];
    float cogHighSize_l             = [defaults floatForKey:kCogHighSize];

    
    NSString *eyeDistanceString     = [NSString stringWithFormat:@"%f", eyeDistance_l];
    NSString *windowSizeString      = [NSString stringWithFormat:@"%li", windowSize_l];
    NSString *mbWindowSizeString    = [NSString stringWithFormat:@"%li", mbWindowSize_l];
    NSString *baslineStartString    = [NSString stringWithFormat:@"%li", baselineStart_l];
    NSString *baslineEndString      = [NSString stringWithFormat:@"%li", baselineEnd_l];
    NSString *thresholdString       = [NSString stringWithFormat:@"%li", threshold_l];
    NSString *markCostString        = [NSString stringWithFormat:@"%li", makeCost_l];
    NSString *baselineString        = [NSString stringWithFormat:@"%f", baseline_l];
    NSString *cogHighString         = [NSString stringWithFormat:@"%f", cogHighSize_l];

    self.s_eyeDistance.text     = eyeDistanceString;
    self.s_windowSize.text      = windowSizeString;
    self.s_mbWindowSize.text    = mbWindowSizeString;
    self.s_baselineStart.text   = baslineStartString;
    self.s_baselineEnd.text     = baslineEndString;
    self.s_threshold.text       = thresholdString;
    self.s_markCost.text        = markCostString;
    self.s_baseline.text        = baselineString;
    self.s_cogHightSize.text    = cogHighString;

    
    NSLog(@"Data Loaded");


    // Do any additional setup after loading the view.
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(void)closeKeyboard
{
    [self.s_eyeDistance resignFirstResponder];
    [self.s_windowSize resignFirstResponder];
    [self.s_mbWindowSize resignFirstResponder];
    [self.s_baselineStart resignFirstResponder];
    [self.s_baselineEnd resignFirstResponder];
    [self.s_threshold resignFirstResponder];
    [self.s_markCost resignFirstResponder];
    [self.s_baseline resignFirstResponder];
    [self.s_cogHightSize resignFirstResponder];
}

-(void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event
{
    [self closeKeyboard];
}

- (IBAction)save:(id)sender
{
    // Hide the keyboard
    [self closeKeyboard];

    
    // Create strings and integer to store the text info
    
    float eyeDistance       = [[self.s_eyeDistance text] floatValue];
    NSInteger windowSize    = [[self.s_windowSize text] integerValue];
    NSInteger mbWindowSize  = [[self.s_mbWindowSize text] integerValue];
    NSInteger baslineStart  = [[self.s_baselineStart text] integerValue];
    NSInteger baselineEnd   = [[self.s_baselineEnd text] integerValue];
    NSInteger threshold     = [[self.s_threshold text] integerValue];
    NSInteger markCost      = [[self.s_markCost text] integerValue];
    float baseline          = [[self.s_baseline text] floatValue];
    float cogHighSize       = [[self.s_cogHightSize text] floatValue];
    
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    
    [defaults setFloat:eyeDistance forKey:kEyeDistance];
    [defaults setInteger:windowSize forKey:kWindowSize];
    [defaults setInteger:mbWindowSize forKey:kMbWindowSize];
    [defaults setInteger:baslineStart forKey:kBaselineStart];
    [defaults setInteger:baselineEnd forKey:kBaselineEnd];
    [defaults setInteger:threshold forKey:kThreshold];
    [defaults setInteger:markCost forKey:kMarkCost];
    [defaults setFloat:baseline forKey:kBaseline];
    [defaults setFloat:cogHighSize forKey:kCogHighSize];

    [defaults synchronize];
    
    NSLog(@"Data saved");
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/


- (void)viewDidUnload
{
    [super viewDidUnload];
 }

@end
