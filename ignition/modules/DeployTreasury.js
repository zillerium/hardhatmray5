const { buildModule } = require("@nomicfoundation/hardhat-ignition/modules");

module.exports = buildModule("TreasuryModule", (m) => {
  const treasury = m.contract("Treasury", ["0x9f0BEA7dE67e8Fb333067ed83b468E5082280835"]); // Modify if constructor needs different args
  return { treasury };
});
