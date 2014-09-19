//
//  BB_MapState.m
//  BeaverBus
//
//  Created by Nick on 9/16/14.
//  Copyright (c) 2014 Oregon State University. All rights reserved.
//

#import "BB_MapState.h"
#import "BB_Stop.h"
#import "BB_Shuttle.h"

static BB_MapState *mapState = NULL;


@implementation BB_MapState




+ (BB_MapState *)get
{
    @synchronized(mapState)
    {
        if (!mapState || mapState == NULL){
            mapState = [[BB_MapState alloc] init];
        }
        return mapState;
    }
}


- (void)initMapView
{
    [GMSServices provideAPIKey:@"AIzaSyBw44K1O1MlTgjVm7mWC2jUqH2WQlFIA_k"];
    //ew LatLng(44.563731, -123.279534);
    // Create a GMSCameraPosition that tells the map to display the
    // coordinate -33.86,151.20 at zoom level 6.
    GMSCameraPosition *camera = [GMSCameraPosition cameraWithLatitude:44.563731
                                                            longitude:-123.279534
                                                                 zoom:14.5];
    
    _mapView = [GMSMapView mapWithFrame:CGRectZero camera:camera];
    _mapView.myLocationEnabled = YES;
 
    [self addRoutePolylines];

}


-(void)initStopMarkers
{
    int stopsLength = [_stops count];

    for(int i = 0; i < stopsLength; i++){
        BB_Stop *stop = [_stops objectAtIndex:i];
        CLLocationCoordinate2D loc = CLLocationCoordinate2DMake(stop.latitude, stop.longitude);

        GMSMarker *newMarker = [GMSMarker markerWithPosition:loc];

        newMarker.map = _mapView;

        stop.marker = newMarker;

        //_stopMarkers = [_stopMarkers setByAddingObject:newMarker];
        //NSLog(@"made it here: %d with marker %@", i, newMarker);
    }
}

-(void)initShuttleMarkers
{
    int shuttlesLength = [_shuttles count];

    for(int i = 0; i < shuttlesLength; i++){
        BB_Shuttle *shuttle = [_shuttles objectAtIndex:i];
        CLLocationDegrees heading = [shuttle.heading doubleValue];
        GMSMarker *newMarker;
        newMarker.groundAnchor = CGPointMake(0.5, 0.5);
        if (shuttle.isOnline){
            CLLocationCoordinate2D loc = CLLocationCoordinate2DMake(shuttle.latitude, shuttle.longitude);
            //NSLog(@"Shuttle is : %f, %f", shuttle.latitude, shuttle.longitude);
            newMarker = [GMSMarker markerWithPosition:loc];
            
        }
        else{
            CLLocationCoordinate2D loc = CLLocationCoordinate2DMake(0,0);
           // NSLog(@"Shuttle is : %f, %f", shuttle.latitude, shuttle.longitude);
            newMarker = [GMSMarker markerWithPosition:loc];
            [newMarker setOpacity:0];

        }
        NSLog(@"Image name: %@", shuttle.imageName);
        [newMarker setIcon:[UIImage imageNamed:shuttle.imageName]];
        [newMarker setTitle:shuttle.name];
        newMarker.rotation = heading;
        
        newMarker.map = _mapView;

        shuttle.marker = newMarker;
       // _shuttleMarkers = [_shuttleMarkers setByAddingObject:newMarker];
    }
}

-(void)setShuttle:(int)index withNewShuttle:(BB_Shuttle*)newShuttle{

    [[_shuttles objectAtIndex:index] updateAll:newShuttle];

    //[((BB_Shuttle *)[_shuttles objectAtIndex:index]) updateAll:newShuttle];
}
/*
-(void)updateShuttleData
{
    for (id obj in _shuttles) {
        BB_Shuttle *shuttle = (BB_Shuttle *) obj;

        for (id tempObj in _tempShuttles){
            BB_Shuttle *tempShuttle = (BB_Shuttle *) tempObj;


            //Double route
            if ([tempShuttle.routeID  isEqual: @2]){
                
            }
            else{


            }


            if (tempShuttle.routeID){
            }
        }


    }





    for (int i = 0; i < [_tempShuttles count]; i++) {
        BB_Shuttle *tempShuttle = [_tempShuttles objectAtIndex:i];
        if (tempShuttle.routeID) {
            <#statements#>
        }
    }

}
*/

