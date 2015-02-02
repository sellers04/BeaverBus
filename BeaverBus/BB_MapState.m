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
#import "BB_StopETABox.h"
#import "BB_CustomInfoWindow.h"
#import "BB_MapLabelView.h"

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

    GMSCameraPosition *camera = [GMSCameraPosition cameraWithLatitude:44.563731
                                                            longitude:-123.279534
                                                                 zoom:14.5];
    _mapView = [GMSMapView mapWithFrame:CGRectZero camera:camera];
    _mapView.myLocationEnabled = YES;

    _mapView.settings.compassButton = YES;
    //_mapView.settings.myLocationButton = YES;

    //_mapView.padding = UIEdgeInsetsMake(0, 0, 430, 0);

    _mapView.delegate = self;

    _favorites = [[NSMutableArray alloc] init];

    //_defaultFavoriteFrame = CGRectMake(10, _mapView.frame.size.height-50, _mapView.frame.size.width-20, 30);
    
    [self addRoutePolylines];
    
    NSLog(@"initmapview: %@", _mapView);
}


-(void)onFavoriteTap:(BB_Stop *)stop
{
    //[_mapView setCamera:[GMSCameraPosition cameraWithLatitude:stop.latitude longitude:stop.longitude zoom:14.5]];
    [_mapView setSelectedMarker:stop.marker];
    [_mapView animateToLocation:stop.marker.position];

    [_mainViewController setFavoriteButton];
    [_mainViewController.addFavoriteButton setHidden:NO];
}

-(BOOL)mapView:(GMSMapView *)mapView didTapMarker:(GMSMarker *)marker
{
    NSLog(@"Tapped marker");
    [_mapView animateToLocation:marker.position];
    [_mapView setSelectedMarker:marker];

    if ([[_mapView selectedMarker].userData isKindOfClass:[BB_Stop class]]){

        [_mainViewController setFavoriteButton];
        [_mainViewController.addFavoriteButton setHidden:NO];

        //[[_mapView selectedMarker] setIcon:[UIImage imageNamed:@"marker"]];


        _mainViewController.mapLabel.text = ((BB_Stop *)marker.userData).name;


        NSLog(@"txt is: %@", [BB_ViewController get].mapLabel.text);
    }



    if ([marker.userData isKindOfClass:[BB_Shuttle class]]){

        [_mainViewController.addFavoriteButton setHidden:YES];
        //If shuttle, move map to it

       // [[BB_ViewController get].mapLabel setText:((BB_Shuttle *)marker.userData).name];
        //[[BB_ViewController get] setMapLabelText:((BB_Shuttle *)marker.userData).name];
        _mainViewController.mapLabel.text = ((BB_Shuttle *)marker.userData).name;
        NSLog(@"txt is: %@", [BB_ViewController get].mapLabel.text);
    }


    
   // [[BB_ViewController get] setMapLabelVisibility:YES];
    _mainViewController.mapLabel.hidden = NO;
   
    return YES;
}

-(void)mapView:(GMSMapView *)mapView didTapAtCoordinate:(CLLocationCoordinate2D)coordinate
{
    NSLog(@"Tapped coord");
    
    if([_mainViewController optionsMenuIsOpen])
    {
        [[_mainViewController menuViewController] removeAnimate];
        [_mainViewController setOptionsMenuIsOpen:false];
    }
    
    _mainViewController.mapLabel.hidden = YES;
    [_mainViewController.addFavoriteButton setHidden:YES];
    //If a marker was deselected, set route line widths to normal
    if ([_mapView selectedMarker] != nil){
        //if ([[_mapView selectedMarker].userData isKindOfClass:[BB_Stop class]]){
            //[[_mapView selectedMarker] setIcon:[UIImage imageNamed:@"marker"]];
        //}
        [_mapView setSelectedMarker:nil];
        [_westPolyline setStrokeWidth:3];
        [_eastPolyline setStrokeWidth:3];
        [_northPolyline setStrokeWidth:3];
    }
}

