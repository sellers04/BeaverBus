//
//  BB_Shuttle.h
//  BeaverBus
//
//  Created by Nick on 9/16/14.
//  Copyright (c) 2014 Oregon State University. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <GoogleMaps/GoogleMaps.h>

@interface BB_Shuttle : NSObject

@property(nonatomic) double latitude, longitude;
@property(strong, nonatomic) NSNumber *heading;
@property(strong, nonatomic) NSString *name;
@property(strong, nonatomic) NSNumber *vehicleID;
@property(strong, nonatomic) NSNumber *routeID;
@property(nonatomic) BOOL isOnline;
@property(strong, nonatomic) GMSMarker *marker;
@property(strong, nonatomic) NSString *imageName;
@property(strong, nonatomic) NSMutableArray *stopsEtaList;

- (void)updateAll:(BB_Shuttle *)newShuttle;
- (void)updateMarker;

@end
