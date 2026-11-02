#import "BOSDatabase.h"
#import <sqlite3.h>

static NSString *kDBPath = @"/var/mobile/Library/BasementOS/basementos.sqlite";

@implementation BOSDatabase {
    sqlite3 *_db;
}

+ (instancetype)sharedDatabase {
    static BOSDatabase *s;
    static dispatch_once_t once;
    dispatch_once(&once, ^{ s = [[BOSDatabase alloc] init]; });
    return s;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        BOOL ok = [[NSFileManager defaultManager] createDirectoryAtPath:@"/var/mobile/Library/BasementOS" withIntermediateDirectories:YES attributes:nil error:NULL];
        if (!ok) NSLog(@"BOSDatabase: mkdir failed, errno=%d", errno);
        if (sqlite3_open([kDBPath UTF8String], &_db) != SQLITE_OK)
            NSLog(@"BOSDatabase: open failed: %s", sqlite3_errmsg(_db));
    }
    return self;
}

- (void)dealloc {
    if (_db) sqlite3_close(_db);
}

- (void)ensureSchema {
    [self executeWithSQL:@"CREATE TABLE IF NOT EXISTS notes (id INTEGER PRIMARY KEY AUTOINCREMENT, text TEXT)" arguments:nil insertedId:NULL];
    [self executeWithSQL:@"CREATE TABLE IF NOT EXISTS events (id INTEGER PRIMARY KEY AUTOINCREMENT, event_date TEXT, title TEXT)" arguments:nil insertedId:NULL];
    [self executeWithSQL:@"CREATE TABLE IF NOT EXISTS state (key TEXT PRIMARY KEY, value TEXT)" arguments:nil insertedId:NULL];

}

- (void)bindArguments:(NSArray *)args toStatement:(sqlite3_stmt *)stmt {
    for (int i = 0; i < (int)[args count]; i++) {
        id arg = [args objectAtIndex:i];
        if ([arg isKindOfClass:[NSNumber class]]) {
            sqlite3_bind_int64(stmt, i + 1, [arg longLongValue]);
        } else {
            NSString *text = [arg description];
            sqlite3_bind_text(stmt, i + 1, [text UTF8String], -1, SQLITE_TRANSIENT);
        }
    }
}

- (NSArray *)queryWithSQL:(NSString *)sql arguments:(NSArray *)args {
    NSMutableArray *rows = [NSMutableArray array];
    sqlite3_stmt *stmt = NULL;
    if (sqlite3_prepare_v2(_db, [sql UTF8String], -1, &stmt, NULL) != SQLITE_OK) {
        NSLog(@"BOSDatabase query failed: %s", sqlite3_errmsg(_db));
        return rows;
    }
    [self bindArguments:args toStatement:stmt];
    while (sqlite3_step(stmt) == SQLITE_ROW) {
        NSMutableDictionary *row = [NSMutableDictionary dictionary];
        for (int i = 0; i < sqlite3_column_count(stmt); i++) {
            const char *name = sqlite3_column_name(stmt, i);
            id value;
            if (sqlite3_column_type(stmt, i) == SQLITE_NULL) {
                value = [NSNull null];

            } else {
                value = [NSString stringWithUTF8String:(const char *)sqlite3_column_text(stmt, i)];
            }
            row[[NSString stringWithUTF8String:name]] = value;
        }
        [rows addObject:row];
    }
    sqlite3_finalize(stmt);
    return rows;
}

- (BOOL)executeWithSQL:(NSString *)sql arguments:(NSArray *)args insertedId:(long long *)insertedId {
    sqlite3_stmt *stmt = NULL;
    if (sqlite3_prepare_v2(_db, [sql UTF8String], -1, &stmt, NULL) != SQLITE_OK) {
        NSLog(@"BOSDatabase execute failed: %s", sqlite3_errmsg(_db));
        return NO;
    }
    [self bindArguments:args toStatement:stmt];
    BOOL ok = (sqlite3_step(stmt) == SQLITE_DONE);
    if (!ok) NSLog(@"BOSDatabase execute failed: %s", sqlite3_errmsg(_db));
    if (ok && insertedId) *insertedId = sqlite3_last_insert_rowid(_db);
    sqlite3_finalize(stmt);
    return ok;
}

@end
