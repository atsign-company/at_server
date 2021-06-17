import 'dart:io';

import 'package:test/test.dart';
import 'package:at_functional_test/conf/config_util.dart';

import 'commons.dart';

void main() {
  var first_atsign = '@high8289';
  var second_atsign = '@92official22';

  Socket _socket_second_atsign;
  Socket _socket_first_atsign;

  //Establish the client socket connection
  setUp(() async {
    var high8289_server =  ConfigUtil.getYaml()['high8289_server']['high8289_url'];
    var high8289_port =  ConfigUtil.getYaml()['high8289_server']['high8289_port'];

    var official22_server =  ConfigUtil.getYaml()['92official22_server']['92official22_url'];
    var official22_port =  ConfigUtil.getYaml()['92official22_server']['92official22_port'];
    
    //  var root_server = ConfigUtil.getYaml()['root_server']['url'];
    _socket_first_atsign =
        await secure_socket_connection(high8289_server, high8289_port);
    socket_listener(_socket_first_atsign);
    await prepare(_socket_first_atsign, first_atsign);

    //Socket connection for alice atsign
    _socket_second_atsign =
    await secure_socket_connection(official22_server, official22_port);
    socket_listener(_socket_second_atsign);
    await prepare(_socket_second_atsign, second_atsign);
  });

  test('plookup verb with public key - positive case', () async {
    /// UPDATE VERB
    await socket_writer(_socket_first_atsign, 'update:public:phone$first_atsign 9982212143');
    var response = await read();
    print('update verb response $response');
    assert((!response.contains('Invalid syntax')) && (!response.contains('null')));

    ///PLOOKUP VERB
    await socket_writer(_socket_second_atsign, 'plookup:phone$first_atsign');
    response = await read();
    print('plookup verb response $response');
    expect(response, contains('data:9982212143'));
  },timeout: Timeout(Duration(seconds: 120)));

  test('plookup verb with private key - negative case', () async {
    /// UPDATE VERB
    await socket_writer(_socket_first_atsign, 'update:$second_atsign:mobile$first_atsign 9982212143');
    var response = await read();
    print('update verb response $response');
    assert((!response.contains('Invalid syntax')) && (!response.contains('null')));

    ///PLOOKUP VERB
    await socket_writer(_socket_second_atsign, 'plookup:mobile$first_atsign$first_atsign');
    response = await read();
    print('plookup verb response $response');
    expect(response, contains('Invalid syntax'));
  },timeout: Timeout(Duration(seconds: 120)));

  test('plookup verb on non existent key - negative case', () async {
    ///PLOOKUP VERB
    await socket_writer(_socket_first_atsign, 'plookup:no-key$first_atsign');
    var response = await read();
    print('plookup verb response $response');
    expect(response,contains('data:null'));
  },timeout: Timeout(Duration(seconds: 120)));

  test('plookup for an emoji key', () async {
    ///UPDATE VERB
    await socket_writer(_socket_first_atsign, 'update:public:🦄🦄$first_atsign 2-unicorn-emojis');
    var response = await read();
    print('update verb response $response');
    assert(!(response.contains('data:null') && (response.contains('Invalid syntax'))));

    ///PLOOKUP VERB
    await socket_writer(_socket_second_atsign, 'plookup:🦄🦄$first_atsign');
    response = await read();
    print('plookup verb response $response');
    expect(response,contains('data:2-unicorn-emojis'));
  },timeout: Timeout(Duration(seconds: 120)));

  test('plookup with an extra symbols after the atsign', () async {
    ///UPDATE VERB
    await socket_writer(_socket_first_atsign, 'update:public:emoji-color@emoji🦄🛠 white');
    var response = await read();
    print('update verb response $response');
    assert((!response.contains('Invalid syntax')) && (!response.contains('null')));

    ///PLOOKUP VERB
    await socket_writer(_socket_second_atsign, 'plookup:emoji-color@emoji🦄🛠@@@');
    response = await read();
    print('plookup verb response $response');
    expect(response,contains('Invalid syntax'));
  },timeout: Timeout(Duration(seconds: 120)));

  test('cached key creation when we do a lookup for a public key', () async {
    ///UPDATE VERB
    await socket_writer(_socket_first_atsign, 'update:public:key-1$first_atsign 9102');
    var response = await read();
    print('update verb response $response');
    assert((!response.contains('Invalid syntax')) && (!response.contains('null')));

    ///PLOOKUP VERB
    await socket_writer(_socket_second_atsign, 'plookup:key-1$first_atsign');
    response = await read();
    print('plookup verb response $response');
    expect(response,contains('data:9102'));

    /// SCAN VERB
    await socket_writer(_socket_second_atsign, 'scan');
    response = await read();
    print('scan verb response $response');
    assert(response.contains('cached:public:key-1$first_atsign'));
  },timeout: Timeout(Duration(seconds: 120)));

  tearDown(() {
    //Closing the client socket connection
    clear();
    _socket_first_atsign.destroy();
    _socket_second_atsign.destroy();
  });
}