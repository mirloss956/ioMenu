import SwiftUI
import Combine

// MARK: - Theme
extension Color {
    init(hex: UInt) {
        self.init(red: Double((hex >> 16) & 0xFF) / 255,
                  green: Double((hex >> 8) & 0xFF) / 255,
                  blue: Double(hex & 0xFF) / 255)
    }
    static let cream = Color(hex: 0xF7F3EC)
    static let espresso = Color(hex: 0x493529)
    static let caramel = Color(hex: 0xB9855A)
    static let latte = Color(hex: 0xE9DCCB)
    static let sage = Color(hex: 0xD9E2D5)
    static let roseBeige = Color(hex: 0xF0D8CE)
    static let subText = Color(hex: 0x8B8177)
}

func nt(_ n: Int) -> String { "NT$\(n)" }

struct CafeButton: ButtonStyle {
    var enabled = true
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline)
            .foregroundColor(.white)
            .frame(maxWidth: .infinity, minHeight: 52)
            .background(enabled ? Color.espresso : Color.subText.opacity(0.5))
            .clipShape(RoundedRectangle(cornerRadius: 14))
            .opacity(configuration.isPressed ? 0.85 : 1)
    }
}

extension View {
    func card() -> some View {
        self.padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.white)
            .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}

struct Badge: View {
    let text: String
    var color: Color = .latte
    var body: some View {
        Text(text)
            .font(.caption.weight(.medium))
            .foregroundColor(.espresso)
            .padding(.horizontal, 8).padding(.vertical, 3)
            .background(color)
            .clipShape(Capsule())
    }
}

struct EmptyState: View {
    let icon: String, title: String, hint: String
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon).font(.largeTitle).foregroundColor(.caramel)
            Text(title).font(.headline)
            Text(hint).font(.subheadline).foregroundColor(.subText)
        }
        .foregroundColor(.espresso)
        .frame(maxWidth: .infinity).padding(.vertical, 48)
    }
}

// MARK: - Models
struct SpecOption: Identifiable, Hashable {
    let id: String
    let name: String
    var price = 0
    var maxQty = 1
    var soldOut = false
    var children: [SpecGroup] = []
}

struct SpecGroup: Identifiable, Hashable {
    let id: String
    let name: String
    var minSel = 0
    var maxSel = 1
    var options: [SpecOption]
}

struct Product: Identifiable, Hashable {
    let id: String
    let name: String
    let desc: String
    let price: Int
    let category: String
    let emoji: String
    var soldOut = false
    var orderLimit: Int? = nil
    var groups: [SpecGroup] = []
}

struct Picked: Hashable { let name: String; let price: Int; let qty: Int }

struct CartItem: Identifiable {
    let id = UUID()
    let product: Product
    var selection: [String: Int]
    var picks: [Picked]
    var qty: Int
    var note: String
    var unit: Int { product.price + picks.reduce(0) { $0 + $1.price * $1.qty } }
    var subtotal: Int { unit * qty }
    var summary: String {
        picks.map { $0.qty > 1 ? "\($0.name)×\($0.qty)" : $0.name }.joined(separator: "、")
    }
}

enum OrderStatus: String { case pending = "待確認", processing = "處理中", completed = "已完成", cancelled = "已取消" }
enum PayStatus: String { case unpaid = "待付款", paid = "已付款", failed = "付款失敗", refunded = "已退款" }

struct Order: Identifiable {
    let id = UUID()
    let number: String
    let date: Date
    let items: [CartItem]
    let discount: Int
    var status: OrderStatus
    var pay: PayStatus
    let pickup: String
    let method: String
    var subtotal: Int { items.reduce(0) { $0 + $1.subtotal } }
    var total: Int { subtotal - discount }
}

// MARK: - 示意資料（集中管理，日後可換成 Repository / API）
enum Catalog {
    static let categories = ["咖啡", "茶飲特調", "輕食", "甜點", "季節限定"]

    static let coffeeGroups: [SpecGroup] = [
        SpecGroup(id: "c-temp", name: "溫度", minSel: 1, maxSel: 1, options: [
            SpecOption(id: "c-ice", name: "冰飲"),
            SpecOption(id: "c-hot", name: "熱飲")
        ]),
        SpecGroup(id: "c-bean", name: "咖啡豆選擇", minSel: 1, maxSel: 1, options: [
            SpecOption(id: "b-blend", name: "經典義式綜合豆"),
            SpecOption(id: "b-yirga", name: "衣索比亞 耶加雪菲", price: 15),
            SpecOption(id: "b-colo", name: "哥倫比亞 蜜處理", price: 20)
        ])
    ]

    static let latteGroups: [SpecGroup] = [
        SpecGroup(id: "size", name: "尺寸", minSel: 1, maxSel: 1, options: [
            SpecOption(id: "s-s", name: "小杯", price: -10),
            SpecOption(id: "s-m", name: "中杯"),
            SpecOption(id: "s-l", name: "大杯", price: 15)]),
        SpecGroup(id: "sweet", name: "甜度", minSel: 1, maxSel: 1, options: [
            SpecOption(id: "w1", name: "正常"),
            SpecOption(id: "w2", name: "半糖"),
            SpecOption(id: "w3", name: "無糖")]),
        SpecGroup(id: "extra", name: "加料", minSel: 0, maxSel: 2, options: [
            SpecOption(id: "e-shot", name: "加濃縮", price: 20, maxQty: 2),
            SpecOption(id: "e-oat", name: "換燕麥奶", price: 15),
            SpecOption(id: "e-van", name: "香草糖漿", soldOut: true)])
    ]

    static let teaGroups: [SpecGroup] = [
        SpecGroup(id: "t-ice", name: "冰塊", minSel: 1, maxSel: 1, options: [
            SpecOption(id: "ti-reg", name: "正常冰"),
            SpecOption(id: "ti-less", name: "少冰"),
            SpecOption(id: "ti-no", name: "去冰"),
            SpecOption(id: "ti-hot", name: "溫熱")
        ]),
        SpecGroup(id: "t-sweet", name: "甜度", minSel: 1, maxSel: 1, options: [
            SpecOption(id: "ts-full", name: "全糖"),
            SpecOption(id: "ts-half", name: "半糖"),
            SpecOption(id: "ts-micro", name: "微糖"),
            SpecOption(id: "ts-no", name: "無糖")
        ]),
        SpecGroup(id: "t-topping", name: "加料", minSel: 0, maxSel: 2, options: [
            SpecOption(id: "tt-pearl", name: "白玉珍珠", price: 10),
            SpecOption(id: "tt-jelly", name: "桂花茶凍", price: 15),
            SpecOption(id: "tt-foam", name: "芝士奶蓋", price: 20)
        ])
    ]

    static let breakfastGroups: [SpecGroup] = [
        SpecGroup(id: "main", name: "主餐", minSel: 1, maxSel: 1, options: [
            SpecOption(id: "m-sa", name: "招牌三明治", children: [
                SpecGroup(id: "fill", name: "口味", minSel: 1, maxSel: 1, options: [
                    SpecOption(id: "f-h", name: "火腿起司"),
                    SpecOption(id: "f-v", name: "蔬菜蛋"),
                    SpecOption(id: "f-s", name: "煙燻鮭魚", price: 30)])]),
            SpecOption(id: "m-wa", name: "鬆餅", price: 20, children: [
                SpecGroup(id: "sauce", name: "醬料", minSel: 0, maxSel: 2, options: [
                    SpecOption(id: "sa1", name: "楓糖"),
                    SpecOption(id: "sa2", name: "巧克力", price: 10),
                    SpecOption(id: "sa3", name: "莓果", soldOut: true)])])]),
        SpecGroup(id: "drink", name: "飲品", minSel: 1, maxSel: 1, options: [
            SpecOption(id: "d1", name: "美式"),
            SpecOption(id: "d2", name: "紅茶"),
            SpecOption(id: "d3", name: "拿鐵", price: 25)])
    ]

