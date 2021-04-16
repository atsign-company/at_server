import 'dart:convert';
import 'package:at_commons/at_commons.dart';
import 'package:at_persistence_secondary_server/at_persistence_secondary_server.dart';
import 'package:at_persistence_secondary_server/src/keystore/elasticsearch/elastic_manager.dart';
import 'package:at_persistence_secondary_server/src/keystore/hive/hive_keystore_helper.dart';
import 'package:at_persistence_secondary_server/src/utils/object_util.dart';
import 'package:at_utils/at_logger.dart';
import 'package:elastic_client/elastic_client.dart';
import 'package:utf7/utf7.dart';

class ElasticKeyStore implements SecondaryKeyStore<String, AtData, AtMetaData> {
  final logger = AtSignLogger('ElasticKeyStore');
  var _atSign;
  ElasticPersistenceManager persistenceManager;
  var keyStoreHelper = HiveKeyStoreHelper.getInstance();
  var _commitLog;

  ElasticKeyStore(this._atSign);

  set commitLog(value) {
    _commitLog = value;
  }

  @override
  Future create(String key, AtData value,
      {int time_to_live,
      int time_to_born,
      int time_to_refresh,
      bool isCascade,
      bool isBinary,
      bool isEncrypted,
      String dataSignature}) async {
    var result;
    var commitOp;
    var elastic_key = keyStoreHelper.prepareKey(key);
    var elastic_data = keyStoreHelper.prepareDataForCreate(value,
        ttl: time_to_live,
        ttb: time_to_born,
        ttr: time_to_refresh,
        isCascade: isCascade,
        isBinary: isBinary,
        isEncrypted: isEncrypted,
        dataSignature: dataSignature);
    // Default commitOp to Update.
    commitOp = CommitOp.UPDATE;

    // Setting metadata defined in values
    if (value != null && value.metaData != null) {
      time_to_live ??= value.metaData.ttl;
      time_to_born ??= value.metaData.ttb;
      time_to_refresh ??= value.metaData.ttr;
      isCascade ??= value.metaData.isCascade;
      isBinary ??= value.metaData.isBinary;
      isEncrypted ??= value.metaData.isEncrypted;
      dataSignature ??= value.metaData.dataSignature;
    }

    // If metadata is set, set commitOp to Update all
    if (ObjectsUtil.isAnyNotNull(
        a1: time_to_live,
        a2: time_to_born,
        a3: time_to_refresh,
        a4: isCascade,
        a5: isBinary,
        a6: isEncrypted)) {
      commitOp = CommitOp.UPDATE_ALL;
    }

    try {
      var value =
          (elastic_data != null) ? json.encode(elastic_data.toJson()) : null;
      await persistenceManager.client.updateDoc(
        index: 'my_index',
        type: 'my_type',
        id: elastic_key,
        doc: value,
      );
      await persistenceManager.client.flushIndex(index: 'my_index');
      result = await _commitLog.commit(elastic_key, commitOp);
      return result;
    } on Exception catch (exception) {
      logger.severe('ElasticKeystore create exception: $exception');
      throw DataStoreException('exception in create: ${exception.toString()}');
    }
  }

  @override
  Future<bool> deleteExpiredKeys() async {
    var result = true;
    try {
      var expiredKeys = <String>[];
      logger.info('type : ${expiredKeys.runtimeType}');
      if (expiredKeys.isNotEmpty) {
        expiredKeys.forEach((element) {
          remove(element);
        });
        result = true;
      }
    } on Exception catch (e) {
      result = false;
      logger.severe('Exception in deleteExpired keys: ${e.toString()}');
      throw DataStoreException(
          'exception in deleteExpiredKeys: ${e.toString()}');
    }
    return result;
  }

  @override
  Future<AtData> get(String key) async {
    var value = AtData();
    try {
      var elastic_key = keyStoreHelper.prepareKey(key);
      var conditions = [];
        conditions.add(Query.match('id', elastic_key));
      var query = Query.bool(should: conditions);
      var result = await persistenceManager.client.search('my_index', 'my_type', query, source: true);
      // var result = await persistenceManager.client
      //     .search('my_index', 'my_type', query: Query.term('id', [elastic_key]) );
      if (result != null) {
        value = value.fromJson(json.decode(result));
      }
    } on Exception catch (exception) {
      logger.severe('ElasticKeystore get exception: $exception');
      throw DataStoreException('exception in get: ${exception.toString()}');
    }
    return value;
  }

  @override
  Future<List<String>> getExpiredKeys() async {
    var keys = <String>[];
    return keys;
  }

