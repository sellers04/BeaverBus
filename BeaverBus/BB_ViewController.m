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
#import <UIKit/UIKit.h>


@interface BB_ViewController ()

@property (strong, nonatomic) IBOutlet UIView *mainView;

@end

#define LABEL_TAG 100

@implementation BB_ViewController

UIView *updateErrorView;
NSMutableArray *changedStopEstimatePairs;


- (void)viewDidLoad
{
    [super viewDidLoad];

    self.navigationItem.leftBarButtonItem=[self OSULogoBar];
    self.navigationItem.rightBarButtonItem =[self optionsBar];
    self.navigationItem.title = @"Beaver Bus Tracker";

    changedStopEstimatePairs = [[NSMutableArray alloc] init];

    UIAlertView *networkFailAlert =  [[UIAlertView alloc] initWithTitle:@"Unable to request data" message:@"Try again or press Home" delegate:self cancelButtonTitle:nil otherButtonTitles:@"Try again", nil];

    self.view = [BB_MapState get].mapView;

    if (![BB_MapState get].didInitialRequest){
        //Initial request failed, show try again dialog
        [networkFailAlert show];
    }
    // Else, continue

	// Do any additional setup after loading the view, typically from a nib.
}

-(UIBarButtonItem *)OSULogoBar
{
    UIImage *image = [UIImage imageNamed:@"osu_icon.png"];
    CGRect buttonFrame = CGRectMake(0, 0, image.size.width, image.size.height);
    UIButton *button = [[UIButton alloc] initWithFrame:buttonFrame];
    [button setImage:image forState:UIControlStateNormal];
    UIBarButtonItem *item = [[UIBarButtonItem alloc] initWithCustomView:button];

    return item;
}

-(UIBarButtonItem *)optionsBar
{
    UIImage *image = [UIImage imageNamed:@"settingsGear.png"];
    CGRect buttonFrame = CGRectMake(0, 0, image.size.width, image.size.height);
    UIButton *button = [[UIButton alloc] initWithFrame:buttonFrame];
    [button setImage:image forState:UIControlStateNormal];

    [button addTarget:self action:@selector(openOptionsMenu) forControlEvents:UIControlEventValueChanged];

    UIBarButtonItem *item = [[UIBarButtonItem alloc] initWithCustomView:button];

    return item;
}

- (void)openOptionsMenu
{
    
}

-(void)viewDidAppear:(BOOL)animated
{

    
}

- (void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex
{
        //Repeat the initial network request
        if (![[BB_ShuttleUpdater get] initialNetworkRequest]) {
            UIAlertView *networkFailAlert =  [[UIAlertView alloc] initWithTitle:@"Unable to request data" message:@"Try again or press Home" delegate:self cancelButtonTitle:nil otherButtonTitles:@"Try again", nil];
            [networkFailAlert show];
        }
}

- (void)moveToMyLocation:(id) sender
{
    CLLocation *location = [BB_MapState get].mapView.myLocation;
    if (location){
        [[BB_MapState get].mapView animateToLocation:location.coordinate];
    }

}

- (void)showUpdateErrorView
{

}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
