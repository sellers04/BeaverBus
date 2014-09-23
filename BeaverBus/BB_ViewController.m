//
//  BB_ViewController.m
//  BeaverBus
//
//  Created by Nick on 9/16/14.
//  Copyright (c) 2014 Oregon State University. All rights reserved.
//

#import "BB_ViewController.h"
#import "BB_StopEstimatePair.h"
#include "BB_MapState.h"
#import <GoogleMaps/GoogleMaps.h>

@interface BB_ViewController ()

@property (strong, nonatomic) IBOutlet UIView *mainView;

@end

#define LABEL_TAG 100

@implementation BB_ViewController

@synthesize bottomView = _bottomView;


- (void)viewDidLoad
{
    [super viewDidLoad];

    CGFloat screenHeight = [UIScreen mainScreen].bounds.size.height;
    CGFloat screenWidth = [UIScreen mainScreen].bounds.size.width;

    self.view = [BB_MapState get].mapView;

    
    
    UIView * MApBaseView=[[UIView alloc]initWithFrame:CGRectZero];// add your frame size here
    //[self.view addSubview:MApBaseView];
    //[MApBaseView addSubview: [BB_MapState get].mapView];
    //self.view =
    
    EasyTableView *view = [[EasyTableView alloc] initWithFrame:CGRectMake(10, screenHeight-100, screenWidth-20, 90) numberOfColumns:4 ofWidth:60];
    
    //EasyTableView *view = [[EasyTableView alloc] initWithFrame:CGRectMake(10, screenHeight-100, screenWidth-20, 90)];
    
    [BB_MapState get].tableView = view;

    self.bottomView = view;
    
    self.bottomView.delegate = self;
    
    [self.view addSubview:self.bottomView];
    
    
    
    /*
    UITableView *bottomView = [[UITableView alloc] initWithFrame:CGRectMake(10, screenHeight-100, screenWidth-20, 90)];
    bottomView.backgroundColor = [UIColor colorWithRed:0 green:0 blue:0 alpha:.7];
    [self.view addSubview:bottomView];
     */
    
    

	// Do any additional setup after loading the view, typically from a nib.
}

-(NSUInteger)numberOfSectionsInEasyTableView:(EasyTableView *)easyTableView
{
    return 1;
}

-(NSUInteger)numberOfCellsForEasyTableView:(EasyTableView *)view inSection:(NSInteger)section
{
    NSUInteger count = [[BB_MapState get].selectedShuttle.stopEstimatePairs count];
    //NSLog(@"NumCells: %d", count);
    return count;
}

-(void)easyTableView:(EasyTableView *)easyTableView selectedView:(UIView *)selectedView atIndexPath:(NSIndexPath *)indexPath deselectedView:(UIView *)deselectedView
{
    GMSMarker *marker = ((BB_StopEstimatePair*)[[BB_MapState get].selectedShuttle.stopEstimatePairs objectAtIndex:[indexPath item]]).marker;
    [BB_MapState get].mapView.selectedMarker = marker;
    GMSCameraPosition *cameraPosition = [GMSCameraPosition cameraWithLatitude:marker.position.latitude longitude:marker.position.longitude zoom:[BB_MapState get].mapView.camera.zoom];
    [[BB_MapState get].mapView setCamera:cameraPosition];
}

- (UIView *)easyTableView:(EasyTableView *)easyTableView viewForRect:(CGRect)rect {

    
    BB_StopCell *newStopCell = [[BB_StopCell alloc] initWithFrame:rect];

    
    //[container addSubview:newStopCell];
	
	//return container;
    return [[[NSBundle mainBundle] loadNibNamed:@"StopCell" owner:self options:nil] firstObject];
}

// Second delegate populates the views with data from a data source



- (void)easyTableView:(EasyTableView *)easyTableView setDataForView:(UIView *)view forIndexPath:(NSIndexPath *)indexPath {
    NSMutableArray *shuttles = [BB_MapState get].shuttles;
    //BB_Shuttle *shuttle = shuttles[0];
    BB_Shuttle *shuttle = [BB_MapState get].selectedShuttle;
    
    
	// Set the image title for the given index
	UILabel *label = (UILabel *)[view viewWithTag:LABEL_TAG];
    
    BB_StopCell *customView = view;
    
    customView.ETAToStop.text = [NSString stringWithFormat:@"%@", ((BB_StopEstimatePair*)[shuttle.stopEstimatePairs objectAtIndex:[indexPath item]]).eta];
    
    if([indexPath row] < 3){
        customView.indexNumber.text = [NSString stringWithFormat:@"%d", ([indexPath item] + 1)];
    }else{
        customView.indexNumber.backgroundColor = customView.backgroundColor;
    }
    
    
    NSLog(@"IndexatPosition 0: %@ and row: %d", indexPath, [indexPath row]);
    
}




- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
