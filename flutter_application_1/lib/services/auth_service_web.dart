import 'dart:html' as html;

Future<String?> redirectToGoogleAuth([String? url]) async {
  if(url != null){
    html.window.location.href = url;
  }
  return null;
}