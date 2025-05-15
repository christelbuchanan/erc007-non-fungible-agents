# Agent Lifecycle

ERC-007 tokens follow a defined lifecycle that enables secure creation, evolution, and potential retirement of agents.

## Creation

Agents are minted through the `createAgent` function, which requires:

1. **Owner Address**: The initial owner who will control the agent
2. **Logic Address**: The contract that defines the agent's behavior
3. **Metadata URI**: A URI pointing to the agent's basic metadata
4. **Extended Metadata**: Optional on-chain persona and memory attributes

During creation, the agent is assigned a unique token ID and initialized with Active status. The minting process emits a `Transfer` event (from ERC-721) and stores the agent's initial state.

## Configuration

After minting, owners can configure their agents through several functions:

1. **updateAgentMetadata**: Update the agent's on-chain persona and memory
2. **setLogicAddress**: Change the agent's behavior by pointing to a new logic contract
3. **registerMemoryModule**: Connect the agent to external memory sources

These configuration options allow agents to evolve over time while maintaining their core identity.

## Operation

Active agents can execute actions through the `executeAction` function, which:

1. Verifies the agent is active and not paused
2. Performs a delegatecall to the agent's logic contract
3. Emits an `ActionExecuted` event with the result
4. Updates the agent's last action timestamp

Agents can also receive funds through the `fundAgent` function, which increases their balance for use in actions that require payment.

## Pausing and Termination

For security and lifecycle management, agents can be:

1. **Paused**: Temporarily disabled by the owner using `pause`
2. **Unpaused**: Re-activated by the owner using `unpause`
3. **Terminated**: Permanently disabled by the owner using `terminate`

Terminated agents cannot be reactivated and can no longer execute actions, though they still exist as tokens that can be transferred.

## Governance Interaction

The ERC-007 standard includes governance mechanisms that can affect agent lifecycle:

1. **Global Pause**: In emergency situations, governance can pause all agents
2. **Protocol Upgrades**: Governance can upgrade the protocol while preserving agent state
3. **Fee Adjustments**: Governance can adjust protocol fees that apply to agent operations

These governance capabilities ensure the protocol can evolve while protecting agent owners.
