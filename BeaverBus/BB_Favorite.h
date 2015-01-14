//
//  BB_Favorite.h
//  BeaverBus
//
//  Created by Nick on 1/12/15.
//  Copyright (c) 2015 Oregon State University. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "BB_Stop.h"

@interface BB_Favorite : NSObject

@property (strong, nonatomic) BB_Stop *favoriteStop;
@property (strong, nonatomic) UIView *favoriteBar;
@property (strong, nonatomic) UILabel *favoriteName;
@property (strong, nonatomic) UIView *favoriteEtaContainer;
@property (strong, nonatomic) NSMutableArray *etaLabels;

+(BB_Favorite *)initNewFavoriteWithStop:(BB_Stop*)stop andFrame:(CGRect)frame;
-(void)updateFavorite;

@end
