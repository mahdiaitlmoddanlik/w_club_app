import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';

class SubmissionsPage extends StatefulWidget {
  final String workerName;
  final String serverIp;

  const SubmissionsPage({
    super.key,
    required this.workerName,
    required this.serverIp,
  });

  @override
  _SubmissionsPageState createState() => _SubmissionsPageState();
}

class _SubmissionsPageState extends State<SubmissionsPage> {
  DateTime? _selectedDate;
  List<Map<String, dynamic>>? _allSubmissions;

  Future<void> _selectDate(BuildContext context) async {
    try {
      final DateTime currentDate = DateTime.now();
      final DateTime initialDate = _selectedDate ?? currentDate;

      // Ensure initialDate is within the valid range
      final DateTime safeInitialDate =
          initialDate.isBefore(DateTime(2025)) ? DateTime(2025) : initialDate;

      final DateTime? picked = await showDatePicker(
        context: context,
        initialDate: safeInitialDate,
        firstDate: DateTime(2025), // Starting from 2025
        lastDate: DateTime(2050), // Up to 2050
        builder: (context, child) {
          return Theme(
            data: Theme.of(context).copyWith(
              colorScheme: const ColorScheme.dark(
                primary: Color(0xFFFFD700),
                onPrimary: Colors.black,
                surface: Colors.black,
                onSurface: Colors.white,
              ),
              dialogBackgroundColor: Colors.grey[900],
            ),
            child: child!,
          );
        },
      );

      if (picked != null && picked != _selectedDate) {
        setState(() {
          _selectedDate = picked;
        });
      }
    } catch (e) {
      print('Error in date picker: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Error opening date picker. Please try again.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<List<Map<String, dynamic>>> _getAllSubmissions() async {
    try {
      if (_allSubmissions == null) {
        final response = await http.get(
          Uri.parse('http://${widget.serverIp}/get_publications'),
        );

        if (response.statusCode == 200) {
          final Map<String, dynamic> decodedResponse =
              jsonDecode(response.body);
          if (decodedResponse['status'] == 'success' &&
              decodedResponse['data'] is List) {
            _allSubmissions =
                List<Map<String, dynamic>>.from(decodedResponse['data']);
          } else {
            print('Invalid response format: $decodedResponse');
            return [];
          }
        } else {
          print('Error response: ${response.statusCode} - ${response.body}');
          return [];
        }
      }

      if (_selectedDate != null) {
        return _allSubmissions!.where((submission) {
          try {
            final String? dateStr =
                submission['date'] ?? submission['timestamp'];
            if (dateStr == null) {
              print('No date or timestamp found in submission: $submission');
              return false;
            }

            final DateTime submissionDate = DateTime.parse(dateStr).toLocal();
            return submissionDate.year == _selectedDate!.year &&
                submissionDate.month == _selectedDate!.month &&
                submissionDate.day == _selectedDate!.day;
          } catch (e) {
            print('Error processing submission date: $e');
            return false;
          }
        }).toList();
      }

      return _allSubmissions ?? [];
    } catch (e) {
      print('Exception while fetching submissions: $e');
      return [];
    }
  }

  void _viewPhoto(Map<String, dynamic> submission) {
    try {
      if (!(submission['has_photo'] ?? false)) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text('No photo available for this submission')),
          );
        }
        return;
      }