    static let bagelGroups: [SpecGroup] = [
        SpecGroup(id: "bg-bread", name: "貝果種類", minSel: 1, maxSel: 1, options: [
            SpecOption(id: "bgb-plain", name: "原味麥香"),
            SpecOption(id: "bgb-cheese", name: "雙重起司", price: 10),
            SpecOption(id: "bgb-berry", name: "藍莓肉桂", price: 10)
        ]),
        SpecGroup(id: "bg-spread", name: "抹醬搭配", minSel: 0, maxSel: 1, options: [
            SpecOption(id: "bgs-cream", name: "經典原味乳酪"),
            SpecOption(id: "bgs-garlic", name: "義式蒜香抹醬"),
            SpecOption(id: "bgs-salmon", name: "煙燻鮭魚抹醬", price: 20)
        ])
    ]

    static let dessertGroups: [SpecGroup] = [
        SpecGroup(id: "ds-serve", name: "享用方式", minSel: 1, maxSel: 1, options: [
            SpecOption(id: "dss-rt", name: "常溫享用"),
            SpecOption(id: "dss-warm", name: "主廚現烤回溫")
        ]),
        SpecGroup(id: "ds-addon", name: "加購搭配", minSel: 0, maxSel: 1, options: [
            SpecOption(id: "dsa-ice", name: "香草冰淇淋一球", price: 25)
        ])
    ]

    static let toastGroups: [SpecGroup] = [
        SpecGroup(id: "t-bake", name: "烘烤程度", minSel: 1, maxSel: 1, options: [
            SpecOption(id: "tb-light", name: "微烤鬆軟"),
            SpecOption(id: "tb-crisp", name: "金黃酥脆")
        ]),
        SpecGroup(id: "t-egg", name: "蛋熟度", minSel: 0, maxSel: 1, options: [
            SpecOption(id: "te-sunny", name: "太陽半熟蛋"),
            SpecOption(id: "te-well", name: "全熟荷包蛋")
        ])
    ]

    static let pastaGroups: [SpecGroup] = [
        SpecGroup(id: "pas-spicy", name: "辣度", minSel: 1, maxSel: 1, options: [
            SpecOption(id: "psp-none", name: "不辣"),
            SpecOption(id: "psp-mild", name: "微辣"),
            SpecOption(id: "psp-hot", name: "大辣")
        ]),
        SpecGroup(id: "pas-extra", name: "加購配料", minSel: 0, maxSel: 2, options: [
            SpecOption(id: "pe-cheese", name: "焗烤乳酪絲", price: 30),
            SpecOption(id: "pe-bacon", name: "加倍厚切培根", price: 35)
        ])
    ]

    static let sparklingGroups: [SpecGroup] = [
        SpecGroup(id: "spk-ice", name: "冰塊", minSel: 1, maxSel: 1, options: [
            SpecOption(id: "spki-norm", name: "正常冰（最佳氣泡感）"),
            SpecOption(id: "spki-less", name: "少冰")
        ]),
        SpecGroup(id: "spk-sweet", name: "甜度", minSel: 1, maxSel: 1, options: [
            SpecOption(id: "spks-reg", name: "黃金比例"),
            SpecOption(id: "spks-half", name: "半糖微甜")
        ])
    ]

