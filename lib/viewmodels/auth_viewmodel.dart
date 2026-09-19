// =============================================================================
// Projeto    : Treinix – Treinador Digital para Atletas Amadores
// Arquivo    : lib/viewmodels/auth_viewmodel.dart
// Camada     : ViewModel – Autenticação
// Descrição  : Estado e lógica de autenticação; escuta mudanças no Firebase Auth
// -----------------------------------------------------------------------------
// Autor      : Adelson Fernando Alvarez Oliveira
// Instituição: Pontifícia Universidade Católica do Paraná – PUC/PR
// Curso      : Pós-graduação em Desenvolvimento de Aplicativos Móveis
// Ano        : 2026
// =============================================================================

import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../data/models/user_model.dart';

enum AuthStatus { idle, loading, success, error }

class AuthViewModel extends ChangeNotifier {
  final _auth = FirebaseAuth.instance;
  final _db   = FirebaseFirestore.instance;

  AuthStatus _status       = AuthStatus.idle;
  String?    _errorMessage;
  UserModel? _currentUser;

  AuthStatus get status        => _status;
  String?    get errorMessage  => _errorMessage;
  UserModel? get currentUser   => _currentUser;
  bool       get isLoggedIn    => _auth.currentUser != null;
  bool       get isGoogleUser  =>
      _auth.currentUser?.providerData
          .any((p) => p.providerId == 'google.com') ?? false;
  bool       get isLoading     => _status == AuthStatus.loading;

  AuthViewModel() {
    // Escuta mudanças de estado de autenticação
    _auth.authStateChanges().listen(_onAuthChanged);
  }

  Future<void> _onAuthChanged(User? user) async {
    if (user != null) {
      // Força refresh do token ao detectar login
      await user.getIdToken(true);
      _currentUser = await _loadUserModel(user.uid);
    } else {
      _currentUser = null;
    }
    notifyListeners();
  }

  Future<UserModel?> _loadUserModel(String uid) async {
    try {
      final doc = await _db.collection('users').doc(uid).get();
      if (doc.exists) return UserModel.fromFirestore(doc);
    } catch (e) {
      debugPrint('[AuthViewModel] Erro ao carregar usuário: $e');
    }
    return null;
  }

  Future<bool> signUp({
    required String name,
    required String email,
    required String password,
  }) async {
    _setStatus(AuthStatus.loading);
    try {
      final cred = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      final user = cred.user!;
      await user.updateDisplayName(name);

      // Cria documento do usuário no Firestore (registra consentimento LGPD)
      final now = DateTime.now();
      final userModel = UserModel(
        uid:          user.uid,
        name:         name,
        email:        email,
        modalities:   [],
        level:        Level.iniciante,
        goal:         Goal.resistencia,
        onboardingDone: false,
        createdAt:    now,
        consentGiven: true,
        consentDate:  now,
      );
      await _db.collection('users').doc(user.uid).set(userModel.toFirestore());

      // Força refresh do token imediatamente após cadastro
      await user.getIdToken(true);

      _currentUser = userModel;
      _setStatus(AuthStatus.success);
      return true;
    } on FirebaseAuthException catch (e) {
      _errorMessage = _mapError(e.code);
      _setStatus(AuthStatus.error);
      return false;
    }
  }

  /// Autentica via Google.
  /// Web: popup nativo do Firebase. Android: fluxo nativo via google_sign_in.
  /// null + status==idle → usuário cancelou (sem mensagem de erro)
  /// null + status==error → erro real
  Future<String?> signInWithGoogle() async {
    _setStatus(AuthStatus.loading);
    try {
      UserCredential cred;

      if (kIsWeb) {
        cred = await _auth.signInWithPopup(GoogleAuthProvider());
      } else {
        // Android: fluxo nativo via google_sign_in + credencial Firebase
        final googleSignIn  = GoogleSignIn();
        final googleUser    = await googleSignIn.signIn();
        if (googleUser == null) {
          // Usuário cancelou — não é um erro, não mostra mensagem
          _setStatus(AuthStatus.idle);
          return null;
        }
        final googleAuth = await googleUser.authentication;
        final credential = GoogleAuthProvider.credential(
          accessToken: googleAuth.accessToken,
          idToken:     googleAuth.idToken,
        );
        cred = await _auth.signInWithCredential(credential);
      }

      final user = cred.user!;
      final doc  = await _db.collection('users').doc(user.uid).get();

      if (!doc.exists) {
        // Novo usuário — cria documento e encaminha para onboarding
        final now = DateTime.now();
        final model = UserModel(
          uid:            user.uid,
          name:           user.displayName ?? '',
          email:          user.email ?? '',
          modalities:     [],
          level:          Level.iniciante,
          goal:           Goal.resistencia,
          onboardingDone: false,
          createdAt:      now,
          consentGiven:   true,
          consentDate:    now,
        );
        await _db.collection('users').doc(user.uid).set(model.toFirestore());
        _currentUser = model;
      } else {
        _currentUser = UserModel.fromFirestore(doc);
      }

      _setStatus(AuthStatus.success);
      return _currentUser!.onboardingDone ? '/home' : '/onboarding';
    } on FirebaseAuthException catch (e) {
      if (e.code == 'popup-closed-by-user') {
        _setStatus(AuthStatus.idle);
        return null;
      }
      _errorMessage = switch (e.code) {
        'popup-blocked' =>
            'Popup bloqueado pelo navegador. Permita popups para este site.',
        'account-exists-with-different-credential' =>
            'Este e-mail já está cadastrado com outro método de login.',
        _ => _mapError(e.code),
      };
      _setStatus(AuthStatus.error);
      return null;
    } catch (_) {
      _errorMessage = 'Erro ao entrar com Google. Tente novamente.';
      _setStatus(AuthStatus.error);
      return null;
    }
  }

