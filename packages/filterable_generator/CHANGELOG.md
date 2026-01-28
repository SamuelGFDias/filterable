## 1.1.2

- Bug fixes

## 1.1.1

- Bug fixes

## 1.1.0

- Freezed support
- Improved null safety handling
- Enhanced generated code structure

## 1.0.0

### 🎉 Production Release

This is the first production-ready release with complete refactoring and stable API.

#### ✨ New Features
- **Enum Support**: Filter enums by value, index (int), or name (string)
- **Enhanced List Support**: Contains checks and length comparisons
- **Null Safety**: Proper handling of nullable fields
- **Metadata Generation**: Auto-generate field information for dynamic UIs

#### 🏗️ Code Architecture
- **Complete Refactoring**: Modular, maintainable code structure
- **Componentized Generation**: Separate methods for different generation tasks
  - `_extractFilterableFields()` - Field metadata extraction
  - `_generateBuildPredicate()` - Filter predicate generation
  - `_generateBuildSorter()` - Sorter generation
  - `_generateFilterableFieldsInfo()` - Metadata generation
- **Type-Specific Handlers**: Dedicated methods for enums, lists, and scalars
- **Clean Code**: Well-documented, easy to maintain

#### 📚 Documentation
- Comprehensive README with usage examples
- Detailed API documentation
- Architecture overview
- Advanced usage patterns

#### 🔧 Improvements
- **Wide Dependency Ranges**: Supports analyzer 5.2.0-9.x, build 2.4.0-4.x
- **Cross-Version Compatibility**: Works with both Element and Element2 APIs
- **Dynamic API Adaptation**: Automatically detects and uses available analyzer APIs
- **No Breaking Changes**: Updates to analyzer/build packages won't break your build
- Optimized generated code
- Better error messages
- Improved type safety

#### 🐛 Bug Fixes
- Fixed null-safety issues in generated code
- Corrected enum comparison logic
- Fixed list length comparisons

---

## 0.4.1

- Fixed file generation issues
- Bug fixes

## 0.4.0

- Compatibility with recent Flutter versions
- Dependency updates

## 0.3.1

- Updated analyzer dependency to ">=6.2.0 <8.0.0"

## 0.3.0

- Updated source_gen dependency

## 0.2.0

- Initial release with buildPredicate and buildSorter generation
- Support for custom comparison functions (customCompare)
- Support for field-specific operators