-(void)initStopMarkers
{
    int stopsLength = [_stops count];

    for(int i = 0; i < stopsLength; i++){
        BB_Stop *stop = [_stops objectAtIndex:i];
        CLLocationCoordinate2D loc = CLLocationCoordinate2DMake(stop.latitude, stop.longitude);

        GMSMarker *newMarker = [GMSMarker markerWithPosition:loc];
        
        //Debugging, displays routeIds as title of marker
       /* NSString *baseString = @"";
        for (NSNumber *num in stop.etaArray) {
            baseString = [baseString  stringByAppendingFormat:@"%d ,", [num integerValue]];
        }
        [newMarker setTitle:baseString];*/

        [newMarker setTitle:@"Route Inactive"];

        [newMarker setIcon:[UIImage imageNamed:@"marker"]];
        [newMarker setZIndex:1];
        [newMarker setMap:_mapView];
        [newMarker setUserData:stop];
        [newMarker setOpacity:0.75];

        [newMarker setGroundAnchor:CGPointMake(0.5, 0.5)];

        [stop setMarker:newMarker];
        _stopsVisible = true;
    }
    [BB_Favorite restoreFavorites];
    
}

-(void)initShuttleMarkers
{
    int shuttlesLength = [_shuttles count];

    for(int i = 0; i < shuttlesLength; i++){
        BB_Shuttle *shuttle = [_shuttles objectAtIndex:i];
        CLLocationDegrees heading = [shuttle.heading doubleValue];
        GMSMarker *newMarker;

        if (shuttle.isOnline){
            CLLocationCoordinate2D loc = CLLocationCoordinate2DMake(shuttle.latitude, shuttle.longitude);
            newMarker = [GMSMarker markerWithPosition:loc];
            [newMarker setOpacity:0.85];
        }
        else{
            //Shuttle offline, give fake coordinates and set to invisible
            CLLocationCoordinate2D loc = CLLocationCoordinate2DMake(0,0);
            newMarker = [GMSMarker markerWithPosition:loc];
            [newMarker setOpacity:0];
        }

        UIImage *iconImage = [UIImage imageNamed:shuttle.imageName];
        [newMarker setIcon:iconImage];
        [newMarker setTitle:shuttle.name];
        [newMarker setRotation:heading];
        [newMarker setGroundAnchor:CGPointMake(0.5, 0.5)];
        [newMarker setZIndex:0];
        [newMarker setMap:_mapView];
        [newMarker setInfoWindowAnchor:CGPointMake(0.5, 0.5)];
        [newMarker setUserData:shuttle];
        [newMarker setFlat:YES];

        [shuttle setMarker:newMarker];
    }
}

-(void)setShuttle:(int)index withNewShuttle:(BB_Shuttle*)newShuttle{
    [[_shuttles objectAtIndex:index] updateAll:newShuttle];
}

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

    _northPolyline = [GMSPolyline polylineWithPath:northPath];
    [_northPolyline setStrokeWidth:3];
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
}

