import { Logger } from '@verdaccio/types';
import { Pool, PoolClient } from 'pg';

export class DbManager {
    private readonly pool: Pool;
    private connectionCount: number;

    public constructor(logger: Logger, connectionString: string) {
        if(!connectionString) {
            throw new Error('Connection string cannot be null!');
        }

        this.pool = new Pool({
            connectionString: connectionString
        });

        //Count minoring
        this.connectionCount = 0;
        this.pool.on('acquire', () => {
            this.connectionCount++;
            logger.debug(`Connection acquired from pool. Count: ${this.connectionCount}`);
        });
        this.pool.on('release', () => {
            this.connectionCount--;
            logger.debug(`Connection released back to pool. Count: ${this.connectionCount}`);
        });
    }

    public async getConnection(): Promise<PoolClient> {
        return await this.pool.connect();
    }
}