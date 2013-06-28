//
//  ViewController.m
//  DriveLogger
//
//  Created by Ian Sheret on 31/05/2013.
//  Copyright (c) 2013 Ian Sheret. All rights reserved.
//

#import "ViewController.h"
#import "AppDelegate.h"

@interface ViewController ()
{
    // State
    bool _isLogging;
    bool _fileOpen;
    
    // System boot time
    NSTimeInterval _bootTime;
    
    // Handle for the log file
  	NSFileHandle *_myHandle;
}

- (void)startLogging;
- (void)stopLogging;

@end

@implementation ViewController

@synthesize button = _button;

- (void)viewDidLoad
{
    [super viewDidLoad];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    _isLogging = false;
    [self.button setTitle:@"Start" forState:UIControlStateNormal];
}


- (void)viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
    [self stopLogging];
}


- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)buttonPressed:(id)sender {
    if (!_isLogging) {
        [self.button setTitle:@"Stop" forState:UIControlStateNormal];
        [self startLogging];
        _isLogging = true;
    } else {
        [self.button setTitle:@"Start" forState:UIControlStateNormal];
        [self stopLogging];
        _isLogging = false;
    }
}

- (void) startLogging {

    // Get an estimate of the system boot time, which is needed to interpret CoreMotion timestamps
    NSProcessInfo *processInfo = [NSProcessInfo processInfo];
    NSTimeInterval uptime1 = [processInfo systemUptime];
    NSDate* dateNow = [NSDate date];
    NSTimeInterval uptime2 = [processInfo systemUptime];
    NSTimeInterval uptime = (uptime1 + uptime2) / 2;
    NSTimeInterval timeNow = dateNow.timeIntervalSinceReferenceDate;
    _bootTime = timeNow - uptime;
    
    // Open log file
    NSArray  *myPathList = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory,NSUserDomainMask, YES);
	NSString *myPath = [myPathList  objectAtIndex:0];
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:@"yyyy-MM-dd_HH-mm-ss"];
    NSString* dateString = [dateFormatter stringFromDate:dateNow];
	NSString *myFilename = [myPath stringByAppendingPathComponent:dateString];
    NSString *content    = @"";
	[content writeToFile:myFilename atomically:NO encoding:NSStringEncodingConversionAllowLossy error:nil];
	_myHandle = [NSFileHandle fileHandleForUpdatingAtPath:myFilename];
    _fileOpen = true;
    
    // Start motion updates
    CMMotionManager *motionManager = [(AppDelegate *)[[UIApplication sharedApplication] delegate] sharedMotionManager];
    if ([motionManager isDeviceMotionAvailable] == YES) {
        [motionManager setDeviceMotionUpdateInterval:UPDATE_INTERVAL];
        [motionManager startDeviceMotionUpdatesUsingReferenceFrame:CMAttitudeReferenceFrameXTrueNorthZVertical toQueue:[NSOperationQueue mainQueue] withHandler:^(CMDeviceMotion *deviceMotion, NSError *error) {
            
            // Get the user acceleration, convert into the B frame
            double accB[3];
            accB[0] = -9.80665*deviceMotion.userAcceleration.x;
            accB[1] = -9.80665*deviceMotion.userAcceleration.y;
            accB[2] = -9.80665*deviceMotion.userAcceleration.z;
            
            // Get the angular rates
            double angRateB[3];
            angRateB[0] = deviceMotion.rotationRate.x;
            angRateB[1] = deviceMotion.rotationRate.y;
            angRateB[2] = deviceMotion.rotationRate.z;

            // Get the attitude matrix, convert to using the E and B frames
            double dcmEToB[9];
            dcmEToB[0] = deviceMotion.attitude.rotationMatrix.m11;
            dcmEToB[1] = deviceMotion.attitude.rotationMatrix.m21;
            dcmEToB[2] = deviceMotion.attitude.rotationMatrix.m31;
            dcmEToB[3] = -deviceMotion.attitude.rotationMatrix.m12;
            dcmEToB[4] = -deviceMotion.attitude.rotationMatrix.m22;
            dcmEToB[5] = -deviceMotion.attitude.rotationMatrix.m32;
            dcmEToB[6] = -deviceMotion.attitude.rotationMatrix.m13;
            dcmEToB[7] = -deviceMotion.attitude.rotationMatrix.m23;
            dcmEToB[8] = -deviceMotion.attitude.rotationMatrix.m33;
            double dcmBToE[9];
            for (int i=0; i<3; i++) {
                for (int j=0; j<3; j++) {
                    dcmBToE[j + 3*i] = dcmEToB[i + 3*j];
                }
            }
            
            // Calculate the acceleration in the E frame
            double accE[3];
            accE[0] = dcmBToE[0]*accB[0] + dcmBToE[3]*accB[1] + dcmBToE[6]*accB[2];
            accE[1] = dcmBToE[1]*accB[0] + dcmBToE[4]*accB[1] + dcmBToE[7]*accB[2];
            accE[2] = dcmBToE[2]*accB[0] + dcmBToE[5]*accB[1] + dcmBToE[8]*accB[2];

            // Calculate the angular rate in the E frame
            double angRateE[3];
            angRateE[0] = dcmBToE[0]*angRateB[0] + dcmBToE[3]*angRateB[1] + dcmBToE[6]*angRateB[2];
            angRateE[1] = dcmBToE[1]*angRateB[0] + dcmBToE[4]*angRateB[1] + dcmBToE[7]*angRateB[2];
            angRateE[2] = dcmBToE[2]*angRateB[0] + dcmBToE[5]*angRateB[1] + dcmBToE[8]*angRateB[2];
            
            // Write to log file
            NSData* aData;
            NSString* aStr;
            aStr = [NSString stringWithFormat:@"0, %.16f, %.16f, %.16f, %.16f, %.16f\n",deviceMotion.timestamp + _bootTime, accE[0], accE[1], accE[2], angRateE[2]];
            aData = [aStr dataUsingEncoding: NSASCIIStringEncoding];
            if (_fileOpen) {
                [_myHandle seekToEndOfFile];
                [_myHandle writeData:aData];
            }
            
        }];
    }
    
    // Start location updates
    CLLocationManager *locationManager = [(AppDelegate *)[[UIApplication sharedApplication] delegate] sharedLocationManager];
    locationManager.desiredAccuracy = kCLLocationAccuracyBestForNavigation;
    locationManager.delegate = self;
    [locationManager startUpdatingLocation];

}

