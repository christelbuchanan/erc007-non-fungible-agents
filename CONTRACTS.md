# ERC-007 Smart Contracts

This document provides an overview of the smart contracts that implement the ERC-007 standard.

## Core Contracts

### ERC007.sol

The main contract that implements the ERC-007 standard. It inherits from ERC-721 and adds functionality for agent creation, action execution, and state management.

**Key Functions:**
- `createAgent`: Creates a new agent token
- `executeAction`: Executes an action on behalf of an agent
- `setLogicAddress`: Updates the logic contract for an agent
- `updateAgentMetadata`: Updates the agent's metadata
- `fundAgent`: Adds funds to an agent's balance
- `pause`/`unpause`/`terminate`: Controls agent status

### AgentFactory.sol

Factory contract for deploying new agent tokens with customizable templates.

**Key Functions:**
- `createAgentFromTemplate`: Creates an agent based on a template
- `registerTemplate`: Registers a new agent template
- `batchCreateAgents`: Creates multiple agents in a single transaction

### MemoryModuleRegistry.sol

Registry for managing external memory modules with cryptographic verification.

**Key Functions:**
- `registerMemoryModule`: Registers a memory module for an agent
- `verifyMemoryModule`: Verifies a memory module's authenticity
- `getApprovedModules`: Gets all approved modules for an agent

### CircuitBreaker.sol

Emergency shutdown mechanism with global and targeted pause capabilities.

**Key Functions:**
- `globalPause`/`globalUnpause`: Controls global pause state
- `pauseAgent`/`unpauseAgent`: Controls individual agent pause state
- `isAgentPaused`: Checks if an agent is paused

### ERC007Governance.sol

Governance contract for protocol-level decisions.

**Key Functions:**
- `proposeChange`: Proposes a protocol parameter change
- `vote`: Votes on a proposal
- `executeProposal`: Executes an approved proposal
- `updateFeeStructure`: Updates protocol fees

### ERC007Treasury.sol

Treasury management for fee collection and distribution.

**Key Functions:**
- `collectFee`: Collects fees from agent operations
- `distributeFees`: Distributes collected fees to stakeholders
- `withdrawFunds`: Withdraws funds for protocol development

### VaultPermissionManager.sol

Manages secure access to off-chain data vaults with time-based delegation.

**Key Functions:**
- `grantAccess`: Grants access to an agent's vault
- `revokeAccess`: Revokes access to an agent's vault
- `verifyAccess`: Verifies if an entity has access to a vault

## Interfaces

### IERC007.sol

Interface defining the core functionality for ERC-007 compliant tokens.

**Key Definitions:**
- `Status` enum: Defines agent status states
- `State` struct: Defines agent state structure
- `AgentMetadata` struct: Defines extended metadata structure
- Core function signatures for agent operations

## Agent Templates

### DeFiAgent.sol

Template for DeFi-focused agents (trading, liquidity provision).

**Key Features:**
- Trading logic implementation
- Liquidity management functions
- Risk management parameters

### GameAgent.sol

Template for gaming-focused agents (NPCs, item management).

**Key Features:**
- Game interaction logic
- Character state management
- Item handling capabilities

### DAOAgent.sol

Template for DAO-focused agents (voting, proposal execution).

**Key Features:**
- Voting logic implementation
- Proposal management functions
- DAO interaction capabilities

### CreatorAgent.sol

Template for creator-focused agents (content management, royalties).

**Key Features:**
- Content creation logic
- Royalty distribution functions
- Collaboration capabilities

### StrategicAgent.sol

Template for strategy-focused agents (market analysis, intelligence).

**Key Features:**
- Analysis logic implementation
- Strategy execution functions
- Data processing capabilities

## Mock Contracts

### MockMemoryRegistry.sol

Mock implementation of the memory registry for testing.

### MockLogic.sol

Mock implementation of agent logic for testing.

## Contract Relationships

```
                  ┌─────────────┐
                  │  ERC007.sol │
                  └──────┬──────┘
                         │
         ┌───────────────┼───────────────┐
         │               │               │
┌────────▼─────┐ ┌───────▼────────┐ ┌───▼───────────────┐
│ AgentFactory │ │ CircuitBreaker │ │ MemoryModuleRegistry │
└──────────────┘ └────────────────┘ └───────────────────┘
         │               │               │
         └───────────────┼───────────────┘
                         │
                  ┌──────▼──────┐
                  │ Governance  │
                  └──────┬──────┘
                         │
                  ┌──────▼──────┐
                  │  Treasury   │
                  └─────────────┘
```

## Gas Optimization

The contracts implement several gas optimization techniques:

1. **Storage Packing**: Related variables are packed into the same storage slot
2. **Minimal Storage**: Only essential data is stored on-chain
3. **Batch Operations**: Support for batch operations to amortize gas costs
4. **Proxy Pattern**: Upgradeable contracts to avoid redeployment costs
5. **Gas Limits**: Explicit gas limits for delegatecall operations

## Security Features

The contracts include several security features:

1. **Access Control**: Strict access control for sensitive operations
2. **Reentrancy Protection**: Guards against reentrancy attacks
3. **Circuit Breaker**: Emergency pause mechanism
4. **Input Validation**: Thorough validation of all inputs
5. **Gas Limits**: Protection against out-of-gas attacks
6. **Upgrade Controls**: Secure upgrade mechanisms with timelock
