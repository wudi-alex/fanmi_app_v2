import 'package:fanmi/config/page_size_config.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_smart_dialog/flutter_smart_dialog.dart';
import 'package:tencent_im_sdk_plugin/models/v2_tim_conversation.dart';
import 'package:tencent_im_sdk_plugin/models/v2_tim_conversation_result.dart';
import 'package:tencent_im_sdk_plugin/models/v2_tim_friend_info.dart';
import 'package:tencent_im_sdk_plugin/models/v2_tim_friend_info_result.dart';
import 'package:tencent_im_sdk_plugin/models/v2_tim_user_full_info.dart';
import 'package:tencent_im_sdk_plugin/models/v2_tim_value_callback.dart';
import 'package:tencent_im_sdk_plugin/tencent_im_sdk_plugin.dart';
import 'package:tuple/tuple.dart';

class ConversionListModel extends ChangeNotifier {
  String nextSeq = '0';

  Map<String, V2TimConversation> conversionMap = {};
  Map<String, V2TimFriendInfo> friendInfoMap = {};

  get pullCnt => PageSizeConfig.CONVERSION_PAGE_SIZE;

  get unreadCntTotal {
    int cnt = 0;
    conversionMap.forEach((userId, conversionInfo) {
      cnt += conversionInfo.unreadCount ?? 0;
    });
    return cnt;
  }

  get conversionPageList {
    List<Tuple3<V2TimConversation, V2TimUserFullInfo?, V2TimFriendInfo?>> res =
        [];
    conversionMap.forEach((userId, conversionInfo) {
      List list = [];
      list.add(conversionInfo);
      if (friendInfoMap.containsKey(userId)) {
        var friendInfo = friendInfoMap[userId]!;
        list.add(friendInfo.userProfile);
        list.add(friendInfo);
      } else {
        list.add(null);
        list.add(null);
      }
      res.add(Tuple3.fromList(list));
    });
    res.sort((v1, v2) => v2.item1.lastMessage!.timestamp!
        .compareTo(v1.item1.lastMessage!.timestamp!));
    return res;
  }

  init() async {
    while (true) {
      bool allLoad = await pullData();
      if (allLoad) {
        break;
      }
    }
  }

  pullData() async {
    var userList = await pullConversionData(nextSeq);
    await pullFriendInfoData(userList);
    return userList.length < pullCnt;
  }

  Future<List<String>> pullConversionData(String nextSeq) async {
    V2TimValueCallback<V2TimConversationResult> response =
        await TencentImSDKPlugin.v2TIMManager
            .getConversationManager()
            .getConversationList(nextSeq: nextSeq, count: pullCnt);
    if (response.code == 0) {
      List<V2TimConversation?> res = response.data!.conversationList!;
      nextSeq = response.data!.nextSeq!;
      updateConversionInfoMap(res);
      return response.data!.conversationList!.map((e) => e!.userID!).toList();
    } else {
      SmartDialog.showToast("获取聊天对象信息错误");
      return [];
    }
  }

  pullFriendInfoData(List<String> users) async {
    if (users.isEmpty) {
      return;
    }
    V2TimValueCallback<List<V2TimFriendInfoResult>> response =
        await TencentImSDKPlugin.v2TIMManager
            .getFriendshipManager()
            .getFriendsInfo(
              userIDList: users,
            );
    if (response.code == 0) {
      List<V2TimFriendInfoResult> res = response.data!;
      updateFriendInfoMap(res.map((v) => v.friendInfo!).toList());
    } else {
      SmartDialog.showToast("获取聊天对象信息错误");
    }
  }

  updateConversionInfoMap(List<V2TimConversation?> newList,
      {bool isDelete = false}) {
    Map<String, V2TimConversation> newMap = {};
    newList.forEach((element) {
      if (element!.lastMessage == null) {
        return;
      }
      newMap[element.userID!] = element;
    });
    updateMap(newMap: newMap, originalMap: conversionMap, isDelete: isDelete);
  }

  updateFriendInfoMap(List<V2TimFriendInfo> newList, {bool isDelete = false}) {
    Map<String, V2TimFriendInfo> newMap = {};
    newList.forEach((element) {
      newMap[element.userID] = element;
    });
    updateMap(newMap: newMap, originalMap: friendInfoMap, isDelete: isDelete);
  }

  clear() {
    conversionMap = {};
    friendInfoMap = {};
    notifyListeners();
  }

  //删除对话
  Future deleteConversion(String userId) async {
    var conversionId = conversionMap[userId]!.conversationID;
    try {
      await TencentImSDKPlugin.v2TIMManager
          .getConversationManager()
          .deleteConversation(
            conversationID: conversionId,
          );
    } catch (e, s) {}
    updateConversionInfoMap([conversionMap[userId]], isDelete: true);
  }

  updateMap<T>(
      {required Map<String, T> newMap,
      required Map<String, T> originalMap,
      required bool isDelete}) {
    newMap.forEach((key, value) {
      if (isDelete) {
        if (originalMap.containsKey(key)) {
          originalMap.remove(key);
        }
      } else {
        originalMap[key] = value;
      }
    });
    notifyListeners();
  }
}
