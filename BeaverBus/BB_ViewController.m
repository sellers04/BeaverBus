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


@end

@implementation BB_ViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.view = [BB_MapState get].mapView;
    
	// Do any additional setup after loading the view, typically from a nib.
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
