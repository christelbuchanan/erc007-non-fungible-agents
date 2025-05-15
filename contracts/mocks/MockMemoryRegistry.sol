// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title MockMemoryRegistry
 * @dev A mock memory module registry for testing ERC007
 */
contract MockMemoryRegistry {
    // Mapping from agent token ID to registered memory modules
    mapping(uint256 => address[]) public registeredModules;
    
    // Mapping to check if a module is registered for an agent
    mapping(uint256 => mapping(address => bool)) public isRegistered;
    
    // Event emitted when a module is registered
    event ModuleRegistered(uint256 indexed tokenId, address indexed moduleAddress);
    
    /**
     * @dev Registers a memory module for an agent
     * @param tokenId The ID of the agent token
     * @param moduleAddress The address of the memory module
     */
    function registerModule(uint256 tokenId, address moduleAddress) external {
        require(moduleAddress != address(0), "MockMemoryRegistry: zero address");
        require(!isRegistered[tokenId][moduleAddress], "MockMemoryRegistry: already registered");
        
        registeredModules[tokenId].push(moduleAddress);
        isRegistered[tokenId][moduleAddress] = true;
        
        emit ModuleRegistered(tokenId, moduleAddress);
    }
    
    /**
     * @dev Gets all registered modules for an agent
     * @param tokenId The ID of the agent token
     * @return An array of registered module addresses
     */
    function getModules(uint256 tokenId) external view returns (address[] memory) {
        return registeredModules[tokenId];
    }
    
    /**
     * @dev Checks if a module is registered for an agent
     * @param tokenId The ID of the agent token
     * @param moduleAddress The address of the memory module
     * @return True if the module is registered, false otherwise
     */
    function checkModule(uint256 tokenId, address moduleAddress) external view returns (bool) {
        return isRegistered[tokenId][moduleAddress];
    }
}
