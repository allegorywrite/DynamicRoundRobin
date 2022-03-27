//main.jsの実行前にDynamicRoundRobinにLINKトークン(継承あたり1link)を送ること!!

const destination = "0x16ea840cfA174FdAC738905C4E5dB59Fd86912a1";
const contractAddr = "0x8707238491a1E764419c1ce00aF4aF0604fe12eD";

async function main() {
  const factory = await ethers.getContractFactory("MagicPlank");
  const RoundRobin = await factory.attach(contractAddr);
  console.log("NFT Deployed to:", RoundRobin.address);
  const MintTx = await RoundRobin.createPlainPlank();
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
