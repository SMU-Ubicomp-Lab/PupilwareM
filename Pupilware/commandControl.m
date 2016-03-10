//
//  commandControl.m
//  CogSense
//
//  Created by Sohail Rafiqi on 1/31/15.
//  Copyright (c) 2015 SMU. All rights reserved.
//

#import "commandControl.h"

@interface commandControl ()

    @property(nonatomic, strong) NSArray *expTypeList;
    @property(nonatomic, strong) NSArray *iterationTypeList;

@end

@implementation commandControl

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    _expTypeList = @[@"Baseline", @"Game", @"Digit5", @"Digit6", @"Digit7", @"Digit8", @"Digit9"];
    _iterationTypeList = @[@"Iter1", @"Iter2", @"Iter3", @"Iter4"];

    
    // Connect data
    self.expPicker.dataSource = self;
    self.expPicker.delegate = self;
    
    self.idText.delegate = self;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}
- (IBAction)onTab:(id)sender {
    [self.idText resignFirstResponder];
}

#pragma mark - text field delegate

-(BOOL)textFieldShouldBeginEditing:(UITextField *)textField
{
    return YES;
}

-(BOOL)textFieldShouldReturn:(UITextField *)textField
{
    [textField resignFirstResponder];
    return YES;
}

#pragma mark - picker data source

// The number of columns of data
- (NSInteger)numberOfComponentsInPickerView:(UIPickerView *)pickerView
{
    return 2;
}

// The number of rows of data
- (NSInteger)pickerView:(UIPickerView *)pickerView numberOfRowsInComponent:(NSInteger)component
{
    //set number of rows
    if(component== 0)
    {
        return self.expTypeList.count;
    }
    else
    {

        return self.iterationTypeList.count;
    }
    
}


-(void)pickerView:(UIPickerView *)pickerView didSelectRow:(NSInteger)row inComponent:(NSInteger)component
{
    // NSLog(@"Selected Row %d", row);
    if (component == 0)
    {
        self.experiment.text = _expTypeList[row];
    }
    else
    {
        self.iteration.text = _iterationTypeList[row];
    }
    self.idText.text = _idText.text;
}



// The data to return for the row and component (column) that's being passed in
- (NSString*)pickerView:(UIPickerView *)pickerView titleForRow:(NSInteger)row forComponent:(NSInteger)component
{
   // NSLog(@"Selected Row %d", row);
    if (component == 0)
    {
        return _expTypeList[row];
    }else
    {
        return _iterationTypeList[row];
    }
}

- (IBAction)exitToHere:(UIStoryboardSegue *)sender {
    // Execute this code upon unwinding.
}

/*
#pragma mark - Navigation
*/
// In a storyboard-based application, you will often want to do a little preparation before navigation
//- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
//    // Get the new view controller using [segue destinationViewController].
//    // Pass the selected object to the new view controller.

 - (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
 if ([[segue identifier] isEqualToString:@"toViewController"]) {
 PWViewController *nextVC = (PWViewController *)[segue destinationViewController];
 
     NSInteger expID = [self.expPicker selectedRowInComponent:0];
     NSInteger iterID = [self.expPicker selectedRowInComponent:1];
     
     nextVC.participant = [NSString stringWithFormat:@"ID%@",self.idText.text];
     nextVC.experiment = [self.expTypeList objectAtIndex: expID];
     nextVC.iteration = [self.iterationTypeList objectAtIndex: iterID];
     nextVC.isRunnningFromVideoMode = false;
     
     NSLog(@"Participant Id in segue %s", [nextVC.participant UTF8String]);

     if ([nextVC.experiment isEqualToString:@"Baseline"])
         nextVC.baseline = true;
     else
         nextVC.baseline = false;
     
     if ([nextVC.experiment isEqualToString:@"Game"])
         nextVC.game = true;
     else
         nextVC.game = false;
     NSLog(@"Value of baseline %hhd%hhd", nextVC.baseline, nextVC.game);
     NSLog(@"Experiment Name   %s", [nextVC.experiment UTF8String]);
     NSLog(@"Participant Name   %s", [nextVC.participant UTF8String]);


 }
}


@end
