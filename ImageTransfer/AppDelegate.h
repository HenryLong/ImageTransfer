//
//  AppDelegate.h
//  ImageTransfer
//
//  Created by LongHenry on 2016/3/15.
//  Copyright © 2016年 qisda. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "SendingViewController.h"

@class ViewController;

@interface AppDelegate : UIResponder <UIApplicationDelegate>

@property (strong, nonatomic) UIWindow *window;
@property (strong, nonatomic) SendingViewController *viewController;

@end
