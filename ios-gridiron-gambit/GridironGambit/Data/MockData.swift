import SwiftUI

/// All Phase 1 content is local mock data — no backend, no persistence layer.
nonisolated enum MockData {

    // MARK: - Stadiums

    static let stadiums: [Stadium] = [
        Stadium(
            id: 1,
            name: "Stadium 1",
            tagline: "Training Grounds",
            firstLevel: 1,
            lastLevel: 15,
            isUnlocked: true,
            leftBanner: "Discipline\nBuilds\nChampions",
            rightBanner: "Small\nPlays\nBig Wins"
        ),
        Stadium(
            id: 2,
            name: "Stadium 2",
            tagline: "Friday Night Field",
            firstLevel: 16,
            lastLevel: 30,
            isUnlocked: false,
            leftBanner: "Lights\nOn\nFocus Up",
            rightBanner: "Own\nThe\nMoment"
        ),
        Stadium(
            id: 3,
            name: "Stadium 3",
            tagline: "City Stadium",
            firstLevel: 31,
            lastLevel: 45,
            isUnlocked: false,
            leftBanner: "Read\nReact\nRepeat",
            rightBanner: "Trust\nThe\nCall"
        ),
        Stadium(
            id: 4,
            name: "Stadium 4",
            tagline: "Metro Dome",
            firstLevel: 46,
            lastLevel: 60,
            isUnlocked: false,
            leftBanner: "Noise\nMeans\nNothing",
            rightBanner: "Win\nThe\nDown"
        ),
        Stadium(
            id: 5,
            name: "Stadium 5",
            tagline: "Championship Stadium",
            firstLevel: 61,
            lastLevel: 75,
            isUnlocked: false,
            leftBanner: "Earn\nEvery\nSnap",
            rightBanner: "Finish\nThe\nDrive"
        )
    ]

    // MARK: - Levels

    /// Titles cycle so every level reads like a real defensive call sheet.
    private static let levelTitles: [String] = [
        "First Read", "Split Coverage", "Stack the Box", "Mirror Motion",
        "Deny the Flat", "Bracket the Slot", "Force the Checkdown", "Cloud Left",
        "Robber Look", "Cut the Crossers", "Disguise the Blitz", "Trap the Boundary",
        "Cap the Post", "Squeeze the Seam"
    ]

    static func levels(for stadium: Stadium, progress: PlayerProgress, starRecords: [Int: Int] = [:]) -> [Level] {
        (stadium.firstLevel...stadium.lastLevel).map { number in
            let indexInStadium = number - stadium.firstLevel
            let isGameDay = number == stadium.lastLevel
            let isCompleted = number < progress.currentLevelNumber
            let isCurrent = number == progress.currentLevelNumber

            let difficulty: LevelDifficulty
            if isGameDay {
                difficulty = .championship
            } else if indexInStadium < 3 {
                difficulty = .walkthrough
            } else if indexInStadium < 9 {
                difficulty = .standard
            } else {
                difficulty = .pressure
            }

            // Stars come from the player's best clears, stored on device.
            let stars = LevelStars(rawValue: starRecords[number] ?? 0) ?? .none

            return Level(
                levelNumber: number,
                stadiumId: stadium.id,
                title: isGameDay ? "Game Day" : levelTitles[indexInStadium % levelTitles.count],
                difficulty: difficulty,
                starsEarned: stars,
                isUnlocked: stadium.isUnlocked && (isCompleted || isCurrent),
                isCompleted: isCompleted,
                isGameDay: isGameDay,
                reward: LevelReward(
                    gameBalls: isGameDay ? 250 : 25 + indexInStadium * 5,
                    xp: isGameDay ? 200 : 40
                )
            )
        }
    }

    /// Bonus stops placed every five levels inside a stadium.
    static func rewardStops(for stadium: Stadium) -> [RewardStop] {
        [5, 10].map { offset in
            let level = stadium.firstLevel + offset - 1
            return RewardStop(
                id: stadium.id * 100 + offset,
                afterLevel: level,
                gameBalls: offset == 5 ? 100 : 200,
                isClaimed: false
            )
        }
    }

    // MARK: - Locker

    static let cosmetics: [CosmeticItem] = [
        // Helmets
        CosmeticItem(
            id: "helmet-midnight",
            name: "Midnight Star",
            category: .helmet,
            preview: .helmet(shell: Color(hex: 0x141B2A), facemask: Color(hex: 0xD9E2EF), stripe: Color(hex: 0xF2F6FB)),
            price: 0, isOwned: true, isEquipped: true
        ),
        CosmeticItem(
            id: "helmet-navy",
            name: "Classic Navy",
            category: .helmet,
            preview: .helmet(shell: Color(hex: 0x1B2C44), facemask: Color(hex: 0x8FA3BF), stripe: Color(hex: 0x3E7BFA)),
            price: 0, isOwned: true, isEquipped: false
        ),
        CosmeticItem(
            id: "helmet-silver",
            name: "Silver Rush",
            category: .helmet,
            preview: .helmet(shell: Color(hex: 0xC9D3E0), facemask: Color(hex: 0x1B2C44), stripe: Color(hex: 0xE0263A)),
            price: 150, isOwned: false, isEquipped: false
        ),
        CosmeticItem(
            id: "helmet-blackout",
            name: "Blackout",
            category: .helmet,
            preview: .helmet(shell: Color(hex: 0x0B0E14), facemask: Color(hex: 0xE0263A), stripe: Color(hex: 0x33445E)),
            price: 150, isOwned: false, isEquipped: false
        ),
        CosmeticItem(
            id: "helmet-crimson",
            name: "Crimson Strike",
            category: .helmet,
            preview: .helmet(shell: Color(hex: 0x9E1B2C), facemask: Color(hex: 0xF2F6FB), stripe: Color(hex: 0xFFC53D)),
            price: 150, isOwned: false, isEquipped: false
        ),
        CosmeticItem(
            id: "helmet-forest",
            name: "Forest Guard",
            category: .helmet,
            preview: .helmet(shell: Color(hex: 0x14442C), facemask: Color(hex: 0xC9D3E0), stripe: Color(hex: 0x2FA05C)),
            price: 300, isOwned: false, isEquipped: false
        ),
        CosmeticItem(
            id: "helmet-violet",
            name: "Violet Reign",
            category: .helmet,
            preview: .helmet(shell: Color(hex: 0x41307E), facemask: Color(hex: 0xD9E2EF), stripe: Color(hex: 0xFFC53D)),
            price: 300, isOwned: false, isEquipped: false
        ),
        CosmeticItem(
            id: "helmet-gold",
            name: "Gold Standard",
            category: .helmet,
            preview: .helmet(shell: Color(hex: 0xB88A2B), facemask: Color(hex: 0x141B2A), stripe: Color(hex: 0xF2F6FB)),
            price: 300, isOwned: false, isEquipped: false
        ),
        CosmeticItem(
            id: "helmet-storm",
            name: "Storm Grey",
            category: .helmet,
            preview: .helmet(shell: Color(hex: 0x6C7B8F), facemask: Color(hex: 0x0B0E14), stripe: Color(hex: 0xD9E2EF)),
            price: 0, isOwned: true, isEquipped: false
        ),

        // Uniforms
        CosmeticItem(
            id: "uniform-home",
            name: "Home Steel",
            category: .uniform,
            preview: .uniform(jersey: Color(hex: 0x1B2C44), trim: Color(hex: 0xF2F6FB)),
            price: 0, isOwned: true, isEquipped: true
        ),
        CosmeticItem(
            id: "uniform-away",
            name: "Away White",
            category: .uniform,
            preview: .uniform(jersey: Color(hex: 0xE7EDF5), trim: Color(hex: 0x1B2C44)),
            price: 0, isOwned: true, isEquipped: false
        ),
        CosmeticItem(
            id: "uniform-red",
            name: "Red Zone",
            category: .uniform,
            preview: .uniform(jersey: Color(hex: 0xB4222F), trim: Color(hex: 0xFFC53D)),
            price: 200, isOwned: false, isEquipped: false
        ),
        CosmeticItem(
            id: "uniform-throwback",
            name: "Throwback Tan",
            category: .uniform,
            preview: .uniform(jersey: Color(hex: 0xA6875A), trim: Color(hex: 0x2C2318)),
            price: 250, isOwned: false, isEquipped: false
        ),
        CosmeticItem(
            id: "uniform-blackout",
            name: "Blackout Alt",
            category: .uniform,
            preview: .uniform(jersey: Color(hex: 0x11141B), trim: Color(hex: 0xE0263A)),
            price: 350, isOwned: false, isEquipped: false
        ),
        CosmeticItem(
            id: "uniform-ice",
            name: "Ice Blue",
            category: .uniform,
            preview: .uniform(jersey: Color(hex: 0x2E5E9E), trim: Color(hex: 0xC9E4FF)),
            price: 350, isOwned: false, isEquipped: false
        ),

        // Fields
        CosmeticItem(
            id: "field-classic",
            name: "Classic Turf",
            category: .field,
            preview: .turf(primary: Color(hex: 0x1E7A46), secondary: Color(hex: 0x176138)),
            price: 0, isOwned: true, isEquipped: true
        ),
        CosmeticItem(
            id: "field-night",
            name: "Night Grass",
            category: .field,
            preview: .turf(primary: Color(hex: 0x134A2C), secondary: Color(hex: 0x0D3320)),
            price: 0, isOwned: true, isEquipped: false
        ),
        CosmeticItem(
            id: "field-frozen",
            name: "Frozen Tundra",
            category: .field,
            preview: .turf(primary: Color(hex: 0xBFD4DE), secondary: Color(hex: 0x92AEBD)),
            price: 300, isOwned: false, isEquipped: false
        ),
        CosmeticItem(
            id: "field-mud",
            name: "Mud Bowl",
            category: .field,
            preview: .turf(primary: Color(hex: 0x5A4A2E), secondary: Color(hex: 0x3E3220)),
            price: 300, isOwned: false, isEquipped: false
        ),
        CosmeticItem(
            id: "field-neon",
            name: "Neon Deck",
            category: .field,
            preview: .turf(primary: Color(hex: 0x1B2C44), secondary: Color(hex: 0x3E7BFA)),
            price: 500, isOwned: false, isEquipped: false
        ),
        CosmeticItem(
            id: "field-desert",
            name: "Desert Clay",
            category: .field,
            preview: .turf(primary: Color(hex: 0xA85C36), secondary: Color(hex: 0x7C4126)),
            price: 500, isOwned: false, isEquipped: false
        ),

        // Stadiums
        CosmeticItem(
            id: "stadium-training",
            name: "Practice Lights",
            category: .stadium,
            preview: .stadiumLights(tint: Color(hex: 0xF4E9C8)),
            price: 0, isOwned: true, isEquipped: true
        ),
        CosmeticItem(
            id: "stadium-friday",
            name: "Friday Glow",
            category: .stadium,
            preview: .stadiumLights(tint: Color(hex: 0xFFC53D)),
            price: 250, isOwned: false, isEquipped: false
        ),
        CosmeticItem(
            id: "stadium-dome",
            name: "Dome Beams",
            category: .stadium,
            preview: .stadiumLights(tint: Color(hex: 0x8FD0FF)),
            price: 400, isOwned: false, isEquipped: false
        ),
        CosmeticItem(
            id: "stadium-title",
            name: "Title Night",
            category: .stadium,
            preview: .stadiumLights(tint: Color(hex: 0xFF6B7A)),
            price: 600, isOwned: false, isEquipped: false
        ),

        // Markers
        CosmeticItem(
            id: "marker-shield",
            name: "Shield",
            category: .markers,
            preview: .marker(symbol: "shield.fill", tint: Palette.accent),
            price: 0, isOwned: true, isEquipped: true
        ),
        CosmeticItem(
            id: "marker-chevron",
            name: "Chevron",
            category: .markers,
            preview: .marker(symbol: "chevron.up.circle.fill", tint: Palette.blue),
            price: 0, isOwned: true, isEquipped: false
        ),
        CosmeticItem(
            id: "marker-bolt",
            name: "Blitz Bolt",
            category: .markers,
            preview: .marker(symbol: "bolt.fill", tint: Palette.gold),
            price: 150, isOwned: false, isEquipped: false
        ),
        CosmeticItem(
            id: "marker-target",
            name: "Target Lock",
            category: .markers,
            preview: .marker(symbol: "scope", tint: Color(hex: 0x2FA05C)),
            price: 200, isOwned: false, isEquipped: false
        ),
        CosmeticItem(
            id: "marker-flame",
            name: "Heat Check",
            category: .markers,
            preview: .marker(symbol: "flame.fill", tint: Color(hex: 0xFF7A3D)),
            price: 350, isOwned: false, isEquipped: false
        ),
        CosmeticItem(
            id: "marker-star",
            name: "All Pro",
            category: .markers,
            preview: .marker(symbol: "star.fill", tint: Color(hex: 0xFFE27A)),
            price: 450, isOwned: false, isEquipped: false
        ),

        // Celebrations
        CosmeticItem(
            id: "celebration-spike",
            name: "Ball Spike",
            category: .celebration,
            preview: .celebration(symbol: "hand.raised.fill", tint: Palette.accent),
            price: 0, isOwned: true, isEquipped: true
        ),
        CosmeticItem(
            id: "celebration-confetti",
            name: "Confetti Drop",
            category: .celebration,
            preview: .celebration(symbol: "sparkles", tint: Palette.gold),
            price: 200, isOwned: false, isEquipped: false
        ),
        CosmeticItem(
            id: "celebration-horn",
            name: "Stadium Horn",
            category: .celebration,
            preview: .celebration(symbol: "horn.fill", tint: Palette.blue),
            price: 300, isOwned: false, isEquipped: false
        ),
        CosmeticItem(
            id: "celebration-fireworks",
            name: "Fireworks",
            category: .celebration,
            preview: .celebration(symbol: "firework", tint: Color(hex: 0xFF6B7A)),
            price: 500, isOwned: false, isEquipped: false
        )
    ]

    // MARK: - Shop

    static let gameBallPacks: [GameBallPack] = [
        GameBallPack(id: "pack-250", amount: 250, price: "$0.99", bonusLabel: nil, ballCount: 1),
        GameBallPack(id: "pack-1500", amount: 1_500, price: "$4.99", bonusLabel: "Popular", ballCount: 2),
        GameBallPack(id: "pack-3500", amount: 3_500, price: "$9.99", bonusLabel: "+15% Extra", ballCount: 3),
        GameBallPack(id: "pack-6000", amount: 6_000, price: "$14.99", bonusLabel: "Best Value", ballCount: 4)
    ]

    static let shopOffers: [ShopOffer] = [
        ShopOffer(
            id: "offer-starter",
            title: "Starter Bundle",
            subtitle: "Game Balls + Gear",
            price: "$2.99",
            perks: ["500 Game Balls", "Exclusive helmet", "Exclusive field & marker"],
            symbol: "shippingbox.fill",
            highlighted: true
        ),
        ShopOffer(
            id: "offer-playbook",
            title: "Special Playbook Pack",
            subtitle: "New Puzzles",
            price: "$2.99",
            perks: ["25 specialty puzzles", "Exotic coverage concepts", "Bonus star chase"],
            symbol: "list.clipboard.fill",
            highlighted: false
        ),
        ShopOffer(
            id: "offer-noads",
            title: "Remove Ads",
            subtitle: "A smoother game day",
            price: "$4.99",
            perks: ["No interruptions", "Faster level restarts", "One-time unlock"],
            symbol: "nosign",
            highlighted: false
        )
    ]
}
