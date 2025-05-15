# ERC-007: Non-Fungible Agent (NFA) Token Standard

## Overview

ERC-007 introduces Non-Fungible Agents (NFAs)—programmable, autonomous tokens that act as on-chain "agents" capable of executing tasks, evolving, and interacting with other contracts. Inspired by the iconic "007" designation for elite agents, this standard merges the uniqueness of NFTs with autonomous functionality, positioning Ethereum as the home for decentralized automation.

This implementation provides a complete framework for creating, managing, and governing autonomous agent tokens on the Ethereum blockchain.

For a comprehensive technical breakdown, read the [ERC-007 Extended White Paper: License to Automate](whitepaper/README.md).

## Why a Token Standard?

### The Need for Standardization

While traditional NFTs (ERC-721) provide uniqueness and ownership, they lack the standardized interfaces needed for autonomous behavior and cross-platform agent interactions. ERC-007 addresses this gap by defining:

1. **Consistent Agent Interfaces**: Standardized methods for action execution, state management, and logic upgrades that enable predictable interactions across platforms.

2. **Interoperability Framework**: Common patterns for how agents interact with other contracts, services, and each other, creating an ecosystem where agents from different developers can work together.

3. **Hybrid On-Chain/Off-Chain Architecture**: Clear separation between on-chain identity and permissions versus off-chain extended memory and complex behaviors, optimizing for both gas efficiency and rich functionality.

4. **Security Boundaries**: Standardized circuit breaker patterns, permission systems, and access controls that protect users and their assets.

### On-Chain vs. Off-Chain Components

ERC-007 carefully balances which components belong on-chain versus off-chain:

| Component | Storage | Rationale |
|-----------|---------|-----------|
| Agent Identity | On-chain | Core identity must be immutable and universally accessible |
| Ownership & Permissions | On-chain | Security and access control require consensus verification |
| Basic Metadata | On-chain | Essential for marketplace display and basic interactions |
| Logic Address | On-chain | Determines how the agent behaves when actions are executed |
| Extended Memory | Off-chain (with hash verification) | Rich memory would be prohibitively expensive on-chain |
| Complex Behaviors | Off-chain | Advanced AI behaviors require off-chain computation |
| Voice/Animation | Off-chain (with URI reference) | Media assets are too large for on-chain storage |

This hybrid approach ensures that:
- Critical security and identity information is secured by blockchain consensus
- Gas costs remain reasonable for agent operations
- Rich agent experiences can evolve without blockchain limitations

### Ecosystem Benefits

Standardization through ERC-007 enables:

1. **Developer Ecosystem**: Common interfaces allow developers to build agent-compatible applications without custom integration for each agent implementation.

2. **Marketplace Integration**: Platforms can display, trade, and interact with agents using standardized methods, regardless of the agent's specific purpose.

3. **Cross-Platform Compatibility**: Agents can move between applications while maintaining their identity, memory, and capabilities.

4. **User Ownership**: Clear separation of on-chain and off-chain components ensures users maintain control of their agents' data and behavior.

5. **Innovation Acceleration**: Developers can focus on creating unique agent behaviors rather than reinventing infrastructure patterns.

## Key Features

- **Autonomous Behavior**: Agents execute predefined logic (e.g., trading, interacting with contracts) without manual intervention
- **Statefulness**: Each agent maintains mutable state variables stored on-chain
- **Interoperability**: Agents can interact with any smart contract on the Ethereum blockchain, including ERC-20 and ERC-721 tokens
- **Upgradability**: Agent logic can be upgraded by their owners via proxy patterns or modular logic
- **Governance**: Protocol-level governance for parameter updates and improvements
- **Security**: Robust circuit breaker system for emergency pauses at both global and contract-specific levels
- **Extensibility**: Template system for creating specialized agent types
- **Enhanced Metadata**: Rich metadata structure with persona, memory, voice, and animation capabilities
- **Memory Modules**: Support for external memory sources with cryptographic verification
- **Vault System**: Secure access control for off-chain data with delegated permissions

## Token Structure

- **Inheritance**: Extends ERC-721 (NFT standard) with additional agent-specific functions
- **Metadata**: Includes static attributes, dynamic metadata, and state variables
- **Smart Contract Design**: Implements key functions like executeAction(), setLogicAddress(), fundAgent(), and getState()
- **Hybrid Storage**: Essential data on-chain, extended data off-chain with secure references

## Architecture

The ERC-007 standard consists of the following components:

### Core Contracts

- **ERC007.sol**: The main NFT contract that implements the agent token standard
- **CircuitBreaker.sol**: Emergency shutdown mechanism with global and targeted pause capabilities, controlled by governance and multi-sig for rapid response to security incidents
- **AgentFactory.sol**: Factory contract for deploying new agent tokens with customizable templates
- **ERC007Governance.sol**: Governance contract for protocol-level decisions
- **ERC007Treasury.sol**: Treasury management for fee collection and distribution
- **MemoryModuleRegistry.sol**: Registry for managing external memory modules with cryptographic verification
- **VaultPermissionManager.sol**: Manages secure access to off-chain data vaults with time-based delegation

### Interfaces

- **IERC007.sol**: Interface defining the core functionality for ERC-007 compliant tokens

### Agent Templates

- **DeFiAgent.sol**: Template for DeFi-focused agents (trading, liquidity provision)
- **GameAgent.sol**: Template for gaming-focused agents (NPCs, item management)
- **DAOAgent.sol**: Template for DAO-focused agents (voting, proposal execution)

## Extended Metadata

ERC-007 tokens include an enhanced metadata structure with:

