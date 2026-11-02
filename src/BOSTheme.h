#import <UIKit/UIKit.h>

@interface BOSTheme : NSObject
+ (instancetype)shared;
@property (nonatomic, readonly) BOOL light;

- (void)setLightTheme:(BOOL)light;
- (UIColor *)backgroundColor;
- (UIColor *)textColor;
- (UIColor *)secondaryTextColor;
- (UIColor *)cardColor;
- (UIColor *)accentColor;

- (UIButton *)md3FilledButtonWithTitle:(NSString *)title target:(id)target action:(SEL)action;
@end
