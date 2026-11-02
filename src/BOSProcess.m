#import "BOSProcess.h"
#import <dirent.h>

@implementation BOSProcess

+ (char **)argvFor:(NSString *)cmd arguments:(NSArray *)args {
    NSMutableArray *all = [NSMutableArray array];
    [all addObject:cmd ?: @""];
    for (NSString *s in (args ?: @[])) [all addObject:(s ?: @"")];
    NSUInteger count = [all count];
    char **argv = (char **)calloc(count + 1, sizeof(char *));
    for (NSUInteger i = 0; i < count; i++)
        argv[i] = strdup([all[i] UTF8String]);
    argv[count] = NULL;
    return argv;
}

+ (void)freeArgv:(char **)argv {
    for (int i = 0; argv[i] != NULL; i++) free(argv[i]);
    free(argv);
}

+ (NSString *)outputOfCommand:(NSString *)cmd arguments:(NSArray *)args {
    int fds[2];
    if (pipe(fds) != 0) return nil;
    pid_t pid = fork();
    if (pid == 0) {
        close(fds[0]);
        dup2(fds[1], 1);
        dup2(fds[1], 2);
        close(fds[1]);
        char **argv = [BOSProcess argvFor:cmd arguments:args];
        execv([cmd UTF8String], argv);
        _exit(127);
    }
    close(fds[1]);
    NSMutableData *data = [NSMutableData data];
    char buf[4096];
    ssize_t n;
    while ((n = read(fds[0], buf, sizeof(buf))) > 0)
        [data appendBytes:buf length:n];
    close(fds[0]);
    int status = 0;
    waitpid(pid, &status, 0);
    return [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding] ?: @"";
}

+ (int)runCommand:(NSString *)cmd arguments:(NSArray *)args {
    pid_t pid = fork();
    if (pid == 0) {
        setsid();
        signal(SIGCHLD, SIG_DFL);
        int devnull = open("/dev/null", O_WRONLY);
        if (devnull >= 0) {
            dup2(devnull, 1);
            dup2(devnull, 2);
        }
        close(devnull);
        char **argv = [BOSProcess argvFor:cmd arguments:args];
        execv([cmd UTF8String], argv);
        _exit(127);
    }
    if (pid > 0) signal(SIGCHLD, SIG_IGN);
    return (int)pid;
}

+ (int)pidOfProcessNamed:(NSString *)name {
    if (!name.length) return 0;
    DIR *dir = opendir("/proc");
    if (!dir) return 0;
    const char *needle = [name UTF8String];
    struct dirent *entry;
    int found = 0;
    while ((entry = readdir(dir)) != NULL && found == 0) {
        int pid = atoi(entry->d_name);
        if (pid <= 1) continue;
        char path[256];
        snprintf(path, sizeof(path), "/proc/%d/cmdline", pid);
        FILE *f = fopen(path, "r");
        if (!f) continue;
        char buf[1024];
        memset(buf, 0, sizeof(buf));
        size_t got = fread(buf, 1, sizeof(buf) - 1, f);
        fclose(f);
        if (got == 0) continue;
        for (size_t i = 0; i < got - 1; i++)
            if (buf[i] == '\0') buf[i] = ' ';
        if (strstr(buf, needle) != NULL) found = pid;
    }
    closedir(dir);
    return found;
}

+ (void)killProcessNamed:(NSString *)name {
    int pid = [BOSProcess pidOfProcessNamed:name];
    if (pid > 0) {
        kill(pid, SIGTERM);
        sleep(1);
        if (kill(pid, 0) == 0) kill(pid, SIGKILL);
        return;
    }
    [BOSProcess outputOfCommand:@"/usr/bin/killall" arguments:@[name]];
}

@end
