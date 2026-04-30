// lib/services/network_service.dart
//
// Best-effort detection of a usable LAN IP for the Local AI Server.
//
// Where this helps: on desktop (Windows / macOS / Linux), the embedded
// server binds to 127.0.0.1 by default. Auto-detecting the host's LAN
// IP lets the same `ApiClient` instance produce a URL that:
//   - still resolves to the local server (any LAN IP loops back to the
//     host on most OSes), AND
//   - is the URL the user should type on a phone if they later switch
//     `lanMode` on.
//
// Where this does NOT help — explicitly returns null:
//   - Web (no dart:io NetworkInterface API).
//   - Real Android / iOS devices: the phone's own Wi-Fi IP isn't the
//     server's IP. Use the manual IP dialog instead.

import 'dart:io';

import 'package:flutter/foundation.dart';

class NetworkService {
  /// Returns a probable LAN IPv4 of the **host this app is running on**,
  /// or null if we can't safely determine one.
  ///
  /// Prefers RFC 1918 private addresses (192.168/16, 10/8, 172.16/12)
  /// and skips obvious virtual adapters (Docker / VirtualBox / vEthernet
  /// / WSL / VPN tunnels).
  ///
  /// Pure read; no side effects.
  static Future<String?> getLocalIp() async {
    // Web has no NetworkInterface; bail before throwing.
    if (kIsWeb) return null;

    // On Android / iOS the "host" is the phone, and its own Wi-Fi IP
    // isn't useful for reaching a desktop server. Caller should use the
    // manual IP dialog.
    if (defaultTargetPlatform == TargetPlatform.android ||
        defaultTargetPlatform == TargetPlatform.iOS) {
      return null;
    }

    try {
      final ifaces = await NetworkInterface.list(
        includeLinkLocal: false,
        type: InternetAddressType.IPv4,
      );

      // 1st pass: prefer a real-looking adapter on a private subnet.
      for (final iface in ifaces) {
        if (_isLikelyVirtual(iface.name)) continue;
        for (final addr in iface.addresses) {
          if (addr.isLoopback) continue;
          if (_isPrivateIp(addr.address)) return addr.address;
        }
      }

      // 2nd pass: any non-loopback IPv4 on a non-virtual adapter.
      for (final iface in ifaces) {
        if (_isLikelyVirtual(iface.name)) continue;
        for (final addr in iface.addresses) {
          if (!addr.isLoopback) return addr.address;
        }
      }

      return null;
    } catch (_) {
      return null;
    }
  }

  /// True if [ip] is in an RFC 1918 private range (192.168/16, 10/8,
  /// 172.16/12). Defensively guards against malformed inputs — neither
  /// `'172.'` nor `'172'` nor `''` will throw.
  static bool _isPrivateIp(String ip) {
    if (ip.startsWith('192.168.') || ip.startsWith('10.')) return true;
    if (!ip.startsWith('172.')) return false;
    final parts = ip.split('.');
    if (parts.length < 2) return false;
    final second = int.tryParse(parts[1]) ?? 0;
    return second >= 16 && second <= 31;
  }

  /// Heuristic blocklist for adapters that almost never give the IP a
  /// phone on the same Wi-Fi can reach. Matches typical Windows naming.
  static bool _isLikelyVirtual(String ifaceName) {
    final n = ifaceName.toLowerCase();
    return n.contains('vethernet') ||
        n.contains('virtualbox') ||
        n.contains('vmware') ||
        n.contains('hyper-v') ||
        n.contains('docker') ||
        n.contains('wsl') ||
        n.contains('tailscale') ||
        n.contains('zerotier') ||
        n.contains('tun') ||
        n.contains('tap');
  }
}
