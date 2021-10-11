# Build Universal Framworks

**Build Apple platform universal framework with Pods Dependency**

> You need to modify these variables in script files as per your requirments.

```bash
# Available Platforms/Architectures 
# macosx | iphoneos | iphonesimulator | appletvos | appletvsimulator | watchos | watchsimulator


DEVICE_ARCH="${PLATFORM_ARCHITECTURE}" # add Available Platforms/Architectures
DEVICE_SIM_ARCH="${PLATFORM_ARCHITECTURE}" # add Available Platforms/Architectures

FRAMEWORK_NAME="${YOUR_FRAMWORK_NAME}"
```

**Build Apple platform universal framework**

> You need to remove `-workspace ${FRAMEWORK_NAME}.xcworkspace` for you to work from `xcodebuild` if your framework is not depend on any pod.
