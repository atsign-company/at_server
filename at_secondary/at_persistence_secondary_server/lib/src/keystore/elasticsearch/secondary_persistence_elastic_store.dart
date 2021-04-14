
import 'package:at_persistence_secondary_server/at_persistence_secondary_server.dart';
import 'package:at_persistence_secondary_server/src/keystore/elasticsearch/elastic_keystore.dart';
import 'package:at_persistence_secondary_server/src/keystore/elasticsearch/elastic_manager.dart';
import 'package:at_persistence_secondary_server/src/keystore/secondary_persistence_manager.dart';

class SecondaryPersistenceElasticStore implements SecondaryPersistenceStore {
  ElasticKeyStore _elasticKeyStore;
  ElasticPersistenceManager _elasticPersistenceManager;
  SecondaryKeyStoreManager _secondaryKeyStoreManager;
  String _atSign;

  SecondaryPersistenceElasticStore(String atSign) {
    _atSign = atSign;
    _init();
  }

  ElasticKeyStore getSecondaryKeyStore() {
    return this._elasticKeyStore;
  }

  PersistenceManager getPersistenceManager() {
    return this._elasticPersistenceManager;
  }

  SecondaryKeyStoreManager getSecondaryKeyStoreManager() {
    return this._secondaryKeyStoreManager;
  }

  void _init() {
    _elasticKeyStore = ElasticKeyStore(this._atSign);
    _elasticPersistenceManager = ElasticPersistenceManager(this._atSign);
    _elasticKeyStore.persistenceManager = _elasticPersistenceManager;
    _secondaryKeyStoreManager = SecondaryKeyStoreManager(this._atSign);
    _secondaryKeyStoreManager.keyStore = _elasticKeyStore;
  }
}
