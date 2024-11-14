# verdaccio-downloads-count

[![License](https://img.shields.io/github/license/voltstro/verdaccio-downloads-count.svg)](https://github.com/Voltstro/verdaccio-downloads-count/blob/master/LICENSE.md)
[![NPM](https://img.shields.io/npm/v/verdaccio-downloads-count)](https://www.npmjs.com/package/verdaccio-downloads-count)
[![Discord](https://img.shields.io/badge/Discord-Voltstro-7289da.svg?logo=discord)](https://discord.voltstro.dev) 
[![YouTube](https://img.shields.io/badge/Youtube-Voltstro-red.svg?logo=youtube)](https://www.youtube.com/Voltstro)

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
    # (Required) Connection string to the database. Postgres connection URI. Can also be set by VDC_DB_CONNECTION_STRING env
    connectionString: <Postgres Connection String>

    # (Optional) Automatically migrates the database. Uses the postgres-migrations package for handling migrations. 
    migrate: true

```

### Database Configuration

You will need to configure a database for this middleware to use. You should create a standalone database for this middleware to use.

The connection string is a Postgres URI connection string. It is parsed by [pg-connection-string](https://github.com/brianc/node-postgres/blob/master/packages/pg-connection-string/README.md).

Generally, the format will look like:

```
postgres://someuser:somepassword@somehost:5432/somedatabase
```

You can set the connection string either in the config, or by setting the `VDC_DB_CONNECTION_STRING` environment variable.

For creating the schema, it is recommended to use the auto-migrations that this middleware has built in by enabling the `migrate` option in the config, otherwise the SQL migration scripts can be found in the `migrations/` directory within the package (or repo). You will need to grant the user that the middleware is using permissions to insert, create and update. If you are also using auto-migrate, you will also need to grant permissions to create tables and procedures to the user.

Currently, everything needs to be on the `public` schema.

## Querying

Since there is currently no way of getting the tracked download counts through either an API endpoint or a web interface, you will need to query the database manually (or through a dashboard/BI tool). Some example SQL queries are below.

```sql
-- Total Download Counts
SELECT * FROM public.package_total_count WHERE package_id = '<PackageId>';

-- Daily Download Counts for a Package Version
SELECT * FROM public.package_count WHERE package_id = '<PackageId>@<Version>';
```

## Why?

Why use Postgres as the datastore for storing package downloads count? Simple, currently all other packages use a different datastore for storing the data, and I already use Postgres in my stack, but not the others, and I don't currently want to introduce another one of these solutions just for storing downloads count.

Other solutions include:

- [verdaccio-install-counts](https://www.npmjs.com/package/verdaccio-install-counts) - Uses Redis
- [@xlts.dev/verdaccio-prometheus-middleware](https://www.npmjs.com/package/@xlts.dev/verdaccio-prometheus-middleware) - Uses prometheus

## Authors

* **Voltstro** - *Initial work* - [Voltstro](https://github.com/Voltstro)

## Thanks

- [verdaccio-install-counts](https://www.npmjs.com/package/verdaccio-install-counts) - Provided base example on tracking downlands count. `parseVersionFromTarballFilename` method comes from here too.
