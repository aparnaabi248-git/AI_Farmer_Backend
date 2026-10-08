import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../api/api_service.dart';
import 'disease_result_screen.dart';

class CameraScreen extends StatefulWidget {
  const CameraScreen({super.key});

  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> {
  XFile? selectedImage;
  bool isAnalyzing = false;

  final ImagePicker picker = ImagePicker();

  // =========================
  // CAMERA
  // =========================
  Future<void> pickCamera() async {
    final XFile? image = await picker.pickImage(
      source: ImageSource.camera,
    );

    if (image != null) {
      setState(() {
        selectedImage = image;
      });
    }
  }

  // =========================
  // GALLERY
  // =========================
  Future<void> pickGallery() async {
    final XFile? image = await picker.pickImage(
      source: ImageSource.gallery,
    );

    if (image != null) {
      setState(() {
        selectedImage = image;
      });
    }
  }

  // =========================
  // ANALYZE PLANT
  // =========================
  Future<void> analyzePlant() async {
    if (selectedImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Please select an image first."),
        ),
      );
      return;
    }

    setState(() {
      isAnalyzing = true;
    });

    try {
      final response = await ApiService.uploadFile(
        "/scans/analyze",
        selectedImage!,
      );

      if (response.statusCode == 200) {
        final data = ApiService.safeJsonDecode(response);

        if (!mounted) return;

        if (data.containsKey("disease")) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => DiseaseResultScreen(
                image: selectedImage!,
                diseaseData: data,
              ),
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                data["detail"] ??
                    "Analysis failed. Please try again.",
              ),
            ),
          );
        }
      } else {
        final data = ApiService.safeJsonDecode(response);

        if (!mounted) return;

        String errorMsg;

        if (response.statusCode == 413) {
          errorMsg =
          "Image is too large. Please use a smaller image or lower camera resolution.";
        } else {
          errorMsg = data["detail"] ??
              "Analysis failed (${response.statusCode}). Please try again.";
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMsg),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            ApiService.friendlyError(e),
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          isAnalyzing = false;
        });
      }
    }
  }

  // =========================
  // IMAGE PREVIEW
  // =========================
  Widget buildImagePreview() {
    if (selectedImage == null) {
      return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: const [
          Icon(
            Icons.image,
            size: 100,
            color: Colors.green,
          ),
          SizedBox(height: 15),
          Text(
            "No Image Selected",
            style: TextStyle(
              fontSize: 18,
            ),
          ),
        ],
      );
    }

    return FutureBuilder<Uint8List>(
      future: selectedImage!.readAsBytes(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(
              color: Colors.green,
            ),
          );
        }

        if (snapshot.hasError || !snapshot.hasData) {
          return const Center(
            child: Text(
              "Unable to load image",
              style: TextStyle(
                fontSize: 16,
                color: Colors.red,
              ),
            ),
          );
        }

        return Image.memory(
          snapshot.data!,
          fit: BoxFit.cover,
          width: double.infinity,
          height: double.infinity,
        );
      },
    );
  }

  // =========================
  // UI
  // =========================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Scan Plant"),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // =========================
            // IMAGE PREVIEW
            // =========================
            Expanded(
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: Colors.green,
                  ),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: buildImagePreview(),
                ),
              ),
            ),

            const SizedBox(height: 20),

            // =========================
            // CAMERA BUTTON
            // =========================
            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton.icon(
                icon: const Icon(
                  Icons.camera_alt,
                ),
                label: const Text(
                  "Capture Image",
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                ),
                onPressed: isAnalyzing
                    ? null
                    : pickCamera,
              ),
            ),

            const SizedBox(height: 15),

            // =========================
            // GALLERY BUTTON
            // =========================
            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton.icon(
                icon: const Icon(
                  Icons.photo_library,
                ),
                label: const Text(
                  "Choose From Gallery",
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  foregroundColor: Colors.white,
                ),
                onPressed: isAnalyzing
                    ? null
                    : pickGallery,
              ),
            ),

            const SizedBox(height: 15),

            // =========================
            // ANALYZE BUTTON
            // =========================
            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton.icon(
                icon: isAnalyzing
                    ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2,
                  ),
                )
                    : const Icon(
                  Icons.search,
                ),
                label: Text(
                  isAnalyzing
                      ? "Analyzing..."
                      : "Analyze Plant",
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                ),
                onPressed: isAnalyzing
                    ? null
                    : analyzePlant,
              ),
            ),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}