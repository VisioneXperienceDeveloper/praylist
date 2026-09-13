#if DEBUG
import Foundation

enum PreviewData {
    static var filled: PrayData {
        var categories = Array(PrayCategory.suggestions.prefix(4))
        let titles = [
            [L10n.text("작은 일에도 감사하는 사람"), L10n.text("내 이야기를 담은 책 출간하기"), L10n.text("꾸준히 달리는 건강한 나"), L10n.text("누군가에게 좋은 멘토 되기"), L10n.text("영어로 편안하게 대화하기"), L10n.text("매일 아침 나를 위한 시간 갖기"), L10n.text("가족에게 마음을 자주 표현하기"), L10n.text("새로운 도전을 즐기는 사람"), L10n.text("나만의 작은 브랜드 만들기"), L10n.text("나눌 줄 아는 여유로운 사람")],
            [L10n.text("햇살이 드는 작은 작업실"), L10n.text("오래 함께할 필름 카메라"), L10n.text("좋아하는 책으로 채운 서재")],
            [L10n.text("가족과 함께 뉴질랜드 여행"), L10n.text("교토의 작은 골목 걷기"), L10n.text("아이슬란드에서 오로라 보기"), L10n.text("제주에서 한 달 살아보기")],
            [L10n.text("하프 마라톤 완주하기"), L10n.text("나만의 레시피로 저녁 초대하기"), L10n.text("피아노 한 곡 끝까지 연주하기")]
        ]
        for i in categories.indices {
            categories[i].prays = titles[i].enumerated().map { j, title in
                Pray(title: title, note: j == 0 ? L10n.text("작은 걸음부터, 나의 속도로.") : "", createdAt: Date().addingTimeInterval(-86400 * 40), achievedAt: i == 0 && (j == 0 || j == 5) ? Date().addingTimeInterval(-86400 * Double(j + 1)) : nil)
            }
        }
        return PrayData(onboarded: true, categories: categories, prayerDays: [PrayData.dayKey(Date().addingTimeInterval(-86400))])
    }
}
#endif
