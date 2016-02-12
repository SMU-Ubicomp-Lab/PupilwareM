//
//  VideoDisplayViewController.m
//  CogSense
//
//  Created by Sohail Rafiqi on 2/4/15.
//  Copyright (c) 2015 SMU. All rights reserved.
//

#import "VideoDisplayViewController.h"

@interface VideoDisplayViewController ()

@property(strong, nonatomic) NSArray *partData_v;
@property(strong, nonatomic) NSArray *experData_v;
@property(strong, nonatomic) NSArray *iterData_v;
@property (weak, nonatomic) IBOutlet UISegmentedControl *calibTypeSegment;

@end

@implementation VideoDisplayViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view
    self.partData_v = @[@"ID502", @"ID503",
                        @"ID504", @"ID505",
                        @"ID506", @"ID507",
                        @"ID510", @"ID511",
                        @"ID512", @"ID513",
                        @"ID514",@"ID515", @"ID516",@"ID517",@"ID518", @"ID519"];
    
    self.experData_v = @[@"Baseline", @"Game", @"Digits5",
                         @"Digits6", @"Digits7",
                         @"Digits8", @"Digits9"];
    
    self.iterData_v = @[@"Iter1", @"Iter2",
                        @"Iter3", @"Iter4"];
    
    
    // Connect data
    self.part_IterPicker.dataSource = self;
    self.part_IterPicker.delegate = self;

}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

// The number of columns of data
- (NSInteger)numberOfComponentsInPickerView:(UIPickerView *)pickerView
{
    return 3;
}

// The number of rows of data
- (NSInteger)pickerView:(UIPickerView *)pickerView numberOfRowsInComponent:(NSInteger)component
{
    //set number of rows
    if(component== 0)
    {
        return _partData_v.count;
    }
    else if (component == 1)
    {
        
        return _experData_v.count;
    }
    else
    {
        return _iterData_v.count;
    }
    
}

-(void)pickerView:(UIPickerView *)pickerView didSelectRow:(NSInteger)row inComponent:(NSInteger)component
{
    // NSLog(@"Selected Row %d", row);
    if (component == 0)
    {
        self.participant_v.text = _partData_v[row];
    }
    else if (component == 1)
    {
        self.experiment_v.text = _experData_v[row];
    }
    else
    {
        self.iteration_v.text = _iterData_v[row];
    }
}

// The data to return for the row and component (column) that's being passed in
- (NSString*)pickerView:(UIPickerView *)pickerView titleForRow:(NSInteger)row forComponent:(NSInteger)component
{
    // NSLog(@"Selected Row %d", row);
    if (component == 0)
    {
        return _partData_v[row];
    }
    else if (component == 1)
    {
        return _experData_v[row];
    }
    else
    {
        return _iterData_v[row];
    }
    
}

- (IBAction)exitToHere:(UIStoryboardSegue *)sender {
    // Execute this code upon unwinding.
}





#pragma mark - Navigation

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([[segue identifier] isEqualToString:@"toVideoViewController"]) {
        PWViewController *nextVC = (PWViewController *)[segue destinationViewController];
        
        NSInteger participantID = [self.part_IterPicker selectedRowInComponent:0];
        NSInteger expID = [self.part_IterPicker selectedRowInComponent:1];
        NSInteger iterID = [self.part_IterPicker selectedRowInComponent:2];
        
        nextVC.participant = [self.partData_v objectAtIndex:participantID];
        nextVC.experiment = [self.experData_v objectAtIndex:expID];
        nextVC.iteration = [self.iterData_v objectAtIndex:iterID];

        nextVC.isRunnningFromVideoMode = true;
        
        // NSLog(@"Experiment Name   %s", [nextVC.experiment UTF8String]);
        
    }
    
    if ([[segue identifier] isEqualToString:@"toCalibrateViewController"]) {
    
        CalibrateViewController *nextVC = (CalibrateViewController *)[segue destinationViewController];
        
        NSInteger participantID = [self.part_IterPicker selectedRowInComponent:0];
        NSInteger expID = [self.part_IterPicker selectedRowInComponent:1];
        NSInteger iterID = [self.part_IterPicker selectedRowInComponent:2];
        
        nextVC.participant = [self.partData_v objectAtIndex:participantID];
        nextVC.experiment = [self.experData_v objectAtIndex:expID];
        nextVC.iteration = [self.iterData_v objectAtIndex:iterID];
        
        nextVC.isRunnningFromVideoMode = true;
        nextVC.isCalibCogMax = (self.calibTypeSegment.selectedSegmentIndex == 1);
        
    }


}
@end
