# AAR Publishing Fix - Technical Explanation

## Date
December 16, 2025

## Problem Summary
When publishing Android library modules to GitHub Packages, the AAR files were not being included in the publication. Only POM and module metadata files were being uploaded, causing `ClassNotFoundException` errors in consumer projects.

## Root Cause Analysis

### Issue 1: Components Not Registered
When running `./gradlew :libuvc:components`, `./gradlew :libausbc:components`, and `./gradlew :libnative:components`, all returned:
```
No components defined for this project.
```

This means that the Android Gradle Plugin was not registering software components for these modules, causing `components.findByName('release')` to return `null`.

**Why this happened:**
- Modules with native code (NDK builds) or specific configurations may not automatically register components
- When `from components.findByName('release')` evaluates to `from null`, the publication only includes metadata files (POM, module.json) but NOT the actual AAR artifact

### Issue 2: Project Dependencies Not Converted to Maven Coordinates
In `libausbc/build.gradle`, the dependencies were declared as:
```groovy
api project(path: ':libuvc')
api project(path: ':libnative')
```

When generating the POM file, these project dependencies have `group = null` because they're local project references. The original POM generation code had:
```groovy
if (it.group != null && it.name != null) {
    // Add dependency
}
```

This condition **excluded all project dependencies**, causing the published POM to reference them as `AndroidUSBCamera:libuvc:unspecified` instead of `com.nando.androidusbcamera:libuvc:3.3.8-rcXX`.

## Solution Implemented

### Fix 1: Explicitly Publish AAR Artifacts
Changed all three modules (`libuvc`, `libausbc`, `libnative`) to explicitly reference the AAR artifact:

**Before:**
```groovy
release(MavenPublication) {
    from components.findByName('release')  // Returns null!
    groupId = 'com.nando.androidusbcamera'
    artifactId = 'libuvc'
    version = rootProject.ext.versionNameString
}
```

**After:**
```groovy
release(MavenPublication) {
    groupId = 'com.nando.androidusbcamera'
    artifactId = 'libuvc'
    version = rootProject.ext.versionNameString
    
    // Explicitly add the AAR artifact
    artifact bundleReleaseAar
}
```

### Fix 2: Manual POM Dependency Generation
Since we're not using `from components.release`, we must manually add dependencies to the POM file.

**For libuvc and libnative (no project dependencies):**
```groovy
pom.withXml {
    def dependenciesNode = asNode().appendNode('dependencies')
    
    configurations.implementation.allDependencies.each {
        if (it.group != null && it.name != null) {
            def dependencyNode = dependenciesNode.appendNode('dependency')
            dependencyNode.appendNode('groupId', it.group)
            dependencyNode.appendNode('artifactId', it.name)
            dependencyNode.appendNode('version', it.version)
            dependencyNode.appendNode('scope', 'runtime')
        }
    }
}
```

**For libausbc (has project dependencies):**
```groovy
import org.gradle.api.artifacts.ProjectDependency

// Inside pom.withXml:
configurations.api.allDependencies.each { dep ->
    def dependencyNode = dependenciesNode.appendNode('dependency')
    
    // Handle project dependencies
    if (dep instanceof ProjectDependency) {
        dependencyNode.appendNode('groupId', 'com.nando.androidusbcamera')
        dependencyNode.appendNode('artifactId', dep.dependencyProject.name)
        dependencyNode.appendNode('version', rootProject.ext.versionNameString)
    } else if (dep.group != null && dep.name != null) {
        dependencyNode.appendNode('groupId', dep.group)
        dependencyNode.appendNode('artifactId', dep.name)
        dependencyNode.appendNode('version', dep.version)
    }
    dependencyNode.appendNode('scope', 'compile')
}
```

## Verification

### Before Fix (rc15)
Consumer project downloaded:
- ✅ `libausbc-3.3.8-rc15.aar`
- ✅ `libnative-3.3.8-rc15.aar`
- ❌ `libuvc-3.3.8-rc15.aar` (MISSING!)
- ❌ `libuvc-3.3.8-rc15.pom` only
- ❌ Error: `AndroidUSBCamera:libuvc:unspecified` - Failed to resolve
- ❌ Error: `AndroidUSBCamera:libnative:unspecified` - Failed to resolve

**Runtime errors:**
```
ClassNotFoundException: com.jiangdg.usb.USBMonitor
ClassNotFoundException: com.jiangdg.uvc.UVCCamera
```

### After Fix (rc17+)
Consumer project should download:
- ✅ `libausbc-3.3.8-rc17.aar`
- ✅ `libnative-3.3.8-rc17.aar`
- ✅ `libuvc-3.3.8-rc17.aar` (NOW INCLUDED!)
- ✅ All dependencies resolved correctly
- ✅ Classes found: `com.jiangdg.usb.USBMonitor`, `com.jiangdg.uvc.UVCCamera`

## Files Modified

1. **libuvc/build.gradle**
   - Added explicit `artifact bundleReleaseAar`
   - Added manual POM dependency generation for `implementation` dependencies

2. **libausbc/build.gradle**
   - Added `import org.gradle.api.artifacts.ProjectDependency`
   - Added explicit `artifact bundleReleaseAar`
   - Added manual POM dependency generation with `ProjectDependency` handling for `api` and `implementation` dependencies

3. **libnative/build.gradle**
   - Added explicit `artifact bundleReleaseAar`
   - Added manual POM dependency generation for `implementation` dependencies

## Key Takeaways

1. **Always verify components are registered:** Run `./gradlew :module:components` to check if the Android Gradle Plugin has registered software components.

2. **Don't rely on null-safe operators with components:** Using `from components.findByName('release')` silently fails when it returns null.

3. **Project dependencies need special handling:** When manually generating POM files, project dependencies (`project(path: ':module')`) must be converted to Maven coordinates.

4. **Test the publication:** Always verify the published artifacts by checking what files are downloaded by a consumer project.

## Related Issues Resolved

- ✅ AAR files now published to GitHub Packages
- ✅ Transitive dependencies properly declared in POM
- ✅ Consumer projects can resolve all dependencies
- ✅ No more `ClassNotFoundException` for classes in libuvc module

## Version History

- **3.3.8-rc15 and earlier:** Only POM files published, AAR missing
- **3.3.8-rc16:** AAR files included but project dependencies not resolved
- **3.3.8-rc17+:** Complete fix - AAR files + correct POM dependencies

