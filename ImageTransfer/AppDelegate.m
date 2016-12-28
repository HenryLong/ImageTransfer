//
//  AppDelegate.m
//  ImageTransfer
//
//  Created by LongHenry on 2016/3/15.
//  Copyright © 2016年 qisda. All rights reserved.
//

#import "AppDelegate.h"

@implementation AppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    //NSLog(@"didFinishLaunchingWithOptions");
    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    self.viewController = [[SendingViewController alloc] initWithNibName:@"SendingViewController" bundle:nil];
    self.window.rootViewController = self.viewController;
    [self.window makeKeyAndVisible];
    return YES;
}

- (void)applicationWillResignActive:(UIApplication *)application
{
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}

- (void)applicationWillTerminate:(UIApplication *)application
{
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}


- (BOOL)application:(UIApplication *)application openURL:(NSURL *)url options:(NSDictionary<UIApplicationOpenURLOptionsKey, id> *)options
{
    NSLog(@"Launch url: %@", url);
    [self readFromExtension];
    
    if(self.viewController.imageArrayData.count != 0){
        [self.viewController processImageList];
    }
    return  YES;
}

- (void)readFromExtension{
    NSUserDefaults *shared = [[NSUserDefaults alloc] initWithSuiteName:@"group.ios.image.share"];
    NSMutableArray *url = [shared valueForKey:@"url"];
    NSMutableArray *imageData = [shared valueForKey:@"imageData"] ;
    
    NSLog(@"readUrlFromExtension url: %@", url);
    NSLog(@"readUrlFromExtension imageData: %@", imageData);
    
    self.viewController.imageArrayUrl = [NSMutableArray arrayWithArray:url];
    self.viewController.imageArrayData = [NSMutableArray arrayWithArray:imageData];

    [shared removeObjectForKey:@"url"];  // delete key after read
    [shared removeObjectForKey:@"imageData"];  // delete key after read
}


@end

