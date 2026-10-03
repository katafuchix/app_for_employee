import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../providers/operation_logic.dart';

class AttendanceSectionHeader extends StatelessWidget {
  final int count;
  final Duration duration;

  const AttendanceSectionHeader({
    super.key,
    required this.count,
    required this.duration,
  });

  @override
  Widget build(BuildContext context) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes % 60;

    return Row(
      children: [
        const Text(
          '出勤者',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppColors.darkGrey,
          ),
        ),
        const Spacer(),
        Text(
          '$count人',
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        const SizedBox(width: 12),
        Text(
          '$hours時間 $minutes分',
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
      ],
    );
  }
}

class AttendanceHorizontalList extends StatelessWidget {
  final List<WorkerAttendance> attendances;

  const AttendanceHorizontalList({super.key, required this.attendances});

  @override
  Widget build(BuildContext context) {
    if (attendances.isEmpty) {
      return const SizedBox(
        height: 100,
        child: Center(
          child: Text('出勤者はいません', style: TextStyle(color: Colors.grey)),
        ),
      );
    }

    return SizedBox(
      height: 120,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: attendances.length,
        separatorBuilder: (_, _) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          final item = attendances[index];
          final hours = item.totalWorkDuration.inHours;
          final minutes = item.totalWorkDuration.inMinutes % 60;

          Color tagColor;
          try {
            final hexCode = item.positionColorHex.replaceAll('#', '');
            tagColor = Color(int.parse('FF$hexCode', radix: 16));
          } catch (e) {
            tagColor = Colors.grey;
          }

          return Container(
            width: 160,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Stack(
                      children: [
                        const CircleAvatar(
                          radius: 20,
                          backgroundColor: AppColors.backgroundLight,
                          child: Icon(
                            Icons.person,
                            color: Colors.grey,
                            size: 24,
                          ),
                        ),
                        if (item.isWorking)
                          Positioned(
                            right: 0,
                            bottom: 0,
                            child: Container(
                              width: 10,
                              height: 10,
                              decoration: BoxDecoration(
                                color: Colors.green,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: Colors.white,
                                  width: 1.5,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.isWorking ? "勤務中" : "退勤済",
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: item.isWorking
                                  ? Colors.green
                                  : Colors.grey,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: tagColor,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              item.positionTitle,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                              ),
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  '${item.worker.familyName} ${item.worker.givenName}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
                const SizedBox(height: 2),
                Text(
                  '${hours}h ${minutes}m',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.subText,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
