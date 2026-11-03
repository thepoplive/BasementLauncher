#import <Foundation/Foundation.h>

@interface BOSDatabase : NSObject
+ (instancetype)sharedDatabase;

- (void)ensureSchema;
- (NSArray *)queryWithSQL:(NSString *)sql arguments:(NSArray *)args;
- (BOOL)executeWithSQL:(NSString *)sql arguments:(NSArray *)args insertedId:(long long *)insertedId;

- (NSString *)stateForKey:(NSString *)key;
- (void)setStateValue:(NSString *)value forKey:(NSString *)key;

@end
