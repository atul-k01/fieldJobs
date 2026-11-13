import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimens.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/navigation/app_navigator.dart';
import '../../../core/utils/app_log.dart';
import '../../../core/widgets/custom_button.dart';
import '../../../core/widgets/status_chip.dart';
import '../../../core/widgets/sync_badge.dart';
import '../models/job_model.dart';
import '../providers/jobs_provider.dart';
import 'widgets/cannot_complete_dialog.dart';
import 'widgets/checklist_widget.dart';
import 'widgets/photos_widget.dart';

class JobDetailScreen extends ConsumerStatefulWidget {
  final String jobId;

  const JobDetailScreen({super.key, required this.jobId});

  @override
  ConsumerState<JobDetailScreen> createState() => _JobDetailScreenState();
}

class _JobDetailScreenState extends ConsumerState<JobDetailScreen> {
  final _notesController = TextEditingController();
  bool _isNotesDirty = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final job = _findJob();
      if (job != null && job.technicianNotes != null) {
        _notesController.text = job.technicianNotes!;
      }
    });
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  JobModel? _findJob() {
    final jobs = ref.watch(jobsProvider).allJobs;
    try {
      return jobs.firstWhere((j) => j.id == widget.jobId);
    } catch (_) {
      return null;
    }
  }

  void _saveNotes() {
    AppLog.d('JobDetailScreen', 'Saving technician notes for ${widget.jobId}');
    ref.read(jobsProvider.notifier).saveNotes(
          widget.jobId,
          _notesController.text.trim(),
        );
    setState(() {
      _isNotesDirty = false;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Notes saved locally & queued for sync!'),
        backgroundColor: AppColors.success,
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _onStatusChange(String newStatus) {
    AppLog.i('JobDetailScreen', 'Transitioning ${widget.jobId} to $newStatus');
    ref.read(jobsProvider.notifier).updateJobStatus(widget.jobId, newStatus);
  }

  void _showCannotCompleteDialog() {
    showDialog(
      context: context,
      builder: (ctx) => CannotCompleteDialog(
        onConfirm: (reason) {
          AppLog.w('JobDetailScreen', 'Marked cannot complete: $reason');
          ref.read(jobsProvider.notifier).updateJobStatus(
                widget.jobId,
                'could_not_complete',
                reason: reason,
              );
        },
      ),
    );
  }

  void _tryCompleteJob(JobModel job) {
    // Check if checklist has uncompleted items
    final pendingChecklist = job.checklists.where((c) => !c.isCompleted).length;
    if (pendingChecklist > 0) {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Row(
            children: const [
              Icon(Icons.warning_amber_rounded, color: AppColors.warning),
              SizedBox(width: 8),
              Text('Checklist Incomplete'),
            ],
          ),
          content: Text(
            'There are still $pendingChecklist unchecked item(s). Are you sure you want to mark this job as completed?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Back to Checklist'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
              onPressed: () {
                Navigator.pop(ctx);
                _onStatusChange('completed');
              },
              child: const Text('Complete Anyway'),
            ),
          ],
        ),
      );
    } else {
      _onStatusChange('completed');
    }
  }

  @override
  Widget build(BuildContext context) {
    final job = _findJob();

    if (job == null) {
      return Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_rounded),
            onPressed: () => AppNavigator.pop(context),
          ),
          title: const Text(AppStrings.jobDetails),
        ),
        body: const Center(child: Text('Job not found')),
      );
    }

    final isReadOnly = job.isDone;

    return Scaffold(
      appBar: AppBar(
        // Explicit Prominent Back Button via AppNavigator
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: AppColors.primary, size: 26),
          tooltip: 'Back to Jobs',
          onPressed: () => AppNavigator.pop(context),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              job.id.toUpperCase(),
              style: AppTextStyles.h2.copyWith(fontSize: 18),
            ),
            Text(
              '${job.customerName} • ${job.timeWindow}',
              style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary),
            ),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: AppDimens.space16),
            child: Center(
              child: SyncBadge(syncStatus: job.syncStatus),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppDimens.space16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Conflict Notice Banner if Office updated while offline
            if (job.hasConflict)
              Container(
                margin: const EdgeInsets.only(bottom: AppDimens.space16),
                padding: const EdgeInsets.all(AppDimens.space12),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEE2E2),
                  borderRadius: BorderRadius.circular(AppDimens.radiusMedium),
                  border: Border.all(color: AppColors.error),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.warning_amber_rounded, color: AppColors.error),
                    const SizedBox(width: AppDimens.space12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            AppStrings.syncConflictNotice,
                            style: AppTextStyles.h3.copyWith(color: AppColors.error, fontSize: 14),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            AppStrings.conflictResolvedMsg,
                            style: AppTextStyles.caption.copyWith(color: AppColors.textPrimary),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

            // Top Status & Header Card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(AppDimens.cardPadding),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        StatusChip(status: job.status),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.background,
                            borderRadius: BorderRadius.circular(AppDimens.radiusSmall),
                            border: Border.all(color: AppColors.divider),
                          ),
                          child: Text(
                            'Version ${job.version}',
                            style: AppTextStyles.caption.copyWith(
                              color: AppColors.textSecondary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppDimens.space12),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppColors.primarySurface,
                            borderRadius: BorderRadius.circular(AppDimens.radiusSmall),
                          ),
                          child: const Icon(
                            Icons.home_repair_service_rounded,
                            color: AppColors.primary,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: AppDimens.space12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                job.appliance,
                                style: AppTextStyles.h2.copyWith(
                                  color: AppColors.primary,
                                  fontSize: 18,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Scheduled: ${job.scheduledDate} (${job.timeWindow})',
                                style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppDimens.space12),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(AppDimens.space12),
                      decoration: BoxDecoration(
                        color: AppColors.background,
                        borderRadius: BorderRadius.circular(AppDimens.radiusSmall),
                        border: Border.all(color: AppColors.divider),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: const [
                              Icon(Icons.report_problem_outlined, size: 16, color: Color(0xFFD97706)),
                              SizedBox(width: 6),
                              Text(
                                AppStrings.problemDescription,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFFD97706),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(
                            job.problemDescription,
                            style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textPrimary),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: AppDimens.space16),

            // Workflow Action Buttons (Travelling -> On site -> Completed)
            if (!isReadOnly) ...[
              _buildWorkflowActions(job),
              const SizedBox(height: AppDimens.space16),
            ] else if (job.cannotCompleteReason != null) ...[
              // Display Reason Job Couldn't be Completed
              Container(
                padding: const EdgeInsets.all(AppDimens.space16),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEE2E2),
                  borderRadius: BorderRadius.circular(AppDimens.radiusMedium),
                  border: Border.all(color: const Color(0xFFFECACA)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      AppStrings.cannotCompleteReasonTitle,
                      style: AppTextStyles.h3.copyWith(
                        color: AppColors.statusCouldNotComplete,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      job.cannotCompleteReason!,
                      style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textPrimary),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppDimens.space16),
            ],

            // Customer & Address Info Card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(AppDimens.cardPadding),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: const [
                        Icon(Icons.person_pin_circle_rounded, color: AppColors.primary, size: 20),
                        SizedBox(width: 8),
                        Text(AppStrings.customerInfo, style: AppTextStyles.h3),
                      ],
                    ),
                    const Divider(height: AppDimens.space24),
                    _buildInfoRow(
                      icon: Icons.person_outline,
                      title: 'Customer Name',
                      value: job.customerName,
                    ),
                    const SizedBox(height: AppDimens.space12),
                    _buildInfoRow(
                      icon: Icons.phone_outlined,
                      title: 'Contact Phone',
                      value: job.customerPhone.isNotEmpty ? job.customerPhone : 'Not provided',
                    ),
                    const SizedBox(height: AppDimens.space12),
                    _buildInfoRow(
                      icon: Icons.location_on_outlined,
                      title: AppStrings.address,
                      value: job.address,
                      trailing: IconButton(
                        icon: const Icon(Icons.copy_rounded, size: 18, color: AppColors.primary),
                        tooltip: 'Copy Address',
                        onPressed: () {
                          Clipboard.setData(ClipboardData(text: job.address));
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Address copied to clipboard'),
                              duration: Duration(seconds: 1),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: AppDimens.space16),

            // Server-defined Checklist
            ChecklistWidget(
              items: job.checklists,
              isReadOnly: isReadOnly,
              onToggle: (itemId, isCompleted) {
                ref.read(jobsProvider.notifier).toggleChecklistItem(
                      itemId,
                      job.id,
                      isCompleted,
                    );
              },
            ),
            const SizedBox(height: AppDimens.space16),

            // Technician Notes
            Card(
              child: Padding(
                padding: const EdgeInsets.all(AppDimens.cardPadding),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: const [
                        Icon(Icons.edit_note_rounded, color: AppColors.primary, size: 24),
                        SizedBox(width: AppDimens.space8),
                        Text(AppStrings.notesTitle, style: AppTextStyles.h3),
                      ],
                    ),
                    const SizedBox(height: AppDimens.space12),
                    TextField(
                      controller: _notesController,
                      maxLines: 4,
                      readOnly: isReadOnly,
                      style: AppTextStyles.bodyMedium,
                      onChanged: (val) {
                        if (!_isNotesDirty) {
                          setState(() => _isNotesDirty = true);
                        }
                      },
                      decoration: InputDecoration(
                        hintText: AppStrings.notesHint,
                        hintStyle: AppTextStyles.bodyMedium.copyWith(color: AppColors.textTertiary),
                      ),
                    ),
                    if (!isReadOnly && _isNotesDirty) ...[
                      const SizedBox(height: AppDimens.space12),
                      CustomButton(
                        text: AppStrings.saveNotes,
                        icon: Icons.save_outlined,
                        onPressed: _saveNotes,
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: AppDimens.space16),

            // Photos Section (Up to 3 photos)
            PhotosWidget(
              photos: job.photos,
              isReadOnly: isReadOnly,
              onAddPhoto: (path) {
                ref.read(jobsProvider.notifier).attachPhoto(job.id, path);
              },
            ),
            const SizedBox(height: AppDimens.space32),
          ],
        ),
      ),
    );
  }

  Widget _buildWorkflowActions(JobModel job) {
    if (job.status == 'assigned') {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          CustomButton(
            text: AppStrings.startTravelling,
            icon: Icons.directions_car_filled_outlined,
            backgroundColor: AppColors.primary,
            onPressed: () => _onStatusChange('travelling'),
          ),
          const SizedBox(height: AppDimens.space8),
          CustomButton(
            text: AppStrings.markCannotComplete,
            isOutlined: true,
            textColor: AppColors.statusCouldNotComplete,
            backgroundColor: AppColors.statusCouldNotComplete,
            onPressed: _showCannotCompleteDialog,
          ),
        ],
      );
    }

    if (job.status == 'travelling') {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          CustomButton(
            text: AppStrings.arriveOnSite,
            icon: Icons.location_on_rounded,
            backgroundColor: const Color(0xFFD97706),
            onPressed: () => _onStatusChange('on_site'),
          ),
          const SizedBox(height: AppDimens.space8),
          CustomButton(
            text: AppStrings.markCannotComplete,
            isOutlined: true,
            textColor: AppColors.statusCouldNotComplete,
            backgroundColor: AppColors.statusCouldNotComplete,
            onPressed: _showCannotCompleteDialog,
          ),
        ],
      );
    }

    if (job.status == 'on_site') {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          CustomButton(
            text: AppStrings.completeJob,
            icon: Icons.check_circle_outline,
            backgroundColor: AppColors.success,
            onPressed: () => _tryCompleteJob(job),
          ),
          const SizedBox(height: AppDimens.space8),
          CustomButton(
            text: AppStrings.markCannotComplete,
            isOutlined: true,
            textColor: AppColors.statusCouldNotComplete,
            backgroundColor: AppColors.statusCouldNotComplete,
            onPressed: _showCannotCompleteDialog,
          ),
        ],
      );
    }

    return const SizedBox.shrink();
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String title,
    required String value,
    Widget? trailing,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: AppColors.primary),
        const SizedBox(width: AppDimens.space12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: AppTextStyles.caption.copyWith(color: AppColors.textTertiary),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: AppTextStyles.bodyMedium.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
        ),
        if (trailing != null) trailing,
      ],
    );
  }
}
