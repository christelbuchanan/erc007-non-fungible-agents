// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title MockLogic
 * @dev A mock logic contract for testing ERC007 agent actions
 */
contract MockLogic {
    // Event emitted when the execute function is called
    event Executed(bytes data);
    
    // Simple storage variable for testing
    uint256 public counter;
    
    /**
     * @dev Executes a simple action that increments the counter
     * @param value The amount to increment the counter by
     * @return The new counter value
     */
    function execute(uint256 value) external returns (uint256) {
        counter += value;
        emit Executed(abi.encode(value));
        return counter;
    }
    
    /**
     * @dev Resets the counter to zero
     */
    function reset() external {
        counter = 0;
        emit Executed(abi.encode(0));
    }
    
    /**
     * @dev A function that will revert, for testing error handling
     */
    function willRevert() external pure {
        revert("MockLogic: intentional revert");
    }
}
