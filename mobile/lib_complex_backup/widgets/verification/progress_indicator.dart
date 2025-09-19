import 'package:flutter/material.dart';

class VerificationProgressIndicator extends StatelessWidget {
  final int currentStep;
  final int totalSteps;
  final Function(int) onStepTap;

  const VerificationProgressIndicator({
    super.key,
    required this.currentStep,
    required this.totalSteps,
    required this.onStepTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Column(
        children: [
          // Progress bar
          Row(
            children: List.generate(totalSteps, (index) {
              final isActive = index <= currentStep;
              final isCompleted = index < currentStep;
              
              return Expanded(
                child: GestureDetector(
                  onTap: () => onStepTap(index),
                  child: Container(
                    margin: EdgeInsets.only(
                      right: index < totalSteps - 1 ? 8 : 0,
                    ),
                    child: Column(
                      children: [
                        // Step circle
                        Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: isCompleted
                                ? Colors.green
                                : isActive
                                    ? Colors.orange
                                    : Colors.grey.shade600,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: Colors.white,
                              width: 2,
                            ),
                          ),
                          child: Center(
                            child: isCompleted
                                ? const Icon(
                                    Icons.check,
                                    color: Colors.white,
                                    size: 16,
                                  )
                                : Text(
                                    '${index + 1}',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                    ),
                                  ),
                          ),
                        ),
                        
                        const SizedBox(height: 8),
                        
                        // Step label
                        Text(
                          _getStepLabel(index),
                          style: TextStyle(
                            color: isActive ? Colors.white : Colors.grey.shade400,
                            fontSize: 12,
                            fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }),
          ),
          
          const SizedBox(height: 16),
          
          // Progress line
          Container(
            height: 2,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.orange,
                  Colors.orange.withOpacity(0.3),
                ],
                stops: [
                  (currentStep + 1) / totalSteps,
                  (currentStep + 1) / totalSteps,
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _getStepLabel(int step) {
    switch (step) {
      case 0:
        return 'Photo';
      case 1:
        return 'Edit';
      case 2:
        return 'Rate';
      case 3:
        return 'Confirm';
      default:
        return 'Step ${step + 1}';
    }
  }
}

