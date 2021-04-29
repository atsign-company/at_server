import 'dart:collection';

import 'package:at_commons/at_commons.dart';
import 'package:at_persistence_secondary_server/at_persistence_secondary_server.dart';
import 'package:at_persistence_spec/src/keystore/secondary_keystore.dart';
import 'package:at_secondary/src/verb/handler/abstract_verb_handler.dart';
import 'package:at_server_spec/src/connection/inbound_connection.dart';
import 'package:at_server_spec/at_server_spec.dart';
import 'package:at_server_spec/at_verb_spec.dart';
import 'package:uuid/uuid.dart';
import '';

class SearchVerbHandler extends AbstractVerbHandler {
  static Search search = Search();

  SearchVerbHandler(SecondaryKeyStore keyStore) : super(keyStore);

  @override
  bool accept(String command) {
    return command.startsWith('search');
  }

  @override
  Verb getVerb() {
    return search;
  }

  @override
  Future<void> processVerb(
      Response response,
      HashMap<String, String> verbParams,
      InboundConnection atConnection) async {

    var keywords = verbParams['keywords'].split(RegExp('[ ,]'));
    response.data = (await (keyStore as IndexKeyStore).search(keywords)).toString();
  }
}