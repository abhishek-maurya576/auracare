import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/api_status_provider.dart';
import '../utils/app_colors.dart';
import 'glass_widgets.dart';

class ApiStatusIndicator extends StatelessWidget {
  final bool showDetails;
  
  const ApiStatusIndicator({
    super.key,
    this.showDetails = false,
  });

  @override
  Widget build(BuildContext context) {
    final apiStatus = Provider.of<ApiStatusProvider>(context);
    
    return GlassWidget(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              apiStatus.isApiConfigured 
                  ? Icons.check_circle_rounded 
                  : (apiStatus.isValidating 
                      ? Icons.pending_rounded 
                      : Icons.error_rounded),
              color: apiStatus.isApiConfigured 
                  ? Colors.green 
                  : (apiStatus.isValidating 
                      ? Colors.orange 
                      : Colors.red),
              size: 16,
            ),
            const SizedBox(width: 8),
            Text(
              apiStatus.isApiConfigured 
                  ? 'AI Ready' 
                  : (apiStatus.isValidating 
                      ? 'Checking AI...' 
                      : 'AI Error'),
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: AppColors.textPrimary,
              ),
            ),
            if (showDetails && !apiStatus.isApiConfigured) ...[
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  apiStatus.apiStatusMessage,
                  style: const TextStyle(
                    fontSize: 10,
                    color: AppColors.textMuted,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
            if (!apiStatus.isApiConfigured && !apiStatus.isValidating) ...[
              const SizedBox(width: 8),
              InkWell(
                onTap: () => apiStatus.validateApiConfiguration(),
                child: const Icon(
                  Icons.refresh_rounded,
                  color: AppColors.accentTeal,
                  size: 16,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}