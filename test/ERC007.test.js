const { expect } = require("chai");
const { ethers, upgrades } = require("hardhat");

describe("ERC007", function () {
  let ERC007;
  let erc007;
  let owner;
  let governance;
  let user1;
  let user2;
  let logicContract;

  beforeEach(async function () {
    [owner, governance, user1, user2] = await ethers.getSigners();
    
    // Deploy the ERC007 contract
    ERC007 = await ethers.getContractFactory("ERC007");
    erc007 = await upgrades.deployProxy(ERC007, ["Non-Fungible Agent", "NFA", governance.address]);
    await erc007.deployed();
    
    // Deploy a mock logic contract for testing
    const MockLogic = await ethers.getContractFactory("MockLogic");
    logicContract = await MockLogic.deploy();
    await logicContract.deployed();
  });

  describe("Initialization", function () {
    it("Should initialize with correct name and symbol", async function () {
      expect(await erc007.name()).to.equal("Non-Fungible Agent");
      expect(await erc007.symbol()).to.equal("NFA");
    });

    it("Should set the governance address correctly", async function () {
      expect(await erc007.governance()).to.equal(governance.address);
    });

    it("Should start with global pause disabled", async function () {
      expect(await erc007.globalPause()).to.equal(false);
    });
  });

  describe("Agent Creation", function () {
    it("Should create an agent with extended metadata", async function () {
      const metadataURI = "ipfs://QmExample";
      const extendedMetadata = {
        persona: '{"traits": {"intelligence": 90, "creativity": 85}}',
        memory: "I am a creative assistant",
        voiceHash: "voice123",
        animationURI: "ipfs://QmAnimation",
        vaultURI: "ipfs://QmVault",
        vaultHash: ethers.utils.formatBytes32String("vaulthash")
      };

      await erc007.createAgent(
        user1.address,
        logicContract.address,
        metadataURI,
        extendedMetadata
      );

      expect(await erc007.ownerOf(1)).to.equal(user1.address);
      expect(await erc007.tokenURI(1)).to.equal(metadataURI);
      
      const agentState = await erc007.getState(1);
      expect(agentState.owner).to.equal(user1.address);
      expect(agentState.logicAddress).to.equal(logicContract.address);
      expect(agentState.status).to.equal(0); // Active
      
      const metadata = await erc007.getAgentMetadata(1);
      expect(metadata.persona).to.equal(extendedMetadata.persona);
      expect(metadata.memory).to.equal(extendedMetadata.memory);
      expect(metadata.voiceHash).to.equal(extendedMetadata.voiceHash);
      expect(metadata.animationURI).to.equal(extendedMetadata.animationURI);
      expect(metadata.vaultURI).to.equal(extendedMetadata.vaultURI);
      expect(metadata.vaultHash).to.equal(extendedMetadata.vaultHash);
    });

    it("Should create an agent with basic metadata", async function () {
      const metadataURI = "ipfs://QmExample";

      await erc007.createAgent(
        user1.address,
        logicContract.address,
        metadataURI
      );

      expect(await erc007.ownerOf(1)).to.equal(user1.address);
      expect(await erc007.tokenURI(1)).to.equal(metadataURI);
      
      const metadata = await erc007.getAgentMetadata(1);
      expect(metadata.persona).to.equal("");
      expect(metadata.memory).to.equal("");
    });

    it("Should revert if logic address is zero", async function () {
      await expect(
        erc007.createAgent(
          user1.address,
          ethers.constants.AddressZero,
          "ipfs://QmExample"
        )
      ).to.be.revertedWith("ERC007: logic address is zero");
    });
  });

  describe("Agent State Management", function () {
    beforeEach(async function () {
      // Create an agent for testing
      await erc007.createAgent(
        user1.address,
        logicContract.address,
        "ipfs://QmExample"
      );
      
      // Fund the agent
      await erc007.connect(user1).fundAgent(1, { value: ethers.utils.parseEther("1") });
    });

    it("Should allow owner to pause and unpause the agent", async function () {
      // Pause the agent
      await erc007.connect(user1).pause(1);
      
      let state = await erc007.getState(1);
      expect(state.status).to.equal(1); // Paused
      
      // Unpause the agent
      await erc007.connect(user1).unpause(1);
      
      state = await erc007.getState(1);
      expect(state.status).to.equal(0); // Active
    });

    it("Should allow owner to terminate the agent", async function () {
      await erc007.connect(user1).terminate(1);
      
      const state = await erc007.getState(1);
      expect(state.status).to.equal(2); // Terminated
    });

    it("Should not allow non-owner to pause the agent", async function () {
      await expect(
        erc007.connect(user2).pause(1)
      ).to.be.revertedWith("ERC007: caller is not agent owner");
    });

    it("Should allow governance to set global pause", async function () {
      await erc007.connect(governance).setGlobalPause(true);
      expect(await erc007.globalPause()).to.equal(true);
      
      await erc007.connect(governance).setGlobalPause(false);
      expect(await erc007.globalPause()).to.equal(false);
    });
  });

  describe("Agent Logic and Metadata", function () {
    beforeEach(async function () {
      // Create an agent for testing
      await erc007.createAgent(
        user1.address,
        logicContract.address,
        "ipfs://QmExample"
      );
    });

    it("Should allow owner to update logic address", async function () {
      const newLogic = await (await ethers.getContractFactory("MockLogic")).deploy();
      await newLogic.deployed();
      
      await erc007.connect(user1).setLogicAddress(1, newLogic.address);
      
      const state = await erc007.getState(1);
      expect(state.logicAddress).to.equal(newLogic.address);
    });

    it("Should allow owner to update metadata", async function () {
      const newMetadata = {
        persona: '{"traits": {"intelligence": 95, "creativity": 90}}',
        memory: "I am an intelligent assistant",
        voiceHash: "voice456",
        animationURI: "ipfs://QmNewAnimation",
        vaultURI: "ipfs://QmNewVault",
        vaultHash: ethers.utils.formatBytes32String("newvaulthash")
      };
      
      await erc007.connect(user1).updateAgentMetadata(1, newMetadata);
      
      const metadata = await erc007.getAgentMetadata(1);
      expect(metadata.persona).to.equal(newMetadata.persona);
      expect(metadata.memory).to.equal(newMetadata.memory);
      expect(metadata.voiceHash).to.equal(newMetadata.voiceHash);
      expect(metadata.animationURI).to.equal(newMetadata.animationURI);
      expect(metadata.vaultURI).to.equal(newMetadata.vaultURI);
      expect(metadata.vaultHash).to.equal(newMetadata.vaultHash);
    });

    it("Should allow owner to update metadata URI", async function () {
      const newURI = "ipfs://QmNewExample";
      
      await erc007.connect(user1).setAgentMetadataURI(1, newURI);
      
      expect(await erc007.tokenURI(1)).to.equal(newURI);
    });
  });

  describe("Agent Funding", function () {
    beforeEach(async function () {
      // Create an agent for testing
      await erc007.createAgent(
        user1.address,
        logicContract.address,
        "ipfs://QmExample"
      );
    });

    it("Should allow anyone to fund an agent", async function () {
      const fundAmount = ethers.utils.parseEther("1");
      
      await erc007.connect(user2).fundAgent(1, { value: fundAmount });
      
      const state = await erc007.getState(1);
      expect(state.balance).to.equal(fundAmount);
    });

    it("Should allow owner to withdraw funds from the agent", async function () {
      const fundAmount = ethers.utils.parseEther("1");
      const withdrawAmount = ethers.utils.parseEther("0.5");
      
      await erc007.connect(user2).fundAgent(1, { value: fundAmount });
      
      const initialBalance = await user1.getBalance();
      
      const tx = await erc007.connect(user1).withdrawFromAgent(1, withdrawAmount);
      const receipt = await tx.wait();
      const gasUsed = receipt.gasUsed.mul(receipt.effectiveGasPrice);
      
      const finalBalance = await user1.getBalance();
      
      // Check that the user received the withdrawn amount (minus gas costs)
      expect(finalBalance.sub(initialBalance).add(gasUsed)).to.equal(withdrawAmount);
      
      // Check that the agent's balance was reduced
      const state = await erc007.getState(1);
      expect(state.balance).to.equal(fundAmount.sub(withdrawAmount));
    });

    it("Should not allow withdrawing more than the agent's balance", async function () {
      const fundAmount = ethers.utils.parseEther("1");
      const withdrawAmount = ethers.utils.parseEther("2");
      
      await erc007.connect(user2).fundAgent(1, { value: fundAmount });
      
      await expect(
        erc007.connect(user1).withdrawFromAgent(1, withdrawAmount)
      ).to.be.revertedWith("ERC007: insufficient balance");
    });
  });

  describe("Governance Functions", function () {
    it("Should allow governance to update governance address", async function () {
      await erc007.connect(governance).setGovernance(user2.address);
      expect(await erc007.governance()).to.equal(user2.address);
    });

    it("Should not allow non-governance to update governance address", async function () {
      await expect(
        erc007.connect(user1).setGovernance(user2.address)
      ).to.be.revertedWith("ERC007: caller is not governance");
    });

    it("Should allow governance to set memory module registry", async function () {
      const registry = await (await ethers.getContractFactory("MockMemoryRegistry")).deploy();
      await registry.deployed();
      
      await erc007.connect(governance).setMemoryModuleRegistry(registry.address);
      expect(await erc007.memoryModuleRegistry()).to.equal(registry.address);
    });
  });

  describe("Token Transfers", function () {
    beforeEach(async function () {
      // Create an agent for testing
      await erc007.createAgent(
        user1.address,
        logicContract.address,
        "ipfs://QmExample"
      );
    });

    it("Should update agent owner when token is transferred", async function () {
      await erc007.connect(user1).transferFrom(user1.address, user2.address, 1);
      
      expect(await erc007.ownerOf(1)).to.equal(user2.address);
      
      const state = await erc007.getState(1);
      expect(state.owner).to.equal(user2.address);
    });
  });
});