    static let products: [Product] = [
        // 咖啡
        Product(id: "p1", name: "手沖單品咖啡", desc: "當日精選莊園豆，產區手沖細緻萃取", price: 120, category: "咖啡", emoji: "☕️", groups: coffeeGroups),
        Product(id: "p2", name: "鮮奶拿鐵", desc: "濃縮與鮮奶的圓潤組合", price: 85, category: "咖啡", emoji: "🥛", groups: latteGroups),
        Product(id: "p6", name: "經典美式", desc: "精選深焙綜合豆，醇厚堅果回甘", price: 75, category: "咖啡", emoji: "☕️", groups: coffeeGroups),
        Product(id: "p7", name: "焦糖瑪奇朵", desc: "綿密奶泡佐以香甜香草與焦糖淋醬", price: 95, category: "咖啡", emoji: "🧋", groups: latteGroups),
        Product(id: "p8", name: "西西里檸檬氣泡咖啡", desc: "新鮮檸檬汁遇上義式濃縮與氣泡水，清爽暢快", price: 95, category: "咖啡", emoji: "🍋", groups: sparklingGroups),
        Product(id: "p9", name: "燕麥生椰拿鐵", desc: "天然生椰乳與燕麥奶完美融合，濃郁絲滑", price: 105, category: "咖啡", emoji: "🥥", groups: latteGroups),
        Product(id: "p26", name: "冰滴冷萃咖啡", desc: "12小時低溫緩慢萃取，口感純淨滑順帶有酒香與黑巧克力微韻", price: 110, category: "咖啡", emoji: "🧊", groups: coffeeGroups),
        Product(id: "p27", name: "經典摩卡咖啡", desc: "法芙娜深黑可可遇上濃縮咖啡與綿密奶泡，微苦香甜", price: 100, category: "咖啡", emoji: "☕️", groups: latteGroups),
        Product(id: "p28", name: "卡布奇諾", desc: "黃金比例義式濃縮與厚實細密奶泡，散發淡淡肉桂香", price: 85, category: "咖啡", emoji: "☕️", groups: latteGroups),
        Product(id: "p29", name: "澳白咖啡 Flat White", desc: "雙份精萃濃縮咖啡搭配極細緻微奶泡，咖啡風味更加濃烈純粹", price: 90, category: "咖啡", emoji: "☕️", groups: latteGroups),
        Product(id: "p30", name: "髒咖啡 Dirty", desc: "冰涼香醇特調鮮乳直落熱濃縮，冷熱交織雙重層次（限店內飲用）", price: 95, category: "咖啡", emoji: "🥛", orderLimit: 5),
        Product(id: "p31", name: "桂花蜂蜜拿鐵", desc: "在地小農天然桂花蜜融入香醇拿鐵，入口花香芬芳甘甜", price: 105, category: "咖啡", emoji: "🍯", groups: latteGroups),
        Product(id: "p32", name: "榛果香草拿鐵", desc: "炒香堅果香氣與天然香草風味，溫暖圓潤", price: 95, category: "咖啡", emoji: "🌰", groups: latteGroups),

        // 茶飲特調
        Product(id: "p10", name: "日月潭紅玉紅茶", desc: "台灣在地台茶18號，自帶薄荷與肉桂蜜香", price: 65, category: "茶飲特調", emoji: "🫖", groups: teaGroups),
        Product(id: "p11", name: "經典鮮奶茶", desc: "濃韻阿薩姆紅茶搭配純淨鮮乳，香醇順口", price: 80, category: "茶飲特調", emoji: "🧋", groups: teaGroups),
        Product(id: "p12", name: "白桃烏龍氣泡飲", desc: "香甜蜜桃果泥融入高山烏龍與綿密氣泡", price: 90, category: "茶飲特調", emoji: "🍑", groups: sparklingGroups),
        Product(id: "p13", name: "宇治抹茶拿鐵", desc: "日本宇治丸久小山園抹茶，茶香濃厚優雅", price: 100, category: "茶飲特調", emoji: "🍵", groups: latteGroups),
        Product(id: "p14", name: "柚香蜜桃冰茶", desc: "黃金柚子醬佐以慢熬水蜜桃果肉，甘甜解膩", price: 85, category: "茶飲特調", emoji: "🍹", groups: teaGroups),
        Product(id: "p33", name: "鐵觀音重乳鮮奶茶", desc: "木質重火烘焙鐵觀音茶湯，融匯醇濃小農鮮奶", price: 85, category: "茶飲特調", emoji: "🧋", groups: teaGroups),
        Product(id: "p34", name: "靜岡焙茶歐蕾", desc: "深焙煎茶溫潤無苦澀，散發堅果與焙火暖香", price: 95, category: "茶飲特調", emoji: "🍵", groups: latteGroups),
        Product(id: "p35", name: "檸檬冬瓜清爽氣泡飲", desc: "手工冬瓜磚熬煮，佐以屏東鮮榨檸檬汁與豐沛氣泡", price: 75, category: "茶飲特調", emoji: "🍋", groups: sparklingGroups),
        Product(id: "p36", name: "蔓越莓接骨木氣泡飲", desc: "酸甜紅寶石蔓越莓搭配優雅歐洲接骨木花香，晶亮透紅", price: 90, category: "茶飲特調", emoji: "🫐", groups: sparklingGroups),
        Product(id: "p37", name: "皇家伯爵茶", desc: "斯里蘭卡高山紅茶佐頂級佛手柑精油，優雅迷人", price: 70, category: "茶飲特調", emoji: "🫖", groups: teaGroups),
        Product(id: "p38", name: "蜂蜜柚子南非國寶茶", desc: "零咖啡因溫和養身茶，搭配韓國黃金柚子與龍眼花蜜", price: 80, category: "茶飲特調", emoji: "🍯", groups: teaGroups),
        Product(id: "p39", name: "泰式手標厚奶茶", desc: "泰國道地手標茶葉現萃，濃香甜郁煉乳風味", price: 85, category: "茶飲特調", emoji: "🧋", groups: teaGroups),

        // 輕食
        Product(id: "p3", name: "早餐套餐", desc: "主餐＋飲品，自由搭配", price: 150, category: "輕食", emoji: "🥪", groups: breakfastGroups),
        Product(id: "p15", name: "燻雞酪梨貝果", desc: "低溫舒肥燻雞胸佐鮮切酪梨片與外酥內韌貝果", price: 120, category: "輕食", emoji: "🥯", groups: bagelGroups),
        Product(id: "p16", name: "牛肉起司可頌堡", desc: "香烤奶油可頌夾入炙燒牛肉片與濃郁切達起司", price: 135, category: "輕食", emoji: "🥐", orderLimit: 5),
        Product(id: "p17", name: "日式厚蛋燒三明治", desc: "柴魚高湯嫩煎厚蛋，甜鹹多汁滑嫩", price: 85, category: "輕食", emoji: "🥪"),
        Product(id: "p18", name: "義式羅勒松子培根麵", desc: "主廚特製新鮮青醬與厚切香煎培根丁", price: 160, category: "輕食", emoji: "🍝", groups: pastaGroups),
        Product(id: "p19", name: "經典凱薩沙拉", desc: "爽脆羅曼生菜佐帕瑪森起司脆片與酥脆麵包丁", price: 110, category: "輕食", emoji: "🥗"),
        Product(id: "p40", name: "庫克太太三明治", desc: "吐司夾炙烤火腿與切達起司，焗烤法式白醬佐半熟太陽蛋", price: 130, category: "輕食", emoji: "🍳", groups: toastGroups),
        Product(id: "p41", name: "煙燻鮭魚酸種開放三明治", desc: "外酥內軟舊金山酸種麵包佐蒔蘿酸奶醬、挪威煙燻鮭魚與酸豆", price: 145, category: "輕食", emoji: "🥪", orderLimit: 4),
        Product(id: "p42", name: "辣味番茄海鮮墨魚義大利麵", desc: "主廚特製辣味番茄紅醬搭配鮮甜白蝦、透抽與蛤蜊", price: 180, category: "輕食", emoji: "🍝", groups: pastaGroups),
        Product(id: "p43", name: "松露野菇奶油義大利麵", desc: "義大利頂級黑松露醬、新鮮牛肝菌菇與濃郁帕瑪森奶醬", price: 170, category: "輕食", emoji: "🍝", groups: pastaGroups),
        Product(id: "p44", name: "炙燒明太子軟法麵包", desc: "博多特級明太子調和日式蛋黃醬，炙烤至焦香酥脆", price: 95, category: "輕食", emoji: "🥖", groups: dessertGroups),
        Product(id: "p45", name: "經典松露野菇鹹派", desc: "法式手工千層派皮，包裹野菇、洋蔥與濃郁蛋奶松露內餡", price: 110, category: "輕食", emoji: "🥧", groups: dessertGroups),
        Product(id: "p46", name: "慢烤南瓜藜麥堅果溫沙拉", desc: "香甜栗子南瓜、有機三色藜麥與烘烤堅果佐義大利巴薩米克醋", price: 125, category: "輕食", emoji: "🥗"),
        Product(id: "p47", name: "酪梨蛋沙拉丹麥吐司", desc: "多層次酥脆丹麥吐司搭配新鮮酪梨塊與香滑蛋沙拉", price: 105, category: "輕食", emoji: "🥑", groups: toastGroups),

        // 甜點
        Product(id: "p4", name: "奶油可頌", desc: "現烤酥脆，每單限點 3 個", price: 55, category: "甜點", emoji: "🥐", orderLimit: 3, groups: dessertGroups),
        Product(id: "p5", name: "檸檬塔", desc: "今日已售完", price: 90, category: "甜點", emoji: "🍋", soldOut: true),
        Product(id: "p20", name: "巴斯克焦香乳酪", desc: "焦黑表皮伴隨半熟流心質地，乳香濃郁化口", price: 95, category: "甜點", emoji: "🧀", groups: dessertGroups),
        Product(id: "p21", name: "法式提拉米蘇", desc: "義大利馬斯卡彭乳酪佐咖啡酒手指餅乾", price: 110, category: "甜點", emoji: "🍰", orderLimit: 2),
        Product(id: "p22", name: "黑糖肉桂捲", desc: "手工烘烤濃郁微辛肉桂香，附烘烤酥脆核桃", price: 80, category: "甜點", emoji: "🍥", groups: dessertGroups),
        Product(id: "p23", name: "靜岡抹茶千層蛋糕", desc: "20層細緻薄餅皮夾入濃抹茶香緹鮮奶油", price: 130, category: "甜點", emoji: "🥞"),
        Product(id: "p48", name: "法式香草可麗露", desc: "蜂蠟銅模烘烤焦香薄脆外殼，內餡濕潤如香草布丁（每人限購4顆）", price: 65, category: "甜點", emoji: "🧁", orderLimit: 4, groups: dessertGroups),
        Product(id: "p49", name: "焦糖脆糖烤布蕾", desc: "現點現噴火烤焦脆焦糖層，滿滿馬達加斯加香草籽純濃布丁", price: 75, category: "甜點", emoji: "🍮", orderLimit: 4),
        Product(id: "p50", name: "法芙娜熔岩黑巧克力蛋糕", desc: "70%法芙娜黑巧克力現烤，切開緩緩流出熱騰騰濃郁生巧漿", price: 105, category: "甜點", emoji: "🍫", groups: dessertGroups),
        Product(id: "p51", name: "伯爵鹽之花奶蓋戚風", desc: "細緻伯爵茶香海綿蛋糕，淋上微鹹法國鹽之花輕盈奶霜", price: 90, category: "甜點", emoji: "🍰", groups: dessertGroups),
        Product(id: "p52", name: "酥皮焦糖泡芙", desc: "菠蘿酥脆外皮灌入滿滿香草卡士達與手炒微苦焦糖醬", price: 70, category: "甜點", emoji: "🥯", groups: dessertGroups),
        Product(id: "p53", name: "白桃蜜香生乳捲", desc: "日本中澤純生鮮奶油裹入多汁水蜜桃切片，輕盈不膩口", price: 115, category: "甜點", emoji: "🍰", orderLimit: 3),
        Product(id: "p54", name: "焦糖蘋果肉桂派", desc: "慢火熬煮肉桂富士蘋果丁，包覆金黃千層酥皮（每日限量）", price: 95, category: "甜點", emoji: "🥧", groups: dessertGroups),

        // 季節限定
        Product(id: "p24", name: "草莓鮮奶油戚風", desc: "當季新鮮大湖草莓與蓬鬆柔軟日式戚風", price: 140, category: "季節限定", emoji: "🍓", orderLimit: 2),
        Product(id: "p25", name: "秋栗蒙布朗", desc: "法國進口栗子泥，層次分明包裹蛋白糖霜", price: 135, category: "季節限定", emoji: "🌰", groups: dessertGroups),
        Product(id: "p55", name: "盛夏芒果乳酪帕菲", desc: "屏東枋山愛文芒果、百香果凍與香草生乳酪杯裝盛宴", price: 160, category: "季節限定", emoji: "🥭", orderLimit: 2),
        Product(id: "p56", name: "櫻花莓果粉紅氣泡特調", desc: "日本鹽漬櫻花萃取液佐覆盆莓果泥與微氣泡，如落櫻般浪漫", price: 100, category: "季節限定", emoji: "🌸", groups: sparklingGroups),
        Product(id: "p57", name: "靜岡抹茶草莓生巧大福", desc: "手工Q彈麻糬皮、宇治抹茶生巧克力與整顆新鮮草莓", price: 80, category: "季節限定", emoji: "🍡", orderLimit: 3),
        Product(id: "p58", name: "炙烤黑糖栗子歐蕾", desc: "慢熬栗子泥與小農蒸奶，表面薄脆火炙黑糖焦香", price: 95, category: "季節限定", emoji: "🌰", groups: latteGroups),
        Product(id: "p59", name: "柚香金桔雪酪氣泡飲", desc: "自製金桔雪酪冰球漂浮於日本柚子氣泡飲中，酸甜沁涼", price: 105, category: "季節限定", emoji: "🍹", groups: sparklingGroups)
    ]
}

