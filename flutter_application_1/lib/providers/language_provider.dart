import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LanguageProvider with ChangeNotifier {
  String _currentLanguage = 'es'; // Default to Spanish
  
  String get currentLanguage => _currentLanguage;
  
  Locale get locale => _getLocale(_currentLanguage);
  
  // Mapa de traducciones COMPLETO
  final Map<String, Map<String, String>> _translations = {
    'app_title': {
      'en': 'TRAZER',
      'es': 'TRAZER',
      'ca': 'TRAZER',
    },
    'settings': {
      'en': 'Settings',
      'es': 'Configuración',
      'ca': 'Configuració',
    },
    'appearance': {
      'en': 'Appearance',
      'es': 'Apariencia',
      'ca': 'Aparença',
    },
    'dark_mode': {
      'en': 'Dark mode',
      'es': 'Modo oscuro',
      'ca': 'Mode fosc',
    },
    'switch_theme': {
      'en': 'Switch between light and dark theme',
      'es': 'Cambiar entre tema claro y oscuro',
      'ca': 'Canviar entre tema clar i fosc',
    },
    'language': {
      'en': 'Language',
      'es': 'Idioma',
      'ca': 'Idioma',
    },
    'notifications': {
      'en': 'Notifications',
      'es': 'Notificaciones',
      'ca': 'Notificacions',
    },
    'push_notifications': {
      'en': 'Push notifications',
      'es': 'Notificaciones push',
      'ca': 'Notificacions push',
    },
    'receive_notifications': {
      'en': 'Receive notifications in real time',
      'es': 'Recibir notificaciones en tiempo real',
      'ca': 'Rebre notificacions en temps real',
    },
    'activity_notifications': {
      'en': 'Activity notifications',
      'es': 'Notificaciones de actividad',
      'ca': 'Notificacions d\'activitat',
    },
    'exercise_reminders': {
      'en': 'Exercise reminders',
      'es': 'Recordatorios para hacer ejercicio',
      'ca': 'Recordatoris per fer exercici',
    },
    'privacy': {
      'en': 'Privacy',
      'es': 'Privacidad',
      'ca': 'Privacitat',
    },
    'public_profile': {
      'en': 'Public profile',
      'es': 'Perfil público',
      'ca': 'Perfil públic',
    },
    'show_profile': {
      'en': 'Show my profile to other users',
      'es': 'Mostrar mi perfil a otros usuarios',
      'ca': 'Mostrar el meu perfil a altres usuaris',
    },
    'share_activities': {
      'en': 'Share activities',
      'es': 'Compartir actividades',
      'ca': 'Compartir activitats',
    },
    'allow_viewing': {
      'en': 'Allow others to see my activities',
      'es': 'Permitir que otros vean mis actividades',
      'ca': 'Permetre que altres vegin les meves activitats',
    },
    'version': {
      'en': 'Version',
      'es': 'Versión',
      'ca': 'Versió',
    },
    'home': {
      'en': 'Home',
      'es': 'Inicio',
      'ca': 'Inici',
    },
    'feed': {
      'en': 'General Feed',
      'es': 'Feed General',
      'ca': 'Feed General',
    },
    'profile': {
      'en': 'Profile',
      'es': 'Perfil',
      'ca': 'Perfil',
    },
    'my_activities': {
      'en': 'My activities',
      'es': 'Mis actividades',
      'ca': 'Les meves activitats',
    },
    'start_activity': {
      'en': 'Start activity',
      'es': 'Iniciar actividad',
      'ca': 'Iniciar activitat',
    },
    'my_songs': {
      'en': 'My songs',
      'es': 'Mis canciones',
      'ca': 'Les meves cançons',
    },
    'achievements': {
      'en': 'Achievements',
      'es': 'Logros',
      'ca': 'Assoliments',
    },
    'chat': {
      'en': 'Chat',
      'es': 'Chat',
      'ca': 'Xat',
    },
    'notifications_title': {
      'en': 'Notifications',
      'es': 'Notificaciones',
      'ca': 'Notificacions',
    },
    'logout': {
      'en': 'Logout',
      'es': 'Cerrar sesión',
      'ca': 'Tancar sessió',
    },
    'logout_confirm': {
      'en': 'Are you sure you want to log out?',
      'es': '¿Estás seguro de que quieres cerrar sesión?',
      'ca': 'Estàs segur que vols tancar la sessió?',
    },
    'cancel': {
      'en': 'Cancel',
      'es': 'Cancelar',
      'ca': 'Cancel·lar',
    },
    'retry': {
      'en': 'Retry',
      'es': 'Reintentar',
      'ca': 'Tornar a intentar',
    },
    'welcome': {
      'en': 'Welcome',
      'es': 'Bienvenido',
      'ca': 'Benvingut',
    },
    'welcome_user': {
      'en': 'Welcome, {username}',
      'es': 'Bienvenido, {username}',
      'ca': 'Benvingut, {username}',
    },
    'activity_management': {
      'en': 'Here you can manage your sport activities and track your progress.',
      'es': 'Aquí puedes gestionar tus actividades deportivas y seguir tu progreso.',
      'ca': 'Aquí pots gestionar les teves activitats esportives i seguir el teu progrés.',
    },
    'view_profile': {
      'en': 'View Profile',
      'es': 'Ver Perfil',
      'ca': 'Veure Perfil',
    },
    'quick_stats': {
      'en': 'Quick stats',
      'es': 'Estadísticas rápidas',
      'ca': 'Estadístiques ràpides',
    },
    'level': {
      'en': 'Level',
      'es': 'Nivel',
      'ca': 'Nivell',
    },
    'distance': {
      'en': 'Distance',
      'es': 'Distancia',
      'ca': 'Distància',
    },
    'time': {
      'en': 'Time',
      'es': 'Tiempo',
      'ca': 'Temps',
    },
    'recent_activities': {
      'en': 'Recent activities',
      'es': 'Actividades recientes',
      'ca': 'Activitats recents',
    },
    'view_less': {
      'en': 'View less',
      'es': 'Ver menos',
      'ca': 'Veure menys',
    },
    'view_all': {
      'en': 'View all',
      'es': 'Ver todas',
      'ca': 'Veure totes',
    },
    'no_activities': {
      'en': 'No activities registered',
      'es': 'No tienes actividades registradas',
      'ca': 'No tens activitats registrades',
    },
    'start_new_activity': {
      'en': 'Start a new activity with the "Start Activity" button',
      'es': 'Comienza una nueva actividad con el botón "Iniciar Actividad"',
      'ca': 'Comença una nova activitat amb el botó "Iniciar Activitat"',
    },
    'users_online': {
      'en': 'Users online',
      'es': 'Usuarios conectados',
      'ca': 'Usuaris connectats',
    },
    'total_online': {
      'en': 'Total:',
      'es': 'Total:',
      'ca': 'Total:',
    },
    'users': {
      'en': 'users online',
      'es': 'usuarios en línea',
      'ca': 'usuaris en línia',
    },
    'no_users_online': {
      'en': 'No users online',
      'es': 'No hay usuarios conectados',
      'ca': 'No hi ha usuaris connectats',
    },
    'user': {
      'en': 'User',
      'es': 'Usuario',
      'ca': 'Usuari',
    },
    'save_changes': {
      'en': 'Save Changes',
      'es': 'Guardar Cambios',
      'ca': 'Desar Canvis',
    },
    'connected': {
      'en': 'Connected',
      'es': 'Conectado',
      'ca': 'Connectat',
    },
    'connecting': {
      'en': 'Connecting...',
      'es': 'Conectando...',
      'ca': 'Connectant...',
    },
    'disconnected': {
      'en': 'Disconnected',
      'es': 'Desconectado',
      'ca': 'Desconnectat',
    },
    'login': {
      'en': 'Sign In',
      'es': 'Iniciar Sesión',
      'ca': 'Iniciar Sessió',
    },
    'login_button': {
      'en': 'Sign In',
      'es': 'Iniciar Sesión',
      'ca': 'Iniciar Sessió',
    },
    'email': {
      'en': 'Email',
      'es': 'Correo electrónico',
      'ca': 'Correu electrònic',
    },
    'password': {
      'en': 'Password',
      'es': 'Contraseña',
      'ca': 'Contrasenya',
    },
    'email_required': {
      'en': 'Please enter your email',
      'es': 'Por favor ingresa tu correo electrónico',
      'ca': 'Si us plau, introdueix el teu correu electrònic',
    },
    'password_required': {
      'en': 'Please enter your password',
      'es': 'Por favor ingresa tu contraseña',
      'ca': 'Si us plau, introdueix la teva contrasenya',
    },
    'no_account': {
      'en': 'Don\'t have an account? Register',
      'es': '¿No tienes una cuenta? Regístrate',
      'ca': 'No tens un compte? Registra\'t',
    },
    'login_failed': {
      'en': 'Login failed. Please check your credentials.',
      'es': 'Inicio de sesión fallido. Por favor verifica tus credenciales.',
      'ca': 'Error d\'inici de sessió. Si us plau, verifica les teves credencials.',
    },
    'login_error': {
      'en': 'An error occurred during login',
      'es': 'Ocurrió un error durante el inicio de sesión',
      'ca': 'S\'ha produït un error durant l\'inici de sessió',
    },

    // Register screen
    'register': {
      'en': 'Register',
      'es': 'Registro',
      'ca': 'Registre',
    },
    'register_button': {
      'en': 'Register',
      'es': 'Registrarse',
      'ca': 'Registrar-se',
    },
    'create_account': {
      'en': 'Create Account',
      'es': 'Crear una cuenta',
      'ca': 'Crear un compte',
    },
    'username': {
      'en': 'Username',
      'es': 'Nombre de usuario',
      'ca': 'Nom d\'usuari',
    },
    'username_required': {
      'en': 'Please enter a username',
      'es': 'Por favor, ingresa un nombre de usuario',
      'ca': 'Si us plau, introdueix un nom d\'usuari',
    },
    'valid_email_required': {
      'en': 'Please enter a valid email',
      'es': 'Por favor, introduce un correo electrónico válido',
      'ca': 'Si us plau, introdueix un correu electrònic vàlid',
    },
    'password_length': {
      'en': 'Password must be at least 6 characters',
      'es': 'La contraseña debe tener al menos 6 caracteres',
      'ca': 'La contrasenya ha de tenir almenys 6 caràcters',
    },
    'register_success': {
      'en': 'Registration successful! You can now login.',
      'es': 'Registro exitoso. Ahora puedes iniciar sesión.',
      'ca': 'Registre exitós. Ara pots iniciar sessió.',
    },
    'register_failed': {
      'en': 'Registration failed. Please try again.',
      'es': 'Error en el registro. Por favor, inténtalo de nuevo.',
      'ca': 'Error en el registre. Si us plau, torna-ho a provar.',
    },
    'register_error': {
      'en': 'An error occurred during registration',
      'es': 'Ocurrió un error durante el registro',
      'ca': 'S\'ha produït un error durant el registre',
    },
    'have_account': {
      'en': 'Already have an account? Sign In',
      'es': '¿Ya tienes una cuenta? Inicia sesión',
      'ca': 'Ja tens un compte? Inicia sessió',
    },

    // Activity screens
    'new_activity': {
      'en': 'New activity',
      'es': 'Nueva actividad',
      'ca': 'Nova activitat',
    },
    'no_auth_user': {
      'en': 'No authenticated user',
      'es': 'No hay usuario autenticado',
      'ca': 'No hi ha usuari autenticat',
    },
    'load_activities_error': {
      'en': 'Error loading activities',
      'es': 'Error al cargar actividades',
      'ca': 'Error en carregar activitats',
    },
    'load_activities_error_title': {
      'en': 'Error loading activities',
      'es': 'Error al cargar actividades',
      'ca': 'Error en carregar activitats',
    },
    'refresh': {
      'en': 'Refresh',
      'es': 'Actualizar',
      'ca': 'Actualitzar',
    },

    // Activity selection
    'select_activity_type': {
      'en': 'Select activity type',
      'es': 'Selecciona el tipo de actividad',
      'ca': 'Selecciona el tipus d\'activitat',
    },
    'running': {
      'en': 'Running',
      'es': 'Correr',
      'ca': 'Córrer',
    },
    'cycling': {
      'en': 'Cycling',
      'es': 'Ciclismo',
      'ca': 'Ciclisme',
    },
    'hiking': {
      'en': 'Hiking',
      'es': 'Senderismo',
      'ca': 'Senderisme',
    },
    'walking': {
      'en': 'Walking',
      'es': 'Caminar',
      'ca': 'Caminar',
    },

    // Notifications
    'all_notifications_read': {
      'en': 'All notifications marked as read',
      'es': 'Todas las notificaciones marcadas como leídas',
      'ca': 'Totes les notificacions marcades com a llegides',
    },
    'mark_all_read': {
      'en': 'Mark all as read',
      'es': 'Marcar todas como leídas',
      'ca': 'Marcar totes com a llegides',
    },
    'load_notifications_error': {
      'en': 'Error loading notifications',
      'es': 'Error al cargar notificaciones',
      'ca': 'Error en carregar notificacions',
    },
    'no_notifications': {
      'en': 'No notifications',
      'es': 'No tienes notificaciones',
      'ca': 'No tens notificacions',
    },
    'delete_notification': {
      'en': 'Delete notification?',
      'es': '¿Eliminar notificación?',
      'ca': 'Eliminar notificació?',
    },
    'delete_notification_confirm': {
      'en': 'Are you sure you want to delete this notification?',
      'es': '¿Estás seguro de que deseas eliminar esta notificación?',
      'ca': 'Estàs segur que vols eliminar aquesta notificació?',
    },
    'delete': {
      'en': 'Delete',
      'es': 'Eliminar',
      'ca': 'Eliminar',
    },
    'delete_notification_error': {
      'en': 'Error deleting notification',
      'es': 'Error al eliminar la notificación',
      'ca': 'Error en eliminar la notificació',
    },
    'error': {
      'en': 'Error',
      'es': 'Error',
      'ca': 'Error',
    },

    // Chat
    'new_chat': {
      'en': 'New chat',
      'es': 'Nuevo chat',
      'ca': 'Nou xat',
    },
    'no_conversations': {
      'en': 'No conversations',
      'es': 'No tienes conversaciones',
      'ca': 'No tens converses',
    },
    'start_new_chat': {
      'en': 'Start a new chat with the + button',
      'es': 'Inicia un nuevo chat con el botón +',
      'ca': 'Inicia un nou xat amb el botó +',
    },
    'no_messages_yet': {
      'en': 'No messages yet',
      'es': 'No hay mensajes aún',
      'ca': 'Encara no hi ha missatges',
    },
    'yesterday': {
      'en': 'Yesterday',
      'es': 'Ayer',
      'ca': 'Ahir',
    },
    'new_group_chat': {
      'en': 'New group chat',
      'es': 'Nuevo chat grupal',
      'ca': 'Nou xat grupal',
    },
    'group_chat': {
      'en': 'Group chat',
      'es': 'Chat grupal',
      'ca': 'Xat grupal',
    },
    'group_name': {
      'en': 'Group name',
      'es': 'Nombre del grupo',
      'ca': 'Nom del grup',
    },
    'select_users': {
      'en': 'Select users',
      'es': 'Selecciona usuarios',
      'ca': 'Selecciona usuaris',
    },
    'select_user': {
      'en': 'Select user',
      'es': 'Seleccionar usuario',
      'ca': 'Seleccionar usuari',
    },
    'no_users_available': {
      'en': 'No users available',
      'es': 'No hay usuarios disponibles',
      'ca': 'No hi ha usuaris disponibles',
    },
    'select_at_least_one_user': {
      'en': 'Select at least one user',
      'es': 'Selecciona al menos un usuario',
      'ca': 'Selecciona almenys un usuari',
    },
    'enter_group_name': {
      'en': 'Enter a name for the group',
      'es': 'Ingresa un nombre para el grupo',
      'ca': 'Introdueix un nom per al grup',
    },
    'current_user_not_identified': {
      'en': 'Current user could not be identified',
      'es': 'No se pudo identificar al usuario actual',
      'ca': 'No s\'ha pogut identificar l\'usuari actual',
    },
    'create': {
      'en': 'Create',
      'es': 'Crear',
      'ca': 'Crear',
    },
    'create_chat_form': {
      'en': 'Create chat form',
      'es': 'Formulario de creación de chat',
      'ca': 'Formulari de creació de xat',
    },
    'confirm_delete': {
      'en': 'Confirm deletion',
      'es': 'Confirmar eliminación',
      'ca': 'Confirmar eliminació',
    },
    'confirm_delete_chat': {
      'en': 'Are you sure you want to delete this chat? This action cannot be undone and all messages will be lost.',
      'es': '¿Estás seguro de que quieres eliminar este chat? Esta acción no se puede deshacer y se perderán todos los mensajes.',
      'ca': 'Estàs segur que vols eliminar aquest xat? Aquesta acció no es pot desfer i es perdran tots els missatges.',
    },
    'chat_deleted': {
      'en': 'Chat deleted',
      'es': 'Chat eliminado',
      'ca': 'Xat eliminat',
    },
    'chat_delete_error': {
      'en': 'Error deleting chat',
      'es': 'Error al eliminar el chat',
      'ca': 'Error en eliminar el xat',
    },
    // User profile screen
    'my_profile': {
      'en': 'My Profile',
      'es': 'Mi Perfil',
      'ca': 'El Meu Perfil',
    },
    'user_data_not_found': {
      'en': 'User data not found',
      'es': 'No se encontraron datos de usuario',
      'ca': 'No s\'han trobat dades d\'usuari',
    },
    'user_data_load_error': {
      'en': 'Error loading user data',
      'es': 'Error al cargar datos del usuario',
      'ca': 'Error en carregar dades d\'usuari',
    },
    'no_user_data': {
      'en': 'No user data found',
      'es': 'No se encontraron datos de usuario',
      'ca': 'No s\'han trobat dades d\'usuari',
    },
    'profile_updated': {
      'en': 'Profile updated successfully',
      'es': 'Perfil actualizado con éxito',
      'ca': 'Perfil actualitzat amb èxit',
    },
    'profile_update_error': {
      'en': 'Error updating profile',
      'es': 'Error al actualizar perfil',
      'ca': 'Error en actualitzar perfil',
    },
    'user_level': {
      'en': 'Level: {level}',
      'es': 'Nivel: {level}',
      'ca': 'Nivell: {level}',
    },
    'biography': {
      'en': 'Biography',
      'es': 'Biografía',
      'ca': 'Biografia',
    },
    'no_biography': {
      'en': 'No biography available',
      'es': 'No hay biografía disponible',
      'ca': 'No hi ha biografia disponible',
    },
    'total_distance': {
      'en': 'Total Distance',
      'es': 'Distancia Total',
      'ca': 'Distància Total',
    },
    'total_time': {
      'en': 'Total Time',
      'es': 'Tiempo Total',
      'ca': 'Temps Total',
    },
    'minutes': {
      'en': 'minutes',
      'es': 'minutos',
      'ca': 'minuts',
    },
    'activities': {
      'en': 'Activities',
      'es': 'Actividades',
      'ca': 'Activitats',
    },
    'challenges': {
      'en': 'challenges',
      'es': 'retos',
      'ca': 'reptes',
    },
    'completed_challenges': {
      'en': 'Completed Challenges',
      'es': 'Retos Completados',
      'ca': 'Reptes Completats',
    },
    'profile_picture_url': {
      'en': 'Profile picture URL',
      'es': 'URL de imagen de perfil',
      'ca': 'URL d\'imatge de perfil',
    },
    'username_too_short': {
      'en': 'Username must be at least 4 characters',
      'es': 'El nombre debe tener al menos 4 caracteres',
      'ca': 'El nom ha de tenir almenys 4 caràcters',
    },

    // NUEVAS TRADUCCIONES QUE FALTABAN (las que encontré en tu código):

    // Seguimiento (Follow system)
    'follow': {
      'en': 'Follow',
      'es': 'Seguir',
      'ca': 'Seguir',
    },
    'unfollow': {
      'en': 'Unfollow',
      'es': 'Dejar de seguir',
      'ca': 'Deixar de seguir',
    },
    'followers': {
      'en': 'Followers',
      'es': 'Seguidores',
      'ca': 'Seguidors',
    },
    'following': {
      'en': 'Following',
      'es': 'Siguiendo',
      'ca': 'Seguint',
    },
    'following_activities': {
      'en': 'Following Activities',
      'es': 'Actividades de Seguidos',
      'ca': 'Activitats de Seguits',
    },
    'followed_users_activities': {
      'en': 'Activities from people you follow',
      'es': 'Actividades de personas que sigues',
      'ca': 'Activitats de persones que segueixes',
    },
    'no_following_activities': {
      'en': 'No activities from followed users',
      'es': 'No hay actividades de usuarios seguidos',
      'ca': 'No hi ha activitats d\'usuaris seguits',
    },
    'start_following_people': {
      'en': 'Start following people to see their activities here',
      'es': 'Comienza a seguir gente para ver sus actividades aquí',
      'ca': 'Comença a seguir gent per veure les seves activitats aquí',
    },
    'search_users': {
      'en': 'Search Users',
      'es': 'Buscar Usuarios',
      'ca': 'Cercar Usuaris',
    },
    'search_users_hint': {
      'en': 'Search for users by username...',
      'es': 'Buscar usuarios por nombre...',
      'ca': 'Cercar usuaris per nom...',
    },
    'no_users_found': {
      'en': 'No users found',
      'es': 'No se encontraron usuarios',
      'ca': 'No s\'han trobat usuaris',
    },
    'searching_users': {
      'en': 'Searching users...',
      'es': 'Buscando usuarios...',
      'ca': 'Cercant usuaris...',
    },
    'expand': {
      'en': 'Expand',
      'es': 'Expandir',
      'ca': 'Expandir',
    },
    'collapse': {
      'en': 'Collapse',
      'es': 'Contraer',
      'ca': 'Contraure',
    },
    'clear_search': {
      'en': 'Clear search',
      'es': 'Limpiar búsqueda',
      'ca': 'Netejar cerca',
    },

    // Acciones básicas
    'edit': {
      'en': 'Edit',
      'es': 'Editar',
      'ca': 'Editar',
    },
    'save': {
      'en': 'Save',
      'es': 'Guardar',
      'ca': 'Desar',
    },
    'search': {
      'en': 'Search',
      'es': 'Buscar',
      'ca': 'Cercar',
    },
    'filter': {
      'en': 'Filter',
      'es': 'Filtrar',
      'ca': 'Filtrar',
    },
    'sort': {
      'en': 'Sort',
      'es': 'Ordenar',
      'ca': 'Ordenar',
    },
    'loading': {
      'en': 'Loading...',
      'es': 'Cargando...',
      'ca': 'Carregant...',
    },
    'success': {
      'en': 'Success',
      'es': 'Éxito',
      'ca': 'Èxit',
    },
    'confirm': {
      'en': 'Confirm',
      'es': 'Confirmar',
      'ca': 'Confirmar',
    },

    // Métricas adicionales
    'calories': {
      'en': 'Calories',
      'es': 'Calorías',
      'ca': 'Calories',
    },
    'duration': {
      'en': 'Duration',
      'es': 'Duración',
      'ca': 'Durada',
    },
    'speed': {
      'en': 'Speed',
      'es': 'Velocidad',
      'ca': 'Velocitat',
    },
    'elevation': {
      'en': 'Elevation',
      'es': 'Elevación',
      'ca': 'Elevació',
    },
    'pace': {
      'en': 'Pace',
      'es': 'Ritmo',
      'ca': 'Ritme',
    },
    'avg_speed': {
      'en': 'Average speed',
      'es': 'Velocidad promedio',
      'ca': 'Velocitat mitjana',
    },
    'max_speed': {
      'en': 'Max speed',
      'es': 'Velocidad máxima',
      'ca': 'Velocitat màxima',
    },

    // Tracking y actividades
    'start_tracking': {
      'en': 'Start Tracking',
      'es': 'Iniciar Seguimiento',
      'ca': 'Iniciar Seguiment',
    },
    'stop_tracking': {
      'en': 'Stop Tracking',
      'es': 'Detener Seguimiento',
      'ca': 'Aturar Seguiment',
    },
    'pause_tracking': {
      'en': 'Pause Tracking',
      'es': 'Pausar Seguimiento',
      'ca': 'Pausar Seguiment',
    },
    'resume_tracking': {
      'en': 'Resume Tracking',
      'es': 'Reanudar Seguimiento',
      'ca': 'Reprendre Seguiment',
    },
    'tracking_paused': {
      'en': 'Tracking paused',
      'es': 'Seguimiento pausado',
      'ca': 'Seguiment pausat',
    },
    'tracking_active': {
      'en': 'Tracking active',
      'es': 'Seguimiento activo',
      'ca': 'Seguiment actiu',
    },
    'finish_activity': {
      'en': 'Finish Activity',
      'es': 'Finalizar Actividad',
      'ca': 'Finalitzar Activitat',
    },
    'discard_activity': {
      'en': 'Discard Activity',
      'es': 'Descartar Actividad',
      'ca': 'Descartar Activitat',
    },
    'activity_saved': {
      'en': 'Activity saved',
      'es': 'Actividad guardada',
      'ca': 'Activitat desada',
    },
    'activity_discarded': {
      'en': 'Activity discarded',
      'es': 'Actividad descartada',
      'ca': 'Activitat descartada',
    },

    // Estados de conexión
    'online': {
      'en': 'Online',
      'es': 'En línea',
      'ca': 'En línia',
    },
    'offline': {
      'en': 'Offline',
      'es': 'Desconectado',
      'ca': 'Desconnectat',
    },

    // Fechas y tiempo
    'today': {
      'en': 'Today',
      'es': 'Hoy',
      'ca': 'Avui',
    },
    'this_week': {
      'en': 'This week',
      'es': 'Esta semana',
      'ca': 'Aquesta setmana',
    },
    'this_month': {
      'en': 'This month',
      'es': 'Este mes',
      'ca': 'Aquest mes',
    },
    'last_week': {
      'en': 'Last week',
      'es': 'Semana pasada',
      'ca': 'Setmana passada',
    },
    'last_month': {
      'en': 'Last month',
      'es': 'Mes pasado',
      'ca': 'Mes passat',
    },

    // Errores y validaciones
    'invalid_data': {
      'en': 'Invalid data',
      'es': 'Datos inválidos',
      'ca': 'Dades invàlides',
    },
    'network_error': {
      'en': 'Network error',
      'es': 'Error de red',
      'ca': 'Error de xarxa',
    },
    'server_error': {
      'en': 'Server error',
      'es': 'Error del servidor',
      'ca': 'Error del servidor',
    },
    'permission_denied': {
      'en': 'Permission denied',
      'es': 'Permiso denegado',
      'ca': 'Permís denegat',
    },
    'location_permission': {
      'en': 'Location permission',
      'es': 'Permiso de ubicación',
      'ca': 'Permís d\'ubicació',
    },
    'camera_permission': {
      'en': 'Camera permission',
      'es': 'Permiso de cámara',
      'ca': 'Permís de càmera',
    },

    // Confirmaciones adicionales
    'are_you_sure': {
      'en': 'Are you sure?',
      'es': '¿Estás seguro?',
      'ca': 'Estàs segur?',
    },
    'this_action_cannot_be_undone': {
      'en': 'This action cannot be undone',
      'es': 'Esta acción no se puede deshacer',
      'ca': 'Aquesta acció no es pot desfer',
    },
    'yes': {
      'en': 'Yes',
      'es': 'Sí',
      'ca': 'Sí',
    },
    'no': {
      'en': 'No',
      'es': 'No',
      'ca': 'No',
    },
    'ok': {
      'en': 'OK',
      'es': 'Aceptar',
      'ca': 'Acceptar',
    },

    // Estados adicionales
    'no_data': {
      'en': 'No data available',
      'es': 'No hay datos disponibles',
      'ca': 'No hi ha dades disponibles',
    },
    'connection_error': {
      'en': 'Connection error',
      'es': 'Error de conexión',
      'ca': 'Error de connexió',
    },
    'try_again': {
      'en': 'Try again',
      'es': 'Intentar de nuevo',
      'ca': 'Tornar a intentar',
    },
    'update_available': {
      'en': 'Update available',
      'es': 'Actualización disponible',
      'ca': 'Actualització disponible',
    },
    'offline_mode': {
      'en': 'Offline mode',
      'es': 'Modo sin conexión',
      'ca': 'Mode sense connexió',
    },

    // Logros y objetivos
    'achievement_unlocked': {
      'en': 'Achievement unlocked',
      'es': 'Logro desbloqueado',
      'ca': 'Assoliment desbloquejat',
    },
    'goal_completed': {
      'en': 'Goal completed',
      'es': 'Objetivo completado',
      'ca': 'Objectiu completat',
    },
    'personal_record': {
      'en': 'Personal record',
      'es': 'Récord personal',
      'ca': 'Rècord personal',
    },
    'streak': {
      'en': 'Streak',
      'es': 'Racha',
      'ca': 'Ratxa',
    },
    'weekly_goal': {
      'en': 'Weekly goal',
      'es': 'Objetivo semanal',
      'ca': 'Objectiu setmanal',
    },
    'monthly_goal': {
      'en': 'Monthly goal',
      'es': 'Objetivo mensual',
      'ca': 'Objectiu mensual',
    },
    'progress': {
      'en': 'Progress',
      'es': 'Progreso',
      'ca': 'Progrés',
    },
    'completed': {
      'en': 'Completed',
      'es': 'Completado',
      'ca': 'Completat',
    },
    'in_progress': {
      'en': 'In progress',
      'es': 'En progreso',
      'ca': 'En progrés',
    },
    'locked': {
      'en': 'Locked',
      'es': 'Bloqueado',
      'ca': 'Bloquejat',
    },

    // Chat adicionales
    'send_message': {
      'en': 'Send message',
      'es': 'Enviar mensaje',
      'ca': 'Enviar missatge',
    },
    'type_message': {
      'en': 'Type a message...',
      'es': 'Escribe un mensaje...',
      'ca': 'Escriu un missatge...',
    },
    'no_messages': {
      'en': 'No messages',
      'es': 'No hay mensajes',
      'ca': 'No hi ha missatges',
    },
    'typing': {
      'en': 'typing...',
      'es': 'escribiendo...',
      'ca': 'escrivint...',
    },
  };
  
  LanguageProvider() {
    _loadLanguageFromPrefs();
  }
  
  Future<void> _loadLanguageFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    _currentLanguage = prefs.getString('language') ?? 'es';
    notifyListeners();
  }
  
  Future<void> setLanguage(String languageCode) async {
    _currentLanguage = languageCode;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('language', languageCode);
    notifyListeners();
  }
  
  Locale _getLocale(String languageCode) {
    switch (languageCode) {
      case 'en':
        return const Locale('en', 'US');
      case 'ca':
        return const Locale('ca', 'ES');
      case 'es':
      default:
        return const Locale('es', 'ES');
    }
  }
  
  
  // Método para obtener traducciones
  String translate(String key) {
    if (!_translations.containsKey(key)) {
      return key; // Si la clave no existe, devolver la misma clave
    }
    
    final translations = _translations[key]!;
    return translations[_currentLanguage] ?? translations['es'] ?? key;
  }
  
  // Método para obtener traducciones con parámetros
  String translateWithParams(String key, Map<String, String> params) {
    String translated = translate(key);
    params.forEach((paramKey, paramValue) {
      translated = translated.replaceAll('{$paramKey}', paramValue);
    });
    return translated;
  }
}