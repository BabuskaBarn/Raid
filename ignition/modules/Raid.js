const { buildModule } = require("@nomicfoundation/hardhat-ignition/modules");

module.exports = buildModule("RaidBossRPGModule", (m) => {

    // Deployment of the RaidBossRPG contract (no constructor args)
    const raidBossRPG = m.contract("RaidBossRPG", []);

    return { raidBossRPG };
});
