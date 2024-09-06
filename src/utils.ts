import { Config, IStorageManager, Package } from '@verdaccio/types';
import semver from 'semver';

//Util functions come from verdaccio-install-counts
//https://github.com/openupm/verdaccio-install-counts/blob/main/src/utils.ts

/**
 * Parse the package version from tarball filename
 * @param {String} name
 * @returns {String}
 */
export function parseVersionFromTarballFilename(name: string): string | undefined {
    // @ts-expect-error FIXME: we know the regex is valid, but we should improve this part as ts suggest
    const version = /.+-(\d.+)\.tgz/.test(name) ? name.match(/.+-(\d.+)\.tgz/)[1] : undefined;
    if (version && semver.valid(version)) return version;

    return undefined;
}

/**
 * The async version of storage.getPackage(options)
 * @param storage storage manager
 * @param options options of storage.getPackage(options)
 * @returns Promise<Package> 
 */
export function getPackageAsync(storage: IStorageManager<Config>, options: any): Promise<Package> {
    return new Promise((resolve, reject) => {
        storage.getPackage({
            ...options,
            callback: (err: any, metadata: Package) => {
                if (err) {
                    reject(err);
                } else {
                    resolve(metadata);
                }
            }
        });
    });
}