  Future<bool> signIn({
    required String email,
    required String password,
  }) async {
    _setStatus(AuthStatus.loading);
    try {
      final cred = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      // Força refresh do token imediatamente após login
      await cred.user?.getIdToken(true);
      _setStatus(AuthStatus.success);
      return true;
    } on FirebaseAuthException catch (e) {
      _errorMessage = _mapError(e.code);
      _setStatus(AuthStatus.error);
      return false;
    }
  }

  /// Atualiza o modelo em memória sem bater no Firestore (após edição local).
  void updateCurrentUser(UserModel updated) {
    _currentUser = updated;
    notifyListeners();
  }

  Future<void> signOut() async {
    await _auth.signOut();
    _currentUser = null;
    notifyListeners();
  }

  /// Exclui permanentemente a conta e todos os dados do usuário no Firestore.
  /// Re-autenticação automática: Google para contas OAuth, senha para e-mail/senha.
  /// [password] obrigatório apenas para contas e-mail/senha; ignorado para Google.
  Future<bool> deleteAccount({String? password}) async {
    final user = _auth.currentUser;
    if (user == null) {
      _errorMessage = 'Usuário não encontrado.';
      _setStatus(AuthStatus.error);
      return false;
    }

    _setStatus(AuthStatus.loading);
    try {
      final providers = user.providerData.map((p) => p.providerId).toList();

      if (providers.contains('google.com')) {
        // Re-autenticação via Google (mesmo fluxo do login)
        final googleSignIn = GoogleSignIn();
        final googleUser   = await googleSignIn.signIn();
        if (googleUser == null) {
          // Usuário cancelou — não é um erro
          _setStatus(AuthStatus.idle);
          return false;
        }
        final googleAuth = await googleUser.authentication;
        final credential = GoogleAuthProvider.credential(
          accessToken: googleAuth.accessToken,
          idToken:     googleAuth.idToken,
        );
        await user.reauthenticateWithCredential(credential);
      } else {
        // Re-autenticação via e-mail + senha
        if (password == null || password.isEmpty || user.email == null) {
          _errorMessage = 'Senha não pode estar vazia.';
          _setStatus(AuthStatus.error);
          return false;
        }
        final credential = EmailAuthProvider.credential(
          email:    user.email!,
          password: password,
        );
        await user.reauthenticateWithCredential(credential);
      }

      // Apaga todos os dados do Firestore antes de remover a conta Auth.
      await _deleteAllUserData(user.uid);

      // Remove a conta do Firebase Authentication.
      await user.delete();

      _currentUser = null;
      _setStatus(AuthStatus.idle);
      return true;
    } on FirebaseAuthException catch (e) {
      _errorMessage = switch (e.code) {
        'wrong-password' || 'invalid-credential' =>
            'Senha incorreta. Tente novamente.',
        'too-many-requests' =>
            'Muitas tentativas. Aguarde alguns minutos.',
        _ => 'Erro ao excluir conta: ${e.message}',
      };
      _setStatus(AuthStatus.error);
      return false;
    } catch (_) {
      _errorMessage = 'Erro ao apagar dados. Tente novamente.';
      _setStatus(AuthStatus.error);
      return false;
    }
  }

  /// Apaga todos os documentos nas subcoleções do usuário e depois o documento
  /// principal. No Firestore, excluir um documento NÃO exclui subcoleções.
  Future<void> _deleteAllUserData(String uid) async {
    final userRef = _db.collection('users').doc(uid);

    for (final sub in ['trainings', 'plans', 'suggestions']) {
      var snap = await userRef.collection(sub).limit(100).get();
      while (snap.docs.isNotEmpty) {
        for (final doc in snap.docs) {
          await doc.reference.delete();
        }
        if (snap.docs.length < 100) break;
        snap = await userRef.collection(sub).limit(100).get();
      }
    }

    await userRef.delete();
  }

  void _setStatus(AuthStatus s) {
    _status = s;
    notifyListeners();
  }

  String _mapError(String code) => switch (code) {
        'user-not-found' ||
        'wrong-password' ||
        'invalid-credential'  => 'E-mail ou senha incorretos.',
        'email-already-in-use' => 'Este e-mail já está cadastrado.',
        'weak-password'        => 'Senha fraca. Use 8+ caracteres, maiúscula, número e símbolo.',
        'invalid-email'        => 'E-mail inválido.',
        _                      => 'Algo deu errado. Tente novamente.',
      };
}