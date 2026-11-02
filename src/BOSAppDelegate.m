#import "BOSAppDelegate.h"
#import "BOSTheme.h"
#import "BOSDatabase.h"
#import "BOSHomeViewController.h"

@implementation BOSAppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    self.window.backgroundColor = [[BOSTheme shared] backgroundColor];

    BOSHomeViewController *home = [[BOSHomeViewController alloc] init];
    self.navController = [[UINavigationController alloc] initWithRootViewController:home];
    self.navController.navigationBarHidden = YES;
    self.window.rootViewController = self.navController;

    [[BOSDatabase sharedDatabase] ensureSchema];

    [self.window makeKeyAndVisible];
    return YES;
}

- (void)applicationWillResignActive:(UIApplication *)application {}
- (void)applicationDidEnterBackground:(UIApplication *)application {}
- (void)applicationWillEnterForeground:(UIApplication *)application {}
- (void)applicationDidBecomeActive:(UIApplication *)application {}
- (void)applicationWillTerminate:(UIApplication *)application {}

@end
