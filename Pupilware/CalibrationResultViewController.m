//
//  DisplayDataViewController.m
//  CogSense
//
//  Created by Sohail Rafiqi on 2/4/15.
//  Copyright (c) 2015 SMU. All rights reserved.
//


#import "CalibrationResultViewController.h"
#import "constants.h"


@interface CalibrationResultViewController ()

@property(nonatomic)NSInteger minIdx;

@end

@implementation CalibrationResultViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    NSNumber *min=[self.stdValues valueForKeyPath:@"@min.self"];
    self.minIdx = [self.stdValues indexOfObject:min];
    
    self.myGraph.dataSource = self;
    self.myGraph.delegate = self;
    
    self.myGraph2.dataSource = self;
    self.myGraph2.delegate = self;
    
    self.myGraph3.dataSource = self;
    self.myGraph3.delegate = self;
    
    self.myGraph4.dataSource = self;
    self.myGraph4.delegate = self;
    
    self.myGraph5.dataSource = self;
    self.myGraph5.delegate = self;
    
    if(self.isCalibMax)
    {
        [self setupGraph:self.myGraph isSelected:YES];
        self.myGraph2.hidden = YES;
        self.myGraph3.hidden = YES;
        self.myGraph4.hidden = YES;
        self.myGraph5.hidden = YES;
        
        self.sdLabel2.hidden = YES;
        self.sdLabel3.hidden = YES;
        self.sdLabel4.hidden = YES;
        self.sdLabel5.hidden = YES;
        
        self.sdLabel1.text = [NSString stringWithFormat:@"Cog Peak %@", self.thePeak ];
    }
    else
    {
        
        [self setupGraph:self.myGraph isSelected:(0 == self.minIdx)];
        [self setupGraph:self.myGraph2 isSelected:(1 == self.minIdx)];
        [self setupGraph:self.myGraph3 isSelected:(2 == self.minIdx)];
        [self setupGraph:self.myGraph4 isSelected:(3 == self.minIdx)];
        [self setupGraph:self.myGraph5 isSelected:(4 == self.minIdx)];

        self.sdLabel1.text = [NSString stringWithFormat:@"MADR %@", [self.stdValues objectAtIndex: 0] ];
        self.sdLabel2.text = [NSString stringWithFormat:@"MADR %@", [self.stdValues objectAtIndex: 1] ];
        self.sdLabel3.text = [NSString stringWithFormat:@"MADR %@", [self.stdValues objectAtIndex: 2] ];
        self.sdLabel4.text = [NSString stringWithFormat:@"MADR %@", [self.stdValues objectAtIndex: 3] ];
        self.sdLabel5.text = [NSString stringWithFormat:@"MADR %@", [self.stdValues objectAtIndex: 4] ];
    }
}

-(void)setupGraph:(BEMSimpleLineGraphView*)graphView isSelected:(BOOL) isSelect
{
    if (isSelect)
    {
        graphView.colorTop = [UIColor colorWithRed:31.0/255.0 green:187.0/255.0 blue:166.0/255.0 alpha:1.0];
        graphView.colorBottom = [UIColor colorWithRed:31.0/255.0 green:187.0/255.0 blue:166.0/255.0 alpha:1.0];
    }

    graphView.colorLine = [UIColor whiteColor];
    graphView.colorXaxisLabel = [UIColor whiteColor];
    graphView.colorYaxisLabel = [UIColor whiteColor];
    //self.myGraph.widthLine = 3.0;
    graphView.enableTouchReport = YES;
    graphView.enablePopUpReport = YES;
    graphView.enableBezierCurve = YES;
    graphView.enableYAxisLabel = YES;
    graphView.autoScaleYAxis = YES;
    graphView.alwaysDisplayDots = NO;
    //self.myGraph.enableReferenceXAxisLines = YES;
    graphView.enableReferenceYAxisLines = YES;
    graphView.enableReferenceAxisFrame = YES;
    graphView.animationGraphStyle = BEMLineAnimationDraw;
}

-(void)viewWillAppear:(BOOL)animated
{

}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)setBestParameter:(id)sender
{
    [sender setEnabled:NO];
    
    if(self.isCalibMax)
    {
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        
        [defaults setFloat:[self.thePeak floatValue] forKey:kCogHighSize];
    }
    else
    {
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        
        [defaults setFloat:[self getBaseline] forKey:kBaseline];
        
        // minIdx = 0 is the default parameter,
        // so do nothing.
        if(self.minIdx == 0) return;
        
        
       
        
        PWParameter* bestParameter = [self.parameters objectAtIndex:self.minIdx ];
        
        [defaults setInteger:bestParameter.threadhold forKey:kThreshold];
        [defaults setInteger:bestParameter.markCost forKey:kMarkCost];
        
    }
}

-(float)getBaseline
{
    return  [[self.baselineValues objectAtIndex: self.minIdx] floatValue];
}

#pragma mark - Simple Line Graph Data Source
-(NSInteger)numberOfPointsInLineGraph:(BEMSimpleLineGraphView *)graph
{
    if (graph == self.myGraph) {
        return [self.dataPoints count];
    }
    else if (graph == self.myGraph2) {
        return [self.dataPoints2 count];
    }
    else if (graph == self.myGraph3) {
        return [self.dataPoints3 count];
    }
    else if (graph == self.myGraph4) {
        return [self.dataPoints4 count];
    }else{
        return [self.dataPoints5 count];
    }
}
-(CGFloat)lineGraph:(BEMSimpleLineGraphView *)graph valueForPointAtIndex:(NSInteger)index
{
    // multiply by 10000 because the graph view does not support float label.
    
    if (graph == self.myGraph) {
        return [[self.dataPoints objectAtIndex:index] floatValue]*10000;
    }
    else if (graph == self.myGraph2) {
        return [[self.dataPoints2 objectAtIndex:index] floatValue]*10000;
    }
    else if (graph == self.myGraph3) {
        return [[self.dataPoints3 objectAtIndex:index] floatValue]*10000;
    }
    else if (graph == self.myGraph4) {
        return [[self.dataPoints4 objectAtIndex:index] floatValue]*10000;
    }else{
        return [[self.dataPoints5 objectAtIndex:index] floatValue]*10000;
    }
    
}

#pragma mark - Table View Datasource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return 6;
}

#pragma mark - simple Line Graph Delegate
- (NSInteger)numberOfGapsBetweenLabelsOnLineGraph:(BEMSimpleLineGraphView *)graph
{
    return 1;
}

- (NSString *)lineGraph:(BEMSimpleLineGraphView *)graph labelOnXAxisForIndex:(NSInteger)index
{
    NSString *label = [NSString stringWithFormat:@"%ld", (long)index];
    return [label stringByReplacingOccurrencesOfString:@" " withString:@"\n"];
}

-(NSInteger)numberOfYAxisLabelsOnLineGraph:(BEMSimpleLineGraphView *)graph
{
    return 3;
}

@end
