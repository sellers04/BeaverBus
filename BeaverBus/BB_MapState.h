//
//  BB_MapState.h
//  BeaverBus
//
//  Created by Nick on 9/16/14.
//  Copyright (c) 2014 Oregon State University. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <GoogleMaps/GoogleMaps.h>
#import "BB_ViewController.h"
#import "BB_Shuttle.h"

@interface BB_MapState : NSObject <GMSMapViewDelegate>

@property (strong, nonatomic) GMSMapView *mapView;
@property (strong, nonatomic) NSMutableArray *tempShuttles;
@property (strong, nonatomic) NSMutableArray *shuttles;
@property (strong, nonatomic) NSMutableArray *stops;

@property (strong, nonatomic) NSMutableDictionary *stopMarkers;
@property (strong, nonatomic) NSMutableDictionary *shuttleMarkers;

@property (strong, nonatomic) BB_Shuttle *selectedShuttle;

@property (strong, nonatomic) EasyTableView *tableView;
//@property (strong, nonatomic) NSSet *stopMarkers;
//@property (strong, nonatomic) NSSet *shuttleMarkers;

@property (strong, nonatomic) NSMutableArray *mapPoints;

@property (nonatomic) BOOL stopsRequestComplete;
@property (nonatomic) BOOL shuttleRequestComplete;
@property (nonatomic) BOOL didInitialRequest;


+ (BB_MapState *)get;
- (void)initMapView;
- (void)initStopMarkers;
- (void)initShuttleMarkers;
//- (void)initMapMarkers;
- (void)addRoutePolylines;
- (void)setShuttle:(int)index withNewShuttle:(BB_Shuttle *)newShuttle;
- (UIImage *)imageWithImage:(UIImage *)image scaledToSize:(CGSize)newSize;

@end
