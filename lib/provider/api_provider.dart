import 'package:mypsy_app/resources/api.dart';
import 'package:flutter/material.dart';

class ApiProvider with ChangeNotifier {
  mypsyApi? _api;
//  ProviderState _providerState = ProviderState.busy;

  mypsyApi? get api => _api;
//  ProviderState get state => _providerState;

  void initializeApi({String? token}) {
    _api = mypsyApi();
  }
}
