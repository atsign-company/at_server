import 'package:at_secondary/src/verb/handler/response/base_response_handler.dart';

class MonitorResponseHandler extends BaseResponseHandler {
  @override
  String getResponseMessage(String verbResult, String prompt) {
    return '';
  }

  @override
  bool isComplete() {
    return true;
  }
}
