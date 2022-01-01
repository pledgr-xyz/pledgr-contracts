# Notes

## Contract design

- `add` and `remove` members don't need to be gas-efficient

## Gas comparisons between implementations

### Contract Deployment

| Commit                                     | Gas (max) | Notes                                   |
| ------------------------------------------ | --------- | --------------------------------------- |
| `c5ad882245df8120c9b7983c1f9153eb76f90685` | 1319448   |                                         |
| `d98c5dd667ddf04af414e782f6447ba6ea8fcd16` | 1290827   |                                         |
| `4655b073dc7a33c16858e4d682b6026e53f73aed` | 1526729   | added various fns                       |
| `5023a5ee3d1f05f4eb42248b68eb6519f0ed7522` | 1515808   | consolidate `distribute` into `receive` |
| `acc3dd5d9f11c2dfb3f26616b0d940c1cb158887` | 1472915   | remove `getReceiversPercent` method     |
| `e131659812fff331ca39845c25ee330b0693b4fc` | 1478397   | Fix `setPayout` bug                     |
| `4431b6a9a55c6ee3c235a4c95ccae13de0a34770` | 1470655   | Push to `setPayout` empty array instead |
| `1892273c15af506fca14e198b14de08e915406e9` | 1470470   | Don't check for payouts length          |

### `receive`

| Commit                                     | Gas   | Notes                                   |
| ------------------------------------------ | ----- | --------------------------------------- |
| `2eed41c5063d42afccf08a2fac98ae06669a48ee` | 62200 |                                         |
| `4655b073dc7a33c16858e4d682b6026e53f73aed` | 59546 | A few optimisations to distribute fn    |
| `5023a5ee3d1f05f4eb42248b68eb6519f0ed7522` | 59517 | consolidate `distribute` into `receive` |
| `4431b6a9a55c6ee3c235a4c95ccae13de0a34770` | 51040 | Push to `setPayout` empty array instead |

Got gas down to 49111 for 1 array of Payouts