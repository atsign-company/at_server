import 'package:at_persistence_secondary_server/at_persistence_secondary_server.dart';
import 'package:at_persistence_secondary_server/src/log/accesslog/access_entry.dart';
import 'package:at_persistence_secondary_server/src/log/accesslog/access_log_keystore.dart';
import 'package:hive/hive.dart';
import 'package:at_utils/at_logger.dart';

/// Class to main access logs on the secondary server for from, cram, pol, lookup and plookup verbs
class AtAccessLog implements AtLogType {
  var logger = AtSignLogger('AtAccessLog');

  late var _accessLogKeyStore;

  AtAccessLog(AccessLogKeyStore keyStore) {
    _accessLogKeyStore = keyStore;
  }

  ///Creates a new entry with fromAtSign, verbName and optional parameter lookupKey for lookup and plookup verbs.
  ///@param fromAtSign : The another user atsign
  ///@param verbName : The verb performed by the atsign user
  ///@param lookupKey : The optional parameter to hold lookup key when performing lookup or plookup verb.
  Future<int?> insert(String fromAtSign, String verbName,
      {String? lookupKey}) async {
    var result;
    var entry = AccessLogEntry(fromAtSign, DateTime.now(), verbName, lookupKey);
    try {
      result = await _accessLogKeyStore.add(entry);
    } on Exception catch (e) {
      throw DataStoreException(
          'Exception adding to access log:${e.toString()}');
    } on HiveError catch (e) {
      throw DataStoreException(
          'Hive error adding to access log:${e.toString()}');
    }
    return result;
  }

  ///The functions returns the top [length] visited atSign's.
  ///@param - length : The maximum number of atsign's to return
  ///@return Map : Returns a key value pair. Key is the atsign and value is the count of number of times the atsign is looked at.
  Map? mostVisitedAtSigns(int length) {
    return _accessLogKeyStore.mostVisitedAtSigns(length);
  }

  ///The functions returns the top [length] visited atKey's.
  ///@param length : The recent number of keys to fetch
  ///@return Map : Returns a key value pair. Key is the atsign key looked up and
  ///value is number of times the key is looked up.
  Map? mostVisitedKeys(int length) {
    return _accessLogKeyStore.mostVisitedKeys(length);
  }

  /// Returns the list of expired keys.
  /// @param expiryInDays - The count of days after which the keys expires
  /// @return List<dynamic> - The list of expired keys.
  @override
  List<dynamic> getExpired(int expiryInDays) {
    return _accessLogKeyStore.getExpired(expiryInDays);
  }

  @override
  void delete(expiredKeys) {
    _accessLogKeyStore.delete(expiredKeys);
  }

  @override
  int entriesCount() {
    return _accessLogKeyStore.entriesCount();
  }

  @override
  List getFirstNEntries(int N) {
    return _accessLogKeyStore.getFirstNEntries(N);
  }

  @override
  int getSize() {
    return _accessLogKeyStore.getSize();
  }

  ///Closes the [accessLogKeyStore] instance.
  void close() {
    _accessLogKeyStore.close();
  }
}
