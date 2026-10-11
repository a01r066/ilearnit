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

  @override
  String get practiceTitle => 'Công cụ luyện tập';

  @override
  String get practiceTileSubtitle => 'Máy đếm nhịp + bộ lên dây';

  @override
  String get practiceMetronome => 'Đếm nhịp';

  @override
  String get practiceTuner => 'Lên dây';

  @override
  String get metronomeTimeSignature => 'Nhịp';

  @override
  String get metronomeTapTempo => 'Gõ theo nhịp';

  @override
  String get metronomeTapHere => 'Gõ đều tay tại đây';

  @override
  String get metronomeStart => 'Bắt đầu';

  @override
  String get metronomeStop => 'Dừng';

  @override
  String get tunerStart => 'Bắt đầu lắng nghe';

  @override
  String get tunerStop => 'Dừng';

  @override
  String get tunerListening => 'Đang lắng nghe…';

  @override
  String get tunerHint =>
      'Chơi một nốt gần micro. Tốt nhất trong phòng yên tĩnh.';

  @override
  String get tunerHintSilent => 'Chơi một nốt để bắt đầu.';

  @override
  String get tunerHintInTune => 'Đúng nhịp.';

  @override
  String get tunerHintFlat => 'Lên dây.';

  @override
  String get tunerHintSharp => 'Hạ dây.';

  @override
  String get tunerPermissionDenied =>
      'Cần quyền truy cập micro. Bật lại trong Cài đặt → iLearnIt → Micro.';

  @override
  String get qaSectionHeader => 'Câu hỏi';

  @override
  String get qaAsk => 'Đặt câu hỏi';

  @override
  String get qaAskTitle => 'Đặt câu hỏi';

  @override
  String get qaQuestionLabel => 'Câu hỏi của bạn';

  @override
  String get qaQuestionHint =>
      'Bạn cần hỏi gì? Hãy cụ thể để giảng viên dễ trả lời.';

  @override
  String get qaPostQuestion => 'Gửi câu hỏi';

  @override
  String get qaEmptyAnonymous =>
      'Đăng nhập để đặt câu hỏi đầu tiên cho bài giảng này.';

  @override
  String get qaEmptyAuthenticated => 'Chưa có câu hỏi — hãy là người đầu tiên.';

  @override
  String qaSeeAll(int count) {
    return 'Xem tất cả $count';
  }

  @override
  String qaReplyCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count trả lời',
      one: '1 trả lời',
      zero: 'Chưa có trả lời',
    );
    return '$_temp0';
  }

  @override
  String get qaThreadTitle => 'Câu hỏi';

  @override
  String get qaThreadMissing => 'Câu hỏi này không còn khả dụng.';

  @override
  String get qaReplies => 'Trả lời';

  @override
  String get qaNoRepliesYet => 'Chưa có trả lời. Hãy bắt đầu trò chuyện.';

  @override
  String get qaAnonymous => 'Học viên';

  @override
  String get qaReplyHint => 'Viết trả lời…';

  @override
  String get qaSend => 'Gửi';

  @override
  String get qaVerifiedInstructor => 'Giảng viên đã xác minh';

  @override
  String get notesSectionHeader => 'Ghi chú của tôi';

  @override
  String get notesAddCta => 'Thêm ghi chú';

  @override
  String get notesAddTitle => 'Ghi chú mới';

  @override
  String get notesEditTitle => 'Sửa ghi chú';

  @override
  String get notesBodyHint => 'Bạn vừa nhận ra điều gì? Ghi lại nhé.';

  @override
  String get notesNoTimestamp => 'Không gắn thời điểm';

  @override
  String get notesClearTimestamp => 'Bỏ';

  @override
  String get notesSaveNew => 'Lưu ghi chú';

  @override
  String get notesSaveChanges => 'Lưu thay đổi';

  @override
  String get notesEmptyAnonymous =>
      'Đăng nhập để bắt đầu ghi chú cho bài giảng này.';

  @override
  String get notesEmptyAuthenticated =>
      'Chưa có ghi chú — nhấn \"Thêm ghi chú\" để bắt đầu.';

  @override
  String notesMoreInProfile(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Còn $count ghi chú trong Ghi chú của tôi',
      one: 'Còn 1 ghi chú trong Ghi chú của tôi',
    );
    return '$_temp0';
  }

  @override
  String get notesEdit => 'Sửa';

  @override
  String get notesDelete => 'Xoá';

  @override
  String get notesCancel => 'Huỷ';

  @override
  String get notesDeleted => 'Đã xoá ghi chú';

  @override
  String get notesDeleteConfirmTitle => 'Xoá ghi chú này?';

  @override
  String get notesDeleteConfirmBody => 'Hành động này không thể hoàn tác.';

  @override
  String get notesPageTitle => 'Ghi chú của tôi';

  @override
  String get notesProfileSubtitle =>
      'Mọi ghi chú có gắn thời điểm trên các bài giảng.';

  @override
  String get notesEmptyPageTitle => 'Chưa có gì ở đây';

  @override
  String get notesEmptyPageBody =>
      'Mở bất kỳ bài giảng và nhấn \"Thêm ghi chú\" để bắt đầu.';

  @override
  String get settingsPrivacySection => 'Quyền riêng tư';

  @override
  String get settingsAnalyticsTitle => 'Gửi dữ liệu sử dụng ẩn danh';

  @override
  String get settingsAnalyticsSubtitle =>
      'Giúp chúng tôi phát hiện lỗi và cải thiện ứng dụng. Tắt để dừng mọi thu thập.';

  @override
  String get errTimeout => 'Kết nối quá thời gian. Vui lòng thử lại.';

  @override
  String get errRequestFailed => 'Yêu cầu thất bại.';

  @override
  String get errRequestCancelled => 'Yêu cầu đã bị huỷ.';

  @override
  String get errBadCertificate => 'Kết nối bảo mật thất bại.';

  @override
  String get errUnknownNetwork => 'Lỗi mạng không xác định.';

  @override
  String get errNoInternet => 'Không có kết nối Internet.';

  @override
  String get authErrInvalidEmail => 'Địa chỉ email không hợp lệ.';

  @override
  String get authErrDisabled => 'Tài khoản này đã bị vô hiệu hoá.';

  @override
  String get authErrInvalidCredentials => 'Email hoặc mật khẩu không đúng.';

  @override
  String get authErrEmailInUse => 'Đã có tài khoản sử dụng email này.';

  @override
  String get authErrWeakPassword => 'Mật khẩu quá yếu.';

  @override
  String get authErrTooManyRequests =>
      'Bạn đã thử quá nhiều lần. Vui lòng thử lại sau.';

  @override
  String get authErrGeneric => 'Xác thực thất bại.';

  @override
  String get valEmailRequired => 'Vui lòng nhập email.';

  @override
  String get valEmailInvalid => 'Vui lòng nhập email hợp lệ.';

  @override
  String get valPasswordRequired => 'Vui lòng nhập mật khẩu.';

  @override
  String get valPasswordMin => 'Tối thiểu 8 ký tự.';

  @override
  String valFieldRequired(String field) {
    return 'Vui lòng nhập $field.';
  }

  @override
  String get valThisField => 'Trường này';

  @override
  String valMismatch(String field) {
    return '$field không khớp.';
  }

  @override
  String get valConfirmation => 'Xác nhận';

  @override
  String get navMyLearning => 'Việc học của tôi';

  @override
  String get routeNotFound => 'Không tìm thấy trang.';

  @override
  String get timeJustNow => 'vừa xong';

  @override
  String timeMinutesAgo(String n) {
    return '$n phút trước';
  }

  @override
  String timeHoursAgo(String n) {
    return '$n giờ trước';
  }

  @override
  String timeDaysAgo(String n) {
    return '$n ngày trước';
  }

  @override
  String timeMinutesShort(String n) {
    return '$n phút';
  }

  @override
  String timeHoursShort(String n) {
    return '$n giờ';
  }

  @override
  String timeDaysShort(String n) {
    return '$n ngày';
  }

  @override
  String get authErrNoUser => 'Đăng nhập chưa hoàn tất. Vui lòng thử lại.';

  @override
  String get authErrGoogleFailed => 'Đăng nhập bằng Google thất bại.';

  @override
  String get authErrCancelled => 'Đã huỷ đăng nhập.';

  @override
  String get authErrAppleOnly =>
      'Đăng nhập bằng Apple chỉ khả dụng trên thiết bị Apple.';

  @override
  String get authErrAppleFailed => 'Đăng nhập bằng Apple thất bại.';

  @override
  String get authErrNotSignedIn => 'Bạn chưa đăng nhập.';

  @override
  String get authErrNoEmailReauth =>
      'Tài khoản của bạn không có email — hãy xác thực lại bằng Google hoặc Apple.';

  @override
  String get authErrReauthFailed => 'Xác thực lại thất bại.';

  @override
  String get authErrReauthCancelled => 'Đã huỷ xác thực lại.';

  @override
  String get authErrDeleteFailed => 'Xoá tài khoản thất bại.';

  @override
  String get authSkipGuestTooltip => 'Bỏ qua — tiếp tục với tư cách khách';

  @override
  String get authWelcomeBack => 'Chào mừng trở lại';

  @override
  String get authSignInSubtitle => 'Đăng nhập để tiếp tục bài học của bạn.';

  @override
  String get authContinueAsGuest => 'Tiếp tục với tư cách khách';

  @override
  String get authEnterEmailFirst => 'Vui lòng nhập email ở trên trước.';

  @override
  String get authResetSent => 'Đã gửi email đặt lại mật khẩu.';

  @override
  String get authResetFailed => 'Không thể gửi email đặt lại mật khẩu.';

  @override
  String get authAcceptTermsFirst =>
      'Vui lòng đồng ý với Điều khoản và Nguyên tắc cộng đồng để tiếp tục.';

  @override
  String get authCreateAccount => 'Tạo tài khoản';

  @override
  String get authSignUpSubtitle =>
      'Cầm nhạc cụ lên nào — guitar, piano hoặc violin.';

  @override
  String get authDisplayName => 'Tên hiển thị';

  @override
  String get authAgreePrefix => 'Tôi đồng ý với ';

  @override
  String get authAgreeTerms => 'Điều khoản';

  @override
  String get authAgreeAnd => ' và ';

  @override
  String get authAgreeGuidelines => 'Nguyên tắc cộng đồng';

  @override
  String get authAgreeSuffix =>
      '. Tôi sẽ không đăng nội dung lăng mạ, bất hợp pháp hoặc phản cảm.';

  @override
  String get profileGuest => 'Khách';

  @override
  String get profilePlanActive => 'Gói Cá nhân · đang hoạt động';

  @override
  String get profilePlanCta => 'Mở khoá mọi khoá học với Gói Cá nhân';

  @override
  String get profileModerationQueue => 'Hàng chờ kiểm duyệt';

  @override
  String get profileModerationSubtitle => 'Xem xét nội dung bị báo cáo';

  @override
  String get profileGuestTitle => 'Lưu tiến độ học của bạn';

  @override
  String get profileGuestBody =>
      'Đăng nhập để mở khoá khoá học, lưu đánh dấu, ghi chú và học tiếp trên mọi thiết bị.';

  @override
  String get myLearningLoadFailed => 'Không thể tải thư viện của bạn.';

  @override
  String get commonTryAgainLater => 'Vui lòng kiểm tra kết nối và thử lại.';

  @override
  String get myLearningEmptyTitle => 'Thư viện của bạn chưa có gì.';

  @override
  String get myLearningEmptyBody =>
      'Hãy bắt đầu một bài giảng bất kỳ, bài đó sẽ hiện ở đây để bạn học tiếp từ chỗ đã dừng.';

  @override
  String get commonSearch => 'Tìm kiếm';

  @override
  String get progressCompleted => 'Đã hoàn thành';

  @override
  String progressPercentComplete(String percent) {
    return 'Đã hoàn thành $percent%';
  }

  @override
  String get purchaseContinueCourse => 'Tiếp tục khoá học';

  @override
  String get purchaseIncludedInPlan => 'Đã bao gồm trong Gói Cá nhân của bạn';

  @override
  String get purchaseSignInToUnlockCourse =>
      'Đăng nhập để mở khoá khoá học này.';

  @override
  String get purchaseSignInToUnlock => 'Đăng nhập để mở khoá';

  @override
  String purchaseUnlockFor(String price) {
    return 'Mở khoá với giá $price';
  }

  @override
  String get purchaseUnavailable =>
      'Thiết bị này không hỗ trợ mua trong ứng dụng.';

  @override
  String get purchaseRestoreDone =>
      'Đã khôi phục. Giao dịch mua của bạn sẽ hiển thị trong giây lát.';

  @override
  String get purchaseRestoreSubtitle =>
      'Đồng bộ các giao dịch mua bằng tài khoản App Store hoặc Google Play của bạn.';

  @override
  String get purchaseProductUnavailable =>
      'Mặt hàng này hiện không có trên cửa hàng.';

  @override
  String get purchaseStoreDeclined =>
      'Cửa hàng không thể bắt đầu giao dịch. Vui lòng thử lại.';

  @override
  String get purchaseNotSupportedPlatform =>
      'Nền tảng này không hỗ trợ mua trong ứng dụng.';

  @override
  String get purchaseAlreadyOwned => 'Bạn đã sở hữu khoá học này.';

  @override
  String get purchaseCourseUnavailable => 'Khoá học này hiện không mở bán.';

  @override
  String get purchaseFailed =>
      'Không thể hoàn tất giao dịch. Vui lòng thử lại.';

  @override
  String get subscriptionVerifyFailed =>
      'Không thể xác nhận gói đăng ký. Vui lòng thử lại hoặc dùng Khôi phục giao dịch mua.';

  @override
  String get subscriptionOtherAccount =>
      'Gói đăng ký này đã liên kết với một tài khoản iLearnIt khác.';

  @override
  String get errLoadFailed => 'Không thể tải dữ liệu. Vui lòng thử lại.';

  @override
  String get courseNotFound => 'Không tìm thấy khoá học.';

  @override
  String get videoUnavailable => 'Không thể phát video. Vui lòng thử lại.';

  @override
  String get notesSaveFailed => 'Không thể lưu ghi chú.';

  @override
  String get qaPostQuestionFailed => 'Không thể đăng câu hỏi.';

  @override
  String get qaPostReplyFailed => 'Không thể đăng câu trả lời.';

  @override
  String durationHM(String h, String m) {
    return '$h giờ $m phút';
  }

  @override
  String durationM(String m) {
    return '$m phút';
  }

  @override
  String durationS(String s) {
    return '$s giây';
  }

  @override
  String get courseTaughtBy => 'Giảng viên: ';

  @override
  String get courseAbout => 'Giới thiệu khoá học';

  @override
  String get courseCurriculumSoon => 'Nội dung khoá học sắp ra mắt.';

  @override
  String get courseCurriculum => 'Nội dung khoá học';

  @override
  String courseCurriculumSummary(
    String sections,
    String lectures,
    String duration,
  ) {
    return '$sections chương • $lectures bài giảng • $duration';
  }

  @override
  String courseLessons(String count) {
    return '$count bài học';
  }

  @override
  String courseEnrolled(String count) {
    return '$count học viên';
  }

  @override
  String get commonRefresh => 'Làm mới';

  @override
  String get coursesShowingFeatured => 'Đang hiển thị khoá học nổi bật';

  @override
  String get coursesShowAll => 'Hiện tất cả khoá học';

  @override
  String get instructorsEmpty => 'Chưa có giảng viên nào.';

  @override
  String instructorStudents(String count) {
    return '$count học viên';
  }

  @override
  String get commonLoadFailed => 'Đã có lỗi xảy ra. Kéo xuống để thử lại.';

  @override
  String courseByInstructor(String name) {
    return 'bởi $name';
  }

  @override
  String get lectureNotFound => 'Không tìm thấy bài giảng.';

  @override
  String get lectureMinimize => 'Thu nhỏ';

  @override
  String get lectureVideoMissing => 'Video không khả dụng.';

  @override
  String get lectureAudioMissing => 'Âm thanh không khả dụng.';

  @override
  String get lecturePurchaseToWatch => 'Hãy mua khoá học này để xem bài giảng.';

  @override
  String get lectureEncoding =>
      'Video đang được xử lý — vui lòng thử lại sau một phút.';

  @override
  String get lectureResources => 'Tài liệu';

  @override
  String get lecturePurchaseToOpen => 'Hãy mua khoá học này để mở bài giảng.';

  @override
  String get lectureLoadFailed => 'Không thể tải bài giảng. Vui lòng thử lại.';

  @override
  String get audioLoadFailed => 'Không thể tải âm thanh.';

  @override
  String get playerBack10 => 'Lùi 10 giây';

  @override
  String get playerForward30 => 'Tới 30 giây';

  @override
  String get playerBack15 => 'Lùi 15 giây';

  @override
  String get playerForward15 => 'Tới 15 giây';

  @override
  String get playerPlay => 'Phát';

  @override
  String get playerPause => 'Tạm dừng';

  @override
  String get commonClose => 'Đóng';

  @override
  String get videoLoadFailed => 'Không thể tải video.';

  @override
  String get levelBeginner => 'Cơ bản';

  @override
  String get levelIntermediate => 'Trung cấp';

  @override
  String get levelAdvanced => 'Nâng cao';

  @override
  String get lectureTypeVideo => 'Video';

  @override
  String get lectureTypeAudio => 'Âm thanh';

  @override
  String get lectureTypePdf => 'PDF';

  @override
  String get lectureTypeDoc => 'Tài liệu';

  @override
  String get reasonSpam => 'Thư rác hoặc lừa đảo';

  @override
  String get reasonHarassment => 'Quấy rối hoặc bắt nạt';

  @override
  String get reasonHate => 'Ngôn từ hoặc biểu tượng thù ghét';

  @override
  String get reasonSexual => 'Ảnh khoả thân hoặc nội dung tình dục';

  @override
  String get reasonViolence => 'Bạo lực hoặc nội dung nguy hiểm';

  @override
  String get reasonSelfHarm => 'Tự gây hại hoặc tự tử';

  @override
  String get reasonMisinformation => 'Thông tin sai lệch';

  @override
  String get reasonIp => 'Vi phạm bản quyền / sở hữu trí tuệ';

  @override
  String get reasonOther => 'Lý do khác';

  @override
  String get ugcReview => 'Đánh giá';

  @override
  String get ugcQuestion => 'Câu hỏi';

  @override
  String get ugcAnswer => 'Câu trả lời';

  @override
  String get ugcNote => 'Ghi chú';

  @override
  String get lectureAdditionalResources => 'Tài liệu bổ sung';

  @override
  String get commonOpen => 'Mở';

  @override
  String get downloadPurchaseToDownload => 'Hãy mua khoá học này để tải về.';

  @override
  String get downloadFailed => 'Tải về thất bại.';

  @override
  String get commonCancelDownload => 'Huỷ tải về';

  @override
  String get lecturePreviewBadge => 'Học thử';

  @override
  String get lectureLockedLabel => 'Đã khoá';

  @override
  String sectionNumber(String n) {
    return 'Chương $n';
  }

  @override
  String sectionSummary(String count, String duration) {
    return '$count bài giảng • $duration';
  }

  @override
  String get reviewsTitle => 'Xếp hạng & Đánh giá';

  @override
  String get reviewsLoadFailed => 'Không thể tải đánh giá.';

  @override
  String get reviewsEmpty => 'Chưa có đánh giá nào — hãy là người đầu tiên.';

  @override
  String get reviewsCountOne => '1 đánh giá';

  @override
  String reviewsCountMany(String count) {
    return '$count đánh giá';
  }

  @override
  String get reviewSignInToWrite => 'Đăng nhập để viết đánh giá';

  @override
  String get reviewEdit => 'Sửa đánh giá của bạn';

  @override
  String get reviewWrite => 'Viết đánh giá';

  @override
  String get reviewSignInSnack => 'Đăng nhập để để lại đánh giá.';

  @override
  String get reviewAccessGate =>
      'Mở khoá khoá học này (hoặc đăng ký gói) để đánh giá.';

  @override
  String get reviewBodyLabel => 'Đánh giá của bạn (không bắt buộc)';

  @override
  String get reviewBodyHint => 'Bạn thấy khoá học thế nào?';

  @override
  String get commonSubmit => 'Gửi';

  @override
  String get reviewDeleteTitle => 'Xoá đánh giá của bạn?';

  @override
  String get reviewDeleteBody =>
      'Thao tác này sẽ xoá xếp hạng và đánh giá của bạn khỏi khoá học.';

  @override
  String get commonDelete => 'Xoá';

  @override
  String get reviewDeleteMine => 'Xoá đánh giá của tôi';

  @override
  String get instructorCoursesLoadFailed => 'Không thể tải khoá học.';

  @override
  String get commonCouldNotOpenLink => 'Không thể mở liên kết.';

  @override
  String get playerForward10 => 'Tới 10 giây';

  @override
  String get eulaAcceptFailed =>
      'Không thể lưu xác nhận của bạn. Vui lòng thử lại.';

  @override
  String get eulaUpdatedTitle => 'Thoả thuận đã cập nhật';

  @override
  String eulaUpdatedBody(String date) {
    return 'Chúng tôi đã cập nhật Điều khoản và Nguyên tắc cộng đồng ($date). Vui lòng xem và đồng ý để tiếp tục sử dụng iLearnIt.';
  }

  @override
  String get eulaReadTerms => 'Đọc điều khoản';

  @override
  String get eulaReadGuidelines => 'Đọc nguyên tắc';

  @override
  String get eulaAccept => 'Tôi đồng ý';

  @override
  String get blockFailed => 'Không thể chặn người dùng này. Vui lòng thử lại.';

  @override
  String get blockThisUser => 'người dùng này';

  @override
  String blockTitle(String name) {
    return 'Chặn $name?';
  }

  @override
  String blockBody(String name) {
    return 'Bạn sẽ không thấy đánh giá, câu hỏi, câu trả lời hay ghi chú nào từ $name. Người này sẽ không nhận được thông báo.';
  }

  @override
  String get blockAction => 'Chặn';

  @override
  String get reportThanks =>
      'Cảm ơn bạn — đội ngũ của chúng tôi sẽ sớm xem xét.';

  @override
  String get reportFailed => 'Không thể gửi báo cáo. Vui lòng thử lại.';

  @override
  String reportTitle(String type) {
    return 'Báo cáo $type';
  }

  @override
  String get reportIntro =>
      'Hãy giúp chúng tôi giữ cộng đồng an toàn. Báo cáo được xem xét trong vòng 24 giờ.';

  @override
  String get reportReason => 'Lý do';

  @override
  String get reportNotes => 'Ghi chú thêm (không bắt buộc)';

  @override
  String get reportSubmit => 'Gửi báo cáo';

  @override
  String get commonMore => 'Thêm';

  @override
  String get ugcReport => 'Báo cáo';

  @override
  String ugcBlockName(String name) {
    return 'Chặn $name';
  }

  @override
  String ugcUnblockName(String name) {
    return 'Bỏ chặn $name';
  }

  @override
  String get ugcUserFallback => 'người dùng';

  @override
  String get modTitle => 'Kiểm duyệt';

  @override
  String get modNoAccess => 'Bạn không có quyền truy cập.';

  @override
  String modOpenCount(String count) {
    return '$count đang chờ';
  }

  @override
  String get modNoOpenReports => 'Không có báo cáo nào đang chờ';

  @override
  String get modNothingToTriage => 'Không có gì cần xử lý';

  @override
  String get modEmptyHint =>
      'Báo cáo liên quan đến khoá học của bạn sẽ hiển thị ở đây.';

  @override
  String get modActionFailed => 'Thao tác thất bại. Vui lòng thử lại.';

  @override
  String get modHide => 'Ẩn';

  @override
  String get modDismiss => 'Bỏ qua';

  @override
  String get notesSignInSnack => 'Đăng nhập để lưu ghi chú.';

  @override
  String get qaSignInToReply => 'Đăng nhập để trả lời';

  @override
  String get qaSignInToJoin => 'Đăng nhập để tham gia thảo luận.';

  @override
  String get qaSignInToAsk => 'Đăng nhập để đặt câu hỏi.';

  @override
  String get filterTitle => 'Bộ lọc';

  @override
  String get filterReset => 'Đặt lại';

  @override
  String get filterInstrument => 'Nhạc cụ';

  @override
  String get filterLevel => 'Trình độ';

  @override
  String get filterMinRating => 'Xếp hạng tối thiểu';

  @override
  String get filterAny => 'Bất kỳ';

  @override
  String get filterMaxPrice => 'Giá tối đa';

  @override
  String get filterApply => 'Áp dụng';

  @override
  String get learningPathCourseLoadFailed => 'Không thể tải khoá học này.';

  @override
  String get legalCommunityGuidelinesTitle => 'Nguyên tắc cộng đồng';

  @override
  String get songbookLoadFailed => 'Không thể tải sách bài hát này.';

  @override
  String songbookSectionFailed(String section) {
    return '$section — tải thất bại.';
  }

  @override
  String get notifChannelName => 'Thông báo iLearnIt';

  @override
  String get notifChannelDesc =>
      'Cập nhật khoá học, trạng thái đơn đăng ký và thông báo chung.';

  @override
  String get a11yShowPassword => 'Hiện mật khẩu';

  @override
  String get a11yHidePassword => 'Ẩn mật khẩu';

  @override
  String a11yRateStars(String n) {
    return 'Đánh giá $n trên 5 sao';
  }

  @override
  String get updateRequiredTitle => 'Cần cập nhật ứng dụng';

  @override
  String get updateRequiredBody =>
      'Phiên bản iLearnIt này không còn được hỗ trợ. Vui lòng cập nhật để tiếp tục học.';

  @override
  String get updateNow => 'Cập nhật';

  @override
  String get updateAvailableBody => 'Đã có phiên bản iLearnIt mới.';

  @override
  String get updateLater => 'Để sau';

  @override
  String get songbookPreparing => 'Đang chuẩn bị sách bài hát…';

  @override
  String get songbookNoViewer => 'Thiết bị không có ứng dụng mở được tệp PDF.';

  @override
  String get songbookLocked =>
      'Hãy mua sách bài hát này (hoặc Gói Cá nhân) để mở.';

  @override
  String get songbookOpenFailed =>
      'Không thể mở sách bài hát. Vui lòng thử lại.';

  @override
  String songbookSamplePage(String page, String total) {
    return 'Trang mẫu · $page/$total';
  }

  @override
  String get songbookOpen => 'Mở sách bài hát';

  @override
  String get songbookSignInToGet => 'Đăng nhập để mua sách bài hát này.';

  @override
  String songbookGetForPrice(String price) {
    return 'Mua sách · $price';
  }

  @override
  String get songbookOtherAccount =>
      'Giao dịch này đã liên kết với một tài khoản iLearnIt khác.';
}
