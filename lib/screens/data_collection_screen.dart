import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:data_acquisition_app/services/firebase_service.dart';
import 'package:data_acquisition_app/utils/theme.dart';
import 'package:data_acquisition_app/widgets/loading_overlay.dart';
import 'package:data_acquisition_app/widgets/plant_image_picker.dart';

class DataCollectionScreen extends StatefulWidget {
  const DataCollectionScreen({Key? key}) : super(key: key);

  @override
  State<DataCollectionScreen> createState() => _DataCollectionScreenState();
}

class _DataCollectionScreenState extends State<DataCollectionScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final plantNameController = TextEditingController();
  final diseaseNameController = TextEditingController();
  final otherInfoController = TextEditingController();
  File? _imageFile;
  bool _isLoading = false;
  late AnimationController _animationController;
  late Animation<double> _slideAnimation;

  // List of common plant types for dropdown
  final List<String> _plantTypes = [
    'Aloe Vera',
    'Basil',
    'Mint',
    'Rosemary',
    'Lavender',
    'Oregano',
    'Thyme',
    'Other',
  ];
  String _selectedPlantType = 'Aloe Vera';

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _slideAnimation = Tween<double>(begin: 100.0, end: 0.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );
    _animationController.forward();
  }

  Future<void> _pickImage(ImageSource source) async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(
      source: source,
      maxWidth: 1200,
      maxHeight: 1200,
      imageQuality: 85,
    );

    if (image != null) {
      setState(() {
        _imageFile = File(image.path);
      });
    }
  }

  Future<void> _submitData() async {
    if (_formKey.currentState!.validate() && _imageFile != null) {
      setState(() {
        _isLoading = true;
      });

      try {
        final plantName =
            _selectedPlantType == 'Other'
                ? plantNameController.text.trim()
                : _selectedPlantType;
        final diseaseName = diseaseNameController.text.trim();
        final additionalInfo = otherInfoController.text.trim();

        // Using the service to upload data
        await FirebaseService.uploadPlantData(
          imageFile: _imageFile!,
          plantName: plantName,
          diseaseName: diseaseName,
          additionalInfo: additionalInfo,
        );

        // Clear form and image
        setState(() {
          _imageFile = null;
          if (_selectedPlantType == 'Other') {
            plantNameController.clear();
          }
          diseaseNameController.clear();
          otherInfoController.clear();
        });

        // Show success message
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Data submitted successfully!'),
              backgroundColor: AppTheme.darkGreen,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error: $e'),
              backgroundColor: Colors.red,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      } finally {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    } else if (_imageFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select an image'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  void dispose() {
    plantNameController.dispose();
    diseaseNameController.dispose();
    otherInfoController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Scaffold(
          appBar: AppBar(
            title: const Text(
              'Upload Plant Data',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            elevation: 0,
          ),
          body: AnimatedBuilder(
            animation: _animationController,
            builder: (context, child) {
              return Transform.translate(
                offset: Offset(0, _slideAnimation.value),
                child: child,
              );
            },
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Theme.of(context).primaryColor, Colors.transparent],
                  stops: const [0.0, 0.3],
                ),
              ),
              child: SafeArea(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.all(16.0),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Image picker
                        PlantImagePicker(
                          imageFile: _imageFile,
                          onCameraTap: () => _pickImage(ImageSource.camera),
                          onGalleryTap: () => _pickImage(ImageSource.gallery),
                        ),
                        const SizedBox(height: 24.0),

                        // Form container
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color:
                                Theme.of(context).brightness == Brightness.dark
                                    ? AppTheme.darkCardColor
                                    : Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 10,
                                offset: const Offset(0, 5),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Plant Information',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 16.0),

                              // Plant Type Dropdown
                              DropdownButtonFormField<String>(
                                decoration: InputDecoration(
                                  labelText: 'Plant Type',
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  prefixIcon: const Icon(
                                    Icons.eco,
                                    color: AppTheme.primaryColor,
                                  ),
                                ),
                                value: _selectedPlantType,
                                items:
                                    _plantTypes.map((String plant) {
                                      return DropdownMenuItem<String>(
                                        value: plant,
                                        child: Text(plant),
                                      );
                                    }).toList(),
                                onChanged: (String? newValue) {
                                  setState(() {
                                    _selectedPlantType = newValue!;
                                  });
                                },
                              ),
                              const SizedBox(height: 16.0),

                              // Custom plant name field (shown only when "Other" is selected)
                              if (_selectedPlantType == 'Other')
                                TextFormField(
                                  controller: plantNameController,
                                  decoration: InputDecoration(
                                    labelText: 'Plant Name',
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    prefixIcon: const Icon(
                                      Icons.local_florist,
                                      color: AppTheme.primaryColor,
                                    ),
                                  ),
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return 'Please enter plant name';
                                    }
                                    return null;
                                  },
                                ),
                              if (_selectedPlantType == 'Other')
                                const SizedBox(height: 16.0),

                              // Disease name
                              TextFormField(
                                controller: diseaseNameController,
                                decoration: InputDecoration(
                                  labelText: 'Disease Name',
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  prefixIcon: const Icon(
                                    Icons.coronavirus,
                                    color: AppTheme.accentColor,
                                  ),
                                ),
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Please enter disease name';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 16.0),

                              // Additional information
                              TextFormField(
                                controller: otherInfoController,
                                decoration: InputDecoration(
                                  labelText:
                                      'Additional Information (Optional)',
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  prefixIcon: const Icon(
                                    Icons.info_outline,
                                    color: AppTheme.accentColor,
                                  ),
                                ),
                                maxLines: 3,
                              ),
                              const SizedBox(height: 24.0),

                              // Submit button
                              ElevatedButton(
                                onPressed: _submitData,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppTheme.primaryColor,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 16.0,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                child: const Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.cloud_upload),
                                    SizedBox(width: 10),
                                    Text(
                                      'SUBMIT DATA',
                                      style: TextStyle(
                                        fontSize: 16.0,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 24.0),

                        // Instructions card
                        Container(
                          padding: const EdgeInsets.all(16.0),
                          decoration: BoxDecoration(
                            color:
                                Theme.of(context).brightness == Brightness.dark
                                    ? AppTheme.darkCardColor.withOpacity(0.7)
                                    : Colors.grey[100],
                            borderRadius: BorderRadius.circular(16.0),
                            border: Border.all(
                              color: AppTheme.lightGreen.withOpacity(0.5),
                              width: 1,
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Row(
                                children: [
                                  Icon(
                                    Icons.lightbulb_outline,
                                    color: AppTheme.accentColor,
                                  ),
                                  SizedBox(width: 8),
                                  Text(
                                    'Tips for Better Data Collection',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),
                              _buildTipItem(
                                context,
                                'Take clear, well-lit photos of the affected plant parts',
                              ),
                              _buildTipItem(
                                context,
                                'Include the entire affected area in the frame',
                              ),
                              _buildTipItem(
                                context,
                                'Be specific about the disease name if known',
                              ),
                              _buildTipItem(
                                context,
                                'Add any observations in the additional information field',
                              ),
                            ],
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
        if (_isLoading) const LoadingOverlay(),
      ],
    );
  }

  Widget _buildTipItem(BuildContext context, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '• ',
            style: TextStyle(
              color: AppTheme.darkGreen,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                color:
                    Theme.of(context).brightness == Brightness.dark
                        ? Colors.grey[300]
                        : Colors.grey[700],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
