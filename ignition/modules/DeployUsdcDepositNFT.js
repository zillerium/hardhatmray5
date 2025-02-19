const { buildModule } = require("@nomicfoundation/hardhat-ignition/modules");

module.exports = buildModule("UsdcDepositNFTModule", (m) => {
  const deposit = m.contract("UsdcDepositNFT", ["0x0D1D5933dA6283D635D6ae65c356FBe01Dc1797C"]); // Modify if constructor needs different args
  return { deposit };
});
