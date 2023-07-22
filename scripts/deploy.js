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

  const setPoolFactoryTx = await controller.contract.setPoolFactory(factory.address);
  await setPoolFactoryTx.wait();

  //await createPool(factory.contract);
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

async function createPool(factory) {
  // address[] calldata stakeTokens,
  //   uint256[] calldata weights,
  //   string calldata name,
  //   string calldata symbol

  const stakeTokens = [
    "0x2791Bca1f2de4661ED88A30C99A7a9449Aa84174", //USDC
    "0x7ceB23fD6bC0adD59E62ac25578270cFf1b9f619" //WETH
  ];

  const weights = [
    hre.ethers.parseUnits("500", 6),
    hre.ethers.parseUnits("500", 18)
  ];


  console.log("Creating pool...");
  console.log("Factory:", factory);
  console.log("StakeTokens:", stakeTokens);
  console.log("Weights:", weights);

  try {
    const createPoolTx = await factory.createPool(stakeTokens, weights, "StakeGarden ETH", "sgETH");
    await createPoolTx.wait();
    console.log("Pool created successfully");
  } catch (error) {
    console.error("createPoolTx failed:", error);
  }


  // const poolAddress = await factory.createPool(stakeTokens, weights, "StakeGarden ETH", "sgETH");
  // console.log(poolAddress);

  //const address = await createPoolTx.getAddress();
  //console.log(`Pool deployed at ${address}`);

  //return {address, contract:null};
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
