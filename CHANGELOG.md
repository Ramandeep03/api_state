## 2.0.0

- **Breaking:** Added `ApiLoadMore<T>` to the sealed `ApiStatus<T>` states. Add an `ApiLoadMore` case to exhaustive switches.
- Added `isLoadMore`, `toLoadMore()`, and load-more handling to mapping and callback helpers.
- `ApiFailure<T>` can optionally retain prior data. Use `hasData: true` when the retained value is `null`.
- Added `toLoadMoreFailure(error)` to preserve loaded data when a next-page request fails.

## 1.0.0

- Initial version.
