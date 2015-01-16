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

+(BB_Favorite*)initNewFavoriteWithStop:(BB_Stop*)stop andFrame:(CGRect)frame
{
    BB_Favorite *newFavorite = [[BB_Favorite alloc] init];
    
    newFavorite.favoriteStop = stop;
    newFavorite.favoriteStop.isFavorite = TRUE;
    
    UIView *favoriteBar = [[UIView alloc] initWithFrame:frame];
    
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


    for (BB_Favorite *fav in [BB_MapState get].favorites){
        [UIView animateWithDuration:0.25 animations:^{
            fav.favoriteBar.frame = CGRectMake(frame.origin.x, fav.favoriteBar.frame.origin.y - favoriteBar.frame.size.height, frame.size.width, frame.size.height);

        }];
    }

    return newFavorite;
}

-(void)updateFavorite
{
    
    NSLog(@"NAME: %@",[self etaLabels]);
    
    dispatch_async(dispatch_get_main_queue(), ^{
    
        for (int i = 0; i < [[_favoriteStop etaArray] count]; i++) {
            NSNumber *eta = [[_favoriteStop etaArray] objectAtIndex:i];
            NSLog(@"Update favorite: %d with %@", i, eta);
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
      //  [_favoriteBar setNeedsDisplay];
    });
    
}




@end
