# Token Standard Architecture

ERC-007 defines an upgraded metadata structure for NFTs that includes four key agentic attributes:

1. Image or video identity
2. Audio voice file
3. A structured persona schema
4. A light memory string

This metadata is stored on-chain to preserve the agent's public-facing identity. However, the core innovation lies in the separation of identity and memory.

While metadata provides the surface-level persona, deeper agent memory, decision trees, and behavioral models are stored off-chain within user-owned vaults and can be permissioned for selective sharing with platforms and backends.

Each NFA is minted with a unique identifier (e.g., NFA88), and the minting process allows users to upload their media assets and generate personas.

These agents can later be extended with voice, video animation, and plug-in logic that interfaces with intelligent backends such as ChatAndBuild's Intelligent Memory Protocol, which supports Boolean logic queries across 90M+ data sources.

## Standardized Components

The ERC-007 standard carefully balances which components belong on-chain versus off-chain:

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

## Standardized Interfaces

ERC-007 defines several key interfaces that all compliant tokens must implement:

1. **Core Agent Interface**: Methods for executing actions, managing state, and upgrading logic.
2. **Metadata Extension**: Standardized structure for agent persona, memory, and media references.
3. **Memory Module Interface**: Protocol for registering and verifying external memory sources.
4. **Vault Permission Interface**: Secure delegation of access to off-chain data.

These interfaces enable predictable interactions across platforms and ensure that agents from different developers can work together seamlessly.