/*
-(void)initMapMarkers
{
    
    
    //NSLog(@"Made it to initMapMarker. Count : %d", [_stops count]);
    int stopsLength = [_stops count];
    int shuttlesLength = [_shuttles count];

        for(int i = 0; i < stopsLength; i++){
            BB_Stop *stop = [_stops objectAtIndex:i];
            CLLocationCoordinate2D loc = CLLocationCoordinate2DMake(stop.latitude, stop.longitude);
            
            GMSMarker *newMarker = [GMSMarker markerWithPosition:loc];
            
            newMarker.map = _mapView;

            _stopMarkers = [_stopMarkers setByAddingObject:newMarker];
            //NSLog(@"made it here: %d with marker %@", i, newMarker);
        }
        NSLog(@"ShuttlesLength : %d", shuttlesLength);
        for(int i = 0; i < shuttlesLength; i++){
            BB_Shuttle *shuttle = [_shuttles objectAtIndex:i];
            CLLocationCoordinate2D loc = CLLocationCoordinate2DMake(shuttle.latitude, shuttle.longitude);
            NSLog(@"Shuttle is : %f, %f", shuttle.latitude, shuttle.longitude);
            GMSMarker *newMarker = [GMSMarker markerWithPosition:loc];

            [newMarker setIcon:[UIImage imageNamed:@"shuttle_green"]];
            [newMarker setTitle:shuttle.name];
            newMarker.map = _mapView;

            _shuttleMarkers = [_shuttleMarkers setByAddingObject:newMarker];
        }

        int mapPointsCount = [_mapPoints count];
        NSLog(@"Mappoints count: %d", mapPointsCount);
        for(int i = 0; i < mapPointsCount; i++){
            CLLocation *point = [_mapPoints objectAtIndex:i];
            double lat = [point coordinate].latitude;
            double lon = [point coordinate].longitude;
            GMSMarker *newMarker = [GMSMarker markerWithPosition:CLLocationCoordinate2DMake(lat, lon)];
            newMarker.map = _mapView;
        }
         

  
}
*/

