#import "BOSAppDelegate.h"
#import "BOSNavigationController.h"
#import "BOSTheme.h"
#import "BOSDatabase.h"
#import "BOSHomeViewController.h"

@implementation BOSAppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    [[BOSDatabase sharedDatabase] ensureSchema];

    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    self.window.backgroundColor = [[BOSTheme shared] backgroundColor];

    BOSHomeViewController *home = [[BOSHomeViewController alloc] init];
    self.navController = [[BOSNavigationController alloc] initWithRootViewController:home];
    self.navController.navigationBarHidden = YES;
    self.window.rootViewController = self.navController;

    [self.window makeKeyAndVisible];
    return YES;
}

@end
