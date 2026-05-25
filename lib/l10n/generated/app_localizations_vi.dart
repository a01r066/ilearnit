// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Vietnamese (`vi`).
class AppLocalizationsVi extends AppLocalizations {
  AppLocalizationsVi([String locale = 'vi']) : super(locale);

  @override
  String get appTitle => 'iLearnIt';

  @override
  String get languageEnglish => 'English';

  @override
  String get languageVietnamese => 'Tiếng Việt';

  @override
  String get navHome => 'Trang chủ';

  @override
  String get navCourses => 'Khoá học';

  @override
  String get navInstructors => 'Giảng viên';

  @override
  String get navProfile => 'Hồ sơ';

  @override
  String get homeWelcomeAnon => 'Chào mừng đến với iLearnIt';

  @override
  String homeWelcomeNamed(String name) {
    return 'Xin chào, $name 👋';
  }

  @override
  String get homeWelcomeSubtitle => 'Hôm nay bạn muốn luyện tập gì?';

  @override
  String get homeBrowseByInstrument => 'Khám phá theo nhạc cụ';

  @override
  String get homeFeaturedCourses => 'Khoá học nổi bật';

  @override
  String get homeSeeAll => 'Xem tất cả';

  @override
  String get homeNoFeaturedYet => 'Chưa có khoá học nổi bật.';

  @override
  String get instrumentGuitar => 'Guitar';

  @override
  String get instrumentPiano => 'Piano';

  @override
  String get instrumentViolin => 'Violin';

  @override
  String get coursesTitle => 'Khoá học';

  @override
  String get coursesFilterAll => 'Tất cả';

  @override
  String get coursesEmpty => 'Không tìm thấy khoá học nào.';

  @override
  String get instructorsTitle => 'Giảng viên';

  @override
  String get settingsTitle => 'Cài đặt';

  @override
  String get settingsAppearance => 'Giao diện';

  @override
  String get settingsTheme => 'Chủ đề';

  @override
  String get settingsThemeDescription =>
      'Chọn giao diện cho ứng dụng. Theo hệ thống sẽ tự đổi sáng/tối theo thiết bị.';

  @override
  String get settingsThemeSystem => 'Theo hệ thống';

  @override
  String get settingsThemeVibrant => 'Rực rỡ';

  @override
  String get settingsThemeProfessional => 'Chuyên nghiệp';

  @override
  String get settingsLanguage => 'Ngôn ngữ';

  @override
  String get settingsLanguageDescription =>
      'Chọn ngôn ngữ hiển thị cho ứng dụng.';

  @override
  String get authSignIn => 'Đăng nhập';

  @override
  String get authSignUp => 'Đăng ký';

  @override
  String get authSignOut => 'Đăng xuất';

  @override
  String get authEmail => 'Email';

  @override
  String get authPassword => 'Mật khẩu';

  @override
  String get authConfirmPassword => 'Xác nhận mật khẩu';

  @override
  String get authForgotPassword => 'Quên mật khẩu?';

  @override
  String get authNoAccount => 'Chưa có tài khoản?';

  @override
  String get authHaveAccount => 'Đã có tài khoản?';

  @override
  String get commonOk => 'OK';

  @override
  String get commonCancel => 'Huỷ';

  @override
  String get commonRetry => 'Thử lại';

  @override
  String get commonSave => 'Lưu';

  @override
  String get commonLoading => 'Đang tải…';

  @override
  String get commonError => 'Đã xảy ra lỗi';

  @override
  String get commonEmpty => 'Chưa có nội dung';

  @override
  String get purchaseBuy => 'Mua';

  @override
  String purchaseBuyForPrice(String price) {
    return 'Mua với giá $price';
  }

  @override
  String get purchaseOwned => 'Đã sở hữu';

  @override
  String get purchaseRestore => 'Khôi phục giao dịch';

  @override
  String get purchaseRestoring => 'Đang khôi phục…';

  @override
  String get purchaseRestored => 'Đã khôi phục giao dịch.';

  @override
  String get lectureLocked =>
      'Bài học này đang bị khoá. Mua khoá học để mở khoá.';

  @override
  String get lectureFreePreview => 'Xem thử miễn phí';
}
