include theos/makefiles/common.mk

TWEAK_NAME = RemoteShutterCameraLauncher
RemoteShutterCameraLauncher_FILES = Tweak.xm
RemoteShutterCameraLauncher_FRAMEWORKS = UIKit IOKit AVFoundation

include $(THEOS_MAKE_PATH)/tweak.mk

after-install::
	install.exec "killall -9 SpringBoard"
