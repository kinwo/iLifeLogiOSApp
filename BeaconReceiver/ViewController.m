//
//  ViewController.m
//  BeaconReceiver
//
//  Created by Henry Chan on 2014-07-14.
//  Copyright (c) 2014 TheLivingApps. All rights reserved.
//

#import "ViewController.h"
#import <Parse/Parse.h>


@interface ViewController () <UIWebViewDelegate, CLLocationManagerDelegate>

@property (weak, nonatomic) IBOutlet UIWebView *webView;
@property (nonatomic, assign) CLProximity lastProximity;

@end

@implementation ViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
    
    // Initialize location manager and set ourselves as the delegate
    self.locationManager = [[CLLocationManager alloc] init];
    self.locationManager.delegate = self;
    
    // Create a NSUUID with the same UUID as the broadcasting beacon
    NSUUID *uuid = [[NSUUID alloc] initWithUUIDString:@"f7826da6-4fa2-4e98-8024-bc5b71e0893e"];
    
    // Setup a new region with that UUID and same identifier as the broadcasting beacon
    self.myBeaconRegion = [[CLBeaconRegion alloc] initWithProximityUUID:uuid major:38056 minor:48419                                                             identifier:@"com.thelivingapps.testregion"];
    self.myBeaconRegion.notifyEntryStateOnDisplay = YES;
    
    // Tell location manager to start monitoring for the beacon region
    [self.locationManager startMonitoringForRegion:self.myBeaconRegion];
    
    // Check if beacon monitoring is available for this device
    if (![CLLocationManager isMonitoringAvailableForClass:[CLBeaconRegion class]]) {
        
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Monitoring not available" message:nil delegate:nil cancelButtonTitle:@"Ok" otherButtonTitles: nil]; [alert show]; return;
    }
}

- (void)viewWillAppear:(BOOL)animated
{
    NSURLRequest* urlRequest = [NSURLRequest requestWithURL:[NSURL URLWithString:@"https://www.parse.com/apps/ibeacon--25/collections"]];
    [self.webView loadRequest:urlRequest];
}


#pragma mark iBeacon
- (void)sendBeaconLogWithInOrOut:(NSString*)inOrOut proximity:(NSString*)proximity
{
    PFObject *beaconLog = [PFObject objectWithClassName:@"BeaconLog"];
    beaconLog[@"inOrOut"] = inOrOut;
    beaconLog[@"proximity"] = proximity;
    [beaconLog saveInBackground];
}

- (NSString *)nameForProximity:(CLProximity)proximity
{
    switch (proximity) {
        case CLProximityUnknown:
            return @"Unknown";
            break;
        case CLProximityImmediate:
            return @"Immediate";
            break;
        case CLProximityNear:
            return @"Near";
            break;
        case CLProximityFar:
            return @"Far";
            break;
    }
}

#pragma mark CLLocationManagerDelegate
- (void)locationManager:(CLLocationManager*)manager didEnterRegion:(CLRegion *)region
{
    [self processEnterRegion];
}

- (void)processEnterRegion
{
    // We entered a region, now start looking for our target beacons!
    self.statusLabel.text = @"Finding beacons.";
    [self.locationManager startRangingBeaconsInRegion:self.myBeaconRegion];
}

-(void)locationManager:(CLLocationManager*)manager didExitRegion:(CLRegion *)region
{
    [self processLeaveRegion];
}

- (void)processLeaveRegion
{
    // Exited the region
    self.statusLabel.text = @"None found.";
    [self sendBeaconLogWithInOrOut:@"out" proximity:@""];
    [self.locationManager stopRangingBeaconsInRegion:self.myBeaconRegion];
}

- (void)locationManager:(CLLocationManager *)manager didDetermineState:(CLRegionState)state forRegion:(CLRegion *)region
{
    switch (state) {
        case CLRegionStateInside:
            [self processEnterRegion];
            break;
        case CLRegionStateOutside:
            [self processLeaveRegion];
            break;
        case CLRegionStateUnknown:
            break;
        default:
            break;
    }
}

-(void)locationManager:(CLLocationManager*)manager
       didRangeBeacons:(NSArray*)beacons
              inRegion:(CLBeaconRegion*)region
{
    // Beacon found!
    CLBeacon *foundBeacon = [beacons firstObject];
    self.statusLabel.text = [NSString stringWithFormat:@"Beacon found with proximity: %@", [self nameForProximity:foundBeacon.proximity]];
    if (self.lastProximity != foundBeacon.proximity) {
        [self sendBeaconLogWithInOrOut:@"in" proximity:[self nameForProximity:foundBeacon.proximity]];
    }
    self.lastProximity = foundBeacon.proximity;
}

@end
