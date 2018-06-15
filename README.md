# Mentat SmartContract

## Development

- install Truffle
  - `truffle develop`
  - `compile`
  - `migrate`
  
If an error occurs during the migration step, try to delete the ./build folder and try to compile again.
  
- Use http://remix.ethereum.org/ to deploy
  - use remixd to link the ./contracts directory
  - copy the contract address from truffle output into remix > run > address
  
You should now be able to interact with your local Smart Contract by calling the functions in remix.
