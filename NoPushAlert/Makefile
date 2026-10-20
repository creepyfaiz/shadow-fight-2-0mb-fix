TARGET := iphone:clang:6.1:6.0
ARCHS = armv7

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = NoPushAlert

NoPushAlert_FILES = Tweak.x
NoPushAlert_CFLAGS = -fno-objc-arc -Wno-deprecated-declarations
NoPushAlert_FRAMEWORKS = UIKit Foundation

include $(THEOS_MAKE_PATH)/tweak.mk

after-install::
	install.exec "killall -9 SpringBoard"
