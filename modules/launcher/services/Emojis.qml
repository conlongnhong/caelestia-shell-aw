pragma Singleton

import QtQuick
import qs.utils

Searcher {
    id: root

    function selector(item: var): string {
        return `${item.name} ${item.keywords}`;
    }

    keys: ["name", "keywords"]
    weights: [0.8, 0.2]
    list: [
        Emoji { glyph: "😀"; name: qsTr("Mặt cười"); keywords: "grin happy smile vui" },
        Emoji { glyph: "😂"; name: qsTr("Cười ra nước mắt"); keywords: "joy laugh tear vui" },
        Emoji { glyph: "🥰"; name: qsTr("Mặt cười với trái tim"); keywords: "love hearts yêu" },
        Emoji { glyph: "😍"; name: qsTr("Mắt hình trái tim"); keywords: "love heart eyes yêu" },
        Emoji { glyph: "😎"; name: qsTr("Mặt đeo kính râm"); keywords: "cool sunglasses" },
        Emoji { glyph: "🤔"; name: qsTr("Đang suy nghĩ"); keywords: "think hmm" },
        Emoji { glyph: "😭"; name: qsTr("Khóc lớn"); keywords: "cry sad buồn" },
        Emoji { glyph: "😡"; name: qsTr("Tức giận"); keywords: "angry mad giận" },
        Emoji { glyph: "🥳"; name: qsTr("Ăn mừng"); keywords: "party celebrate tiệc" },
        Emoji { glyph: "😴"; name: qsTr("Buồn ngủ"); keywords: "sleep tired ngủ" },
        Emoji { glyph: "🤯"; name: qsTr("Nổ tung đầu"); keywords: "mind blown shocked" },
        Emoji { glyph: "🫡"; name: qsTr("Chào kiểu quân đội"); keywords: "salute respect" },
        Emoji { glyph: "👍"; name: qsTr("Ngón cái hướng lên"); keywords: "yes good like đồng ý" },
        Emoji { glyph: "👎"; name: qsTr("Ngón cái hướng xuống"); keywords: "no bad dislike" },
        Emoji { glyph: "👏"; name: qsTr("Vỗ tay"); keywords: "clap applause" },
        Emoji { glyph: "🙏"; name: qsTr("Chắp tay"); keywords: "please thanks pray cảm ơn" },
        Emoji { glyph: "🤝"; name: qsTr("Bắt tay"); keywords: "handshake agreement" },
        Emoji { glyph: "💪"; name: qsTr("Cơ bắp"); keywords: "strong strength khỏe" },
        Emoji { glyph: "👀"; name: qsTr("Đôi mắt"); keywords: "eyes look xem" },
        Emoji { glyph: "✨"; name: qsTr("Lấp lánh"); keywords: "sparkles magic" },
        Emoji { glyph: "🔥"; name: qsTr("Lửa"); keywords: "fire hot lit" },
        Emoji { glyph: "❤️"; name: qsTr("Trái tim đỏ"); keywords: "heart love yêu" },
        Emoji { glyph: "💔"; name: qsTr("Trái tim tan vỡ"); keywords: "broken heart sad" },
        Emoji { glyph: "💯"; name: qsTr("Một trăm điểm"); keywords: "hundred perfect" },
        Emoji { glyph: "✅"; name: qsTr("Dấu kiểm"); keywords: "check done yes xong" },
        Emoji { glyph: "❌"; name: qsTr("Dấu chéo"); keywords: "cross no error sai" },
        Emoji { glyph: "⚠️"; name: qsTr("Cảnh báo"); keywords: "warning caution" },
        Emoji { glyph: "🎉"; name: qsTr("Pháo giấy"); keywords: "party celebrate congratulations" },
        Emoji { glyph: "🎂"; name: qsTr("Bánh sinh nhật"); keywords: "birthday cake" },
        Emoji { glyph: "🎁"; name: qsTr("Quà tặng"); keywords: "gift present" },
        Emoji { glyph: "🚀"; name: qsTr("Tên lửa"); keywords: "rocket launch fast" },
        Emoji { glyph: "💡"; name: qsTr("Bóng đèn"); keywords: "idea light ý tưởng" },
        Emoji { glyph: "🔍"; name: qsTr("Kính lúp"); keywords: "search find tìm" },
        Emoji { glyph: "📌"; name: qsTr("Ghim"); keywords: "pin location" },
        Emoji { glyph: "📝"; name: qsTr("Ghi chú"); keywords: "memo note write" },
        Emoji { glyph: "📁"; name: qsTr("Thư mục"); keywords: "folder directory" },
        Emoji { glyph: "💻"; name: qsTr("Máy tính xách tay"); keywords: "computer laptop code" },
        Emoji { glyph: "🐛"; name: qsTr("Con bọ"); keywords: "bug insect debug lỗi" },
        Emoji { glyph: "🔒"; name: qsTr("Khóa"); keywords: "lock secure bảo mật" },
        Emoji { glyph: "🌈"; name: qsTr("Cầu vồng"); keywords: "rainbow colour" },
        Emoji { glyph: "☀️"; name: qsTr("Mặt trời"); keywords: "sun sunny weather" },
        Emoji { glyph: "🌙"; name: qsTr("Mặt trăng"); keywords: "moon night đêm" },
        Emoji { glyph: "⭐"; name: qsTr("Ngôi sao"); keywords: "star favourite" },
        Emoji { glyph: "🌍"; name: qsTr("Địa cầu"); keywords: "earth world globe" },
        Emoji { glyph: "🐱"; name: qsTr("Mèo"); keywords: "cat pet" },
        Emoji { glyph: "🐶"; name: qsTr("Chó"); keywords: "dog pet" },
        Emoji { glyph: "🍕"; name: qsTr("Pizza"); keywords: "food pizza" },
        Emoji { glyph: "☕"; name: qsTr("Cà phê"); keywords: "coffee drink" },
        Emoji { glyph: "🍺"; name: qsTr("Bia"); keywords: "beer drink" },
        Emoji { glyph: "🎵"; name: qsTr("Nốt nhạc"); keywords: "music song" }
    ]

    component Emoji: QtObject {
        required property string glyph
        required property string name
        required property string keywords
    }
}
