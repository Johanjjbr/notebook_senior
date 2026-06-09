# Plan de Integración Google — Notebook Senior

> Documento de implementación detallado para conectar la app con servicios de Google.
> Versión: 1.0 — Fecha: 2026-06-09

---

## Índice

- [Fase 0 — Configuración Previa (Google Cloud Console)](#fase-0--configuración-previa-google-cloud-console)
- [Fase 1 — Google Sign-In](#fase-1--google-sign-in)
- [Fase 2 — Subida de Archivos a Notas](#fase-2--subida-de-archivos-a-notas)
- [Fase 3 — Google Calendar (Exportar Eventos)](#fase-3--google-calendar-exportar-eventos)
- [Fase 4 — Compartir Notas entre Usuarios](#fase-4--compartir-notas-entre-usuarios)
- [Nota sobre Google Keep](#nota-sobre-google-keep)
- [Apéndice — Verificación y Testing](#apéndice--verificación-y-testing)

---

## Fase 0 — Configuración Previa (Google Cloud Console)

Antes de tocar código, hay que configurar los servicios de Google.

### 0.1 Crear proyecto en Google Cloud Console

1. Ir a https://console.cloud.google.com
2. Crear proyecto nuevo → "Notebook Senior"
3. Anotar el **Project ID**

### 0.2 Configurar pantalla de consentimiento OAuth

1. Ir a **APIs & Services → OAuth consent screen**
2. Tipo: **External** (o Internal si hay Google Workspace)
3. Completar:
   - App name: `Notebook Senior`
   - User support email: tu email
   - Developer contact: tu email
4. **Scopes**: agregar `.../auth/userinfo.email`, `.../auth/userinfo.profile`, y más adelante `.../auth/calendar.events`
5. **Test users**: agregar los emails de prueba

### 0.3 Crear credenciales OAuth 2.0

Se necesitan **3 tipos** de credenciales para que funcione en todas las plataformas:

#### Web
1. **APIs & Services → Credentials → Create Credentials → OAuth client ID**
2. Application type: **Web application**
3. Name: `Web Client`
4. Authorized JavaScript origins: `http://localhost` (y URL de producción si aplica)
5. Authorized redirect URIs: `http://localhost` (para desarrollo)
6. Guardar el **Client ID**

#### Android
1. **Create Credentials → OAuth client ID → Android**
2. Package name: `com.notebook.senior` (el que esté en `android/app/build.gradle`)
3. SHA-1 certificate fingerprint: obtener con:
   ```bash
   keytool -list -v -keystore %USERPROFILE%\.android\debug.keystore -alias androiddebugkey -storepass android -keypass android
   ```
4. Guardar el **Client ID**

#### iOS
1. **Create Credentials → OAuth client ID → iOS**
2. Bundle ID: `com.notebook.senior` (el que esté en `ios/Runner.xcodeproj`)
3. Guardar el **Client ID** y el **iOS URL scheme** (tiene formato `com.googleusercontent.apps.XXXXX`)

### 0.4 Habilitar Google Calendar API

1. Ir a **APIs & Services → Library**
2. Buscar **Google Calendar API**
3. Habilitarla

### 0.5 Configurar Supabase Auth para Google

1. Ir al dashboard de Supabase → **Authentication → Providers**
2. Habilitar **Google**
3. Pegar el **Client ID** de Web creado arriba
4. Pegar el **Client Secret** (también de la credencial Web)
5. Guardar

### 0.6 Configurar Supabase Storage

1. Ir a Supabase Dashboard → **Storage**
2. Crear bucket: `documentos`
3. Configuración:
   - **Public bucket**: NO (seguridad por RLS)
   - **Allowed MIME types**: image/*, application/pdf, application/msword, application/vnd.openxmlformats-officedocument.*, text/*
   - **File size limit**: 10 MB

4. Agregar políticas RLS para el bucket:

```sql
CREATE POLICY "Usuarios suben sus propios archivos"
  ON storage.objects FOR INSERT
  WITH CHECK (
    bucket_id = 'documentos' AND
    auth.role() = 'authenticated' AND
    (storage.foldername(name))[1] = auth.uid()::text
  );

CREATE POLICY "Usuarios ven sus propios archivos"
  ON storage.objects FOR SELECT
  USING (
    bucket_id = 'documentos' AND
    auth.role() = 'authenticated' AND
    (storage.foldername(name))[1] = auth.uid()::text
  );

CREATE POLICY "Usuarios eliminan sus propios archivos"
  ON storage.objects FOR DELETE
  USING (
    bucket_id = 'documentos' AND
    auth.role() = 'authenticated' AND
    (storage.foldername(name))[1] = auth.uid()::text
  );
```

### 0.7 Agregar variables de entorno

Editar `.env` (ya existe en el proyecto):

```yaml
# Ya existentes
SUPABASE_URL=https://xxxxx.supabase.co
SUPABASE_ANON_KEY=eyJxxxxx

# NUEVAS - Google
GOOGLE_WEB_CLIENT_ID=xxxxx.apps.googleusercontent.com
GOOGLE_ANDROID_CLIENT_ID=xxxxx.apps.googleusercontent.com
GOOGLE_IOS_CLIENT_ID=xxxxx.apps.googleusercontent.com
```

---

## Fase 1 — Google Sign-In

### Archivos a modificar/crear: 5

| Archivo | Acción |
|---|---|
| `pubspec.yaml` | Agregar dependencia `google_sign_in` |
| `lib/main.dart` | Inicializar GoogleSignIn |
| `lib/core/providers/auth_provider.dart` | Agregar método `loginWithGoogle()` |
| `lib/auth/login_screen.dart` | Agregar botón "Iniciar sesión con Google" |
| `lib/configuracion/config_screen.dart` | Mostrar si el usuario usa Google |

### Paso 1.1 — pubspec.yaml

Agregar bajo las dependencias existentes:

```yaml
  google_sign_in: ^6.3.0
```

Luego ejecutar:

```bash
flutter pub get
```

### Paso 1.2 — AuthProvider: agregar login con Google

En `lib/core/providers/auth_provider.dart`:

1. Agregar imports:

```dart
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter/foundation.dart';
```

2. Agregar campo `_googleSignIn` y `_esGoogle`:

```dart
  final GoogleSignIn _googleSignIn;
  bool _esGoogle = false;
```

3. Modificar constructor para inicializar `_googleSignIn`:

```dart
  AuthProvider({SupabaseClient? supabase})
      : _supabase = supabase ?? Supabase.instance.client,
        _googleSignIn = GoogleSignIn(
          scopes: ['email', 'profile'],
        ) {
    _user = _supabase.auth.currentUser;
    _esGoogle = _user?.appMetadata?['provider'] == 'google';
    _authSubscription = _supabase.auth.onAuthStateChange.listen((event) {
      _user = event.session?.user;
      _esGoogle = _user?.appMetadata?['provider'] == 'google';
      notifyListeners();
    });
  }
```

4. Agregar getter:

```dart
  bool get esGoogle => _esGoogle;
```

Nota: al hacer logout con Google, también hay que llamar a `_googleSignIn.signOut()`. No se hace en el método `logout()` de abajo porque `supabase.auth.signOut()` ya maneja la sesión.

5. Agregar método `loginWithGoogle`:

```dart
  Future<String?> loginWithGoogle() async {
    _cargando = true;
    _error = null;
    notifyListeners();

    try {
      if (kIsWeb) {
        // En web, signInWithOAuth redirige al browser
        await _supabase.auth.signInWithOAuth(
          OAuthProvider.google,
          redirectTo: 'http://localhost',  // Ajustar en producción
        );
      } else {
        // En mobile: GoogleSignIn -> Supabase
        final googleUser = await _googleSignIn.signIn();
        if (googleUser == null) {
          _cargando = false;
          notifyListeners();
          return 'Inicio de sesión cancelado';
        }

        final googleAuth = await googleUser.authentication;
        if (googleAuth.idToken == null) {
          _cargando = false;
          notifyListeners();
          return 'Error al obtener token de Google';
        }

        await _supabase.auth.signInWithIdToken(
          provider: OAuthProvider.google,
          idToken: googleAuth.idToken!,
          accessToken: googleAuth.accessToken,
        );
      }
      return null;
    } on AuthException catch (e) {
      _error = e.message;
      return e.message;
    } catch (e) {
      _error = 'Error al iniciar sesión con Google';
      return 'Error al iniciar sesión con Google';
    } finally {
      _cargando = false;
      notifyListeners();
    }
  }
```

6. Agregar método `esProveedorGoogle()` para comprobar si el usuario se registró con Google:

```dart
  bool esProveedorGoogle() {
    return _user?.appMetadata?['provider'] == 'google';
  }
```

7. Modificar `logout()` para también cerrar sesión de Google:

```dart
  Future<void> logout() async {
    _error = null;
    try {
      await _googleSignIn.signOut();
      await _supabase.auth.signOut();
    } catch (e) {
      _error = 'Error al cerrar sesión';
      notifyListeners();
    }
  }
```

### Paso 1.3 — LoginScreen: agregar botón de Google

En `lib/auth/login_screen.dart`:

1. Agregar divider con texto "o" y botón de Google entre el formulario y el TextButton de toggle.

Después del `SizedBox(height: spacingMedium)` que contiene el `FilledButton` de submit (línea 156), y antes del `SizedBox(height: spacingSmall)` y `TextButton`:

```dart
                        // Divider "o"
                        Padding(
                          padding: EdgeInsets.symmetric(vertical: spacingMedium),
                          child: Row(
                            children: [
                              const Expanded(child: Divider()),
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 16),
                                child: Text(
                                  'o',
                                  style: TextStyle(color: Colors.grey[500]),
                                ),
                              ),
                              const Expanded(child: Divider()),
                            ],
                          ),
                        ),

                        // Botón Google
                        SizedBox(
                          width: double.infinity,
                          height: isSmallScreen ? 48 : 52,
                          child: OutlinedButton.icon(
                            onPressed: auth.cargando ? null : () async {
                              final error = await auth.loginWithGoogle();
                              if (error != null && mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(error),
                                    backgroundColor: Colors.red,
                                  ),
                                );
                              }
                            },
                            icon: Image.asset(
                              'assets/google_logo.png',
                              height: 20,
                              width: 20,
                            ),
                            label: const Text('Continuar con Google'),
                          ),
                        ),
```

**Nota**: Si no se quiere usar un asset image para el logo de Google, se puede usar `Text('G')` con estilo bold y color azul como alternativa simple, o descargar el logo de Google Branding.

### Paso 1.4 — Config screen: mostrar proveedor

En `lib/configuracion/config_screen.dart`, modificar el subtítulo del perfil para mostrar el método de autenticación:

```dart
                        Text(
                          auth.esGoogle ? 'Conectado con Google' : 'Conectado con email',
                          style: TextStyle(color: Colors.grey[600]),
                        ),
```

### Paso 1.5 — main.dart: inicializar GoogleSignIn

En `lib/main.dart`, no hace falta inicializar nada adicional porque `GoogleSignIn` se auto-configura. Pero hay que pasarle el client ID de web para que funcione correctamente en todas las plataformas.

Modificar el `AuthProvider` en `main.dart` para pasar los client IDs si es necesario. En realidad, `google_sign_in` detecta automáticamente la plataforma y usa el client ID correspondiente (del `GoogleService-Info.plist` en iOS, de `strings.xml` en Android, o del proporcionado en web). Para web, se configura más abajo.

Para web, agregar en `web/index.html` dentro del `<head>`:

```html
<script src="https://accounts.google.com/gsi/client"></script>
<meta name="google-signin-client_id" content="TU_WEB_CLIENT_ID.apps.googleusercontent.com">
```

### Verificación Fase 1

```bash
flutter run
```

1. Abrir la app → debe mostrar botón "Continuar con Google"
2. Tocar → debe abrir el selector de cuentas Google
3. Seleccionar cuenta → debe crear sesión y redirigir al dashboard
4. Ir a Configuración → debe mostrar "Conectado con Google"
5. Cerrar sesión → debe funcionar correctamente

---

## Fase 2 — Subida de Archivos a Notas

### Archivos a modificar/crear: 10

| Archivo | Acción |
|---|---|
| `pubspec.yaml` | Agregar `file_picker` |
| `supabase/migrations/20250610_archivos.sql` | Crear tabla `nota_archivos` |
| `lib/models/archivo.dart` | **NUEVO** modelo `Archivo` |
| `lib/data/database_service.dart` | Agregar métodos CRUD para archivos |
| `lib/data/supabase_database_service.dart` | Implementar CRUD de archivos |
| `lib/core/providers/notas_provider.dart` | Agregar métodos de archivos + cargar archivos con notas |
| `lib/notas/nota_form_screen.dart` | Agregar sección de adjuntos + file picker |
| `lib/notas/nota_detalle_screen.dart` | **NUEVO** pantalla detalle de nota con galería |
| `lib/notas/notas_list_screen.dart` | Mostrar indicador de archivos en cards |
| `lib/app.dart` | Agregar ruta para detalle de nota |

### Paso 2.1 — pubspec.yaml

```yaml
  file_picker: ^8.1.6
  image_picker: ^1.1.2   # Opcional, para fotos directas con cámara
  mime: ^2.0.0           # Para determinar tipo MIME
```

```bash
flutter pub get
```

### Paso 2.2 — Migración SQL: nota_archivos

Crear `supabase/migrations/20250610_archivos.sql`:

```sql
-- TABLA DE ARCHIVOS ADJUNTOS A NOTAS
CREATE TABLE nota_archivos (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  nota_id UUID REFERENCES notas(id) ON DELETE CASCADE NOT NULL,
  user_id UUID REFERENCES auth.users(id) NOT NULL,
  nombre TEXT NOT NULL,
  tipo_mime TEXT NOT NULL DEFAULT 'application/octet-stream',
  tamano INTEGER NOT NULL DEFAULT 0,
  storage_path TEXT NOT NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX idx_nota_archivos_nota_id ON nota_archivos(nota_id);
CREATE INDEX idx_nota_archivos_user_id ON nota_archivos(user_id);

ALTER TABLE nota_archivos ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Usuarios ven sus propios archivos"
  ON nota_archivos FOR ALL
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);
```

### Paso 2.3 — Modelo Archivo

Crear `lib/models/archivo.dart`:

```dart
class Archivo {
  final String id;
  final String notaId;
  final String userId;
  final String nombre;
  final String tipoMime;
  final int tamano;
  final String storagePath;
  final DateTime createdAt;

  const Archivo({
    required this.id,
    required this.notaId,
    required this.userId,
    required this.nombre,
    required this.tipoMime,
    required this.tamano,
    required this.storagePath,
    required this.createdAt,
  });

  factory Archivo.fromJson(Map<String, dynamic> json) {
    return Archivo(
      id: json['id'] as String,
      notaId: json['nota_id'] as String,
      userId: json['user_id'] as String,
      nombre: json['nombre'] as String,
      tipoMime: json['tipo_mime'] as String? ?? 'application/octet-stream',
      tamano: json['tamano'] as int? ?? 0,
      storagePath: json['storage_path'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id.isNotEmpty) 'id': id,
      'nota_id': notaId,
      'user_id': userId,
      'nombre': nombre,
      'tipo_mime': tipoMime,
      'tamano': tamano,
      'storage_path': storagePath,
    };
  }

  Archivo copyWith({
    String? id,
    String? notaId,
    String? userId,
    String? nombre,
    String? tipoMime,
    int? tamano,
    String? storagePath,
    DateTime? createdAt,
  }) {
    return Archivo(
      id: id ?? this.id,
      notaId: notaId ?? this.notaId,
      userId: userId ?? this.userId,
      nombre: nombre ?? this.nombre,
      tipoMime: tipoMime ?? this.tipoMime,
      tamano: tamano ?? this.tamano,
      storagePath: storagePath ?? this.storagePath,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  bool get esImagen => tipoMime.startsWith('image/');

  String get tamanoFormateado {
    if (tamano < 1024) return '$tamano B';
    if (tamano < 1024 * 1024) return '${(tamano / 1024).toStringAsFixed(1)} KB';
    return '${(tamano / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  String get extension => nombre.contains('.')
      ? nombre.split('.').last.toUpperCase()
      : '';
}
```

### Paso 2.4 — DatabaseService: agregar métodos de archivos

En `lib/data/database_service.dart`, agregar después del método de categorías:

```dart
  Future<List<Archivo>> cargarArchivos(String notaId);
  Future<void> insertarArchivo(Archivo archivo);
  Future<void> eliminarArchivo(String id);
  Future<String> subirArchivoStorage(String userId, String notaId, String fileName, List<int> bytes, String mimeType);
  Future<String> obtenerUrlDescarga(String storagePath);
  Future<void> eliminarArchivoStorage(String storagePath);
```

Y agregar el import:

```dart
import '../models/archivo.dart';
```

### Paso 2.5 — SupabaseDatabaseService: implementar métodos de archivos

En `lib/data/supabase_database_service.dart`, agregar implementaciones:

```dart
  @override
  Future<List<Archivo>> cargarArchivos(String notaId) async {
    final response = await _supabase
        .from('nota_archivos')
        .select()
        .eq('nota_id', notaId)
        .order('created_at', ascending: false);
    return (response as List)
        .map((json) => Archivo.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<void> insertarArchivo(Archivo archivo) async {
    await _supabase.from('nota_archivos').insert(archivo.toJson());
  }

  @override
  Future<void> eliminarArchivo(String id) async {
    await _supabase.from('nota_archivos').delete().eq('id', id);
  }

  @override
  Future<String> subirArchivoStorage(String userId, String notaId, String fileName, List<int> bytes, String mimeType) async {
    final path = '$userId/$notaId/$fileName';
    await _supabase.storage.from('documentos').uploadBinary(
      path,
      bytes,
      fileOptions: FileOptions(contentType: mimeType),
    );
    return path;
  }

  @override
  Future<String> obtenerUrlDescarga(String storagePath) async {
    return _supabase.storage.from('documentos').getPublicUrl(storagePath);
  }

  @override
  Future<void> eliminarArchivoStorage(String storagePath) async {
    await _supabase.storage.from('documentos').remove([storagePath]);
  }
```

### Paso 2.6 — NotasProvider: cargar archivos con notas

En `lib/core/providers/notas_provider.dart`:

1. Agregar campo `_archivos`:

```dart
  Map<String, List<Archivo>> _archivos = {};  // nota_id -> archivos
```

2. Getter:

```dart
  List<Archivo> archivosDeNota(String notaId) => _archivos[notaId] ?? [];
```

3. Al cargar notas, también cargar archivos:

```dart
  Future<void> _cargarArchivosDeNotas() async {
    for (final nota in _notas) {
      try {
        _archivos[nota.id] = await _db.cargarArchivos(nota.id);
      } catch (_) {}
    }
    notifyListeners();
  }
```

Llamar `_cargarArchivosDeNotas()` al final de `cargarNotas()` (después de `_suscribirCambios()`).

4. Agregar métodos para subir/eliminar archivos:

```dart
  Future<void> subirArchivo(String notaId, String filePath, String fileName) async {
    _guardando = true;
    notifyListeners();

    try {
      final file = File(filePath);
      final bytes = await file.readAsBytes();
      final mimeType = lookupMimeType(fileName) ?? 'application/octet-stream';

      final storagePath = await _db.subirArchivoStorage(
        _db.userId, notaId, fileName, bytes, mimeType,
      );

      final archivo = Archivo(
        id: _uuid.v4(),
        notaId: notaId,
        userId: _db.userId,
        nombre: fileName,
        tipoMime: mimeType,
        tamano: bytes.length,
        storagePath: storagePath,
        createdAt: DateTime.now(),
      );

      await _db.insertarArchivo(archivo);
      _archivos[notaId] = [...(_archivos[notaId] ?? []), archivo];
    } catch (e) {
      _error = 'Error al subir archivo';
    }

    _guardando = false;
    notifyListeners();
  }

  Future<void> eliminarArchivo(String archivoId, String notaId, String storagePath) async {
    _eliminando = true;
    notifyListeners();

    try {
      await _db.eliminarArchivoStorage(storagePath);
      await _db.eliminarArchivo(archivoId);
      _archivos[notaId] = (_archivos[notaId] ?? [])
          .where((a) => a.id != archivoId)
          .toList();
    } catch (e) {
      _error = 'Error al eliminar archivo';
    }

    _eliminando = false;
    notifyListeners();
  }
```

5. Al eliminar nota, también limpiar `_archivos`:

```dart
  // En eliminarNota, después de eliminar de DB:
  _archivos.remove(id);
```

6. Agregar import:

```dart
import 'dart:io';
import 'package:mime/mime.dart';
import '../models/archivo.dart';
```

### Paso 2.7 — NotaFormScreen: agregar sección de adjuntos

En `lib/notas/nota_form_screen.dart`:

1. Agregar import:

```dart
import 'package:file_picker/file_picker.dart';
import '../models/archivo.dart';
```

2. Agregar campo `_archivos`:

```dart
  List<Archivo> _archivos = [];
```

3. Cargar archivos si es edición (en `_initForm`):

```dart
  if (widget.notaId != null) {
    _archivos = provider.archivosDeNota(widget.notaId!);
  }
```

4. Agregar método `_seleccionarArchivo`:

```dart
  Future<void> _seleccionarArchivo() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.any,
      allowMultiple: true,
    );

    if (result != null && mounted) {
      final provider = context.read<NotasProvider>();
      for (final file in result.files) {
        if (file.path != null) {
          // Si estamos creando la nota (no tiene ID aún), primero guardamos
          if (widget.notaId == null && _notaOriginal == null) {
            await _guardarYAbrirNota(file);
            return;
          }
          await provider.subirArchivo(
            widget.notaId!,
            file.path!,
            file.name,
          );
        }
      }
      // Recargar archivos
      if (widget.notaId != null) {
        setState(() {
          _archivos = provider.archivosDeNota(widget.notaId!);
        });
      }
    }
  }
```

5. Método auxiliar para crear nota primero y luego subir archivos:

```dart
  Future<void> _guardarYAbrirArchivo(PlatformFile file) async {
    if (!_formKey.currentState!.validate()) return;
    final provider = context.read<NotasProvider>();
    
    // Crear nota primero
    await provider.crearNota(
      Nota(
        id: '',
        userId: '',
        titulo: _tituloController.text.trim().isNotEmpty
            ? _tituloController.text.trim()
            : file.name,
        contenido: _contenidoController.text.trim(),
        color: _colorSeleccionado,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
      categoriaIds: _categoriaIds,
    );
    
    // La nota ya fue creada y recargada, obtener la última
    final nuevaNota = provider.notas.first;
    if (file.path != null) {
      await provider.subirArchivo(nuevaNota.id, file.path!, file.name);
    }
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nota creada con archivo adjunto')),
      );
      Navigator.pop(context);
    }
  }
```

6. En el `build`, agregar sección de archivos después de categorías:

```dart
            const SizedBox(height: 24),
            Row(
              children: [
                Text('Archivos adjuntos', style: theme.textTheme.titleMedium),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.attach_file),
                  tooltip: 'Adjuntar archivo',
                  onPressed: _seleccionarArchivo,
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (_archivos.isEmpty)
              Text(
                'Sin archivos adjuntos',
                style: TextStyle(color: Colors.grey[500]),
              )
            else
              ..._archivos.map((archivo) => ListTile(
                leading: Icon(
                  archivo.esImagen ? Icons.image : Icons.attach_file,
                  color: archivo.esImagen ? Colors.blue : Colors.grey,
                ),
                title: Text(archivo.nombre),
                subtitle: Text(archivo.tamanoFormateado),
                trailing: IconButton(
                  icon: const Icon(Icons.delete_outline, color: Colors.red),
                  onPressed: () async {
                    await provider.eliminarArchivo(
                      archivo.id, widget.notaId!, archivo.storagePath,
                    );
                    setState(() {
                      _archivos = provider.archivosDeNota(widget.notaId!);
                    });
                  },
                ),
              )),
```

**IMPORTANTE**: Cuando el `widget.notaId` es null (creación nueva), los archivos solo se pueden adjuntar después de crear la nota. El flujo es:
1. Llenar título y contenido
2. Tocar el botón de adjuntar
3. Aparece un diálogo "Primero guarda la nota" o se guarda automáticamente y luego se adjunta

Para simplificar, la implementación de arriba lo maneja guardando automáticamente si no hay notaId.

### Paso 2.8 — NotaDetalleScreen (nueva)

Crear `lib/notas/nota_detalle_screen.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../core/providers/notas_provider.dart';
import '../models/nota.dart';
import '../models/archivo.dart';
import '../widgets/color_utils.dart';

class NotaDetalleScreen extends StatefulWidget {
  final String notaId;

  const NotaDetalleScreen({super.key, required this.notaId});

  @override
  State<NotaDetalleScreen> createState() => _NotaDetalleScreenState();
}

class _NotaDetalleScreenState extends State<NotaDetalleScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<NotasProvider>().cargarNotas();
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<NotasProvider>();
    final nota = provider.notas.where((n) => n.id == widget.notaId).firstOrNull;

    if (nota == null) {
      return Scaffold(
        appBar: AppBar(),
        body: const Center(child: Text('Nota no encontrada')),
      );
    }

    final archivos = provider.archivosDeNota(nota.id);
    final bgColor = parseColor(nota.color);
    final textColor = bgColor.computeLuminance() > 0.5
        ? Colors.black87
        : Colors.white;

    return Scaffold(
      appBar: AppBar(
        title: Text(nota.titulo.isNotEmpty ? nota.titulo : 'Sin título'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () => context.go('/notas/editar/${nota.id}'),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Contenido de la nota
          Card(
            color: bgColor,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    nota.titulo.isNotEmpty ? nota.titulo : 'Sin título',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: textColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (nota.categorias.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 4,
                      children: nota.categorias.map((c) => Chip(
                        label: Text(c.nombre, style: const TextStyle(fontSize: 12)),
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      )).toList(),
                    ),
                  ],
                  const SizedBox(height: 16),
                  Text(
                    nota.contenido,
                    style: TextStyle(fontSize: 16, color: textColor),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 24),

          // Archivos adjuntos
          Row(
            children: [
              Text(
                'Archivos adjuntos (${archivos.length})',
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ],
          ),
          const SizedBox(height: 8),

          if (archivos.isEmpty)
            Text(
              'Sin archivos adjuntos',
              style: TextStyle(color: Colors.grey[500]),
            )
          else
            ...archivos.map((archivo) => _buildArchivoTile(archivo)),
        ],
      ),
    );
  }

  Widget _buildArchivoTile(Archivo archivo) {
    if (archivo.esImagen) {
      return Card(
        margin: const EdgeInsets.only(bottom: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
              child: Image.network(
                '${Supabase.instance.client.storage.from('documentos').getPublicUrl(archivo.storagePath)}',
                width: double.infinity,
                height: 200,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(
                  height: 200,
                  color: Colors.grey[200],
                  child: const Center(child: Icon(Icons.broken_image, size: 48)),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      archivo.nombre,
                      style: const TextStyle(fontWeight: FontWeight.w500),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Text(archivo.tamanoFormateado,
                      style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                ],
              ),
            ),
          ],
        ),
      );
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: const Icon(Icons.description, color: Colors.blue),
        title: Text(archivo.nombre),
        subtitle: Text(archivo.tamanoFormateado),
      ),
    );
  }
}
```

### Paso 2.9 — NotasListScreen: mostrar indicador de archivos

En `lib/notas/notas_list_screen.dart`, dentro del `itemBuilder` del GridView, después de mostrar categorías (después de línea 331, el `)` que cierra el Wrap de categorías), agregar indicador:

```dart
                                        if (provider.archivosDeNota(nota.id).isNotEmpty)
                                          Padding(
                                            padding: const EdgeInsets.only(top: 4),
                                            child: Row(
                                              children: [
                                                Icon(Icons.attach_file, size: 14, color: mutedColor),
                                                const SizedBox(width: 2),
                                                Text(
                                                  '${provider.archivosDeNota(nota.id).length}',
                                                  style: TextStyle(fontSize: 11, color: mutedColor),
                                                ),
                                              ],
                                            ),
                                          ),
```

También hacer que el contenido de la nota sea tappable para ir al detalle (ya existe el `GestureDetector` en línea 297-307, modificar para ir a detalle o edición):

Cambiar `onTap` de ir a editar a ir a detalle:

```dart
                                          child: GestureDetector(
                                            onTap: () =>
                                                context.go('/notas/detalle/${nota.id}'),
                                            ...
```

### Paso 2.10 — app.dart: agregar ruta de detalle

En `lib/app.dart`, dentro de las rutas de `/notas`, agregar:

```dart
              GoRoute(
                path: 'detalle/:id',
                builder: (context, state) => NotaDetalleScreen(
                  notaId: state.pathParameters['id']!,
                ),
              ),
```

Importar:

```dart
import 'notas/nota_detalle_screen.dart';
```

### Verificación Fase 2

```bash
flutter run
```

1. Crear nota nueva → debe mostrar sección "Archivos adjuntos"
2. Tocar botón de adjuntar → debe abrir el file picker
3. Seleccionar imagen → debe aparecer en la lista de archivos
4. Guardar nota → los archivos persisten al recargar
5. En la lista de notas, debe verse un indicador de archivos
6. Tocar una nota → debe ir al detalle con galería de imágenes

---

## Fase 3 — Google Calendar (Exportar Eventos)

### Archivos a modificar/crear: 12

| Archivo | Acción |
|---|---|
| `pubspec.yaml` | Agregar `googleapis`, `extension_google_sign_in_as_googleapis_auth` |
| `lib/core/services/calendar_sync_service.dart` | **NUEVO** servicio de sincronización con Calendar |
| `lib/core/providers/auth_provider.dart` | Agregar scope de Calendar al login |
| `lib/models/recordatorio.dart` | Agregar `sincronizarCalendar`, `googleEventId` |
| `lib/models/tarea.dart` | Agregar `sincronizarCalendar`, `googleEventId` |
| `supabase/migrations/20250611_google_calendar.sql` | Agregar columnas de Calendar |
| `lib/data/database_service.dart` | Agregar métodos para campos Calendar |
| `lib/data/supabase_database_service.dart` | Implementar actualización de campos Calendar |
| `lib/core/providers/recordatorios_provider.dart` | Integrar Calendar al crear/editar recordatorios |
| `lib/core/providers/tareas_provider.dart` | Integrar Calendar al crear/editar tareas |
| `lib/recordatorios/recordatorios_screen.dart` | Agregar toggle "Sincronizar con Calendar" |
| `lib/tareas/tarea_form_screen.dart` | Agregar toggle "Crear evento en Calendar" |

### Paso 3.1 — pubspec.yaml

```yaml
  googleapis: ^13.1.0
  googleapis_auth: ^1.6.0
  extension_google_sign_in_as_googleapis_auth: ^2.0.4
```

```bash
flutter pub get
```

### Paso 3.2 — Modelos: agregar campos de Calendar

#### Recordatorio (`lib/models/recordatorio.dart`)

Agregar campos:

```dart
  final bool sincronizarCalendar;
  final String? googleEventId;
```

Actualizar constructor:

```dart
  const Recordatorio({
    ...
    this.sincronizarCalendar = false,
    this.googleEventId,
    ...
  });
```

Actualizar `fromJson`:

```dart
      sincronizarCalendar: json['sincronizar_calendar'] as bool? ?? false,
      googleEventId: json['google_event_id'] as String?,
```

Actualizar `toJson`:

```dart
      'sincronizar_calendar': sincronizarCalendar,
      if (googleEventId != null) 'google_event_id': googleEventId,
```

Actualizar `copyWith`:

```dart
    bool? sincronizarCalendar,
    String? googleEventId,
```

```dart
      sincronizarCalendar: sincronizarCalendar ?? this.sincronizarCalendar,
      googleEventId: googleEventId ?? this.googleEventId,
```

#### Tarea (`lib/models/tarea.dart`)

Mismos campos agregar:

```dart
  final bool sincronizarCalendar;
  final String? googleEventId;
```

Seguir el mismo patrón que Recordatorio para constructor, fromJson, toJson y copyWith.

### Paso 3.3 — Migración SQL

Crear `supabase/migrations/20250611_google_calendar.sql`:

```sql
-- Agregar campos de sincronización con Google Calendar

ALTER TABLE recordatorios
  ADD COLUMN sincronizar_calendar BOOLEAN NOT NULL DEFAULT false,
  ADD COLUMN google_event_id TEXT;

ALTER TABLE tareas
  ADD COLUMN sincronizar_calendar BOOLEAN NOT NULL DEFAULT false,
  ADD COLUMN google_event_id TEXT;
```

### Paso 3.4 — CalendarSyncService (nuevo)

Crear `lib/core/services/calendar_sync_service.dart`:

```dart
import 'package:googleapis/calendar/v3.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:extension_google_sign_in_as_googleapis_auth/extension_google_sign_in_as_googleapis_auth.dart';

class CalendarSyncService {
  static final CalendarSyncService _instance = CalendarSyncService._();
  factory CalendarSyncService() => _instance;
  CalendarSyncService._();

  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: [CalendarApi.calendarEventsScope],
  );

  Future<CalendarApi?> _getApi() async {
    try {
      final account = await _googleSignIn.signInSilently();
      if (account == null) return null;
      final authHeader = await account.authHeaders;
      final client = AutoRefreshingAuthClient.fromGoogleSignInAccount(account);
      return CalendarApi(client);
    } catch (_) {
      return null;
    }
  }

  Future<String?> crearEvento({
    required String titulo,
    String? descripcion,
    required DateTime inicio,
    DateTime? fin,
    String? recordatorioId,
  }) async {
    final api = await _getApi();
    if (api == null) return null;

    final event = Event()
      ..summary = titulo
      ..description = descripcion
      ..start = EventDateTime()
        ..dateTime = inicio
        ..timeZone = DateTime.now().timeZoneName
      ..end = EventDateTime()
        ..dateTime = fin ?? inicio.add(const Duration(hours: 1))
        ..timeZone = DateTime.now().timeZoneName;

    if (recordatorioId != null) {
      event.extendedProperties = ExtendedProperties(
        private: {'appRecordatorioId': recordatorioId},
      );
    }

    try {
      final created = await api.events.insert(event, 'primary');
      return created.id;
    } catch (e) {
      return null;
    }
  }

  Future<bool> actualizarEvento({
    required String eventId,
    required String titulo,
    String? descripcion,
    required DateTime inicio,
    DateTime? fin,
  }) async {
    final api = await _getApi();
    if (api == null) return false;

    try {
      final event = await api.events.get('primary', eventId);
      event
        ..summary = titulo
        ..description = descripcion
        ..start = EventDateTime()
          ..dateTime = inicio
          ..timeZone = DateTime.now().timeZoneName
        ..end = EventDateTime()
          ..dateTime = fin ?? inicio.add(const Duration(hours: 1))
          ..timeZone = DateTime.now().timeZoneName;

      await api.events.update(event, 'primary', eventId);
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> eliminarEvento(String eventId) async {
    final api = await _getApi();
    if (api == null) return false;

    try {
      await api.events.delete('primary', eventId);
      return true;
    } catch (_) {
      return false;
    }
  }
}
```

### Paso 3.5 — DatabaseService: métodos para Calendar

En `lib/data/database_service.dart`, agregar:

```dart
  Future<void> actualizarGoogleEventIdRecordatorio(String id, String? googleEventId);
  Future<void> actualizarSincronizarCalendarRecordatorio(String id, bool value);
  Future<void> actualizarGoogleEventIdTarea(String id, String? googleEventId);
  Future<void> actualizarSincronizarCalendarTarea(String id, bool value);
```

### Paso 3.6 — SupabaseDatabaseService: implementar

```dart
  @override
  Future<void> actualizarGoogleEventIdRecordatorio(String id, String? googleEventId) async {
    await _supabase.from('recordatorios').update({
      'google_event_id': googleEventId,
    }).eq('id', id);
  }

  @override
  Future<void> actualizarSincronizarCalendarRecordatorio(String id, bool value) async {
    await _supabase.from('recordatorios').update({
      'sincronizar_calendar': value,
    }).eq('id', id);
  }

  @override
  Future<void> actualizarGoogleEventIdTarea(String id, String? googleEventId) async {
    await _supabase.from('tareas').update({
      'google_event_id': googleEventId,
    }).eq('id', id);
  }

  @override
  Future<void> actualizarSincronizarCalendarTarea(String id, bool value) async {
    await _supabase.from('tareas').update({
      'sincronizar_calendar': value,
    }).eq('id', id);
  }
```

### Paso 3.7 — AuthProvider: agregar scope de Calendar

En `lib/core/providers/auth_provider.dart`:

1. Agregar import:

```dart
import 'package:googleapis/calendar/v3.dart';
```

2. Modificar el `GoogleSignIn` para incluir scope de Calendar:

```dart
        _googleSignIn = GoogleSignIn(
          scopes: ['email', 'profile', CalendarApi.calendarEventsScope],
        ),
```

### Paso 3.8 — RecordatoriosProvider: integrar Calendar

En `lib/core/providers/recordatorios_provider.dart`:

1. Agregar import y campo:

```dart
import '../services/calendar_sync_service.dart';
```

```dart
  final _calendarSync = CalendarSyncService();
```

2. Modificar `crearRecordatorio` para sincronizar:

```dart
  Future<void> crearRecordatorio(Recordatorio recordatorio, {bool sincronizarCalendar = false}) async {
    _guardando = true;
    _error = null;
    notifyListeners();

    try {
      final nuevo = recordatorio.copyWith(
        id: _uuid.v4(),
        userId: _db.userId,
        createdAt: DateTime.now(),
      );

      await _db.crearRecordatorio(nuevo);
      await _notificacionService.programarRecordatorio(nuevo);

      // Sincronizar con Google Calendar si aplica
      String? googleEventId;
      if (sincronizarCalendar) {
        googleEventId = await _calendarSync.crearEvento(
          titulo: nuevo.titulo,
          descripcion: nuevo.descripcion.isNotEmpty
              ? nuevo.descripcion
              : null,
          inicio: nuevo.fechaHora,
          recordatorioId: nuevo.id,
        );
      }

      if (googleEventId != null) {
        await _db.actualizarGoogleEventIdRecordatorio(nuevo.id, googleEventId);
        await _db.actualizarSincronizarCalendarRecordatorio(nuevo.id, true);
      }

      await cargarRecordatorios();
    } catch (e) {
      _error = 'Error al crear recordatorio';
      notifyListeners();
    }

    _guardando = false;
    notifyListeners();
  }
```

3. Modificar `actualizarRecordatorio` para Calendar:

```dart
  Future<void> actualizarRecordatorio(
    Recordatorio recordatorio, {
    bool sincronizarCalendar = false,
  }) async {
    _guardando = true;
    _error = null;
    notifyListeners();

    try {
      await _db.actualizarRecordatorio(recordatorio);

      await _notificacionService.cancelarRecordatorio(recordatorio.id);
      if (!recordatorio.completado) {
        await _notificacionService.programarRecordatorio(recordatorio);
      }

      // Calendar sync
      if (recordatorio.googleEventId != null) {
        // Actualizar evento existente
        if (!recordatorio.sincronizarCalendar && !sincronizarCalendar) {
          // No hacer nada
        } else if (!sincronizarCalendar) {
          // Eliminar evento si desactivaron la sincronización
          await _calendarSync.eliminarEvento(recordatorio.googleEventId!);
          await _db.actualizarGoogleEventIdRecordatorio(recordatorio.id, null);
          await _db.actualizarSincronizarCalendarRecordatorio(recordatorio.id, false);
        } else {
          // Actualizar
          await _calendarSync.actualizarEvento(
            eventId: recordatorio.googleEventId!,
            titulo: recordatorio.titulo,
            descripcion: recordatorio.descripcion.isNotEmpty
                ? recordatorio.descripcion
                : null,
            inicio: recordatorio.fechaHora,
          );
        }
      } else if (sincronizarCalendar && !recordatorio.completado) {
        // Crear nuevo evento
        final eventId = await _calendarSync.crearEvento(
          titulo: recordatorio.titulo,
          descripcion: recordatorio.descripcion.isNotEmpty
              ? recordatorio.descripcion
              : null,
          inicio: recordatorio.fechaHora,
          recordatorioId: recordatorio.id,
        );
        if (eventId != null) {
          await _db.actualizarGoogleEventIdRecordatorio(recordatorio.id, eventId);
          await _db.actualizarSincronizarCalendarRecordatorio(recordatorio.id, true);
        }
      }

      await cargarRecordatorios();
    } catch (e) {
      _error = 'Error al actualizar recordatorio';
      notifyListeners();
    }

    _guardando = false;
    notifyListeners();
  }
```

4. Modificar `eliminarRecordatorio` para Calendar:

```dart
  Future<void> eliminarRecordatorio(String id) async {
    _eliminando = true;
    _error = null;
    _ultimoRecordatorioEliminado =
        _recordatorios.where((r) => r.id == id).firstOrNull;
    notifyListeners();

    try {
      // Eliminar evento de Calendar si existe
      final recordatorio = _ultimoRecordatorioEliminado;
      if (recordatorio?.googleEventId != null) {
        await _calendarSync.eliminarEvento(recordatorio!.googleEventId!);
      }

      await _db.eliminarRecordatorio(id);
      await _notificacionService.cancelarRecordatorio(id);
      await cargarRecordatorios();
    } catch (e) {
      ...
```

### Paso 3.9 — TareasProvider: integrar Calendar

Mismo patrón que RecordatoriosProvider. En `lib/core/providers/tareas_provider.dart`:

1. Agregar imports:

```dart
import '../services/calendar_sync_service.dart';
```

```dart
  final _calendarSync = CalendarSyncService();
```

2. Modificar `crearTarea`:

```dart
  Future<void> crearTarea(
    Tarea tarea, {
    List<ChecklistItem>? checklistItems,
    List<String>? categoriaIds,
    bool sincronizarCalendar = false,
  }) async {
    // ... existing code ...

    await _db.crearTarea(tareaJson);

    // Calendar sync
    if (sincronizarCalendar && tarea.fechaVencimiento != null) {
      final eventId = await _calendarSync.crearEvento(
        titulo: tarea.titulo,
        descripcion: tarea.descripcion.isNotEmpty ? tarea.descripcion : null,
        inicio: tarea.fechaVencimiento!,
        fin: tarea.fechaVencimiento!.add(const Duration(hours: 23, minutes: 59)),
      );
      if (eventId != null) {
        await _db.actualizarGoogleEventIdTarea(tareaId, eventId);
        await _db.actualizarSincronizarCalendarTarea(tareaId, true);
      }
    }

    // ... rest of code ...
  }
```

Seguir el mismo patrón para `actualizarTarea` y `eliminarTarea`.

### Paso 3.10 — RecordatoriosScreen: toggle de Calendar

En `lib/recordatorios/recordatorios_screen.dart`, en el método `_mostrarDialogo`:

Agregar:

```dart
  bool _sincronizarCalendar = false;
  if (existente != null) _sincronizarCalendar = existente.sincronizarCalendar;
```

Después del selector de hora y antes del botón guardar:

```dart
                    SwitchListTile(
                      secondary: Image.asset(
                        'assets/google_calendar_logo.png',
                        height: 24,
                        width: 24,
                        errorBuilder: (context, error, stackTrace) =>
                            const Icon(Icons.calendar_month, color: Colors.blue),
                      ),
                      title: const Text('Sincronizar con Google Calendar'),
                      subtitle: const Text(
                        'Crea un evento en tu calendario',
                        style: TextStyle(fontSize: 12),
                      ),
                      value: _sincronizarCalendar,
                      onChanged: (v) => setSheetState(() {
                        _sincronizarCalendar = v;
                      }),
                    ),
```

Modificar la llamada a `crearRecordatorio`:

```dart
await provider.crearRecordatorio(
  Recordatorio(...),
  sincronizarCalendar: _sincronizarCalendar,
);
```

Y `actualizarRecordatorio`:

```dart
await provider.actualizarRecordatorio(
  existente.copyWith(...),
  sincronizarCalendar: _sincronizarCalendar,
);
```

### Paso 3.11 — TareaFormScreen: toggle de Calendar

En `lib/tareas/tarea_form_screen.dart`:

Agregar campo:

```dart
  bool _sincronizarCalendar = false;
```

Cargar desde la tarea original si es edición (en `_initForm`):

```dart
  _sincronizarCalendar = _tareaOriginal?.sincronizarCalendar ?? false;
```

En el `build`, después del selector de fecha y antes de "Checklist":

```dart
            SwitchListTile(
              secondary: const Icon(Icons.calendar_month, color: Colors.blue),
              title: const Text('Crear evento en Google Calendar'),
              subtitle: const Text(
                'Solo si tiene fecha de vencimiento',
                style: TextStyle(fontSize: 12),
              ),
              value: _sincronizarCalendar,
              onChanged: _fechaVencimiento != null
                  ? (v) => setState(() => _sincronizarCalendar = v)
                  : null,
            ),
            const SizedBox(height: 16),
```

Modificar `_guardar` para pasar el flag:

```dart
      await provider.actualizarTarea(
        ...,
        sincronizarCalendar: _sincronizarCalendar,
      );
```

```dart
      await provider.crearTarea(
        ...,
        sincronizarCalendar: _sincronizarCalendar,
      );
```

### Verificación Fase 3

```bash
flutter run
```

1. Iniciar sesión con Google (necesario para obtener token de Calendar)
2. Ir a Recordatorios → crear nuevo → debe mostrar toggle "Sincronizar con Google Calendar"
3. Activar toggle y guardar → evento debe aparecer en Google Calendar
4. Editar recordatorio → cambios deben reflejarse en Calendar
5. Eliminar recordatorio → evento debe eliminarse de Calendar
6. Ir a Tareas → crear tarea con fecha → toggle disponible
7. Desactivar toggle → solo guarda local

---

## Fase 4 — Compartir Notas entre Usuarios

### Archivos a modificar/crear: 8

| Archivo | Acción |
|---|---|
| `supabase/migrations/20250612_compartir.sql` | Crear tabla `notas_compartidas` |
| `lib/models/nota_compartida.dart` | **NUEVO** modelo |
| `lib/data/database_service.dart` | Agregar métodos para compartir |
| `lib/data/supabase_database_service.dart` | Implementar |
| `lib/core/providers/notas_provider.dart` | Cargar notas compartidas + métodos CRUD |
| `lib/notas/nota_form_screen.dart` | Agregar sección "Compartir" |
| `lib/notas/notas_list_screen.dart` | Mostrar indicador de notas compartidas |
| `lib/app.dart` | (sin cambios) |

### Paso 4.1 — Migración SQL

Crear `supabase/migrations/20250612_compartir.sql`:

```sql
-- COMPARTIR NOTAS ENTRE USUARIOS
CREATE TABLE notas_compartidas (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  nota_id UUID REFERENCES notas(id) ON DELETE CASCADE NOT NULL,
  usuario_email TEXT NOT NULL,
  permiso TEXT NOT NULL DEFAULT 'lectura'
    CHECK (permiso IN ('lectura', 'escritura')),
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  UNIQUE(nota_id, usuario_email)
);

CREATE INDEX idx_notas_compartidas_nota_id ON notas_compartidas(nota_id);
CREATE INDEX idx_notas_compartidas_email ON notas_compartidas(usuario_email);

ALTER TABLE notas_compartidas ENABLE ROW LEVEL SECURITY;

-- El dueño de la nota puede gestionar los permisos
CREATE POLICY "Dueño gestiona compartidos"
  ON notas_compartidas FOR ALL
  USING (
    EXISTS (SELECT 1 FROM notas WHERE id = nota_id AND user_id = auth.uid())
  )
  WITH CHECK (
    EXISTS (SELECT 1 FROM notas WHERE id = nota_id AND user_id = auth.uid())
  );

-- El usuario compartido puede ver las notas compartidas con él
CREATE POLICY "Usuario ve notas compartidas con él"
  ON notas FOR SELECT
  USING (
    auth.uid() = user_id OR
    EXISTS (
      SELECT 1 FROM notas_compartidas
      WHERE nota_id = id AND usuario_email = auth.email()
    )
  );

-- El usuario compartido con permisos de escritura puede editar
CREATE POLICY "Usuario edita notas compartidas con escritura"
  ON notas FOR UPDATE
  USING (
    auth.uid() = user_id OR
    EXISTS (
      SELECT 1 FROM notas_compartidas
      WHERE nota_id = id AND usuario_email = auth.email() AND permiso = 'escritura'
    )
  )
  WITH CHECK (
    auth.uid() = user_id OR
    EXISTS (
      SELECT 1 FROM notas_compartidas
      WHERE nota_id = id AND usuario_email = auth.email() AND permiso = 'escritura'
    )
  );
```

**Nota importante**: Las políticas RLS existentes para `notas` usaban solo `auth.uid() = user_id`. Ahora se reemplazan las políticas de SELECT y UPDATE para incluir notas compartidas.

### Paso 4.2 — Modelo NotaCompartida

Crear `lib/models/nota_compartida.dart`:

```dart
class NotaCompartida {
  final String id;
  final String notaId;
  final String usuarioEmail;
  final String permiso;  // 'lectura' | 'escritura'
  final DateTime createdAt;

  const NotaCompartida({
    required this.id,
    required this.notaId,
    required this.usuarioEmail,
    required this.permiso,
    required this.createdAt,
  });

  factory NotaCompartida.fromJson(Map<String, dynamic> json) {
    return NotaCompartida(
      id: json['id'] as String,
      notaId: json['nota_id'] as String,
      usuarioEmail: json['usuario_email'] as String,
      permiso: json['permiso'] as String? ?? 'lectura',
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id.isNotEmpty) 'id': id,
      'nota_id': notaId,
      'usuario_email': usuarioEmail,
      'permiso': permiso,
    };
  }

  String get permisoLabel => permiso == 'lectura' ? 'Solo lectura' : 'Puede editar';
}
```

### Paso 4.3 — DatabaseService: métodos de compartir

```dart
  Future<List<NotaCompartida>> obtenerCompartidos(String notaId);
  Future<void> compartirNota(String notaId, String email, String permiso);
  Future<void> quitarCompartido(String compartidoId);
  Future<List<Nota>> cargarNotasCompartidasConmigo();
```

### Paso 4.4 — SupabaseDatabaseService: implementar

```dart
  @override
  Future<List<NotaCompartida>> obtenerCompartidos(String notaId) async {
    final response = await _supabase
        .from('notas_compartidas')
        .select()
        .eq('nota_id', notaId);
    return (response as List)
        .map((json) => NotaCompartida.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<void> compartirNota(String notaId, String email, String permiso) async {
    await _supabase.from('notas_compartidas').insert({
      'nota_id': notaId,
      'usuario_email': email,
      'permiso': permiso,
    });
  }

  @override
  Future<void> quitarCompartido(String compartidoId) async {
    await _supabase.from('notas_compartidas').delete().eq('id', compartidoId);
  }

  @override
  Future<List<Nota>> cargarNotasCompartidasConmigo() async {
    final response = await _supabase
        .from('notas')
        .select('*, categorias:nota_categorias(categoria_id, categorias(*))')
        .not('user_id', 'eq', userId)
        .eq('notas_compartidas.usuario_email', _supabase.auth.currentUser!.email)
        .order('updated_at', ascending: false);

    return (response as List).map((json) {
      final categorias = (json['categorias'] as List<dynamic>?)
              ?.map((e) => Categoria.fromJson(
                  (e as Map<String, dynamic>)['categorias'] as Map<String, dynamic>))
              .toList() ??
          [];
      return Nota.fromJson(json).copyWith(categorias: categorias);
    }).toList();
  }
```

**Nota**: La query de `cargarNotasCompartidasConmigo` puede requerir ajustes dependiendo de la relación exacta en Supabase. Alternativa: primero obtener los nota_id de `notas_compartidas` donde `usuario_email = current email`, luego cargar esas notas.

### Paso 4.5 — NotasProvider: integrar compartir

En `lib/core/providers/notas_provider.dart`:

```dart
import '../models/nota_compartida.dart';
```

Campos:

```dart
  Map<String, List<NotaCompartida>> _compartidos = {};
  List<Nota> _notasCompartidasConmigo = [];
```

Getter:

```dart
  List<NotaCompartida> compartidosDeNota(String notaId) => _compartidos[notaId] ?? [];
  List<Nota> get notasCompartidasConmigo => _notasCompartidasConmigo;
```

Métodos:

```dart
  Future<void> cargarCompartidos(String notaId) async {
    try {
      _compartidos[notaId] = await _db.obtenerCompartidos(notaId);
      notifyListeners();
    } catch (_) {}
  }

  Future<void> compartirNota(String notaId, String email, String permiso) async {
    _guardando = true;
    _error = null;
    notifyListeners();

    try {
      await _db.compartirNota(notaId, email, permiso);
      await cargarCompartidos(notaId);
    } catch (e) {
      _error = 'Error al compartir nota';
      notifyListeners();
    }

    _guardando = false;
    notifyListeners();
  }

  Future<void> quitarCompartido(String notaId, String compartidoId) async {
    try {
      await _db.quitarCompartido(compartidoId);
      await cargarCompartidos(notaId);
    } catch (_) {}
  }

  Future<void> cargarNotasCompartidas() async {
    try {
      _notasCompartidasConmigo = await _db.cargarNotasCompartidasConmigo();
      notifyListeners();
    } catch (_) {}
  }
```

### Paso 4.6 — NotaFormScreen: sección "Compartir"

En la pantalla de edición de nota (cuando `widget.notaId != null`), agregar sección de compartir después de los archivos.

```dart
            if (widget.notaId != null) ...[
              const SizedBox(height: 24),
              Text('Compartir nota', style: theme.textTheme.titleMedium),
              const SizedBox(height: 8),
              
              // Lista de personas con acceso
              ...provider.compartidosDeNota(widget.notaId!).map((c) => ListTile(
                leading: CircleAvatar(
                  child: Text(c.usuarioEmail[0].toUpperCase()),
                ),
                title: Text(c.usuarioEmail),
                subtitle: Text(c.permisoLabel),
                trailing: IconButton(
                  icon: const Icon(Icons.remove_circle_outline, color: Colors.red),
                  onPressed: () => provider.quitarCompartido(widget.notaId!, c.id),
                ),
              )),

              // Botón para agregar persona
              TextButton.icon(
                icon: const Icon(Icons.person_add),
                label: const Text('Compartir con...'),
                onPressed: () => _mostrarDialogoCompartir(),
              ),
            ],
```

Método `_mostrarDialogoCompartir`:

```dart
  void _mostrarDialogoCompartir() {
    final emailCtrl = TextEditingController();
    final permisoNotifier = ValueNotifier<String>('lectura');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Compartir nota'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: emailCtrl,
              decoration: const InputDecoration(
                labelText: 'Correo electrónico',
                hintText: 'usuario@ejemplo.com',
              ),
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 16),
            ValueListenableBuilder<String>(
              valueListenable: permisoNotifier,
              builder: (context, permiso, _) => SegmentedButton<String>(
                segments: const [
                  ButtonSegment(value: 'lectura', label: Text('Solo lectura')),
                  ButtonSegment(value: 'escritura', label: Text('Puede editar')),
                ],
                selected: {permiso},
                onSelectionChanged: (v) => permisoNotifier.value = v.first,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () {
              final email = emailCtrl.text.trim();
              if (email.isNotEmpty && email.contains('@')) {
                provider.compartirNota(
                  widget.notaId!, email, permisoNotifier.value,
                );
                Navigator.pop(ctx);
              }
            },
            child: const Text('Compartir'),
          ),
        ],
      ),
    );
  }
```

### Paso 4.7 — NotasListScreen: indicador de compartidas y filtro

1. En la card de nota, agregar icono si tiene compartidos:

```dart
                                        // Después del título y antes de categorías
                                        if (provider.compartidosDeNota(nota.id).isNotEmpty)
                                          Icon(Icons.people_outline, size: 14, color: mutedColor),
```

2. Agregar un botón en el AppBar para ver notas compartidas conmigo:

```dart
          IconButton(
            icon: const Icon(Icons.people_outline),
            tooltip: 'Compartidas conmigo',
            onPressed: () {
              showModalBottomSheet(
                context: context,
                builder: (ctx) => ListView(
                  children: provider.notasCompartidasConmigo.map((nota) => ListTile(
                    title: Text(nota.titulo),
                    subtitle: Text('Compartida por: ${nota.userId}'),
                    onTap: () => context.go('/notas/detalle/${nota.id}'),
                  )).toList(),
                ),
              );
            },
          ),
```

### Verificación Fase 4

```bash
flutter run
```

1. Crear nota → ir a editar → debe mostrar "Compartir nota" sección
2. Ingresar email de otro usuario → seleccionar permiso → compartir
3. Cerrar sesión e iniciar con el otro usuario → debe ver la nota compartida
4. Si el permiso es "lectura", no debe poder editar
5. Si el permiso es "escritura", debe poder editar

---

## Nota sobre Google Keep

**Google Keep no tiene API pública oficial**. No es posible leer notas desde Keep de forma programática.

### Alternativa: importar desde Google Takeout

1. El usuario va a https://takeout.google.com/
2. Selecciona solo "Google Keep"
3. Exporta (recibe ZIP con archivos JSON+HTML)
4. En la app, implementar función "Importar desde Takeout":
   - Subir el archivo ZIP
   - Parsear los JSON de Keep
   - Convertir a formato `Nota`
   - Marcar con un tag especial

Si se desea implementar esta alternativa:

Crear `lib/services/keep_import_service.dart`:

```dart
import 'dart:convert';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import '../models/nota.dart';

class KeepImportService {
  Future<List<Nota>> importarDesdeTakeout() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['zip', 'json'],
    );

    if (result == null || result.files.isEmpty) return [];

    final file = result.files.first;
    if (file.extension == 'zip') {
      // Descomprimir y buscar archivos .json de Keep
      return _procesarZip(file.path!);
    } else {
      // Archivo JSON individual
      return _procesarJson(file.path!);
    }
  }

  Future<List<Nota>> _procesarJson(String path) async {
    final content = await File(path).readAsString();
    final json = jsonDecode(content) as Map<String, dynamic>;
    return [_convertirNotaKeep(json)];
  }

  Future<List<Nota>> _procesarZip(String path) async {
    // Usar package:archive/archive.dart para descomprimir
    // Buscar archivos .json que tengan estructura de Keep
    return [];
  }

  Nota _convertirNotaKeep(Map<String, dynamic> keepJson) {
    // Formato de Keep:
    // {
    //   "title": "...",
    //   "textContent": "...",
    //   "lists": [...],
    //   "color": "...",
    //   "isArchived": bool,
    //   "createdTimestampUsec": 123456789,
    //   "userEditedTimestampUsec": 123456789,
    // }
    return Nota(
      id: '',
      userId: '',
      titulo: keepJson['title'] as String? ?? '',
      contenido: keepJson['textContent'] as String? ?? '',
      color: _keepColorToHex(keepJson['color'] as String?),
      archivada: keepJson['isArchived'] as bool? ?? false,
      createdAt: DateTime.fromMicrosecondsSinceEpoch(
        (keepJson['createdTimestampUsec'] as int?) ?? 0,
      ),
      updatedAt: DateTime.fromMicrosecondsSinceEpoch(
        (keepJson['userEditedTimestampUsec'] as int?) ?? 0,
      ),
    );
  }

  String _keepColorToHex(String? keepColor) {
    // Mapear colores de Keep a colores de la app
    switch (keepColor) {
      case 'RED': return '#FFCCCC';
      case 'ORANGE': return '#FFD9B3';
      case 'YELLOW': return '#FFF3CD';
      case 'GREEN': return '#D4EDDA';
      case 'BLUE': return '#CCE5FF';
      case 'PURPLE': return '#E8D5F5';
      case 'PINK': return '#F5D5E0';
      case 'BROWN': return '#E8DCC8';
      case 'GRAY': return '#E0E0E0';
      default: return '#FFF3CD';
    }
  }
}
```

Para descompresión ZIP, agregar dependencia:

```yaml
  archive: ^4.0.2
```

---

## Apéndice — Verificación y Testing

### Verificar análisis de Dart

```bash
flutter analyze
```

No debe reportar errores. Las warnings de `prefer_const_constructors` se pueden ignorar.

### Ejecutar tests existentes

```bash
flutter test
```

Los 19 tests existentes deben seguir pasando. Si se rompen, actualizar mocks en `test/mocks/mock_database_service.dart` para incluir los nuevos métodos.

### MockDatabaseService actualizado

En `test/mocks/mock_database_service.dart`, agregar stubs para los nuevos métodos:

```dart
// Fase 2 - Archivos
  @override
  Future<List<Archivo>> cargarArchivos(String notaId) async => [];
  @override
  Future<void> insertarArchivo(Archivo archivo) async {}
  @override
  Future<void> eliminarArchivo(String id) async {}
  @override
  Future<String> subirArchivoStorage(String userId, String notaId, String fileName, List<int> bytes, String mimeType) async => '';
  @override
  Future<String> obtenerUrlDescarga(String storagePath) async => '';
  @override
  Future<void> eliminarArchivoStorage(String storagePath) async {}

// Fase 3 - Calendar
  @override
  Future<void> actualizarGoogleEventIdRecordatorio(String id, String? googleEventId) async {}
  @override
  Future<void> actualizarSincronizarCalendarRecordatorio(String id, bool value) async {}
  @override
  Future<void> actualizarGoogleEventIdTarea(String id, String? googleEventId) async {}
  @override
  Future<void> actualizarSincronizarCalendarTarea(String id, bool value) async {}

// Fase 4 - Compartir
  @override
  Future<List<NotaCompartida>> obtenerCompartidos(String notaId) async => [];
  @override
  Future<void> compartirNota(String notaId, String email, String permiso) async {}
  @override
  Future<void> quitarCompartido(String compartidoId) async {}
  @override
  Future<List<Nota>> cargarNotasCompartidasConmigo() async => [];
```

### Configuración Android (google_sign_in)

En `android/app/build.gradle`, agregar en `defaultConfig`:

```gradle
manifestPlaceholders = [
    googleSignInClientId: "TU_WEB_CLIENT_ID.apps.googleusercontent.com"
]
```

Opcional: configurar `default_web_client_id` en `android/app/src/main/res/values/strings.xml`:

```xml
<string name="default_web_client_id" translatable="false">TU_WEB_CLIENT_ID.apps.googleusercontent.com</string>
```

### Configuración iOS

1. Abrir `ios/Runner.xcworkspace` en Xcode
2. En `Runner/Info.plist`, agregar:

```xml
<key>CFBundleURLTypes</key>
<array>
  <dict>
    <key>CFBundleTypeRole</key>
    <string>Editor</string>
    <key>CFBundleURLName</key>
    <string>com.googleusercontent.apps.TU_IOS_CLIENT_ID</string>
    <key>CFBundleURLSchemes</key>
    <array>
      <string>com.googleusercontent.apps.TU_IOS_CLIENT_ID</string>
    </array>
  </dict>
</array>
```

3. Si se usa CocoaPods, `pod install`

### Configuración Web

En `web/index.html`, dentro del `<head>`:

```html
<script src="https://accounts.google.com/gsi/client"></script>
<meta name="google-signin-client_id" content="TU_WEB_CLIENT_ID.apps.googleusercontent.com">
```

### Roadmap de implementación sugerido

| Día | Fase | Tareas |
|---|---|---|
| 1 | Fase 0 | Google Cloud Console, Supabase Auth/Storage |
| 2 | Fase 1 | Google Sign-In completo |
| 3 | Fase 2 (parte 1) | SQL, modelo, DatabaseService, Provider |
| 4 | Fase 2 (parte 2) | UI: formulario, detalle, lista |
| 5 | Fase 3 (parte 1) | CalendarSyncService, modelos, DB |
| 6 | Fase 3 (parte 2) | Integración en providers + UI toggles |
| 7 | Fase 4 | Compartir notas completo |
| 8 | Testing | Verificar todo, corregir bugs |

---

*Documento generado para implementación asistida por IA.*
