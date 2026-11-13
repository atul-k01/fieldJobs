import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimens.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/utils/app_snackbar.dart';
import '../../models/job_photo_model.dart';

class PhotosWidget extends StatelessWidget {
  final List<JobPhotoModel> photos;
  final Function(String localPath) onAddPhoto;
  final bool isReadOnly;

  const PhotosWidget({
    super.key,
    required this.photos,
    required this.onAddPhoto,
    this.isReadOnly = false,
  });

  Future<void> _pickImage(BuildContext context, ImageSource source) async {
    final picker = ImagePicker();
    try {
      final picked = await picker.pickImage(
        source: source,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      if (picked != null) {
        onAddPhoto(picked.path);
      }
    } catch (e) {
      if (context.mounted) {
        AppSnackBar.showError(context, '${AppStrings.photoAttachError}: $e');
      }
    }
  }

  void _showPickerModal(BuildContext context) {
    if (photos.length >= 3) {
      AppSnackBar.showWarning(context, AppStrings.photoLimitReached);
      return;
    }

    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppDimens.radiusLarge)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: AppDimens.space16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                AppStrings.addPhoto,
                style: AppTextStyles.h3,
              ),
              const SizedBox(height: AppDimens.space16),
              ListTile(
                leading: const Icon(Icons.camera_alt_outlined, color: AppColors.primary),
                title: const Text(AppStrings.takePhoto),
                onTap: () {
                  Navigator.pop(ctx);
                  _pickImage(context, ImageSource.camera);
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library_outlined, color: AppColors.primary),
                title: const Text(AppStrings.chooseFromGallery),
                onTap: () {
                  Navigator.pop(ctx);
                  _pickImage(context, ImageSource.gallery);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppDimens.cardPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.photo_camera_outlined,
                  color: AppColors.primary,
                  size: 22,
                ),
                const SizedBox(width: AppDimens.space8),
                Expanded(
                  child: Text(
                    AppStrings.photosTitle,
                    style: AppTextStyles.h3,
                  ),
                ),
                Text(
                  '${photos.length} / 3',
                  style: AppTextStyles.caption.copyWith(
                    fontWeight: FontWeight.bold,
                    color: photos.length == 3 ? AppColors.warning : AppColors.textSecondary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppDimens.space12),

            // Photos Grid
            Row(
              children: [
                // Render attached photos
                for (int i = 0; i < photos.length; i++) ...[
                  Expanded(
                    child: AspectRatio(
                      aspectRatio: 1.0,
                      child: Container(
                        margin: const EdgeInsets.only(right: AppDimens.space8),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(AppDimens.radiusMedium),
                          border: Border.all(color: AppColors.border),
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: _buildPhotoThumbnail(photos[i]),
                      ),
                    ),
                  ),
                ],

                // Render Add button if < 3 photos and not read-only
                if (photos.length < 3 && !isReadOnly)
                  Expanded(
                    child: AspectRatio(
                      aspectRatio: 1.0,
                      child: InkWell(
                        onTap: () => _showPickerModal(context),
                        borderRadius: BorderRadius.circular(AppDimens.radiusMedium),
                        child: Container(
                          decoration: BoxDecoration(
                            color: AppColors.primarySurface,
                            borderRadius: BorderRadius.circular(AppDimens.radiusMedium),
                            border: Border.all(
                              color: AppColors.primaryLight,
                              style: BorderStyle.solid,
                              width: 1.5,
                            ),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(
                                Icons.add_a_photo_outlined,
                                color: AppColors.primary,
                                size: 28,
                              ),
                              const SizedBox(height: AppDimens.space4),
                              Text(
                                'Attach',
                                style: AppTextStyles.caption.copyWith(
                                  color: AppColors.primaryDark,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),

                // Empty slots spacers if < 3
                for (int i = 0; i < (2 - photos.length); i++)
                  const Expanded(child: SizedBox()),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPhotoThumbnail(JobPhotoModel photo) {
    final file = File(photo.localPath);
    if (file.existsSync()) {
      return Image.file(file, fit: BoxFit.cover);
    }

    // Fallback placeholder if local file is simulated or moved
    return Container(
      color: AppColors.primarySurface,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.image_outlined, color: AppColors.primary, size: 24),
            const SizedBox(height: 2),
            Text(
              'Attached',
              style: AppTextStyles.caption.copyWith(color: AppColors.primaryDark, fontSize: 10),
            ),
          ],
        ),
      ),
    );
  }
}
