const { buildModule } = require("@nomicfoundation/hardhat-ignition/modules");

module.exports = buildModule("MintERC20Module", (m) => {
  const MintContract = m.contract("MintERC20", ["0x0D1D5933dA6283D635D6ae65c356FBe01Dc1797C"]); // Modify if constructor needs different args
  return { MintContract };
});