- (UIView *)mapView:(GMSMapView *)mapView markerInfoWindow:(GMSMarker *)marker{

    if ([marker.userData isKindOfClass:[BB_Shuttle class]]){



        //Set the thickness of selected shuttle's associated route

        if ([((BB_Shuttle *)marker.userData).routeID isEqualToNumber:@9]){ //West Route
            [_westPolyline setStrokeWidth:6];
            [_eastPolyline setStrokeWidth:3];
            [_northPolyline setStrokeWidth:3];
        }
        else if ([((BB_Shuttle *)marker.userData).routeID isEqualToNumber:@8]){ //East Route
            [_eastPolyline setStrokeWidth:6];
            [_westPolyline setStrokeWidth:3];
            [_northPolyline setStrokeWidth:3];
        }
        else if ([((BB_Shuttle *)marker.userData).routeID isEqualToNumber:@7]){ //North Route
            [_northPolyline setStrokeWidth:6];
            [_westPolyline setStrokeWidth:3];
            [_eastPolyline setStrokeWidth:3];
        }
    }

    else if ([marker.userData isKindOfClass:[BB_Stop class]]){

        //s[marker setIcon:[UIImage imageNamed:@"marker_selected"]];



        [_eastPolyline setStrokeWidth:3];
        [_westPolyline setStrokeWidth:3];
        [_northPolyline setStrokeWidth:3];

        //Create dynamic stop ETA info window

        BB_Stop *stop = marker.userData;
        NSMutableArray *stopETABoxes = [[NSMutableArray alloc] init];
        int xPosition = 0;
        int numEtaFound = 0;

        for (int i = 0; i < [stop.etaArray count]; i++){

            if ([[stop.etaArray objectAtIndex:i] integerValue] > -1){
                numEtaFound++;
                BB_StopETABox *stopETABox = [[[NSBundle mainBundle] loadNibNamed:@"StopETABox" owner:self options:nil] objectAtIndex:0];
                if ([[stop.etaArray objectAtIndex:i] integerValue] <= 1){
                    stopETABox.ETA.text = @"~1";
                } else {
                    stopETABox.ETA.text = [[stop.etaArray objectAtIndex:i] stringValue];
                }
                switch (i) {
                    case 0:
                        stopETABox.colorBox.backgroundColor = [UIColor colorWithRed:.439 green:.659 blue:0 alpha:1]; //Green
                        break;
                    case 1:
                        stopETABox.colorBox.backgroundColor = [UIColor colorWithRed:.878 green:.667 blue:.059 alpha:1]; //Yellow
                        break;
                    case 2:
                        stopETABox.colorBox.backgroundColor = [UIColor colorWithRed:.878 green:.667 blue:.059 alpha:1]; //Yellow
                        break;
                    case 3:
                        stopETABox.colorBox.backgroundColor = [UIColor colorWithRed:.667 green:.4 blue:.804 alpha:1]; //Purple
                        break;
                    default:
                        stopETABox.colorBox.backgroundColor = [UIColor grayColor];
                        break;
                }
                stopETABox.frame = CGRectMake(xPosition, 0, stopETABox.frame.size.width, stopETABox.frame.size.height);
                xPosition += 40;
                [stopETABoxes addObject:stopETABox];
            }
        }

        //There were no shuttles with ETAs found for this stop
        if (numEtaFound == 0){
            return nil;
        }
                UIView *stopInfoWindow = [[UIView alloc] initWithFrame:CGRectMake(0, 0, ([stopETABoxes count]*40), (((BB_StopETABox *)[stopETABoxes objectAtIndex:0]).frame.size.height))];
        stopInfoWindow.layer.cornerRadius = 5;
        stopInfoWindow.layer.masksToBounds = YES;
        stopInfoWindow.backgroundColor = [UIColor clearColor];

        /*
        UIImageView *bottomArrow = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"infowindow_arrow"]];
        [bottomArrow setContentMode:UIViewContentModeScaleAspectFit];
        NSLog(@"image frame: %@", NSStringFromCGSize(bottomArrow.image.size));
        [stopInfoWindow addSubview:bottomArrow];
         */

        for (int i = 0; i < [stopETABoxes count]; i++){
            [stopInfoWindow addSubview:[stopETABoxes objectAtIndex:i]];
        }

        //The custom infowindow for stop
        return stopInfoWindow;
    }

    //The default infowindow for shuttle
    return nil;
}


- (void)changeStopsVisibility{
    if (_stopsVisible){

        [_mapView setSelectedMarker:nil];

        for (BB_Stop *stop in _stops){
            [stop.marker setOpacity:0];
            [stop.marker setTappable:NO];
        }
        _stopsVisible = false;
    } else {
        for (BB_Stop *stop in _stops){
            [stop.marker setOpacity:0.75];
            [stop.marker setTappable:YES];
        }
        _stopsVisible = true;
    }



}


@end
