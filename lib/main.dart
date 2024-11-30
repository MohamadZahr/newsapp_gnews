import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:url_launcher/url_launcher_string.dart';
import 'package:cached_network_image/cached_network_image.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'News App',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
        fontFamily: 'Roboto',
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.blue,
          titleTextStyle: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      home: const NewsListScreen(),
    );
  }
}

class NewsListScreen extends StatefulWidget {
  const NewsListScreen({super.key});

  @override
  State<NewsListScreen> createState() => _NewsListScreenState();
}

class _NewsListScreenState extends State<NewsListScreen> {
  List<dynamic> _newsArticles = [];
  bool _isLoading = true;
  String _error = '';

  Future<void> _fetchNews() async {
    try {
      final response = await http.get(Uri.parse(
          'https://gnews.io/api/v4/top-headlines?token=7ad7eaf3969edeec99e056be4dc98ec3&lang=en'));

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        setState(() {
          _newsArticles = jsonData['articles'];
          _isLoading = false;
        });
      } else {
        setState(() {
          _error = 'Failed to load news. Status code: ${response.statusCode}';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = 'An error occurred: $e';
        _isLoading = false;
      });
    }
  }

  @override
  void initState() {
    super.initState();
    _fetchNews();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    } else if (_error.isNotEmpty) {
      return Center(child: Text('Error: $_error'));
    } else {
      return Scaffold(
        appBar: AppBar(
          title: const Text('News Headlines'),
          flexibleSpace: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.blue.shade700,
                  Colors.blue.shade300,
                ],
              ),
            ),
          ),
        ),
        body: RefreshIndicator(
          onRefresh: _fetchNews,
          child: ListView.builder(
            itemCount: _newsArticles.length,
            itemBuilder: (context, index) {
              final article = _newsArticles[index];
              final imageUrl = article['image'];

              return Card(
                margin: const EdgeInsets.all(8),
                child: InkWell(
                  onTap: () async {
                    final url = article['url'];
                    if (url != null && await canLaunchUrlString(url)) {
                      await launchUrlString(url);
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Could not launch URL')),
                      );
                    }
                  },
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (imageUrl != null && imageUrl.isNotEmpty)
                          CachedNetworkImage(
                            imageUrl: imageUrl,
                            placeholder: (context, url) =>
                                const CircularProgressIndicator(),
                            errorWidget: (context, url, error) =>
                                const Icon(Icons.error),
                            height: 200,
                            width: double.infinity,
                            fit: BoxFit.cover,
                          ),
                        const SizedBox(height: 8),
                        Text(
                          article['title'] ?? 'No Title Available',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          article['source']['name'] ?? 'Unknown Source',
                          style: const TextStyle(fontSize: 14, color: Colors.grey),
                        ),
                        const SizedBox(height: 4),
                        if (article['description'] != null)
                          Text(
                            article['description'],
                            style: const TextStyle(fontSize: 16),
                          ),
                        const SizedBox(height: 8),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      );
    }
  }
}