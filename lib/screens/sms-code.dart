
import 'package:flutter/material.dart';
import 'package:flutter_verification_code/flutter_verification_code.dart';
import 'package:gasoilt/api/auth.dart';
import 'package:gasoilt/screens/main-section/home.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async';
import '../themes/manager.dart';
import '../widgets/mainButton.dart';

// ignore: must_be_immutable
class SmsCodeVerificationScreen extends StatefulWidget {
  String phone;

  SmsCodeVerificationScreen({super.key, required this.phone});

  @override
  State<SmsCodeVerificationScreen> createState() =>
      _SmsCodeVerificationScreenState();
}

class _SmsCodeVerificationScreenState extends State<SmsCodeVerificationScreen> {
  bool _onEditing = true;
  String? _code;
  late int _start;
  bool resend = false;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    sendCode(widget.phone);
    _start = 30;
    _startTimer();
  }

  // Метод для запуска таймера
  void _startTimer() {
    _timer = Timer.periodic(Duration(seconds: 1), (timer) {
      if (_start > 0) {
        setState(() {
          _start--;
        });
      } else {
        setState(() {
          resend = true;
        });
        _timer?.cancel();
      }
    });
  }


  void _resetTimer() {
    setState(() {
      resend = false;
      _start = 30;
    });
    _startTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }


  @override
  Widget build(BuildContext context) {
    bool isDark = Provider.of<DarkThemeProvider>(context).darkTheme;
    return Scaffold(
      backgroundColor: const Color(0xfff6f6f7),
      body: Stack(
        children: [
          isDark
              ? Container(
            decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xff173435), Color(0xff134e29)],
                  stops: [0, 1],
                  begin: Alignment.topRight,
                  end: Alignment.bottomLeft,
                )),
          )
              : Container(),
          Padding(
            padding: EdgeInsets.symmetric(
                horizontal: MediaQuery.of(context).size.width * .05),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  height: MediaQuery.of(context).size.height * .01,
                ),
                const Padding(
                  padding: EdgeInsets.only(top: 20, left: 12),
                  child: Text(
                    'Звонок',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 35),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(left: 12),
                  child: SizedBox(
                    width: MediaQuery.of(context).size.width * .7,
                    child: const Text(
                      'На Ваш номер будет совершен звонок, введите последние 4 цифры номера телефона',
                      style: TextStyle(),
                    ),
                  ),
                ),
                Center(
                 child:  VerificationCode(
                  fullBorder: true,
                  digitsOnly: true,
                  autofocus: true,
                  keyboardType: TextInputType.number,
                  length: 4,
                  itemSize: MediaQuery.of(context).size.width * 0.14,
                  textStyle:
                  const TextStyle(fontWeight: FontWeight.bold, fontSize: 22),
                  margin: const EdgeInsets.all(8),
                  onCompleted: (String value) {
                    setState(() {
                      _code = value;
                    });
                  },
                  onEditing: (bool value) {
                    setState(() {
                      _onEditing = value;
                    });
                    if (!_onEditing) FocusScope.of(context).unfocus();
                  },
                ),
                ),
                Center(
                  child: mainButton(
                      MediaQuery.of(context).size.width * .6, 40.0, () async {
                    if (resend) {
                      _resetTimer();
                      resendCode(widget.phone).then((value) => showDialog(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: const Text("Внимание"),
                            content:
                            const Text("На Ваш номер отправлен смс-код!"),
                            actions: [
                              TextButton(
                                  onPressed: () =>
                                      Navigator.of(context).pop(),
                                  child: const Text("Ok"))
                            ],
                          )
                      ));
                    }
                  }, 'Отправить смс-код ($_start)', !resend),
                ),
                SizedBox(
                  width: double.infinity,
                  child: mainButton(double.infinity,
                      MediaQuery.of(context).size.height * .055, () async {
                        Map<String, dynamic> data =
                        await checkCode(widget.phone, _code);
                        SharedPreferences instance =
                        await SharedPreferences.getInstance();
                        if (data['status']) {
                          String token = data['user'];
                          instance.setString('token', token);
                          Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(
                                  builder: (BuildContext context) => HomeScreen(
                                    initPage: 2,
                                  )));
                        }
                      }, "Войти"),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