// MARK: - 規格邏輯（驗證、可見群組、快照）
enum Spec {
    static func visible(_ groups: [SpecGroup], _ sel: [String: Int]) -> [SpecGroup] {
        var out: [SpecGroup] = []
        for g in groups {
            out.append(g)
            for o in g.options where (sel[o.id] ?? 0) > 0 { out += visible(o.children, sel) }
        }
        return out
    }
    static func allOptions(_ groups: [SpecGroup]) -> [SpecOption] {
        var out: [SpecOption] = []
        for g in groups { for o in g.options { out.append(o); out += allOptions(o.children) } }
        return out
    }
    static func errors(_ p: Product, _ sel: [String: Int]) -> [String] {
        var e: [String] = []
        for g in visible(p.groups, sel) {
            let n = g.options.filter { (sel[$0.id] ?? 0) > 0 }.count
            if n < g.minSel { e.append("請選擇「\(g.name)」") }
            if n > g.maxSel { e.append("「\(g.name)」最多選 \(g.maxSel) 項") }
        }
        return e
    }
    static func picks(_ p: Product, _ sel: [String: Int]) -> [Picked] {
        var r: [Picked] = []
        for g in visible(p.groups, sel) {
            for o in g.options {
                let q = sel[o.id] ?? 0
                if q > 0 { r.append(Picked(name: o.name, price: o.price, qty: q)) }
            }
        }
        return r
    }
    static func clear(_ o: SpecOption, _ sel: inout [String: Int]) {
        sel[o.id] = nil
        for g in o.children { for c in g.options { clear(c, &sel) } }
    }
}

// MARK: - App 狀態
final class AppModel: ObservableObject {
    @Published var cart: [CartItem] = []
    @Published var orders: [Order] = []
    @Published var promo: String?
    @Published var tab = 0
    @Published var showCart = false
    @Published var dining = "內用"
    @Published var table = "A3"
    @Published var toast: String?
    @Published var isOrdering = false
    let minSpend = 150
    let products = Catalog.products

    init() {
        func line(_ pid: String, _ sel: [String: Int], _ q: Int) -> CartItem {
            let p = Catalog.products.first { $0.id == pid }!
            return CartItem(product: p, selection: sel, picks: Spec.picks(p, sel), qty: q, note: "")
        }
        let day: TimeInterval = 86400
        orders = [
            Order(number: "CL-1051", date: Date().addingTimeInterval(-day), items: [
                line("p3", ["m-sa": 1, "f-h": 1, "d1": 1], 1)],
                  discount: 0, status: .processing, pay: .unpaid, pickup: "立即取餐", method: "匯款"),
            Order(number: "CL-1042", date: Date().addingTimeInterval(-3 * day), items: [
                line("p2", ["s-l": 1, "w2": 1, "e-shot": 2], 1), line("p4", [:], 2)],
                  discount: 20, status: .completed, pay: .paid, pickup: "立即取餐", method: "LINE Pay"),
            Order(number: "CL-1038", date: Date().addingTimeInterval(-7 * day), items: [
                line("p5", [:], 1), line("p1", [:], 1)],
                  discount: 0, status: .cancelled, pay: .refunded, pickup: "預約取餐", method: "信用卡")
        ]
    }

    var count: Int { cart.reduce(0) { $0 + $1.qty } }
    var subtotal: Int { cart.reduce(0) { $0 + $1.subtotal } }
    var discount: Int {
        switch promo {
        case "WELCOME10": return subtotal / 10
        case "SAVE50": return subtotal >= 300 ? 50 : 0
        default: return 0
        }
    }
    var total: Int { subtotal - discount }

    func qtyInCart(_ pid: String, excluding: UUID? = nil) -> Int {
        cart.filter { $0.product.id == pid && $0.id != excluding }.reduce(0) { $0 + $1.qty }
    }

    func flash(_ s: String) {
        toast = s
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.6) { self.toast = nil }
    }

    /// 回傳錯誤訊息；nil 代表成功
    func add(_ item: CartItem, replacing: UUID?) -> String? {
        guard isOrdering else {
            return "目前為純瀏覽模式，請從首頁點擊「開始點餐」"
        }
        if let lim = item.product.orderLimit,
           qtyInCart(item.product.id, excluding: replacing) + item.qty > lim {
            return "「\(item.product.name)」每單限點 \(lim) 份"
        }
        if let r = replacing, let i = cart.firstIndex(where: { $0.id == r }) {
            cart[i] = item
            flash("已更新購物車")
        } else if let i = cart.firstIndex(where: {
            $0.product.id == item.product.id && $0.selection == item.selection && $0.note == item.note }) {
            cart[i].qty += item.qty
            flash("已加入購物車")
        } else {
            cart.append(item)
            flash("已加入購物車")
        }
        return nil
    }

    @discardableResult
    func setQty(_ id: UUID, _ q: Int) -> String? {
        guard let i = cart.firstIndex(where: { $0.id == id }) else { return nil }
        if q <= 0 { cart.remove(at: i); if cart.isEmpty { promo = nil }; return nil }
        let p = cart[i].product
        if let lim = p.orderLimit, qtyInCart(p.id, excluding: id) + q > lim {
            return "「\(p.name)」每單限點 \(lim) 份"
        }
        cart[i].qty = q
        return nil
    }

    /// 回傳錯誤訊息；nil 代表成功套用
    func applyPromo(_ raw: String) -> String? {
        let c = raw.trimmingCharacters(in: .whitespaces).uppercased()
        switch c {
        case "WELCOME10": promo = c; return nil
        case "SAVE50":
            if subtotal < 300 { return "未達使用門檻：需消費滿 NT$300" }
            promo = c; return nil
        case "OLD2024": return "此優惠碼已過期"
        default: return "無效的優惠碼"
        }
    }

    func placeOrder(pickup: String, method: String, payFails: Bool) -> Order {
        let o = Order(number: "CL-\(1060 + orders.count)", date: Date(), items: cart, discount: discount,
                      status: payFails ? .pending : .processing,
                      pay: payFails ? .failed : (method == "匯款" ? .unpaid : .paid),
                      pickup: pickup, method: method)
        orders.insert(o, at: 0)
        cart = []; promo = nil
        isOrdering = false
        return o
    }

    /// 再次購買：逐項重新檢查商品與規格是否仍可用
    func reorder(_ order: Order) -> String {
        isOrdering = true
        var added = 0
        var skipped: [String] = []
        for it in order.items {
            guard let p = products.first(where: { $0.id == it.product.id }) else {
                skipped.append("\(it.product.name)（已下架）"); continue }
            if p.soldOut { skipped.append("\(p.name)（已售完）"); continue }
            let all = Spec.allOptions(p.groups)
            let valid = it.selection.keys.allSatisfy { id in
                if let o = all.first(where: { $0.id == id }) { return !o.soldOut }
                return false
            }
            if !valid || !Spec.errors(p, it.selection).isEmpty {
                skipped.append("\(p.name)（規格已變更，請重新選擇）"); continue }
            let fresh = CartItem(product: p, selection: it.selection, picks: Spec.picks(p, it.selection),
                                 qty: it.qty, note: it.note)
            if add(fresh, replacing: nil) == nil { added += 1 } else { skipped.append("\(p.name)（超過限點）") }
        }
        var msg = "已加入 \(added) 項到購物車。"
        if !skipped.isEmpty { msg += "\n無法加入：" + skipped.joined(separator: "、") }
        return msg
    }
}

