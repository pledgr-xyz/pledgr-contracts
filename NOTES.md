# Notes

## Contract design

- `add` and `remove` members don't need to be gas-efficient

## Gas comparisons between implementations

### Contract Deployment

| Commit                                     | Gas     | Notes                                   |
| ------------------------------------------ | ------- | --------------------------------------- |
| `c5ad882245df8120c9b7983c1f9153eb76f90685` | 1319448 |                                         |
| `d98c5dd667ddf04af414e782f6447ba6ea8fcd16` | 1290827 |                                         |
| `4655b073dc7a33c16858e4d682b6026e53f73aed` | 1526729 | added various fns                       |
| `commit`                                   | 1515808 | consolidate `distribute` into `receive` |

### `receive`

| Commit                                     | Gas   | Notes                                   |
| ------------------------------------------ | ----- | --------------------------------------- |
| `2eed41c5063d42afccf08a2fac98ae06669a48ee` | 62200 |                                         |
| `4655b073dc7a33c16858e4d682b6026e53f73aed` | 59546 | A few optimisations to distribute fn    |
| `commit`                                   | 59517 | consolidate `distribute` into `receive` |
