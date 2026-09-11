import Foundation

enum ApplePayCategorizer {

    /// Keywords grouped by default category. Launch markets are the US, Canada,
    /// and Brazil. Matching uses longest keyword first so "uber eats" wins over
    /// "uber" and "taco bell" wins over "bell canada".
    private static let categoryKeywordRules: [String: [String]] = [
        "Entertainment": [
            "netflix", "spotify", "disney+", "disney plus", "disney",
            "hbo max", "hbo", "prime video", "primevideo",
            "apple tv+", "apple tv", "apple music",
            "youtube music", "youtube premium", "youtube",
            "hulu", "peacock", "espn+", "crave", "siriusxm", "pandora",
            "paramount", "crunchyroll", "funimation", "star+", "telecine",
            "deezer", "tidal", "audible", "kindle", "globoplay", "globo play",
            "cinemark", "cineplex", "amc theatres", "amc plus", "regal",
            "kinoplex", "cinesystem", "uci cinemas", "cinema",
            "ingresso.com", "ingressos", "ingresso",
            "ticketmaster", "fandango", "livenation", "live nation",
            "sympla", "eventim"
        ],
        "Productivity": [
            "squarespace", "sqsp", "chatgpt", "openai", "anthropic",
            "github", "gitlab", "figma", "adobe", "notion", "canva",
            "google workspace", "google storage", "google one", "google cloud",
            "icloud", "apple.com/bill", "app store", "apple developer",
            "microsoft 365", "office 365", "microsoft", "quickbooks",
            "slack", "zoom", "linkedin", "jetbrains", "cursor", "setapp",
            "amazon web services", "digitalocean", "digital ocean",
            "aws", "vercel", "netlify", "heroku", "cloudflare", "supabase",
            "godaddy", "namecheap", "hostgator", "registro.br", "wordpress", "wix",
            "grammarly", "dropbox", "1password", "lastpass", "bitwarden",
            "nordvpn", "expressvpn", "surfshark", "copilot", "midjourney", "replit"
        ],
        "Lifestyle": [
            "starbucks", "tim hortons", "dunkin",
            "uber eats", "ubereats", "doordash", "door dash",
            "grubhub", "postmates", "skip the dishes", "skipthedishes",
            "ifood", "ifd", "rappi", "99food", "99 food", "instacart",
            "mcdonald", "burger king", "chipotle", "chick-fil-a", "chickfila",
            "chick fil a", "taco bell", "wendys", "wendy's", "panera",
            "five guys", "shake shack", "sweetgreen", "in-n-out", "in n out",
            "outback", "popeyes", "kfc", "pizza hut", "dominos", "domino's",
            "habibs", "habib", "spoleto", "subway", "coco bambu",
            "bacio di latte", "madero", "madeiro", "giraffas", "bobs", "bob's",
            "padaria", "bakery", "restaurante", "cafeteria", "lanchonete",
            "chopp", "sorveteria", "acai",
            "whole foods", "wholefds", "trader joe", "costco", "kroger",
            "safeway", "publix", "albertsons", "h-e-b", "wegmans",
            "loblaws", "no frills", "sobeys", "freshco",
            "supermercado", "carrefour", "pao de acucar", "assai", "atacadao",
            "walmart", "target", "oxxo", "ampm", "am pm", "7-eleven", "7 eleven",
            "circle k", "wawa",
            "mercado livre", "mercadolivre", "shopee", "shein", "aliexpress",
            "amazon", "amzn", "ebay", "etsy",
            "best buy", "home depot", "lowes", "lowe's",
            "zara", "nike", "old navy", "nordstrom", "macys", "macy's",
            "tj maxx", "t.j. maxx", "marshalls", "ulta",
            "centauro", "netshoes", "dafiti",
            "magazine luiza", "magalu", "americanas", "casas bahia", "ponto frio",
            "renner", "riachuelo", "natura", "boticario", "sephora",
            "petz", "cobasi", "petlove",
            "shopping", "ikea", "leroy merlin"
        ],
        "Utilities": [
            "uber trip", "uber one", "uber", "lyft",
            "99 pop", "indrive", "in drive", "cabify", "taxi", "99",
            "shell", "chevron", "exxon", "petro-canada", "ipiranga",
            "petrobras", "raizen", "autoposto", "gasolina", "combustivel",
            "estacionamento", "parking", "zona azul",
            "parkwhiz", "spothero", "parkmobile", "ezpass", "e-zpass", "fastrak",
            "verizon", "at&t", "att wireless", "att mobility", "t-mobile",
            "tmobile", "t mobile", "xfinity", "comcast", "spectrum",
            "rogers", "bell canada", "bell mobility", "bell internet",
            "telus", "fido", "koodo",
            "vivo", "claro", "tim brasil", "tim celular", "starlink", "algar",
            "enel", "sabesp", "cpfl", "cemig", "copel", "light energia",
            "hydro one", "bc hydro", "hydro quebec", "enbridge",
            "pg&e", "con edison",
            "concessionaria", "pedagio", "sem parar", "veloe", "conectcar",
            "move mais", "detran", "presto"
        ],
        "Finance": [
            "bank of america", "wells fargo", "capital one",
            "american express", "amex", "chase",
            "td bank", "td canada", "scotiabank", "scotia bank",
            "cibc", "wealthsimple", "tangerine", "rbc",
            "nubank", "itau", "bradesco", "santander", "banco inter",
            "banco do brasil", "c6 bank", "c6bank",
            "venmo", "cash app", "paypal", "picpay", "mercado pago", "pagbank",
            "cora", "pagseguro", "stone", "sumup", "safra", "btg",
            "xp investimentos", "robinhood", "fidelity", "vanguard", "schwab",
            "binance", "coinbase", "mercado bitcoin",
            "geico", "state farm", "progressive", "allstate",
            "seguro", "insurance", "anuidade", "iof", "investimento",
            "turbotax", "wise", "stripe"
        ],
        "Health": [
            "cvs", "walgreens", "rite aid", "shoppers drug mart", "rexall",
            "farmacia", "drogasil", "droga raia", "drogaria", "pharmacy",
            "panvel", "pague menos", "extrafarma", "ultrafarma", "drofarma",
            "planet fitness", "la fitness", "anytime fitness", "orangetheory",
            "equinox", "goodlife",
            "smartfit", "smart fit", "bioritmo", "bio ritmo",
            "bodytech", "selfit", "bluefit", "gympass", "totalpass", "wellhub",
            "academia", "gym",
            "labcorp", "quest diagnostics", "kaiser",
            "fleury", "delboni", "lavoisier", "dasa",
            "dr consulta", "hospital", "consulta", "medico",
            "dentista", "dentist", "odonto", "psicolog", "manipulacao", "unimed"
        ],
        "Gaming": [
            "nintendo", "playstation", "psn", "xbox", "game pass",
            "steam", "epic games", "riot games", "roblox", "twitch",
            "gog.com", "blizzard", "ubisoft", "ea games", "ea app", "valve",
            "gamestop", "nuuvem", "minecraft", "fortnite"
        ]
    ]

