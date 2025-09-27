import 'package:flutter/material.dart';

/// Notification types with predefined styling
enum NotificationType {
  success,
  error,
  warning,
  info,
}

/// A custom notification widget that displays at the top right of the screen
class CustomNotification extends StatefulWidget {
  final String message;
  final String? title;
  final NotificationType type;
  final Color? backgroundColor;
  final Color? textColor;
  final IconData? icon;
  final Duration duration;
  final VoidCallback? onDismiss;
  final bool showProgressBar;

  const CustomNotification({
    super.key,
    required this.message,
    this.title,
    this.type = NotificationType.info,
    this.backgroundColor,
    this.textColor,
    this.icon,
    this.duration = const Duration(seconds: 4),
    this.onDismiss,
    this.showProgressBar = true,
  });

  @override
  State<CustomNotification> createState() => _CustomNotificationState();
}

class _CustomNotificationState extends State<CustomNotification>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late AnimationController _progressController;
  late Animation<double> _slideAnimation;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<double> _progressAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );

    _progressController = AnimationController(
      duration: widget.duration,
      vsync: this,
    );

    _slideAnimation = Tween<double>(
      begin: 1.0,
      end: 0.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.elasticOut,
    ));

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
    ));

    _scaleAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: const Interval(0.0, 0.6, curve: Curves.elasticOut),
    ));

    _progressAnimation = Tween<double>(
      begin: 1.0,
      end: 0.0,
    ).animate(CurvedAnimation(
      parent: _progressController,
      curve: Curves.linear,
    ));

    _animationController.forward();
    _progressController.forward();

    // Auto dismiss after duration
    Future.delayed(widget.duration, () {
      if (mounted) {
        _dismiss();
      }
    });
  }

  void _dismiss() {
    _animationController.reverse().then((_) {
      if (mounted) {
        widget.onDismiss?.call();
      }
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    _progressController.dispose();
    super.dispose();
  }

  /// Get notification styling based on type
  _NotificationStyle _getNotificationStyle() {
    switch (widget.type) {
      case NotificationType.success:
        return _NotificationStyle(
          backgroundColor: const Color(0xFF10B981),
          lightBackgroundColor: const Color(0xFFD1FAE5),
          textColor: Colors.white,
          lightTextColor: const Color(0xFF065F46),
          icon: Icons.check_circle_rounded,
          gradient: const LinearGradient(
            colors: [Color(0xFF10B981), Color(0xFF059669)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        );
      case NotificationType.error:
        return _NotificationStyle(
          backgroundColor: const Color(0xFFEF4444),
          lightBackgroundColor: const Color(0xFFFEE2E2),
          textColor: Colors.white,
          lightTextColor: const Color(0xFF991B1B),
          icon: Icons.error_rounded,
          gradient: const LinearGradient(
            colors: [Color(0xFFEF4444), Color(0xFFDC2626)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        );
      case NotificationType.warning:
        return _NotificationStyle(
          backgroundColor: const Color(0xFFF59E0B),
          lightBackgroundColor: const Color(0xFFFEF3C7),
          textColor: Colors.white,
          lightTextColor: const Color(0xFF92400E),
          icon: Icons.warning_rounded,
          gradient: const LinearGradient(
            colors: [Color(0xFFF59E0B), Color(0xFFD97706)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        );
      case NotificationType.info:
        return _NotificationStyle(
          backgroundColor: const Color(0xFF3B82F6),
          lightBackgroundColor: const Color(0xFFDBEAFE),
          textColor: Colors.white,
          lightTextColor: const Color(0xFF1E40AF),
          icon: Icons.info_rounded,
          gradient: const LinearGradient(
            colors: [Color(0xFF3B82F6), Color(0xFF2563EB)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final style = _getNotificationStyle();
    final effectiveBackgroundColor =
        widget.backgroundColor ?? style.backgroundColor;
    final effectiveTextColor = widget.textColor ?? style.textColor;
    final effectiveIcon = widget.icon ?? style.icon;
    final theme = Theme.of(context);

    return AnimatedBuilder(
      animation: Listenable.merge([_animationController, _progressController]),
      builder: (context, child) {
        return Positioned(
          top: MediaQuery.of(context).padding.top + 16,
          right: 16,
          child: Transform.translate(
            offset: Offset(_slideAnimation.value * 400, 0),
            child: Transform.scale(
              scale: _scaleAnimation.value,
              child: Opacity(
                opacity: _fadeAnimation.value,
                child: Material(
                  elevation: 0,
                  color: Colors.transparent,
                  child: Container(
                    constraints: const BoxConstraints(
                      maxWidth: 260,
                      minWidth: 220,
                    ),
                    decoration: BoxDecoration(
                      gradient: widget.backgroundColor == null
                          ? style.gradient
                          : null,
                      color: widget.backgroundColor != null
                          ? effectiveBackgroundColor
                          : null,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: effectiveBackgroundColor.withOpacity(0.3),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                          spreadRadius: 0,
                        ),
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                          spreadRadius: 0,
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: Stack(
                        children: [
                          // Main content
                          Container(
                            padding: const EdgeInsets.all(10),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    // Icon with background
                                    Container(
                                      padding: const EdgeInsets.all(4),
                                      decoration: BoxDecoration(
                                        color:
                                            effectiveTextColor.withOpacity(0.2),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Icon(
                                        effectiveIcon,
                                        color: effectiveTextColor,
                                        size: 20,
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    // Title and message
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          if (widget.title != null) ...[
                                            Text(
                                              widget.title!,
                                              style: theme.textTheme.titleMedium
                                                  ?.copyWith(
                                                color: effectiveTextColor,
                                                fontWeight: FontWeight.w600,
                                                letterSpacing: -0.2,
                                              ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                            const SizedBox(height: 4),
                                          ],
                                          Text(
                                            widget.message,
                                            style: theme.textTheme.bodyMedium
                                                ?.copyWith(
                                              color: effectiveTextColor
                                                  .withOpacity(0.9),
                                              fontWeight: FontWeight.w400,
                                              height: 1.4,
                                              letterSpacing: -0.1,
                                            ),
                                            maxLines: 3,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    // Close button
                                    Material(
                                      color: Colors.transparent,
                                      child: InkWell(
                                        onTap: _dismiss,
                                        borderRadius: BorderRadius.circular(8),
                                        child: Container(
                                          padding: const EdgeInsets.all(3),
                                          decoration: BoxDecoration(
                                            color: effectiveTextColor
                                                .withOpacity(0.1),
                                            borderRadius:
                                                BorderRadius.circular(8),
                                          ),
                                          child: Icon(
                                            Icons.close_rounded,
                                            color: effectiveTextColor
                                                .withOpacity(0.7),
                                            size: 16,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                // Progress bar
                                if (widget.showProgressBar) ...[
                                  const SizedBox(height: 8),
                                  Container(
                                    height: 3,
                                    decoration: BoxDecoration(
                                      color:
                                          effectiveTextColor.withOpacity(0.2),
                                      borderRadius: BorderRadius.circular(2),
                                    ),
                                    child: FractionallySizedBox(
                                      alignment: Alignment.centerLeft,
                                      widthFactor: _progressAnimation.value,
                                      child: Container(
                                        decoration: BoxDecoration(
                                          color: effectiveTextColor
                                              .withOpacity(0.8),
                                          borderRadius:
                                              BorderRadius.circular(2),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                          // Subtle border
                          Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: effectiveTextColor.withOpacity(0.1),
                                width: 1,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

/// Internal class for notification styling
class _NotificationStyle {
  final Color backgroundColor;
  final Color lightBackgroundColor;
  final Color textColor;
  final Color lightTextColor;
  final IconData icon;
  final LinearGradient gradient;

  const _NotificationStyle({
    required this.backgroundColor,
    required this.lightBackgroundColor,
    required this.textColor,
    required this.lightTextColor,
    required this.icon,
    required this.gradient,
  });
}

/// A notification overlay that manages multiple notifications
class NotificationOverlay extends StatefulWidget {
  final Widget child;
  final List<CustomNotification> notifications;

  const NotificationOverlay({
    Key? key,
    required this.child,
    this.notifications = const [],
  }) : super(key: key);

  @override
  State<NotificationOverlay> createState() => _NotificationOverlayState();
}

class _NotificationOverlayState extends State<NotificationOverlay> {
  final List<CustomNotification> _notifications = [];

  void showNotification({
    required String message,
    String? title,
    NotificationType type = NotificationType.info,
    Color? backgroundColor,
    Color? textColor,
    IconData? icon,
    Duration duration = const Duration(seconds: 4),
    bool showProgressBar = true,
  }) {
    late final CustomNotification notification;
    notification = CustomNotification(
      message: message,
      title: title,
      type: type,
      backgroundColor: backgroundColor,
      textColor: textColor,
      icon: icon,
      duration: duration,
      showProgressBar: showProgressBar,
      onDismiss: () {
        setState(() {
          _notifications.remove(notification);
        });
      },
    );

    setState(() {
      _notifications.add(notification);
    });
  }

  // Convenience methods for different notification types
  void showSuccessNotification({
    required String message,
    String? title,
    Duration duration = const Duration(seconds: 3),
  }) {
    showNotification(
      message: message,
      title: title,
      type: NotificationType.success,
      duration: duration,
    );
  }

  void showErrorNotification({
    required String message,
    String? title,
    Duration duration = const Duration(seconds: 5),
  }) {
    showNotification(
      message: message,
      title: title,
      type: NotificationType.error,
      duration: duration,
    );
  }

  void showWarningNotification({
    required String message,
    String? title,
    Duration duration = const Duration(seconds: 4),
  }) {
    showNotification(
      message: message,
      title: title,
      type: NotificationType.warning,
      duration: duration,
    );
  }

  void showInfoNotification({
    required String message,
    String? title,
    Duration duration = const Duration(seconds: 4),
  }) {
    showNotification(
      message: message,
      title: title,
      type: NotificationType.info,
      duration: duration,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        widget.child,
        ..._notifications,
      ],
    );
  }
}

/// Extension to easily show notifications from any widget
extension NotificationExtension on BuildContext {
  void showCustomNotification({
    required String message,
    String? title,
    NotificationType type = NotificationType.info,
    Color? backgroundColor,
    Color? textColor,
    IconData? icon,
    Duration duration = const Duration(seconds: 4),
    bool showProgressBar = true,
  }) {
    final overlay = Overlay.of(this);
    late final OverlayEntry overlayEntry;
    overlayEntry = OverlayEntry(
      builder: (context) => CustomNotification(
        message: message,
        title: title,
        type: type,
        backgroundColor: backgroundColor,
        textColor: textColor,
        icon: icon,
        duration: duration,
        showProgressBar: showProgressBar,
        onDismiss: () {
          overlayEntry.remove();
        },
      ),
    );

    overlay.insert(overlayEntry);
  }

  // Convenience methods for different notification types
  void showSuccessNotification({
    required String message,
    String? title,
    Duration duration = const Duration(seconds: 3),
  }) {
    showCustomNotification(
      message: message,
      title: title,
      type: NotificationType.success,
      duration: duration,
    );
  }

  void showErrorNotification({
    required String message,
    String? title,
    Duration duration = const Duration(seconds: 5),
  }) {
    showCustomNotification(
      message: message,
      title: title,
      type: NotificationType.error,
      duration: duration,
    );
  }

  void showWarningNotification({
    required String message,
    String? title,
    Duration duration = const Duration(seconds: 4),
  }) {
    showCustomNotification(
      message: message,
      title: title,
      type: NotificationType.warning,
      duration: duration,
    );
  }

  void showInfoNotification({
    required String message,
    String? title,
    Duration duration = const Duration(seconds: 4),
  }) {
    showCustomNotification(
      message: message,
      title: title,
      type: NotificationType.info,
      duration: duration,
    );
  }
}