- (void) stopLogging {
  
    // Stop logging
    CMMotionManager *motionManager = [(AppDelegate *)[[UIApplication sharedApplication] delegate] sharedMotionManager];
    [motionManager stopDeviceMotionUpdates];
    CLLocationManager *locationManager = [(AppDelegate *)[[UIApplication sharedApplication] delegate] sharedLocationManager];
    [locationManager stopUpdatingLocation];
    
    // Close the file
    _fileOpen = false;
    [_myHandle closeFile];
    NSLog(@"Closed the file");

}

- (void)locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray *)locations{

    // Loop over the locations
    int numLocations = locations.count;
    for (int i=0; i<numLocations; i++) {
        CLLocation* location = [locations objectAtIndex:i];
        NSData* aData;
        NSString* aStr;
        aStr = [NSString stringWithFormat:@"1, %.16f, %.16f, %.16f, %.16f, %.16f, %.16f\n",
                location.timestamp.timeIntervalSinceReferenceDate,
                location.coordinate.latitude*M_PI/180.0, location.coordinate.longitude*M_PI/180.0,
                location.speed, location.course*M_PI/180.0, location.horizontalAccuracy ];
        
        aData = [aStr dataUsingEncoding: NSASCIIStringEncoding];
        if (_fileOpen) {
            [_myHandle seekToEndOfFile];
            [_myHandle writeData:aData];
        }
    }

}

@end