// MARK: - ContentView
struct ContentView: View {
    @StateObject private var model = AppModel()
    var body: some View {
        TabView(selection: $model.tab) {
            HomeView().tabItem { Label("首頁", systemImage: "house") }.tag(0)
            MenuView().tabItem { Label("菜單", systemImage: "cup.and.saucer") }.tag(1)
            OrdersView().tabItem { Label("訂單", systemImage: "list.bullet.rectangle") }.tag(2)
            ProfileView().tabItem { Label("我的", systemImage: "person") }.tag(3)
        }
        .onChange(of: model.tab) { _, newTab in
            if newTab == 0 {
                model.isOrdering = false
            }
        }
        .tint(.caramel)
        .environmentObject(model)
        .sheet(isPresented: $model.showCart) { CartSheet().environmentObject(model) }
        .overlay(alignment: .top) {
            if let t = model.toast {
                Text(t)
                    .font(.subheadline.weight(.medium))
                    .padding(.horizontal, 16).padding(.vertical, 10)
                    .background(Color.espresso).foregroundColor(.white)
                    .clipShape(Capsule()).padding(.top, 8)
                    .transition(.move(edge: .top).combined(with: .opacity))
            }
        }
        .animation(.easeInOut, value: model.toast)
    }
}

// MARK: - 首頁
struct HomeView: View {
    @EnvironmentObject var m: AppModel
    @State private var askBell = false
    @State private var bellDone = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    ZStack(alignment: .bottomLeading) {
                        RoundedRectangle(cornerRadius: 24).fill(Color.espresso)
                        Text("☕️").font(.system(size: 96)).opacity(0.9)
                            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing).padding(20)
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Café Life").font(.system(size: 32, weight: .semibold, design: .serif))
                            Text("A little pause, a better day.").font(.system(.body, design: .serif).italic())
                            Text("讓一杯咖啡，成為日常的小小儀式。").font(.subheadline).opacity(0.85)
                        }
                        .foregroundColor(.white).padding(20)
                    }
                    .frame(height: 230)

                    VStack(alignment: .leading, spacing: 12) {
                        Badge(text: "營業中", color: .sage)
                        Label("今日營業 10:00–20:00", systemImage: "clock")
                        Label("最後加點 19:30", systemImage: "bell.badge")
                        Label("低消 \(nt(m.minSpend))", systemImage: "creditcard")
                    }
                    .font(.subheadline).foregroundColor(.espresso).card()

                    VStack(alignment: .leading, spacing: 12) {
                        Text("用餐方式").font(.headline)
                        Picker("用餐方式", selection: $m.dining) {
                            Text("內用").tag("內用"); Text("外帶").tag("外帶")
                        }.pickerStyle(.segmented)
                        if m.dining == "內用" {
                            Picker("桌號", selection: $m.table) {
                                ForEach(["A1", "A2", "A3", "B1", "B2"], id: \.self) { Text("桌號 \($0)").tag($0) }
                            }.tint(.caramel)
                        }
                    }
                    .foregroundColor(.espresso).card()

                    Button("開始點餐") {
                        m.isOrdering = true
                        m.tab = 1
                    }.buttonStyle(CafeButton())
                    Button { askBell = true } label: {
                        Label("呼叫服務鈴", systemImage: "bell")
                            .frame(maxWidth: .infinity, minHeight: 48)
                            .background(Color.latte).foregroundColor(.espresso)
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                    }
                }
                .padding(20)
            }
            .background(Color.cream)
            .navigationBarHidden(true)
            .confirmationDialog("呼叫服務鈴？", isPresented: $askBell, titleVisibility: .visible) {
                Button("確認呼叫") { bellDone = true }
            }
            .alert("服務鈴", isPresented: $bellDone) {
                Button("好") {}
            } message: { Text("已通知店家，請稍後") }
            .onAppear {
                m.isOrdering = false
            }
        }
    }
}

// MARK: - 菜單
struct MenuView: View {
    @EnvironmentObject var m: AppModel
    @State private var cat = "全部"
    @State private var query = ""
    @State private var picked: Product?

    var list: [Product] {
        m.products.filter { p in
            (cat == "全部" || p.category == cat) &&
            (query.isEmpty || p.name.localizedCaseInsensitiveContains(query)
             || p.desc.localizedCaseInsensitiveContains(query))
        }
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                if !m.isOrdering {
                    HStack(spacing: 8) {
                        Image(systemName: "eye.fill")
                            .foregroundColor(.caramel)
                        Text("目前為純瀏覽模式，不可加入購物車")
                            .font(.caption.weight(.medium))
                            .foregroundColor(.espresso)
                        Spacer()
                        Button("前往首頁點餐") {
                            m.tab = 0
                        }
                        .font(.caption.weight(.bold))
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(Color.caramel)
                        .foregroundColor(.white)
                        .clipShape(Capsule())
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
                    .background(Color.white)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .padding(.horizontal, 20)
                    .padding(.bottom, 8)
                }
                VStack(spacing: 12) {
                    HStack {
                        Image(systemName: "magnifyingglass").foregroundColor(.subText)
                        TextField("搜尋商品名稱或描述", text: $query)
                    }
                    .padding(.horizontal, 14).frame(height: 48)
                    .background(Color.white).clipShape(RoundedRectangle(cornerRadius: 12))

                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack {
                            ForEach(["全部"] + Catalog.categories, id: \.self) { c in
                                Button(c) { cat = c }
                                    .font(.subheadline.weight(.medium))
                                    .padding(.horizontal, 16).padding(.vertical, 8)
                                    .background(cat == c ? Color.espresso : Color.latte)
                                    .foregroundColor(cat == c ? .white : .espresso)
                                    .clipShape(Capsule())
                            }
                        }
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 12)

                ScrollView {
                    LazyVStack(spacing: 12) {
                        if list.isEmpty {
                            EmptyState(icon: "magnifyingglass", title: "找不到商品", hint: "換個關鍵字，或切換分類看看")
                        }
                        ForEach(list) { p in
                            Button { picked = p } label: { ProductRow(p: p) }
                                .buttonStyle(.plain).disabled(p.soldOut)
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 4)
                    .padding(.bottom, 16)
                }
            }
            .background(Color.cream)
            .navigationTitle(m.isOrdering ? "菜單" : "菜單（僅供瀏覽）")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button { m.showCart = true } label: { Image(systemName: "bag") }
                }
            }
            .safeAreaInset(edge: .bottom) {
                if m.isOrdering && m.count > 0 {
                    Button { m.showCart = true } label: {
                        HStack {
                            Image(systemName: "bag.fill")
                            Text("購物車 \(m.count) 件")
                            Spacer()
                            Text(nt(m.subtotal)).fontWeight(.semibold)
                        }
                        .padding(.horizontal, 18).frame(height: 54)
                        .background(Color.espresso).foregroundColor(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                        .padding(.horizontal, 20).padding(.bottom, 6)
                    }
                }
            }
            .sheet(item: $picked) { p in ProductSheet(product: p).environmentObject(m) }
        }
    }
}

