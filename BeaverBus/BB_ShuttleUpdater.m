//
//  BB_ShuttleUpdater.m
//  BeaverBus
//
//  Created by Nick on 9/16/14.
//  Copyright (c) 2014 Oregon State University. All rights reserved.
//

#import "BB_ShuttleUpdater.h"
#import "BB_Stop.h"
#import "BB_Shuttle.h"
#import "BB_MapState.h"


int const NORTH = 1;
int const WEST = 2;
int const EAST = 3;


static BB_ShuttleUpdater *shuttleUpdater = NULL;
static BB_MapState *mapState;

dispatch_semaphore_t sem;


@implementation BB_ShuttleUpdater


@synthesize session = _session;

- (NSURLSession *)session
{
    //NSURLSession *session;
    if(!_session)
    {
        NSURLSessionConfiguration *config = [NSURLSessionConfiguration defaultSessionConfiguration];
        _session = [NSURLSession sessionWithConfiguration:config delegate:self delegateQueue:nil];
    }
    return _session;
}

+ (BB_ShuttleUpdater *)get
{
    @synchronized(shuttleUpdater)
    {
        if (!shuttleUpdater || shuttleUpdater == NULL){
            shuttleUpdater = [[BB_ShuttleUpdater alloc] init];
            mapState = [BB_MapState get];
        }
        return shuttleUpdater;
    }
}

- (BOOL)initialNetworkRequest
{
    mapState.shuttles = [[NSMutableArray alloc] init];
    for (int i = 0; i < 4; i++){
        BB_Shuttle *newShuttle = [[BB_Shuttle alloc] init];
        newShuttle.isOnline = FALSE;
        [mapState.shuttles addObject:newShuttle];
    }


    sem = dispatch_semaphore_create(0);

    NSLog(@"Starting requests...");
    [self getStops];
    //NSLog(@"Done stops");
    [self getShuttles];
    //[BB_MapState get].shuttles =
    //NSLog(@"Done shuttles");

    dispatch_semaphore_wait(sem, DISPATCH_TIME_FOREVER);

    NSLog(@"Done with one");
    dispatch_semaphore_wait(sem, DISPATCH_TIME_FOREVER);

    dispatch_async(dispatch_get_main_queue(), ^{
        [mapState initStopMarkers];
        [mapState initShuttleMarkers];
    });

    NSLog(@"Done with all!");

    return true;
}

- (void)startShuttleUpdaterHandler{

    NSTimer *timer = [NSTimer scheduledTimerWithTimeInterval:5 target:self selector:@selector(updateEvent:) userInfo:nil repeats:TRUE];

}

- (void)updateEvent{
    [self getShuttles];
    
}


- (BOOL) getStops{
    NSURL *url = [NSURL URLWithString:@"http://osushuttles.com/Services/JSONPRelay.svc/GetStops"];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
    request.HTTPMethod = @"GET";

    NSURLSessionDataTask *getDataTask = [self.session dataTaskWithRequest:request completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {

        NSError *jsonParsingError = nil;
        NSArray *jsonArray = [NSJSONSerialization JSONObjectWithData:data options:0 error:&jsonParsingError];
        //NSLog(@"StopArray : %@", jsonArray);
        
        NSMutableArray *stopsArray = [[NSMutableArray alloc] init];
        int count = [jsonArray count];
        NSMutableArray *routePoints = [[NSMutableArray alloc] init];
        //NSLog(@"jsonArray count: %d", [jsonArray count]);
        for(int i = 0; i < count; i++){
            id obj = [jsonArray objectAtIndex:i];
            
            BB_Stop *newStop = [[BB_Stop alloc] init];
            newStop.latitude = [[obj objectForKey:@"Latitude"] doubleValue];
            newStop.longitude = [[obj objectForKey:@"Longitude"] doubleValue];

            id mapPoints = [obj objectForKey:@"MapPoints"];
            int mapPointsCount = [mapPoints count];
            //NSLog(@"mappointsCount: %d", mapPointsCount);

            for(int j = 0; j < mapPointsCount; j++){
                id point = [mapPoints objectAtIndex:j];
                double lat = [[point objectForKey:@"Latitude"] doubleValue];
                double lon = [[point objectForKey:@"Longitude"] doubleValue];
                CLLocation *loc = [[CLLocation alloc] initWithLatitude:lat longitude:lon];
                if(![routePoints containsObject:(id)loc]){
                    [routePoints addObject:(id)loc];
                }
                mapState.mapPoints = routePoints;
                //GMSMarker *newMarker = [GMSMarker markerWithPosition:loc]
            }




            newStop.name = [obj objectForKey:@"Description"];
            //NSLog(@"newStop name: %@", newStop.name);
            [stopsArray addObject:newStop];
            //NSLog(@"stopsArray : %@", stopsArray);
        }
        NSLog(@"Stops stuff");
        //NSLog(@"StopsArray count: %d", [stopsArray count]);
        mapState.stops = stopsArray;
        //NSLog(@"Finished first request mapstateStops count: %d", [[BB_MapState get].stops count]);

        dispatch_semaphore_signal(sem);

    }];
    [getDataTask resume];
    
    return true;
}

