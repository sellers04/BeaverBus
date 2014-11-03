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


@interface BB_ViewController : UIViewController <UIAlertViewDelegate>

@property BOOL optionsMenuIsOpen;
@property (nonatomic, strong) UILabel *mapLabel;

+ (BB_ViewController *)get;
- (void)slideUpdateErrorView;
- (void)showNetworkErrorAlert;

@end

