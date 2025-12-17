# SIGBUS Fix Summary - Quick Reference

## What Was Fixed
The SIGBUS crash in your UVC camera library was caused by **memory alignment issues** when accessing camera frame buffers on devices with 16KB page sizes.

## Files Modified
- `/libuvc/src/main/jni/libuvc/src/frame.c`

## Changes Made

### 1. Added Aligned Memory Allocation Helper
```c
static inline void* aligned_malloc(size_t size) {
    if (size == 0) return NULL;
    void* ptr = NULL;
    // Align to 16KB (16384 bytes) for 16KB page size support
    if (posix_memalign(&ptr, 16384, size) != 0) {
        return NULL;
    }
    return ptr;
}
```

### 2. Fixed `uvc_allocate_frame()` Function
**Before:** Used regular `malloc()` (no alignment guarantee)
```c
frame->data = malloc(data_bytes);
```

**After:** Uses `aligned_malloc()` (16KB aligned)
```c
frame->data = aligned_malloc(data_bytes);
```

### 3. Fixed `uvc_ensure_frame_size()` Function  
**Before:** Used `realloc()` (no alignment guarantee)
```c
frame->data = realloc(frame->data, frame->data_bytes);
```

**After:** Uses `aligned_malloc()` with manual copy
```c
void* new_data = aligned_malloc(need_bytes);
if (new_data && frame->data && old_size > 0) {
    memcpy(new_data, frame->data, old_size < need_bytes ? old_size : need_bytes);
    free(frame->data);
}
frame->data = new_data;
```

## Why This Fixes SIGBUS

1. **SIGBUS occurs when**: Memory is accessed at addresses that aren't properly aligned for the system's page size
2. **On 16KB page devices**: Memory must be aligned to 16KB boundaries (16384 bytes)
3. **Standard malloc()**: Only guarantees 8-16 byte alignment, not 16KB
4. **posix_memalign()**: Guarantees alignment to any power-of-2 boundary (we use 16384)

## Testing Your Fix

### Before Publishing
```bash
# Build with the fix
./gradlew clean assembleRelease

# Verify 16KB compliance with APK Analyzer
# Android Studio → Build → Analyze APK → Check warnings
```

### Publishing New Version
```bash
# Update version in gradle.properties
# Then publish
./gradlew publish
```

### In Your Consuming App
Update the version in `libs.versions.toml`:
```toml
nandoUsbCamera = "3.3.8-rc17"  # or whatever your next version is
```

## Expected Results

✅ **No more SIGBUS crashes** on 16KB page devices  
✅ **Works on both** 4KB and 16KB page size devices  
✅ **APK Analyzer** shows no 16KB warnings for native libs  
✅ **Camera operations** stable during start/stop/resolution changes

## Where Crashes Were Happening

Based on the Firebase stacktrace:
- Frame allocation during camera initialization
- Buffer resizing during resolution changes
- Frame pool operations during continuous capture
- Any memory access to camera frame data

All these paths now use properly aligned memory.

## Next Steps

1. Build and test locally
2. Publish new version
3. Test on 16KB page device (if available) or use Android 15+ emulator
4. Monitor Firebase Crashlytics for SIGBUS occurrences

## Documentation
See `SIGBUS_FIX_16KB_PAGES.md` for detailed technical explanation.

