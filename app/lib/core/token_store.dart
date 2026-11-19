import 'dart:convert';
import 'dart:ffi';
import 'dart:io';

import 'package:ffi/ffi.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Token 安全存储：Windows 用 DPAPI 加密后落盘，Android 用 Keystore（AES/GCM）。
abstract class TokenStore {
  Future<String?> read();
  Future<void> write(String value);
  Future<void> delete();
}

TokenStore createTokenStore(SharedPreferences prefs) {
  if (!kIsWeb && Platform.isWindows) return _DpapiTokenStore(prefs);
  if (!kIsWeb && Platform.isAndroid) return _KeystoreTokenStore();
  return _PrefsTokenStore(prefs);
}

/// Android：原生 Keystore 加密，密文存在应用私有 SharedPreferences。
class _KeystoreTokenStore implements TokenStore {
  static const _channel = MethodChannel('liangpu/secure_token');

  @override
  Future<String?> read() => _channel.invokeMethod<String>('read');

  @override
  Future<void> write(String value) =>
      _channel.invokeMethod<void>('write', {'value': value});

  @override
  Future<void> delete() => _channel.invokeMethod<void>('delete');
}

/// Windows：CryptProtectData / CryptUnprotectData（DPAPI），Base64 后存 SharedPreferences。
class _DpapiTokenStore implements TokenStore {
  static const _kKey = 'lp_token_dpapi';
  final SharedPreferences prefs;

  _DpapiTokenStore(this.prefs);

  @override
  Future<String?> read() async {
    final stored = prefs.getString(_kKey);
    if (stored == null || stored.isEmpty) return null;
    try {
      return utf8.decode(_Dpapi.unprotect(base64Decode(stored)));
    } catch (_) {
      await prefs.remove(_kKey);
      return null;
    }
  }

  @override
  Future<void> write(String value) async {
    final encrypted = _Dpapi.protect(Uint8List.fromList(utf8.encode(value)));
    await prefs.setString(_kKey, base64Encode(encrypted));
  }

  @override
  Future<void> delete() => prefs.remove(_kKey);
}

/// 其他平台（测试/桌面调试）兜底，不做系统级加密。
class _PrefsTokenStore implements TokenStore {
  static const _kKey = 'lp_token_plain';
  final SharedPreferences prefs;

  _PrefsTokenStore(this.prefs);

  @override
  Future<String?> read() async => prefs.getString(_kKey);

  @override
  Future<void> write(String value) => prefs.setString(_kKey, value);

  @override
  Future<void> delete() => prefs.remove(_kKey);
}

final class _DataBlob extends Struct {
  @Uint32()
  external int cbData;
  external Pointer<Uint8> pbData;
}

typedef _CryptProtectC = Int32 Function(Pointer<_DataBlob>, Pointer<Utf16>,
    Pointer<_DataBlob>, Pointer<Void>, Pointer<Void>, Uint32, Pointer<_DataBlob>);
typedef _CryptProtectD = int Function(Pointer<_DataBlob>, Pointer<Utf16>,
    Pointer<_DataBlob>, Pointer<Void>, Pointer<Void>, int, Pointer<_DataBlob>);

typedef _CryptUnprotectC = Int32 Function(
    Pointer<_DataBlob>,
    Pointer<Pointer<Utf16>>,
    Pointer<_DataBlob>,
    Pointer<Void>,
    Pointer<Void>,
    Uint32,
    Pointer<_DataBlob>);
typedef _CryptUnprotectD = int Function(
    Pointer<_DataBlob>,
    Pointer<Pointer<Utf16>>,
    Pointer<_DataBlob>,
    Pointer<Void>,
    Pointer<Void>,
    int,
    Pointer<_DataBlob>);

typedef _LocalFreeC = IntPtr Function(IntPtr);
typedef _LocalFreeD = int Function(int);

class _Dpapi {
  static const _uiForbidden = 0x1;

  static final _protectFn = DynamicLibrary.open('crypt32.dll').lookupFunction<
      _CryptProtectC, _CryptProtectD>('CryptProtectData');
  static final _unprotectFn = DynamicLibrary.open('crypt32.dll').lookupFunction<
      _CryptUnprotectC, _CryptUnprotectD>('CryptUnprotectData');
  static final _localFreeFn = DynamicLibrary.open('kernel32.dll')
      .lookupFunction<_LocalFreeC, _LocalFreeD>('LocalFree');

  static Uint8List protect(Uint8List plain) {
    return _run(plain, (inBlob, outBlob) => _protectFn(
          inBlob,
          nullptr,
          nullptr,
          nullptr,
          nullptr,
          _uiForbidden,
          outBlob,
        ));
  }

  static Uint8List unprotect(Uint8List encrypted) {
    return _run(encrypted, (inBlob, outBlob) => _unprotectFn(
          inBlob,
          nullptr,
          nullptr,
          nullptr,
          nullptr,
          _uiForbidden,
          outBlob,
        ));
  }

  static Uint8List _run(
    Uint8List input,
    int Function(Pointer<_DataBlob>, Pointer<_DataBlob>) call,
  ) {
    final length = input.isEmpty ? 1 : input.length;
    final dataPtr = calloc<Uint8>(length);
    if (input.isNotEmpty) dataPtr.asTypedList(input.length).setAll(0, input);
    final inBlob = calloc<_DataBlob>();
    inBlob.ref.cbData = input.length;
    inBlob.ref.pbData = dataPtr;
    final outBlob = calloc<_DataBlob>();
    var outPtr = nullptr.cast<Uint8>();
    try {
      final ok = call(inBlob, outBlob);
      if (ok == 0) throw StateError('DPAPI 调用失败');
      outPtr = outBlob.ref.pbData;
      return Uint8List.fromList(outPtr.asTypedList(outBlob.ref.cbData));
    } finally {
      if (outPtr != nullptr) _localFreeFn(outPtr.address);
      calloc.free(inBlob);
      calloc.free(dataPtr);
      calloc.free(outBlob);
    }
  }
}