      final String? photoPath = submission['photo_path'];
      if (photoPath == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Photo path not found')),
          );
        }
        return;
      }

      final String fullUrl = 'http://${widget.serverIp}/uploads/$photoPath';
      print('Debug - Attempting to view photo at: $fullUrl');

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => Scaffold(
            appBar: AppBar(
              title: Text(
                submission['guest_name'] ?? 'Guest Photo',
                style: const TextStyle(color: Color(0xFFFFD700)),
              ),
              backgroundColor: Colors.black,
              iconTheme: const IconThemeData(color: Color(0xFFFFD700)),
            ),
            backgroundColor: Colors.black,
            body: Center(
              child: InteractiveViewer(
                minScale: 0.5,
                maxScale: 4.0,
                child: Image.network(
                  fullUrl,
                  fit: BoxFit.contain,
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CircularProgressIndicator(
                            value: loadingProgress.expectedTotalBytes != null
                                ? loadingProgress.cumulativeBytesLoaded /
                                    loadingProgress.expectedTotalBytes!
                                : null,
                            color: const Color(0xFFFFD700),
                          ),
                          const SizedBox(height: 10),
                          const Text(
                            'Loading image...',
                            style: TextStyle(color: Colors.white),
                          ),
                        ],
                      ),
                    );
                  },
                  errorBuilder: (context, error, stackTrace) {
                    return Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.error_outline,
                          color: Color(0xFFFFD700),
                          size: 48,
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'Failed to load image',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: Text(
                            'URL: $fullUrl',
                            style: const TextStyle(
                              color: Colors.white60,
                              fontSize: 12,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                        const SizedBox(height: 24),
                        ElevatedButton(
                          onPressed: () {
                            Navigator.pop(context);
                            _viewPhoto(submission);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFFFD700),
                            foregroundColor: Colors.black,
                          ),
                          child: const Text('Retry'),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ),
          ),
        ),
      );
    } catch (e) {
      print('Exception in _viewPhoto: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error viewing photo: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            const Text('All Submissions',
                style: TextStyle(color: Color(0xFFFFD700))),
            if (_selectedDate != null) ...[
              const SizedBox(width: 10),
              Text(
                '(${DateFormat('MMM dd').format(_selectedDate!)})',
                style: const TextStyle(color: Color(0xFFFFD700), fontSize: 14),
              ),
            ],
          ],
        ),
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Color(0xFFFFD700)),
        actions: [
          IconButton(
            icon: const Icon(
              Icons.calendar_today,
              color: Color(0xFFFFD700),
            ),
            onPressed: () => _selectDate(context),
          ),
          if (_selectedDate != null)
            IconButton(
              icon: const Icon(
                Icons.clear,
                color: Color(0xFFFFD700),
              ),
              onPressed: () {
                setState(() {
                  _selectedDate = null;
                });
              },
            ),
        ],
      ),
      backgroundColor: Colors.black,
      body: Container(
        width: screenSize.width,
        height: screenSize.height,
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/background.png'),
            fit: BoxFit.cover,
          ),
        ),
        child: FutureBuilder<List<Map<String, dynamic>>>(
          future: _getAllSubmissions(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: CircularProgressIndicator(
                  color: Color(0xFFFFD700),
                ),
              );
            }

            if (snapshot.hasError) {
              return Center(
                child: Text(
                  'Error: ${snapshot.error}',
                  style: const TextStyle(color: Colors.white),
                ),
              );
            }

            final submissions = snapshot.data ?? [];
            final reversedSubmissions = submissions.reversed.toList();

            if (submissions.isEmpty) {
              return Center(
                child: Text(
                  _selectedDate != null
                      ? 'No submissions for ${DateFormat('MMM dd, yyyy').format(_selectedDate!)}'
                      : 'No submissions available',
                  style: const TextStyle(color: Colors.white),
                ),
              );
            }

            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: reversedSubmissions.length,
              itemBuilder: (context, index) {
                final submission = reversedSubmissions[index];
                final String? dateStr =
                    submission['date'] ?? submission['timestamp'];
                final DateTime submissionDate = DateTime.parse(dateStr!);
                final formattedDate =
                    DateFormat('MMM dd, yyyy HH:mm').format(submissionDate);

                // Calculate the correct number (newest submissions get higher numbers)
                final submissionNumber = submissions.length - index;

                return Card(
                  margin: const EdgeInsets.only(bottom: 16),
                  color: Colors.grey[900],
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: const Color(0xFFFFD700),
                      child: Text(
                        '$submissionNumber',
                        style: const TextStyle(
                          color: Colors.black,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    title: Text(
                      submission['guest_name'] ?? 'Unknown Guest',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    subtitle: Text(
                      'Worker: ${submission['worker_name'] ?? 'Unknown'}\nSubmitted: $formattedDate',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.7),
                      ),
                    ),
                    trailing: (submission['has_photo'] ?? false)
                        ? IconButton(
                            icon: const Icon(
                              Icons.image,
                              color: Color(0xFFFFD700),
                            ),
                            onPressed: () => _viewPhoto(submission),
                          )
                        : null,
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}
