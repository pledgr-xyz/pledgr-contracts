# Notes

## Contract design

- `add` and `remove` members don't need to be gas-efficient

## Gas comparisons between implementations

##### Initial (`c5ad882245df8120c9b7983c1f9153eb76f90685`)

Gas: 1319448

##### With struct (`d98c5dd667ddf04af414e782f6447ba6ea8fcd16`)

Gas: 1290827

### receive method

Gas for tx: 62200