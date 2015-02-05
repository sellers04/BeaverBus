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
#include "BB_Favorite.h"
@class BB_MenuViewController;

@interface BB_ViewController : UIViewController <UIAlertViewDelegate, UIActionSheetDelegate>

@property (nonatomic, strong) UILabel *mapLabel;
@property (nonatomic, strong) UIButton *addFavoriteButton;
@property (nonatomic, strong) BB_MenuViewController *menuViewController;
@property BOOL optionsMenuIsOpen;

+ (BB_ViewController *)get;
- (UIView *)getMainView;
- (void)setOptionsMenuIsOpen:(BOOL)optionsMenuIsOpen;
- (void)setFavoriteButton;
- (void)showNetworkErrorAlert:(BOOL)initialRequest;

@end

