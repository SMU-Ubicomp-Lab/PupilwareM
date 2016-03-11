//
//  LauncherViewController.m
//  CogSense
//
//  Created by Sohail Rafiqi on 2/5/15.
//  Copyright (c) 2015 SMU. All rights reserved.
//

#import "LauncherViewController.h"

@interface LauncherViewController ()

@end

@implementation LauncherViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    // NSLog(@"LaunchViewController: viewDidLoad");
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)exitToHome:(UIStoryboardSegue *)sender {
    // Execute this code upon unwinding.
    // NSLog(@"Inside the exit to home");
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
