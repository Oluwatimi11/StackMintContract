# SmartMint (SMT)
**Version:** 1.1.0  
**Language:** Clarity (Stacks Blockchain)  
**Standard:** ERC-20-like with enhancements for token locking and supply control  

---

## 📘 Overview

**SmartMint (SMT)** is a fungible token smart contract written in Clarity, designed to emulate the ERC-20 standard while incorporating advanced features such as:

- Token locking with unlock heights  
- Adjustable allowances  
- Minting and burning by the contract owner  
- Max supply enforcement  
- Transfer restrictions for locked tokens  

---

## 🔧 Token Configuration

| Property        | Value                        |
|----------------|------------------------------|
| **Name**       | SmartMint                    |
| **Symbol**     | SMT                          |
| **Decimals**   | 6                            |
| **Initial Supply** | 1,000,000 SMT (`u1000000000000`) |
| **Max Supply** | 10,000,000 SMT (`u10000000000000`) |
| **Admin**      | `tx-sender` at deployment    |

---

## 🛠 Contract Features

### ✅ Token Mechanics
- `transfer(recipient, amount)` — Standard token transfer with lock and balance checks.  
- `transfer-from(sender, recipient, amount)` — Transfer using allowances.  
- `approve(spender, amount)` — Authorize another account to spend tokens.  
- `increase-allowance(spender, amount)` / `decrease-allowance(spender, amount)` — Granular allowance control.  

### 🔐 Token Locking
- Lock tokens by setting an `unlock-height`.  
- Tokens remain unusable until the specified block height is reached.  
- Lock info is stored and queryable by lock ID and account.  

### 🔥 Supply Management
- `mint(recipient, amount)` — Only the admin can mint new tokens.  
- `burn(account, amount)` — Only the admin can burn tokens.  
- Enforces a maximum total supply (`max-supply`).  

---

## 📥 Initialization

Upon deployment, all initial supply is allocated to the contract deployer (`tx-sender`). This event is logged using a print statement for observability.

---

## 🔍 Read-Only Functions

| Function                         | Description                                  |
|----------------------------------|----------------------------------------------|
| `get-name()`                    | Returns `"SmartMint"`                        |
| `get-symbol()`                  | Returns `"SMT"`                              |
| `get-decimals()`                | Returns `u6`                                 |
| `get-total-supply()`           | Returns current total supply                 |
| `get-max-supply()`             | Returns `max-supply`                         |
| `get-balance(account)`         | Returns balance of an account                |
| `get-available-balance(account)` | Returns unlocked tokens only               |
| `get-locked-amount(account)`   | Returns total locked tokens                  |
| `get-lock-info(account, lock-id)` | Returns lock info (amount, unlock height) |
| `get-account-lock-ids(account)` | Returns list of lock IDs for an account    |
| `lock-exists?(account, lock-id)`| Returns true if a specific lock ID exists   |
| `get-allowance(owner, spender)`| Returns approved allowance amount           |

---

## ⚠️ Error Codes

| Code  | Description              |
|-------|--------------------------|
| `u100` | Unauthorized action      |
| `u101` | Balance too low          |
| `u102` | Allowance exceeded       |
| `u103` | Invalid recipient        |
| `u104` | Tokens locked            |
| `u105` | Invalid lock period      |
| `u106` | Zero-amount operation    |
| `u107` | Max supply reached       |
| `u108` | Lock not found           |
| `u109` | Duplicate lock ID        |
| `u110` | Self-transfer attempted  |

---

## 📦 Events

Emitted using the `print` function for key activities:

- `token-initialized`  
- `transfer`  
- `approve`  
- `allowance-increased`  
- `allowance-decreased`  
- `mint`  
- `burn`  

Each event logs relevant metadata (e.g., amounts, sender/recipient, new balances).

---

## 🔒 Security Considerations

- Token transfers check for lock status and available balance.  
- `mint` and `burn` are admin-only.  
- `tx-sender` is used as both executor and owner where applicable.  
- Self-transfers are blocked to prevent redundant state changes.

---

## 📈 Use Cases

- Token distribution with vesting (via time-locked balances)  
- Staking/vesting protocols  
- Controlled supply systems  
- DAO token issuance with governance controls  

---

## 🚀 Deployment

Deploy using Clarinet or directly through the Stacks API with the contract content:

```bash
clarinet deploy
```

**Contract file:** `smartmint-contract.clar`

---

## 🧪 Testing

Ensure you validate the contract against:

- Transfers with and without locks  
- Allowance and `transfer-from` patterns  
- Minting/burning enforcement  
- Lock handling: creation, expiration, queries  

---

## 📜 License

MIT License © Claude

---