- (BOOL) getShuttles{
    NSURL *url = [NSURL URLWithString:@"http://portal.campusops.oregonstate.edu/files/shuttle/GetMapVehiclePoints.txt"];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
    request.HTTPMethod = @"GET";
    
    NSURLSessionDataTask *getDataTask = [self.session dataTaskWithRequest:request completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        
        NSError *jsonParsingError = nil;
        NSArray *jsonArray = [NSJSONSerialization JSONObjectWithData:data options:0 error:&jsonParsingError];
        //NSLog(@"ShuttleArray : %@", jsonArray);
        
        //NSMutableArray *shuttlesArray = [[NSMutableArray alloc] init];
        int count = [jsonArray count];
        //BOOL firstWestSeen = false;
        NSLog(@"shuttle jsonArray count: %d", [jsonArray count]);

        //TODO: Figure out bool array for setting online states if no shuttle found
        bool onlineStates[] = {false, false, false, false};

        for(int i = 0; i < count; i++){
            id obj = [jsonArray objectAtIndex:i];
            
            BB_Shuttle *newShuttle = [[BB_Shuttle alloc] init];
            newShuttle.latitude = [[obj objectForKey:@"Latitude"] doubleValue];
            newShuttle.longitude = [[obj objectForKey:@"Longitude"] doubleValue];
            newShuttle.vehicleID = [obj objectForKey:@"VehicleId"];
            newShuttle.routeID =[obj objectForKey:@"RouteID"];
            newShuttle.heading = [obj objectForKey:@"Heading"];
            newShuttle.name = [obj objectForKey:@"Name"];
            newShuttle.isOnline = true;


            switch ([[obj objectForKey:@"RouteID"] integerValue]) {
                case NORTH:
                    [mapState setShuttle:0 withNewShuttle:newShuttle];
                    //newShuttle.name = @"North";
                    onlineStates[0] = true;
                    break;
                case WEST:

                    if (((BB_Shuttle *)[mapState.shuttles objectAtIndex:1]).vehicleID == newShuttle.vehicleID){
                        [mapState setShuttle:1 withNewShuttle:newShuttle];
                        onlineStates[1] = true;
                    }
                    else if (((BB_Shuttle *)[mapState.shuttles objectAtIndex:2]).vehicleID == newShuttle.vehicleID){
                        [mapState setShuttle:2 withNewShuttle:newShuttle];
                        onlineStates[2] = true;
                    }
                    else if (((BB_Shuttle *)[mapState.shuttles objectAtIndex:1]).isOnline == FALSE){
                        [mapState setShuttle:1 withNewShuttle:newShuttle];
                        onlineStates[1] = true;
                    }
                    else if (((BB_Shuttle *)[mapState.shuttles objectAtIndex:2]).isOnline == FALSE){
                        [mapState setShuttle:2 withNewShuttle:newShuttle];
                        onlineStates[2] = true;
                    }

                    /*if(!firstWestSeen) newShuttle.name = @"West 1";
                    else newShuttle.name = @"West 2";*/
                    break;
                case EAST:
                    [mapState setShuttle:3 withNewShuttle:newShuttle];
                    //newShuttle.name = @"East";
                    onlineStates[3] = true;
                    break;
                default:
                    break;
            }

        }

        for (int i = 0; i < 4; i++) {
            if (!onlineStates[i]){
                ((BB_Shuttle *)[mapState.shuttles objectAtIndex:i]).isOnline = false;

            }
            else ((BB_Shuttle *)[mapState.shuttles objectAtIndex:2]).isOnline = true;
        }

      //  NSLog(@"ShuttlesArray len: %d", [shuttlesArray count]);

         NSLog(@"Finished second request");


        dispatch_semaphore_signal(sem);

    }];
    [getDataTask resume];
    
    return true;
}

@end
