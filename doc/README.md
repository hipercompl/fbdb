# *fbdb* Documentation

## Naming conventions
- **fbdb** is the name of the library (package), as published on pub.dev - it should be added to the pubspec.yaml of a Dart / Flutter project as a dependency,
- **FbDb** is the high-level API of the library, and, at the same time, the name of the main class of this API,
- **FbClient** is the low-level API of the library, and, at the same time, the name of the main class of this API.


## Available documentation
- [*fbdb* Architecture Overview](https://github.com/hipercompl/fbdb/blob/main/doc/fbdb_arch.md)  
A recommended read to gain a general understaning of the architecture and the inner working of the library.
- [FbDb Programmer's Guide](https://github.com/hipercompl/fbdb/blob/main/doc/fbdb_guide.md)  
A guide for the programmers, who intend to use the high-level, asynchronous API of *fbdb*. Unless a project has some very specific needs, this is the API intended for general use and this guide is a highly recommended read.
- [FbDb Tutorial](https://github.com/hipercompl/fbdb/blob/main/doc/fbdb_tutorial.md)  
A tutorial, illustrating (by building a simple CLI application) various tasks related to interaction with a Firebird database.
- [FbClient Programmer's Guide](https://github.com/hipercompl/fbdb/blob/main/doc/fbclient_guide.md)  
The guide for the low-level API of *fbdb*. A recommended read fo all who intend to use the Dart bindings of the native Firebird client interfaces directly.
