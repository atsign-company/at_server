import 'dart:convert';
import 'dart:io';

import 'package:at_commons/at_commons.dart';
import 'package:at_persistence_secondary_server/at_persistence_secondary_server.dart';
import 'package:at_secondary/src/connection/inbound/inbound_connection_impl.dart';
import 'package:at_secondary/src/connection/inbound/inbound_connection_metadata.dart';
import 'package:at_secondary/src/notification/at_notification_map.dart';
import 'package:at_secondary/src/server/at_secondary_impl.dart';
import 'package:at_secondary/src/utils/handler_util.dart';
import 'package:at_secondary/src/verb/handler/notify_list_verb_handler.dart';
import 'package:at_server_spec/at_verb_spec.dart';
import 'package:crypto/crypto.dart';
import 'package:test/test.dart';

void main() {
  var storageDir = Directory.current.path + '/test/hive';
  late var keyStoreManager;
  group('A group of notify list verb tests', () {
    test('test notify getVerb', () {
      var handler = NotifyListVerbHandler(null);
      var verb = handler.getVerb();
      expect(verb is NotifyList, true);
    });

    test('test notify command accept test', () {
      var command = 'notify:list .me:2021-01-01:2021-01-12';
      var handler = NotifyListVerbHandler(null);
      var result = handler.accept(command);
      print('result : $result');
      expect(result, true);
    });

    test('test notify list with params', () {
      var verb = NotifyList();
      var command = 'notify:list:2021-01-01:2021-01-12:.me';
      var regex = verb.syntax();
      var paramsMap = getVerbParam(regex, command);
      expect('.me', paramsMap['regex']);
      expect('2021-01-01', paramsMap['fromDate']);
      expect('2021-01-12', paramsMap['toDate']);
    });

    test('test notify list with regex', () {
      var verb = NotifyList();
      var command = 'notify:list:^phone';
      var regex = verb.syntax();
      var paramsMap = getVerbParam(regex, command);
      expect('^phone', paramsMap['regex']);
    });

    test('test fromDate is populated and toDate is optional', () {
      var verb = NotifyList();
      var command = 'notify:list:2021-01-12:^phone:';
      var regex = verb.syntax();
      var paramsMap = getVerbParam(regex, command);
      expect('^phone', paramsMap['regex']);
      expect('2021-01-12', paramsMap['fromDate']);
    });
  });

  group('A group of notify list negative test', () {
    test('test notify key- invalid keyword', () {
      var verb = NotifyList();
      var command = 'notif:list';
      var regex = verb.syntax();
      expect(
          () => getVerbParam(regex, command),
          throwsA(predicate((dynamic e) =>
              e is InvalidSyntaxException && e.message == 'Syntax Exception')));
    });
  });

  group('A group of tests on date time', () {
    setUp(() async => keyStoreManager = await setUpFunc(storageDir));
    test('A test to verify from date', () async {
      var notifyListVerbHandler =
          NotifyListVerbHandler(keyStoreManager.getKeyStore());
      var notification1 = (AtNotificationBuilder()
            ..id = '122'
            ..fromAtSign = '@test_user_1'
            ..notificationDateTime = DateTime.now().subtract(Duration(days: 1))
            ..toAtSign = '@bob'
            ..notification = 'key-2'
            ..type = NotificationType.received
            ..opType = OperationType.update
            ..messageType = MessageType.key
            ..expiresAt = null
            ..priority = NotificationPriority.low
            ..notificationStatus = NotificationStatus.queued
            ..retryCount = 0
            ..strategy = 'latest'
            ..notifier = 'persona'
            ..depth = 3)
          .build();

      var notification2 = (AtNotificationBuilder()
            ..id = '125'
            ..fromAtSign = '@test_user_1'
            ..notificationDateTime = DateTime.now()
            ..toAtSign = '@bob'
            ..notification = 'key-3'
            ..type = NotificationType.received
            ..opType = OperationType.update
            ..messageType = MessageType.key
            ..expiresAt = null
            ..priority = NotificationPriority.low
            ..notificationStatus = NotificationStatus.queued
            ..retryCount = 0
            ..strategy = 'latest'
            ..notifier = 'persona'
            ..depth = 3)
          .build();

      await AtNotificationKeystore.getInstance().put('122', notification1);
      await AtNotificationKeystore.getInstance().put('125', notification2);
      var verb = NotifyList();
      var date = DateTime.now().toString().split(' ')[0];
      var command = 'notify:list:$date';
      var regex = verb.syntax();
      var verbParams = getVerbParam(regex, command);
      var inBoundSessionId = '123';
      var metadata = InboundConnectionMetadata()
        ..fromAtSign = '@alice'
        ..isAuthenticated = true;
      var atConnection = InboundConnectionImpl(null, inBoundSessionId)
        ..metaData = metadata;
      var response = Response();
      await notifyListVerbHandler.processVerb(
          response, verbParams, atConnection);
      var result = jsonDecode(response.data!);
      expect('125', result[0]['id']);
      expect('@test_user_1', result[0]['from']);
      expect('@bob', result[0]['to']);
      expect('key-3', result[0]['key']);
    });

    test('A test to verify from and to date', () async {
      var notifyListVerbHandler =
          NotifyListVerbHandler(keyStoreManager.getKeyStore());
      var notification1 = (AtNotificationBuilder()
            ..id = '121'
            ..fromAtSign = '@test_user_1'
            ..notificationDateTime = DateTime.now().subtract(Duration(days: 2))
            ..toAtSign = '@bob'
            ..notification = 'key-1'
            ..type = NotificationType.received
            ..opType = OperationType.update
            ..messageType = MessageType.key
            ..expiresAt = null
            ..priority = NotificationPriority.low
            ..notificationStatus = NotificationStatus.queued
            ..retryCount = 0
            ..strategy = 'latest'
            ..notifier = 'persona'
            ..depth = 3)
          .build();

      var notification2 = (AtNotificationBuilder()
            ..id = '122'
            ..fromAtSign = '@test_user_1'
            ..notificationDateTime = DateTime.now().subtract(Duration(days: 1))
            ..toAtSign = '@bob'
            ..notification = 'key-2'
            ..type = NotificationType.received
            ..opType = OperationType.update
            ..messageType = MessageType.key
            ..expiresAt = null
            ..priority = NotificationPriority.low
            ..notificationStatus = NotificationStatus.queued
            ..retryCount = 0
            ..strategy = 'latest'
            ..notifier = 'persona'
            ..depth = 3)
          .build();

      var notification3 = (AtNotificationBuilder()
            ..id = '123'
            ..fromAtSign = '@test_user_1'
            ..notificationDateTime =
                DateTime.now().subtract(Duration(seconds: 1))
            ..toAtSign = '@bob'
            ..notification = 'key-3'
            ..type = NotificationType.received
            ..opType = OperationType.update
            ..messageType = MessageType.key
            ..expiresAt = null
            ..priority = NotificationPriority.low
            ..notificationStatus = NotificationStatus.queued
            ..retryCount = 0
            ..strategy = 'latest'
            ..notifier = 'persona'
            ..depth = 3)
          .build();

      await AtNotificationKeystore.getInstance().put('121', notification1);
      await AtNotificationKeystore.getInstance().put('122', notification2);
      await AtNotificationKeystore.getInstance().put('123', notification3);
      var verb = NotifyList();
      var fromDate =
          DateTime.now().subtract(Duration(days: 2)).toString().split(' ')[0];
      var toDate =
          DateTime.now().subtract(Duration(days: 1)).toString().split(' ')[0];
      var command = 'notify:list:$fromDate:$toDate';
      var regex = verb.syntax();
      var verbParams = getVerbParam(regex, command);
      var inBoundSessionId = '100';
      var metadata = InboundConnectionMetadata()
        ..fromAtSign = '@alice'
        ..isAuthenticated = true;
      var atConnection = InboundConnectionImpl(null, inBoundSessionId)
        ..metaData = metadata;
      var response = Response();
      await notifyListVerbHandler.processVerb(
          response, verbParams, atConnection);
      var result = jsonDecode(response.data!);
      expect('121', result[0]['id']);
      expect('@test_user_1', result[0]['from']);
      expect('@bob', result[0]['to']);
      expect('key-1', result[0]['key']);
      expect('122', result[1]['id']);
      expect('@test_user_1', result[1]['from']);
      expect('@bob', result[1]['to']);
      expect('key-2', result[1]['key']);
    });
    tearDown(() async => tearDownFunc());
  });
}

