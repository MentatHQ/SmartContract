const MentatToken = artifacts.require("./MentatToken.sol");

module.exports = function(deployer) {
  deployer.deploy(MentatToken);
};