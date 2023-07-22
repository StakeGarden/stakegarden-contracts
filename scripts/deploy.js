// We require the Hardhat Runtime Environment explicitly here. This is optional
// but useful for running the script in a standalone fashion through `node <script>`.
//
// You can also run a script with `npx hardhat run <script>`. If you do that, Hardhat
// will compile your contracts, add the Hardhat Runtime Environment's members to the
// global scope, and execute the script.
const hre = require("hardhat");

async function main() {
  const controller = await deployController();
  const factory = await deployFactory(controller.address);

  const setPoolTX = await controller.contract.setPoolFactory(factory.address);
  await setPoolTX.wait();
}

async function deployController() {
  const oneInchContract = "0x1111111254EEB25477B68fb85Ed929f73A960582";
  const allowedStakeTokens = [
    "0x2791Bca1f2de4661ED88A30C99A7a9449Aa84174", //USDC
    "0x7ceB23fD6bC0adD59E62ac25578270cFf1b9f619" //WETH
  ];
  
  const controller = await hre.ethers.deployContract("StakeGardenController", [oneInchContract, allowedStakeTokens]);
  await controller.waitForDeployment();
  
  const address = await controller.getAddress();
  console.log(`Controller deployed at ${address}`);
  return {address, contract: controller};
}

async function deployFactory(controllerAddress) {
  const factory = await hre.ethers.deployContract("StakeGardenPoolFactory", [controllerAddress]);
  await factory.waitForDeployment();

  const address = await factory.getAddress();
  console.log(`Factory deployed at ${address}`);

  return {address, contract: factory};
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
