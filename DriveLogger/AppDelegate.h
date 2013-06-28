//
//  AppDelegate.h
//  DriveLogger
//
//  Created by Ian Sheret on 31/05/2013.
//  Copyright (c) 2013 Ian Sheret. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <CoreMotion/CoreMotion.h>
#import <CoreLocation/CoreLocation.h>

@class ViewController;

@interface AppDelegate : UIResponder <UIApplicationDelegate>

@property (strong, nonatomic) UIWindow *window;

@property (strong, nonatomic) ViewController *viewController;

@property (strong, nonatomic, readonly) CMMotionManager *sharedMotionManager;

@property (strong, nonatomic, readonly) CLLocationManager *sharedLocationManager;

@end
