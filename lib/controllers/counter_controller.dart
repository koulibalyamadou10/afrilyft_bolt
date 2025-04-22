import 'package:get/get.dart';
import '../models/counter_model.dart';

class CounterController extends GetxController {
  final CounterModel _model = CounterModel();
  
  // Variable réactive
  final _count = 0.obs;
  
  // Getter pour la variable réactive
  int get count => _count.value;
  
  void incrementCounter() {
    _count.value++;
    update(); // Notifie les widgets qui utilisent GetBuilder
  }
} 