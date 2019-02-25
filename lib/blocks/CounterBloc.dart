import 'package:bloc/bloc.dart';
import 'package:blocks/events/CounterEvent.dart';

class CounterBloc extends Bloc<CounterEvent, int> {
  @override 
  int get initialState => 0;

  @override
  Stream<int> mapEventToState(int currentState, CounterEvent event) async*{
    switch (event) {
      case CounterEvent.decrement:
        yield currentState - 1;
        break;
      case CounterEvent.increment:
        yield currentState + 1;
        break;
      default:
    }
  }
}