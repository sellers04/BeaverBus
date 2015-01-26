//
//  BB_Favorite.m
//  BeaverBus
//
//  Created by Nick on 1/12/15.
//  Copyright (c) 2015 Oregon State University. All rights reserved.
//

#import "BB_Favorite.h"
#import "BB_MapState.h"


@implementation BB_Favorite

int const NORTH = 0;
int const WEST1 = 1;
int const WEST2 = 2;
int const EAST = 3;

+ (void)handleFavoriteTap:(UITapGestureRecognizer *)sender
{
    //Find favorite obj of tapped view. Send stop obj to MapState to have map moved.
    for (int i = 0; i < [[[BB_MapState get] favorites] count]; i++) {
        BB_Favorite *fav = [[[BB_MapState get] favorites] objectAtIndex:i];
        if([sender isEqual:[fav favoriteBar]]){
            [[BB_MapState get] onFavoriteTap:[fav favoriteStop]];
        }
    }
}

+ (BB_Favorite*)initNewFavoriteWithStop:(BB_Stop*)stop andFrame:(CGRect)frame
{
    
    NSMutableArray *favorites = [[BB_MapState get] favorites];
    
    BB_Favorite *newFavorite = [[BB_Favorite alloc] init];
    
    newFavorite.favoriteStop = stop;
    newFavorite.favoriteStop.isFavorite = TRUE;
    newFavorite.defaultFrame = frame;

    UIControl *favoriteBar = [[UIControl alloc] initWithFrame:frame];
    UILabel *favoriteName = [[UILabel alloc] initWithFrame:CGRectMake(10, 0, 100, 30)];
    UIView *favoriteEta = [[UILabel alloc] initWithFrame:CGRectMake(120, 0, 100, 30)];

    favoriteName.text = stop.name;
    newFavorite.favoriteName = favoriteName;
    newFavorite.favoriteEtaContainer = favoriteEta;
    
    [favoriteBar setBackgroundColor:[UIColor whiteColor]];
    [favoriteBar setAlpha:0];
    favoriteBar.layer.cornerRadius = 5;
    favoriteBar.layer.masksToBounds = YES;
    favoriteBar.layer.borderWidth = 1;
    favoriteBar.layer.borderColor = [UIColor blackColor].CGColor;
    favoriteBar.autoresizingMask = UIViewAutoresizingFlexibleTopMargin;
    
    [favoriteBar addSubview:favoriteName];
    [favoriteBar addSubview:favoriteEta];

    [favoriteBar setUserInteractionEnabled:true];
    [favoriteBar addTarget:self action:@selector(handleFavoriteTap:) forControlEvents:UIControlEventTouchUpInside];

    
    newFavorite.favoriteBar = favoriteBar;
    newFavorite.etaLabels = [[NSMutableArray alloc] init];
    
    int x = 0;
    for (NSNumber *eta in stop.etaArray){
        UILabel *etaLabel = [[UILabel alloc] initWithFrame:CGRectMake(x, 0, 30, 30)];
        [newFavorite.etaLabels addObject:etaLabel];
        etaLabel.text = [eta stringValue];
        x += 35;
        [favoriteEta addSubview:etaLabel];
    }

    for (BB_Favorite *fav in favorites){
        [UIView animateWithDuration:0.25 animations:^{
            fav.favoriteBar.frame = CGRectMake(frame.origin.x, fav.favoriteBar.frame.origin.y - favoriteBar.frame.size.height, frame.size.width, frame.size.height);

        }];
    }
    
    [favorites addObject:newFavorite];

    [BB_Favorite saveCurrentFavorites];
    
    return newFavorite;
}


+ (void)removeFavorite
{
    NSMutableArray *favorites = [[BB_MapState get] favorites];

    ((BB_Stop*)[BB_MapState get].mapView.selectedMarker.userData).isFavorite = FALSE;

    for (BB_Favorite *fav in favorites) {
        if([fav.favoriteStop isEqual:[BB_MapState get].mapView.selectedMarker.userData]){
            [UIView animateWithDuration:0.4 animations:^{
                fav.favoriteBar.alpha = 0.0;
            } completion:^(BOOL finished) {
                [fav.favoriteBar removeFromSuperview];
                [favorites removeObject:fav];
                [BB_Favorite animateFavoritesAfterRemove];
                [BB_Favorite saveCurrentFavorites];
                [[[BB_MapState get] mainViewController] setFavoriteButton];
            }];
        }
    }
}


//Replaces userdefaults string with a newly generated string from current mapstate favorites array.
+ (void)saveCurrentFavorites
{
    NSMutableArray *favorites = [[BB_MapState get] favorites];
    NSMutableString *savedFavNames = [NSMutableString stringWithString:@""];

    for (int i = 0; i < [favorites count]; i++){
        if (i!=0) [savedFavNames appendString:@"_"];
        [savedFavNames appendString:((BB_Favorite *)[favorites objectAtIndex:i]).favoriteStop.name];
    }

    //NSLog(@"savedfavnames: %@", savedFavNames);
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    [userDefaults setObject:savedFavNames forKey:@"Favorites"];
    [userDefaults synchronize];
}


//Iterates through userdefaults favorites, looks for match in mapstate stops, creates favorite from a match.
+ (void)restoreFavorites
{
    
    CGRect frame = CGRectMake(10, [[BB_MapState get] mapView].frame.size.height-50, [[BB_MapState get] mapView].frame.size.width-20, 30);
    
    NSArray *splitItems = [[[NSUserDefaults standardUserDefaults] objectForKey:@"Favorites"] componentsSeparatedByString:@"_"];

    NSLog(@"Split items is: %@", splitItems);

    for (NSString *favName in splitItems){

        for (BB_Stop *stop in [[BB_MapState get] stops]){

            if ([favName isEqualToString:stop.name]){
                
                BB_Favorite *newFavorite = [self initNewFavoriteWithStop:stop andFrame:frame];

                [[[[BB_MapState get] mainViewController] view] addSubview:newFavorite.favoriteBar];

                [UIView animateWithDuration:0.4 animations:^{
                    newFavorite.favoriteBar.alpha = 0.75;
                }];
            }
        }
    }
}


+ (void)animateFavoritesAfterRemove
{
    NSUInteger count = [[[BB_MapState get] favorites] count];
    for (BB_Favorite *fav in [BB_MapState get].favorites){
        count--;
        
        [UIView animateWithDuration:0.25 animations:^{
            fav.favoriteBar.frame = CGRectMake(fav.defaultFrame.origin.x, fav.defaultFrame.origin.y-(count*fav.defaultFrame.size.height), fav.defaultFrame.size.width, fav.defaultFrame.size.height);
        }];
    }
}


- (void)updateFavorite
{
    
    dispatch_async(dispatch_get_main_queue(), ^{
    
        for (int i = 0; i < [[_favoriteStop etaArray] count]; i++) {
            NSNumber *eta = [[_favoriteStop etaArray] objectAtIndex:i];
            //NSLog(@"Update favorite: %d with %@", i, eta);
            switch (i) {
                case NORTH:
                    ((UILabel*)_etaLabels[NORTH]).text = [eta stringValue];
                    break;
                case WEST1:
                    ((UILabel*)_etaLabels[WEST1]).text = [eta stringValue];
                    break;
                case WEST2:
                    ((UILabel*)_etaLabels[WEST2]).text = [eta stringValue];
                    break;
                case EAST:
                    ((UILabel*)_etaLabels[EAST]).text = [eta stringValue];
                    break;
                default:
                    break;
            }
        }
    });
    
}


@end
