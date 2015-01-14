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



@end
