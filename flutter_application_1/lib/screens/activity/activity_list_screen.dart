// lib/screens/activity/activity_list_screen.dart - VERSIÓN MEJORADA CON BRANDING TRAZER
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_application_1/models/activity.dart';
import 'package:flutter_application_1/services/auth_service.dart';
import 'package:flutter_application_1/services/http_service.dart';
import 'package:flutter_application_1/services/activity_service.dart';
import 'package:flutter_application_1/widgets/custom_drawer.dart';
import 'package:flutter_application_1/config/routes.dart';
import 'package:flutter_application_1/screens/activity/activity_detail_screen.dart';
import 'package:flutter_application_1/extensions/string_extensions.dart';
import 'package:intl/intl.dart';
import 'dart:math' as math;

enum SortOption { date, distance, duration, name }
enum FilterOption { all, running, cycling, walking, hiking }

class ActivitiesListScreen extends StatefulWidget {
  const ActivitiesListScreen({Key? key}) : super(key: key);

  @override
  _ActivitiesListScreenState createState() => _ActivitiesListScreenState();
}

class _ActivitiesListScreenState extends State<ActivitiesListScreen> 
    with TickerProviderStateMixin {
  bool _isLoading = true;
  List<Activity> _activities = [];
  List<Activity> _filteredActivities = [];
  String _errorMessage = '';
  
  // Filtros y ordenamiento
  SortOption _currentSort = SortOption.date;
  FilterOption _currentFilter = FilterOption.all;
  bool _isAscending = false;
  
  // Búsqueda
  final TextEditingController _searchController = TextEditingController();
  bool _isSearchExpanded = false;
  
  // Animaciones
  late AnimationController _fadeController;
  late AnimationController _listController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  
  // Estadísticas
  Map<String, dynamic> _stats = {};
  
  @override
  void initState() {
    super.initState();
    
    // Inicializar animaciones
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _listController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeInOut,
    ));
    
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _listController,
      curve: Curves.easeOutBack,
    ));
    
    _searchController.addListener(_onSearchChanged);
    _loadActivities();
  }
  
  @override
  void dispose() {
    _searchController.dispose();
    _fadeController.dispose();
    _listController.dispose();
    super.dispose();
  }
  
  void _onSearchChanged() {
    _applyFiltersAndSort();
  }
  
  Future<void> _loadActivities() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });
    
    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      final httpService = HttpService(authService);
      final activityService = ActivityService(httpService);
      
      if (authService.currentUser != null) {
        final activities = await activityService.getActivitiesByUserId(
          authService.currentUser!.id
        );
        
        setState(() {
          _activities = activities;
          _isLoading = false;
        });
        
        _calculateStats();
        _applyFiltersAndSort();
        _startAnimations();
      } else {
        setState(() {
          _errorMessage = 'no_auth_user'.tr(context);
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error cargando actividades: $e');
      setState(() {
        _errorMessage = 'load_activities_error'.tr(context);
        _isLoading = false;
      });
    }
  }
  
  void _startAnimations() {
    _fadeController.forward();
    Future.delayed(const Duration(milliseconds: 200), () {
      _listController.forward();
    });
  }
  
  void _calculateStats() {
    if (_activities.isEmpty) {
      _stats = {};
      return;
    }
    
    double totalDistance = 0;
    int totalDuration = 0;
    Map<ActivityType, int> typeCount = {};
    
    for (final activity in _activities) {
      totalDistance += activity.distance ?? 0;
      totalDuration += activity.duration is Duration
          ? (activity.duration as Duration).inMinutes
          : (activity.duration ?? 0).toInt();
      typeCount[activity.type] = (typeCount[activity.type] ?? 0) + 1;
    }
    
    final mostFrequentType = typeCount.entries
        .reduce((a, b) => a.value > b.value ? a : b)
        .key;
    
    _stats = {
      'totalActivities': _activities.length,
      'totalDistance': totalDistance / 1000, // km
      'totalDuration': totalDuration,
      'averageDistance': (totalDistance / 1000) / _activities.length,
      'mostFrequentType': mostFrequentType,
    };
  }
  
  void _applyFiltersAndSort() {
    List<Activity> filtered = List.from(_activities);
    
    // Aplicar filtro de tipo
    if (_currentFilter != FilterOption.all) {
      ActivityType? filterType;
      switch (_currentFilter) {
        case FilterOption.running:
          filterType = ActivityType.running;
          break;
        case FilterOption.cycling:
          filterType = ActivityType.cycling;
          break;
        case FilterOption.walking:
          filterType = ActivityType.walking;
          break;
        case FilterOption.hiking:
          filterType = ActivityType.hiking;
          break;
        default:
          break;
      }
      if (filterType != null) {
        filtered = filtered.where((activity) => activity.type == filterType).toList();
      }
    }
    
    // Aplicar búsqueda por texto
    final searchQuery = _searchController.text.toLowerCase();
    if (searchQuery.isNotEmpty) {
      filtered = filtered.where((activity) =>
          activity.name.toLowerCase().contains(searchQuery)).toList();
    }
    
    // Aplicar ordenamiento
    switch (_currentSort) {
      case SortOption.date:
        filtered.sort((a, b) => _isAscending
            ? a.startTime.compareTo(b.startTime)
            : b.startTime.compareTo(a.startTime));
        break;
      case SortOption.distance:
        filtered.sort((a, b) => _isAscending
            ? (a.distance ?? 0).compareTo(b.distance ?? 0)
            : (b.distance ?? 0).compareTo(a.distance ?? 0));
        break;
      case SortOption.duration:
        filtered.sort((a, b) => _isAscending
            ? (_getDurationInMinutes(a)).compareTo(_getDurationInMinutes(b))
            : (_getDurationInMinutes(b)).compareTo(_getDurationInMinutes(a)));
        break;
      case SortOption.name:
        filtered.sort((a, b) => _isAscending
            ? a.name.compareTo(b.name)
            : b.name.compareTo(a.name));
        break;
    }
    
    setState(() {
      _filteredActivities = filtered;
    });
  }

  int _getDurationInMinutes(Activity activity) {
    if (activity.duration is Duration) {
      return (activity.duration as Duration).inMinutes;
    } else if (activity.duration != null) {
      return activity.duration.toInt();
    } else {
      return 0;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: const CustomDrawer(currentRoute: AppRoutes.activities),
      body: CustomScrollView(
        slivers: [
          // AppBar moderna con gradiente
          SliverAppBar(
            expandedHeight: 120,
            floating: false,
            pinned: true,
            elevation: 0,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Color(0xFF667eea),
                      Color(0xFF764ba2),
                    ],
                  ),
                ),
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 20),
                        FadeTransition(
                          opacity: _fadeAnimation,
                          child: const Text(
                            ' Mis Actividades',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        FadeTransition(
                          opacity: _fadeAnimation,
                          child: Text(
                            'Historial completo de entrenamientos',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.9),
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.search, color: Colors.white),
                onPressed: () {
                  setState(() {
                    _isSearchExpanded = !_isSearchExpanded;
                    if (!_isSearchExpanded) {
                      _searchController.clear();
                    }
                  });
                },
              ),
              IconButton(
                icon: const Icon(Icons.refresh, color: Colors.white),
                onPressed: _loadActivities,
              ),
            ],
          ),
          
          // Contenido principal
          SliverToBoxAdapter(
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: _isLoading 
                  ? const SizedBox(
                      height: 400,
                      child: Center(child: CircularProgressIndicator()),
                    )
                  : _errorMessage.isNotEmpty
                      ? _buildErrorView()
                      : Column(
                          children: [
                            // Estadísticas resumidas
                            if (_activities.isNotEmpty) _buildStatsSection(),
                            
                            // Búsqueda expandible
                            if (_isSearchExpanded) _buildSearchSection(),
                            
                            // Filtros y ordenamiento
                            if (_activities.isNotEmpty) _buildFiltersSection(),
                            
                            // Lista de actividades o estado vacío
                            _activities.isEmpty
                                ? _buildEmptyView()
                                : _buildActivitiesList(),
                          ],
                        ),
            ),
          ),
        ],
      ),
      
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.pushNamed(context, AppRoutes.activitySelection);
        },
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text(
          'Nueva Actividad',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: const Color(0xFF667eea),
        elevation: 8,
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }
  
  Widget _buildStatsSection() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 2,
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Estadísticas Generales',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildStatItem(
                  icon: Icons.fitness_center,
                  value: '${_stats['totalActivities'] ?? 0}',
                  label: 'Actividades',
                  color: const Color(0xFF667eea),
                ),
              ),
              Expanded(
                child: _buildStatItem(
                  icon: Icons.straighten,
                  value: '${(_stats['totalDistance'] ?? 0).toStringAsFixed(1)} km',
                  label: 'Distancia',
                  color: Colors.green,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildStatItem(
                  icon: Icons.timer,
                  value: '${(_stats['totalDuration'] ?? 0)} min',
                  label: 'Tiempo Total',
                  color: Colors.orange,
                ),
              ),
              Expanded(
                child: _buildStatItem(
                  icon: Icons.trending_up,
                  value: '${(_stats['averageDistance'] ?? 0).toStringAsFixed(1)} km',
                  label: 'Promedio',
                  color: Colors.purple,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
  
  Widget _buildStatItem({
    required IconData icon,
    required String value,
    required String label,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      margin: const EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildSearchSection() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 2,
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: 'Buscar actividades...',
          prefixIcon: const Icon(Icons.search, color: Color(0xFF667eea)),
          suffixIcon: _searchController.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    _searchController.clear();
                  },
                )
              : null,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: Colors.grey[50],
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(
              color: Color(0xFF667eea),
              width: 2,
            ),
          ),
        ),
      ),
    );
  }
  
  Widget _buildFiltersSection() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 2,
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text(
                'Filtros y Ordenamiento',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              Text(
                '${_filteredActivities.length} resultado${_filteredActivities.length != 1 ? 's' : ''}',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 14,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          
          // Filtro por tipo
          Wrap(
            spacing: 8,
            children: FilterOption.values.map((filter) {
              final isSelected = _currentFilter == filter;
              String label;
              IconData icon;
              
              switch (filter) {
                case FilterOption.all:
                  label = 'Todas';
                  icon = Icons.apps;
                  break;
                case FilterOption.running:
                  label = 'Correr';
                  icon = Icons.directions_run;
                  break;
                case FilterOption.cycling:
                  label = 'Ciclismo';
                  icon = Icons.directions_bike;
                  break;
                case FilterOption.walking:
                  label = 'Caminar';
                  icon = Icons.directions_walk;
                  break;
                case FilterOption.hiking:
                  label = 'Senderismo';
                  icon = Icons.terrain;
                  break;
              }
              
              return FilterChip(
                selected: isSelected,
                label: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(icon, size: 16),
                    const SizedBox(width: 4),
                    Text(label),
                  ],
                ),
                onSelected: (selected) {
                  setState(() {
                    _currentFilter = filter;
                  });
                  _applyFiltersAndSort();
                },
                selectedColor: const Color(0xFF667eea).withOpacity(0.2),
                checkmarkColor: const Color(0xFF667eea),
              );
            }).toList(),
          ),
          
          const SizedBox(height: 12),
          
          // Ordenamiento
          Row(
            children: [
              const Text('Ordenar por: '),
              Expanded(
                child: DropdownButton<SortOption>(
                  value: _currentSort,
                  isExpanded: true,
                  onChanged: (SortOption? newValue) {
                    if (newValue != null) {
                      setState(() {
                        _currentSort = newValue;
                      });
                      _applyFiltersAndSort();
                    }
                  },
                  items: [
                    const DropdownMenuItem(
                      value: SortOption.date,
                      child: Text('Fecha'),
                    ),
                    const DropdownMenuItem(
                      value: SortOption.distance,
                      child: Text('Distancia'),
                    ),
                    const DropdownMenuItem(
                      value: SortOption.duration,
                      child: Text('Duración'),
                    ),
                    const DropdownMenuItem(
                      value: SortOption.name,
                      child: Text('Nombre'),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: Icon(
                  _isAscending ? Icons.arrow_upward : Icons.arrow_downward,
                  color: const Color(0xFF667eea),
                ),
                onPressed: () {
                  setState(() {
                    _isAscending = !_isAscending;
                  });
                  _applyFiltersAndSort();
                },
                tooltip: _isAscending ? 'Ascendente' : 'Descendente',
              ),
            ],
          ),
        ],
      ),
    );
  }
  
  Widget _buildEmptyView() {
    return Container(
      height: 400,
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: const Color(0xFF667eea).withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.directions_run_outlined,
              size: 64,
              color: Color(0xFF667eea),
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            '¡Hora de moverte!',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Aún no tienes actividades registradas.\n¡Comienza tu primera aventura!',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 32),
          Container(
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF667eea), Color(0xFF764ba2)],
              ),
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF667eea).withOpacity(0.3),
                  spreadRadius: 1,
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: ElevatedButton.icon(
              onPressed: () {
                Navigator.pushNamed(context, AppRoutes.activitySelection);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                shadowColor: Colors.transparent,
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
              ),
              icon: const Icon(Icons.add, color: Colors.white),
              label: const Text(
                'Comenzar Actividad',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildErrorView() {
    return Container(
      height: 400,
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.red.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.red,
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'Error al cargar',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.red,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            _errorMessage,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 32),
          ElevatedButton.icon(
            onPressed: _loadActivities,
            icon: const Icon(Icons.refresh),
            label: const Text('Reintentar'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildActivitiesList() {
    return SlideTransition(
      position: _slideAnimation,
      child: ListView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
        itemCount: _filteredActivities.length,
        itemBuilder: (context, index) {
          final activity = _filteredActivities[index];
          return AnimatedContainer(
            duration: Duration(milliseconds: 300 + (index * 100)),
            curve: Curves.easeOutBack,
            child: _buildActivityCard(activity, index),
          );
        },
      ),
    );
  }
  
  Widget _buildActivityCard(Activity activity, int index) {
    IconData activityIcon;
    Color activityColor;
    
    switch (activity.type) {
      case ActivityType.running:
        activityIcon = Icons.directions_run;
        activityColor = Colors.green;
        break;
      case ActivityType.cycling:
        activityIcon = Icons.directions_bike;
        activityColor = Colors.blue;
        break;
      case ActivityType.hiking:
        activityIcon = Icons.terrain;
        activityColor = Colors.orange;
        break;
      case ActivityType.walking:
        activityIcon = Icons.directions_walk;
        activityColor = Colors.purple;
        break;
    }
    
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: activityColor.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ActivityDetailScreen(activity: activity),
              ),
            );
          },
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: activityColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        activityIcon,
                        color: activityColor,
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            activity.name,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _formatDateWithRelative(activity.startTime),
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: activityColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        activity.formatDistance(),
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: activityColor,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                
                // Métricas en la parte inferior
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: _buildMetric(
                          Icons.timer,
                          'Duración',
                          activity.formatDuration(),
                        ),
                      ),
                      Container(
                        width: 1,
                        height: 30,
                        color: Colors.grey[300],
                      ),
                      Expanded(
                        child: _buildMetric(
                          Icons.speed,
                          'Velocidad',
                          '${(activity.averageSpeed * 3.6).toStringAsFixed(1)} km/h',
                        ),
                      ),
                      Container(
                        width: 1,
                        height: 30,
                        color: Colors.grey[300],
                      ),
                      Expanded(
                        child: _buildMetric(
                          Icons.local_fire_department,
                          'Calorías',
                          '${(activity.distance ?? 0 * 0.05).toInt()}', // Estimación simple
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
  
  Widget _buildMetric(IconData icon, String label, String value) {
    return Column(
      children: [
        Icon(icon, size: 16, color: Colors.grey[600]),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }
  
  String _formatDateWithRelative(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);
    
    if (difference.inDays == 0) {
      return 'Hoy, ${DateFormat('HH:mm').format(date)}';
    } else if (difference.inDays == 1) {
      return 'Ayer, ${DateFormat('HH:mm').format(date)}';
    } else if (difference.inDays < 7) {
      return 'Hace ${difference.inDays} días';
    } else {
      return DateFormat('dd/MM/yyyy').format(date);
    }
  }
}