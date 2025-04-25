import 'package:flutter/material.dart';
import 'package:flutter_application_1/models/activityhistory.dart';
import 'package:flutter_application_1/services/activityhistoryservice.dart';

class ActivityHistoryDialog extends StatefulWidget {
  final String activityId;

  const ActivityHistoryDialog({
    Key? key,
    required this.activityId,
  }) : super(key: key);

  @override
  _ActivityHistoryDialogState createState() => _ActivityHistoryDialogState();
}

class _ActivityHistoryDialogState extends State<ActivityHistoryDialog> {
  final ActivityHistoryService _historyService = ActivityHistoryService();
  
  List<ActivityHistory> _histories = [];
  int _currentPage = 1;
  int _totalPages = 1;
  bool _isLoading = false;
  String _errorMessage = '';
  String? _expandedHistoryId;

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final response = await _historyService.getHistoryByActivityId(
        widget.activityId,
        page: _currentPage,
        limit: 10,
      );
      
      setState(() {
        _histories = response['histories'];
        _totalPages = response['pages'];
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Error loading activity history';
        _isLoading = false;
      });
      print('Error loading activity history: $e');
    }
  }

  void _changePage(int page) {
    if (page < 1 || page > _totalPages) return;
    setState(() {
      _currentPage = page;
      _expandedHistoryId = null;
    });
    _loadHistory();
  }

  void _toggleHistoryDetails(String historyId) {
    setState(() {
      if (_expandedHistoryId == historyId) {
        _expandedHistoryId = null;
      } else {
        _expandedHistoryId = historyId;
      }
    });
  }

  String _formatChangeType(ChangeType type) {
    switch (type) {
      case ChangeType.create:
        return 'Created';
      case ChangeType.update:
        return 'Updated';
      case ChangeType.delete:
        return 'Deleted';
    }
  }

  Color _getChangeTypeColor(ChangeType type) {
    switch (type) {
      case ChangeType.create:
        return Colors.green;
      case ChangeType.update:
        return Colors.blue;
      case ChangeType.delete:
        return Colors.red;
    }
  }

  String _formatChangedFields(List<String>? fields) {
    if (fields == null || fields.isEmpty) {
      return '-';
    }
    return fields.join(', ');
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16.0),
      ),
      elevation: 0,
      backgroundColor: Colors.transparent,
      child: Container(
        width: double.maxFinite,
        padding: const EdgeInsets.all(16.0),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16.0),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Activity History',
                  style: Theme.of(context).textTheme.headline6,
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            const SizedBox(height: 16.0),
            if (_isLoading)
              const Center(
                child: CircularProgressIndicator(),
              )
            else if (_errorMessage.isNotEmpty)
              Container(
                padding: const EdgeInsets.all(12.0),
                decoration: BoxDecoration(
                  color: Colors.red.shade100,
                  borderRadius: BorderRadius.circular(8.0),
                ),
                child: Text(
                  _errorMessage,
                  style: TextStyle(color: Colors.red.shade800),
                ),
              )
            else if (_histories.isEmpty)
              Container(
                padding: const EdgeInsets.symmetric(vertical: 32.0),
                child: Column(
                  children: const [
                    Icon(
                      Icons.history,
                      size: 64.0,
                      color: Colors.grey,
                    ),
                    SizedBox(height: 16.0),
                    Text(
                      'No history records found for this activity',
                      style: TextStyle(
                        color: Colors.grey,
                        fontSize: 16.0,
                      ),
                    ),
                  ],
                ),
              )
            else
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: _histories.length,
                  itemBuilder: (context, index) {
                    final history = _histories[index];
                    return Container(
                      margin: const EdgeInsets.only(bottom: 8.0),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(8.0),
                        border: Border.all(
                          color: Colors.grey.shade300,
                        ),
                      ),
                      child: Column(
                        children: [
                          ListTile(
                            leading: CircleAvatar(
                              backgroundColor: _getChangeTypeColor(history.changeType).withOpacity(0.2),
                              child: Icon(
                                _getHistoryIcon(history.changeType),
                                color: _getChangeTypeColor(history.changeType),
                              ),
                            ),
                            title: Text(
                              _formatChangeType(history.changeType),
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _formatDateTime(history.timestamp),
                                  style: const TextStyle(fontSize: 12.0),
                                ),
                                if (history.changedFields != null && history.changedFields!.isNotEmpty)
                                  Text(
                                    'Changed: ${_formatChangedFields(history.changedFields)}',
                                    style: const TextStyle(fontSize: 12.0),
                                  ),
                              ],
                            ),
                            trailing: IconButton(
                              icon: Icon(
                                _expandedHistoryId == history.id
                                    ? Icons.keyboard_arrow_up
                                    : Icons.keyboard_arrow_down,
                              ),
                              onPressed: () => _toggleHistoryDetails(history.id),
                            ),
                          ),
                          if (_expandedHistoryId == history.id)
                            Container(
                              padding: const EdgeInsets.all(16.0),
                              decoration: BoxDecoration(
                                color: Colors.grey.shade100,
                                borderRadius: const BorderRadius.only(
                                  bottomLeft: Radius.circular(8.0),
                                  bottomRight: Radius.circular(8.0),
                                ),
                              ),
                              child: _buildHistoryDetails(history),
                            ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            if (_totalPages > 1)
              Padding(
                padding: const EdgeInsets.only(top: 16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.chevron_left),
                      onPressed: _currentPage > 1
                          ? () => _changePage(_currentPage - 1)
                          : null,
                    ),
                    Text(
                      '$_currentPage / $_totalPages',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.chevron_right),
                      onPressed: _currentPage < _totalPages
                          ? () => _changePage(_currentPage + 1)
                          : null,
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  IconData _getHistoryIcon(ChangeType type) {
    switch (type) {
      case ChangeType.create:
        return Icons.add_circle_outline;
      case ChangeType.update:
        return Icons.edit_outlined;
      case ChangeType.delete:
        return Icons.delete_outline;
    }
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.day}/${dateTime.month}/${dateTime.year} ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  Widget _buildHistoryDetails(ActivityHistory history) {
    switch (history.changeType) {
      case ChangeType.create:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Activity Created:',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14.0,
              ),
            ),
            const SizedBox(height: 8.0),
            _buildJsonViewer(history.newValues),
          ],
        );
      case ChangeType.update:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Changes:',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14.0,
              ),
            ),
            const SizedBox(height: 8.0),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Before:',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 12.0,
                        ),
                      ),
                      const SizedBox(height: 4.0),
                      _buildJsonViewer(history.previousValues),
                    ],
                  ),
                ),
                const SizedBox(width: 16.0),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'After:',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 12.0,
                        ),
                      ),
                      const SizedBox(height: 4.0),
                      _buildJsonViewer(history.newValues),
                    ],
                  ),
                ),
              ],
            ),
          ],
        );
      case ChangeType.delete:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Activity Deleted:',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14.0,
              ),
            ),
            const SizedBox(height: 8.0),
            _buildJsonViewer(history.previousValues),
          ],
        );
    }
  }

  Widget _buildJsonViewer(Map<String, dynamic>? json) {
    if (json == null) {
      return const Text('No data available');
    }

    // Filter out large arrays or complex objects to simplify the view
    final simplifiedJson = Map<String, dynamic>.from(json);
    simplifiedJson.forEach((key, value) {
      if (value is List && value.length > 3) {
        simplifiedJson[key] = '[Array with ${value.length} items]';
      } else if (value is Map && value.length > 5) {
        simplifiedJson[key] = '{Object with ${value.length} properties}';
      }
    });

    return Container(
      padding: const EdgeInsets.all(8.0),
      decoration: BoxDecoration(
        color: Colors.grey.shade200,
        borderRadius: BorderRadius.circular(4.0),
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: simplifiedJson.entries.map((entry) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 2.0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${entry.key}: ',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 12.0,
                    ),
                  ),
                  Expanded(
                    child: Text(
                      _formatJsonValue(entry.value),
                      style: const TextStyle(fontSize: 12.0),
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  String _formatJsonValue(dynamic value) {
    if (value == null) {
      return 'null';
    } else if (value is String) {
      // Format date strings if they look like ISO 8601
      if (value.contains('T') && value.endsWith('Z')) {
        try {
          final date = DateTime.parse(value);
          return _formatDateTime(date);
        } catch (_) {
          return value;
        }
      }
      return value;
    } else if (value is Map) {
      return '{${value.length} properties}';
    } else if (value is List) {
      return '[${value.length} items]';
    } else {
      return value.toString();
    }
  }
}

extension on TextTheme {
  get headline6 => null;
}