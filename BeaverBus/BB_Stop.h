//
//  BB_Stop.h
//  BeaverBus
//
//  Created by Nick on 9/16/14.
//  Copyright (c) 2014 Oregon State University. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <GoogleMaps/GoogleMaps.h>

@interface BB_Stop : NSObject

@property(nonatomic) double latitude, longitude;
@property(strong, nonatomic) NSString *name;
@property(strong, nonatomic) GMSMarker *marker;
@property(strong, nonatomic) NSMutableArray *etaArray;

@end
