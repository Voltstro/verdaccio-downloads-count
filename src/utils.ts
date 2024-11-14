import { Config, IStorageManager, Package } from '@verdaccio/types';

//Util functions come from verdaccio-install-counts
//https://github.com/openupm/verdaccio-install-counts/blob/main/src/utils.ts

const semverRegex = /.+-((0|[1-9]\d*)\.(0|[1-9]\d*)\.(0|[1-9]\d*)(?:-((?:0|[1-9]\d*|\d*[a-zA-Z-][0-9a-zA-Z-]*)(?:\.(?:0|[1-9]\d*|\d*[a-zA-Z-][0-9a-zA-Z-]*))*))?(?:\+([0-9a-zA-Z-]+(?:\.[0-9a-zA-Z-]+)*))?)\.tgz/;

/**
 * Parse the package version from tarball filename
 * @param {String} name
 * @returns {String}
 */
export function parseVersionFromTarballFilename(name: string): string | null {
    if(typeof name !== 'string')
        throw new Error('\'name\' needs to be typeof string!');

    return semverRegex.test(name) ? name.match(semverRegex)![1] : null;
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
