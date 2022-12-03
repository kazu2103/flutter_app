import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:package_info/package_info.dart';
import 'package:uni_links/uni_links.dart';
import 'package:url_launcher/url_launcher.dart';

import '../qiita_repository.dart';
// import 'item_list_screen.dart';


class SignInScreen extends StatefulWidget {
  @override
  _SignInScreenState createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen> {
  final QiitaRepository repository = QiitaRepository();
}