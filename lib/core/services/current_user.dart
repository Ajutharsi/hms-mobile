import 'package:flutter/foundation.dart';

/// The signed-in user's picture, as every shell shows it.
///
/// The avatar in a role's header and drawer used to come from the
/// [AppUser] captured at login, which never changed again: upload a new
/// picture, go back, and the old one was still there until the next sign
/// in. The profile screens know the new URL the moment the server
/// answers, so they publish it here and the shells listen.
///
/// It is a plain notifier rather than a provider because the shells sit
/// above the profile screens in the tree, not below them -- there is no
/// common ancestor to hang a ChangeNotifier on without rebuilding the
/// navigation.
final ValueNotifier<String?> myPhotoUrl = ValueNotifier<String?>(null);

/// Called wherever the server has just told us what the picture is: on
/// sign-in, on session restore, and after a profile loads or saves.
void rememberMyPhoto(String? url) {
  if (myPhotoUrl.value != url) myPhotoUrl.value = url;
}

/// Sign-out: the next account must not inherit this one's face.
void forgetMyPhoto() => myPhotoUrl.value = null;
