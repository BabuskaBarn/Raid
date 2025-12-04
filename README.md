In NoBodesModule which is the working path as main is not up to date
npm init -y
npm install --save-dev hardhat


npx hardhat compile
npx hardhat ignition deploy ignition/modules/Raid.js --network sepolia
To verify Contract use:
npx hardhat verify --network sepolia Your_Contract  (RaidBossRPGModule#RaidBossRPG)

In Etherscanunder under Contract: write Contract 

Conect to Web3 via Metamask


attacks can be executed
The Raidboss can be executed
andRewards can be claimed once the boss is dead


Test for Console
npx hardhat console
in hardhat console:

Connect with:
const [owner] = await ethers.getSigners();
const RaidBossRPG = await ethers.getContractFactory("RaidBossRPG");
const game = RaidBossRPG.attach("YOUR_CONTRACT_ADDRESS");

Reset boss:
const tx1 = await game.resetBoss(100, 1000);
await tx1.wait();

Attack:
const tx2 = await game.attack(0); // 0, 1, or 2
await tx2.wait();


Claim rewards (only executable once RaidBoss is dead):
const tx3 = await game.claim();
await tx3.wait();


Move Type	Description	Base Damage	Variance
0	Slash (steady)	Base Damage: 10	 Variance: 6
1	Fireball (higher variance) Base Damage: 7	 Variance: 12
2	Smite (slow, big) Base Damage:	14	 Variance: 4
