# 🌾 Farmer-to-Market-Chain Smart Contract

A comprehensive blockchain solution for tracking agricultural products from farm to market, ensuring transparency, quality, and traceability in the food supply chain.

## 🚀 Features

- 👨‍🌾 **Farmer Registration**: Register farmers with certifications and location data
- 🏪 **Market Registration**: Register markets, retailers, and distributors  
- 🥕 **Product Management**: Add and track agricultural products with detailed metadata
- 📦 **Batch Tracking**: Create batches for granular supply chain tracking
- 🚚 **Transfer System**: Transfer ownership of product batches between parties
- 🌡️ **Temperature Monitoring**: Log temperature data for cold chain management
- 📍 **Location Tracking**: Track product movement through the supply chain
- 🔬 **Quality Testing**: Record quality test results and certifications
- ⭐ **Rating System**: Rate markets and review products
- 🛡️ **Organic Verification**: Track organic certification status

## 📋 Contract Functions

### Registration Functions
- `register-farmer` - Register a new farmer with certification details
- `register-market` - Register a market or retailer
- `add-farmer-certification` - Add additional certifications to farmer profile

### Product Management
- `add-product` - Add a new agricultural product with harvest details
- `create-batch` - Create trackable batches from products
- `update-batch-status` - Update the status of a product batch

### Supply Chain Tracking  
- `transfer-batch` - Transfer ownership of a batch between parties
- `update-location` - Update current location of a batch
- `add-temperature-reading` - Log temperature data for cold chain
- `add-quality-test` - Record quality test results
- `confirm-delivery` - Confirm delivery and quality acceptance

### Reviews & Ratings
- `rate-market` - Rate a market based on experience
- `add-product-review` - Review a specific product

### Administrative
- `deactivate-farmer` - Deactivate a farmer account (owner only)
- `deactivate-market` - Deactivate a market account (owner only) 
- `emergency-pause-product` - Emergency pause a product (owner only)

## 🔍 Read-Only Functions

- `get-farmer` - Get farmer details
- `get-market` - Get market details  
- `get-product` - Get product information
- `get-batch` - Get batch details and tracking info
- `get-batch-trace` - Get complete traceability information
- `verify-organic-certification` - Check organic certification status
- `check-expiry-status` - Check if product is still fresh
- `calculate-total-price` - Calculate price for batch quantity

## 🛠️ Getting Started

### Prerequisites
- Clarinet CLI installed
- Stacks wallet for testing

### Installation
```bash
git clone <repository-url>
cd Farmer-to-Market-Chain
clarinet check
```

### Testing
```bash
npm install
npm test
```

## 💡 Usage Examples

### Register as a Farmer
```clarity
(contract-call? .Farmer-to-Market-Chain register-farmer 
    "Green Valley Farm" 
    "California, USA" 
    "USDA Organic")
```

### Add a Product
```clarity
(contract-call? .Farmer-to-Market-Chain add-product 
    "Organic Tomatoes" 
    "Vegetables" 
    u1000 
    "kg" 
    u1640995200 
    u1641600000 
    u5 
    "A" 
    true)
```

### Create and Transfer a Batch
```clarity
(contract-call? .Farmer-to-Market-Chain create-batch u1 "BATCH-001" u500)
(contract-call? .Farmer-to-Market-Chain transfer-batch u1 'SP2J6ZY48GV1EZ5V2V5RB9MP66SW86PYKKNRV9EJ7 u2500 (some u1641686400))
```

### Track Quality and Location
```clarity
(contract-call? .Farmer-to-Market-Chain add-quality-test u1 "Pesticide-Free Certified")
(contract-call? .Farmer-to-Market-Chain add-temperature-reading u1 u4)
(contract-call? .Farmer-to-Market-Chain update-location u1 "Distribution Center NYC")
```

## 🏗️ Contract Architecture

The contract uses several data structures:
- **Farmers Map**: Stores farmer registration and certification data
- **Markets Map**: Stores market/retailer information  
- **Products Map**: Stores product details and metadata
- **Product Batches Map**: Tracks individual batches through supply chain
- **Transactions Map**: Records all ownership transfers
- **Quality Data**: Temperature logs, test results, location history

## 🔐 Security Features

- Ownership verification for all operations
- Input validation for all user data
- Emergency pause functionality for products
- Organic certification tracking
- Quality control checkpoints

## 📊 Data Transparency

All supply chain data is stored on-chain providing:
- Complete product traceability from farm to market
- Immutable quality and safety records  
- Transparent pricing and transaction history
- Verifiable organic and quality certifications



## 📄 License

This project is open source and available under the MIT License.
