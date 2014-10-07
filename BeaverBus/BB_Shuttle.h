//
//  BB_Shuttle.h
//  BeaverBus
//
//  Created by Nick on 9/16/14.
//  Copyright (c) 2014 Oregon State University. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <GoogleMaps/GoogleMaps.h>
#import "BB_StopEstimatePair.h"

@interface BB_Shuttle : NSObject

@property(nonatomic) double latitude, longitude;
@property(strong, nonatomic) NSNumber *heading;
@property(strong, nonatomic) NSString *name;
@property(strong, nonatomic) NSNumber *vehicleID;
@property(strong, nonatomic) NSNumber *routeID;
@property(nonatomic) BOOL isOnline;
@property(strong, nonatomic) GMSMarker *marker;
@property(strong, nonatomic) NSString *imageName;
@property(nonatomic) double groundSpeed;
@property(strong, nonatomic) NSMutableArray *stopsEtaList;

@property(strong, nonatomic) NSMutableArray *stopEstimatePairs;
@property(strong, nonatomic) UIColor *color;


- (void)updateAll:(BB_Shuttle *)newShuttle;
- (void)updateMarker;

@end
