#Paper published in proceedings of [12th International Symposium on Applied Computing for Software and Smart Systems (ACSS-2025)](https://link.springer.com/chapter/10.1007/978-3-032-18985-1_1)
# 🔐 SecureDeFiLendingOptimized

A **Game-Theoretic Smart Contract for Decentralized Lending** on Ethereum, integrating dynamic reputation systems, collateral-backed loans, and trust-based incentives. Built with Solidity and deployed on the Ethereum testnet, this smart contract is the implementation of the research paper:

🎓 *“Game-Theory Approach using Blockchain to Enhance Trust in Decentralized Finance Systems”*  
By: **Krrish Dubey** and **Priyanka Mukherjee**

---

## 📜 Overview

This contract implements a **reputation-based lending protocol** in DeFi using game-theoretic principles. It aims to build **trust without intermediaries** by aligning lender and borrower incentives through:

- **Dynamic Credit Score (0–10)**
- **Collateral Requirement (20%)**
- **Late Payment Penalties & Grace Period**
- **Reputation Rewards for Timely Repayment**
- **Interest Rate Curve Based on Reputation**
- **Gas-optimized & Secure (Reentrancy Protected)**

---

## ⚙️ Smart Contract Features

| Feature                             | Description                                                                 |
|-------------------------------------|-----------------------------------------------------------------------------|
| 🎓 Reputation-Based Lending         | Credit score determines interest rate and access                            |
| 💰 20% Collateral Enforcement       | Prevents abuse and ensures skin in the game                                 |
| ⏱️ Grace Period & Late Fees        | 6-day extension with 0.5% penalty/day                                       |
| 🎯 Reputation Incentives            | +1 on-time, -1 late, -2 on default                                          |
| 🔐 Reentrancy & Access Protection   | Uses OpenZeppelin’s `ReentrancyGuard` and `Ownable`                         |
| 🧮 Interest Rate Curve              | Fully configurable and future-ready (IPFS/oracle support)                   |
| 📉 Cooldown on Loan Reattempts      | Prevents spam borrowing by enforcing cooldowns after repayment/default      |
| 🛠️ Gas Optimized                   | Reduces redundant reads and logic duplications                              |

---

## 📊 Flowchart Alignment

This contract is fully aligned with the below lifecycle:

```
1. Borrower creates a loan demand
2. Submits 20% collateral
3. Smart contract validates reputation
4. Calculates interest based on score
5. Sends principal to borrower
6. Borrower repays with interest
7. Reward: +1% collateral + rep boost if on time
8. Late: penalized 0.5% per day, reputation -1
9. No repayment after 6 days: default
```

🔄 Borrowers can reapply after the cooldown period.

---

## 🚀 How to Deploy (Remix IDE)

1. Go to [Remix IDE](https://remix.ethereum.org)
2. Paste the code from `SecureDeFiLendingOptimized.sol`
3. Compile with Solidity version `^0.8.20`
4. Deploy to **Ethereum Sepolia Testnet**
5. Use injected provider (MetaMask) to fund and test

---

## 🧪 Functions

### 🟢 `requestLoan(uint durationInDays)`
Borrower deposits 20% collateral and receives a loan with interest calculated based on reputation.

### 🟢 `repayLoan()`
Borrower repays loan; if on time, gets reward and full collateral back.

### 🔴 `markAsDefaulted(uint loanId)`
Callable by contract owner if borrower fails to repay after 6-day grace. Borrower penalized.

### 🟢 `setInterestRateCurve(uint rep, uint rate)`
Owner can configure dynamic interest rates for each rep level.

### 🟢 `lenderWithdraw()`
Lender (owner) can withdraw collected ETH (interest and defaulted collateral).

---

## 📦 Interest Rate Curve (Default)

| Reputation | Interest Rate (%) |
|------------|--------------------|
| 0          | 32.3               |
| 1          | 28.9               |
| 2          | 23.4               |
| 3          | 18.7               |
| 4          | 13.2               |
| 5          | 11.4               |
| 6          | 9.1                |
| 7          | 8.7                |
| 8          | 7.2                |
| 9          | 6.9                |
| 10         | 6.0                |

---

## 📂 Repository Structure

```
📁 /SecureDeFiLendingOptimized
├── 📄 README.md
├── 📄 Response to reviews.pdf
├── 📄 SecureDeFiLendingOptimized.sol
└── 📊 flowchart.png
```

---

## 👩‍🔬 Authors

- **Krrish Dubey** — [`@theskepticgeek`](https://github.com/theskepticgeek)
- **Priyanka Mukherjee** — [`@CodeWithPriyankaMukherjee`](https://github.com/CodeWithPriyankaMukherjee)

Affiliated with: *[JIS College of Engineering]*  
This project was created as part of our research contribution to the field of **Game Theory in Blockchain-Based Finance**.

---

## 📜 License

This project is licensed under the [MIT License](./LICENSE).

---

## ⭐ Acknowledgements

Special thanks to the reviewers who helped improve the robustness and real-world applicability of this protocol.

---

## 📬 Contact

For collaboration, queries, or academic discussions, feel free to reach out via GitHub or email.
