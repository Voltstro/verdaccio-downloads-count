import { Config } from '@verdaccio/types';

export interface DownloadsCountConfig extends Config {
    migrate: boolean;
    connectionString: string;
}