    private static let rankedRules: [(keyword: String, category: String)] = {
        categoryKeywordRules.flatMap { category, keywords in
            keywords.map { (normalized($0), category) }
        }
        .sorted { $0.keyword.count > $1.keyword.count }
    }()

    /// Categorizes a merchant name string against user's custom categories or standard defaults.
    static func categorize(merchant: String, availableCategories: [String]) -> String {
        let haystack = normalized(merchant)

        for (keyword, targetCategory) in rankedRules where haystack.contains(keyword) {
            if let match = resolve(targetCategory, in: availableCategories) {
                return match
            }
        }

        if let directCategory = availableCategories.first(where: {
            let name = normalized($0)
            return !name.isEmpty && haystack.contains(name)
        }) {
            return directCategory
        }

        return availableCategories.first(where: { $0.caseInsensitiveCompare("Other") == .orderedSame })
            ?? availableCategories.first
            ?? "Other"
    }

    /// Apple Pay descriptors use asterisks, extra spaces, and mixed accents.
    private static func normalized(_ string: String) -> String {
        string
            .folding(options: [.diacriticInsensitive, .caseInsensitive], locale: Locale(identifier: "en"))
            .replacingOccurrences(of: "*", with: " ")
            .replacingOccurrences(of: "\\s+", with: " ", options: .regularExpression)
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private static func resolve(_ target: String, in available: [String]) -> String? {
        if let exact = available.first(where: { $0.caseInsensitiveCompare(target) == .orderedSame }) {
            return exact
        }
        let needle = target.lowercased()
        return available.first {
            let name = $0.lowercased()
            return name.contains(needle) || needle.contains(name)
        }
    }
}
