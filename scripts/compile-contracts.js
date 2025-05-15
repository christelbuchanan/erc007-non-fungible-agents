const { execSync } = require("child_process");
const fs = require("fs");
const path = require("path");

// Compile contracts
console.log("Compiling contracts...");
try {
  execSync("npx hardhat compile", { stdio: "inherit" });
  console.log("Contracts compiled successfully!");
} catch (error) {
  console.error("Error compiling contracts:", error);
  process.exit(1);
}

// Generate documentation
console.log("Generating documentation...");

// Ensure docs directory exists
const docsDir = path.join(__dirname, "..", "docs");
if (!fs.existsSync(docsDir)) {
  fs.mkdirSync(docsDir);
}

// Get contract artifacts
const artifactsDir = path.join(__dirname, "..", "artifacts", "contracts");
const contracts = [
  "ERC007",
  "ERC007Governance",
  "ERC007Treasury",
  "MemoryModuleRegistry",
  "AgentFactory",
  "CircuitBreaker",
  "VaultPermissionManager"
];

// Generate markdown documentation for each contract
contracts.forEach(contractName => {
  try {
    const artifactPath = path.join(
      artifactsDir, 
      `${contractName}.sol`, 
      `${contractName}.json`
    );
    
    if (!fs.existsSync(artifactPath)) {
      console.warn(`Artifact not found for ${contractName}`);
      return;
    }
    
    const artifact = require(artifactPath);
    const abi = artifact.abi;
    
    let markdown = `# ${contractName}\n\n`;
    
    // Add description
    const descriptions = {
      "ERC007": "Implementation of the ERC-007 standard for autonomous agent tokens",
      "ERC007Governance": "Governance contract for the ERC-007 ecosystem",
      "ERC007Treasury": "Treasury contract for the ERC-007 ecosystem",
      "MemoryModuleRegistry": "Registry for memory modules used by ERC-007 agents",
      "AgentFactory": "Factory contract for creating and managing ERC-007 agents",
      "CircuitBreaker": "Emergency circuit breaker for the ERC-007 ecosystem",
      "VaultPermissionManager": "Manages permissions for accessing agent vaults"
    };
    
    markdown += `## Description\n\n${descriptions[contractName] || "No description available."}\n\n`;
    
    // Add functions
    markdown += `## Functions\n\n`;
    
    const functions = abi.filter(item => item.type === "function");
    functions.forEach(func => {
      markdown += `### ${func.name}\n\n`;
      
      // Add function signature
      let signature = `function ${func.name}(`;
      signature += func.inputs.map(input => `${input.type} ${input.name}`).join(", ");
      signature += `)`;
      
      if (func.outputs && func.outputs.length > 0) {
        signature += ` returns (${func.outputs.map(output => output.type).join(", ")})`;
      }
      
      markdown += `\`\`\`solidity\n${signature}\n\`\`\`\n\n`;
      
      // Add inputs
      if (func.inputs.length > 0) {
        markdown += `#### Parameters\n\n`;
        markdown += `| Name | Type | Description |\n`;
        markdown += `| ---- | ---- | ----------- |\n`;
        
        func.inputs.forEach(input => {
          markdown += `| ${input.name} | ${input.type} | ${input.description || ""} |\n`;
        });
        
        markdown += `\n`;
      }
      
      // Add outputs
      if (func.outputs && func.outputs.length > 0) {
        markdown += `#### Returns\n\n`;
        markdown += `| Type | Description |\n`;
        markdown += `| ---- | ----------- |\n`;
        
        func.outputs.forEach(output => {
          markdown += `| ${output.type} | ${output.description || ""} |\n`;
        });
        
        markdown += `\n`;
      }
    });
    
    // Add events
    const events = abi.filter(item => item.type === "event");
    if (events.length > 0) {
      markdown += `## Events\n\n`;
      
      events.forEach(event => {
        markdown += `### ${event.name}\n\n`;
        
        // Add event signature
        let signature = `event ${event.name}(`;
        signature += event.inputs.map(input => `${input.indexed ? "indexed " : ""}${input.type} ${input.name}`).join(", ");
        signature += `)`;
        
        markdown += `\`\`\`solidity\n${signature}\n\`\`\`\n\n`;
        
        // Add inputs
        if (event.inputs.length > 0) {
          markdown += `#### Parameters\n\n`;
          markdown += `| Name | Type | Indexed | Description |\n`;
          markdown += `| ---- | ---- | ------- | ----------- |\n`;
          
          event.inputs.forEach(input => {
            markdown += `| ${input.name} | ${input.type} | ${input.indexed ? "Yes" : "No"} | ${input.description || ""} |\n`;
          });
          
          markdown += `\n`;
        }
      });
    }
    
    // Write markdown to file
    const docPath = path.join(docsDir, `${contractName}.md`);
    fs.writeFileSync(docPath, markdown);
    console.log(`Documentation generated for ${contractName}`);
    
  } catch (error) {
    console.error(`Error generating documentation for ${contractName}:`, error);
  }
});

console.log("Documentation generation complete!");
