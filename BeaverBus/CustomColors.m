//
//  CustomColors.m
//  BeaverBus
//
//  Created by Nick on 2/3/15.
//  Copyright (c) 2015 Oregon State University. All rights reserved.
//

#import "CustomColors.h"

@implementation CustomColors

@end







[_northPolyline setSpans:@[[GMSStyleSpan spanWithColor:[UIColor colorWithRed:.439 green:.659 blue:0 alpha:1]]]]; //Green
[_northPolyline setMap:_mapView];

_eastPolyline = [GMSPolyline polylineWithPath:eastPath];
[_eastPolyline setStrokeWidth:3];
[_eastPolyline setSpans:@[[GMSStyleSpan spanWithColor:[UIColor colorWithRed:.667 green:.4 blue:.804 alpha:1]]]]; //Purple
[_eastPolyline setMap:_mapView];

_westPolyline = [GMSPolyline polylineWithPath:westPath];
[_westPolyline setStrokeWidth:3];
[_westPolyline setSpans:@[[GMSStyleSpan spanWithColor:[UIColor colorWithRed:.878 green:.667 blue:.059 alpha:1]]]]; //Yellow
[_westPolyline setMap:_mapView];