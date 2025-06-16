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

    // Profile picture management
    'profile_picture_updated': {
      'en': 'Profile picture updated successfully',
      'es': 'Imagen de perfil actualizada con éxito',
      'ca': 'Imatge de perfil actualitzada amb èxit',
    },
    'profile_picture_upload_error': {
      'en': 'Error uploading profile picture',
      'es': 'Error al subir imagen de perfil',
      'ca': 'Error en pujar imatge de perfil',
    },
    'select_image_source': {
      'en': 'Select image source',
      'es': 'Selecciona fuente de imagen',
      'ca': 'Selecciona font d\'imatge',
    },
    'camera': {
      'en': 'Camera',
      'es': 'Cámara',
      'ca': 'Càmera',
    },
    'gallery': {
      'en': 'Gallery',
      'es': 'Galería',
      'ca': 'Galeria',
    },
    'delete_profile_picture': {
      'en': 'Delete profile picture',
      'es': 'Eliminar imagen de perfil',
      'ca': 'Eliminar imatge de perfil',
    },
    'delete_profile_picture_confirmation': {
      'en': 'Are you sure you want to delete your profile picture?',
      'es': '¿Estás seguro de que quieres eliminar tu imagen de perfil?',
      'ca': 'Estàs segur que vols eliminar la teva imatge de perfil?',
    },
    'profile_picture_deleted': {
      'en': 'Profile picture deleted successfully',
      'es': 'Imagen de perfil eliminada con éxito',
      'ca': 'Imatge de perfil eliminada amb èxit',
    },
    'profile_picture_delete_error': {
      'en': 'Error deleting profile picture',
      'es': 'Error al eliminar imagen de perfil',
      'ca': 'Error en eliminar imatge de perfil',
    },

    // Follow system
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
    'following_of': {
      'en': 'Following of',
      'es': 'Siguiendo de',
      'ca': 'Seguint de',
    },
    'followers_of': {
      'en': 'Followers of',
      'es': 'Seguidores de',
      'ca': 'Seguidors de',
    },
    'not_following_anyone': {
      'en': 'Not following anyone yet',
      'es': 'Aún no sigues a nadie',
      'ca': 'Encara no segueixes ningú',
    },
    'not_following_description': {
      'en': 'Start following people to see their activities in your feed',
      'es': 'Comienza a seguir gente para ver sus actividades en tu feed',
      'ca': 'Comença a seguir gent per veure les seves activitats al teu feed',
    },
    'no_followers': {
      'en': 'No followers yet',
      'es': 'Aún no tienes seguidores',
      'ca': 'Encara no tens seguidors',
    },
    'no_followers_description': {
      'en': 'Share your activities and connect with other users to gain followers',
      'es': 'Comparte tus actividades y conecta con otros usuarios para ganar seguidores',
      'ca': 'Comparteix les teves activitats i connecta amb altres usuaris per guanyar seguidors',
    },
    'user_followed_successfully': {
      'en': 'User followed successfully',
      'es': 'Usuario seguido con éxito',
      'ca': 'Usuari seguit amb èxit',
    },
    'user_unfollowed_successfully': {
      'en': 'User unfollowed successfully',
      'es': 'Dejaste de seguir al usuario con éxito',
      'ca': 'Has deixat de seguir l\'usuari amb èxit',
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

    // Activity list screen
    'all_activities': {
      'en': 'All',
      'es': 'Todas',
      'ca': 'Totes',
    },
    'filter_by': {
      'en': 'Filter by',
      'es': 'Filtrar por',
      'ca': 'Filtrar per',
    },
    'sort_by': {
      'en': 'Sort by',
      'es': 'Ordenar por',
      'ca': 'Ordenar per',
    },
    'date': {
      'en': 'Date',
      'es': 'Fecha',
      'ca': 'Data',
    },
    'name': {
      'en': 'Name',
      'es': 'Nombre',
      'ca': 'Nom',
    },
    'ascending': {
      'en': 'Ascending',
      'es': 'Ascendente',
      'ca': 'Ascendent',
    },
    'descending': {
      'en': 'Descending',
      'es': 'Descendente',
      'ca': 'Descendent',
    },
    'search_activities': {
      'en': 'Search activities...',
      'es': 'Buscar actividades...',
      'ca': 'Cercar activitats...',
    },
    'clear_search': {
      'en': 'Clear search',
      'es': 'Limpiar búsqueda',
      'ca': 'Netejar cerca',
    },
    'no_activities_found': {
      'en': 'No activities found',
      'es': 'No se encontraron actividades',
      'ca': 'No s\'han trobat activitats',
    },
    'activity_count': {
      'en': '{count} activities',
      'es': '{count} actividades',
      'ca': '{count} activitats',
    },
    'general_stats': {
      'en': 'General Statistics',
      'es': 'Estadísticas Generales',
      'ca': 'Estadístiques Generals',
    },
    'total_activities': {
      'en': 'Activities',
      'es': 'Actividades',
      'ca': 'Activitats',
    },
    'average': {
      'en': 'Average',
      'es': 'Promedio',
      'ca': 'Promig',
    },
    'total_time_label': {
      'en': 'Total Time',
      'es': 'Tiempo Total',
      'ca': 'Temps Total',
    },
    'filters_and_sorting': {
      'en': 'Filters and Sorting',
      'es': 'Filtros y Ordenamiento',
      'ca': 'Filtres i Ordenació',
    },
    'results': {
      'en': 'results',
      'es': 'resultados',
      'ca': 'resultats',
    },
    'result': {
      'en': 'result',
      'es': 'resultado',
      'ca': 'resultat',
    },

    // Achievements screen
    'unlocked_achievements': {
      'en': 'Unlocked',
      'es': 'Desbloqueados',
      'ca': 'Desbloquejats',
    },
    'locked_achievements': {
      'en': 'Locked',
      'es': 'Bloqueados',
      'ca': 'Bloquejats',
    },
    'achievement_stats': {
      'en': 'Achievement Statistics',
      'es': 'Estadísticas de Logros',
      'ca': 'Estadístiques d\'Assoliments',
    },
    'unlocked_achievements_label': {
      'en': 'Unlocked\nAchievements',
      'es': 'Logros\nDesbloqueados',
      'ca': 'Assoliments\nDesbloquejats',
    },
    'total_achievements': {
      'en': 'Total\nAchievements',
      'es': 'Total de\nLogros',
      'ca': 'Total\nd\'Assoliments',
    },
    'total_progress': {
      'en': 'Total\nProgress',
      'es': 'Progreso\nTotal',
      'ca': 'Progrés\nTotal',
    },
    'total_points': {
      'en': 'Total\nPoints',
      'es': 'Puntos\nTotales',
      'ca': 'Punts\nTotals',
    },
    'difficulty': {
      'en': 'Difficulty',
      'es': 'Dificultad',
      'ca': 'Dificultat',
    },
    'type': {
      'en': 'Type',
      'es': 'Tipo',
      'ca': 'Tipus',
    },
    'all_difficulties': {
      'en': 'All',
      'es': 'Todas',
      'ca': 'Totes',
    },
    'bronze': {
      'en': 'Bronze',
      'es': 'Bronce',
      'ca': 'Bronze',
    },
    'silver': {
      'en': 'Silver',
      'es': 'Plata',
      'ca': 'Plata',
    },
    'gold': {
      'en': 'Gold',
      'es': 'Oro',
      'ca': 'Or',
    },
    'diamond': {
      'en': 'Diamond',
      'es': 'Diamante',
      'ca': 'Diamant',
    },
    'all_types': {
      'en': 'All',
      'es': 'Todos',
      'ca': 'Tots',
    },
    'distance_type': {
      'en': 'Distance',
      'es': 'Distancia',
      'ca': 'Distància',
    },
    'time_type': {
      'en': 'Time',
      'es': 'Tiempo',
      'ca': 'Temps',
    },
    'activity_type': {
      'en': 'Activities',
      'es': 'Actividades',
      'ca': 'Activitats',
    },
    'speed_type': {
      'en': 'Speed',
      'es': 'Velocidad',
      'ca': 'Velocitat',
    },
    'elevation_type': {
      'en': 'Elevation',
      'es': 'Elevación',
      'ca': 'Elevació',
    },
    'consecutive_type': {
      'en': 'Consecutive',
      'es': 'Consecutivos',
      'ca': 'Consecutius',
    },
    'no_unlocked_achievements': {
      'en': 'No unlocked achievements with these filters yet',
      'es': 'Aún no has desbloqueado logros con estos filtros',
      'ca': 'Encara no has desbloquejat assoliments amb aquests filtres',
    },
    'no_locked_achievements': {
      'en': 'No locked achievements with these filters',
      'es': 'No hay logros bloqueados con estos filtros',
      'ca': 'No hi ha assoliments bloquejats amb aquests filtres',
    },
    'points': {
      'en': 'pts',
      'es': 'pts',
      'ca': 'pts',
    },
    'objective': {
      'en': 'Objective',
      'es': 'Objetivo',
      'ca': 'Objectiu',
    },
    'activity_type_label': {
      'en': 'Activity Type',
      'es': 'Tipo de Actividad',
      'ca': 'Tipus d\'Activitat',
    },
    'unlocked': {
      'en': 'Unlocked',
      'es': 'Desbloqueado',
      'ca': 'Desbloquejat',
    },
    'not_unlocked_yet': {
      'en': 'Not unlocked yet',
      'es': 'Aún no desbloqueado',
      'ca': 'Encara no desbloquejat',
    },
    'close': {
      'en': 'Close',
      'es': 'Cerrar',
      'ca': 'Tancar',
    },
    'new_achievements': {
      'en': 'New Achievements',
      'es': 'Nuevos Logros',
      'ca': 'Nous Assoliments',
    },
    'achievement_unlocked_single': {
      'en': 'You have unlocked a new achievement:',
      'es': 'Has desbloqueado un nuevo logro:',
      'ca': 'Has desbloquejat un nou assoliment:',
    },
    'achievement_unlocked_multiple': {
      'en': 'You have unlocked {count} new achievements:',
      'es': 'Has desbloqueado {count} nuevos logros:',
      'ca': 'Has desbloquejat {count} nous assoliments:',
    },
    'great': {
      'en': 'Great',
      'es': 'Genial',
      'ca': 'Genial',
    },

    // General actions
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

    // Metrics
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

    // Tracking
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

    // Connection states
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

    // Time and dates
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

    // Errors and validations
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

    // Confirmations
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

    // Additional states
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

    // Achievements and goals
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

    // Chat additional
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

    // USER HOME SCREEN SPECIFIC
    'welcome_back': {
      'en': 'Welcome back!',
      'es': '¡Bienvenido de nuevo!',
      'ca': 'Benvingut de nou!',
    },
    'quick_summary': {
      'en': 'Quick Summary',
      'es': 'Resumen Rápido',
      'ca': 'Resum Ràpid',
    },
    'next': {
      'en': 'Next',
      'es': 'Próximo',
      'ca': 'Següent',
    },
    'goal': {
      'en': 'Goal',
      'es': 'Meta',
      'ca': 'Meta',
    },
    'weekly_activity': {
      'en': '📈 Weekly Activity',
      'es': '📈 Actividad Semanal',
      'ca': '📈 Activitat Setmanal',
    },
    'last_7_days_km': {
      'en': '🏃‍♂️ Last 7 Days (km)',
      'es': '🏃‍♂️ Últimos 7 Días (km)',
      'ca': '🏃‍♂️ Últims 7 Dies (km)',
    },
    'activity_types': {
      'en': ' Activity Types',
      'es': ' Tipos de Actividad',
      'ca': ' Tipus d\'Activitat',
    },
    'achievements_section': {
      'en': '🏆 Achievements',
      'es': '🏆 Logros',
      'ca': '🏆 Assoliments',
    },
    'view_all_achievements': {
      'en': 'View all',
      'es': 'Ver todos',
      'ca': 'Veure tots',
    },
    'recent_activities_section': {
      'en': ' Recent Activities',
      'es': ' Actividades Recientes',
      'ca': ' Activitats Recents',
    },
    'no_activities_yet': {
      'en': 'No activities yet',
      'es': 'No hay actividades aún',
      'ca': 'Encara no hi ha activitats',
    },
    'start_first_activity': {
      'en': 'Start your first activity!',
      'es': '¡Comienza tu primera actividad!',
      'ca': 'Comença la teva primera activitat!',
    },
    'online_users_section': {
      'en': ' Online Users',
      'es': ' Usuarios Conectados',
      'ca': ' Usuaris Connectats',
    },
    'search_users_section': {
      'en': '🔍 Search Users',
      'es': '🔍 Buscar Usuarios',
      'ca': '🔍 Cercar Usuaris',
    },
    'search_by_username': {
      'en': 'Search by username...',
      'es': 'Buscar por nombre de usuario...',
      'ca': 'Cercar per nom d\'usuari...',
    },
    'searching_users_loading': {
      'en': 'Searching users...',
      'es': 'Buscando usuarios...',
      'ca': 'Cercant usuaris...',
    },
    'no_users_found_search': {
      'en': 'No users found',
      'es': 'No se encontraron usuarios',
      'ca': 'No s\'han trobat usuaris',
    },
    'hours': {
      'en': 'h',
      'es': 'h',
      'ca': 'h',
    },
    'minutes_short': {
      'en': 'm',
      'es': 'm',
      'ca': 'm',
    },
    'ago': {
      'en': 'ago',
      'es': 'hace',
      'ca': 'fa',
    },
    'days': {
      'en': 'days',
      'es': 'días',
      'ca': 'dies',
    },
    'now': {
      'en': 'Now',
      'es': 'Ahora',
      'ca': 'Ara',
    },
    'min': {
      'en': 'min',
      'es': 'min',
      'ca': 'min',
    },

    // FOLLOWING ACTIVITIES SCREEN SPECIFIC
    'friends_activities': {
      'en': 'Activities from your friends',
      'es': 'Actividades de tus amigos',
      'ca': 'Activitats dels teus amics',
    },
    'following_people_count': {
      'en': 'Following {count} people',
      'es': 'Siguiendo a {count} personas',
      'ca': 'Seguint {count} persones',
    },
    'activities_found': {
      'en': '{count} activities found',
      'es': '{count} actividades encontradas',
      'ca': '{count} activitats trobades',
    },
    'feed_empty': {
      'en': 'Your feed is empty!',
      'es': '¡Tu feed está vacío!',
      'ca': 'El teu feed està buit!',
    },
    'not_following_anyone_yet': {
      'en': 'You\'re not following anyone yet.\nFind friends to see their activities!',
      'es': 'Aún no sigues a nadie.\n¡Encuentra amigos para ver sus actividades!',
      'ca': 'Encara no segueixes ningú.\nTroba amics per veure les seves activitats!',
    },
    'people_no_activities': {
      'en': 'People you follow haven\'t\nposted activities yet.',
      'es': 'Las personas que sigues aún no han\npublicado actividades.',
      'ca': 'Les persones que segueixes encara no han\npublicat activitats.',
    },
    'find_users': {
      'en': 'Find Users',
      'es': 'Buscar Usuarios',
      'ca': 'Trobar Usuaris',
    },
    'error_loading_activities': {
      'en': 'Error loading activities',
      'es': 'Error al cargar actividades',
      'ca': 'Error en carregar activitats',
    },
    'running_caps': {
      'en': 'RUNNING',
      'es': 'CORRER',
      'ca': 'CÓRRER',
    },
    'cycling_caps': {
      'en': 'CYCLING',
      'es': 'CICLISMO',
      'ca': 'CICLISME',
    },
    'hiking_caps': {
      'en': 'HIKING',
      'es': 'SENDERISMO',
      'ca': 'SENDERISME',
    },
    'walking_caps': {
      'en': 'WALKING',
      'es': 'CAMINAR',
      'ca': 'CAMINAR',
    },
    'activity_caps': {
      'en': 'ACTIVITY',
      'es': 'ACTIVIDAD',
      'ca': 'ACTIVITAT',
    },

    // ACHIEVEMENTS SCREEN SPECIFIC
    'achievements_statistics': {
      'en': 'Achievement Statistics',
      'es': 'Estadísticas de Logros',
      'ca': 'Estadístiques d\'Assoliments',
    },
    'unlocked_achievements_stats': {
      'en': 'Unlocked\nAchievements',
      'es': 'Logros\nDesbloqueados',
      'ca': 'Assoliments\nDesbloquejats',
    },
    'total_achievements_stats': {
      'en': 'Total\nAchievements',
      'es': 'Total de\nLogros',
      'ca': 'Total\nd\'Assoliments',
    },
    'total_progress_stats': {
      'en': 'Total\nProgress',
      'es': 'Progreso\nTotal',
      'ca': 'Progrés\nTotal',
    },
    'total_points_stats': {
      'en': 'Total\nPoints',
      'es': 'Puntos\nTotales',
      'ca': 'Punts\nTotals',
    },
    'all_difficulties': {
      'en': 'All',
      'es': 'Todas',
      'ca': 'Totes',
    },
    'all_types_achievements': {
      'en': 'All',
      'es': 'Todos',
      'ca': 'Tots',
    },
    'distance_achievements': {
      'en': 'Distance',
      'es': 'Distancia',
      'ca': 'Distància',
    },
    'time_achievements': {
      'en': 'Time',
      'es': 'Tiempo',
      'ca': 'Temps',
    },
    'activities_achievements': {
      'en': 'Activities',
      'es': 'Actividades',
      'ca': 'Activitats',
    },
    'speed_achievements': {
      'en': 'Speed',
      'es': 'Velocidad',
      'ca': 'Velocitat',
    },
    'elevation_achievements': {
      'en': 'Elevation',
      'es': 'Elevación',
      'ca': 'Elevació',
    },
    'consecutive_achievements': {
      'en': 'Consecutive',
      'es': 'Consecutivos',
      'ca': 'Consecutius',
    },
    'no_unlocked_filtered': {
      'en': 'No unlocked achievements with these filters yet',
      'es': 'Aún no has desbloqueado logros con estos filtros',
      'ca': 'Encara no has desbloquejat assoliments amb aquests filtres',
    },
    'no_locked_filtered': {
      'en': 'No locked achievements with these filters',
      'es': 'No hay logros bloqueados con estos filtros',
      'ca': 'No hi ha assoliments bloquejats amb aquests filtres',
    },
    'new_achievements_dialog': {
      'en': 'New Achievements',
      'es': 'Nuevos Logros',
      'ca': 'Nous Assoliments',
    },
    'unlocked_one_achievement': {
      'en': 'You have unlocked a new achievement:',
      'es': 'Has desbloqueado un nuevo logro:',
      'ca': 'Has desbloquejat un nou assoliment:',
    },
    'unlocked_multiple_achievements': {
      'en': 'You have unlocked {count} new achievements:',
      'es': 'Has desbloqueado {count} nuevos logros:',
      'ca': 'Has desbloquejat {count} nous assoliments:',
    },
    'great_button': {
      'en': 'Great',
      'es': 'Genial',
      'ca': 'Genial',
    },
    'achievement_target': {
      'en': 'Target',
      'es': 'Objetivo',
      'ca': 'Objectiu',
    },
    'points_label': {
      'en': 'Points',
      'es': 'Puntos',
      'ca': 'Punts',
    },
    'activity_type_achievement': {
      'en': 'Activity Type',
      'es': 'Tipo de Actividad',
      'ca': 'Tipus d\'Activitat',
    },
    'unlocked_status': {
      'en': 'Unlocked',
      'es': 'Desbloqueado',
      'ca': 'Desbloquejat',
    },
    'not_unlocked_status': {
      'en': 'Not unlocked yet',
      'es': 'Aún no desbloqueado',
      'ca': 'Encara no desbloquejat',
    },

    // WEEK DAYS
    'monday': {
      'en': 'Mon',
      'es': 'Lun',
      'ca': 'Dil',
    },
    'tuesday': {
      'en': 'Tue',
      'es': 'Mar',
      'ca': 'Dim',
    },
    'wednesday': {
      'en': 'Wed',
      'es': 'Mié',
      'ca': 'Dic',
    },
    'thursday': {
      'en': 'Thu',
      'es': 'Jue',
      'ca': 'Dij',
    },
    'friday': {
      'en': 'Fri',
      'es': 'Vie',
      'ca': 'Div',
    },
    'saturday': {
      'en': 'Sat',
      'es': 'Sáb',
      'ca': 'Dis',
    },
    'sunday': {
      'en': 'Sun',
      'es': 'Dom',
      'ca': 'Diu',
    },

    // ADDITIONAL METRICS LABELS  
    'elevation_gain': {
      'en': 'Elevation',
      'es': 'Elevación',
      'ca': 'Elevació',
    },
    'average_pace': {
      'en': 'Average Pace',
      'es': 'Ritmo Medio',
      'ca': 'Ritme Mitjà',
    },
    'start_activity_button': {
      'en': 'Start Activity',
      'es': 'Iniciar Actividad',
      'ca': 'Iniciar Activitat',
    },
    'begin_activity_button': {
      'en': 'Start Activity',
      'es': 'Comenzar Actividad',
      'ca': 'Començar Activitat',
    },

    // ACTIVITY LIST SPECIFIC
    'time_it_takes': {
      'en': 'Start your first adventure!',
      'es': '¡Comienza tu primera aventura!',
      'ca': 'Comença la teva primera aventura!',
    },
    'move_time': {
      'en': 'Time to move!',
      'es': '¡Hora de moverte!',
      'ca': 'Hora de moure\'s!',
    },
    'no_registered_activities': {
      'en': 'You don\'t have any registered activities yet.\nStart your first adventure!',
      'es': 'Aún no tienes actividades registradas.\n¡Comienza tu primera aventura!',
      'ca': 'Encara no tens activitats registrades.\nComença la teva primera aventura!',
    },
    'complete_training_history': {
      'en': 'Complete training history',
      'es': 'Historial completo de entrenamientos',
      'ca': 'Historial complet d\'entrenaments',
    },
    'my_activities_title': {
      'en': ' My Activities',
      'es': ' Mis Actividades',
      'ca': ' Les Meves Activitats',
    },

    // ADDITIONAL TIME REFERENCES
    'ago_time': {
      'en': 'ago',
      'es': 'hace',
      'ca': 'fa',
    },
    'yesterday_time': {
      'en': 'Yesterday',
      'es': 'Ayer',
      'ca': 'Ahir',
    },
    'days_ago': {
      'en': 'days ago',
      'es': 'días',
      'ca': 'dies',
    },

    // ACTIVITY LIST SCREEN SPECIFIC
    'complete_training_history': {
      'en': 'Complete training history',
      'es': 'Historial completo de entrenamientos',
      'ca': 'Historial complet d\'entrenaments',
    },
    'general_stats': {
      'en': 'General Statistics',
      'es': 'Estadísticas Generales',
      'ca': 'Estadístiques Generals',
    },
    'total_activities': {
      'en': 'Activities',
      'es': 'Actividades',
      'ca': 'Activitats',
    },
    'total_time_label': {
      'en': 'Total Time',
      'es': 'Tiempo Total',
      'ca': 'Temps Total',
    },
    'average': {
      'en': 'Average',
      'es': 'Promedio',
      'ca': 'Promig',
    },
'current_password_incorrect': {
  'en': 'Current password is incorrect',
  'es': 'La contraseña actual es incorrecta',
  'ca': 'La contrasenya actual és incorrecta',
},
'change_password': {
  'en': 'Change Password',
  'es': 'Cambiar Contraseña',
  'ca': 'Canviar Contrasenya',
},
'change_password_subtitle': {
  'en': 'Enter your current password and choose a new one',
  'es': 'Introduce tu contraseña actual y elige una nueva',
  'ca': 'Introdueix la teva contrasenya actual i tria una de nova',
},
'current_password': {
  'en': 'Current Password',
  'es': 'Contraseña Actual',
  'ca': 'Contrasenya Actual',
},
'current_password_hint': {
  'en': 'Enter your current password',
  'es': 'Introduce tu contraseña actual',
  'ca': 'Introdueix la teva contrasenya actual',
},
'current_password_required': {
  'en': 'Please enter your current password',
  'es': 'Por favor introduce tu contraseña actual',
  'ca': 'Si us plau, introdueix la teva contrasenya actual',
},
'new_password': {
  'en': 'New Password',
  'es': 'Nueva Contraseña',
  'ca': 'Nova Contrasenya',
},
'new_password_hint': {
  'en': 'Enter your new password',
  'es': 'Introduce tu nueva contraseña',
  'ca': 'Introdueix la teva nova contrasenya',
},
'new_password_required': {
  'en': 'Please enter a new password',
  'es': 'Por favor introduce una nueva contraseña',
  'ca': 'Si us plau, introdueix una nova contrasenya',
},
'confirm_new_password': {
  'en': 'Confirm New Password',
  'es': 'Confirmar Nueva Contraseña',
  'ca': 'Confirmar Nova Contrasenya',
},
'confirm_new_password_hint': {
  'en': 'Confirm your new password',
  'es': 'Confirma tu nueva contraseña',
  'ca': 'Confirma la teva nova contrasenya',
},
'confirm_password_required': {
  'en': 'Please confirm your new password',
  'es': 'Por favor confirma tu nueva contraseña',
  'ca': 'Si us plau, confirma la teva nova contrasenya',
},
'passwords_dont_match': {
  'en': 'Passwords do not match',
  'es': 'Las contraseñas no coinciden',
  'ca': 'Les contrasenyes no coincideixen',
},
'password_changed_success': {
  'en': 'Password changed successfully',
  'es': 'Contraseña cambiada con éxito',
  'ca': 'Contrasenya canviada amb èxit',
},
'password_change_error': {
  'en': 'Error changing password',
  'es': 'Error al cambiar la contraseña',
  'ca': 'Error en canviar la contrasenya',
},
'change_password_button': {
  'en': 'Change Password',
  'es': 'Cambiar Contraseña',
  'ca': 'Canviar Contrasenya',
},
    'filters_and_sorting': {
      'en': 'Filters and Sorting',
      'es': 'Filtros y Ordenamiento',
      'ca': 'Filtres i Ordenació',
    },
    'all_activities': {
      'en': 'All',
      'es': 'Todas',
      'ca': 'Totes',
    },
    'move_time': {
      'en': 'Time to move!',
      'es': '¡Hora de moverte!',
      'ca': 'Hora de moure\'s!',
    },
    'no_registered_activities': {
      'en': 'You don\'t have any registered activities yet.\nStart your first adventure!',
      'es': 'Aún no tienes actividades registradas.\n¡Comienza tu primera aventura!',
      'ca': 'Encara no tens activitats registrades.\nComença la teva primera aventura!',
    },
    'begin_activity_button': {
      'en': 'Start Activity',
      'es': 'Comenzar Actividad',
      'ca': 'Començar Activitat',
    },
    'load_activities_error_title': {
      'en': 'Error loading',
      'es': 'Error al cargar',
      'ca': 'Error en carregar',
    },
    'results': {
      'en': 'results',
      'es': 'resultados',
      'ca': 'resultats',
    },
    'result': {
      'en': 'result',
      'es': 'resultado',
      'ca': 'resultat',
    },

    // NOTIFICATION DETAIL SCREEN
    'notification_details': {
      'en': 'Notification Details',
      'es': 'Detalles de la notificación',
      'ca': 'Detalls de la notificació',
    },
    'notification_not_found': {
      'en': 'Notification not found',
      'es': 'Notificación no encontrada',
      'ca': 'Notificació no trobada',
    },
    'read': {
      'en': 'Read',
      'es': 'Leída',
      'ca': 'Llegida',
    },
    'unread': {
      'en': 'Unread',
      'es': 'No leída',
      'ca': 'No llegida',
    },
    'message': {
      'en': 'Message',
      'es': 'Mensaje',
      'ca': 'Missatge',
    },
    'activity_information': {
      'en': 'Activity Information',
      'es': 'Información de la Actividad',
      'ca': 'Informació de l\'Activitat',
    },
    'chat_information': {
      'en': 'Chat Information',
      'es': 'Información del Chat',
      'ca': 'Informació del Xat',
    },
    'achievement_information': {
      'en': 'Achievement Information',
      'es': 'Información del Logro',
      'ca': 'Informació de l\'Assoliment',
    },
    'sender': {
      'en': 'Sender',
      'es': 'Remitente',
      'ca': 'Remitent',
    },
    'room': {
      'en': 'Room',
      'es': 'Sala',
      'ca': 'Sala',
    },
    'achievement': {
      'en': 'Achievement',
      'es': 'Logro',
      'ca': 'Assoliment',
    },
    'description': {
      'en': 'Description',
      'es': 'Descripción',
      'ca': 'Descripció',
    },
    'go_to_chat': {
      'en': 'Go to chat',
      'es': 'Ir al chat',
      'ca': 'Anar al xat',
    },
    'back': {
      'en': 'Back',
      'es': 'Volver',
      'ca': 'Tornar',
    },
    'accept': {
      'en': 'Accept',
      'es': 'Aceptar',
      'ca': 'Acceptar',
    },
    'reject': {
      'en': 'Reject',
      'es': 'Rechazar',
      'ca': 'Rebutjar',
    },
    'friend_request_accepted': {
      'en': 'Friend request accepted',
      'es': 'Solicitud de amistad aceptada',
      'ca': 'Sol·licitud d\'amistat acceptada',
    },
    'friend_request_rejected': {
      'en': 'Friend request rejected',
      'es': 'Solicitud de amistad rechazada',
      'ca': 'Sol·licitud d\'amistat rebutjada',
    },
    'challenge_invitation_accepted': {
      'en': 'Challenge invitation accepted',
      'es': 'Invitación a reto aceptada',
      'ca': 'Invitació a repte acceptada',
    },
    'challenge_invitation_rejected': {
      'en': 'Challenge invitation rejected',
      'es': 'Invitación a reto rechazada',
      'ca': 'Invitació a repte rebutjada',
    },
    'no_additional_info': {
      'en': 'No additional information available',
      'es': 'No hay información adicional disponible',
      'ca': 'No hi ha informació adicional disponible',
    },
    'building_activity_info_error': {
      'en': 'Error building activity information',
      'es': 'Error construyendo información de actividad',
      'ca': 'Error construint informació d\'activitat',
    },

    // NOTIFICATION TYPES AND ACTIVITY TYPES
    'activity_update': {
      'en': 'Activity',
      'es': 'Actividad',
      'ca': 'Activitat',
    },
    'running_activity': {
      'en': 'Running',
      'es': 'Correr',
      'ca': 'Córrer',
    },
    'cycling_activity': {
      'en': 'Cycling',
      'es': 'Ciclismo',
      'ca': 'Ciclisme',
    },
    'walking_activity': {
      'en': 'Walking',
      'es': 'Caminar',
      'ca': 'Caminar',
    },
    'hiking_activity': {
      'en': 'Hiking',
      'es': 'Senderismo',
      'ca': 'Senderisme',
    },

    // NOTIFICATION SCREEN SPECIFIC
    'your_notifications': {
      'en': 'Your notifications',
      'es': 'Tus notificaciones',
      'ca': 'Les teves notificacions',
    },
    'no_title': {
      'en': 'No title',
      'es': 'Sin título',
      'ca': 'Sense títol',
    },
    'no_message': {
      'en': 'No message',
      'es': 'Sin mensaje',
      'ca': 'Sense missatge',
    },
    'mark_as_read_and_delete': {
      'en': 'Mark as read and delete',
      'es': 'Marcar como leída y eliminar',
      'ca': 'Marcar com a llegida i eliminar',
    },
    'mark_as_read_error': {
      'en': 'Error marking notification as read',
      'es': 'Error al marcar notificación como leída',
      'ca': 'Error en marcar notificació com a llegida',
    },

    // NOTIFICATION ACTIONS
    'no_authenticated_user_notification': {
      'en': 'No authenticated user',
      'es': 'No hay usuario autenticado',
      'ca': 'No hi ha usuari autenticat',
    },
    'loading_user_data_error': {
      'en': 'Error loading user data',
      'es': 'Error al cargar datos del usuario',
      'ca': 'Error en carregar dades d\'usuari',
    },

    // ADDITIONAL NOTIFICATION TYPES
    'new_follower': {
      'en': 'New follower',
      'es': 'Nuevo seguidor',
      'ca': 'Nou seguidor',
    },
    'friend_request': {
      'en': 'Friend request',
      'es': 'Solicitud de amistad',
      'ca': 'Sol·licitud d\'amistat',
    },
    'challenge_invitation': {
      'en': 'Challenge invitation',
      'es': 'Invitación a reto',
      'ca': 'Invitació a repte',
    },
    'challenge_completed': {
      'en': 'Challenge completed',
      'es': 'Reto completado',
      'ca': 'Repte completat',
    },

    // ERROR MESSAGES FOR NOTIFICATIONS
    'notification_action_error': {
      'en': 'Error performing notification action',
      'es': 'Error al realizar acción de notificación',
      'ca': 'Error en realitzar acció de notificació',
    },
    'delete_notification_failed': {
      'en': 'Failed to delete notification',
      'es': 'Error al eliminar la notificación',
      'ca': 'Error en eliminar la notificació',
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