struct ProductRow: View {
    let p: Product
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(p.name).font(.headline)
                if p.soldOut { Badge(text: "售完", color: .roseBeige) }
                if let l = p.orderLimit { Badge(text: "每單限 \(l)", color: .roseBeige) }
            }
            Text(p.desc).font(.subheadline).foregroundColor(.subText).lineLimit(2)
            Text(nt(p.price)).font(.subheadline.weight(.semibold)).foregroundColor(.caramel)
        }
        .foregroundColor(.espresso).card().opacity(p.soldOut ? 0.55 : 1)
    }
}

// MARK: - 商品詳情（動態規格）
struct ProductSheet: View {
    @EnvironmentObject var m: AppModel
    @Environment(\.dismiss) private var dismiss
    let product: Product
    let editing: CartItem?
    @State private var sel: [String: Int]
    @State private var qty: Int
    @State private var note: String
    @State private var errors: [String] = []

    init(product: Product, editing: CartItem? = nil) {
        self.product = product
        self.editing = editing
        _sel = State(initialValue: editing?.selection ?? [:])
        _qty = State(initialValue: editing?.qty ?? 1)
        _note = State(initialValue: editing?.note ?? "")
    }

    var unit: Int { product.price + Spec.picks(product, sel).reduce(0) { $0 + $1.price * $1.qty } }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    Text(product.name).font(.title2.weight(.semibold))
                    Text(product.desc).foregroundColor(.subText)
                    Text("基本價 \(nt(product.price))").font(.headline).foregroundColor(.caramel)

                    ForEach(Spec.visible(product.groups, sel)) { g in groupView(g) }

                    VStack(alignment: .leading, spacing: 8) {
                        Text("特殊需求").font(.headline)
                        TextField("例如：少冰、不要吸管", text: $note)
                            .padding(.horizontal, 12).frame(height: 48)
                            .background(Color.cream).clipShape(RoundedRectangle(cornerRadius: 12))
                    }.card()

                    HStack {
                        Text("數量").font(.headline)
                        Spacer()
                        stepper(value: qty, minus: { if qty > 1 { qty -= 1 } }, plus: { qty += 1 })
                    }.card()
                }
                .foregroundColor(.espresso).padding(20)
            }
            .background(Color.cream)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .navigationBarLeading) { Button("關閉") { dismiss() } } }
            .safeAreaInset(edge: .bottom) {
                VStack(spacing: 8) {
                    if !errors.isEmpty {
                        Text(errors.joined(separator: "\n")).font(.footnote)
                            .foregroundColor(.espresso).padding(10).frame(maxWidth: .infinity, alignment: .leading)
                            .background(Color.roseBeige).clipShape(RoundedRectangle(cornerRadius: 10))
                    }
                    if m.isOrdering {
                        Button("\(editing == nil ? "加入購物車" : "更新品項") · \(nt(unit * qty))") { submit() }
                            .buttonStyle(CafeButton())
                    } else {
                        VStack(spacing: 6) {
                            Text("菜單僅供瀏覽，請先從首頁「開始點餐」")
                                .font(.footnote)
                                .foregroundColor(.subText)
                            Button("加入購物車（請由首頁開始點餐）") {
                                dismiss()
                                m.tab = 0
                            }
                            .buttonStyle(CafeButton(enabled: false))
                        }
                    }
                }
                .padding(.horizontal, 20).padding(.vertical, 10).background(Color.cream)
            }
        }
    }

    func stepper(value: Int, minus: @escaping () -> Void, plus: @escaping () -> Void) -> some View {
        HStack(spacing: 14) {
            Button(action: minus) { Image(systemName: "minus.circle") }
            Text("\(value)").frame(minWidth: 22).font(.headline)
            Button(action: plus) { Image(systemName: "plus.circle") }
        }.font(.title3).foregroundColor(.caramel)
    }

    @ViewBuilder func groupView(_ g: SpecGroup) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(g.name).font(.headline)
                Badge(text: g.minSel > 0 ? "必選" : "選填", color: g.minSel > 0 ? .roseBeige : .latte)
                Spacer()
                Text(g.maxSel > 1 ? "最多 \(g.maxSel) 項" : "單選").font(.caption).foregroundColor(.subText)
            }
            ForEach(g.options) { o in optionRow(g, o) }
        }.card()
    }

    func optionRow(_ g: SpecGroup, _ o: SpecOption) -> some View {
        let n = sel[o.id] ?? 0
        let icon = g.maxSel == 1 ? (n > 0 ? "largecircle.fill.circle" : "circle")
                                 : (n > 0 ? "checkmark.square.fill" : "square")
        return HStack {
            Button { toggle(g, o) } label: {
                HStack {
                    Image(systemName: icon).foregroundColor(n > 0 ? .caramel : .subText)
                    Text(o.name + (o.soldOut ? "（售完）" : ""))
                    Spacer()
                    if o.price != 0 {
                        Text(o.price > 0 ? "+\(o.price)" : "\(o.price)").foregroundColor(.caramel)
                    }
                }
            }
            .buttonStyle(.plain).disabled(o.soldOut)
            .foregroundColor(o.soldOut ? .subText : .espresso)
            if n > 0 && o.maxQty > 1 {
                stepper(value: n,
                        minus: { sel[o.id] = max(1, n - 1) },
                        plus: { if n < o.maxQty { sel[o.id] = n + 1 } else { errors = ["「\(o.name)」最多 \(o.maxQty) 份"] } })
                    .font(.body)
            }
        }
    }

    func toggle(_ g: SpecGroup, _ o: SpecOption) {
        errors = []
        if (sel[o.id] ?? 0) > 0 {
            if !(g.maxSel == 1 && g.minSel > 0) { Spec.clear(o, &sel) }   // 單選必填不可取消
            return
        }
        if g.maxSel == 1 {
            for x in g.options where x.id != o.id { Spec.clear(x, &sel) }   // 換選時清除舊子規格
        } else if g.options.filter({ (sel[$0.id] ?? 0) > 0 }).count >= g.maxSel {
            errors = ["「\(g.name)」最多選 \(g.maxSel) 項"]; return
        }
        sel[o.id] = 1
    }

    func submit() {
        guard m.isOrdering else {
            errors = ["目前為純瀏覽模式，請由首頁點擊「開始點餐」"]
            return
        }
        let e = Spec.errors(product, sel)
        if !e.isEmpty { errors = e; return }
        let item = CartItem(product: product, selection: sel, picks: Spec.picks(product, sel), qty: qty, note: note)
        if let err = m.add(item, replacing: editing?.id) { errors = [err]; return }
        dismiss()
    }
}

// MARK: - 購物車
struct EmptyCartHeightKey: PreferenceKey {
    static var defaultValue: CGFloat = 250
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        let n = nextValue()
        if n > 0 { value = n }
    }
}

struct CartSheet: View {
    @EnvironmentObject var m: AppModel
    @State private var code = ""
    @State private var promoError: String?
    @State private var cartError: String?
    @State private var editing: CartItem?
    @State private var confirmClear = false
    @State private var emptyHeight: CGFloat = 250

    var short: Int { max(0, m.minSpend - m.subtotal) }

