const hre = require("hardhat");

const initialUri = "https://ipfs.io/ipfs/QmYouRy6h83ifpmTx4MpN6rhg3ByCxhDBCAYsBFWPngjhX?filename=metadata2.json";

async function main() {
  const factory = await hre.ethers.getContractFactory("DynamicRoundRobin");
  const RoundRobin = await factory.deploy(initialUri);
  await RoundRobin.deployed();
  console.log("NFT deployed to:", RoundRobin.address);
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });