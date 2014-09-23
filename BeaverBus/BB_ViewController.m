//
//  BB_ViewController.m
//  BeaverBus
//
//  Created by Nick on 9/16/14.
//  Copyright (c) 2014 Oregon State University. All rights reserved.
//

#import "BB_ViewController.h"
#include "BB_MapState.h"
#import <GoogleMaps/GoogleMaps.h>

@interface BB_ViewController ()

@property (strong, nonatomic) IBOutlet UIView *mainView;

@end

#define LABEL_TAG 100

@implementation BB_ViewController

UIView *updateErrorView;
UIAlertView *networkFailAlert;

@synthesize bottomView = _bottomView;


- (void)viewDidLoad
{
    [super viewDidLoad];


    CGFloat screenHeight = [UIScreen mainScreen].bounds.size.height;
    CGFloat screenWidth = [UIScreen mainScreen].bounds.size.width;


    UIButton *myLocationButton = [UIButton buttonWithType:UIButtonTypeInfoDark];
    [myLocationButton addTarget:self action:@selector(moveToMyLocation:) forControlEvents:UIControlEventTouchUpInside];
    [myLocationButton setTitle:@"My LOC" forState:UIControlStateNormal];
    myLocationButton.frame = CGRectMake(10, 10, 90, 50);

    networkFailAlert =  [[UIAlertView alloc] initWithTitle:@"Unable to request data" message:@"Try again or press Home" delegate:self cancelButtonTitle:nil otherButtonTitles:@"Try again", nil];

    self.view = [BB_MapState get].mapView;

[self.view addSubview:myLocationButton];

    if ([BB_MapState get].didInitialRequest){

        UIView * MApBaseView=[[UIView alloc]initWithFrame:CGRectZero];// add your frame size here
        //[self.view addSubview:MApBaseView];
        //[MApBaseView addSubview: [BB_MapState get].mapView];
        //self.view =
        
        EasyTableView *view = [[EasyTableView alloc] initWithFrame:CGRectMake(10, screenHeight-100, screenWidth-20, 90) numberOfColumns:8 ofWidth:60];
        
        self.bottomView = view;
        
        self.bottomView.delegate = self;
        
        [self.view addSubview:self.bottomView];


        
        /*
        UITableView *bottomView = [[UITableView alloc] initWithFrame:CGRectMake(10, screenHeight-100, screenWidth-20, 90)];
        bottomView.backgroundColor = [UIColor colorWithRed:0 green:0 blue:0 alpha:.7];
        [self.view addSubview:bottomView];
         */
    
    }
    else{
        //Initial request failed, show try again dialog
        [networkFailAlert show];

    }

	// Do any additional setup after loading the view, typically from a nib.
}

- (void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex{

        //repeat the initial network request
        if (![[BB_ShuttleUpdater get] initialNetworkRequest]) {
            /*UIAlertView *networkFailAlert =  [[UIAlertView alloc] initWithTitle:@"Unable to request data" message:@"Try again or press Home" delegate:self cancelButtonTitle:nil otherButtonTitles:@"Try again", nil];*/
            [networkFailAlert show];
        }

}

- (void)moveToMyLocation{
    CLLocation *location = [BB_MapState get].mapView.myLocation;
    if (location){
        [[BB_MapState get].mapView animateToLocation:location.coordinate];
    }

}

- (void)showUpdateErrorView{




}


- (UIView *)easyTableView:(EasyTableView *)easyTableView viewForRect:(CGRect)rect {
	// Create a container view for an EasyTableView cell
	
   // UIView *container = [[UIView alloc] initWithFrame:rect];
    
	/*
    
    
	// Setup a label to display the image title
	CGRect labelRect		= CGRectMake(10, rect.size.height-20, rect.size.width-20, 20);
	UILabel *label			= [[UILabel alloc] initWithFrame:labelRect];

	label.textAlignment		= NSTextAlignmentCenter;

	label.textColor			= [UIColor colorWithWhite:0 alpha:0.5];
	label.backgroundColor	= [UIColor clearColor];
	label.font				= [UIFont boldSystemFontOfSize:14];
	label.tag               = LABEL_TAG;
    
	[container addSubview:label];*/
    
    BB_StopCell *newStopCell = [[BB_StopCell alloc] initWithFrame:rect];

    
    //[container addSubview:newStopCell];
	
	//return container;
    return [[[NSBundle mainBundle] loadNibNamed:@"StopCell" owner:self options:nil] firstObject];
}

// Second delegate populates the views with data from a data source

- (void)easyTableView:(EasyTableView *)easyTableView setDataForView:(UIView *)view forIndexPath:(NSIndexPath *)indexPath {
    
    
	// Set the image title for the given index
	UILabel *label = (UILabel *)[view viewWithTag:LABEL_TAG];
	label.text = @"TEST TEXT";
}




- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