    var body: some View {
        NavigationStack {
            Group {
                if m.cart.isEmpty {
                    VStack {
                        EmptyState(icon: "bag", title: "購物車是空的", hint: "到菜單挑選喜歡的品項吧")
                        Button("回菜單") { m.showCart = false; m.tab = 1 }.buttonStyle(CafeButton()).padding(.horizontal, 40)
                    }
                    .background(
                        GeometryReader { geo in
                            Color.clear.preference(key: EmptyCartHeightKey.self, value: geo.size.height)
                        }
                    )
                } else { content }
            }
            .background(Color.cream)
            .navigationTitle("購物車")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) { Button("關閉") { m.showCart = false } }
                if !m.cart.isEmpty {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button("清空", role: .destructive) { confirmClear = true }
                    }
                }
            }
            .confirmationDialog("清空購物車？", isPresented: $confirmClear, titleVisibility: .visible) {
                Button("清空", role: .destructive) { m.cart = []; m.promo = nil }
            }
            .sheet(item: $editing) { it in ProductSheet(product: it.product, editing: it).environmentObject(m) }
        }
        .onPreferenceChange(EmptyCartHeightKey.self) { h in
            if h > 0 { emptyHeight = h }
        }
        .presentationDetents(m.cart.isEmpty ? [.height(emptyHeight)] : [.large])
    }

    var content: some View {
        ScrollView {
            VStack(spacing: 12) {
                ForEach(m.cart) { it in itemCard(it) }
                if let e = cartError { warn(e) }

                VStack(alignment: .leading, spacing: 8) {
                    Text("優惠碼").font(.headline)
                    HStack {
                        TextField("輸入優惠碼", text: $code).textInputAutocapitalization(.characters)
                            .padding(.horizontal, 12).frame(height: 48)
                            .background(Color.cream).clipShape(RoundedRectangle(cornerRadius: 12))
                        Button("套用") { promoError = m.applyPromo(code) }
                            .padding(.horizontal, 16).frame(height: 48)
                            .background(Color.caramel).foregroundColor(.white)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                    if let e = promoError { warn(e) }
                    if let p = m.promo {
                        HStack {
                            Badge(text: "已套用 \(p)", color: .sage)
                            Text(m.discount > 0 ? "折抵 \(nt(m.discount))" : "目前未達折扣條件").font(.footnote)
                            Spacer()
                            Button("移除") { m.promo = nil; code = ""; promoError = nil }.font(.footnote)
                        }
                    }
                    Text("優惠碼：WELCOME10（9 折）、SAVE50（滿 300 折 50）、OLD2024（已過期）")
                        .font(.caption).foregroundColor(.subText)
                }.foregroundColor(.espresso).card()

                VStack(spacing: 8) {
                    row("商品小計", nt(m.subtotal))
                    if m.discount > 0 { row("優惠折扣", "-" + nt(m.discount)) }
                    Divider()
                    row("總計", nt(m.total), bold: true)
                }.card()

                if short > 0 { warn("未達低消 \(nt(m.minSpend))，尚差 \(nt(short))") }

                NavigationLink { CheckoutView() } label: { Text("前往結帳") }
                    .buttonStyle(CafeButton(enabled: short == 0)).disabled(short > 0)
            }
            .padding(20)
        }
    }

    func warn(_ s: String) -> some View {
        Text(s).font(.footnote).foregroundColor(.espresso)
            .padding(10).frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.roseBeige).clipShape(RoundedRectangle(cornerRadius: 10))
    }

    func row(_ a: String, _ b: String, bold: Bool = false) -> some View {
        HStack { Text(a); Spacer(); Text(b).fontWeight(bold ? .bold : .regular) }
            .foregroundColor(.espresso)
    }

    func itemCard(_ it: CartItem) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(it.product.name).font(.headline)
                    if !it.summary.isEmpty { Text(it.summary).font(.subheadline).foregroundColor(.subText) }
                    if !it.note.isEmpty { Text("備註：\(it.note)").font(.footnote).foregroundColor(.subText) }
                }
                Spacer()
                Text(nt(it.subtotal)).font(.headline).foregroundColor(.caramel)
            }
            HStack(spacing: 14) {
                Button { cartError = m.setQty(it.id, it.qty - 1) } label: { Image(systemName: "minus.circle") }
                Text("\(it.qty)").font(.headline)
                Button { cartError = m.setQty(it.id, it.qty + 1) } label: { Image(systemName: "plus.circle") }
                Text("單價 \(nt(it.unit))").font(.caption).foregroundColor(.subText)
                Spacer()
                Button("編輯") { editing = it }.font(.subheadline)
                Button(role: .destructive) { m.setQty(it.id, 0) } label: { Image(systemName: "trash") }
            }
            .font(.title3).foregroundColor(.caramel)
        }
        .foregroundColor(.espresso).card()
    }
}

// MARK: - 結帳
struct CheckoutView: View {
    @EnvironmentObject var m: AppModel
    @AppStorage("pName") private var name = ""
    @AppStorage("pPhone") private var phone = ""
    @State private var asap = true
    @State private var when = Date().addingTimeInterval(3600)
    @State private var method = "LINE Pay"
    @State private var last5 = ""
    @State private var payFails = false
    @State private var invType = "個人電子發票"
    @State private var taxID = ""
    @State private var carrier = ""
    @State private var donate = ""
    @State private var tags: Set<String> = []
    @State private var note = ""
    @State private var errors: [String] = []
    @State private var done: Order?
    private let prepMin = 20

    var pickupText: String {
        asap ? "立即取餐（約 \(prepMin) 分鐘）" : when.formatted(date: .abbreviated, time: .shortened)
    }

