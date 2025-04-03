import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/item.dart';
import '../utils/app_theme.dart';

class ItemCard extends StatelessWidget {
  final Item item;
  final VoidCallback onTap;

  const ItemCard({
    super.key,
    required this.item,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isLost = item.type == ItemType.lost;
    final statusColor = _getStatusColor();
    
    return Hero(
      tag: 'item-${item.id}',
      child: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: (isLost ? AppTheme.lostItemColor : AppTheme.foundItemColor).withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Card(
          margin: EdgeInsets.zero,
          clipBehavior: Clip.antiAlias,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Item image with status indicator overlay
                Stack(
                  children: [
                    // Item image (if available)
                    if (item.photoUrl != null)
                      SizedBox(
                        height: 150,
                        width: double.infinity,
                        child: Image.network(
                          item.photoUrl!,
                          fit: BoxFit.cover,
                          loadingBuilder: (context, child, loadingProgress) {
                            if (loadingProgress == null) return child;
                            return Container(
                              height: 150,
                              color: Colors.grey[200],
                              child: Center(
                                child: CircularProgressIndicator(
                                  value: loadingProgress.expectedTotalBytes != null
                                      ? loadingProgress.cumulativeBytesLoaded /
                                          (loadingProgress.expectedTotalBytes ?? 1)
                                      : null,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                      isLost ? AppTheme.lostItemColor : AppTheme.foundItemColor),
                                ),
                              ),
                            );
                          },
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              height: 150,
                              width: double.infinity,
                              color: Colors.grey[200],
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    isLost ? Icons.search : Icons.check_circle,
                                    size: 40,
                                    color: isLost ? AppTheme.lostItemColor : AppTheme.foundItemColor,
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    isLost ? 'Lost Item' : 'Found Item',
                                    style: TextStyle(
                                      color: isLost ? AppTheme.lostItemColor : AppTheme.foundItemColor,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      )
                    else
                      Container(
                        height: 120,
                        width: double.infinity,
                        color: (isLost ? AppTheme.lostItemColor : AppTheme.foundItemColor).withOpacity(0.1),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              isLost ? Icons.search : Icons.check_circle,
                              size: 40,
                              color: isLost ? AppTheme.lostItemColor : AppTheme.foundItemColor,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              isLost ? 'Lost Item' : 'Found Item',
                              style: TextStyle(
                                color: isLost ? AppTheme.lostItemColor : AppTheme.foundItemColor,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    
                    // Type indicator badge
                    Positioned(
                      top: 12,
                      left: 12,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: isLost ? AppTheme.lostItemColor : AppTheme.foundItemColor,
                          borderRadius: BorderRadius.circular(30),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Text(
                          isLost ? 'LOST' : 'FOUND',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    
                    // Status indicator
                    Positioned(
                      top: 12,
                      right: 12,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: statusColor,
                          borderRadius: BorderRadius.circular(30),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Text(
                          _getStatusText(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                
                // Content
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Title
                      Text(
                        item.title,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textPrimary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      
                      const SizedBox(height: 12),
                      
                      // Info section with icons
                      Row(
                        children: [
                          // Category
                          _buildInfoItem(
                            Icons.category_rounded,
                            item.category,
                            isLost ? AppTheme.lostItemColor : AppTheme.foundItemColor,
                          ),
                          
                          const SizedBox(width: 16),
                          
                          // Date
                          _buildInfoItem(
                            Icons.calendar_today_rounded,
                            DateFormat('MMM d, yyyy').format(item.date),
                            isLost ? AppTheme.lostItemColor : AppTheme.foundItemColor,
                          ),
                        ],
                      ),
                      
                      const SizedBox(height: 8),
                      
                      // Location
                      _buildInfoItem(
                        Icons.location_on_rounded,
                        item.location,
                        isLost ? AppTheme.lostItemColor : AppTheme.foundItemColor,
                        showDivider: false,
                      ),
                      
                      // Description preview
                      if (item.description.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 12),
                          child: Text(
                            item.description.length > 80
                                ? '${item.description.substring(0, 80)}...'
                                : item.description,
                            style: const TextStyle(
                              fontSize: 14,
                              color: AppTheme.textSecondary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                    ],
                  ),
                ),
                
                // View details button
                Container(
                  width: double.infinity,
                  height: 40,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        isLost ? AppTheme.lostItemColor : AppTheme.foundItemColor,
                        isLost 
                            ? AppTheme.lostItemColor.withOpacity(0.8) 
                            : AppTheme.foundItemColor.withOpacity(0.8),
                      ],
                    ),
                  ),
                  child: const Center(
                    child: Text(
                      'View Details',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoItem(IconData icon, String text, Color color, {bool showDivider = true}) {
    return Row(
      children: [
        Icon(
          icon, 
          size: 16, 
          color: color,
        ),
        const SizedBox(width: 4),
        Flexible(
          child: Text(
            text,
            style: const TextStyle(
              fontSize: 14,
              color: AppTheme.textSecondary,
            ),
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
          ),
        ),
      ],
    );
  }

  Color _getStatusColor() {
    switch (item.status) {
      case ItemStatus.pending:
        return AppTheme.warningColor;
      case ItemStatus.resolved:
        return AppTheme.foundItemColor;
      case ItemStatus.claimed:
        return AppTheme.accentColor;
    }
  }
  
  String _getStatusText() {
    switch (item.status) {
      case ItemStatus.pending:
        return 'PENDING';
      case ItemStatus.resolved:
        return 'RESOLVED';
      case ItemStatus.claimed:
        return 'CLAIMED';
    }
  }
}