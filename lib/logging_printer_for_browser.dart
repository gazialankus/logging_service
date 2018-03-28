import 'dart:html' as html;

import 'package:logging/logging.dart' as log;
import 'package:logging_service/src/js_console_proxy.dart';
import 'package:stack_trace/stack_trace.dart';

class LoggingPrinterForBrowser {
  static const String separatorString = '\n****************************************************************\n';
  final bool _shouldTerseErrorWhenPrint;
  final JsConsoleProxy _consoleProxy;

  LoggingPrinterForBrowser({bool shouldTerseErrorWhenPrint: false, JsConsoleProxy consoleProxy})
      : _shouldTerseErrorWhenPrint = shouldTerseErrorWhenPrint,
        _consoleProxy = consoleProxy ?? new JsConsoleProxy();

  void call(log.LogRecord rec) {
    print('### Log: ${rec.sequenceNumber}');
    if (rec.level == log.Level.SEVERE) {
      print('### rec.level: ${rec.level}');
      print('### rec.loggerName: ${rec.loggerName}');
      print('### rec.time: ${rec.time}');
      print('### rec.message: ${rec.message}');

      print('### rec.error.runtimeType: ${rec.error.runtimeType}');
      print('### rec.error.toString():\n${rec.error.toString()}');
      if (rec.error is Error) {
        print('### rec.error is Error');
        var stack = (rec.error as Error).stackTrace;
        print('### stack.runtimeType: ${stack.runtimeType}');
        print('### stack.toString():\n${stack.toString()}');
      }

      print('### rec.stackTrace.runtimeType: ${rec.stackTrace.runtimeType}');
      print('### rec.stackTrace.toString():\n${rec.stackTrace.toString()}');
      if (rec.stackTrace is Trace) {
        print('### rec.stackTrace is Trace');
        print('### rec.stackTrace.terse.toString():\n${(rec.stackTrace as Trace).terse.toString()}');
      } else if (rec.stackTrace is Chain) {
        print('### rec.stackTrace is Chain');
        for (var trace in (rec.stackTrace as Chain).traces) {
          print('### trace.original.runtimeType: ${trace.original.runtimeType}');
          print('### trace.original:');
          print(trace.original);
        }
        print('### rec.stackTrace.terse.toString():\n${(rec.stackTrace as Chain).terse.toString()}');
      }
    }

    var devMode = false;
    assert(devMode = true);

    print('### devMode: $devMode');
    print('### _shouldTerseErrorWhenPrint: $_shouldTerseErrorWhenPrint');

    /////////////////////////////////////////////////////////////////////////////////////////////////////

    var additionalInfo = <String>[];
    var msg = '${rec.sequenceNumber}/${rec.level} [${rec.time.toIso8601String()}] ';
    msg += '${rec.loggerName}: ${rec.message ?? '<the record.message is empty>'}';

    if (rec.error != null) {
      additionalInfo.add(_makeHeaderString('record.error.toString()'));
      additionalInfo.add(rec.error.toString());

      if (rec.error is Error && (rec.error as Error).stackTrace != null) {
        var stack = (rec.error as Error).stackTrace;

        if (!devMode) {
          additionalInfo.add(_makeHeaderString('record.error.stackTrace.toString()'));
          additionalInfo.add(stack.toString());
        }
      }
    }

    if (rec.stackTrace != null) {
      var stackTraceDesc = 'record.stackTrace';
      var traceStrings = <String>[];

      if (devMode) {
        if (_shouldTerseErrorWhenPrint) {
          if (rec.stackTrace is Trace) {
            stackTraceDesc += '<Trace>';
            traceStrings.add((rec.stackTrace as Trace).terse.toString());
          } else if (rec.stackTrace is Chain) {
            stackTraceDesc += '<Chain>';
            traceStrings.add((rec.stackTrace as Chain).terse.toString());
          } else {
            traceStrings.add(new Trace.from(rec.stackTrace).terse.toString());
          }
          stackTraceDesc += '<terse>';
        } else {
          traceStrings.add(rec.stackTrace.toString());
        }

        additionalInfo.add(_makeHeaderString(stackTraceDesc));
        additionalInfo.addAll(traceStrings);
      } else {
        if (rec.stackTrace is Trace) {
          stackTraceDesc += '<Trace>';
          var trace = rec.stackTrace as Trace;
          if (_shouldTerseErrorWhenPrint) {
            stackTraceDesc += '<terse>';
            trace = trace.terse;
          }

          traceStrings.add(trace.original.toString());
        } else if (rec.stackTrace is Chain) {
          stackTraceDesc += '<Chain>';
          var tracesChain = rec.stackTrace as Chain;
          if (_shouldTerseErrorWhenPrint) {
            stackTraceDesc += '<terse>';
            tracesChain = tracesChain.terse;
          }

          traceStrings.addAll(tracesChain.traces.map((Trace trace) => trace.original.toString()));
        } else {
          if (_shouldTerseErrorWhenPrint) {
            stackTraceDesc += '<terse>';
            traceStrings.add(new Trace.from(rec.stackTrace).terse.toString());
          } else {
            traceStrings.add(rec.stackTrace.toString());
          }
        }

        additionalInfo.add(_makeHeaderString(stackTraceDesc));
        additionalInfo.addAll(traceStrings);
      }
    }

    if (devMode && additionalInfo.isNotEmpty) {
      msg += '\n' + additionalInfo.join('\n');
    }

    if (rec.level == log.Level.SEVERE) {
      _consoleProxy.error(msg);
    } else {
      _consoleProxy.log(msg);
    }

    if (additionalInfo.isNotEmpty && !devMode) {
      _consoleProxy.group('${rec.sequenceNumber}/${rec.level} Additional info:');
      for (var msg in additionalInfo) {
        _consoleProxy.log(msg);
      }
      _consoleProxy.groupEnd();
    }

//    if (rec.error != null && rec.error.toString() != rec.message) {
//      msg += '\n' + rec.error.toString();
//    }
//
//    if (rec.level == log.Level.SEVERE) {
//      _consoleProxy.error(msg);
//    } else {
//      _consoleProxy.log(msg);
//    }
//
//    if (rec.stackTrace != null) {
//      String trace;
//
//      if (_shouldTerseErrorWhenPrint) {
//        if (rec.stackTrace is Trace) {
//          trace = (rec.stackTrace as Trace).terse.toString();
//        } else if (rec.stackTrace is Chain) {
//          trace = (rec.stackTrace as Chain).terse.toString();
//        } else {
//          trace = new Trace.from(rec.stackTrace).terse.toString();
//        }
//      } else if (rec.stackTrace is Chain) {
//        _consoleProxy.group('The chained stack trace: ');
//        for (final trace in (rec.stackTrace as Chain).traces) {
//          _consoleProxy.log(_correctFormat(trace.original.toString()));
//        }
//        _consoleProxy.groupEnd();
//      } else if (rec.stackTrace is Trace) {
//        trace = _correctFormat((rec.stackTrace as Trace).original.toString());
//      } else {
//        trace = _correctFormat(rec.stackTrace.toString());
//      }
//
//      if (trace != null) {
//        _consoleProxy.log(trace);
//      }
//    }
  }

  String _correctFormat(String trace) {
    var traceStrings = trace.split(new RegExp(r'(?:\r\n)|(?:\r)|(?:\n)'));

    if (!traceStrings.first.startsWith(new RegExp(r'[A-Za-z]*Error'))) {
      return 'Error: \n$trace';
    }

    return trace;
  }

  String _makeHeaderString(String info) => '\n***** $info '.padRight(100, '*');
}
