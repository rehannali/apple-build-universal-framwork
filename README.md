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
> If you are using bitbucket version of script then modify these variables as well.

```bash
BITBUCKET_WORKSPACE_NAME="${YOUR_WORKSPACE_NAME}"
BITBUCKET_REPO_NAME="${YOUR_REPO_SLUG}"
```

**Build Apple platform universal framework**

> You need to remove `-workspace ${FRAMEWORK_NAME}.xcworkspace` for you to work from `xcodebuild` if your framework is not depend on any pod.

**Public repo binary distribution Github using SPM**

> You need to add you public repo path to work fully automation.

**Private repo binary distribution Bitbucket using spm**

> You need to configure credentials to work with private repo for upload and download artifacts.
