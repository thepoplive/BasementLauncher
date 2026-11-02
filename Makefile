TARGET := iphone:clang:latest:8.4.1
ARCHS = armv7

include $(THEOS)/makefiles/common.mk

APPLICATION_NAME = BasementOS
BasementOS_FILES = src/main.m src/BOSAppDelegate.m src/BOSTheme.m src/BOSDatabase.m src/BOSProcess.m src/BOSHomeViewController.m src/BOSClockViewController.m src/BOSCalendarViewController.m src/BOSNotesViewController.m src/BOSFilesViewController.m src/BOSServerManagerViewController.m src/BOSTerminalViewController.m src/BOSSettingsViewController.m
BasementOS_FRAMEWORKS = UIKit Foundation
BasementOS_LDFLAGS = -lsqlite3
BasementOS_CFLAGS = -fobjc-arc

include $(THEOS_MAKE_PATH)/application.mk
