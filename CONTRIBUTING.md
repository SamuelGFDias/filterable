# Contributing to Filterable

First off, thank you for considering contributing to Filterable! It's people like you that make Filterable such a great tool.

## 🤝 Code of Conduct

This project and everyone participating in it is governed by a code of conduct. By participating, you are expected to uphold this code. Please be respectful and constructive in your interactions.

## 🐛 Reporting Bugs

Before creating bug reports, please check the [existing issues](https://github.com/SamuelGFDias/filterable/issues) to avoid duplicates.

### How to Submit a Bug Report

1. **Use a clear and descriptive title** for the issue
2. **Describe the exact steps to reproduce the problem**
3. **Provide specific examples** to demonstrate the steps
4. **Describe the behavior you observed** and what you expected
5. **Include code samples** and error messages
6. **Specify your environment:**
   - Dart/Flutter version
   - Package versions
   - Operating system

### Bug Report Template

```markdown
## Description
A clear description of the bug.

## Steps to Reproduce
1. Step one
2. Step two
3. ...

## Expected Behavior
What you expected to happen.

## Actual Behavior
What actually happened.

## Environment
- Dart/Flutter version:
- filterable_annotation version:
- filterable_generator version:
- OS:

## Code Sample
```dart
// Your code here
```

## Error Output
```
Error message here
```
```

## 💡 Suggesting Enhancements

Enhancement suggestions are tracked as [GitHub issues](https://github.com/SamuelGFDias/filterable/issues).

### How to Submit an Enhancement Suggestion

1. **Use a clear and descriptive title**
2. **Provide a detailed description** of the suggested enhancement
3. **Explain why this enhancement would be useful**
4. **Provide code examples** if applicable
5. **List any similar features** in other tools/packages

## 🔧 Pull Requests

### Getting Started

1. Fork the repository
2. Clone your fork: `git clone https://github.com/YOUR-USERNAME/filterable.git`
3. Create a branch: `git checkout -b feature/my-feature`
4. Make your changes
5. Test your changes
6. Commit your changes: `git commit -m 'Add some feature'`
7. Push to the branch: `git push origin feature/my-feature`
8. Open a Pull Request

### Development Setup

```bash
# Clone the repository
git clone https://github.com/SamuelGFDias/filterable.git
cd filterable

# Install dependencies for all packages
cd packages/filterable_annotation
flutter pub get
cd ../filterable_generator
flutter pub get
cd ../../example
flutter pub get
cd ..
```

### Running Tests

```bash
# Test annotation package
cd packages/filterable_annotation
flutter test

# Test generator package
cd ../filterable_generator
dart test

# Test example
cd ../../example
flutter test
```

### Code Style

- Follow the [Dart Style Guide](https://dart.dev/guides/language/effective-dart/style)
- Use `dart format` to format your code
- Run `dart analyze` to check for issues
- Add comments for complex logic
- Keep functions small and focused

### Code Generation

When modifying the generator:

```bash
cd example
dart run build_runner build --delete-conflicting-outputs
```

### Commit Messages

- Use the present tense ("Add feature" not "Added feature")
- Use the imperative mood ("Move cursor to..." not "Moves cursor to...")
- Limit the first line to 72 characters or less
- Reference issues and pull requests liberally after the first line

Examples:
```
Add enum filtering by index and name

- Support filtering enums by int index
- Support filtering enums by string name
- Add tests for new functionality
- Update documentation

Closes #123
```

### Pull Request Process

1. **Update documentation** for any new features
2. **Add tests** for new functionality
3. **Update the CHANGELOG.md** with your changes
4. **Ensure all tests pass**
5. **Follow the code style guidelines**
6. **Write a clear PR description** explaining:
   - What changes you made
   - Why you made them
   - How to test them

### Pull Request Template

```markdown
## Description
A clear description of what this PR does.

## Type of Change
- [ ] Bug fix
- [ ] New feature
- [ ] Breaking change
- [ ] Documentation update

## Changes Made
- Change 1
- Change 2
- ...

## Testing
Describe how you tested your changes.

## Checklist
- [ ] My code follows the style guidelines
- [ ] I have commented my code where necessary
- [ ] I have updated the documentation
- [ ] I have added tests that prove my fix/feature works
- [ ] All tests pass locally
- [ ] I have updated the CHANGELOG.md
```

## 📝 Documentation

- Update README files when adding new features
- Add dartdoc comments to public APIs
- Include code examples in documentation
- Keep documentation clear and concise

## 🧪 Testing

- Write tests for new features
- Ensure existing tests still pass
- Test edge cases and error conditions
- Test on multiple platforms when possible

## 📦 Package Structure

```
filterable/
├── packages/
│   ├── filterable_annotation/    # Runtime annotations
│   └── filterable_generator/     # Code generator
├── example/                       # Example app
├── README.md                      # Main documentation
├── CHANGELOG.md                   # Version history
└── CONTRIBUTING.md               # This file
```

## 🎯 Areas for Contribution

We welcome contributions in these areas:

- **New comparators**: Add support for new comparison operators
- **Type support**: Extend support for more Dart types
- **Performance**: Optimize generated code
- **Documentation**: Improve examples and guides
- **Tests**: Increase test coverage
- **Bug fixes**: Fix reported issues
- **Examples**: Add more usage examples

## 📮 Questions?

Feel free to open an issue for:
- Questions about the codebase
- Discussion about features
- Help with contributions

## 🙏 Recognition

Contributors will be recognized in:
- Release notes
- README acknowledgments
- GitHub contributors page

Thank you for contributing to Filterable! 🎉
