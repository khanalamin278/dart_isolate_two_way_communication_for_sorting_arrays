/// Support for doing something awesome.
///
/// More dartdocs go here.
library;

export 'src/dart_isolate_two_way_communication_for_sorting_arrays_base.dart';

import 'dart:async';
import 'dart:isolate';

/*
Revised Practice Question 2: Two-Way Communication for Sorting Arrays
Task:
Update sortArrayInIsolate to allow two-way communication. 
The main isolate should be able to send multiple arrays to 
the spawned isolate for sorting and receive sorted arrays 
in response
 */

class SendingTextCommandsAndReceivedProcessedIsolate {
  final _receivedFromProcessed = ReceivePort();
  late final Stream _broadcastStream;
  SendPort? sendingToTextProcessor;
  bool sendPortInitialized = false;
  Isolate? isolateForTextProcessor;

  SendingTextCommandsAndReceivedProcessedIsolate() {
    _broadcastStream = _receivedFromProcessed.asBroadcastStream();
    //allows for _receivedFromProcessed to be listened to multiple times
    //don't worry, there is a below line "subscription?.cancel();" which closes a listener once it is done with the stream
    //so listeners don't needlessly accumulate
  }

  Future<dynamic> sendAndReceive(List<int> commandsAndInput) async {
    final completer = Completer();

    // if (isolateForTextProcessor != null) {
    //   isolateForTextProcessor?.kill();
    //   isolateForTextProcessor = null;
    // }
    // isolateForTextProcessor =
    //     await Isolate.spawn(_textProcessPort, _receivedFromProcessed.sendPort);
    //the above will work but is not advised, better to reuse isolates rather than kill/remake them

    isolateForTextProcessor ??=
        await Isolate.spawn(_textProcessPort, _receivedFromProcessed.sendPort);

    StreamSubscription? subscription;
    (sendPortInitialized)
        ? sendingToTextProcessor?.send(
            commandsAndInput) //triggers the text processor isolate by sending it a map. without this, it will not send anything back!
        : print('Send Port to text processor has not been initialized yet!');

    subscription = _broadcastStream.listen((message) async {
      print("Message from text processing isolate: $message");

      if (message is SendPort) {
        sendingToTextProcessor = message;
        sendPortInitialized = true;
        sendingToTextProcessor?.send(commandsAndInput);
      }
      if (message is List) {
        completer.complete(message);
        subscription?.cancel();
      }
    });
    return completer.future;
  }

  void shutdown() {
    _receivedFromProcessed.close();
    isolateForTextProcessor?.kill();
    isolateForTextProcessor = null;
  }
}

Future<void> _textProcessPort(SendPort sendBackToMainPort) async {
  final receiveFromMainPort = ReceivePort();
  sendBackToMainPort.send(receiveFromMainPort
      .sendPort); //sending the recieve port to the main isolate so it can communicate back with us

  await for (var message in receiveFromMainPort) {
    if (message is List<int>) {
      var sortedArray = List<int>.from(message)..sort();
      sendBackToMainPort.send(sortedArray);
    } else if (message == 'shutdown') {
      receiveFromMainPort.close();
      break;
    }
  }
}

processingFunction(List<int> commandsAndInput) async {
  ReceivePort receivePort = ReceivePort();

  return await receivePort.toList();
}

setupSortingIsolate() async {
  return SendingTextCommandsAndReceivedProcessedIsolate();
}

/*
extension SortingIsolate on Isolate {
  Future<List<int>> sendAndReceive(List<int> array) async {
    ReceivePort receivePort = ReceivePort();
    this.send(receivePort.sendPort);

    SendPort isolateSendPort = await receivePort.first;
    isolateSendPort.send(array);

    return await receivePort.first;
  }

  Future<void> shutdown() {
    final completer = Completer<void>();
    this.send('shutdown');
    this.addOnExitListener(receivePort.sendPort, response: completer.complete);
    return completer.future;
  }
}

Future<Isolate> setupSortingIsolate() async {
  ReceivePort receivePort = ReceivePort();
  Isolate isolate = await Isolate.spawn(sortArrayInIsolate, receivePort.sendPort);
  SendPort sendPort = await receivePort.first;

  return isolate;
}

 */