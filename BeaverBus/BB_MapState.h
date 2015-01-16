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
#import "BB_MenuViewController.h"
#import "BB_Shuttle.h"

@interface BB_MapState : NSObject <GMSMapViewDelegate>

@property (strong, nonatomic) NSMutableArray *favorites;

@property (strong, nonatomic) GMSMapView *mapView;
@property (strong, nonatomic) NSMutableArray *tempShuttles;
@property (strong, nonatomic) NSMutableArray *shuttles;
@property (strong, nonatomic) NSMutableArray *stops;
@property BOOL stopsVisible;

@property (strong, nonatomic) NSMutableDictionary *stopIDObjectPairs;

@property (strong, nonatomic) NSMutableDictionary *stopMarkers;
@property (strong, nonatomic) NSMutableDictionary *shuttleMarkers;

@property (strong, nonatomic) BB_Shuttle *selectedShuttle;

@property (strong, nonatomic) NSMutableArray *mapPoints;

@property (strong, nonatomic) GMSPolyline *northPolyline;
@property (strong, nonatomic) GMSPolyline *westPolyline;
@property (strong, nonatomic) GMSPolyline *eastPolyline;

@property (nonatomic) BOOL stopsRequestComplete;
@property (nonatomic) BOOL shuttleRequestComplete;
@property (nonatomic) BOOL didInitialRequest;

@property BOOL stopsInvalid;

@property BB_ViewController *mainViewController;


+ (BB_MapState *)get;
- (void)initMapView;
- (void)initStopMarkers;
- (void)initShuttleMarkers;
- (void)addRoutePolylines;
- (void)setShuttle:(int)index withNewShuttle:(BB_Shuttle *)newShuttle;
- (void)changeStopsVisibility;
- (void)onFavoriteTap:(BB_Stop *)stop;

@end
