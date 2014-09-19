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

@implementation BB_ViewController

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
    UIView *bottomView = [[UIView alloc] initWithFrame:CGRectMake(10, screenHeight-100, screenWidth-20, 90)];

    bottomView.backgroundColor = [UIColor colorWithRed:80 green:0 blue:80 alpha:.7];
    [self.view addSubview:bottomView];

    //[[[NSBundle mainBundle] loadNibNamed:@"MyCustomView" owner:self options:nil] objectAtIndex:0];

    //NSArray *bottomSegment = [[NSBundle mainBundle] loadNibNamed:@"BottomSubView" owner:self options:nil];
    //UIView *bottomSegView = [bottomSegment objectAtIndex:0];
    //bottomSegView.backgroundColor = [UIColor colorWithRed:0 green:80 blue:80 alpha:.7];
    //[bottomView addSubview:bottomSegView];



    //[self.view addSubview:[self mainView]];
    //mapView.bounds = CGRectMake(0, 0, 100, 100);

	// Do any additional setup after loading the view, typically from a nib.
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
