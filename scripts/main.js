const destination = '0x2e765468e8CCe070117608FBa390dF61Cd293C50';
const authorAddress = '0x16ea840cfA174FdAC738905C4E5dB59Fd86912a1';

async function main() {
  const factory = await ethers.getContractFactory("APIConsumer");
  const contract = await factory.deploy();
  console.log("NFT Deployed to:", contract.address);
  const res = await contract.toString(0x000000000000000000000000000000000000000000000000746f6d6f6b696e67);
  console.log(res);
}
main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
