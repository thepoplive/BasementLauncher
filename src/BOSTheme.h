#import <UIKit/UIKit.h>

extern NSString *const BOSThemeDidChangeNotification;

@interface BOSTheme : NSObject
+ (instancetype)shared;
@property (nonatomic, readonly) BOOL light;
@property (nonatomic, readonly, getter=isLandscapeMode) BOOL landscapeMode;

- (void)setLightTheme:(BOOL)light;
- (void)setLandscapeMode:(BOOL)on;

- (UIColor *)backgroundColor;
- (UIColor *)textColor;
- (UIColor *)secondaryTextColor;
- (UIColor *)cardColor;
- (UIColor *)accentColor;
- (UIColor *)strokeColor;

- (NSArray *)wallpaperPalette;   // NSArray of NSArray of UIColor (gradient stops)
- (NSUInteger)wallpaperIndex;
- (void)setWallpaperIndex:(NSUInteger)index;

- (NSString *)accentHex;
- (void)setAccentHex:(NSString *)hex;

- (NSUInteger)supportedOrientationsMask;

- (UIButton *)md3FilledButtonWithTitle:(NSString *)title target:(id)target action:(SEL)action;

@end
