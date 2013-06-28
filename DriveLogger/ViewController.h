//
//  ViewController.h
//  DriveLogger
//
//  Created by Ian Sheret on 31/05/2013.
//  Copyright (c) 2013 Ian Sheret. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <CoreLocation/CoreLocation.h>

#define UPDATE_INTERVAL 0.01

@interface ViewController : UIViewController <CLLocationManagerDelegate>

@property (nonatomic, weak) IBOutlet UIButton *button;

- (IBAction)buttonPressed:(id)sender;

- (void)locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray *)locations;

@end