    var body: some View {
        if let o = done {
            SuccessView(order: o)
        } else {
            Form {
                Section("取餐") {
                    Picker("取餐方式", selection: $asap) {
                        Text("立即取餐").tag(true); Text("預約取餐").tag(false)
                    }.pickerStyle(.segmented)
                    if asap {
                        Text("預計備餐 \(prepMin) 分鐘").font(.footnote).foregroundColor(.subText)
                    } else {
                        DatePicker("預約時間", selection: $when,
                                   in: Date().addingTimeInterval(Double(prepMin) * 60)...Date().addingTimeInterval(7 * 86400))
                    }
                }
                Section("訂購人") {
                    TextField("姓名", text: $name)
                    TextField("手機（09xxxxxxxx）", text: $phone).keyboardType(.phonePad)
                }
                Section("付款") {
                    Picker("付款方式", selection: $method) {
                        ForEach(["LINE Pay", "信用卡", "匯款"], id: \.self) { Text($0).tag($0) }
                    }
                    if method == "匯款" {
                        TextField("匯款帳號末五碼", text: $last5).keyboardType(.numberPad)
                    }
                }
                Section("發票") {
                    Picker("類型", selection: $invType) {
                        ForEach(["個人電子發票", "公司統編", "手機載具", "捐贈愛心碼"], id: \.self) { Text($0).tag($0) }
                    }
                    if invType == "公司統編" { TextField("統一編號（8 碼）", text: $taxID).keyboardType(.numberPad) }
                    if invType == "手機載具" { TextField("載具條碼（/ 開頭 7 碼）", text: $carrier).textInputAutocapitalization(.characters) }
                    if invType == "捐贈愛心碼" { TextField("愛心碼（3–7 碼）", text: $donate).keyboardType(.numberPad) }
                }
                Section("訂單備註") {
                    ForEach(["少冰", "不要吸管", "需要餐具", "晚點取餐"], id: \.self) { t in
                        Button {
                            if tags.contains(t) { tags.remove(t) } else { tags.insert(t) }
                        } label: {
                            HStack {
                                Text(t); Spacer()
                                if tags.contains(t) { Image(systemName: "checkmark").foregroundColor(.caramel) }
                            }
                        }.foregroundColor(.espresso)
                    }
                    TextField("自訂備註（最多 50 字）", text: $note)
                        .onChange(of: note) { _, v in if v.count > 50 { note = String(v.prefix(50)) } }
                }
                Section("訂單確認") {
                    LabeledContent("用餐方式", value: m.dining == "內用" ? "內用・桌號 \(m.table)" : "外帶")
                    LabeledContent("取餐時間", value: pickupText)
                    ForEach(m.cart) { it in
                        VStack(alignment: .leading, spacing: 2) {
                            HStack { Text("\(it.product.name) × \(it.qty)"); Spacer(); Text(nt(it.subtotal)) }
                            if !it.summary.isEmpty { Text(it.summary).font(.caption).foregroundColor(.subText) }
                        }
                    }
                    LabeledContent("商品小計", value: nt(m.subtotal))
                    if m.discount > 0 { LabeledContent("優惠折扣", value: "-" + nt(m.discount)) }
                    LabeledContent("總計", value: nt(m.total)).fontWeight(.bold)
                    LabeledContent("付款", value: method)
                    LabeledContent("發票", value: invType)
                    if !tags.isEmpty || !note.isEmpty {
                        LabeledContent("備註", value: (tags.sorted() + (note.isEmpty ? [] : [note])).joined(separator: "、"))
                    }
                }
                Section {
                    if !errors.isEmpty {
                        Text(errors.joined(separator: "\n")).font(.footnote)
                            .listRowBackground(Color.roseBeige)
                    }
                    Button("確認並建立訂單") { submit() }
                }
            }
            .scrollContentBackground(.hidden)
            .background(Color.cream)
            .navigationTitle("結帳")
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    func validate() -> [String] {
        var e: [String] = []
        if m.subtotal < m.minSpend { e.append("未達低消 \(nt(m.minSpend))") }
        if !asap && when < Date().addingTimeInterval(Double(prepMin) * 60) {
            e.append("預約時間過早，請至少預留 \(prepMin) 分鐘備餐")
        }
        if name.trimmingCharacters(in: .whitespaces).isEmpty { e.append("請填寫姓名") }
        if phone.range(of: "^09\\d{8}$", options: .regularExpression) == nil { e.append("手機需為 09 開頭共 10 碼") }
        if method == "匯款" && last5.range(of: "^\\d{5}$", options: .regularExpression) == nil {
            e.append("請輸入匯款帳號末五碼（5 位數字）")
        }
        switch invType {
        case "公司統編":
            if taxID.range(of: "^\\d{8}$", options: .regularExpression) == nil { e.append("統一編號需為 8 碼數字") }
        case "手機載具":
            if carrier.range(of: "^/[0-9A-Z.+-]{7}$", options: .regularExpression) == nil { e.append("載具條碼格式需為 / 開頭共 8 碼") }
        case "捐贈愛心碼":
            if donate.range(of: "^\\d{3,7}$", options: .regularExpression) == nil { e.append("愛心碼需為 3–7 碼數字") }
        default: break
        }
        return e
    }

    func submit() {
        errors = validate()
        if errors.isEmpty { done = m.placeOrder(pickup: pickupText, method: method, payFails: payFails) }
    }
}

struct SuccessView: View {
    @EnvironmentObject var m: AppModel
    let order: Order
    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                Image(systemName: order.pay == .failed ? "exclamationmark.circle.fill" : "checkmark.circle.fill")
                    .font(.system(size: 60)).foregroundColor(order.pay == .failed ? .caramel : .espresso)
                Text(order.pay == .failed ? "付款失敗" : "訂單已建立").font(.title2.weight(.semibold))
                Text(order.number).font(.system(.title3, design: .monospaced))
                HStack { Badge(text: order.status.rawValue); Badge(text: order.pay.rawValue) }
                if order.pay == .failed {
                    Text("訂單已保留，可在訂單頁查看。")
                        .font(.footnote).multilineTextAlignment(.center)
                        .padding(10).frame(maxWidth: .infinity).background(Color.roseBeige)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                }
                VStack(spacing: 6) {
                    ForEach(order.items) { it in
                        HStack { Text("\(it.product.name) × \(it.qty)"); Spacer(); Text(nt(it.subtotal)) }
                    }
                    Divider()
                    HStack { Text("總計").bold(); Spacer(); Text(nt(order.total)).bold() }
                }.card()
                Button("查看訂單") { m.showCart = false; m.tab = 2 }.buttonStyle(CafeButton())
                Button("繼續點餐") { m.showCart = false; m.isOrdering = true; m.tab = 1 }
                    .foregroundColor(.espresso).padding(.top, 4)
            }
            .foregroundColor(.espresso).padding(20)
        }
        .background(Color.cream)
        .navigationBarBackButtonHidden(true)
    }
}

// MARK: - 訂單
struct OrdersView: View {
    @EnvironmentObject var m: AppModel
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 12) {
                    if m.orders.isEmpty {
                        EmptyState(icon: "list.bullet.rectangle", title: "還沒有訂單", hint: "完成第一筆訂單後會出現在這裡")
                    }
                    ForEach(m.orders.prefix(15)) { o in
                        NavigationLink { OrderDetailView(order: o) } label: {
                            VStack(alignment: .leading, spacing: 8) {
                                HStack {
                                    Text(o.number).font(.headline); Spacer()
                                    Text(nt(o.total)).font(.headline).foregroundColor(.caramel)
                                }
                                Text(o.date.formatted(date: .abbreviated, time: .shortened))
                                    .font(.caption).foregroundColor(.subText)
                                Text(o.items.map { "\($0.product.name)×\($0.qty)" }.joined(separator: "、"))
                                    .font(.subheadline).lineLimit(2)
                                HStack { Badge(text: o.status.rawValue, color: statusColor(o.status))
                                         Badge(text: o.pay.rawValue, color: payColor(o.pay)) }
                            }
                            .foregroundColor(.espresso).card()
                        }
                    }
                }.padding(20)
            }
            .background(Color.cream)
            .navigationTitle("訂單")
        }
    }
}

func statusColor(_ s: OrderStatus) -> Color { s == .completed ? .sage : (s == .cancelled ? .roseBeige : .latte) }
func payColor(_ s: PayStatus) -> Color { s == .paid ? .sage : (s == .failed ? .roseBeige : .latte) }

struct OrderDetailView: View {
    @EnvironmentObject var m: AppModel
    let order: Order
    @State private var result: String?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                VStack(alignment: .leading, spacing: 10) {
                    HStack { Text("訂單狀態"); Spacer(); Badge(text: order.status.rawValue, color: statusColor(order.status)) }
                    HStack { Text("付款狀態"); Spacer(); Badge(text: order.pay.rawValue, color: payColor(order.pay)) }
                    HStack { Text("付款方式"); Spacer(); Text(order.method).foregroundColor(.subText) }
                    HStack { Text("取餐"); Spacer(); Text(order.pickup).foregroundColor(.subText) }
                }.card()
                VStack(alignment: .leading, spacing: 10) {
                    ForEach(order.items) { it in
                        VStack(alignment: .leading, spacing: 2) {
                            HStack { Text("\(it.product.name) × \(it.qty)").font(.headline); Spacer(); Text(nt(it.subtotal)) }
                            if !it.summary.isEmpty { Text(it.summary).font(.footnote).foregroundColor(.subText) }
                        }
                    }
                    Divider()
                    HStack { Text("小計"); Spacer(); Text(nt(order.subtotal)) }
                    if order.discount > 0 { HStack { Text("折扣"); Spacer(); Text("-" + nt(order.discount)) } }
                    HStack { Text("總計").bold(); Spacer(); Text(nt(order.total)).bold() }
                }.card()
                Button("再次購買") { m.isOrdering = true; result = m.reorder(order) }.buttonStyle(CafeButton())
            }
            .foregroundColor(.espresso).padding(20)
        }
        .background(Color.cream)
        .navigationTitle(order.number)
        .navigationBarTitleDisplayMode(.inline)
        .alert("再次購買", isPresented: Binding(get: { result != nil }, set: { if !$0 { result = nil } })) {
            Button("查看購物車") { m.showCart = true }
            Button("好", role: .cancel) {}
        } message: { Text(result ?? "") }
    }
}

// MARK: - 我的
struct ProfileView: View {
    @AppStorage("pName") private var name = ""
    @AppStorage("pPhone") private var phone = ""
    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("姓名", text: $name)
                    TextField("手機", text: $phone).keyboardType(.phonePad)
                } header: { Text("常用訂購人") } footer: { Text("僅儲存在這支裝置，不會跨裝置同步。") }
                Section("關於") {
                    LabeledContent("品牌", value: "Café Life（暫定）")
                }
            }
            .scrollContentBackground(.hidden)
            .background(Color.cream)
            .navigationTitle("我的")
        }
    }
}

#Preview { ContentView() }
