#import "ViewController.h"

#include "exploit/exploit.h"
#include "exploit/kernel_rw.h"

#include <pthread.h>

static NSMutableString *logs;

static int go(void)
{
    uint64_t kernel_base = 0;
    
    if (exploit_get_krw_and_kernel_base(&kernel_base) != 0)
    {
		[[NSNotificationCenter defaultCenter] postNotificationName: @"updateLog" object:nil userInfo:@{@"logs": @"Exploit failed!\n"}];
		[[NSNotificationCenter defaultCenter] postNotificationName: @"done" object:nil userInfo:@{@"info": @"Exploit failed!"}];
        return 1;
    }
    
    // test kernel r/w, read kernel base
    uint32_t mh_magic = kread32(kernel_base);
    if (mh_magic != 0xFEEDFACF)
    {
		[[NSNotificationCenter defaultCenter] postNotificationName: @"updateLog" object:nil userInfo:@{@"logs": [[NSString alloc] initWithFormat:@"mh_magic != 0xFEEDFACF: %08X\n", mh_magic]}];
		[[NSNotificationCenter defaultCenter] postNotificationName: @"done" object:nil userInfo:@{@"info": @"Exploit failed!"}];
        return 1;
    }
    
	[[NSNotificationCenter defaultCenter] postNotificationName: @"updateLog" object:nil userInfo:@{@"logs": [[NSString alloc] initWithFormat:@"kread32(_kernel_base) success: %08X\n", mh_magic]}];
    
	[[NSNotificationCenter defaultCenter] postNotificationName: @"updateLog" object:nil userInfo:@{@"logs": @"Done\n"}];
	[[NSNotificationCenter defaultCenter] postNotificationName: @"done" object:nil userInfo:@{@"info": @"Done"}];
    
    return 0;
}

@interface ViewController ()

@end

@implementation ViewController

- (void)updateLogFromNotification:(id)sender{
	dispatch_async(dispatch_get_main_queue(), ^{
		[logs appendFormat:@"%@", [sender userInfo][@"logs"]];
		[self->_TextView setText:logs];
		[self->_TextView scrollRangeToVisible:NSMakeRange(self->_TextView.text.length, 1)];
	});
}

- (void)doneFromNotification:(id)sender{
	dispatch_async(dispatch_get_main_queue(), ^{
		[self->_Button setAttributedTitle:[[NSAttributedString alloc] initWithString:[sender userInfo][@"info"] attributes:@{NSFontAttributeName:self->_Button.titleLabel.font}] forState:UIControlStateNormal];
		self->_Button.frame = CGRectMake((self.view.frame.size.width - [self->_Button sizeThatFits:CGSizeMake(self.view.safeAreaLayoutGuide.layoutFrame.size.width, self->_Button.frame.size.height)].width)/2, self->_Button.frame.origin.y, [self->_Button sizeThatFits:CGSizeMake(self.view.safeAreaLayoutGuide.layoutFrame.size.width, self->_Button.frame.size.height)].width, self->_Button.frame.size.height);
	});
}

- (void)viewDidLoad {
	_Label.frame = CGRectMake(_Label.frame.origin.x, _Label.frame.origin.y, [_Label sizeThatFits:CGSizeMake(self.view.safeAreaLayoutGuide.layoutFrame.size.width, _Label.frame.size.height)].width, _Label.frame.size.height);
	_Button.frame = CGRectMake(_Button.frame.origin.x, _Button.frame.origin.y, [_Button sizeThatFits:CGSizeMake(self.view.safeAreaLayoutGuide.layoutFrame.size.width, _Button.frame.size.height)].width, _Button.frame.size.height);
    [super viewDidLoad];
	logs = [[NSMutableString alloc] init];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updateLogFromNotification:) name:@"updateLog" object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(doneFromNotification:) name:@"done" object:nil];

}

- (void)viewSafeAreaInsetsDidChange {
	_Label.frame = CGRectMake((self.view.frame.size.width - _Label.frame.size.width)/2, self.view.safeAreaInsets.top + self.view.superview.layoutMargins.top, _Label.frame.size.width, _Label.frame.size.height);
	_Button.frame = CGRectMake((self.view.frame.size.width - _Button.frame.size.width)/2, self.view.safeAreaInsets.top + self.view.safeAreaLayoutGuide.layoutFrame.size.height - _Button.frame.size.height - self.view.superview.layoutMargins.bottom, _Button.frame.size.width, _Button.frame.size.height);
	_TextView.frame = CGRectMake(self.view.superview.layoutMargins.left, self.view.safeAreaInsets.top + _Label.frame.size.height + 8, self.view.frame.size.width - 2 * self.view.superview.layoutMargins.left, _Button.frame.origin.y - _Label.frame.origin.y - _Label.frame.size.height - 8);
	[super viewSafeAreaInsetsDidChange];

}

- (IBAction)Exploit:(id)sender {
	[_Button setUserInteractionEnabled:false];
	[_Button setAttributedTitle:[[NSAttributedString alloc] initWithString:@"Exploiting..." attributes:@{NSFontAttributeName:_Button.titleLabel.font}] forState:UIControlStateNormal];
	_Button.frame = CGRectMake((self.view.frame.size.width - [_Button sizeThatFits:CGSizeMake(self.view.safeAreaLayoutGuide.layoutFrame.size.width, _Button.frame.size.height)].width)/2, _Button.frame.origin.y, [_Button sizeThatFits:CGSizeMake(self.view.safeAreaLayoutGuide.layoutFrame.size.width, _Button.frame.size.height)].width, _Button.frame.size.height);
	pthread_t pt;
	pthread_create(&pt, NULL, (void *(*)(void *))go, NULL);
	
	// uncomment for synchronous
	// pthread_join(pt, NULL);
}

@end
