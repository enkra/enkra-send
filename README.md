# Enkra Send

Enkra Send is a Flutter-based software product that allows users to easily and securely transfer files between their phone and computer. With end-to-end encryption technology, users can be sure that their personal and sensitive documents are kept safe and private.

## Features

- Easy file transfer between phone and computer
- End-to-end encryption for privacy and security
- Simple and intuitive user interface

To use Enkra Send on the web, visit [https://send.enkra.io](https://send.enkra.io) and enjoy the service.

## End to end encryption

Enkra Send employs the use of [HPKE](https://datatracker.ietf.org/doc/rfc9180/) and [XChacha20poly1305](https://docs.rs/chacha20poly1305/latest/chacha20poly1305/#xchacha20poly1305) to establish a secure file transmission channel. The cipher code is implemented entirely in Rust, a memory-safe language, to ensure that the implementation is secure and free from common memory-related vulnerabilities.

For auditor reviewing code, here are some specific files that you can focus on:

- All the cipher code located in `native/src/api.rs`
- The code that uses cipher located in `lib/wait_to_pair.dart` and `lib/paired.dart`:

## Getting Started with Development

If you would like to contribute to the development of Enkra Send, follow these steps:

1. Install the Flutter SDK according to the Flutter documentation.
2. Install the Rust according to the Rust langugage documentation.
3. `flutter pub get`
4. `flutter pub run build_runner build`
5. `./build_tools/build_web.sh`
6. `flutter build web --dart-define ENKRA_API_URL=https://api.enkra.io --dart-define SEND_APP_URL=https://send.enkra.io`
7. `./build_tools/patch_web.sh`

## License

Enkra Send is released under the [BSL 1.1](./LICENSE). The software is free to use for non-commercial purposes. After the change date, the software will be released under the GNU General Public License Version 2 ("GPLv2").
