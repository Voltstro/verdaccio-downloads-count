import { Application } from 'express';
import { Config, IBasicAuth, IPluginMiddleware, IStorageManager, Logger, PluginOptions } from '@verdaccio/types';
import { DownloadsCountConfig } from './downloadsCountConfig';
import { getPackageAsync, parseVersionFromTarballFilename } from './utils';
import { DbManager } from './dbManager';
import { LOGGER_PREFIX } from './constants';

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

        let connectionString = this.config.connectionString;

        if(!connectionString)
            connectionString = process.env.VDC_DB_CONNECTION_STRING as string;

        this.dbManager = new DbManager(this.logger, connectionString);
    }

    public register_middlewares(app: Application, auth: IBasicAuth<Config>, storage: IStorageManager<Config>,): void {
        //Migrate DB (if needed)
        if(this.config.migrate) {
            void this.dbManager.migrateDb();
        }

        app.get('/:package/-/:filename', async (req, res, next) => {
            //Get package name and file name
            const packageName = req.params.package;
            const fileName = req.params.filename;

            //Immediately process the request, we will do everything after
            next();

            this.logger.debug(`${LOGGER_PREFIX}: Got request for package download...`);

            try {
                const version = parseVersionFromTarballFilename(fileName);

                if(!packageName) {
                    this.logger.debug(`${LOGGER_PREFIX}: No package name was in the query params.`);
                    return;
                }

                if(!fileName) {
                    this.logger.debug(`${LOGGER_PREFIX}: No file name was in the query params.`);
                    return;
                }

                if(!version) {
                    this.logger.debug(`${LOGGER_PREFIX}: Could not get package version.`);
                    return;
                }

                const packageDetails = await getPackageAsync(storage, {
                    name: packageName,
                    uplinksLook: true,
                    req,
                    abbreviated: false
                });

                if(!packageDetails) {
                    this.logger.warn({ packageName, version }, `${LOGGER_PREFIX}: Failed getting package @{packageName}, ver: @{version}.`);
                    return;
                }

                if(!(version in packageDetails.versions)) return;

                const pgClient = await this.dbManager.getConnection();
                try {
                    this.logger.debug(`${LOGGER_PREFIX}: Calling handle_package_count on DB...`);
                    await pgClient.query('SELECT public.handle_package_count($1, $2);', [packageName, version]);
                } catch(ex) {
                    this.logger.error({ ex }, `${LOGGER_PREFIX}: An error occurred while calling handle package count on the DB! @{ex}`);
                } finally {
                    pgClient.release();
                }
            } catch(ex) {
                this.logger.error({ ex }, `${LOGGER_PREFIX}: An error occurred in downloads count middleware! @{ex}`);
            }
        });

        this.logger.info(`${LOGGER_PREFIX}: Installed downloads count middleware`);
    }
}
