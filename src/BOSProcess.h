#import <Foundation/Foundation.h>

@interface BOSProcess : NSObject
+ (NSString *)outputOfCommand:(NSString *)cmd arguments:(NSArray *)args;
+ (int)runCommand:(NSString *)cmd arguments:(NSArray *)args;
+ (int)pidOfProcessNamed:(NSString *)name;
+ (void)killProcessNamed:(NSString *)name;
@end
