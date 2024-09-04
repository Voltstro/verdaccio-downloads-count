# verdaccio-downloads-count

Tracks daily downloads count for packages. Data is stored in a Postgres database.

## Features

- Tracks daily and total downloads count for packages
- Stores data in a Postgres database

There is currently no web UI or endpoints for retrieving downloads count stats, the only way is via running queries on the database.

## Getting Started

### Prerequisites

- Postgres Database (Tested on Postgres 15)
- Verdaccio 5

### Install

Install like any other Verdaccio middleware.

```
npm install verdaccio-downloads-count
```

### Configuration

To use the middleware, you will need to add the middleware to your verdaccio's config `middleware` option.

```yaml
middlewares:
  downloads-count:
    # (Required) Connection string to the database. Standard Postgres connection string. Can also be set by VDC_DB_CONNECTION_STRING
    connectionString: <Postgres Connection String>

    # (Optional) Automatically migrate the database. Uses the postgres-migrations package for handling migration. 
    migrate: true

```

#### Migrations

Since this package stores its data in Postgres database, the database will need to contain the schema this package needs.

If the `migrate` option is enabled in the config, then this package will automatically maintain the migrations using the [postgres-migrations](https://www.npmjs.com/package/postgres-migrations) package. Otherwise you will need to maintain the database migrations your self. Migrations scripts can be found `migrations/` directory within the package (or repo).

## Why?

Why use Postgres as the datastore for storing package downloads count? Simple, all other packages use a different datastore for storing the data, and I already use Postgres in my stack, but not the others, and I don't currently want to introduce another one of these solutions just for storing downloads count.

Other solutions include:

- [verdaccio-install-counts](https://www.npmjs.com/package/verdaccio-install-counts) - Uses Redis
- [@xlts.dev/verdaccio-prometheus-middleware](https://www.npmjs.com/package/@xlts.dev/verdaccio-prometheus-middleware) - Uses prometheus

## Authors

* **Voltstro** - *Initial work* - [Voltstro](https://github.com/Voltstro)

## Thanks

- [verdaccio-install-counts](https://www.npmjs.com/package/verdaccio-install-counts) - Provided base example on tracking downlands count. `parseVersionFromTarballFilename` method comes from here too.
