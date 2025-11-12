# CraftBasin

**Decentralized creator patronage platform with tokenized content access and automated royalty distribution**

## Overview

CraftBasin revolutionizes creator monetization through blockchain-based content tokenization, tiered access NFTs, and the innovative "Creator Royalty Cascade" system. Built on Stacks blockchain, the platform eliminates dependency on traditional platforms while providing transparent, sustainable income streams for creators and tradeable access rights for patrons.

## Key Features

### 🎨 Creative Commons Vault
- Encrypted IPFS content storage with smart contract access gates
- Blockchain timestamping for IP protection
- Zero-knowledge proof content verification
- Multi-category support (Music, Art, Writing, Education, Video)

### 💎 Tiered Access NFTs
- **Basic** - Entry-level content access
- **Premium** - Enhanced features and early access
- **Exclusive** - VIP content and perks
- **Lifetime** - Permanent access rights

### 💰 Creator Royalty Cascade
- Automated royalty distribution on NFT resales
- Configurable primary (5-50%) and secondary royalties
- Multi-level cascade tracking
- Transparent revenue streams

### 🤝 Revenue Splitting
- Collaborative content support
- Automated split distribution
- Real-time earnings tracking
- Instant withdrawals

## Smart Contract Functions

### Creator Management
- `register-creator` - Join the platform as a creator
- `create-content-vault` - Tokenize new content with encryption
- `set-content-tier` - Configure access tiers and pricing
- `set-royalty-config` - Customize royalty percentages

### Patron Operations
- `purchase-access-nft` - Buy content access tokens
- `access-content` - Verify and log content access
- `list-nft-for-resale` - List access rights on secondary market
- `purchase-resale-nft` - Buy from secondary market with auto-royalties

### Revenue Management
- `withdraw-revenue` - Claim creator earnings
- `add-revenue-split` - Add collaborators
- `withdraw-collaborator-split` - Claim collaboration earnings

## Use Cases

✅ **Musicians** - Release exclusive albums, demos, and behind-the-scenes content  
✅ **Digital Artists** - Early access to NFT collections and limited editions  
✅ **Writers** - Serialize premium novels, articles, and poetry  
✅ **Educators** - Offer specialized courses and tutorial series  
✅ **Video Creators** - Premium streaming content and unreleased footage

## Getting Started

### Prerequisites
- Clarinet CLI
- Stacks wallet (Leather/Xverse)
- IPFS node or Pinata account
- Node.js 18+

### Installation
```bash
# Clone repository
git clone https://github.com/yourusername/craftbasin
cd craftbasin

# Install dependencies
npm install

# Deploy contract
clarinet integrate
```

### Quick Example
```clarity
;; Register as creator
(contract-call? .craftbasin register-creator)

;; Create content vault
(contract-call? .craftbasin create-content-vault
    u"Exclusive Album - Midnight Sessions"
    u"10 unreleased tracks from my studio sessions"
    u1  ;; CATEGORY-MUSIC
    "QmXxxx..."  ;; IPFS hash
    0x1234...    ;; Encrypted key hash
)

;; Set premium tier pricing
(contract-call? .craftbasin set-content-tier
    u1           ;; content-id
    u2           ;; TIER-PREMIUM
    u100000000   ;; 100 STX
    u100         ;; Max 100 NFTs
    u144000      ;; ~100 days access
    u"Early access + exclusive artwork"
)

;; Purchase as patron
(contract-call? .craftbasin purchase-access-nft u1 u2)

;; List for resale
(contract-call? .craftbasin list-nft-for-resale u1 u120000000)
```

## Architecture
```
┌─────────────────┐
│   Creators      │ ← Musicians, Artists, Writers, Educators
└────────┬────────┘
         │
┌────────▼────────┐
│  Content Vault  │ ← Encrypted IPFS + Smart Contracts
│  + IP Timestamp │
└────────┬────────┘
         │
┌────────▼────────┐
│  Access NFTs    │ ← Tiered, Tradeable, Time-bound
│  (4 Tiers)      │
└────────┬────────┘
         │
┌────────▼────────┐
│  Royalty        │ ← Auto-distribution on resales
│  Cascade        │
└────────┬────────┘
         │
┌────────▼────────┐
│  Patrons        │ ← Supporters with tradeable access
└─────────────────┘
```

## Revenue Model

### Primary Sales
- Creator receives 95% (minus platform fee)
- Platform receives 5% fee
- Instant settlement to creator wallet

### Secondary Sales (Resales)
- Previous owner receives majority
- Creator receives 5-50% royalty (configurable)
- Platform receives 5% fee
- Cascade tracking up to 5 levels

### Collaborative Content
- Custom revenue splits per collaborator
- Automated distribution on each sale
- Independent withdrawal system

## Technical Innovations

🔐 **Zero-Knowledge Proofs** - Secure content verification  
🔗 **Hybrid Architecture** - On-chain rights, off-chain content  
⛓️ **Royalty Cascade** - Multi-level automated distribution  
📝 **IP Timestamping** - Immutable proof of creation  
🎯 **Smart Access Gates** - Cryptographic content protection

## Platform Benefits

### For Creators
- 95% revenue share (vs 50-70% on traditional platforms)
- Complete IP control
- Automated royalty collection
- Transparent earnings tracking
- No platform lock-in

### For Patrons
- Tradeable access rights
- Multiple tier options
- Verifiable authenticity
- Direct creator support
- Potential investment value

## Roadmap

- [ ] Mobile app (iOS/Android)
- [ ] Social features and creator profiles
- [ ] AI plagiarism detection oracles
- [ ] Cross-chain bridge for multi-blockchain support
- [ ] Decentralized governance (DAO)
- [ ] Advanced analytics dashboard
- [ ] Creator collaboration tools
- [ ] Subscription bundling