-(void)addRoutePolylines
{
    GMSMutablePath *northPath = [GMSMutablePath path];
    [northPath addCoordinate:CLLocationCoordinate2DMake(44.566792, -123.289718)];[northPath addCoordinate:CLLocationCoordinate2DMake(44.566783, -123.284842)];
    [northPath addCoordinate:CLLocationCoordinate2DMake(44.566799, -123.284738)];[northPath addCoordinate:CLLocationCoordinate2DMake(44.566798, -123.284360)];
    [northPath addCoordinate:CLLocationCoordinate2DMake(44.567408, -123.284354)];[northPath addCoordinate:CLLocationCoordinate2DMake(44.567685, -123.284553)];
    [northPath addCoordinate:CLLocationCoordinate2DMake(44.567904, -123.284555)];[northPath addCoordinate:CLLocationCoordinate2DMake(44.567957, -123.279962)];
    [northPath addCoordinate:CLLocationCoordinate2DMake(44.566784, -123.279930)];[northPath addCoordinate:CLLocationCoordinate2DMake(44.566765, -123.272398)];
    [northPath addCoordinate:CLLocationCoordinate2DMake(44.565833, -123.272961)];[northPath addCoordinate:CLLocationCoordinate2DMake(44.564669, -123.274050)];
    [northPath addCoordinate:CLLocationCoordinate2DMake(44.564643, -123.275300)];[northPath addCoordinate:CLLocationCoordinate2DMake(44.564635, -123.279935)];
    [northPath addCoordinate:CLLocationCoordinate2DMake(44.564650, -123.284575)];[northPath addCoordinate:CLLocationCoordinate2DMake(44.564590, -123.289720)];
    [northPath addCoordinate:CLLocationCoordinate2DMake(44.566792, -123.289718)];

    GMSMutablePath *eastPath = [GMSMutablePath path];
    [eastPath addCoordinate:CLLocationCoordinate2DMake(44.564507, -123.274058)];[eastPath addCoordinate:CLLocationCoordinate2DMake(44.564489, -123.275318)];
    [eastPath addCoordinate:CLLocationCoordinate2DMake(44.564495, -123.280051)];[eastPath addCoordinate:CLLocationCoordinate2DMake(44.564158, -123.280016)];
    [eastPath addCoordinate:CLLocationCoordinate2DMake(44.563829, -123.279917)];[eastPath addCoordinate:CLLocationCoordinate2DMake(44.563401, -123.279700)];
    [eastPath addCoordinate:CLLocationCoordinate2DMake(44.563371, -123.279686)];[eastPath addCoordinate:CLLocationCoordinate2DMake(44.561972, -123.279700)];
    [eastPath addCoordinate:CLLocationCoordinate2DMake(44.560713, -123.279700)];[eastPath addCoordinate:CLLocationCoordinate2DMake(44.560713, -123.281585)];
    [eastPath addCoordinate:CLLocationCoordinate2DMake(44.560538, -123.282356)];[eastPath addCoordinate:CLLocationCoordinate2DMake(44.559992, -123.282962)];
    [eastPath addCoordinate:CLLocationCoordinate2DMake(44.559296, -123.283010)];[eastPath addCoordinate:CLLocationCoordinate2DMake(44.558409, -123.281948)];
    [eastPath addCoordinate:CLLocationCoordinate2DMake(44.558455, -123.280609)];[eastPath addCoordinate:CLLocationCoordinate2DMake(44.559033, -123.279740)];
    [eastPath addCoordinate:CLLocationCoordinate2DMake(44.557859, -123.279679)];[eastPath addCoordinate:CLLocationCoordinate2DMake(44.559460, -123.276646)];
    [eastPath addCoordinate:CLLocationCoordinate2DMake(44.559873, -123.273996)];[eastPath addCoordinate:CLLocationCoordinate2DMake(44.561578, -123.274318)];
    [eastPath addCoordinate:CLLocationCoordinate2DMake(44.562113, -123.274114)];[eastPath addCoordinate:CLLocationCoordinate2DMake(44.564507, -123.274058)];

    GMSMutablePath *westPath = [GMSMutablePath path];
    [westPath addCoordinate:CLLocationCoordinate2DMake(44.558993, -123.279550)];[westPath addCoordinate:CLLocationCoordinate2DMake(44.561972, -123.279550)];
    [westPath addCoordinate:CLLocationCoordinate2DMake(44.563391, -123.279526)];[westPath addCoordinate:CLLocationCoordinate2DMake(44.563401, -123.279520)];
    [westPath addCoordinate:CLLocationCoordinate2DMake(44.563829, -123.279737)];[westPath addCoordinate:CLLocationCoordinate2DMake(44.564158, -123.279826)];
    [westPath addCoordinate:CLLocationCoordinate2DMake(44.564495, -123.279901)];[westPath addCoordinate:CLLocationCoordinate2DMake(44.564500, -123.284775)];
    [westPath addCoordinate:CLLocationCoordinate2DMake(44.562234, -123.284775)];[westPath addCoordinate:CLLocationCoordinate2DMake(44.561965, -123.284625)];
    [westPath addCoordinate:CLLocationCoordinate2DMake(44.560529, -123.284625)];[westPath addCoordinate:CLLocationCoordinate2DMake(44.560538, -123.282576)];
    [westPath addCoordinate:CLLocationCoordinate2DMake(44.560012, -123.283142)];[westPath addCoordinate:CLLocationCoordinate2DMake(44.559246, -123.283160)];
    [westPath addCoordinate:CLLocationCoordinate2DMake(44.558254, -123.281967)];[westPath addCoordinate:CLLocationCoordinate2DMake(44.558305, -123.280559)];
    [westPath addCoordinate:CLLocationCoordinate2DMake(44.558993, -123.279550)];


    GMSPolyline *northPolyline = [GMSPolyline polylineWithPath:northPath];
    [northPolyline setStrokeWidth:3];
    northPolyline.spans = @[[GMSStyleSpan spanWithColor:[UIColor greenColor]]];
    northPolyline.map = _mapView;

    GMSPolyline *eastPolyline = [GMSPolyline polylineWithPath:eastPath];
    [eastPolyline setStrokeWidth:3];
    eastPolyline.spans = @[[GMSStyleSpan spanWithColor:[UIColor yellowColor]]];
    eastPolyline.map = _mapView;

    GMSPolyline *westPolyline = [GMSPolyline polylineWithPath:westPath];
    [westPolyline setStrokeWidth:3];
    westPolyline.spans = @[[GMSStyleSpan spanWithColor:[UIColor purpleColor]]];
    westPolyline.map = _mapView;

}


@end
