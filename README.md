# Control: State Management for Flutter

[![Pub](https://img.shields.io/pub/v/control.svg)](https://pub.dev/packages/control)
[![Actions Status](https://github.com/PlugFox/control/actions/workflows/checkout.yml/badge.svg)](https://github.com/PlugFox/control/actions)
[![Coverage](https://codecov.io/gh/PlugFox/control/branch/master/graph/badge.svg)](https://codecov.io/gh/PlugFox/control)
[![License: MIT](https://img.shields.io/badge/license-MIT-purple.svg)](https://opensource.org/licenses/MIT)
[![Linter](https://img.shields.io/badge/style-linter-40c4ff.svg)](https://pub.dev/packages/linter)
[![GitHub stars](https://img.shields.io/github/stars/plugfox/control?style=social)](https://github.com/plugfox/control/)

---

## Installation

Add the following dependency to your `pubspec.yaml` file:

```yaml
dependencies:
  control: <version>
```

## Example

```dart
/// Counter state for [CounterController]
typedef CounterState = ({int count, bool idle});

/// Counter controller
final class CounterController extends StateController<CounterState>
    with SequentialControllerHandler {
  CounterController({CounterState? initialState})
      : super(initialState: initialState ?? (idle: true, count: 0));

  void add(int value) => handle(() async {
        setState((idle: false, count: state.count));
        await Future<void>.delayed(const Duration(milliseconds: 1500));
        setState((idle: true, count: state.count + value));
      });

  void subtract(int value) => handle(() async {
        setState((idle: false, count: state.count));
        await Future<void>.delayed(const Duration(milliseconds: 1500));
        setState((idle: true, count: state.count - value));
      });
}
```

## Coverage

[![](https://codecov.io/gh/PlugFox/control/branch/master/graphs/sunburst.svg)](https://codecov.io/gh/PlugFox/control/branch/master)

## Changelog

Refer to the [Changelog](https://github.com/PlugFox/control/blob/master/CHANGELOG.md) to get all release notes.

## Maintainers

- [Matiunin Mikhail aka Plague Fox](https://plugfox.dev)

## Funding

If you want to support the development of our library, there are several ways you can do it:

- [Buy me a coffee](https://www.buymeacoffee.com/plugfox)
- [Support on Patreon](https://www.patreon.com/plugfox)
- [Subscribe through Boosty](https://boosty.to/plugfox)

We appreciate any form of support, whether it's a financial donation or just a star on GitHub. It helps us to continue developing and improving our library. Thank you for your support!

## License

[MIT](https://opensource.org/licenses/MIT)
