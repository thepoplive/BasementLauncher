TARGET := iphone:clang:latest:8.4.1
ARCHS = armv7

include $(THEOS)/makefiles/common.mk

APPLICATION_NAME = BasementOS
BasementOS_FILES = main.m BOSAppDelegate.m BOSTheme.m BOSDatabase.m BOSProcess.m BOSHomeViewController.m BOSClockViewController.m BOSCalendarViewController.m BOSNotesViewController.m BOSFilesViewController.m BOSServerManagerViewController.m BOSTerminalViewController.m BOSSettingsViewController.m
BasementOS_FRAMEWORKS = UIKit Foundation
BasementOS_LDFLAGS = -lsqlite3
BasementOS_CFLAGS = -fobjc-arc

include $(THEOS_MAKE_PATH)/application.mk
