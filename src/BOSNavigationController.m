#import "BOSNavigationController.h"
#import "BOSTheme.h"

@implementation BOSNavigationController

- (BOOL)shouldAutorotate {
    return YES;
}

- (NSUInteger)supportedInterfaceOrientations {
    return [[BOSTheme shared] supportedOrientationsMask];
}

@end
