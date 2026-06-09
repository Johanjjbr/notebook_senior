import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_es.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('es'),
  ];

  /// The title of the application
  ///
  /// In es, this message translates to:
  /// **'Notebook Senior'**
  String get appTitle;

  /// No description provided for @appSubtitle.
  ///
  /// In es, this message translates to:
  /// **'Tus notas y tareas siempre contigo'**
  String get appSubtitle;

  /// No description provided for @loginTitle.
  ///
  /// In es, this message translates to:
  /// **'Iniciar sesión'**
  String get loginTitle;

  /// No description provided for @registerTitle.
  ///
  /// In es, this message translates to:
  /// **'Crear cuenta'**
  String get registerTitle;

  /// No description provided for @emailLabel.
  ///
  /// In es, this message translates to:
  /// **'Correo electrónico'**
  String get emailLabel;

  /// No description provided for @passwordLabel.
  ///
  /// In es, this message translates to:
  /// **'Contraseña'**
  String get passwordLabel;

  /// No description provided for @emailRequired.
  ///
  /// In es, this message translates to:
  /// **'Ingresa tu correo'**
  String get emailRequired;

  /// No description provided for @emailInvalid.
  ///
  /// In es, this message translates to:
  /// **'Correo inválido'**
  String get emailInvalid;

  /// No description provided for @passwordRequired.
  ///
  /// In es, this message translates to:
  /// **'Ingresa tu contraseña'**
  String get passwordRequired;

  /// No description provided for @passwordMinLength.
  ///
  /// In es, this message translates to:
  /// **'Mínimo 6 caracteres'**
  String get passwordMinLength;

  /// No description provided for @noAccount.
  ///
  /// In es, this message translates to:
  /// **'¿No tienes cuenta? Regístrate'**
  String get noAccount;

  /// No description provided for @hasAccount.
  ///
  /// In es, this message translates to:
  /// **'¿Ya tienes cuenta? Inicia sesión'**
  String get hasAccount;

  /// No description provided for @loginError.
  ///
  /// In es, this message translates to:
  /// **'Error al iniciar sesión'**
  String get loginError;

  /// No description provided for @registerError.
  ///
  /// In es, this message translates to:
  /// **'Error al registrar'**
  String get registerError;

  /// No description provided for @logoutError.
  ///
  /// In es, this message translates to:
  /// **'Error al cerrar sesión'**
  String get logoutError;

  /// No description provided for @dashboardTitle.
  ///
  /// In es, this message translates to:
  /// **'Resumen del día'**
  String get dashboardTitle;

  /// No description provided for @nextReminder.
  ///
  /// In es, this message translates to:
  /// **'Próximo recordatorio'**
  String get nextReminder;

  /// No description provided for @tasksToday.
  ///
  /// In es, this message translates to:
  /// **'Tareas para hoy'**
  String get tasksToday;

  /// No description provided for @recentNotes.
  ///
  /// In es, this message translates to:
  /// **'Notas recientes'**
  String get recentNotes;

  /// No description provided for @scheduledTasks.
  ///
  /// In es, this message translates to:
  /// **'Tareas programadas'**
  String get scheduledTasks;

  /// No description provided for @quickActions.
  ///
  /// In es, this message translates to:
  /// **'Acceso rápido'**
  String get quickActions;

  /// No description provided for @quickNote.
  ///
  /// In es, this message translates to:
  /// **'Nota rápida'**
  String get quickNote;

  /// No description provided for @newTask.
  ///
  /// In es, this message translates to:
  /// **'Nueva tarea'**
  String get newTask;

  /// No description provided for @reminder.
  ///
  /// In es, this message translates to:
  /// **'Recordatorio'**
  String get reminder;

  /// No description provided for @search.
  ///
  /// In es, this message translates to:
  /// **'Buscar'**
  String get search;

  /// No description provided for @notesTitle.
  ///
  /// In es, this message translates to:
  /// **'Notas'**
  String get notesTitle;

  /// No description provided for @archivedNotes.
  ///
  /// In es, this message translates to:
  /// **'Notas archivadas'**
  String get archivedNotes;

  /// No description provided for @newNote.
  ///
  /// In es, this message translates to:
  /// **'Nueva nota'**
  String get newNote;

  /// No description provided for @editNote.
  ///
  /// In es, this message translates to:
  /// **'Editar nota'**
  String get editNote;

  /// No description provided for @noteTitle.
  ///
  /// In es, this message translates to:
  /// **'Título'**
  String get noteTitle;

  /// No description provided for @noteContent.
  ///
  /// In es, this message translates to:
  /// **'Contenido'**
  String get noteContent;

  /// No description provided for @noteHint.
  ///
  /// In es, this message translates to:
  /// **'¿De qué trata esta nota?'**
  String get noteHint;

  /// No description provided for @contentHint.
  ///
  /// In es, this message translates to:
  /// **'Escribe aquí...'**
  String get contentHint;

  /// No description provided for @noteCreated.
  ///
  /// In es, this message translates to:
  /// **'Nota creada'**
  String get noteCreated;

  /// No description provided for @noteUpdated.
  ///
  /// In es, this message translates to:
  /// **'Nota actualizada'**
  String get noteUpdated;

  /// No description provided for @noteDeleted.
  ///
  /// In es, this message translates to:
  /// **'Nota eliminada'**
  String get noteDeleted;

  /// No description provided for @noteArchived.
  ///
  /// In es, this message translates to:
  /// **'Nota archivada'**
  String get noteArchived;

  /// No description provided for @noteRestored.
  ///
  /// In es, this message translates to:
  /// **'Nota restaurada'**
  String get noteRestored;

  /// No description provided for @deleteNote.
  ///
  /// In es, this message translates to:
  /// **'Eliminar nota'**
  String get deleteNote;

  /// No description provided for @deleteNoteConfirm.
  ///
  /// In es, this message translates to:
  /// **'¿Estás seguro? Esta acción no se puede deshacer.'**
  String get deleteNoteConfirm;

  /// No description provided for @deleteConfirm.
  ///
  /// In es, this message translates to:
  /// **'¿Estás seguro?'**
  String get deleteConfirm;

  /// No description provided for @cancel.
  ///
  /// In es, this message translates to:
  /// **'Cancelar'**
  String get cancel;

  /// No description provided for @delete.
  ///
  /// In es, this message translates to:
  /// **'Eliminar'**
  String get delete;

  /// No description provided for @edit.
  ///
  /// In es, this message translates to:
  /// **'Editar'**
  String get edit;

  /// No description provided for @archive.
  ///
  /// In es, this message translates to:
  /// **'Archivar'**
  String get archive;

  /// No description provided for @unarchive.
  ///
  /// In es, this message translates to:
  /// **'Desarchivar'**
  String get unarchive;

  /// No description provided for @color.
  ///
  /// In es, this message translates to:
  /// **'Color'**
  String get color;

  /// No description provided for @categories.
  ///
  /// In es, this message translates to:
  /// **'Categorías'**
  String get categories;

  /// No description provided for @titleRequired.
  ///
  /// In es, this message translates to:
  /// **'El título es obligatorio'**
  String get titleRequired;

  /// No description provided for @noNotes.
  ///
  /// In es, this message translates to:
  /// **'Sin notas'**
  String get noNotes;

  /// No description provided for @noArchivedNotes.
  ///
  /// In es, this message translates to:
  /// **'Sin notas archivadas'**
  String get noArchivedNotes;

  /// No description provided for @createNote.
  ///
  /// In es, this message translates to:
  /// **'Crear nota'**
  String get createNote;

  /// No description provided for @archiveHint.
  ///
  /// In es, this message translates to:
  /// **'Archiva notas para verlas aquí'**
  String get archiveHint;

  /// No description provided for @createNoteHint.
  ///
  /// In es, this message translates to:
  /// **'Toca + para crear una nota'**
  String get createNoteHint;

  /// No description provided for @tasksTitle.
  ///
  /// In es, this message translates to:
  /// **'Tareas'**
  String get tasksTitle;

  /// No description provided for @newTaskTitle.
  ///
  /// In es, this message translates to:
  /// **'Nueva tarea'**
  String get newTaskTitle;

  /// No description provided for @editTask.
  ///
  /// In es, this message translates to:
  /// **'Editar tarea'**
  String get editTask;

  /// No description provided for @taskTitle.
  ///
  /// In es, this message translates to:
  /// **'Título'**
  String get taskTitle;

  /// No description provided for @taskDescription.
  ///
  /// In es, this message translates to:
  /// **'Descripción (opcional)'**
  String get taskDescription;

  /// No description provided for @taskHint.
  ///
  /// In es, this message translates to:
  /// **'¿Qué tienes que hacer?'**
  String get taskHint;

  /// No description provided for @priority.
  ///
  /// In es, this message translates to:
  /// **'Prioridad'**
  String get priority;

  /// No description provided for @low.
  ///
  /// In es, this message translates to:
  /// **'Baja'**
  String get low;

  /// No description provided for @medium.
  ///
  /// In es, this message translates to:
  /// **'Media'**
  String get medium;

  /// No description provided for @high.
  ///
  /// In es, this message translates to:
  /// **'Alta'**
  String get high;

  /// No description provided for @dueDate.
  ///
  /// In es, this message translates to:
  /// **'Fecha de vencimiento'**
  String get dueDate;

  /// No description provided for @noDueDate.
  ///
  /// In es, this message translates to:
  /// **'Sin fecha de vencimiento'**
  String get noDueDate;

  /// No description provided for @checklist.
  ///
  /// In es, this message translates to:
  /// **'Checklist'**
  String get checklist;

  /// No description provided for @addStep.
  ///
  /// In es, this message translates to:
  /// **'Añadir paso'**
  String get addStep;

  /// No description provided for @stepHint.
  ///
  /// In es, this message translates to:
  /// **'Paso'**
  String get stepHint;

  /// No description provided for @taskCreated.
  ///
  /// In es, this message translates to:
  /// **'Tarea creada'**
  String get taskCreated;

  /// No description provided for @taskUpdated.
  ///
  /// In es, this message translates to:
  /// **'Tarea actualizada'**
  String get taskUpdated;

  /// No description provided for @taskDeleted.
  ///
  /// In es, this message translates to:
  /// **'Tarea eliminada'**
  String get taskDeleted;

  /// No description provided for @deleteTask.
  ///
  /// In es, this message translates to:
  /// **'Eliminar tarea'**
  String get deleteTask;

  /// No description provided for @deleteTaskConfirm.
  ///
  /// In es, this message translates to:
  /// **'¿Estás seguro? Esta acción no se puede deshacer.'**
  String get deleteTaskConfirm;

  /// No description provided for @noTasks.
  ///
  /// In es, this message translates to:
  /// **'Sin tareas'**
  String get noTasks;

  /// No description provided for @createTask.
  ///
  /// In es, this message translates to:
  /// **'Crear tarea'**
  String get createTask;

  /// No description provided for @createTaskHint.
  ///
  /// In es, this message translates to:
  /// **'Toca + para crear una tarea'**
  String get createTaskHint;

  /// No description provided for @allTasks.
  ///
  /// In es, this message translates to:
  /// **'Todas'**
  String get allTasks;

  /// No description provided for @pending.
  ///
  /// In es, this message translates to:
  /// **'Pendientes'**
  String get pending;

  /// No description provided for @completed.
  ///
  /// In es, this message translates to:
  /// **'Completadas'**
  String get completed;

  /// No description provided for @scheduled.
  ///
  /// In es, this message translates to:
  /// **'Programadas'**
  String get scheduled;

  /// No description provided for @remindersTitle.
  ///
  /// In es, this message translates to:
  /// **'Recordatorios'**
  String get remindersTitle;

  /// No description provided for @newReminder.
  ///
  /// In es, this message translates to:
  /// **'Nuevo recordatorio'**
  String get newReminder;

  /// No description provided for @editReminder.
  ///
  /// In es, this message translates to:
  /// **'Editar recordatorio'**
  String get editReminder;

  /// No description provided for @reminderTitle.
  ///
  /// In es, this message translates to:
  /// **'Título'**
  String get reminderTitle;

  /// No description provided for @reminderDescription.
  ///
  /// In es, this message translates to:
  /// **'Descripción (opcional)'**
  String get reminderDescription;

  /// No description provided for @reminderCreated.
  ///
  /// In es, this message translates to:
  /// **'Recordatorio creado'**
  String get reminderCreated;

  /// No description provided for @reminderUpdated.
  ///
  /// In es, this message translates to:
  /// **'Recordatorio actualizado'**
  String get reminderUpdated;

  /// No description provided for @reminderDeleted.
  ///
  /// In es, this message translates to:
  /// **'Recordatorio eliminado'**
  String get reminderDeleted;

  /// No description provided for @reminderCompleted.
  ///
  /// In es, this message translates to:
  /// **'Recordatorio completado'**
  String get reminderCompleted;

  /// No description provided for @deleteReminder.
  ///
  /// In es, this message translates to:
  /// **'Eliminar recordatorio'**
  String get deleteReminder;

  /// No description provided for @noReminders.
  ///
  /// In es, this message translates to:
  /// **'Sin recordatorios'**
  String get noReminders;

  /// No description provided for @createReminder.
  ///
  /// In es, this message translates to:
  /// **'Crear recordatorio'**
  String get createReminder;

  /// No description provided for @createReminderHint.
  ///
  /// In es, this message translates to:
  /// **'Programa recordatorios para no olvidar nada'**
  String get createReminderHint;

  /// No description provided for @upcoming.
  ///
  /// In es, this message translates to:
  /// **'Próximos'**
  String get upcoming;

  /// No description provided for @all.
  ///
  /// In es, this message translates to:
  /// **'Todos'**
  String get all;

  /// No description provided for @saveReminder.
  ///
  /// In es, this message translates to:
  /// **'Guardar recordatorio'**
  String get saveReminder;

  /// No description provided for @required.
  ///
  /// In es, this message translates to:
  /// **'Obligatorio'**
  String get required;

  /// No description provided for @settingsTitle.
  ///
  /// In es, this message translates to:
  /// **'Configuración'**
  String get settingsTitle;

  /// No description provided for @appearance.
  ///
  /// In es, this message translates to:
  /// **'Apariencia'**
  String get appearance;

  /// No description provided for @darkMode.
  ///
  /// In es, this message translates to:
  /// **'Tema oscuro'**
  String get darkMode;

  /// No description provided for @information.
  ///
  /// In es, this message translates to:
  /// **'Información'**
  String get information;

  /// No description provided for @version.
  ///
  /// In es, this message translates to:
  /// **'Versión'**
  String get version;

  /// No description provided for @developedWith.
  ///
  /// In es, this message translates to:
  /// **'Desarrollado con Flutter'**
  String get developedWith;

  /// No description provided for @logout.
  ///
  /// In es, this message translates to:
  /// **'Cerrar sesión'**
  String get logout;

  /// No description provided for @logoutConfirm.
  ///
  /// In es, this message translates to:
  /// **'¿Estás seguro de cerrar sesión?'**
  String get logoutConfirm;

  /// No description provided for @connected.
  ///
  /// In es, this message translates to:
  /// **'Conectado'**
  String get connected;

  /// No description provided for @user.
  ///
  /// In es, this message translates to:
  /// **'Usuario'**
  String get user;

  /// No description provided for @searchHint.
  ///
  /// In es, this message translates to:
  /// **'Buscar notas y tareas...'**
  String get searchHint;

  /// No description provided for @searchTitle.
  ///
  /// In es, this message translates to:
  /// **'Busca en tus notas y tareas'**
  String get searchTitle;

  /// No description provided for @searchSubtitle.
  ///
  /// In es, this message translates to:
  /// **'Escribe arriba para empezar'**
  String get searchSubtitle;

  /// No description provided for @searchNoResults.
  ///
  /// In es, this message translates to:
  /// **'Sin resultados'**
  String get searchNoResults;

  /// No description provided for @sortBy.
  ///
  /// In es, this message translates to:
  /// **'Ordenar'**
  String get sortBy;

  /// No description provided for @sortLastModified.
  ///
  /// In es, this message translates to:
  /// **'Última modificación'**
  String get sortLastModified;

  /// No description provided for @sortCreated.
  ///
  /// In es, this message translates to:
  /// **'Fecha creación'**
  String get sortCreated;

  /// No description provided for @sortTitle.
  ///
  /// In es, this message translates to:
  /// **'Título'**
  String get sortTitle;

  /// No description provided for @sortPriority.
  ///
  /// In es, this message translates to:
  /// **'Prioridad'**
  String get sortPriority;

  /// No description provided for @loading.
  ///
  /// In es, this message translates to:
  /// **'Cargando...'**
  String get loading;

  /// No description provided for @undo.
  ///
  /// In es, this message translates to:
  /// **'Deshacer'**
  String get undo;

  /// No description provided for @errorLoadNotes.
  ///
  /// In es, this message translates to:
  /// **'Error al cargar notas'**
  String get errorLoadNotes;

  /// No description provided for @errorLoadTasks.
  ///
  /// In es, this message translates to:
  /// **'Error al cargar tareas'**
  String get errorLoadTasks;

  /// No description provided for @errorLoadReminders.
  ///
  /// In es, this message translates to:
  /// **'Error al cargar recordatorios'**
  String get errorLoadReminders;

  /// No description provided for @errorCreateNote.
  ///
  /// In es, this message translates to:
  /// **'Error al crear nota'**
  String get errorCreateNote;

  /// No description provided for @errorUpdateNote.
  ///
  /// In es, this message translates to:
  /// **'Error al actualizar nota'**
  String get errorUpdateNote;

  /// No description provided for @errorDeleteNote.
  ///
  /// In es, this message translates to:
  /// **'Error al eliminar nota'**
  String get errorDeleteNote;

  /// No description provided for @errorArchiveNote.
  ///
  /// In es, this message translates to:
  /// **'Error al archivar nota'**
  String get errorArchiveNote;

  /// No description provided for @errorRestoreNote.
  ///
  /// In es, this message translates to:
  /// **'Error al restaurar nota'**
  String get errorRestoreNote;

  /// No description provided for @errorCreateTask.
  ///
  /// In es, this message translates to:
  /// **'Error al crear tarea'**
  String get errorCreateTask;

  /// No description provided for @errorUpdateTask.
  ///
  /// In es, this message translates to:
  /// **'Error al actualizar tarea'**
  String get errorUpdateTask;

  /// No description provided for @errorDeleteTask.
  ///
  /// In es, this message translates to:
  /// **'Error al eliminar tarea'**
  String get errorDeleteTask;

  /// No description provided for @errorCreateReminder.
  ///
  /// In es, this message translates to:
  /// **'Error al crear recordatorio'**
  String get errorCreateReminder;

  /// No description provided for @errorUpdateReminder.
  ///
  /// In es, this message translates to:
  /// **'Error al actualizar recordatorio'**
  String get errorUpdateReminder;

  /// No description provided for @errorDeleteReminder.
  ///
  /// In es, this message translates to:
  /// **'Error al eliminar recordatorio'**
  String get errorDeleteReminder;

  /// No description provided for @errorCompleteReminder.
  ///
  /// In es, this message translates to:
  /// **'Error al completar recordatorio'**
  String get errorCompleteReminder;

  /// No description provided for @errorLoadCategories.
  ///
  /// In es, this message translates to:
  /// **'Error al cargar categorías'**
  String get errorLoadCategories;

  /// No description provided for @errorCreateCategory.
  ///
  /// In es, this message translates to:
  /// **'Error al crear categoría'**
  String get errorCreateCategory;

  /// No description provided for @taskDueToday.
  ///
  /// In es, this message translates to:
  /// **'Tarea vence hoy'**
  String get taskDueToday;

  /// No description provided for @taskPendingNotification.
  ///
  /// In es, this message translates to:
  /// **'Tienes una tarea pendiente por completar'**
  String get taskPendingNotification;

  /// No description provided for @reminderNotification.
  ///
  /// In es, this message translates to:
  /// **'Tienes un recordatorio pendiente'**
  String get reminderNotification;

  /// No description provided for @noTitle.
  ///
  /// In es, this message translates to:
  /// **'Sin título'**
  String get noTitle;

  /// No description provided for @noDescription.
  ///
  /// In es, this message translates to:
  /// **'Sin descripción'**
  String get noDescription;

  /// No description provided for @taskCount.
  ///
  /// In es, this message translates to:
  /// **'{count, plural, one {{count} tarea pendiente} other {{count} tareas pendientes}}'**
  String taskCount(num count);

  /// No description provided for @noteCount.
  ///
  /// In es, this message translates to:
  /// **'{count, plural, one {{count} nota} other {{count} notas}}'**
  String noteCount(num count);

  /// No description provided for @editProfile.
  ///
  /// In es, this message translates to:
  /// **'Editar perfil'**
  String get editProfile;

  /// No description provided for @changeName.
  ///
  /// In es, this message translates to:
  /// **'Cambiar nombre'**
  String get changeName;

  /// No description provided for @changeEmail.
  ///
  /// In es, this message translates to:
  /// **'Cambiar correo electrónico'**
  String get changeEmail;

  /// No description provided for @changePassword.
  ///
  /// In es, this message translates to:
  /// **'Cambiar contraseña'**
  String get changePassword;

  /// No description provided for @nameLabel.
  ///
  /// In es, this message translates to:
  /// **'Nombre'**
  String get nameLabel;

  /// No description provided for @nameHint.
  ///
  /// In es, this message translates to:
  /// **'Tu nombre'**
  String get nameHint;

  /// No description provided for @newEmailLabel.
  ///
  /// In es, this message translates to:
  /// **'Nuevo correo electrónico'**
  String get newEmailLabel;

  /// No description provided for @currentPasswordLabel.
  ///
  /// In es, this message translates to:
  /// **'Contraseña actual'**
  String get currentPasswordLabel;

  /// No description provided for @newPasswordLabel.
  ///
  /// In es, this message translates to:
  /// **'Nueva contraseña'**
  String get newPasswordLabel;

  /// No description provided for @confirmPasswordLabel.
  ///
  /// In es, this message translates to:
  /// **'Confirmar contraseña'**
  String get confirmPasswordLabel;

  /// No description provided for @passwordMismatch.
  ///
  /// In es, this message translates to:
  /// **'Las contraseñas no coinciden'**
  String get passwordMismatch;

  /// No description provided for @nameUpdated.
  ///
  /// In es, this message translates to:
  /// **'Nombre actualizado'**
  String get nameUpdated;

  /// No description provided for @emailUpdated.
  ///
  /// In es, this message translates to:
  /// **'Correo electrónico actualizado'**
  String get emailUpdated;

  /// No description provided for @passwordUpdated.
  ///
  /// In es, this message translates to:
  /// **'Contraseña actualizada'**
  String get passwordUpdated;

  /// No description provided for @errorUpdateName.
  ///
  /// In es, this message translates to:
  /// **'Error al actualizar nombre'**
  String get errorUpdateName;

  /// No description provided for @errorUpdateEmail.
  ///
  /// In es, this message translates to:
  /// **'Error al actualizar email'**
  String get errorUpdateEmail;

  /// No description provided for @errorUpdatePassword.
  ///
  /// In es, this message translates to:
  /// **'Error al actualizar contraseña'**
  String get errorUpdatePassword;

  /// No description provided for @save.
  ///
  /// In es, this message translates to:
  /// **'Guardar'**
  String get save;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'es'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'es':
      return AppLocalizationsEs();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
