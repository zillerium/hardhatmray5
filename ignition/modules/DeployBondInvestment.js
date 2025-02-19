const { buildModule } = require("@nomicfoundation/hardhat-ignition/modules");

module.exports = buildModule("BondInvestmentModule", (m) => {
  const invest = m.contract("BondInvestment", ["0x0D1D5933dA6283D635D6ae65c356FBe01Dc1797C"]); // Modify if constructor needs different args
  return { invest };
});
