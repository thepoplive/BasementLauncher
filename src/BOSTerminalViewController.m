#import "BOSTerminalViewController.h"
#import "BOSTheme.h"
#import "BOSProcess.h"

@interface BOSTerminalViewController () <UITextFieldDelegate>
@end

@implementation BOSTerminalViewController {
    UITextView *_editor;
    UITextField *_field;
    UIButton *_run;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    _editor = [[UITextView alloc] init];
    _editor.font = [UIFont fontWithName:@"Menlo-Regular" size:12];
    _editor.editable = NO;
    _editor.text = @"basement ~$" ;
    _field = [[UITextField alloc] init];
    _field.placeholder = @"command";
    _field.font = [UIFont fontWithName:@"Menlo-Regular" size:14];
    _field.borderStyle = UITextBorderStyleRoundedRect;
    _field.delegate = self;
    _run = [[BOSTheme shared] md3FilledButtonWithTitle:@"Run" target:self action:@selector(runCommand)];
    [self.view addSubview:_editor];
    [self.view addSubview:_field];
    [self.view addSubview:_run];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    self.view.backgroundColor = [[BOSTheme shared] backgroundColor];
    _editor.backgroundColor = [[BOSTheme shared] cardColor];
    _editor.textColor = [[BOSTheme shared] textColor];
    _field.textColor = [[BOSTheme shared] textColor];
}

- (void)runCommand {
    NSString *line = _field.text;
    if (!line.length) return;
    NSString *out = [BOSProcess outputOfCommand:@"/bin/sh" arguments:@[@"-c", line ?: @""]] ?: @"";
    NSString *block = [NSString stringWithFormat:@"\n$ %@\n%@", line, out];
    _editor.text = [_editor.text stringByAppendingString:block];
    NSRange bottom = NSMakeRange(_editor.text.length - 1, 1);
    [_editor scrollRangeToVisible:bottom];
    _field.text = @"";
    [_field resignFirstResponder];
}

- (BOOL)textFieldShouldReturn:(UITextField *)field {
    [self runCommand];
    return YES;
}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    CGFloat w = self.view.bounds.size.width;
    CGFloat h = self.view.bounds.size.height;
    _editor.frame = CGRectMake(16.0, 16.0, w - 32.0, h - 112.0);
    _field.frame = CGRectMake(16.0, h - 84.0, w - 120.0, 38.0);
    _run.frame = CGRectMake(w - 96.0, h - 84.0, 80.0, 38.0);
}

@end
