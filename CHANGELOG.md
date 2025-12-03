# Changelog

All notable changes to the Filterable project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.0.0] - 2024-12-03

### 🎉 First Production Release

This is the first production-ready release of the Filterable package ecosystem.

### Added

#### filterable_annotation 1.0.0
- Complete API documentation with examples
- `toString()`, `operator==`, and `hashCode` for `FilterCriteria` and `SortCriteria`
- Comprehensive README with all features documented
- Production-ready package metadata

#### filterable_generator 1.0.0
- **Enum Support**: Filter enums by value, index (int), or name (string)
- **Enhanced List Support**: Contains checks and length comparisons
- **Null Safety**: Proper handling of nullable fields
- **Metadata Generation**: Auto-generate field information for dynamic UIs
- Complete code refactoring with modular architecture
- Comprehensive documentation

#### Repository
- Main README with complete project overview
- Contribution guidelines
- Example app with real-world usage
- Clean architecture documentation

### Changed

#### filterable_generator
- **Complete Code Refactoring**:
  - Componentized generation methods for better maintainability
  - Type-specific handlers (enums, lists, scalars)
  - Clean, well-documented code structure
- **Wider Dependency Ranges**: Better compatibility with other packages
- **Improved Type Safety**: Enhanced compile-time validation

### Fixed

#### filterable_generator
- Null-safety issues in generated code
- Enum comparison logic
- List length comparison operators

---

## [0.4.1] - 2024-03-31

### Fixed
- File generation issues in filterable_generator

## [0.4.0] - 2024-03-26

### Changed
- Updated compatibility with recent Flutter versions

## [0.3.1] - 2024-02-15

### Changed
- Updated analyzer dependency range in filterable_generator

## [0.3.0] - 2024-01-20

### Changed
- Updated source_gen dependency in filterable_generator

## [0.2.0] - 2023-12-10

### Added
- `FilterableFieldInfo` for metadata support
- Dynamic UI generation capabilities

## [0.1.0] - 2023-11-01

### Added
- Initial release of filterable_annotation
- Initial release of filterable_generator
- `@Filterable` annotation for marking classes
- `@FilterableField` annotation for marking fields
- Custom comparators support
- Custom comparison functions support
- Basic filter and sort generation

[1.0.0]: https://github.com/SamuelGFDias/filterable/compare/v0.4.1...v1.0.0
[0.4.1]: https://github.com/SamuelGFDias/filterable/compare/v0.4.0...v0.4.1
[0.4.0]: https://github.com/SamuelGFDias/filterable/compare/v0.3.1...v0.4.0
[0.3.1]: https://github.com/SamuelGFDias/filterable/compare/v0.3.0...v0.3.1
[0.3.0]: https://github.com/SamuelGFDias/filterable/compare/v0.2.0...v0.3.0
[0.2.0]: https://github.com/SamuelGFDias/filterable/compare/v0.1.0...v0.2.0
[0.1.0]: https://github.com/SamuelGFDias/filterable/releases/tag/v0.1.0
