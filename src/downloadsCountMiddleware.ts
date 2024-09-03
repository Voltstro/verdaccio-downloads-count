import { Application } from 'express';
import { Config, IPluginMiddleware, Logger, PluginOptions } from '@verdaccio/types';
import { DownloadsCountConfig } from './downloadsCountConfig';
import { parseVersionFromTarballFilename } from './utils';
import { DbManager } from './dbManager';

/**
 * Main downloads count middleware
 */
export class DownloadsCountMiddleware implements IPluginMiddleware<DownloadsCountConfig> {
    private readonly logger: Logger;
    private readonly config: DownloadsCountConfig;
    private readonly dbManager: DbManager;

    public constructor(config: Config, options: PluginOptions<DownloadsCountConfig>) {
        this.logger = options.logger;
        this.config = options.config;
        this.dbManager = new DbManager(this.logger, this.config.connectionString);
    }

    public register_middlewares(app: Application): void {
        //Migrate DB (if needed)
        if(this.config.migrate) {
            void this.dbManager.migrateDb();
        }

        //Package download handler
        app.use('/:package/-/:filename', async (req, res, next) => {
            //Immediately process the request, we will do everything after
            next();

            //Only interested in downloads that were successful
            if(req.method !== 'GET' && res.statusCode !== 200) return;

            //Handle count with DB
            const pgClient = await this.dbManager.getConnection();
            try {
                const packageName = req.params.package;
                const fileName = req.params.filename;
                const version = parseVersionFromTarballFilename(fileName);

                await pgClient.query('SELECT public.handle_package_count($1, $2);', [packageName, version]);
            } catch(ex) {
                this.logger.error({ ex }, 'An error occurred handling package download count! @{ex}');
            } finally {
                pgClient.release();
            }
        });

        this.logger.info('Installed downloads count middleware');
    }
}
