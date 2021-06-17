import 'dart:io';

import 'package:test/test.dart';

import 'commons.dart';
import 'package:at_functional_test/conf/config_util.dart';

///The below test functions runs a complete flow of all verbs
void main() async {
  // First atsign details
  var first_atsign = '@high8289';
  var second_atsign = '@92official22';

  Socket _socket_first_atsign;

  //Establish the client socket connection
  setUp(() async {
    var high8289_server =  ConfigUtil.getYaml()['high8289_server']['high8289_url'];
    var high8289_port =  ConfigUtil.getYaml()['high8289_server']['high8289_port'];
    
    _socket_first_atsign =
        await secure_socket_connection(high8289_server, high8289_port);
    socket_listener(_socket_first_atsign);
    await prepare(_socket_first_atsign, first_atsign);

    //Socket connection for alice atsign
  });

  test('update verb test $first_atsign', () async {
    ///Update verb with public key
    await socket_writer(
        _socket_first_atsign, 'update:public:mobile$first_atsign 9988112343');
    var response = await read();
    print('update verb response $response');
    assert((!response.contains('Invalid syntax')) && (!response.contains('null')));

    ///Update verb with private key
    await socket_writer(
        _socket_first_atsign, 'update:@alice:email$first_atsign bob@atsign.com');
    response = await read();
    print('update verb response $response');
    assert((!response.contains('Invalid syntax')) && (!response.contains('null')));
  });

  test('scan verb test $first_atsign', () async {
    await socket_writer(_socket_first_atsign, 'scan');
    var response = await read();
    print('scan verb response $response');
    expect(response, contains('"public:mobile$first_atsign"'));
  });

  test('llookup verb test $first_atsign', () async {
    await socket_writer(_socket_first_atsign, 'llookup:public:mobile$first_atsign');
    var response = await read();
    print('llookup verb response $response');
    expect(response, contains('data:9988112343'));
  });

  test('Delete verb test $first_atsign', () async {
    await socket_writer(_socket_first_atsign, 'delete:public:mobile$first_atsign');
    var response = await read();
    print('Delete verb response $response');
    assert(!response.contains('data:null'));
  });

  test('scan verb test after delete $first_atsign', () async {
    await socket_writer(_socket_first_atsign, 'scan');
    var response = await read();
    print('scan verb response $response');
    expect(response, isNot('public:mobile$first_atsign'));
  });

  test('config verb test -add block list $first_atsign', () async {
    await socket_writer(_socket_first_atsign, 'config:block:add:$second_atsign');
    var response = await read();
    print('Config verb response $response');
    expect(response, contains('data:success'));
  });

  test('config verb test - show list $first_atsign', () async {
    await socket_writer(_socket_first_atsign, 'config:block:show');
    var response = await read();
    print('Config verb response $response');
    expect(response, contains('$second_atsign'));
  });

  test('config verb test -remove from block list $first_atsign', () async {
    await socket_writer(_socket_first_atsign, 'config:block:remove:$second_atsign');
    var response = await read();
    print('config verb response $response');
    expect(response, contains('data:success'));
  });

  test('config verb test - show list $first_atsign', () async {
    await socket_writer(_socket_first_atsign, 'config:block:show');
    var response = await read();
    print('config verb response $response');
    expect(response, contains('data:null'));
  });


  tearDown(() {
    //Closing the socket connection
    clear();
    _socket_first_atsign.destroy();
  });
}
