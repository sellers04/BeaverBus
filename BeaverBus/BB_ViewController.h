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


@interface BB_ViewController : UIViewController <UIAlertViewDelegate>

@property BOOL optionsMenuIsOpen;
@property (nonatomic, strong) UILabel *mapLabel;
@property (nonatomic, strong) UIButton *addFavoriteButton;

+ (BB_ViewController *)get;
- (void)slideUpdateErrorView;
- (void)showNetworkErrorAlert;
- (void)setFavoriteButton;

@end

