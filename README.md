# SportAuth

A comprehensive supply chain tracking smart contract for sports equipment authenticity and performance verification on the Stacks blockchain.

## Description

SportAuth enables manufacturers, retailers, and consumers to track the authenticity, ownership, and performance data of sports equipment throughout the entire supply chain. Built with Clarity smart contract language, it provides immutable records of equipment lifecycle, ownership transfers, quality assessments, and performance testing data.

## Features

- **Equipment Registration**: Manufacturers can register new sports equipment with unique identifiers
- **Supply Chain Tracking**: Track equipment status from manufacturing to end-user
- **Ownership Management**: Secure ownership transfers with complete history tracking
- **Authenticity Verification**: Quality checker authorization and verification system
- **Performance Testing**: Record and track equipment performance data
- **Authorization System**: Role-based access control for manufacturers, quality checkers, and retailers
- **Immutable Records**: Permanent blockchain-based tracking and verification

## Technical Specifications

- **Blockchain**: Stacks
- **Language**: Clarity
- **Version**: 1.0.0
- **Clarity Version**: 2
- **Epoch**: 2.5

### Equipment Status Lifecycle

1. **MANUFACTURED** (1) - Initial state after equipment registration
2. **QUALITY_CHECKED** (2) - After quality verification
3. **SHIPPED** (3) - Equipment shipped from manufacturer
4. **RETAIL** (4) - Available at retail location
5. **SOLD** (5) - Purchased by end consumer
6. **IN_USE** (6) - Active use by consumer

## Installation

### Prerequisites

- [Clarinet](https://github.com/hirosystems/clarinet) CLI tool
- Node.js (for development dependencies)

### Setup

1. Clone the repository:
```bash
git clone <repository-url>
cd SportAuth
```

2. Navigate to the contract directory:
```bash
cd SportAuth_contract
```

3. Install dependencies:
```bash
npm install
```

4. Check contract syntax:
```bash
clarinet check
```

## Usage Examples

### 1. Authorize Entity

Only contract owner can authorize entities:

```clarity
(contract-call? .SportAuth authorize-entity 'ST1MANUFACTURER123 "manufacturer")
(contract-call? .SportAuth authorize-entity 'ST1QUALITYCHECKER456 "quality-checker")
(contract-call? .SportAuth authorize-entity 'ST1RETAILER789 "retailer")
```

### 2. Register Equipment

Authorized manufacturers can register new equipment:

```clarity
(contract-call? .SportAuth register-equipment
  "Nike Air Max 2024"
  "AM24-001-XYZ123"
  u1234567890)
```

### 3. Update Equipment Status

Authorized parties can update equipment status:

```clarity
(contract-call? .SportAuth update-equipment-status u1 u2)
```

### 4. Transfer Ownership

Current owner can transfer equipment ownership:

```clarity
(contract-call? .SportAuth transfer-ownership u1 'ST1NEWOWNER123)
```

### 5. Record Performance Test

Authorized testers can record performance data:

```clarity
(contract-call? .SportAuth record-performance-test
  u1
  "Durability Test"
  u95
  "Excellent performance under stress testing")
```

### 6. Verify Authenticity

Quality checkers can verify equipment authenticity:

```clarity
(contract-call? .SportAuth verify-authenticity u1 true)
```

## Contract Functions Documentation

### Public Functions

#### `authorize-entity`
**Access**: Contract owner only
**Purpose**: Authorize manufacturers, quality checkers, or retailers
**Parameters**:
- `entity` (principal): Address to authorize
- `entity-type` (string-ascii 20): Type of authorization ("manufacturer", "quality-checker", "retailer")

#### `register-equipment`
**Access**: Authorized manufacturers only
**Purpose**: Register new sports equipment
**Parameters**:
- `model` (string-ascii 100): Equipment model name
- `serial-number` (string-ascii 50): Unique serial number
- `manufacture-date` (uint): Manufacturing date (block height)
**Returns**: Equipment ID

#### `update-equipment-status`
**Access**: Authorized entities and owners
**Purpose**: Update equipment status in supply chain
**Parameters**:
- `equipment-id` (uint): Equipment identifier
- `new-status` (uint): New status (1-6)

#### `transfer-ownership`
**Access**: Current owner only
**Purpose**: Transfer equipment ownership
**Parameters**:
- `equipment-id` (uint): Equipment identifier
- `new-owner` (principal): New owner address

#### `record-performance-test`
**Access**: Quality checkers and owners
**Purpose**: Record equipment performance test data
**Parameters**:
- `equipment-id` (uint): Equipment identifier
- `test-type` (string-ascii 50): Type of test performed
- `performance-score` (uint): Performance score (0-100)
- `notes` (string-ascii 200): Additional test notes

#### `verify-authenticity`
**Access**: Quality checkers only
**Purpose**: Verify equipment authenticity
**Parameters**:
- `equipment-id` (uint): Equipment identifier
- `is-authentic` (bool): Authenticity verification result

### Read-Only Functions

#### `get-equipment-info`
Returns complete equipment information including manufacturer, model, status, and ownership details.

#### `get-ownership-history`
Returns ownership transfer history for specific equipment and transfer ID.

#### `get-performance-data`
Returns performance test data for specific equipment and test ID.

#### `get-entity-authorization`
Returns authorization details for a specific entity.

#### `get-total-equipment-count`
Returns total number of registered equipment items.

#### `is-equipment-authentic`
Returns authenticity verification status for specific equipment.

## Deployment Guide

### Local Development

1. Start Clarinet console:
```bash
clarinet console
```

2. Deploy contract:
```clarity
::deploy_contracts
```

3. Test contract functions in the console environment

### Testnet Deployment

1. Configure testnet settings in `settings/Testnet.toml`

2. Deploy to testnet:
```bash
clarinet deployments apply --testnet
```

### Mainnet Deployment

1. Configure mainnet settings in `settings/Mainnet.toml`

2. Deploy to mainnet:
```bash
clarinet deployments apply --mainnet
```

## Security Notes

### Access Control
- **Contract Owner**: Can authorize entities and has administrative privileges
- **Manufacturers**: Can register equipment and update status
- **Quality Checkers**: Can verify authenticity, test equipment, and update status
- **Retailers**: Can update equipment status
- **Equipment Owners**: Can transfer ownership and test their equipment

### Security Features
- Role-based authorization system prevents unauthorized access
- Ownership verification ensures only legitimate owners can transfer equipment
- Immutable blockchain records prevent tampering with historical data
- Input validation prevents invalid status updates and malformed data

### Important Considerations
- Ensure proper key management for authorized entities
- Verify entity authorization before granting access
- Monitor for suspicious ownership transfer patterns
- Regularly audit authorized entities list
- Consider multi-signature requirements for high-value equipment

### Error Codes
- `ERR_NOT_AUTHORIZED` (100): Insufficient permissions
- `ERR_EQUIPMENT_NOT_FOUND` (101): Equipment ID does not exist
- `ERR_ALREADY_EXISTS` (102): Equipment already registered
- `ERR_INVALID_OWNER` (103): Invalid ownership claim
- `ERR_INVALID_STATUS` (104): Invalid status code

## Data Privacy
- All data stored on-chain is publicly visible
- Consider privacy implications for sensitive equipment information
- Use off-chain storage for confidential data with on-chain hashes for verification

## Contributing

1. Fork the repository
2. Create a feature branch
3. Test thoroughly with Clarinet
4. Submit a pull request with comprehensive documentation

## License

This project is licensed under the MIT License - see the LICENSE file for details.