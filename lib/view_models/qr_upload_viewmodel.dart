import 'package:dio/dio.dart';
import 'package:fanmi/net/common_service.dart';
import 'package:fanmi/net/status_code.dart';
import 'package:fanmi/view_models/view_state_model.dart';
import 'package:flutter_smart_dialog/flutter_smart_dialog.dart';

class QrUploadViewModel extends ViewStateModel {
  String qrType;
  String? qrUrl;
  bool isDelete = false;

  QrUploadViewModel({this.qrUrl, required this.qrType}) {
    if (qrUrl == "") {
      qrUrl = null;
    }
  }

  Future<bool> uploadQr(String toUpQr) async {
    try {
      var resp =
          await CommonService.upLoadContactQr(qrUrl: toUpQr, qrType: qrType);
      if(resp.statusCode == StatusCode.SUCCESS){
        setQrUrl(toUpQr);
      }
      return true;
    } catch (e, s) {
      print(e);
      e as DioError;
      SmartDialog.showToast(e.error.message);
      return false;
    }
  }

  removeImgUploaded() {
    qrUrl = null;
    isDelete = true;
    notifyListeners();
  }

  setQrUrl(String qrUrl) {
    this.qrUrl = qrUrl;
    isDelete = false;
    notifyListeners();
  }
}
