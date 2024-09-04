import { migrate } from 'postgres-migrations';
import { Logger } from '@verdaccio/types';
import { Pool, PoolClient } from 'pg';
import { join } from 'path';
import { LOGGER_PREFIX } from './constants';

/**
 * Manager for DB connections
 */
export class DbManager {
    private readonly pool: Pool;
    private readonly logger: Logger;
    private connectionCount: number;

    public constructor(logger: Logger, connectionString: string) {
        if(!connectionString) {
            throw new Error('Connection string cannot be null!');
        }

        this.pool = new Pool({
            connectionString: connectionString
        });
        this.logger = logger;

        //Count monitoring
        this.connectionCount = 0;
        this.pool.on('acquire', () => {
            this.connectionCount++;
            this.logger.debug(`${LOGGER_PREFIX}: Connection acquired from pool. Count: ${this.connectionCount}`);
        });
        this.pool.on('release', () => {
            this.connectionCount--;
            this.logger.debug(`${LOGGER_PREFIX}: Connection released back to pool. Count: ${this.connectionCount}`);
        });
    }

    /**
     * Gets a new PoolClient.
     * Must call PoolClient.release to release the connection back to the pool
     */
    public async getConnection(): Promise<PoolClient> {
        return await this.pool.connect();
    }

    /**
     * Runs migrations
     */
    public async migrateDb(): Promise<void> {
        const pgClient = await this.getConnection();
        try {
            const migrationsDir = join(__dirname, '../migrations');
            await migrate({
                client: pgClient,
            }, migrationsDir, {
                logger: (msg) => this.logger.info(`${LOGGER_PREFIX} [postgres-migrations]: ${msg}`)
            });
        } catch(ex) {
            this.logger.error({ ex: ex.message }, `${LOGGER_PREFIX}: Error running migrations! @{ex}`);
            throw ex;
        } finally {
            pgClient.release();
        }
    }
}
