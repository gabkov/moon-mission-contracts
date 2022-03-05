# Deployment: [moon-mission-dev](https://moon-mission.netlify.app/#/)


# Moon Mission WIP


```shell
npx hardhat accounts
npx hardhat compile
npx hardhat clean
npx hardhat test
npx hardhat node
node scripts/sample-script.js
npx hardhat help
```

# Security analysis tool commands:

## Slynther:
**For all the contracts**
```
slynther .
```
**For separated contract** (solc remap required for npm package contracts):
```
slither <contract-name> --solc-remaps @=node_modules/@
```


Mythril: 

**with solc json:** (execution timeout is optional)
```
myth -v4 analyze <contract_name> --solc-json solc_json.json --execution-timeout 180
```
**with flattend contract** (run npx hardhat flat --output Flatten.sol first):
```
myth -v4 analyze Flatten.sol:<contranc-name> --execution-timeout 180
```