import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:indriver_clone/providers/auth.dart';
import 'package:indriver_clone/screens/account_details.dart';
import 'package:indriver_clone/screens/homepage.dart';
import 'package:indriver_clone/ui/button.dart';
import 'package:pinput/pinput.dart';
import 'package:provider/provider.dart';

class Verification extends StatefulWidget {
  const Verification({Key? key, required this.phoneNum}) : super(key: key);
  final String phoneNum;

  @override
  _VerificationState createState() => _VerificationState();
}

class _VerificationState extends State<Verification> {
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  final _pinController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  String? verificationCode;

  final pinDecoration = BoxDecoration(
    color: Colors.white,
    boxShadow: const [
      BoxShadow(offset: Offset(0, 0.1), color: Colors.green, blurRadius: 4)
    ],
    borderRadius: BorderRadius.circular(10.0),
  );

  @override
  void initState() {
    super.initState();
    signin(widget.phoneNum, context, _pinController.text);
  }

  void verifyPhoneNumber() async {
    var provider = Provider.of<Authentication>(context, listen: false);
    provider.signin(widget.phoneNum, context);
  }

  var pin;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        title: const Text('Verification'),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            Container(
              margin: const EdgeInsets.only(top: 20),
              child: Center(
                child: GestureDetector(
                  onTap: () {
                    verifyPhoneNumber();
                  },
                  child: Text('Verifying : ${widget.phoneNum}'),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(40.0),
              child: Pinput(
                length: 6,
                focusNode: _focusNode,
                controller: _pinController,
                pinAnimationType: PinAnimationType.rotation,
                onSubmitted: (pin) async {
                  try {
                    print(pin);
                    //signin(widget.phoneNum, context, pin);
                  } on FirebaseAuthException catch (e) {
                    FocusScope.of(context).unfocus();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(e.toString()),
                        duration: const Duration(seconds: 3),
                      ),
                    );
                  }
                },
              ),
            ),
            BotButton(
                onTap: () async {
                  print(_pinController.text);
                  try {
                    await FirebaseAuth.instance
                        .signInWithCredential(PhoneAuthProvider.credential(
                            verificationId: verificationCode!,
                            smsCode: _pinController.text))
                        .then((value) async {
                      await FirebaseFirestore.instance
                          .collection('users')
                          .where('id', isEqualTo: value.user!.uid)
                          .get()
                          .then((result) {
                        if (result.docs.isEmpty) {
                          Navigator.pushAndRemoveUntil(
                              context,
                              MaterialPageRoute(
                                //here change with CompleteSignUp
                                builder: (context) => const HomePage(),
                              ),
                              (route) => false);
                        } else {
                          Navigator.pushAndRemoveUntil(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const HomePage(),
                              ),
                              (route) => false);
                        }
                      });
                    });
                  } on FirebaseAuthException catch (e) {
                    FocusScope.of(context).unfocus();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(e.toString()),
                        duration: const Duration(seconds: 3),
                      ),
                    );
                  }
                },
                title: 'Go')
          ],
        ),
      ),
    );
  }

  Future<void> signin(
      String phoneNum, BuildContext context, String smsCode) async {
    try {
      await FirebaseAuth.instance.verifyPhoneNumber(
        phoneNumber: phoneNum,
        verificationCompleted: (PhoneAuthCredential credential) async {
          await FirebaseAuth.instance
              .signInWithCredential(credential)
              .then((value) async {
            await FirebaseFirestore.instance
                .collection('users')
                .where('id', isEqualTo: value.user!.uid)
                .get()
                .then((result) {
              if (result.docs.isEmpty) {
                Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const HomePage(),
                    ),
                    (route) => false);
              } else {
                Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const HomePage(),
                    ),
                    (route) => false);
              }
            });
          });
        },
        verificationFailed: (FirebaseAuthException e) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(e.message.toString()),
              duration: const Duration(seconds: 3),
            ),
          );
        },
        codeSent: (String vID, int? resendToken) {
          setState(() {
            verificationCode = vID;
          });
          if (_pinController.text.isNotEmpty) {
            PhoneAuthCredential cred = PhoneAuthProvider.credential(
              verificationId: vID,
              smsCode: _pinController.text,
            );
            FirebaseAuth.instance.signInWithCredential(cred);
          }
        },
        codeAutoRetrievalTimeout: (String vID) {
          verificationCode = vID;
        },
        timeout: const Duration(seconds: 60),
      );
    } on FirebaseAuthException catch (e) {
      print(e.message);
    }
  }
}
