const hre = require("hardhat");

const initialUri = "https://ipfs.moralis.io:2053/ipfs/QmRiuXrWe9RWGtoHcBjcjgzqx8bcxZ2jXfjsZPudforCPv/metadata/0000000000000000000000000000000000000000000000000000000000000001.json";

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