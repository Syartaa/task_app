import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:frontend/core/services/sp_service.dart';
import 'package:frontend/features/auth/repository/auth_local_repository.dart';
import 'package:frontend/features/auth/repository/auth_remote_repository.dart';
import 'package:frontend/models/user_model.dart';

part 'auth_state.dart';

class AuthCubit extends Cubit<AuthState> {
  AuthCubit() : super(AuthInitial());

  final authRemoteRepository = AuthRemoteRepository();
  final authLocalRepository = AuthLocalRepository();
  final spService = SpService();

  void getUserData() async {
    try {
      emit(AuthLoading());
      final userModel = await authRemoteRepository.getUserData();
      if (userModel != null) {
        await authLocalRepository.insertUser(userModel);
        emit(AuthLoggedIn(userModel));
      } else {
        emit(AuthInitial());
      }
    } catch (e) {
      print("Error fetching user data: $e");
      emit(AuthInitial());
    }
  }

  void signUp({
    required String name,
    required String email,
    required String password,
  }) async {
    try {
      emit(AuthLoading());
      print("Signing up user: $name, $email");
      await authRemoteRepository.signUp(
        name: name,
        email: email,
        password: password,
      );
      emit(AuthSignUp());
      print("User signed up successfully");
    } catch (e) {
      print("SignUp error: $e");
      emit(AuthError(e.toString()));
    }
  }

  void login({
    required String email,
    required String password,
  }) async {
    try {
      emit(AuthLoading());
      print("Logging in user: $email");
      final userModel = await authRemoteRepository.login(
        email: email,
        password: password,
      );

      if (userModel.token.isNotEmpty) {
        spService.setToken(userModel.token);
      }

      await authLocalRepository.insertUser(userModel);

      emit(AuthLoggedIn(userModel));
      print("User logged in: ${userModel.name}");
    } catch (e) {
      print("Login error: $e");
      emit(AuthError(e.toString()));
    }
  }

  void logout() async {
    try {
      // Clear the saved token
      await spService.removeToken();
      // Clear user data from local repository
      await authLocalRepository.clearUser();
      // Emit the initial state (logged out)
      emit(AuthInitial());
    } catch (e) {
      print("Logout error: $e");
      emit(AuthError("Logout failed"));
    }
  }
}
