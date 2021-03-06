# How to create a taped-package

Suppose there's a package named <kbd>sample</kbd> that contains some types you want to make serializable with tape and publish the adapters for others to use.

First, check if a <kbd>sample_taped</kbd> package already exists.
If it does, just use it. If it doesn't contain the type you want to serialize, consider opening a pull request.

If no <kbd>sample_taped</kbd> package exists, it's time to create your own!  
To do that, [open an issue](https://github.com/marcelgarus/taped/issues/new?template=1-taped-package.md) for the new package.
[@marcelgarus](https://github.com/marcelgarus) will try to answer you soon-ish and add ids in the [holy table of type ids](table_of_type_ids.md).

Then, create a new project using

```bash
flutter create --template=package sample_taped
```

After that command ran successfully, add <kbd>tape</kbd> and <kbd>tapegen</kbd> in your `pubspec.yaml`:

```dart
dependencies:
  tape:

dev_dependencies:
  tapegen:
```

Note that you don't need the <kbd>build_runner</kbd>, because you won't be generating adapters automatically.

Navigate into the project folder and generate the taped-package boilerplate:

```bash
cd sample_taped
pub run tapegen init --package // TODO: make this work
```

<details>
<summary>If you can't use tapegen init, here's how to do it manually.</summary>

Change the `pubspec.yaml`'s `description' to something like

```yaml
description: 'A package containing tape adapters for sample. Intended to be '
    'used with sample and tape.
```

Replace the `README.md` with something like the following:

```md
This package offers `TapeAdapter`s for using the following classes from [<kbd>sample</kbd>](https://pub.dev/packages/sample) with [<kbd>tape</kbd>](https://pub.dev/packages/tape):

* `Fruit`
* `OtherType`
```

Consider adding the MIT `LICENSE`:

```txt
Copyright 2020 Your name

Permission is hereby granted, free of charge, to any person obtaining a copy of
this software and associated documentation files (the "Software"), to deal in
the Software without restriction, including without limitation the rights to
use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of
the Software, and to permit persons to whom the Software is furnished to do so,
subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS
FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR
COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER
IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN
CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
```

Your `lib/TODO_taped.dart` should look like this:

```dart
library sample_taped;

import 'package:sample/sample.dart';
import 'package:tape/package.dart';

extension FlutterTaped on TapeApi {
  void initializeMyPackage() {
    registerAdapters({
      // Only use ids that @marcelgarus registered for you.
      -100: AdapterForFruit(),
      -101: AdapterForOtherType(),
    });
  }
}

// Your adapters go here...
```

Also, consider adding tests in `test/sample_taped_test.dart`:

```dart
extension TestableAdapter<T> on TapeAdapter<T> {
  T roundtripValue(T value) => fromBlock(toBlock(value));
  void expectSameValueAfterRoundtrip(T value) =>
      expect(roundtripValue(value), equals(value));

  void expectEncoding(T value, Block block) =>
      expect(toBlock(value), equals(block));
  void expectDecoding(Block block, T value) =>
      expect(fromBlock(block), equals(value));
}

void main() {
  group('AdapterForColor', () {
    test('encoding works', () {
      AdapterForColor()
        ..expectSameValueAfterRoundtrip(Colors.blue[500])
        ..expectSameValueAfterRoundtrip(Colors.red.withAlpha(200))
        ..expectSameValueAfterRoundtrip(Colors.pink[300])
        ..expectSameValueAfterRoundtrip(Colors.teal.withOpacity(0.4));
    });

    test('produces expected encoding', () {
      AdapterForColor()
        ..expectEncoding(Colors.blue, Uint32Block(4280391411))
        ..expectEncoding(Colors.teal.withOpacity(0.2), Uint32Block(855676552));
    });

    test('is compatible with all versions', () {
      AdapterForColor()
        ..expectDecoding(Uint32Block(4280391411), Colors.blue[500])
        ..expectDecoding(Uint32Block(855676552), Colors.teal.withOpacity(0.2));
    });
  });
}
```
</details>

Now, it's time to actually write adapters!
For more information about what role adapters play in the larger picture, it definitely makes sense to have a look at the [encoding pipeline](the_life_of_a_fruit.md).
Also, you might want to check out some adapters other people have written.

<!--
TODO: Insert more text about thinking about future compatibility etc.
Or insert a link to the custom adapter guide.
-->


```bash
pub run tapegen init --package
```

It's time to wait! After your PR has been merged, just insert the type ids in the `sample_tape.dart` file of your package.

Then, publish your package using `pub lish`.

Finally, close the issue.
