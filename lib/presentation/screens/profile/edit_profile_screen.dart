import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/di/riverpod_providers.dart';
import '../../widgets/custom_app_bar.dart';

class EditProfileScreen extends ConsumerStatefulWidget {
  @override
  _EditProfileScreenState createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends ConsumerState<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  String? _selectedWorkArea;
  String? _selectedSpecialty;

  final List<String> _workAreas = ['Urbano', 'Rural'];
  final List<String> _specialties = [
    'Educación Inicial',
    'Educación Primaria',
    'Matemática',
    'Biología y Geografía',
    'Física',
    'Química',
    'Lengua Extranjera',
    'Artes Plásticas',
    'Educación Musical',
    'Otros',
  ];

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_nameController.text.isEmpty) {
      final authProvider = ref.read(authStateProvider);
      _nameController.text = authProvider.currentUser?.name ?? '';
      _selectedWorkArea = authProvider.currentUser?.workArea;
      _selectedSpecialty = authProvider.currentUser?.specialty;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = ref.watch(authStateProvider);

    return Scaffold(
      appBar: const CustomAppBar(
        title: 'Editar Perfil',
        titleColor: Colors.white,
      ),

      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: 'Nombre Completo',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.person),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor ingresa tu nombre';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              // Selector de área de trabajo
              DropdownButtonFormField<String>(
                value: _selectedWorkArea,
                decoration: InputDecoration(
                  labelText: 'Área de Trabajo',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.location_city),
                ),
                items: _workAreas.map((area) {
                  return DropdownMenuItem(value: area, child: Text(area));
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedWorkArea = value;
                  });
                },
              ),
              const SizedBox(height: 16),
              // Selector de especialidad
              DropdownButtonFormField<String>(
                value: _selectedSpecialty,
                decoration: InputDecoration(
                  labelText: 'Especialidad',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.school),
                ),
                items: _specialties.map((specialty) {
                  return DropdownMenuItem(value: specialty, child: Text(specialty));
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedSpecialty = value;
                  });
                },
              ),
              const SizedBox(height: 20),
              if (authProvider.errorMessage != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 20.0),
                  child: Text(
                    authProvider.errorMessage!,
                    style: TextStyle(color: Colors.red),
                  ),
                ),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed:
                      authProvider.isLoading
                          ? null
                          : () async {
                            if (_formKey.currentState!.validate() && mounted) {
                              final success = await authProvider.updateUser(
                                _nameController.text,
                                _selectedWorkArea,
                                _selectedSpecialty,
                              );
                              if (mounted) {
                                if (success) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        'Perfil actualizado correctamente',
                                      ),
                                    ),
                                  );
                                  Navigator.pop(context);
                                } else {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        authProvider.errorMessage ??
                                            'Error al actualizar el perfil',
                                      ),
                                      backgroundColor: Colors.red,
                                    ),
                                  );
                                }
                              }
                            }
                          },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryColor,
                    padding: EdgeInsets.symmetric(vertical: 15),
                  ),
                  child:
                      authProvider.isLoading
                          ? CircularProgressIndicator(color: Colors.white)
                          : Text('Guardar Cambios'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
