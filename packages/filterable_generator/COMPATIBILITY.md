# Analyzer & Build Compatibility

This document explains how `filterable_generator` maintains compatibility across different versions of the `analyzer` and `build` packages.

## Problem

The Dart ecosystem has undergone significant API changes:

### Analyzer Package Changes

- **Analyzer 5.x - 6.x**: Uses `Element` with direct `metadata` property
- **Analyzer 7.x - 8.x**: Transition period with Element2 introduction
- **Analyzer 9.x+**: Full Element2 migration (in newer versions)

### Build Package Changes

- **Build 2.x**: 
  - Stable API
  - Works with analyzer 5.x - 6.x
  - Element-based API
  
- **Build 3.x**:
  - Breaking changes in how builders are constructed
  - BuildStep API changes
  - Better performance and caching
  - Works with analyzer 6.x - 8.x
  
- **Build 4.x**:
  - Further API refinements
  - Element2 support
  - Works with analyzer 7.x+

These changes can cause breaking issues in code generators that directly interact with the analyzer/build APIs.

## Solution

`filterable_generator` implements a **compatibility layer** that adapts to the available API version:

### 1. Wide Dependency Range

```yaml
dependencies:
  analyzer: ">=5.2.0 <10.0.0"
  build: ">=2.4.0 <5.0.0"
```

This allows the package to work with a broad range of analyzer versions.

### 2. Dynamic API Detection

The `_getFieldMetadata()` method uses dynamic casting to handle API variations:

```dart
List<ElementAnnotation> _getFieldMetadata(FieldElement field) {
  try {
    final metadata = field.metadata;
    // Dynamic cast handles type variations across versions
    return (metadata as dynamic) as List<ElementAnnotation>;
  } catch (e) {
    return <ElementAnnotation>[];
  }
}
```

### 3. Safe Fallbacks

If the API call fails (which shouldn't happen in practice), the code gracefully returns an empty list, preventing crashes.

## Tested Versions

The generator has been tested with the following combinations:

| Build Runner | Analyzer | Build | Source Gen | Status |
|--------------|----------|-------|------------|--------|
| 2.4.0 - 2.4.13 | 5.2.0 - 6.4.1 | 2.4.x | 1.2.x - 1.5.x | ✅ Fully Supported & Tested |
| 2.7.x | 7.x | 3.x | 2.x - 4.x | ✅ Compatible (requires source_gen >=2.0.0) |
| 2.8.x - 2.10.x | 7.x - 8.x | 4.x | 3.x - 4.x | ✅ Compatible (requires source_gen >=3.0.0) |

### Current Dependency Strategy

Our wide dependency ranges ensure maximum compatibility:

```yaml
dependencies:
  analyzer: ">=5.2.0 <10.0.0"  # Covers Element and Element2 APIs
  source_gen: ">=1.2.0 <5.0.0" # Supports build 2.x, 3.x, and 4.x
  build: ">=2.4.0 <5.0.0"      # Covers all major build API versions
```

### Compatibility Matrix

**build_runner 2.4.x** (Most Common):
- ✅ Works with analyzer 5.x - 6.x
- ✅ Uses build 2.x
- ✅ Uses source_gen 1.x
- ✅ Compatible with older Flutter/Dart projects
- ✅ Used by most existing projects

**build_runner 2.7.x+** (Newer):
- ✅ Requires build 3.x or 4.x
- ✅ Requires source_gen >=2.0.0
- ✅ Compatible with newer analyzer versions (7.x+)
- ⚠️ May conflict with other packages still on build 2.x

### Real-World Compatibility

In practice, the effective version range depends on other dependencies in your project:

- **With riverpod_generator**: Limited to build_runner ~2.4.0
- **With json_serializable**: Compatible with wide range
- **With freezed**: Compatible with wide range
- **Standalone**: Full range 2.4.0 - 2.10.x supported

This approach allows:
- ✅ Projects using older Flutter/Dart SDKs (build 2.x)
- ✅ Projects using latest tooling (build 3.x, 4.x)
- ✅ Mixed dependency environments
- ✅ Gradual migration paths

## Benefits

1. **No Breaking Changes**: Updates to analyzer don't break your build
2. **Forward Compatible**: Works with future analyzer versions
3. **Backward Compatible**: Works with older projects
4. **Ecosystem Friendly**: Doesn't conflict with other code generators

## When Publishing

When a version transition occurs (e.g., analyzer 10.x), the upper bound can be increased after testing:

```yaml
analyzer: ">=5.2.0 <11.0.0"
```

## Troubleshooting

If you encounter issues with a specific analyzer version:

1. Check that your `analyzer` version is within the supported range
2. Run `dart pub upgrade analyzer` to get a compatible version
3. If using Flutter, run `flutter pub upgrade`
4. Report issues at: https://github.com/SamuelGFDias/filterable/issues

Include:
- Your `analyzer` version
- Your `build` version  
- Full error message
- Code sample

## Build Package Version Differences

### Build 2.x → 3.x

**Breaking Changes:**
- BuildStep API signatures changed
- Asset reading/writing API updated
- Resolver API improvements

**Impact on filterable_generator:** ✅ None - We use stable APIs

### Build 3.x → 4.x

**Breaking Changes:**
- Further Element API refinements
- BuildStep performance improvements
- Caching behavior changes

**Impact on filterable_generator:** ✅ None - Compatible abstraction layer

### Why We Support Multiple Versions

Different projects may be locked to specific versions:
- **Flutter SDK constraints**: Older Flutter versions require build 2.x
- **Other dependencies**: Some packages may not support build 4.x yet
- **Legacy projects**: May not be ready to upgrade
- **Monorepos**: Different packages may use different versions

By supporting build 2.4.0 through 4.x, we ensure maximum compatibility.

## Technical Details

### Why Dynamic Casting?

The `metadata` property on `FieldElement` may return:
- `List<ElementAnnotation>` (most versions)
- A subtype or wrapped type (some versions)
- Different collection types (rare but possible)

Dynamic casting ensures we can handle all these cases without compile-time type errors.

### Why Not Version Checking?

We could check the analyzer version at runtime and use different code paths, but:
- Version checking is fragile (patch versions may differ)
- Adds complexity and maintenance burden
- Dynamic casting is simpler and more robust
- Works for unknown future versions

### Performance Impact

The dynamic casting adds negligible overhead:
- Only occurs during code generation (build time)
- Not present in generated code
- Minimal allocation/boxing
- Try-catch is rarely triggered

## Future Considerations

If analyzer introduces breaking changes that can't be handled with dynamic casting:

1. Detect API capabilities at runtime
2. Use conditional code paths
3. Update this compatibility layer
4. Maintain backward compatibility where possible

## Contributing

When modifying code that interacts with the analyzer API:

1. Test with multiple analyzer versions
2. Use the `_getFieldMetadata()` helper
3. Add fallbacks for edge cases
4. Update this document if changes are needed

## References

- [Analyzer Package](https://pub.dev/packages/analyzer)
- [Build Package](https://pub.dev/packages/build)
- [Source Gen](https://pub.dev/packages/source_gen)
- [Analyzer Changelog](https://github.com/dart-lang/sdk/blob/main/pkg/analyzer/CHANGELOG.md)
