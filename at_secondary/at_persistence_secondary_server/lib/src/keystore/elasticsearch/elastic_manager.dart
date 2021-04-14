import 'package:at_persistence_secondary_server/at_persistence_secondary_server.dart';
import 'package:at_persistence_secondary_server/src/keystore/secondary_persistence_manager.dart';
import 'package:at_utils/at_logger.dart';
import 'package:cron/cron.dart';
import 'package:elastic_client/elastic_client.dart';

class ElasticPersistenceManager implements PersistenceManager {
  final bool _debug = false;

  var _atSign;

  ElasticPersistenceManager(this._atSign);

  final logger = AtSignLogger('ElasticPersistenceManager');
  var transport;
  var client;

  @override
  Future<bool> init(String atSign, {String storagePath}) async {
    var success = false;
    try {
      transport = HttpTransport(url: 'http://localhost:9200/');
      client = Client(transport);
    } on Exception catch (e) {
      logger.severe('AtPersistence.init exception: ' + e.toString());
      throw DataStoreException(
          'Exception initializing secondary keystore manager: ${e.toString()}');
    }
    return success;
  }

  //TODO change into to Duration and construct cron string dynamically
  void scheduleKeyExpireTask(int runFrequencyMins) {
    logger.finest('scheduleKeyExpireTask starting cron job.');
    var cron = Cron();
    cron.schedule(Schedule.parse('*/${runFrequencyMins} * * * *'), () async {
      var elasticKeyStore = SecondaryPersistenceStoreFactory.getInstance()
          .getSecondaryPersistenceStore(this._atSign)
          .getSecondaryKeyStore();
      await elasticKeyStore.deleteExpiredKeys();
    });
  }

  // Closes the secondary keystore.
  Future<void> close() async {
    await transport.close();
  }

  @override
  Future openVault(String atsign, {List<int> hiveSecret}) {
    // Not applicable
    return null;
  }
}