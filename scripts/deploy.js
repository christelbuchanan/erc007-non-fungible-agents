const { ethers, upgrades } = require("hardhat");

async function main() {
  console.log("Deploying ERC007 ecosystem contracts...");

  // Get the contract factories
  const ERC007 = await ethers.getContractFactory("ERC007");
  const ERC007Governance = await ethers.getContractFactory("ERC007Governance");
  const ERC007Treasury = await ethers.getContractFactory("ERC007Treasury");
  const MemoryModuleRegistry = await ethers.getContractFactory("MemoryModuleRegistry");
  const AgentFactory = await ethers.getContractFactory("AgentFactory");
  const CircuitBreaker = await ethers.getContractFactory("CircuitBreaker");
  const VaultPermissionManager = await ethers.getContractFactory("VaultPermissionManager");

  // Deploy ERC007 as upgradeable
  console.log("Deploying ERC007...");
  const erc007 = await upgrades.deployProxy(ERC007, [
    "Non-Fungible Agent", 
    "NFA",
    ethers.constants.AddressZero // Temporary governance address
  ]);
  await erc007.deployed();
  console.log("ERC007 deployed to:", erc007.address);

  // Deploy Treasury
  console.log("Deploying ERC007Treasury...");
  const treasury = await upgrades.deployProxy(ERC007Treasury, [
    ethers.constants.AddressZero, // Temporary governance address
    500, // 5% treasury fee
    200  // 2% owner fee
  ]);
  await treasury.deployed();
  console.log("ERC007Treasury deployed to:", treasury.address);

  // Deploy MemoryModuleRegistry
  console.log("Deploying MemoryModuleRegistry...");
  const memoryRegistry = await upgrades.deployProxy(MemoryModuleRegistry, [
    erc007.address,
    ethers.constants.AddressZero // Temporary governance address
  ]);
  await memoryRegistry.deployed();
  console.log("MemoryModuleRegistry deployed to:", memoryRegistry.address);

  // Deploy Governance
  console.log("Deploying ERC007Governance...");
  const governance = await upgrades.deployProxy(ERC007Governance, [
    treasury.address,
    erc007.address,
    memoryRegistry.address
  ]);
  await governance.deployed();
  console.log("ERC007Governance deployed to:", governance.address);

  // Deploy AgentFactory
  console.log("Deploying AgentFactory...");
  const agentFactory = await upgrades.deployProxy(AgentFactory, [
    erc007.address,
    governance.address
  ]);
  await agentFactory.deployed();
  console.log("AgentFactory deployed to:", agentFactory.address);

  // Deploy CircuitBreaker
  console.log("Deploying CircuitBreaker...");
  const [owner] = await ethers.getSigners();
  const circuitBreaker = await upgrades.deployProxy(CircuitBreaker, [
    erc007.address,
    governance.address,
    treasury.address,
    [owner.address] // Initial council member
  ]);
  await circuitBreaker.deployed();
  console.log("CircuitBreaker deployed to:", circuitBreaker.address);

  // Deploy VaultPermissionManager
  console.log("Deploying VaultPermissionManager...");
  const vaultManager = await upgrades.deployProxy(VaultPermissionManager, [
    erc007.address
  ]);
  await vaultManager.deployed();
  console.log("VaultPermissionManager deployed to:", vaultManager.address);

  // Update governance addresses
  console.log("Updating governance addresses...");
  await erc007.setGovernance(governance.address);
  await treasury.setGovernance(governance.address);
  await memoryRegistry.setGovernance(governance.address);

  // Set memory module registry in ERC007
  console.log("Setting memory module registry in ERC007...");
  await erc007.setMemoryModuleRegistry(memoryRegistry.address);

  console.log("Deployment complete!");
  console.log({
    ERC007: erc007.address,
    ERC007Governance: governance.address,
    ERC007Treasury: treasury.address,
    MemoryModuleRegistry: memoryRegistry.address,
    AgentFactory: agentFactory.address,
    CircuitBreaker: circuitBreaker.address,
    VaultPermissionManager: vaultManager.address
  });
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1));
}
