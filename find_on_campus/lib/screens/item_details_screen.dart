import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/item.dart';
import '../models/user.dart';
import '../services/auth_service.dart';
import '../services/item_service.dart';

class ItemDetailsScreen extends StatefulWidget {
  final String itemId;
  
  const ItemDetailsScreen({super.key, required this.itemId});

  @override
  State<ItemDetailsScreen> createState() => _ItemDetailsScreenState();
}

class _ItemDetailsScreenState extends State<ItemDetailsScreen> {
  final ItemService _itemService = ItemService();
  final AuthService _authService = AuthService();
  bool _isLoading = true;
  Item? _item;
  List<Item> _matchingItems = [];
  AppUser? _itemOwner;
  bool _isCurrentUserOwner = false;

  @override
  void initState() {
    super.initState();
    _loadItemDetails();
  }

  Future<void> _loadItemDetails() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Get item details
      final item = await _itemService.getItemById(widget.itemId);
      
      if (item != null) {
        // Check if current user is the owner
        final currentUser = _authService.currentUser;
        final isOwner = currentUser != null && currentUser.uid == item.userId;
        
        // Get matching items if any
        List<Item> matchingItems = [];
        if (item.matchingItemIds != null && item.matchingItemIds!.isNotEmpty) {
          for (final id in item.matchingItemIds!) {
            final matchingItem = await _itemService.getItemById(id);
            if (matchingItem != null) {
              matchingItems.add(matchingItem);
            }
          }
        }
        
        // Get item owner details
        AppUser? owner;
        try {
          owner = await _authService.getUserById(item.userId);
        } catch (e) {
          print('Error getting item owner: $e');
        }
        
        // Update state
        setState(() {
          _item = item;
          _matchingItems = matchingItems;
          _itemOwner = owner;
          _isCurrentUserOwner = isOwner;
          _isLoading = false;
        });
      } else {
        // Item not found
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Item not found')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      print('Error loading item details: $e');
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading item details: $e')),
      );
    }
  }

  Future<void> _updateItemStatus(ItemStatus newStatus) async {
    setState(() {
      _isLoading = true;
    });

    try {
      await _itemService.updateItemStatus(widget.itemId, newStatus);
      
      // Reload item details
      await _loadItemDetails();
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Item status updated to ${newStatus.toString().split('.').last}')),
      );
    } catch (e) {
      print('Error updating item status: $e');
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error updating item status: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Item Details')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_item == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Item Details')),
        body: const Center(child: Text('Item not found')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(_item!.type == ItemType.lost ? 'Lost Item' : 'Found Item'),
        actions: _isCurrentUserOwner
            ? [
                PopupMenuButton<String>(
                  onSelected: (value) {
                    if (value == 'delete') {
                      _showDeleteConfirmation();
                    }
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'delete',
                      child: Text('Delete'),
                    ),
                  ],
                ),
              ]
            : null,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Item image
            if (_item!.photoUrl != null)
              Image.network(
                _item!.photoUrl!,
                height: 250,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    height: 250,
                    width: double.infinity,
                    color: Colors.grey[300],
                    child: const Icon(Icons.image_not_supported, size: 50),
                  );
                },
              ),
            
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Status and type indicators
                  Row(
                    children: [
                      _buildTypeChip(_item!.type),
                      const SizedBox(width: 8),
                      _buildStatusChip(_item!.status),
                    ],
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Title
                  Text(
                    _item!.title,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  
                  const SizedBox(height: 8),
                  
                  // Category
                  _buildInfoRow(Icons.category, 'Category', _item!.category),
                  
                  // Location
                  _buildInfoRow(Icons.location_on, 'Location', _item!.location),
                  
                  // Date
                  _buildInfoRow(
                    Icons.calendar_today,
                    _item!.type == ItemType.lost ? 'Date Lost' : 'Date Found',
                    DateFormat('MMMM d, yyyy').format(_item!.date),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Description
                  const Text(
                    'Description',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(_item!.description),
                  
                  const SizedBox(height: 24),
                  
                  // Reported by
                  if (_itemOwner != null)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Reported by',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            CircleAvatar(
                              radius: 20,
                              backgroundImage: _itemOwner!.photoUrl != null
                                  ? NetworkImage(_itemOwner!.photoUrl!)
                                  : null,
                              child: _itemOwner!.photoUrl == null
                                  ? Text(_itemOwner!.displayName[0].toUpperCase())
                                  : null,
                            ),
                            const SizedBox(width: 12),
                            Text(
                              _itemOwner!.displayName,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  
                  const SizedBox(height: 24),
                  
                  // Status update buttons (only for item owner)
                  if (_isCurrentUserOwner) ...[
                    const Text(
                      'Update Status',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            onPressed: _item!.status != ItemStatus.pending
                                ? () => _updateItemStatus(ItemStatus.pending)
                                : null,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.orange,
                              foregroundColor: Colors.white,
                            ),
                            child: const Text('Pending'),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: _item!.status != ItemStatus.resolved
                                ? () => _updateItemStatus(ItemStatus.resolved)
                                : null,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                              foregroundColor: Colors.white,
                            ),
                            child: const Text('Resolved'),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: _item!.status != ItemStatus.claimed
                                ? () => _updateItemStatus(ItemStatus.claimed)
                                : null,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue,
                              foregroundColor: Colors.white,
                            ),
                            child: const Text('Claimed'),
                          ),
                        ),
                      ],
                    ),
                  ],
                  
                  const SizedBox(height: 24),
                  
                  // Potential Matches
                  if (_matchingItems.isNotEmpty) ...[
                    const Text(
                      'Potential Matches',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _matchingItems.length,
                      itemBuilder: (context, index) {
                        final matchingItem = _matchingItems[index];
                        return Card(
                          margin: const EdgeInsets.only(bottom: 8),
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: matchingItem.type == ItemType.lost 
                                  ? Colors.red[700] 
                                  : Colors.green[700],
                              child: Icon(
                                matchingItem.type == ItemType.lost
                                    ? Icons.search
                                    : Icons.check_circle,
                                color: Colors.white,
                              ),
                            ),
                            title: Text(matchingItem.title),
                            subtitle: Text(
                              '${matchingItem.category} • ${DateFormat('MMM d').format(matchingItem.date)}',
                            ),
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => ItemDetailsScreen(
                                    itemId: matchingItem.id,
                                  ),
                                ),
                              ).then((_) => _loadItemDetails());
                            },
                          ),
                        );
                      },
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: !_isCurrentUserOwner && _item!.status == ItemStatus.pending
          ? FloatingActionButton.extended(
              onPressed: () {
                // Show contact info or messaging option
                _showContactOwnerDialog();
              },
              icon: const Icon(Icons.message),
              label: const Text('Contact'),
            )
          : null,
    );
  }

  Widget _buildTypeChip(ItemType type) {
    final isLost = type == ItemType.lost;
    return Chip(
      label: Text(
        isLost ? 'LOST' : 'FOUND',
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
        ),
      ),
      backgroundColor: isLost ? Colors.red[700] : Colors.green[700],
      padding: const EdgeInsets.symmetric(horizontal: 8),
    );
  }

  Widget _buildStatusChip(ItemStatus status) {
    Color backgroundColor;
    String label;
    
    switch (status) {
      case ItemStatus.pending:
        backgroundColor = Colors.orange;
        label = 'PENDING';
      case ItemStatus.resolved:
        backgroundColor = Colors.green;
        label = 'RESOLVED';
      case ItemStatus.claimed:
        backgroundColor = Colors.blue;
        label = 'CLAIMED';
    }
    
    return Chip(
      label: Text(
        label,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
        ),
      ),
      backgroundColor: backgroundColor,
      padding: const EdgeInsets.symmetric(horizontal: 8),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            size: 20,
            color: Colors.grey[700],
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showDeleteConfirmation() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Item'),
        content: const Text(
          'Are you sure you want to delete this item? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('CANCEL'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              
              try {
                await _itemService.deleteItem(
                  widget.itemId,
                  _authService.currentUser!.uid,
                );
                
                if (!mounted) return;
                
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Item deleted successfully')),
                );
                
                Navigator.pop(context);
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Error deleting item: $e')),
                );
              }
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('DELETE'),
          ),
        ],
      ),
    );
  }

  void _showContactOwnerDialog() {
    if (_itemOwner == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Owner information not available')),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Contact Information'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Name: ${_itemOwner!.displayName}'),
            const SizedBox(height: 8),
            Text('Email: ${_itemOwner!.email}'),
            const SizedBox(height: 16),
            const Text(
              'Please contact the person who reported this item for more information.',
              style: TextStyle(fontSize: 14),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('CLOSE'),
          ),
        ],
      ),
    );
  }
}