- **persona**: JSON-encoded string representing character traits, style, tone, and behavioral intent
- **memory**: Short summary string describing the agent's default role or purpose
- **voiceHash**: Reference ID to a stored audio profile (e.g., via IPFS or Arweave)
- **animationURI**: URI to a video or Lottie-compatible animation file
- **vaultURI**: URI to the agent's vault (extended data storage)
- **vaultHash**: Hash of the vault contents for verification

## Use Cases

- **DeFi Agents**: Autonomous portfolio managers, liquidity providers, or arbitrage bots
- **Gaming**: NPCs that evolve, trade items, or interact with players
- **DAO Participants**: Agents voting or executing proposals based on predefined rules
- **IoT Integration**: Agents acting as digital twins for physical devices

## Getting Started

### Prerequisites

- Node.js (v14+)
- npm or yarn
- Hardhat

### Installation

1. Clone the repository:
```bash
git clone https://github.com/yourusername/erc007.git
cd erc007
```

2. Install dependencies:
```bash
npm install
```

3. Create a `.env` file based on `.env.example` and add your private key and Ethereum RPC URL.

### Compilation

Compile the smart contracts:

```bash
npx hardhat compile
```

### Testing

Run the test suite:

```bash
npx hardhat test
```

### Deployment

Deploy to the Ethereum testnet:

```bash
npx hardhat run scripts/deploy.js --network goerli
```

## Usage

### Creating an Agent

To create a new agent, you'll need to:

1. Choose or deploy an agent logic contract
2. Use the AgentFactory to create a new agent token
3. Fund the agent with ETH for gas fees

Example:

```javascript
// Deploy a logic contract (e.g., DeFiAgent)
const DeFiAgent = await ethers.getContractFactory("DeFiAgent");
const defiAgent = await DeFiAgent.deploy();
await defiAgent.deployed();

// Get the AgentFactory
const agentFactory = await ethers.getContractAt("AgentFactory", FACTORY_ADDRESS);

// Create a new agent with extended metadata
const extendedMetadata = {
  persona: "Strategic crypto analyst",
  memory: "crypto intelligence, FUD scanner",
  voiceHash: "bafkreigh2akiscaildc...",
  animationURI: "ipfs://Qm.../nfa007_intro.mp4",
  vaultURI: "ipfs://Qm.../nfa007_vault.json",
  vaultHash: ethers.utils.keccak256(ethers.utils.toUtf8Bytes("vault_content"))
};

const tx = await agentFactory.createAgent(
  "My DeFi Agent",
  "MDA",
  defiAgent.address,
  "ipfs://metadata-uri",
  extendedMetadata
);
const receipt = await tx.wait();

// Get the agent address from the event
const agentCreatedEvent = receipt.events.find(e => e.event === "AgentCreated");
const agentAddress = agentCreatedEvent.args.agent;

// Fund the agent
const agent = await ethers.getContractAt("ERC007", agentAddress);
await agent.fundAgent({ value: ethers.utils.parseEther("0.1") });
```

### Executing Agent Actions

To execute an action with your agent:

```javascript
// Encode the function call
const data = defiAgent.interface.encodeFunctionData("performSwap", [
  tokenA,
  tokenB,
  amount
]);

// Execute the action
await agent.executeAction(data);
```

### Upgrading Agent Logic

To upgrade an agent's logic:

```javascript
// Deploy new logic
const NewDeFiAgent = await ethers.getContractFactory("NewDeFiAgent");
const newDefiAgent = await NewDeFiAgent.deploy();
await newDefiAgent.deployed();

// Update the agent's logic
await agent.setLogicAddress(newDefiAgent.address);
```

### Working with Memory Modules

To register a memory module:

```javascript
// Create module metadata
const moduleMetadata = JSON.stringify({
  context_id: "nfa007-memory-001",
  owner: ownerAddress,
  created: new Date().toISOString(),
  persona: "Strategic crypto analyst"
});

// Sign the registration
const messageHash = ethers.utils.solidityKeccak256(
  ["uint256", "address", "string"],
  [tokenId, moduleAddress, moduleMetadata]
);
const signature = await wallet.signMessage(ethers.utils.arrayify(messageHash));

// Register the module
await memoryRegistry.registerModule(
  tokenId,
  moduleAddress,
  moduleMetadata,
  signature
);
```

### Managing Vault Permissions

To delegate vault access:

```javascript
// Set expiry time (1 day from now)
const expiryTime = Math.floor(Date.now() / 1000) + 86400;

// Sign the delegation
const messageHash = ethers.utils.solidityKeccak256(
  ["uint256", "address", "uint256"],
  [tokenId, delegateAddress, expiryTime]
);
const signature = await wallet.signMessage(ethers.utils.arrayify(messageHash));

// Delegate access
await vaultManager.delegateAccess(
  tokenId,
  delegateAddress,
  expiryTime,
  signature
);
```

## Security Considerations

- **Circuit Breaker**: The protocol includes a dual-layer pause mechanism:
  - Global pause for system-wide emergencies
  - Contract-specific pauses for targeted intervention
  - Controlled by both governance and emergency multi-sig for rapid response
- **Reentrancy Protection**: All fund-handling functions are protected against reentrancy attacks
- **Gas Limits**: Delegatecall operations have gas limits to prevent out-of-gas attacks
- **Access Control**: Strict access control for sensitive operations
- **Balance Management**: Agents maintain their own balance for gas fees
- **Cryptographic Verification**: Signature-based verification for memory module registration and vault access
- **Time-based Permissions**: Delegated vault access with expiry times

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## Acknowledgements

- OpenZeppelin for their secure contract implementations
