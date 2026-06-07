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
  String homePopularInstrument(String instrument) {
    return 'Khoá học $instrument phổ biến';
  }

  @override
  String get homeNoPopularYet => 'Chưa có khoá học phổ biến.';

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
  String get authOrContinueWith => 'hoặc đăng nhập bằng';

  @override
  String get authContinueWithGoogle => 'Tiếp tục với Google';

  @override
  String get authContinueWithApple => 'Tiếp tục với Apple';

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

  @override
  String get subscriptionTitle => 'Gói đăng ký';

  @override
  String get subscriptionActivePlans => 'Gói đang hoạt động';

  @override
  String get subscriptionNoneActive => 'Bạn chưa đăng ký gói nào';

  @override
  String get subscriptionAvailable => 'Các gói đăng ký có sẵn';

  @override
  String get personalPlan => 'Gói cá nhân';

  @override
  String get personalPlanIntro =>
      'Cơ hội mới đang chờ đón. Đăng ký Gói Cá Nhân để nhận tất cả những điều này và hơn thế nữa:';

  @override
  String get personalPlanFeature1 => 'Truy cập tất cả khoá học nhạc cổ điển';

  @override
  String get personalPlanFeature2 => 'Khoá học guitar, piano và violin';

  @override
  String get personalPlanFeature3 => 'Bản nhạc, bài tập và hỏi đáp';

  @override
  String get personalPlanLearnMoreTitle => 'Về Gói Cá Nhân';

  @override
  String get personalPlanLearnMoreBody =>
      'Gói Cá Nhân cho bạn truy cập không giới hạn mọi khoá học trên iLearnIt với một mức giá hàng tháng hoặc hàng năm. Đổi nhạc cụ bất kỳ lúc nào, học theo tốc độ riêng, huỷ bất cứ khi nào.';

  @override
  String get startSubscription => 'Bắt đầu đăng ký';

  @override
  String get learnMore => 'Tìm hiểu thêm';

  @override
  String startingAtPerMonth(String price) {
    return 'Chỉ từ $price mỗi tháng. Huỷ bất cứ lúc nào.';
  }

  @override
  String subscriptionRenewsOn(String date) {
    return 'Gia hạn vào $date';
  }

  @override
  String subscriptionCancelsOn(String date) {
    return 'Sẽ huỷ vào $date';
  }

  @override
  String get planBilledYearly => 'Thanh toán hàng năm';

  @override
  String get planBilledMonthly => 'Thanh toán hàng tháng';

  @override
  String get checkoutTitle => 'Thanh toán';

  @override
  String get yearlyAccess => 'Gói năm';

  @override
  String get monthlyAccess => 'Gói tháng';

  @override
  String get billedYearly => 'thanh toán hàng năm';

  @override
  String get billedMonthly => 'thanh toán hàng tháng';

  @override
  String saveAmount(String amount) {
    return 'Tiết kiệm $amount';
  }

  @override
  String get checkoutFeature1 =>
      'Truy cập mọi khoá học iLearnIt, bất cứ lúc nào';

  @override
  String get checkoutFeature2 =>
      'Bài học thực hành cho guitar, piano và violin';

  @override
  String get checkoutFeature3 => 'Gợi ý khoá học theo mục tiêu của bạn';

  @override
  String get summary => 'Tóm tắt';

  @override
  String get totalDueToday => 'Tổng thanh toán hôm nay:';

  @override
  String checkoutBillingDisclaimer(String total) {
    return 'Huỷ bất cứ lúc nào tại trang Gói đăng ký trong tài khoản của bạn. Đăng ký bắt đầu ngay khi thanh toán và khoản phí $total (cộng thuế áp dụng) sẽ được tính ngay và tự động vào mỗi chu kỳ thanh toán cho đến khi bạn huỷ. Khi đặt đơn này, bạn đồng ý với Điều khoản Sử dụng và cho phép khoản phí định kỳ này. Không hoàn tiền trừ khi luật yêu cầu.';
  }

  @override
  String get searchHint => 'Tìm khoá học';

  @override
  String get searchCancel => 'Huỷ';

  @override
  String get searchRecentSearches => 'Tìm kiếm gần đây';

  @override
  String get searchClear => 'Xoá';

  @override
  String get searchEmptyState => 'Tìm khoá học, giảng viên hoặc chủ đề.';

  @override
  String searchNoMatchesForQuery(String query) {
    return 'Không có kết quả cho \"$query\"';
  }

  @override
  String get searchTryDifferent => 'Thử từ khác hoặc điều chỉnh bộ lọc.';

  @override
  String get badgeBestseller => 'Bán chạy';

  @override
  String get badgeHighestRated => 'Đánh giá cao';

  @override
  String get badgeNew => 'Mới';

  @override
  String get songbooksTitle => 'Songbooks';

  @override
  String get songbooksSearchHint => 'Tìm Songbook';

  @override
  String get songbooksRecentlyViewed => 'Đã xem gần đây';

  @override
  String get songbooksBestsellers => 'Bán chạy nhất';

  @override
  String get songbooksTrialTitle => 'Dùng thử miễn phí 7 ngày';

  @override
  String get songbooksTrialSubtitle => 'Chạm để mở khoá dùng thử 7 ngày';

  @override
  String get songbookGet => 'Mở khoá Songbook';

  @override
  String get songbookSave => 'Lưu';

  @override
  String get songbookSample => 'Xem thử';

  @override
  String get songbookIncludes => 'Bao gồm';

  @override
  String get songbookViewAll => 'xem tất cả';

  @override
  String get songbookInstrument => 'NHẠC CỤ';

  @override
  String get songbookTopics => 'CHỦ ĐỀ';

  @override
  String get songbookPublisher => 'NHÀ XUẤT BẢN';

  @override
  String get songbookReviews => 'Đánh giá';

  @override
  String get songbookYouMightAlsoLike => 'Bạn có thể cũng thích';

  @override
  String get songbookNotFound => 'Không tìm thấy songbook.';

  @override
  String get songbookNoReviewsYet => 'Chưa có đánh giá.';

  @override
  String get instructorTitle => 'Giảng viên';

  @override
  String get instructorTotalStudents => 'Tổng số học viên';

  @override
  String get instructorReviews => 'Đánh giá';

  @override
  String get instructorAboutMe => 'Về tôi';

  @override
  String instructorAboutName(String name) {
    return 'Về $name';
  }

  @override
  String get instructorShowMore => 'Xem thêm';

  @override
  String get instructorShowLess => 'Thu gọn';

  @override
  String instructorMyCoursesCount(int count) {
    return 'Khoá học của tôi ($count)';
  }

  @override
  String get instructorNoCoursesYet => 'Chưa có khoá học nào.';

  @override
  String get instructorNotFound => 'Không tìm thấy giảng viên.';

  @override
  String get instructorLinkWebsite => 'Website';

  @override
  String get instructorLinkFacebook => 'Facebook';

  @override
  String get instructorLinkTwitter => 'X / Twitter';

  @override
  String get instructorLinkYouTube => 'YouTube';

  @override
  String get instructorLinkInstagram => 'Instagram';

  @override
  String get legalPrivacyPolicyTitle => 'Chính sách bảo mật';

  @override
  String get legalTermsOfServiceTitle => 'Điều khoản sử dụng';

  @override
  String get legalLoadFailed => 'Không thể tải tài liệu này. Vui lòng thử lại.';

  @override
  String get legalAgreementPrefix => 'Bằng việc tiếp tục, bạn đồng ý với ';

  @override
  String get legalAgreementAnd => ' và ';

  @override
  String get legalAgreementPeriod => '.';

  @override
  String get legalAbout => 'Về iLearnIt';

  @override
  String get deleteAccountTitle => 'Xoá tài khoản';

  @override
  String get deleteAccountWarningHeader =>
      'Hành động này sẽ xoá vĩnh viễn tài khoản của bạn';

  @override
  String get deleteAccountWarningBody =>
      'Chúng tôi sẽ xoá hồ sơ, danh sách khoá học đã đăng ký, các đánh giá bạn đã viết, đơn ứng tuyển giảng viên và mọi tệp bạn đã tải lên. Không thể khôi phục.';

  @override
  String get deleteAccountSubscriptionNote =>
      'Gói đăng ký do App Store hoặc Google Play quản lý và phải được huỷ riêng. Xoá tài khoản tại đây sẽ không huỷ gói đăng ký có phí.';

  @override
  String get deleteAccountReauthIntro =>
      'Vui lòng xác nhận mật khẩu để tiếp tục.';

  @override
  String get deleteAccountReauthIntroSocial =>
      'Vui lòng đăng nhập lại để xác nhận danh tính.';

  @override
  String get deleteAccountReauthGoogle => 'Đăng nhập lại với Google';

  @override
  String get deleteAccountReauthApple => 'Đăng nhập lại với Apple';

  @override
  String get deleteAccountConfirmCheckbox =>
      'Tôi hiểu rằng hành động này là vĩnh viễn.';

  @override
  String get deleteAccountConfirmTitle => 'Xoá tài khoản của bạn?';

  @override
  String get deleteAccountConfirmBody =>
      'Nhập DELETE để xác nhận. Chúng tôi không thể khôi phục dữ liệu sau khi xoá.';

  @override
  String get deleteAccountConfirmHint => 'DELETE';

  @override
  String get deleteAccountSubmit => 'Xoá tài khoản';

  @override
  String get deleteAccountInProgress => 'Đang xoá tài khoản…';

  @override
  String get deleteAccountSuccess => 'Tài khoản của bạn đã được xoá.';

  @override
  String get deleteAccountFailed =>
      'Không thể xoá tài khoản. Vui lòng thử lại hoặc liên hệ hỗ trợ.';

  @override
  String get continueLearningTitle => 'Tiếp tục học';

  @override
  String courseProgressInProgress(int completed, int total) {
    return 'Đã hoàn thành $completed trên $total bài học';
  }

  @override
  String get courseProgressFinished => 'Đã hoàn thành khoá học';

  @override
  String get courseProgressResume => 'Tiếp tục';

  @override
  String get courseProgressUntitled => 'Khoá học chưa đặt tên';

  @override
  String get onboardingSkip => 'Bỏ qua';

  @override
  String get onboardingContinue => 'Tiếp tục';

  @override
  String get onboardingDone => 'Xong';

  @override
  String get onboardingEnableNotifications => 'Bật thông báo';

  @override
  String get onboardingInstrumentTitle => 'Bạn chơi nhạc cụ gì?';

  @override
  String get onboardingInstrumentSubtitle =>
      'Chọn nhạc cụ chính của bạn. Có thể thay đổi sau trong Cài đặt.';

  @override
  String get onboardingLevelTitle => 'Trình độ của bạn?';

  @override
  String get onboardingLevelSubtitle =>
      'Chúng tôi sẽ tinh chỉnh gợi ý cho phù hợp.';

  @override
  String get onboardingLevelBeginner => 'Mới bắt đầu';

  @override
  String get onboardingLevelBeginnerBlurb =>
      'Mới làm quen với nhạc cụ — bắt đầu với những kiến thức cơ bản.';

  @override
  String get onboardingLevelIntermediate => 'Trung cấp';

  @override
  String get onboardingLevelIntermediateBlurb =>
      'Đã nắm vững cơ bản — sẵn sàng học kỹ thuật và bài bản mới.';

  @override
  String get onboardingLevelAdvanced => 'Nâng cao';

  @override
  String get onboardingLevelAdvancedBlurb =>
      'Nhiều năm tập luyện — tập trung vào thành thục và biểu diễn.';

  @override
  String get onboardingNotificationsTitle => 'Giữ vững thói quen';

  @override
  String get onboardingNotificationsSubtitle =>
      'Bật thông báo để iLearnIt giúp bạn duy trì việc tập luyện.';

  @override
  String get onboardingNotificationsReason1 =>
      'Nhận tin khi giảng viên ra bài học mới.';

  @override
  String get onboardingNotificationsReason2 =>
      'Cập nhật khoá học mới cho nhạc cụ bạn yêu thích.';

  @override
  String get onboardingNotificationsReason3 =>
      'Nhận lời nhắc thân thiện để tập mỗi ngày.';

  @override
  String get onboardingNotificationsThanks => 'Cảm ơn bạn — đã sẵn sàng.';

  @override
  String get onboardingNotificationsCanChange =>
      'Không sao. Bạn có thể bật thông báo bất cứ lúc nào trong Cài đặt.';

  @override
  String get notificationsInboxTitle => 'Thông báo';

  @override
  String get notificationsEmpty =>
      'Bạn đã xem hết.\nThông báo mới sẽ hiển thị tại đây.';

  @override
  String get notificationsMarkAllRead => 'Đánh dấu tất cả đã đọc';

  @override
  String get notificationsClearAll => 'Xoá tất cả';

  @override
  String get notificationsClearAllConfirmTitle => 'Xoá tất cả thông báo?';

  @override
  String get notificationsClearAllConfirmBody =>
      'Tất cả thông báo trong hộp thư sẽ bị xoá vĩnh viễn.';

  @override
  String get notificationsPrefsTitle => 'Thông báo';

  @override
  String get notificationsPrefsSubtitle =>
      'Chọn loại thông báo đẩy bạn muốn nhận. Cài đặt sẽ áp dụng trên các thiết bị của bạn.';

  @override
  String get notificationsPrefsSubtitleShort => 'Chọn loại thông báo bạn nhận';

  @override
  String get notificationsPrefsTopicAll => 'Tất cả cập nhật';

  @override
  String get notificationsPrefsTopicAllBlurb =>
      'Nhận mọi thông báo dành cho cộng đồng.';

  @override
  String get notificationsPrefsTopicInstrumentBlurb =>
      'Khoá học, bài học và mẹo mới cho nhạc cụ này.';

  @override
  String get notificationsPrefsUpdateFailed =>
      'Không thể cập nhật — vui lòng thử lại.';

  @override
  String get downloadsTitle => 'Đã tải về';

  @override
  String get downloadsEmpty =>
      'Bạn chưa tải bài học nào.\nNhấn nút tải về trên bất kỳ bài học nào để xem ngoại tuyến.';

  @override
  String get downloadsClearAll => 'Xoá tất cả bản tải';

  @override
  String get downloadsClearAllConfirmTitle => 'Xoá tất cả bản tải?';

  @override
  String get downloadsClearAllConfirmBody =>
      'Tất cả bài học đã tải sẽ bị xoá khỏi thiết bị. Bạn có thể tải lại bất cứ lúc nào.';

  @override
  String downloadsUsed(String size) {
    return 'Đã dùng $size';
  }

  @override
  String get downloadCta => 'Tải về';

  @override
  String get downloadInProgress => 'Đang tải';

  @override
  String get downloadResume => 'Tiếp tục tải';

  @override
  String get downloadCompleted => 'Đã tải';

  @override
  String get downloadDelete => 'Xoá bản tải';

  @override
  String get coursesLoadingMore => 'Đang tải thêm khoá học…';

  @override
  String get coursesEndOfList => 'Bạn đã xem hết danh sách.';

  @override
  String get wishlistTitle => 'Khoá học đã lưu';

  @override
  String get wishlistSubtitleEmpty => 'Lưu khoá học để xem lại sau';

  @override
  String wishlistSubtitleCount(int count) {
    return 'Đã lưu $count khoá học';
  }

  @override
  String get wishlistEmptyTitle => 'Chưa có khoá học nào được lưu';

  @override
  String get wishlistEmptyBody =>
      'Chạm trái tim trên bất kỳ khoá học nào để lưu lại. Bạn sẽ được thông báo khi giá giảm.';

  @override
  String get wishlistBrowseCta => 'Khám phá khoá học';

  @override
  String get wishlistAddTooltip => 'Lưu để xem sau';

  @override
  String get wishlistRemoveTooltip => 'Bỏ khỏi danh sách lưu';

  @override
  String get wishlistError => 'Không thể cập nhật — vui lòng thử lại.';

  @override
  String get wishlistSignInPrompt => 'Đăng nhập để lưu khoá học.';

  @override
  String get wishlistUntitled => 'Khoá học chưa đặt tên';

  @override
  String get learningPathsTitle => 'Lộ trình học';

  @override
  String get learningPathEyebrow => 'LỘ TRÌNH';

  @override
  String learningPathCourseCount(int count) {
    return '$count khoá học';
  }

  @override
  String learningPathTotalHours(String hours) {
    return '$hours giờ';
  }

  @override
  String get learningPathCurriculumHeader => 'Nội dung lộ trình';

  @override
  String get learningPathCourseMissing => '(Khoá học không còn khả dụng)';

  @override
  String get learningPathNotFound => 'Không tìm thấy lộ trình học.';
}
