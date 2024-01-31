import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class HomePage extends StatefulWidget {
  const HomePage({required key}) : super(key: key);

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final String _baseUrl = "https://jsonplaceholder.typicode.com/posts";
  int _page = 0;
  final int _limit = 20;
  bool _isFirstLoadRunning = false;
  bool _hasNextPage = true;
  bool _isLoadMoreRunning = false;
  late ScrollController _controller;

  List _posts = [];

  void _loadMore() async {
    if (_hasNextPage &&
        !_isFirstLoadRunning &&
        !_isLoadMoreRunning &&
        _controller.position.maxScrollExtent - _controller.position.pixels <
            50) {
      setState(() {
        _isLoadMoreRunning = true;
      });
      _page += 1;

      try {
        final res =
            await http.get(Uri.parse("$_baseUrl?_page=$_page&_limit=$_limit"));
        final List fetchedPosts = json.decode(res.body);
        if (fetchedPosts.isNotEmpty) {
          setState(() {
            _posts.addAll(fetchedPosts);
            _isLoadMoreRunning = false;
          });
        } else {
          setState(() {
            _hasNextPage = false;
            _isLoadMoreRunning = false;
          });
        }
      } catch (err) {
        if (kDebugMode) {
          print("Something Went Wrong");
        }
        print('Error: $err');
        setState(() {
          _isLoadMoreRunning = false;
        });
      }
    }
  }

  @override
  void initState() {
    super.initState();
    _firstLoad();
    _controller = ScrollController()..addListener(_loadMore);
  }

  void _firstLoad() async {
    setState(() {
      _isFirstLoadRunning = true;
    });

    try {
      final response =
          await http.get(Uri.parse("$_baseUrl?_page=$_page&_limit=$_limit"));
      if (response.statusCode == 200) {
        setState(() {
          _posts = json.decode(response.body);
          _isFirstLoadRunning = false;
        });
      } else {
        throw Exception('Failed to load data');
      }
    } catch (err) {
      print('Error: $err');
      setState(() {
        _isFirstLoadRunning = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Posts'),
      ),
      body: _isFirstLoadRunning
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : Column(
              children: [
                Expanded(
                  child: ListView.builder(
                    itemCount: _posts.length,
                    controller: _controller,
                    itemBuilder: (_, index) => Card(
                      margin: const EdgeInsets.symmetric(
                          vertical: 8, horizontal: 10),
                      child: ListTile(
                        title: Text(_posts[index]['title']),
                        subtitle: Text(_posts[index]['body']),
                      ),
                    ),
                  ),
                ),
                if (_isLoadMoreRunning == true)
                  Container(
                      padding: const EdgeInsets.only(top: 10, bottom: 40),
                      color: Colors.blueGrey,
                      child:
                          const Center(child: CircularProgressIndicator()), // Or any other widget you want to display
                    
                  ),
                if (_hasNextPage == false)
                  Container(
                        padding: const EdgeInsets.only( bottom: 40),
                        color: Colors.green,
                        child: const Center(
                          child: Text(
                              "You have fetched all the data"),
                        ) // Or any other widget you want to display
                        ),
              ],
            ),
    );
  }
}
