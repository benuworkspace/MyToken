# Hari 4 — MyToken ERC20

Standard ERC20 token dengan mint, burn, dan pause functionality.
Dibangun menggunakan OpenZeppelin contracts.

## Contract

| Network | Address | Etherscan |
|---------|---------|-----------|
| Sepolia | `0x8054091C2248b938782ff3eC4772065ab90B6314` | [View](https://sepolia.etherscan.io/address/0x8054091C2248b938782ff3eC4772065ab90B6314) |

## Features

- ✅ Standard ERC20 (transfer, approve, transferFrom, allowance)
- ✅ Mintable — owner dapat mencetak token baru
- ✅ Burnable — siapapun dapat membakar token milik sendiri
- ✅ Pausable — owner dapat menghentikan semua transfer
- ✅ Max Supply — hard cap 100 juta token
- ✅ Verified — source code publik di Etherscan

## Token Info

| Property | Value |
|----------|-------|
| Name | My Example Token |
| Symbol | MET |
| Decimals | 18 |
| Initial Supply | 1,000,000 MET |
| Max Supply | 100,000,000 MET |
| Network | Sepolia Testnet |

## Test Coverage

52 tests — semua passing.

## Deploy

```bash
cp .env.example .env
# Isi PRIVATE_KEY, SEPOLIA_RPC_URL, ETHERSCAN_API_KEY

forge script script/DeployMyToken.s.sol \
    --rpc-url $SEPOLIA_RPC_URL \
    --private-key $PRIVATE_KEY \
    --broadcast
```

## Security Considerations

- Owner memiliki hak mint dan pause — gunakan multisig untuk production deployment
- `burnFrom` memungkinkan owner membakar token siapapun — pertimbangkan untuk remove jika tidak dibutuhkan
- Infinite approval membawa risiko jika contract di-exploit — informasikan user untuk hanya approve jumlah yang dibutuhkan