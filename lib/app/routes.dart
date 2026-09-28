/// Every route path in one place. Use these helpers instead of string
/// literals so a renamed route is a one-line change.
abstract final class AppRoutes {
  static const home = '/';
  static const signIn = '/sign-in';
  static const settings = '/settings';
  static const boardPattern = '/board/:id';
  static const pdfPattern = '/pdf/:id';

  static String board(String id) => '/board/$id';
  static String pdf(String id) => '/pdf/$id';
}
