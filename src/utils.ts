import semver from 'semver';

/**
 * Parse the package version from tarball filename
 * @param {String} name
 * @returns {String}
 */
export function parseVersionFromTarballFilename(name: string): string | void {
    // @ts-expect-error FIXME: we know the regex is valid, but we should improve this part as ts suggest
    const version = /.+-(\d.+)\.tgz/.test(name) ? name.match(/.+-(\d.+)\.tgz/)[1] : undefined;
    if (version && semver.valid(version)) return version;
}
