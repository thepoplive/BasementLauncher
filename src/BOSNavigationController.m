#import "BOSNavigationController.h"
#import "BOSTheme.h"

@implementation BOSNavigationController

- (BOOL)shouldAutorotate {
    return YES;
}

- (UIInterfaceOrientationMask)supportedInterfaceOrientations {
    return [[BOSTheme shared] supportedOrientationsMask];
}

@end
