/**
 * The single place the frontend imports the frozen contract from.
 *
 * Everything else in the app imports from `@/lib/contract`, never from a deep
 * path inside the contract package. That keeps the contract's physical
 * location an implementation detail and makes a version bump a one-file change
 * here rather than a repo-wide search.
 *
 * `@glassbox/contracts` is a real `file:` dependency rather than a tsconfig
 * path alias: Turbopack will not resolve a path alias that points outside the
 * project root, and a package boundary also stops a component from reaching
 * into contract internals.
 *
 * Owner: gb-frontend-architecture. The contract itself is owned by
 * gb-backend-contract and is never edited from this side.
 */
export * from "@glassbox/contracts";
