//main.jsの実行前にDynamicRoundRobinにLINKトークン(継承あたり1link)を送ること!!

const destination = process.env.DESTINATION;
const contractAddr = "ROUNDROBIN_CONTRACT_ADDRESS";

async function main() {
  const factory = await ethers.getContractFactory("DynamicRoundRobin");
  const RoundRobin = await factory.attach(contractAddr);
  console.log("NFT Deployed to:", RoundRobin.address);
  const MintTx = await RoundRobin.createPlainRobin();
  await MintTx.wait();
  const MintTx1 = await RoundRobin.Inherit(destination, 0);
  await MintTx1.wait();
  const uri = await RoundRobin.tokenURI(0);
  console.log(uri);
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
