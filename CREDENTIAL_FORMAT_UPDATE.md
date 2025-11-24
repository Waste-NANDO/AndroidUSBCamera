# ✅ Credential Format Update Complete

## What Changed

Your repository now supports **both** credential formats in `local.properties`:

### ✅ Recommended Format (Your preference - consistent with other repos)
```properties
github.actor=YOUR_USERNAME
github.token=YOUR_TOKEN
```

### ✅ Legacy Format (Still supported)
```properties
gpr.user=YOUR_USERNAME
gpr.token=YOUR_TOKEN
```

## Files Updated

1. **`quick-publish.sh`**
   - Now detects both credential formats
   - Prompts you to choose which format when adding credentials
   - Shows which format is being used

2. **`libausbc/build.gradle`**
   - Credential resolution order: `GITHUB_ACTOR` env → `github.actor` → `gpr.user`

3. **`libuvc/build.gradle`**
   - Credential resolution order: `GITHUB_ACTOR` env → `github.actor` → `gpr.user`

4. **`libnative/build.gradle`**
   - Credential resolution order: `GITHUB_ACTOR` env → `github.actor` → `gpr.user`

5. **Documentation Updated:**
   - `GITHUB_PACKAGES_GUIDE.md`
   - `PUBLISH_SUMMARY.md`
   - `PUBLISHING_FAQ.md`

## How It Works

The credential resolution follows this priority:

1. **Environment variables** (highest priority)
   - `GITHUB_ACTOR` and `GITHUB_TOKEN`
   
2. **github.actor/github.token** (recommended)
   - Your preferred format
   
3. **gpr.user/gpr.token** (fallback)
   - Legacy format for backward compatibility

## Usage Examples

### Use your preferred format:
```bash
# Add to local.properties
echo "github.actor=NicoMederoReLearn" >> local.properties
echo "github.token=ghp_your_token_here" >> local.properties

# Then publish
./gradlew publish
```

### Or use the interactive script:
```bash
./quick-publish.sh
# Choose option 2 (publish locally)
# Select format 1 (github.actor) when prompted
```

## Testing

You can verify it works by:

```bash
# Option 1: Test with the quick script
./quick-publish.sh

# Option 2: Test directly with Gradle
./gradlew publish
```

Both formats will work seamlessly! 🎉

## Migration Note

If you already have `gpr.user`/`gpr.token` in your `local.properties`, you don't need to change anything. The system will continue to work.

If you want to switch to the new format, simply:
1. Remove or comment out the old format
2. Add the new format:
   ```properties
   #gpr.user=NicoMederoReLearn
   #gpr.token=old_token
   github.actor=NicoMederoReLearn
   github.token=new_token
   ```

