# Union Contracts V1.5

Built using [foundry](https://book.getfoundry.sh/) and [hardhat](https://hardhat.org/)

## Difference from V1

View the [diff](https://github.com/unioncredit/union-v1.5-contracts/compare/v1...v1.5)

-   Does not lock interest, only locks principal
-   First in first out locks for vouchers

## Install

To install dependencies:

```
git clone git@github.com:unioncredit/union-v1.5-contracts.git && cd union-v1.5-contracts
yarn install
```

## Compile

To compile with hardhat:

```
yarn hh:compile
```

## Foundry

Union V1.5 Contracts also includes a suit of tests (fuzzing tests) writte in solidity with foundry

To install Foundry (assuming a Linux or macOS System):

```
curl -L https://foundry.paradigm.xyz | bash
```

This will download foundryup. To start Foundry, run:

```
foundryup
```

To install dependencies:

```
forge install
```

To run tests:

```
forge test
```

The following modifiers are also available:

-   Level 2 (-vv): Logs emitted during tests are also displayed.
-   Level 3 (-vvv): Stack traces for failing tests are also displayed.
-   Level 4 (-vvvv): Stack traces for all tests are displayed, and setup traces for failing tests are displayed.
-   Level 5 (-vvvvv): Stack traces and setup traces are always displayed.

```
forge -vv
```

To profile gas usage:

```
forge test --gas-report
forge snapshot
```

## Fork Tests

Integration tests can be run using hardhat.

```
yarn hh:test
```

They can also be run in fork mode. (Some tests can be excluded from running in fork mode and other tests can only run in fork mode)

```
FORK_NODE_URL=<URL> FORK_BLOCK=<NUMBER> yarn hh:test
```

You can also define which config should be used for the fork mode.

```
CONFIG=arbitrum FORK_NODE_URL=<URL> FORK_BLOCK=<NUMBER> yarn hh:test
```

## Format

```
yarn format
```
