const { buildModule } = require("@nomicfoundation/hardhat-ignition/modules");

module.exports = buildModule("BondOfferNFTViewModule", (m) => {
  const bondOfferView = m.contract("BondOfferNFTView", ["0x0D1D5933dA6283D635D6ae65c356FBe01Dc1797C"]); // Modify if constructor needs different args
  return { bondOfferView };
});