Future<SecondaryKeyStoreManager> setUpFunc(storageDir) async {
  var secondaryPersistenceStore = SecondaryPersistenceStoreFactory.getInstance()
      .getSecondaryPersistenceStore(
          AtSecondaryServerImpl.getInstance().currentAtSign)!;
  var persistenceManager =
      secondaryPersistenceStore.getHivePersistenceManager()!;
  await persistenceManager.init('@test_user_1', storageDir);
  await persistenceManager.openVault('@test_user_1');
//  persistenceManager.scheduleKeyExpireTask(1); //commented this line for coverage test
  var hiveKeyStore = secondaryPersistenceStore.getSecondaryKeyStore()!;
  var keyStoreManager =
      secondaryPersistenceStore.getSecondaryKeyStoreManager()!;
  keyStoreManager.keyStore = hiveKeyStore;
  hiveKeyStore.commitLog = await AtCommitLogManagerImpl.getInstance()
      .getCommitLog('@test_user_1', commitLogPath: storageDir);
  await AtAccessLogManagerImpl.getInstance()
      .getAccessLog('@test_user_1', accessLogPath: storageDir);
  var notificationInstance = AtNotificationKeystore.getInstance();
  await notificationInstance.init(
      storageDir, 'notifications_' + _getShaForAtsign('@test_user_1'));
  return keyStoreManager;
}

Future<void> tearDownFunc() async {
  var isExists = await Directory('test/hive').exists();
  AtNotificationMap.getInstance().clear();
  if (isExists) {
    Directory('test/hive').deleteSync(recursive: true);
  }
}

String _getShaForAtsign(String atsign) {
  var bytes = utf8.encode(atsign);
  return sha256.convert(bytes).toString();
}
