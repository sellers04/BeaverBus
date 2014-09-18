//
//  BB_Shuttle.m
//  BeaverBus
//
//  Created by Nick on 9/16/14.
//  Copyright (c) 2014 Oregon State University. All rights reserved.
//

#import "BB_Shuttle.h"

@implementation BB_Shuttle

-(void)updateAll:(BB_Shuttle *)newShuttle{
    _latitude = newShuttle.latitude;
    _longitude = newShuttle.longitude;
    _heading = newShuttle.heading;
    _name = newShuttle.name;
    _vehicleID = newShuttle.vehicleID;
    _routeID = newShuttle.routeID;
    _isOnline = newShuttle.isOnline;
}

@end

