import 'dart:io';

import 'package:at_secondary/src/connection/inbound/inbound_connection_metadata.dart';
import 'package:at_server_spec/at_server_spec.dart';

/// A dummy implementation of [InboundConnection] class which returns a dummy inbound connection.
class DummyInboundConnection implements InboundConnection {
  static final DummyInboundConnection _singleton =
      DummyInboundConnection._internal();

  factory DummyInboundConnection.getInstance() {
    return _singleton;
  }

  DummyInboundConnection._internal();

  @override
  void acceptRequests(Function(String p1, InboundConnection p2) callback,
      Function(List<int>, InboundConnection) streamCallback) {}

  @override
  Future<void> close() async {}

  @override
  bool equals(InboundConnection connection) {
    if (connection is DummyInboundConnection) {
      return true;
    }
    return false;
  }

  @override
  AtConnectionMetaData getMetaData() {
    return InboundConnectionMetadata()..fromAtSign = null;
  }

  @override
  Socket getSocket() {
    throw ('not implemented');
  }

  @override
  bool isInValid() {
    return false;
  }

  @override
  void write(String data) {}

  @override
  bool? isMonitor;

  @override
  String? initiatedBy;

  bool isStream = false;

  @override
  Socket? receiverSocket;
}
