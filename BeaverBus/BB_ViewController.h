//
//  BB_ViewController.h
//  BeaverBus
//
//  Created by Nick on 9/16/14.
//  Copyright (c) 2014 Oregon State University. All rights reserved.
//

#import <UIKit/UIKit.h>
#include "EasyTableView.h"
#include "BB_StopCell.h"
#include "BB_ShuttleUpdater.h"
@class BB_MenuViewController;
#include "BB_Favorite.h"


@interface BB_ViewController : UIViewController <UIAlertViewDelegate> 


@property (nonatomic, strong) UILabel *mapLabel;
@property (nonatomic, strong) UIButton *addFavoriteButton;
@property (nonatomic, strong) BB_MenuViewController *menuViewController;
@property BOOL optionsMenuIsOpen;

+ (BB_ViewController *)get;
-(UIView *)getMainView;
- (void)slideUpdateErrorView;
- (void)showNetworkErrorAlert;

-(void)setOptionsMenuIsOpen:(BOOL)optionsMenuIsOpen;

- (void)setFavoriteButton;
-(void)handleFavoriteTap:(id) sender;
- (void)addFavorite;

@end

