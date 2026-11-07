import 'dart:async';
import 'package:services_immobilier/features/favorites_profile/edit_profile_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:services_immobilier/features/auth/auth_screen.dart';

import 'package:services_immobilier/screens/home_screen.dart';
import 'package:services_immobilier/screens/map_screen.dart';
import 'package:services_immobilier/screens/favorites_screen.dart';
import 'package:services_immobilier/screens/messages_screen.dart';
import 'package:services_immobilier/screens/profile_screen.dart';
import 'package:services_immobilier/screens/my_listings_screen.dart';
import 'package:services_immobilier/screens/login_screen.dart';
import 'package:services_immobilier/screens/publish_screen.dart';
import 'package:services_immobilier/screens/listing_detail_screen.dart';
import 'package:services_immobilier/screens/chat_screen.dart';

/// Prévient go_router quand l'utilisateur se connecte / se déconnecte.
class _AuthNotifier extends ChangeNotifier {
  _AuthNotifier() {
    _sub = FirebaseAuth.instance.authStateChanges().listen((_) {
      notifyListeners();
    });
  }

  late final StreamSubscription<User?> _sub;

  @override
  void dispose() {
    _sub.cancel();
    super.dispose();
  }
}

final GoRouter router = GoRouter(
  initialLocation: '/home',
  refreshListenable: _AuthNotifier(),
  redirect: (context, state) {
    final bool loggedIn = FirebaseAuth.instance.currentUser != null;
    final bool onAuth = state.matchedLocation == '/auth';
    if (!loggedIn && !onAuth) return '/auth'; // pas connecté -> connexion
    if (loggedIn && onAuth) return '/home'; // connecté -> accueil + barre
    return null;
  },
  routes: [
    // Les 5 onglets avec la barre de navigation
    StatefulShellRoute.indexedStack(
      builder: (context, state, shell) {
        return Scaffold(
          body: shell,
          bottomNavigationBar: NavigationBar(
            selectedIndex: shell.currentIndex,
            onDestinationSelected: (index) => shell.goBranch(
              index,
              initialLocation: index == shell.currentIndex,
            ),
            destinations: const [
              NavigationDestination(
                icon: Icon(Icons.home_outlined),
                selectedIcon: Icon(Icons.home),
                label: 'Accueil',
              ),
              NavigationDestination(
                icon: Icon(Icons.map_outlined),
                selectedIcon: Icon(Icons.map),
                label: 'Carte',
              ),
              NavigationDestination(
                icon: Icon(Icons.favorite_border),
                selectedIcon: Icon(Icons.favorite),
                label: 'Favoris',
              ),
              NavigationDestination(
                icon: Icon(Icons.chat_bubble_outline),
                selectedIcon: Icon(Icons.chat_bubble),
                label: 'Messages',
              ),
              NavigationDestination(
                icon: Icon(Icons.person_outline),
                selectedIcon: Icon(Icons.person),
                label: 'Profil',
              ),
            ],
          ),
        );
      },
      branches: [
        StatefulShellBranch(routes: [
          GoRoute(
            path: '/home',
            builder: (context, state) => const HomeScreen(),
          ),
        ]),
        StatefulShellBranch(routes: [
          GoRoute(
            path: '/map',
            builder: (context, state) => const MapScreen(),
          ),
        ]),
        StatefulShellBranch(routes: [
          GoRoute(
            path: '/favorites',
            builder: (context, state) => const FavoritesScreen(),
          ),
        ]),
        StatefulShellBranch(routes: [
          GoRoute(
            path: '/messages',
            builder: (context, state) => const MessagesScreen(),
          ),
        ]),
        StatefulShellBranch(routes: [
          GoRoute(
            path: '/profile',
            builder: (context, state) => const ProfileScreen(),
          ),
        ]),
      ],
    ),

    // Écran de connexion / inscription (Firebase)
    GoRoute(
      path: '/auth',
      builder: (context, state) => const AuthScreen(),
    ),

    // Écrans hors onglets (sans barre de navigation)
    GoRoute(
      path: '/login',
      builder: (context, state) => const LoginScreen(),
    ),
    GoRoute(
      path: '/listing/new',
      builder: (context, state) => const PublishScreen(),
    ),
        GoRoute(
      path: '/listing/:id/edit',
      builder: (context, state) =>
          PublishScreen(listingId: state.pathParameters['id']),
    ),
    GoRoute(
      path: '/my-listings',
      builder: (context, state) => const MyListingsScreen(),
    ),
    GoRoute(
      path: '/listing/:id',
      builder: (context, state) =>
          ListingDetailScreen(id: state.pathParameters['id']!),
    ),
    GoRoute(
      path: '/chat/:id',
      builder: (context, state) =>
          ChatScreen(id: state.pathParameters['id']!),
    ),
        GoRoute(
      path: '/profile/edit',
      builder: (context, state) => const EditProfileScreen(),
    ),
  ],
);