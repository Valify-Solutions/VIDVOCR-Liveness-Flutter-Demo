import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/services.dart';
import 'package:vidvliveness_flutter_plugin/vidvliveness_flutter_plugin.dart';
import 'package:pretty_http_logger/pretty_http_logger.dart';
import 'package:vidvocr_flutter_plugin/vidvocr_flutter_plugin.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  String _LivenessResult = 'No result yet';
  final _vidvlivenessFlutterPlugin = VidvlivenessFlutterPlugin();
  String _ocrResult = 'No result yet';
  final _vidvocrFlutterPlugin = VidvocrFlutterPlugin();

  // Example credentials, replace with real values
  final String baseURL = 'https://www.valifystage.com/';
  final String bundleKey = 'ad44eb94ca6747beaf99eef02407221f';
  final String userName = 'mobileusername';
  final String password = 'q5YT54wuJ2#mbanR';
  final String clientID = 'aKM21T4hXpgHFsgNJNTKFpaq4fFpoQvuBsNWuZoQ';
  final String clientSecret = 'r0tLrtxTue8c4kNmPVgaAFNGSeCWvL4oOZfBnVXoQe2Ffp5rscXXAAhX50BaZEll8ZRtr2BlgD3Nk6QLOPGtjbGXYoCBL9Fn7QCu5CsMlRKDbtwSnUAfKEG30cIv8tdW';

  // Liveness parameters
  bool _enableSmile = false;
  bool _enableLookLeft = false;
  bool _enableLookRight = false;
  bool _enableCloseEyes = false;
  bool _enableVoiceover = false;
  int _trials = 3;
  int _instructions = 4;
  int _timer = 10;


  // OCR parameters
  bool _isArabic = false;
  bool _documentVerification = false;
  bool _reviewData = false;
  bool _captureOnlyMode = false;
  bool _manualCaptureMode = false;
  bool _previewCapturedImage = false;
  bool _enableLogging = false;
  bool _collectUserInfo = false;
  bool _advancedConfidence = false;
  bool _professionAnalysis = false;
  bool _documentVerificationPlus = false;

  //ekyc params
  bool _testLiveness = false ;
  bool _testOcr = false ;


  // Function to generate a token using the provided credentials
  Future<String?> getToken() async {
    final String url = '$baseURL/api/o/token/';
    HttpWithMiddleware httpWithMiddleware = HttpWithMiddleware.build(middlewares: [
      HttpLogger(logLevel: LogLevel.BODY),
    ]);
    final Map<String, String> headers = {
      'Content-Type': 'application/x-www-form-urlencoded',
    };

    final String body = 'username=$userName&password=$password&client_id=$clientID&client_secret=$clientSecret&grant_type=password';

    final http.Response response = await httpWithMiddleware.post(
      Uri.parse(url),
      headers: headers,
      body: body,
    );

    if (response.statusCode == 200) {
      final Map<String, dynamic> jsonResponse = json.decode(response.body);
      return jsonResponse['access_token'];
    } else {
      print('Failed to retrieve token: ${response.statusCode}');
      return null;
    }
  }
  Future<void> startOCR() async {
    String? token;

    try {
      token = await getToken();
      if (token == null) {
        setState(() {
          _ocrResult = 'Failed to get token';
        });
        return;
      }
    } catch (e) {
      setState(() {
        _ocrResult = 'Error retrieving token: $e';
      });
      return;
    }

    // Prepare parameters based on checkbox states
    final Map<String, dynamic> params = {
      "base_url": baseURL,
      "access_token": token,
      "bundle_key": bundleKey,
      "language": _isArabic ? "ar" : "en",
      "document_verification": _documentVerification,
      "review_data": _reviewData,
      "capture_only_mode": _captureOnlyMode,
      "manual_capture_mode": _manualCaptureMode,
      "preview_captured_image": _previewCapturedImage,
      "primary_color": "#FF0000",
      "enable_logging": _enableLogging,
      "collect_user_info": _collectUserInfo,
      "advanced_confidence": _advancedConfidence,
      "profession_analysis": _professionAnalysis,
      "document_verification_plus": _documentVerificationPlus,
    };

    try {
      final String? result = await VidvocrFlutterPlugin.startOCR(params);
      final parsedResult = result is String ? jsonDecode(result) : result;
      switch (parsedResult['state']) {
        case 'SUCCESS':
          setState(() {
            _ocrResult = '_ocrResult success! Result: ${parsedResult['ocrResult']}';
          });
          break;
        case 'ERROR':
          setState(() {
            _ocrResult = 'Error occurred: ${parsedResult['errorCode']} - ${parsedResult['errorMessage']}';
          });
          break;
        case 'FAILURE':
          setState(() {
            _ocrResult = 'Service failed. Error code: ${parsedResult['errorCode']} - ${parsedResult['errorMessage']}';
          });
          break;
        case 'EXIT':
          setState(() {
            _ocrResult = 'User exited at step: ${parsedResult['step']}';
          });
          break;
        default:
          setState(() {
            _ocrResult = 'Unhandled response: $parsedResult';
          });
          break;
      }
    } catch (e) {
      setState(() {
        _ocrResult = 'Error: $e';
      });
    }
  }

  // Function to start the SDK after generating the token
  Future<void> startLiveness() async {
    String? token;

    try {
      token = await getToken();
      if (token == null) {
        setState(() {
          _LivenessResult= 'Failed to get token';
        });
        return;
      }
    } catch (e) {
      setState(() {
        _LivenessResult = 'Error retrieving token: $e';
      });
      return;
    }
    Map<String, dynamic> params = {
      'base_url': baseURL,
      'access_token': token,
      'bundle_key': bundleKey,
      'language': 'en',
      'liveness_time_per_action': _timer.toString(),
      'liveness_number_of_instructions': _instructions.toString(),
      'enable_smile': _enableSmile,
      'enable_look_left': _enableLookLeft,
      'enable_look_right': _enableLookRight,
      'enable_close_eyes': _enableCloseEyes,
      'enable_voiceover': _enableVoiceover,
      'primary_color': '#FF5733',
      'show_error_message': true,
    };

    try {
      final result = await VidvlivenessFlutterPlugin.startLiveness(params);
      setState(() {
        _LivenessResult = result.toString();
      });
    } catch (e) {
      setState(() {
        _LivenessResult = 'Error: $e';
      });
    }
  }
  Future<void> startValify() async {

    final token = await getToken();

    if (token == null) {
      setState(() {
        _ocrResult = 'Failed to get token';

      });
      return;
    }

    // Start OCR Process
    final Map<String, dynamic> ocrParams = {
      "access_token": token,
      "base_url": baseURL,
      "bundle_key": bundleKey,
      "document_verification": _documentVerification,
      "review_data": _reviewData,
      "capture_only_mode": _captureOnlyMode,
      "manual_capture_mode": _manualCaptureMode,
      "preview_captured_image": _previewCapturedImage,
      "primary_color": "#FF0000",
      "enable_logging": _enableLogging,
      "collect_user_info": _collectUserInfo,
      "advanced_confidence": _advancedConfidence,
      "profession_analysis": _professionAnalysis,
      "document_verification_plus": _documentVerificationPlus,
    };

    try {
      final String? ocrResponse = await VidvocrFlutterPlugin.startOCR(ocrParams);
      print('OCR Result: $ocrResponse');

      final parsedResponse = ocrResponse != null ? json.decode(ocrResponse) : null;

      if (parsedResponse != null && parsedResponse['state'] == 'SUCCESS') {
        final transactionIdFront = parsedResponse['ocrResult']['ocrResult']['transactionIdFront'];
        print('Transaction ID Front: $transactionIdFront');

        if (transactionIdFront != null) {
          // Wait 2 seconds before starting Liveness experience
          await Future.delayed(Duration(seconds: 15));

          final livenessParams = {
            "access_token": token,
            "base_url": baseURL,
            "bundle_key": bundleKey,
            "language": 'en',
            "enableSmile": _enableSmile,
            "enableLookLeft": _enableLookLeft,
            "enableLookRight": _enableLookRight,
            "enableCloseEyes": _enableCloseEyes,
            "trials": _trials,
            "instructions": _instructions,
            "timer": _timer,
            "primaryColor": "#FFFFFF", // replace with actual hex color code
            "enableVoiceover": _enableVoiceover,
            "facematch_ocr_transactionId": transactionIdFront, // Pass transaction ID from OCR
          };

          try {
            final String? livenessResult = await VidvlivenessFlutterPlugin.startLiveness(livenessParams);
            setState(() {
              _LivenessResult = livenessResult ?? 'Failed to start Liveness process.';
            });
          } on PlatformException catch (e) {
            setState(() {
              _LivenessResult = 'Liveness Error: ${e.message}';
            });
          }
        } else {
          setState(() {
            _ocrResult = 'Transaction ID not found in OCR response';
          });
        }
      } else {
        setState(() {
          _ocrResult = 'OCR state is not SUCCESS';
        });
      }
    } on PlatformException catch (e) {
      setState(() {
        _ocrResult = 'OCR Error: ${e.message}';
      });
    }


  }
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('OCR & Liveness'),
        ),
        body: SingleChildScrollView( // Make the entire body scrollable
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              CheckboxListTile(
                title: const Text('Language: Arabic'),
                value: _isArabic,
                onChanged: (bool? value) {
                  setState(() {
                    _isArabic = value ?? false;
                  });
                },
              ),
              const Text(
                'Liveness Options',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),

              CheckboxListTile(
                title: const Text('Enable Smile'),
                value: _enableSmile,
                onChanged: (bool? value) {
                  setState(() {
                    _enableSmile = value ?? true;
                  });
                },
              ),
              CheckboxListTile(
                title: const Text('Enable Look Left'),
                value: _enableLookLeft,
                onChanged: (bool? value) {
                  setState(() {
                    _enableLookLeft = value ?? true;
                  });
                },
              ),
              CheckboxListTile(
                title: const Text('Enable Look Right'),
                value: _enableLookRight,
                onChanged: (bool? value) {
                  setState(() {
                    _enableLookRight = value ?? true;
                  });
                },
              ),
              CheckboxListTile(
                title: const Text('Enable Close Eyes'),
                value: _enableCloseEyes,
                onChanged: (bool? value) {
                  setState(() {
                    _enableCloseEyes = value ?? true;
                  });
                },
              ),
              CheckboxListTile(
                title: const Text('Enable Voiceover'),
                value: _enableVoiceover,
                onChanged: (bool? value) {
                  setState(() {
                    _enableVoiceover = value ?? true;
                  });
                },
              ),

              const SizedBox(height: 10),

              // Adjustments for trials, instructions, and timer
              const Text('Trials (default: 3):'),
              Slider(
                value: _trials.toDouble(),
                min: 1,
                max: 10,
                divisions: 9,
                label: _trials.toString(),
                onChanged: (double value) {
                  setState(() {
                    _trials = value.toInt();
                  });
                },
              ),
              const SizedBox(height: 10),
              const Text('Instructions (default: 4):'),
              Slider(
                value: _instructions.toDouble(),
                min: 1,
                max: 10,
                divisions: 9,
                label: _instructions.toString(),
                onChanged: (double value) {
                  setState(() {
                    _instructions = value.toInt();
                  });
                },
              ),
              const SizedBox(height: 10),
              const Text('Timer (default: 10):'),
              Slider(
                value: _timer.toDouble(),
                min: 1,
                max: 30,
                divisions: 29,
                label: _timer.toString(),
                onChanged: (double value) {
                  setState(() {
                    _timer = value.toInt();
                  });
                },
              ),
              const SizedBox(height: 70),


              const Text(
                'OCR Options',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),


              CheckboxListTile(
                title: const Text('Document Verification'),
                value: _documentVerification,
                onChanged: (bool? value) {
                  setState(() {
                    _documentVerification = value ?? false;
                  });
                },
              ),
              CheckboxListTile(
                title: const Text('Review Data'),
                value: _reviewData,
                onChanged: (bool? value) {
                  setState(() {
                    _reviewData = value ?? false;
                  });
                },
              ),
              CheckboxListTile(
                title: const Text('Capture Only Mode'),
                value: _captureOnlyMode,
                onChanged: (bool? value) {
                  setState(() {
                    _captureOnlyMode = value ?? false;
                  });
                },
              ),
              CheckboxListTile(
                title: const Text('Manual Capture Mode'),
                value: _manualCaptureMode,
                onChanged: (bool? value) {
                  setState(() {
                    _manualCaptureMode = value ?? true;
                  });
                },
              ),
              CheckboxListTile(
                title: const Text('Preview Captured Image'),
                value: _previewCapturedImage,
                onChanged: (bool? value) {
                  setState(() {
                    _previewCapturedImage = value ?? true;
                  });
                },
              ),
              CheckboxListTile(
                title: const Text('Enable Logging'),
                value: _enableLogging,
                onChanged: (bool? value) {
                  setState(() {
                    _enableLogging = value ?? true;
                  });
                },
              ),
              CheckboxListTile(
                title: const Text('Collect User Info'),
                value: _collectUserInfo,
                onChanged: (bool? value) {
                  setState(() {
                    _collectUserInfo = value ?? false;
                  });
                },
              ),
              CheckboxListTile(
                title: const Text('Advanced Confidence'),
                value: _advancedConfidence,
                onChanged: (bool? value) {
                  setState(() {
                    _advancedConfidence = value ?? false;
                  });
                },
              ),
              CheckboxListTile(
                title: const Text('Profession Analysis'),
                value: _professionAnalysis,
                onChanged: (bool? value) {
                  setState(() {
                    _professionAnalysis = value ?? false;
                  });
                },
              ),
              CheckboxListTile(
                title: const Text('Document Verification Plus'),
                value: _documentVerificationPlus,
                onChanged: (bool? value) {
                  setState(() {
                    _documentVerificationPlus = value ?? false;
                  });
                },
              ),
              const SizedBox(height: 20),

              ElevatedButton(
                onPressed: startLiveness,
                child: const Text('Start Liveness'),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: startOCR,
                child: const Text('Start OCR'),
              ),
              const SizedBox(height: 20),
              // ElevatedButton(
              //   onPressed: startValify,
              //   child: const Text('Start Valify'),
              // ),
              const SizedBox(height: 20),

              Text(
                'Liveness Result: $_LivenessResult\n',
                textAlign: TextAlign.left,
              ),
              const SizedBox(height: 20),

              Text(
                'OCR Result: $_ocrResult\n',
                textAlign: TextAlign.left,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
