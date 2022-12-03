import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import 'models/item.dart';
import 'models/tag.dart';
import 'models/user.dart';

class QiitaRepository {
  final clientId = '5cc4a5c98f7dbf2e338b90c1242d048b74933000';
  final clientSecret = '';
  final keyAccessToken = 'qiita/accessToken';

  String createAuthorizeUrl(String state) {
    final scope = 'read_qiita';
    return 'https://qiita.com/api/v2/oauth/authorize?client_id=$clientId&scope=$scope&state=$state';
  }

  Future<String> createAccessTokenFromCallbackUri(
    Uri uri,
    String expectedState,
  ) async {
    final String state = uri.queryParameters['state'];
    final String code = uri.queryParameters['code'];
    if (expectedState != state) {
      throw Exception('The state is different from expectedState');
    }

    final response =
        await http.post(Uri.parse('https://qiita.com/api/v2/access_tokens'),
            headers: {
              'content-type': 'application/json',
            },
            body: jsonEncode({
              'client_id': clientId,
              'client_secret': clientSecret,
              'code': code,
            }));
    final body = jsonDecode(response.body);
    final accessToken = body['token'];

    return accessToken;
  }

  Future<void> revokeSavedAccessToken() async {
    final accessToken = await getAccessToken();
  }

  Future<String> getAccessToken() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString(keyAccessToken);
  }

  Future<void> setAccessToken(String accessToken) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString(keyAccessToken, accessToken);
  }

  Future<void> deleteAccessToken() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.remove(keyAccessToken);
  }

  Future<bool> isAccessTokenSaved() async {
    final accessToken = await getAccessToken();
    return accessToken != null;
  }

  Future<List<Item>> getItemList({int page = 1, QiitaItemsQuery query}) async {
    final accessToken = await getAccessToken();
    String url = 'https://qiita.com/api/v2/items?page=$page';
    if (query != null) {
      url += '&query=${query.buildString()}';
    }

    final response = await http.get(
      Uri.parse(url),
      headers: {
        'Authorization': 'Bearer $accessToken',
      },
    );
    final body = jsonDecode(response.body);
    final itemList = (body as List<dynamic>)
        .map((item) => Item(
              id: item['id'],
              title: item['title'],
              renderedBody: item['rendered_body'],
              likesCount: item['likes_count'],
              createdAt: DateTime.parse(item['created_at']),
              tags: (item['tags'] as List<dynamic>).map((tag) {
                return Tag(
                  name: tag['name'],
                  versions: (tag['versions'] as List<dynamic>)
                      .map((v) => v as String)
                      .toList(),
                );
              }).toList(),
              user: _mapToUser(item['user']),
            ))
        .toList();

    return itemList;
  }

  User _mapToUser(Map<String, dynamic> map) {
    return User(
      id: map['id'],
      name: map['name'],
      description: map['description'],
      profileImageUrl: map['profile_image_url'],
      itemsCount: map['items_count'],
      followersCount: map['followers_count'],
    );
  }

  Future<User> getAuthenticatedUser() async {
    final accessToken = await getAccessToken();
    final response = await http.get(
      Uri.parse('https://qiita.com/api/v2/authenticated_user'),
      headers: {
        'Authorization': 'Bearer $accessToken',
      },
    );
    final body = jsonDecode(response.body);
    final user = _mapToUser(body);

    return user;
  }
}

class QiitaItemsQuery {
  String userId;

  QiitaItemsQuery userIdEquals(String id) {
    userId = id;
    return this;
  }

  String buildString() {
    List<String> queries = [];

    if (userId != null) {
      queries.add('user:$userId');
    }

    return queries.join(' ');
  }
}
