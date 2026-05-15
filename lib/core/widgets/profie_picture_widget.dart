import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as path;

class ProfilePictureWidget extends StatefulWidget {
  final String? initialUrl;
  final Function(XFile file) onImagePicked;

  const ProfilePictureWidget({
    super.key,
    required this.initialUrl,
    required this.onImagePicked,
  });

  @override
  State<ProfilePictureWidget> createState() => _ProfilePictureWidgetState();
}

class _ProfilePictureWidgetState extends State<ProfilePictureWidget> {
  String? imageUrl;
  XFile? pickedImage;
  String? uploadedImageUrl;
  final ImagePicker picker = ImagePicker();
  bool isLoading = false;

  void pickProfileImage(BuildContext context) async {
    final image = await picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() {
        pickedImage = image;
      });
      debugPrint("Picked IMAGE PATH : ${pickedImage!.path}");
      widget.onImagePicked(pickedImage!);
    }
  }

  @override
  void initState() {
    super.initState();
  }

  Future<void> onImageUploaded() async {
    if (pickedImage == null) return;

    try {
      final image = File(pickedImage!.path);
      final fileName = path.basename(pickedImage!.path);
      final storageRef = FirebaseStorage.instance
          .ref()
          .child('profile_pictures')
          .child(fileName);

      await storageRef.putFile(image);

      final downloadUrl = await storageRef.getDownloadURL();

      // setState(() {
      //   widget.initialUrl = downloadUrl;
      // });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Upload failed: $e")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Container(
            width: 150,
            height: 150,
            color: Colors.grey.shade200,
            child: pickedImage != null
                ? Image.file(File(pickedImage!.path), fit: BoxFit.cover)
                : widget.initialUrl != null && widget.initialUrl!.isNotEmpty
                    ? Image.network(widget.initialUrl!, fit: BoxFit.cover)
                    : Image.asset(
                        'assets/images/profile_picture.png',
                        fit: BoxFit.cover,
                      ),
          ),
        ),
        if (isLoading)
          Positioned.fill(
            child: Container(
              color: Colors.black45,
              child: const Center(child: CircularProgressIndicator()),
            ),
          ),
        Positioned(
          bottom: 8,
          right: 8,
          child: Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColor,
              shape: BoxShape.circle,
            ),
            child: IconButton(
              icon: const Icon(Icons.camera_alt, color: Colors.white),
              onPressed: () => pickProfileImage(context),
            ),
          ),
        ),
      ],
    );
  }
}
