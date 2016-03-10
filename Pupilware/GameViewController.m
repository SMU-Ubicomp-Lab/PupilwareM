//
//  GameViewController.m
//  CogSense
//
//  Created by Sohail Rafiqi on 3/6/15.
//  Copyright (c) 2015 SMU. All rights reserved.
//

#import "GameViewController.h"
#import "PWViewController.h"

@interface GameViewController ()

@end

@implementation GameViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    [super viewDidLoad];
    PWViewController *pwViewController = [[PWViewController alloc]init];
    pwViewController.participant = @"979";
    pwViewController.experiment = @"Game";
    pwViewController.iteration = @"1";

    [pwViewController preparePupilProcessor];
    NSLog(@"Calling video camera");
    
   // [[pwViewController videoCamera](UIView *)imageViewForGame];


    NSString *fullURL = @"http://html5games.com/Game/Flow-Free/8557fc8f-26b3-4bc1-a770-d4fa798a30ca";
    NSURL *url = [NSURL URLWithString:fullURL];
    NSURLRequest *requestObj = [NSURLRequest requestWithURL:url];
    [_gameView loadRequest:requestObj];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
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
