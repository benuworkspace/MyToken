# Desain Token
--------------

## Nama Token
Apa nama lengkap token? → "My Example Token"
Apa symbol/ticker?      → "MET"
Kenapa nama ini?        → Deskriptif, mudah diingat

## Supply
Berapa total supply awal?     → 1,000,000 token
Apakah supply bisa bertambah? → Ya, owner bisa mint
Apakah ada max supply?        → Tidak (untuk contoh ini)
Siapa yang dapat supply awal? → Deployer (msg.sender)

## Decimals
Berapa decimals?   → 18 (standard Ethereum)
Kenapa 18?         → Konsisten dengan ETH, kompatibel semua DEX
Kapan pakai < 18?  → Token yang merepresentasikan nilai fiat
                     (USDC pakai 6, mirip cent)

## Bagaimana 1,000,000 token direpresentasikan di contract:
1 token = 1 * 10^18 = 1_000_000_000_000_000_000

Jadi 1,000,000 token = 1_000_000 * 10^18
                     = 1_000_000 * 1e18
                     = 1e24