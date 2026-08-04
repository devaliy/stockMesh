import 'package:flutter_riverpod/flutter_riverpod.dart';

/// What the app-bar sync pill shows (design direction §8.2):
/// LIVE green / SYNCING amber / OFFLINE gray with pending count.
enum SyncPillState { live, syncing, offline }

/// Current pill state. The Hub is always LIVE (it *is* the authority);
/// clients are driven by the sync client's connection state machine
/// (`sync/client/sync_client.dart`) once networking is up.
final syncPillProvider =
    StateProvider<SyncPillState>((ref) => SyncPillState.offline);

/// Number of devices currently connected to the Hub — shown in the Hub's
/// pill and the devices screen. Updated by the hub server.
final connectedDeviceCountProvider = StateProvider<int>((ref) => 0);

/// Which registered devices hold a live session right now (Hub only) —
/// drives the online dot on the Devices screen.
final onlineDevicesProvider = StateProvider<Set<String>>((ref) => const {});