  @override
  Future<List<String>> getKeys({String regex}) async {
    var keys = <String>[];
    var encodedKeys;

    try {
      if (persistenceManager.client != null) {
        keys = keys = persistenceManager.client.search(
            index: 'my_index',
            type: 'my_type',
            query: {
              "query": {"match_all": {}},
              "size": 30000,
              "fields": ['id']
            },
            source: true);
        ;
        // If regular expression is not null or not empty, filter keys on regular expression.
        if (regex != null && regex.isNotEmpty) {
          encodedKeys = keys
              .where((element) => Utf7.decode(element).contains(RegExp(regex)));
        } else {
          encodedKeys = keys;
        }
        //encodedKeys?.forEach((key) => keys.add(Utf7.decode(key)));
      }
    } on FormatException catch (exception) {
      logger.severe('Invalid regular expression : ${regex}');
      throw InvalidSyntaxException('Invalid syntax ${exception.toString()}');
    } on Exception catch (exception) {
      logger
          .severe('ElasticKeystore getKeys exception: ${exception.toString()}');
      throw DataStoreException('exception in getKeys: ${exception.toString()}');
    }
    return encodedKeys;
  }

  @override
  Future<AtMetaData> getMeta(String key) {
    // TODO: implement getMeta
    throw UnimplementedError();
  }

  @override
  Future put(String key, AtData value,
      {int time_to_live,
      int time_to_born,
      int time_to_refresh,
      bool isCascade,
      bool isBinary,
      bool isEncrypted,
      String dataSignature}) async {
    var result;
    // Default the commit op to just the value update
    var commitOp = CommitOp.UPDATE;
    // Verifies if any of the args are not null
    var isMetadataNotNull = ObjectsUtil.isAnyNotNull(
        a1: time_to_live,
        a2: time_to_born,
        a3: time_to_refresh,
        a4: isCascade,
        a5: isBinary,
        a6: isEncrypted);
    if (isMetadataNotNull) {
      // Set commit op to UPDATE_META
      commitOp = CommitOp.UPDATE_META;
    }
    if (value != null) {
      commitOp = CommitOp.UPDATE_ALL;
    }
    try {
      assert(key != null);
      var existingData = await get(key);
      if (existingData == null) {
        result = await create(key, value,
            time_to_live: time_to_live,
            time_to_born: time_to_born,
            time_to_refresh: time_to_refresh,
            isCascade: isCascade,
            isBinary: isBinary,
            isEncrypted: isEncrypted,
            dataSignature: dataSignature);
      } else {
        var elastic_key = keyStoreHelper.prepareKey(key);
        var elastic_value = keyStoreHelper.prepareDataForUpdate(
            existingData, value,
            ttl: time_to_live,
            ttb: time_to_born,
            ttr: time_to_refresh,
            isCascade: isCascade,
            isBinary: isBinary,
            isEncrypted: isEncrypted,
            dataSignature: dataSignature);
        logger.finest('elastic key:${elastic_key}');
        logger.finest('elastic value:${elastic_value}');
        // await persistenceManager.box?.put(elastic_key, elastic_value);
        // result = await _commitLog.commit(elastic_key, commitOp);
        var elastic_value_json = (elastic_value != null)
            ? json.encode(elastic_value.toJson())
            : null;
        await persistenceManager.client.updateDoc(
          index: 'my_index',
          type: 'my_type',
          id: elastic_key,
          doc: elastic_value_json,
        );
        result = await _commitLog.commit(elastic_key, commitOp);
      }
    } on DataStoreException {
      rethrow;
    } on Exception catch (exception) {
      logger.severe('ElasticKeystore put exception: $exception');
      throw DataStoreException('exception in put: ${exception.toString()}');
    }
    return result;
  }

  @override
  Future putAll(String key, AtData value, AtMetaData metadata) async {
    var result;
    var elastic_key = keyStoreHelper.prepareKey(key);
    value.metaData = AtMetadataBuilder(newAtMetaData: metadata).build();
    // Updating the version of the metadata.
    (metadata.version != null) ? metadata.version += 1 : metadata.version = 0;
    await persistenceManager.client.updateDoc(
      index: 'my_index',
      type: 'my_type',
      id: elastic_key,
      doc: value,
    );
    result = await _commitLog.commit(elastic_key, CommitOp.UPDATE_ALL);
    return result;
  }

  @override
  Future putMeta(String key, AtMetaData metadata) async {
    var elastic_key = keyStoreHelper.prepareKey(key);
    var existingData = await get(key);
    var newData = existingData ?? AtData();
    newData.metaData = AtMetadataBuilder(
            newAtMetaData: metadata, existingMetaData: newData.metaData)
        .build();
    // Updating the version of the metadata.
    (newData.metaData.version != null)
        ? newData.metaData.version += 1
        : newData.metaData.version = 0;
    await persistenceManager.client.updateDoc(
        index: 'my_index', type: 'my_type', id: elastic_key, doc: newData);
    var result = await _commitLog.commit(elastic_key, CommitOp.UPDATE_META);
    return result;
  }

  @override
  Future remove(String key) async {
    var result;
    try {
      assert(key != null);
      await persistenceManager.client.deleteDoc(index: 'my_index', id: key)(
          keys: [key]);
      result = await _commitLog.commit(key, CommitOp.DELETE);
      return result;
    } on Exception catch (exception) {
      logger.severe('ElasticKeystore delete exception: $exception');
      throw DataStoreException('exception in remove: ${exception.toString()}');
    }
  }
}
