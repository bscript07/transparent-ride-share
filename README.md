# 🚕 Ride Share Treasury – Upgradeable Smart Contract (Sepolia)

This project implements a secure, upgradeable smart contract for a ride-sharing platform. It allows drivers to claim ETH payments via EIP-712 signed vouchers. The contract is deployed on Sepolia using a Transparent Upgradable Proxy.

---

## ✅ Features

- 🔐 Upgradeable via OpenZeppelin Transparent Proxy
- 🧾 EIP-712 signature verification
- 🧮 ETH/USD price conversion via Chainlink
- 🛡️ Role separation: Owner vs Admin vs Driver
- 🚫 Reentrancy protection

---

## 🔧 Set Up and Run

### 1. Clone the project and install dependencies

```bash
git clone https://github.com/bscript07/ride-share-treasury.git
cd ride-share
forge install
forge test
```

 ### 2. Set environment variables

 ```bash
 OWNER_ADDRESS=<OWNER_ADDRESS>
 OWNER_PRIVATE_KEY=<OWNER_PRIVATE_KEY>

 ADMIN_ADDRESS=<ADMIN_ADDRESS>
 ADMIN_PRIVATE_KEY=<ADMIN_PRIVATE_KEY>

 DRIVER_ONE__ADDRESS=<DRIVER_ONE__ADDRESS>
 DRIVER_TWO__ADDRESS=<DRIVER_TWO__ADDRESS>

 CLONE_ADDRESS=<PROXY_CONTRACT_ADDRESS_AFTER_DEPLOY>

 SEPOLIA_RPC_URL=<SEPOLIA_RPC_URL>
 ETHERSCAN_API_KEY=<ETHERSCAN_API_KEY>
 ```

### 3. Deployment & Verification (Sepolia)

```bash
forge script script/deploy.s.sol:DeployScript --rpc-url sepolia --broadcast --verify -vv --private-key <ADMIN_PRIVATE_KEY>
```

 ### 4. Generate Voucher Signature (Off-chain)

 ```bash
 node scripts/generate-voucher-signature.js
 ```
 
 This script generates a signed voucher using the OWNER_PRIVATE_KEY and writes a JSON object containing:
- driver address
- tripId
- usdCents
- expiry timestamp
- signature
- domain info (incl. verifyingContract = CLONE_ADDRESS)

### 5. Etherscan Links

Proxy: 0xf0722f5c70392F7233f0C37504c25226B3044f78
Implementation: 0x263ece95f545fd910f8bdc91f4726557B7096Ef6

### 6. Example Transactions

Treasury Funded by Owner: [0x71e824214a0453a78e08c5f12dde6408c72dc530d6fcbdbb0ddd700399f3086d](https://sepolia.etherscan.io/tx/0x71e824214a0453a78e08c5f12dde6408c72dc530d6fcbdbb0ddd700399f3086d)

Driver One Voucher Claim: [0xce2bd2736fc493312b9eaf4d0531434929327cd3dcea6ce5bf50419bb458bf53](https://sepolia.etherscan.io/tx/0xce2bd2736fc493312b9eaf4d0531434929327cd3dcea6ce5bf50419bb458bf53)

Driver Two Voucher Claim: [0x1cb84d2e237f816d05bcf10f19edf597dcb957b8c39ab2a2fcb782da0e8c19e1](https://sepolia.etherscan.io/tx/0x1cb84d2e237f816d05bcf10f19edf597dcb957b8c39ab2a2fcb782da0e8c19e1)

Owner Withdraws ETH: [0x30d0f3aa0e66796627ab6d4d6485cd5cb0ddd8bd51fcd5028bd917b7266edfcf](https://sepolia.etherscan.io/tx/0x30d0f3aa0e66796627ab6d4d6485cd5cb0ddd8bd51fcd5028bd917b7266edfcf)