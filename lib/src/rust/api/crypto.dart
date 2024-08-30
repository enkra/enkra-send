// This file is automatically generated, so please do not edit it.
// Generated by `flutter_rust_bridge`@ 2.3.0.

// ignore_for_file: invalid_use_of_internal_member, unused_import, unnecessary_import

import '../frb_generated.dart';
import 'package:flutter_rust_bridge/flutter_rust_bridge_for_generated.dart';

// These functions are ignored because they are not marked as `pub`: `new`, `read_public_key`

// Rust type: RustOpaqueMoi<EnkraSecureChannelKey>
abstract class EnkraSecureChannelKey implements RustOpaqueInterface {}

// Rust type: RustOpaqueMoi<Mutex < StdRng >>
abstract class MutexStdRng implements RustOpaqueInterface {}

// Rust type: RustOpaqueMoi<XChaCha20Poly1305>
abstract class XChaCha20Poly1305 implements RustOpaqueInterface {}

class AeadCipher {
  final XChaCha20Poly1305 inner;

  const AeadCipher({
    required this.inner,
  });

  Future<Uint8List> decrypt({required List<int> ct, required List<int> aad}) =>
      RustLib.instance.api
          .crateApiCryptoAeadCipherDecrypt(that: this, ct: ct, aad: aad);

  Future<Uint8List> encrypt({required List<int> pt, required List<int> aad}) =>
      RustLib.instance.api
          .crateApiCryptoAeadCipherEncrypt(that: this, pt: pt, aad: aad);

  @override
  int get hashCode => inner.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AeadCipher &&
          runtimeType == other.runtimeType &&
          inner == other.inner;
}

class EncappedKey {
  final Uint8List encapsulatedKey;
  final AeadCipher sharedSecret;

  const EncappedKey({
    required this.encapsulatedKey,
    required this.sharedSecret,
  });

  @override
  int get hashCode => encapsulatedKey.hashCode ^ sharedSecret.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is EncappedKey &&
          runtimeType == other.runtimeType &&
          encapsulatedKey == other.encapsulatedKey &&
          sharedSecret == other.sharedSecret;
}

class SecureChannelCipher {
  final EnkraSecureChannelKey key;
  final MutexStdRng csprng;

  const SecureChannelCipher({
    required this.key,
    required this.csprng,
  });

  Future<EncappedKey> encapKey({required List<int> public}) => RustLib
      .instance.api
      .crateApiCryptoSecureChannelCipherEncapKey(that: this, public: public);

  static Future<SecureChannelCipher> newRandom() =>
      RustLib.instance.api.crateApiCryptoSecureChannelCipherNewRandom();

  Future<Uint8List> public() =>
      RustLib.instance.api.crateApiCryptoSecureChannelCipherPublic(
        that: this,
      );

  Future<AeadCipher> sharedSecret({required List<int> encapsulatedKey}) =>
      RustLib.instance.api.crateApiCryptoSecureChannelCipherSharedSecret(
          that: this, encapsulatedKey: encapsulatedKey);

  @override
  int get hashCode => key.hashCode ^ csprng.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SecureChannelCipher &&
          runtimeType == other.runtimeType &&
          key == other.key &&
          csprng == other.csprng;
}
