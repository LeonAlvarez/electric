# electric-sql

## 0.5.0-next.5

### Patch Changes

- d359cae: Made argument of liveMany optional.

## 0.5.0-next.4

### Patch Changes

- 5567869: Use PascalCased model names in generated Prisma schema and map them to the original table names.
- dc48f1f: Fixed `liveMany`, `liveUnique`, and `liveFirst` functions not exposing the `include` tables properly, making `useLiveQuery` miss some relevant updates
- c588bdf: Fixed not sending all the transactions if more than one was done within a throttle window
- 4531dde: Fix unreliable behaviour in the React `useConnectivityState` hook.
- b29693e: Modify generated migrations file to be a .ts file instead of .js file
- 18619ef: Fixed race condition in throttled perform snapshot
- 232f7a5: Updated snapshotting function to be more efficient when handling a large oplog
- 10bbae9: Moved `better-sqlite3` to dependencies because CLI command uses it
- 3cb872d: Chore: made `_getMeta` types more precise
- 9db6891: Also fix casing in types that refer to model names
- 7eab08e: Improved `config.url` parsing and SSL support.
- f4184b1: Fix: ensure we do much more cleanup in `useEffect` returned functions and in `close` method of Satellite

## 0.5.0-next.3

### Patch Changes

- edfb298: Improved subscription data insertion to do batched inserts instead of one-by-one statements. Inserting a lot of data should be much faster.
- a112a03: Fixed Satellite not handling mutliple concurrent subscription calls properly
- 3345cf8: Bugfix: update the `wa-sqlite` driver to use the `WebSocketFactory`.
- 80531f0: Fixed subscription being registered too late preventing deduplication
- e165048: Fixed subscription data not triggering data changed notification and thus `liveQuery` not working as expected

## 0.5.0-next.2

### Patch Changes

- bd02d79: Fixed garbage collection on shape unsubscribe (also called on subscription errors), which caused the DELETEs performed by GC get noted in operations log and sent to the server, causing data loss
- 49cbe27: Fixed using `.sync()` calls before the replication is established. Now we defer trying to subscribe until the replication is succesfully established if we're already in the process of connecting and starting.
- 2e8bfdf: Fixed the client not being able to reconnect if the migrations were preloaded and the only operation was a subscription. In that case the client have never received any LSNs (because migrations didn't need to be sent), so reconnection yielded errors due to missing LSN but existing previously fulfilled subscriptions. We now send the LSN with the subscription data so even if it's the first and only received message, the client has enough information to proceed.
- 93d7059: Fixed calls to the `.sync()` function when page reloads establishing a new subscription alongside existing one. Now we deduplicate subscription requests by hash of their contents, so no two exactly the same subscriptions are possible. This also solves calling `<table>.sync()` many times in multiple components - they will return the same promise.

## 0.5.0-next.1

### Patch Changes

- 49c4b35: Allowed `https:` protocol in service connections for CLI
- 525c8d1: Moved CLI dependency from dev to prod dependency list

## 0.5.0-next.0

### Minor Changes

- 69d13c4: Large rewrite, that introduces Data Access Library, client-side migration application, and subscriptions.

  This release encompasses quite a bit of work, but this is still considered an unstable release and so this is only a minor version bump.
  We intend to keep this and the `components/electric` server sync layer somewhat in sync on minor versions up to `1.0.0`: new features that require both server-side support as well as client-side support are going to result in a minor-level version bump on both, while features/improvements that don't need both sides will be marked as a patch version.

  Data access library exposes a prisma-like interface to interact with SQLite (any platform works, including web). On top of that, we introduce a `.sync()` interface which establishes a subscription with the server to get initial data and changes for the tables we're interested in.

  Server now knows how to send migrations to the clients as soon as they get applied to the underlying PostgreSQL database, and this client version applies them to the local database.

  Server now knows how to handle subscriptions and reconnection a bit better, which the client makes use of (in particular, this heavily improves initial sync performance).